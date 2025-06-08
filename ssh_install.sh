#!/bin/bash

# Telegram 监控转发工具 - SSH 一键安装脚本
# 支持通过SSH连接远程服务器并自动安装

# 设置颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # 恢复默认颜色

echo -e "${BLUE}====================================${NC}"
echo -e "${BLUE}   Telegram 监控工具 SSH 安装器    ${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""

# 显示使用方法
show_usage() {
    echo -e "${YELLOW}使用方法:${NC}"
    echo "1. SSH密钥认证: bash ssh_install.sh -h <服务器IP> -u <用户名> -k <私钥路径>"
    echo "2. 密码认证:   bash ssh_install.sh -h <服务器IP> -u <用户名> -p"
    echo ""
    echo -e "${YELLOW}参数说明:${NC}"
    echo "  -h  服务器IP地址或域名"
    echo "  -u  SSH用户名"
    echo "  -k  SSH私钥文件路径（可选，用于密钥认证）"
    echo "  -p  使用密码认证（可选）"
    echo "  -P  SSH端口（可选，默认22）"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo "  bash ssh_install.sh -h 192.168.1.100 -u root -k ~/.ssh/id_rsa"
    echo "  bash ssh_install.sh -h example.com -u ubuntu -p -P 2222"
    exit 1
}

# 解析命令行参数
while getopts "h:u:k:pP:" opt; do
    case $opt in
        h) SERVER_HOST="$OPTARG" ;;
        u) SSH_USER="$OPTARG" ;;
        k) SSH_KEY="$OPTARG" ;;
        p) USE_PASSWORD=true ;;
        P) SSH_PORT="$OPTARG" ;;
        *) show_usage ;;
    esac
done

# 检查必需参数
if [ -z "$SERVER_HOST" ] || [ -z "$SSH_USER" ]; then
    echo -e "${RED}错误: 缺少必需参数${NC}"
    show_usage
fi

# 设置默认值
SSH_PORT=${SSH_PORT:-22}

# 构建SSH命令
if [ "$USE_PASSWORD" = true ]; then
    SSH_CMD="ssh -p $SSH_PORT $SSH_USER@$SERVER_HOST"
    SCP_CMD="scp -P $SSH_PORT"
    echo -e "${YELLOW}将使用密码认证连接到 $SSH_USER@$SERVER_HOST:$SSH_PORT${NC}"
elif [ -n "$SSH_KEY" ]; then
    SSH_CMD="ssh -i $SSH_KEY -p $SSH_PORT $SSH_USER@$SERVER_HOST"
    SCP_CMD="scp -i $SSH_KEY -P $SSH_PORT"
    echo -e "${YELLOW}将使用密钥认证连接到 $SSH_USER@$SERVER_HOST:$SSH_PORT${NC}"
    # 检查密钥文件是否存在
    if [ ! -f "$SSH_KEY" ]; then
        echo -e "${RED}错误: SSH私钥文件不存在: $SSH_KEY${NC}"
        exit 1
    fi
else
    echo -e "${RED}错误: 请指定认证方式（-k 指定密钥文件或 -p 使用密码）${NC}"
    show_usage
fi

# 测试SSH连接
echo -e "${YELLOW}测试SSH连接...${NC}"
if ! $SSH_CMD "echo 'SSH连接成功'" 2>/dev/null; then
    echo -e "${RED}SSH连接失败，请检查:${NC}"
    echo "1. 服务器地址和端口是否正确"
    echo "2. 用户名是否正确"
    echo "3. SSH密钥或密码是否正确"
    echo "4. 服务器是否允许SSH连接"
    exit 1
fi

echo -e "${GREEN}✅ SSH连接测试成功${NC}"

# 检查目标系统
echo -e "${YELLOW}检查目标系统...${NC}"
OS_INFO=$($SSH_CMD "cat /etc/os-release 2>/dev/null || echo 'Unknown'" 2>/dev/null)
echo -e "${BLUE}目标系统信息:${NC}"
echo "$OS_INFO"

