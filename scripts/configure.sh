#!/bin/bash

# 配置脚本 - 用于交互式创建配置文件

# 设置颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # 恢复默认颜色

WORK_DIR="/opt/telegram-monitor"
CONFIG_FILE="$WORK_DIR/config/config.json"

echo -e "${GREEN}开始配置 Telegram 监控转发工具${NC}"
echo ""

# 获取Telegram API ID
echo -e "${YELLOW}请输入您的 Telegram API ID${NC}"
echo "可从 https://my.telegram.org/apps 获取"
attempt=0
while true; do
    attempt=$((attempt + 1))
    if [ $attempt -gt 50 ]; then
        echo -e "${RED}错误: 尝试次数过多，可能运行在非交互式环境中${NC}"
        echo -e "${RED}请手动运行: cd /tmp/telegram-monitor && bash scripts/configure.sh${NC}"
        exit 1
    fi
    
    if read -t 30 -p "API ID: " API_ID; then
        if [ ! -z "$API_ID" ] && [[ "$API_ID" =~ ^[0-9]+$ ]]; then
            break
        else
            echo -e "${RED}API ID 不能为空且必须是数字${NC}"
        fi
    else
        echo -e "${RED}读取超时或输入错误${NC}"
        exit 1
    fi
done

# 获取Telegram API Hash
echo -e "${YELLOW}请输入您的 Telegram API Hash${NC}"
attempt=0
while true; do
    attempt=$((attempt + 1))
    if [ $attempt -gt 50 ]; then
        echo -e "${RED}错误: 尝试次数过多${NC}"
        exit 1
    fi
    
    if read -t 30 -p "API Hash: " API_HASH; then
        if [ ! -z "$API_HASH" ]; then
            break
        else
            echo -e "${RED}API Hash 不能为空${NC}"
        fi
    else
        echo -e "${RED}读取超时或输入错误${NC}"
        exit 1
    fi
done

# 获取Bot Token
echo -e "${YELLOW}请输入您的 Telegram Bot Token${NC}"
echo "从 BotFather 获取"
attempt=0
while true; do
    attempt=$((attempt + 1))
    if [ $attempt -gt 50 ]; then
        echo -e "${RED}错误: 尝试次数过多${NC}"
        exit 1
    fi
    
    if read -t 30 -p "Bot Token: " BOT_TOKEN; then
        if [ ! -z "$BOT_TOKEN" ]; then
            break
        else
            echo -e "${RED}Bot Token 不能为空${NC}"
        fi
    else
        echo -e "${RED}读取超时或输入错误${NC}"
        exit 1
    fi
done

# 获取管理员ID
echo -e "${YELLOW}请输入管理员的 Telegram 用户ID${NC}"
echo "可以使用 @userinfobot 获取您的用户ID"
attempt=0
while true; do
    attempt=$((attempt + 1))
    if [ $attempt -gt 50 ]; then
        echo -e "${RED}错误: 尝试次数过多${NC}"
        exit 1
    fi
    
    if read -t 30 -p "管理员ID: " ADMIN_ID; then
        if [ ! -z "$ADMIN_ID" ] && [[ "$ADMIN_ID" =~ ^[0-9]+$ ]]; then
            break
        else
            echo -e "${RED}管理员ID 不能为空且必须是数字${NC}"
        fi
    else
        echo -e "${RED}读取超时或输入错误${NC}"
        exit 1
    fi
done

# 设置监控关键词
echo -e "${YELLOW}请输入要监控的关键词 (用空格分隔)${NC}"
echo "例如: 重要 通知 紧急"
if ! read -t 30 -p "关键词: " KEYWORDS; then
    echo -e "${RED}读取超时，使用默认关键词${NC}"
    KEYWORDS=""
fi

if [ -z "$KEYWORDS" ]; then
    KEYWORDS="重要 通知"
    echo -e "${YELLOW}使用默认关键词: $KEYWORDS${NC}"
fi

