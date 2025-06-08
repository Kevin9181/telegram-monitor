#!/bin/bash

# Telegram 群组监控转发工具安装脚本
# GitHub 版本

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
echo -e "${BLUE}  Telegram 群组监控转发工具安装器  ${NC}"
echo -e "${BLUE}           GitHub 版本             ${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WORK_DIR="/opt/telegram-monitor"

echo -e "${YELLOW}创建工作目录: $WORK_DIR${NC}"
mkdir -p $WORK_DIR

# 复制项目文件
echo -e "${YELLOW}复制项目文件...${NC}"
cp -r $SCRIPT_DIR/src/* $WORK_DIR/
cp -r $SCRIPT_DIR/config $WORK_DIR/
cp $SCRIPT_DIR/requirements.txt $WORK_DIR/

cd $WORK_DIR

# 安装系统依赖
echo -e "${YELLOW}安装系统依赖...${NC}"
apt update
apt install -y python3-pip python3-venv python3-full

# 创建虚拟环境
echo -e "${YELLOW}创建Python虚拟环境...${NC}"
python3 -m venv telegram_env
source telegram_env/bin/activate

echo -e "${YELLOW}安装 Python 依赖...${NC}"
pip install --upgrade pip
pip install -r requirements.txt

# 创建启动脚本
echo -e "${YELLOW}创建启动脚本...${NC}"
cat > $WORK_DIR/start_forwarder.sh << 'EOF'
#!/bin/bash
cd /opt/telegram-monitor
source telegram_env/bin/activate
python3 channel_forwarder.py
EOF

cat > $WORK_DIR/start_bot_manager.sh << 'EOF'
#!/bin/bash
cd /opt/telegram-monitor
source telegram_env/bin/activate
python3 bot_manager.py
EOF

cat > $WORK_DIR/start_login_helper.sh << 'EOF'
#!/bin/bash
cd /opt/telegram-monitor
source telegram_env/bin/activate
python3 login_helper.py
EOF

# 设置权限
chmod +x $WORK_DIR/*.py
chmod +x $WORK_DIR/*.sh

# 复制系统服务文件
echo -e "${YELLOW}安装系统服务...${NC}"
cp $SCRIPT_DIR/systemd/*.service /etc/systemd/system/

# 更新服务文件中的路径
sed -i "s|/opt/telegram-monitor|$WORK_DIR|g" /etc/systemd/system/channel_forwarder.service
sed -i "s|/opt/telegram-monitor|$WORK_DIR|g" /etc/systemd/system/bot_manager.service

# 重新加载systemd
systemctl daemon-reload

# 启用服务
systemctl enable channel_forwarder.service
systemctl enable bot_manager.service

# 配置部分
echo ""
echo -e "${GREEN}现在进行配置${NC}"
echo ""

# 检查是否已有配置文件
if [ -f "$WORK_DIR/config/config.json" ]; then
    echo -e "${YELLOW}检测到已存在配置文件${NC}"
    read -p "是否要重新配置？(y/n): " reconfigure
    if [ "$reconfigure" != "y" ]; then
        echo -e "${GREEN}使用现有配置${NC}"
    else
        mv $WORK_DIR/config/config.json $WORK_DIR/config/config.json.bak.$(date +%Y%m%d_%H%M%S)
        bash $SCRIPT_DIR/scripts/configure.sh
    fi
else
    bash $SCRIPT_DIR/scripts/configure.sh
fi

# 登录
echo ""
echo -e "${GREEN}现在进行Telegram账号登录...${NC}"
echo -e "${YELLOW}请按照提示完成 Telegram 登录认证${NC}"
echo ""

cd $WORK_DIR
./start_login_helper.sh

# 询问是否登录成功
echo ""
while true; do
    read -p "登录是否成功？(y/n): " yn
    case $yn in
        [Yy]* ) 
            echo -e "${GREEN}开始启动系统服务...${NC}"
            
            # 启动服务
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
            
            break
            ;;
        [Nn]* ) 
            echo -e "${RED}请手动运行登录助手:${NC}"
            echo -e "${BLUE}cd ${WORK_DIR} && ./start_login_helper.sh${NC}"
            break
            ;;
        * ) echo "请输入 y 或 n";;
    esac
done

echo ""
echo -e "${GREEN}✅ 安装完成！${NC}"
echo ""
echo -e "${YELLOW}常用命令:${NC}"
echo -e "${BLUE}查看日志: ${NC}journalctl -u channel_forwarder -f"
echo -e "${BLUE}重启服务: ${NC}systemctl restart channel_forwarder"
echo -e "${BLUE}停止服务: ${NC}systemctl stop channel_forwarder bot_manager"
echo ""
echo -e "${YELLOW}使用您的Bot进行管理:${NC}"
echo -e "在Telegram中找到您的Bot，发送 /help 查看命令"
echo "" 