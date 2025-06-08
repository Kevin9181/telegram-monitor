#!/bin/bash

# 启动所有服务

echo "启动 Telegram 监控转发服务..."
sudo systemctl start channel_forwarder
echo "✅ channel_forwarder 已启动"

echo "启动 Bot 管理服务..."
sudo systemctl start bot_manager
echo "✅ bot_manager 已启动"

echo ""
echo "查看服务状态:"
sudo systemctl status channel_forwarder --no-pager | head -n 5
echo ""
sudo systemctl status bot_manager --no-pager | head -n 5 