#!/bin/bash

# Telegram 监控转发工具 - SSH 完全自动化安装脚本
# 使用方法: curl -sSL https://raw.githubusercontent.com/Kevin9181/telegram-monitor/main/ssh_auto_install.sh | bash -s -- -h <服务器IP> -u <用户名> -k <私钥路径>

# 设置颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================${NC}"
echo -e "${BLUE}  Telegram 监控工具 自动SSH安装    ${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""

# 显示使用方法
show_usage() {
    echo -e "${YELLOW}使用方法:${NC}"
    echo "1. 直接运行: bash ssh_auto_install.sh -h <IP> -u <用户名> -k <私钥>"
    echo "2. 在线安装: curl -sSL https://raw.githubusercontent.com/Kevin9181/telegram-monitor/main/ssh_auto_install.sh | bash -s -- -h <IP> -u <用户名> -k <私钥>"
    echo ""
    echo -e "${YELLOW}参数:${NC}"
    echo "  -h  服务器IP"
    echo "  -u  用户名"  
    echo "  -k  SSH私钥路径"
    echo "  -p  使用密码认证"
    echo "  -P  SSH端口(默认22)"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo "  bash ssh_auto_install.sh -h 1.2.3.4 -u root -k ~/.ssh/id_rsa"
    exit 1
}

# 解析参数
while getopts "h:u:k:pP:" opt; do
    case $opt in
        h) HOST="$OPTARG" ;;
        u) USER="$OPTARG" ;;
        k) KEY="$OPTARG" ;;
        p) PASSWORD_AUTH=true ;;
        P) PORT="$OPTARG" ;;
        *) show_usage ;;
    esac
done

# 检查必需参数
if [ -z "$HOST" ] || [ -z "$USER" ]; then
    echo -e "${RED}错误: 缺少服务器地址或用户名${NC}"
    show_usage
fi

PORT=${PORT:-22}

# 构建SSH命令
if [ "$PASSWORD_AUTH" = true ]; then
    SSH="ssh -p $PORT $USER@$HOST"
elif [ -n "$KEY" ]; then
    SSH="ssh -i $KEY -p $PORT $USER@$HOST"
    if [ ! -f "$KEY" ]; then
        echo -e "${RED}SSH密钥文件不存在: $KEY${NC}"
        exit 1
    fi
else
    echo -e "${RED}请指定认证方式 (-k 密钥 或 -p 密码)${NC}"
    show_usage
fi

echo -e "${YELLOW}连接到 $USER@$HOST:$PORT${NC}"

# 测试连接
if ! $SSH "echo '连接成功'" 2>/dev/null; then
    echo -e "${RED}SSH连接失败${NC}"
    exit 1
fi

echo -e "${GREEN}✅ SSH连接成功${NC}"

# 执行远程安装
echo -e "${YELLOW}开始远程安装...${NC}"

$SSH "bash -s" << 'REMOTE_INSTALL_SCRIPT'
#!/bin/bash

set -e

# 颜色定义
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}在远程服务器上开始安装...${NC}"

# 检查权限
if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
    echo -e "${RED}需要root权限或sudo权限${NC}"
    exit 1
fi

SUDO_CMD=""
if [ "$EUID" -ne 0 ]; then
    SUDO_CMD="sudo"
fi

# 检测系统
if command -v apt-get >/dev/null 2>&1; then
    echo -e "${YELLOW}检测到 Debian/Ubuntu 系统${NC}"
    $SUDO_CMD apt update
    $SUDO_CMD apt install -y git python3 python3-pip python3-venv
elif command -v yum >/dev/null 2>&1; then
    echo -e "${YELLOW}检测到 CentOS/RHEL 系统${NC}"
    $SUDO_CMD yum update -y
    $SUDO_CMD yum install -y git python3 python3-pip
else
    echo -e "${RED}不支持的系统${NC}"
    exit 1
fi

# 下载项目
echo -e "${YELLOW}下载项目...${NC}"
cd /tmp
rm -rf telegram-monitor
git clone https://github.com/Kevin9181/telegram-monitor.git
cd telegram-monitor

# 设置权限
chmod +x install.sh scripts/*.sh

echo -e "${GREEN}✅ 项目下载完成！${NC}"
echo -e "${YELLOW}项目位置: /tmp/telegram-monitor${NC}"
echo ""
echo -e "${BLUE}现在需要运行配置向导...${NC}"
echo "请提供以下信息来完成自动配置："

REMOTE_INSTALL_SCRIPT

echo -e "${GREEN}✅ 远程准备完成！${NC}"
echo ""
echo -e "${YELLOW}接下来需要配置 Telegram API 信息...${NC}"

# 收集配置信息
echo ""
echo -e "${BLUE}请提供配置信息:${NC}"
read -p "Telegram API ID: " API_ID
read -p "Telegram API Hash: " API_HASH
read -p "Bot Token: " BOT_TOKEN
read -p "管理员用户ID: " ADMIN_ID
read -p "监控关键词(空格分隔): " KEYWORDS
read -p "监控群组/频道(空格分隔): " WATCH_IDS
read -p "转发目标ID(空格分隔): " TARGET_IDS

# 创建配置并安装
echo -e "${YELLOW}应用配置并安装...${NC}"

$SSH "bash -s" << REMOTE_CONFIG_SCRIPT
#!/bin/bash

cd /tmp/telegram-monitor

# 创建配置文件
mkdir -p config

# 处理关键词数组
KEYWORDS_JSON="["
for kw in $KEYWORDS; do
    KEYWORDS_JSON+="\"\$kw\","
done
KEYWORDS_JSON=\${KEYWORDS_JSON%,}"]"

# 处理监控源数组  
WATCH_JSON="["
for src in $WATCH_IDS; do
    if [[ \$src =~ ^-?[0-9]+\$ ]]; then
        WATCH_JSON+="\$src,"
    else
        WATCH_JSON+="\"\$src\","
    fi
done
WATCH_JSON=\${WATCH_JSON%,}"]"

# 处理目标数组
TARGET_JSON="["
for tgt in $TARGET_IDS; do
    if [[ \$tgt =~ ^-?[0-9]+\$ ]]; then
        TARGET_JSON+="\$tgt,"
    else
        TARGET_JSON+="\"\$tgt\","
    fi
done
TARGET_JSON=\${TARGET_JSON%,}"]"

# 生成配置文件
cat > config/config.json << EOF
{
  "api_id": "$API_ID",
  "api_hash": "$API_HASH", 
  "bot_token": "$BOT_TOKEN",
  "target_ids": \$TARGET_JSON,
  "keywords": \$KEYWORDS_JSON,
  "watch_ids": \$WATCH_JSON,
  "whitelist": [$ADMIN_ID]
}
EOF

echo "配置文件已创建"

# 运行安装脚本(跳过交互式配置)
SKIP_CONFIG=1 sudo bash install.sh

REMOTE_CONFIG_SCRIPT

echo ""
echo -e "${GREEN}🎉 SSH自动安装完成！${NC}"
echo ""
echo -e "${YELLOW}服务状态:${NC}"
$SSH "systemctl status channel_forwarder --no-pager | head -n 5; echo ''; systemctl status bot_manager --no-pager | head -n 5"

echo ""
echo -e "${BLUE}管理命令:${NC}"
echo "查看日志: $SSH 'journalctl -u channel_forwarder -f'"
echo "重启服务: $SSH 'systemctl restart channel_forwarder bot_manager'"
echo "停止服务: $SSH 'systemctl stop channel_forwarder bot_manager'" 