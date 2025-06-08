#!/bin/bash

# Telegram 监控工具 - 一键快速安装脚本
# 使用方法: curl -sSL https://raw.githubusercontent.com/Kevin9181/telegram-monitor/main/quick_install.sh | bash

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
    echo "例如: sudo bash quick_install.sh"
    exit 1
fi

echo -e "${YELLOW}开始一键安装...${NC}"

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
echo -e "${YELLOW}设置权限...${NC}"
chmod +x install.sh
chmod +x scripts/*.sh

# 安装Python依赖
echo -e "${YELLOW}安装Python依赖...${NC}"
pip3 install --break-system-packages telethon python-telegram-bot

echo -e "${GREEN}✅ 依赖安装完成！${NC}"
echo ""
echo -e "${YELLOW}现在运行完整安装脚本...${NC}"

# 运行完整安装脚本
./install.sh

echo -e "${GREEN}🎉 一键安装完成！${NC}" 