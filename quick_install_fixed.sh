#!/bin/bash

# Telegram 监控工具 - 一键快速安装脚本 (修复版)
# 避免无限循环问题，使用环境变量配置

set -e

# 设置颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}====================================${NC}"
echo -e "${BLUE}   Telegram 监控工具 一键安装      ${NC}"
echo -e "${BLUE}           修复版                   ${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""

# 检查是否为root用户
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 root 权限运行此脚本${NC}"
    exit 1
fi

# 检查是否设置了环境变量
if [ -z "$TG_API_ID" ]; then
    echo -e "${YELLOW}检测到首次安装，需要配置 Telegram API 信息${NC}"
    echo ""
    echo -e "${BLUE}请先设置环境变量，然后重新运行脚本:${NC}"
    echo ""
    echo "export TG_API_ID='你的API_ID'"
    echo "export TG_API_HASH='你的API_Hash'"
    echo "export TG_BOT_TOKEN='你的Bot_Token'"
    echo "export TG_ADMIN_ID='你的用户ID'"
    echo "export TG_KEYWORDS='重要 通知 紧急'  # 可选"
    echo "export TG_WATCH_IDS='channelname -1001234567890'"
    echo "export TG_TARGET_IDS='123456789 -1009876543210'"
    echo ""
    echo -e "${YELLOW}设置完成后运行:${NC}"
    echo "curl -sSL https://raw.githubusercontent.com/Kevin9181/telegram-monitor/main/quick_install_fixed.sh | bash"
    echo ""
    echo -e "${BLUE}获取信息的方法:${NC}"
    echo "- API ID/Hash: https://my.telegram.org/apps"
    echo "- Bot Token: 找 @BotFather"
    echo "- 用户ID: 找 @userinfobot"
    exit 1
fi

echo -e "${YELLOW}检测到配置信息，开始安装...${NC}"

# 更新系统并安装依赖
echo -e "${YELLOW}更新系统并安装依赖...${NC}"
apt update && apt install -y python3-pip python3-venv python3-full git wget curl

# 下载项目
echo -e "${YELLOW}下载项目...${NC}"
cd /tmp
rm -rf telegram-monitor
git clone https://github.com/Kevin9181/telegram-monitor.git
cd telegram-monitor

# 设置权限
chmod +x install.sh scripts/*.sh

# 安装Python依赖
echo -e "${YELLOW}安装Python依赖...${NC}"
pip3 install --break-system-packages telethon python-telegram-bot

# 使用非交互式配置
echo -e "${YELLOW}创建配置文件...${NC}"
bash scripts/configure_non_interactive.sh

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ 配置创建成功${NC}"
else
    echo -e "${RED}❌ 配置创建失败${NC}"
    exit 1
fi

# 运行安装脚本（跳过交互式配置）
echo -e "${YELLOW}运行安装脚本...${NC}"
SKIP_CONFIG=1 bash install.sh

echo -e "${GREEN}🎉 一键安装完成！${NC}"
echo ""
echo -e "${YELLOW}服务状态:${NC}"
systemctl status channel_forwarder --no-pager | head -n 5
echo ""
systemctl status bot_manager --no-pager | head -n 5
echo ""
echo -e "${BLUE}管理命令:${NC}"
echo "查看日志: journalctl -u channel_forwarder -f"
echo "重启服务: systemctl restart channel_forwarder bot_manager"
echo "停止服务: systemctl stop channel_forwarder bot_manager" 