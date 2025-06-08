#!/bin/bash

# Telegram 监控工具 - 一键安装脚本
# 先安装程序，后配置参数

set -e

# 设置颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================${NC}"
echo -e "${BLUE}   Telegram 监控工具 一键安装      ${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 root 权限运行此脚本${NC}"
    exit 1
fi

echo -e "${YELLOW}开始安装依赖和下载项目...${NC}"

# 更新系统并安装依赖
echo -e "${YELLOW}[1/6] 更新系统并安装依赖...${NC}"
apt update && apt install -y python3-pip python3-venv python3-full git wget curl

# 安装Python依赖
echo -e "${YELLOW}[2/6] 安装Python依赖...${NC}"
pip3 install --break-system-packages telethon python-telegram-bot

# 下载项目
echo -e "${YELLOW}[3/6] 下载项目...${NC}"
cd /tmp
rm -rf telegram-monitor
git clone https://github.com/Kevin9181/telegram-monitor.git
cd telegram-monitor

# 设置权限
echo -e "${YELLOW}[4/6] 设置权限...${NC}"
chmod +x install.sh scripts/*.sh

# 创建工作目录并复制文件
echo -e "${YELLOW}[5/6] 创建工作目录...${NC}"
mkdir -p /opt/telegram-monitor
cp -r * /opt/telegram-monitor/
cd /opt/telegram-monitor

# 安装系统服务
echo -e "${YELLOW}[6/6] 安装系统服务...${NC}"
cp systemd/*.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable channel_forwarder.service
systemctl enable bot_manager.service

echo -e "${GREEN}✅ 程序安装完成！${NC}"
echo ""
echo -e "${BLUE}现在需要配置 Telegram API 信息${NC}"
echo ""
echo -e "${YELLOW}请按照以下步骤配置:${NC}"
echo ""
echo "1. 获取 Telegram API 信息:"
echo "   - API ID/Hash: 访问 https://my.telegram.org/apps"
echo "   - Bot Token: 找 @BotFather 创建机器人"
echo "   - 用户ID: 找 @userinfobot 获取你的用户ID"
echo ""
echo "2. 设置环境变量:"
echo -e "${GREEN}export TG_API_ID='你的API_ID'${NC}"
echo -e "${GREEN}export TG_API_HASH='你的API_Hash'${NC}"
echo -e "${GREEN}export TG_BOT_TOKEN='你的Bot_Token'${NC}"
echo -e "${GREEN}export TG_ADMIN_ID='你的用户ID'${NC}"
echo -e "${GREEN}export TG_KEYWORDS='重要 通知 紧急'${NC}"
echo -e "${GREEN}export TG_WATCH_IDS='channelname -1001234567890'${NC}"
echo -e "${GREEN}export TG_TARGET_IDS='123456789 -1009876543210'${NC}"
echo ""
echo "3. 运行配置脚本:"
echo -e "${GREEN}bash /opt/telegram-monitor/scripts/configure_non_interactive.sh${NC}"
echo ""
echo "4. 启动服务:"
echo -e "${GREEN}systemctl start channel_forwarder bot_manager${NC}"
echo ""
echo -e "${BLUE}完整配置示例:${NC}"
echo -e "${YELLOW}# 复制粘贴下面的命令，替换成你的真实信息${NC}"
cat << 'EOF'

# 设置你的配置信息
export TG_API_ID='12345678'
export TG_API_HASH='your_api_hash_here'
export TG_BOT_TOKEN='1234567890:your_bot_token_here'
export TG_ADMIN_ID='123456789'
export TG_KEYWORDS='重要 通知 紧急'
export TG_WATCH_IDS='channelname -1001234567890'
export TG_TARGET_IDS='123456789 -1009876543210'

# 应用配置
bash /opt/telegram-monitor/scripts/configure_non_interactive.sh

# 启动服务
systemctl start channel_forwarder bot_manager

# 查看状态
systemctl status channel_forwarder
systemctl status bot_manager

EOF

echo ""
echo -e "${GREEN}🎉 安装完成！请按照上面的说明进行配置。${NC}" 