# 检查是否为root用户或有sudo权限
echo -e "${YELLOW}检查用户权限...${NC}"
if $SSH_CMD "id | grep -q 'uid=0(root)'" 2>/dev/null; then
    SUDO_CMD=""
    echo -e "${GREEN}✅ 当前用户为root${NC}"
elif $SSH_CMD "sudo -n true" 2>/dev/null; then
    SUDO_CMD="sudo"
    echo -e "${GREEN}✅ 当前用户有sudo权限${NC}"
else
    echo -e "${RED}❌ 当前用户不是root且无sudo权限${NC}"
    echo "请使用root用户或具有sudo权限的用户"
    exit 1
fi

# 创建远程安装脚本
echo -e "${YELLOW}创建远程安装脚本...${NC}"
REMOTE_SCRIPT=$(cat << 'EOF'
#!/bin/bash

# 远程服务器上的安装脚本
set -e

# 设置颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}开始在远程服务器上安装 Telegram 监控工具...${NC}"

# 检查系统类型
if command -v apt-get >/dev/null 2>&1; then
    PKG_MANAGER="apt-get"
    UPDATE_CMD="apt update"
    INSTALL_CMD="apt install -y"
elif command -v yum >/dev/null 2>&1; then
    PKG_MANAGER="yum"
    UPDATE_CMD="yum update -y"
    INSTALL_CMD="yum install -y"
else
    echo -e "${RED}不支持的系统类型${NC}"
    exit 1
fi

echo -e "${YELLOW}系统包管理器: $PKG_MANAGER${NC}"

# 安装必需的软件包
echo -e "${YELLOW}安装系统依赖...${NC}"
$UPDATE_CMD
$INSTALL_CMD git wget curl python3 python3-pip python3-venv

# 检查Git是否安装成功
if ! command -v git >/dev/null 2>&1; then
    echo -e "${RED}Git 安装失败${NC}"
    exit 1
fi

# 克隆项目
echo -e "${YELLOW}克隆项目仓库...${NC}"
cd /tmp
rm -rf telegram-monitor
git clone https://github.com/Kevin9181/telegram-monitor.git
cd telegram-monitor

# 设置执行权限
echo -e "${YELLOW}设置执行权限...${NC}"
chmod +x install.sh
chmod +x scripts/*.sh

# 创建交互式配置脚本
echo -e "${YELLOW}准备配置向导...${NC}"
echo "项目已下载到 /tmp/telegram-monitor"
echo "请运行以下命令完成安装:"
echo ""
echo "cd /tmp/telegram-monitor"
echo "sudo bash install.sh"
echo ""
echo -e "${GREEN}✅ 远程下载和准备完成！${NC}"
EOF
)

# 将安装脚本传输到远程服务器
echo -e "${YELLOW}传输安装脚本到远程服务器...${NC}"
echo "$REMOTE_SCRIPT" | $SSH_CMD "cat > /tmp/telegram_remote_install.sh && chmod +x /tmp/telegram_remote_install.sh"

# 执行远程安装脚本
echo -e "${YELLOW}在远程服务器上执行安装准备...${NC}"
$SSH_CMD "$SUDO_CMD bash /tmp/telegram_remote_install.sh"

echo ""
echo -e "${GREEN}✅ SSH传输完成！${NC}"
echo ""
echo -e "${YELLOW}下一步操作:${NC}"
echo "1. SSH连接到服务器："
echo "   ssh -p $SSH_PORT $SSH_USER@$SERVER_HOST"
echo ""
echo "2. 进入项目目录："
echo "   cd /tmp/telegram-monitor"
echo ""
echo "3. 运行安装脚本："
echo "   sudo bash install.sh"
echo ""
echo -e "${BLUE}或者运行以下一键命令:${NC}"
echo "$SSH_CMD 'cd /tmp/telegram-monitor && $SUDO_CMD bash install.sh'"
echo ""

# 询问是否立即进行交互式安装
read -p "是否要立即通过SSH进行交互式安装？(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}开始交互式安装...${NC}"
    $SSH_CMD "cd /tmp/telegram-monitor && $SUDO_CMD bash install.sh"
else
    echo -e "${YELLOW}稍后可以手动运行安装脚本${NC}"
fi

echo -e "${GREEN}�� SSH安装脚本执行完成！${NC}" 