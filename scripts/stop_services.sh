#!/bin/bash

# 停止所有服务

echo "停止 Telegram 监控转发服务..."
sudo systemctl stop channel_forwarder
echo "✅ channel_forwarder 已停止"

echo "停止 Bot 管理服务..."
sudo systemctl stop bot_manager
echo "✅ bot_manager 已停止"

echo ""
echo "服务状态:"
sudo systemctl status channel_forwarder --no-pager | head -n 3
sudo systemctl status bot_manager --no-pager | head -n 3 