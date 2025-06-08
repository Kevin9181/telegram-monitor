#!/bin/bash

# 更新脚本 - 用于更新已安装的程序

# 设置颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # 恢复默认颜色

# 检查是否为 root 用户运行
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}请使用 root 权限运行此脚本${NC}"
  echo "例如: sudo bash $0"
  exit 1
fi

echo -e "${BLUE}====================================${NC}"
echo -e "${BLUE}  更新 Telegram 监控转发工具       ${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORK_DIR="/opt/telegram-monitor"

# 检查工作目录是否存在
if [ ! -d "$WORK_DIR" ]; then
    echo -e "${RED}错误: 工作目录 $WORK_DIR 不存在${NC}"
    echo -e "${RED}请先运行安装脚本${NC}"
    exit 1
fi

cd $WORK_DIR

# 备份当前文件
echo -e "${YELLOW}备份当前文件...${NC}"
BACKUP_DIR="$WORK_DIR/backup/$(date +%Y%m%d_%H%M%S)"
mkdir -p $BACKUP_DIR
cp *.py $BACKUP_DIR/ 2>/dev/null

# 停止服务
echo -e "${YELLOW}停止服务...${NC}"
systemctl stop channel_forwarder
systemctl stop bot_manager

# 更新源代码文件
echo -e "${YELLOW}更新源代码文件...${NC}"
cp $SCRIPT_DIR/../src/*.py $WORK_DIR/

# 设置权限
chmod +x $WORK_DIR/*.py

# 激活虚拟环境并更新依赖
echo -e "${YELLOW}更新 Python 依赖...${NC}"
source $WORK_DIR/telegram_env/bin/activate
pip install --upgrade -r $SCRIPT_DIR/../requirements.txt

# 重启服务
echo -e "${YELLOW}重启服务...${NC}"
systemctl start channel_forwarder
sleep 2
systemctl start bot_manager
sleep 2

# 检查服务状态
echo ""
echo -e "${GREEN}服务状态:${NC}"
systemctl --no-pager status channel_forwarder | head -n 5
echo ""
systemctl --no-pager status bot_manager | head -n 5

echo ""
echo -e "${GREEN}✅ 更新完成！${NC}"
echo ""
echo -e "${YELLOW}备份文件保存在: ${BACKUP_DIR}${NC}"
echo -e "${BLUE}查看日志: ${NC}journalctl -u channel_forwarder -f"
echo "" 