KEYWORDS_ARRAY=($KEYWORDS)
KEYWORDS_JSON="["
for i in "${!KEYWORDS_ARRAY[@]}"; do
  KEYWORDS_JSON+="\"${KEYWORDS_ARRAY[i]}\""
  if [ $i -lt $((${#KEYWORDS_ARRAY[@]}-1)) ]; then
    KEYWORDS_JSON+=", "
  fi
done
KEYWORDS_JSON+="]"

# 设置监控的群组/频道
echo -e "${YELLOW}请输入要监控的群组或频道 (用空格分隔)${NC}"
echo "可以是用户名(如 channelname)或ID(如 -1001234567890)"
attempt=0
while true; do
    attempt=$((attempt + 1))
    if [ $attempt -gt 50 ]; then
        echo -e "${RED}错误: 尝试次数过多${NC}"
        exit 1
    fi
    
    if read -t 30 -p "监控源: " WATCH_IDS; then
        if [ ! -z "$WATCH_IDS" ]; then
            break
        else
            echo -e "${RED}至少需要一个监控源${NC}"
        fi
    else
        echo -e "${RED}读取超时或输入错误${NC}"
        exit 1
    fi
done

WATCH_ARRAY=($WATCH_IDS)
WATCH_JSON="["
for i in "${!WATCH_ARRAY[@]}"; do
  # 检查是否为数字ID
  if [[ ${WATCH_ARRAY[i]} =~ ^-?[0-9]+$ ]]; then
    WATCH_JSON+="${WATCH_ARRAY[i]}"
  else
    WATCH_JSON+="\"${WATCH_ARRAY[i]}\""
  fi
  if [ $i -lt $((${#WATCH_ARRAY[@]}-1)) ]; then
    WATCH_JSON+=", "
  fi
done
WATCH_JSON+="]"

# 设置转发目标
echo -e "${YELLOW}请输入消息转发目标 (用空格分隔)${NC}"
echo "可以是用户ID或群组ID，群组ID通常是负数"
attempt=0
while true; do
    attempt=$((attempt + 1))
    if [ $attempt -gt 50 ]; then
        echo -e "${RED}错误: 尝试次数过多${NC}"
        exit 1
    fi
    
    if read -t 30 -p "转发目标: " TARGET_IDS; then
        if [ ! -z "$TARGET_IDS" ]; then
            break
        else
            echo -e "${RED}至少需要一个转发目标${NC}"
        fi
    else
        echo -e "${RED}读取超时或输入错误${NC}"
        exit 1
    fi
done

TARGET_ARRAY=($TARGET_IDS)
TARGET_JSON="["
for i in "${!TARGET_ARRAY[@]}"; do
  # 检查是否为数字ID
  if [[ ${TARGET_ARRAY[i]} =~ ^-?[0-9]+$ ]]; then
    TARGET_JSON+="${TARGET_ARRAY[i]}"
  else
    TARGET_JSON+="\"${TARGET_ARRAY[i]}\""
  fi
  if [ $i -lt $((${#TARGET_ARRAY[@]}-1)) ]; then
    TARGET_JSON+=", "
  fi
done
TARGET_JSON+="]"

# 创建配置文件
echo -e "${YELLOW}正在创建配置文件...${NC}"
mkdir -p $(dirname $CONFIG_FILE)
cat > $CONFIG_FILE << EOF
{
  "api_id": "${API_ID}",
  "api_hash": "${API_HASH}",
  "bot_token": "${BOT_TOKEN}",
  "target_ids": ${TARGET_JSON},
  "keywords": ${KEYWORDS_JSON},
  "watch_ids": ${WATCH_JSON},
  "whitelist": [${ADMIN_ID}]
}
EOF

# 显示配置摘要
echo ""
echo -e "${GREEN}✅ 配置文件已创建！${NC}"
echo ""
echo -e "${YELLOW}配置摘要:${NC}"
echo -e "监控关键词: ${KEYWORDS_JSON}"
echo -e "监控源: ${WATCH_JSON}"
echo -e "转发目标: ${TARGET_JSON}"
echo -e "管理员ID: ${ADMIN_ID}"
echo "" 