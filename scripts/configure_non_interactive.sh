#!/bin/bash

# 非交互式配置脚本 - 用于自动化安装
# 使用环境变量或命令行参数配置

# 设置颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

WORK_DIR="/opt/telegram-monitor"
CONFIG_FILE="$WORK_DIR/config/config.json"

echo -e "${GREEN}非交互式配置 Telegram 监控转发工具${NC}"
echo ""

# 检查是否提供了所有必需的参数
if [ -z "$TG_API_ID" ] || [ -z "$TG_API_HASH" ] || [ -z "$TG_BOT_TOKEN" ] || [ -z "$TG_ADMIN_ID" ] || [ -z "$TG_WATCH_IDS" ] || [ -z "$TG_TARGET_IDS" ]; then
    echo -e "${RED}错误: 缺少必需的环境变量${NC}"
    echo -e "${YELLOW}请设置以下环境变量:${NC}"
    echo "export TG_API_ID='your_api_id'"
    echo "export TG_API_HASH='your_api_hash'"
    echo "export TG_BOT_TOKEN='your_bot_token'"
    echo "export TG_ADMIN_ID='your_admin_id'"
    echo "export TG_KEYWORDS='重要 通知 紧急'  # 可选"
    echo "export TG_WATCH_IDS='channelname -1001234567890'"
    echo "export TG_TARGET_IDS='123456789 -1009876543210'"
    echo ""
    echo -e "${BLUE}然后重新运行: bash scripts/configure_non_interactive.sh${NC}"
    exit 1
fi

# 验证API ID是否为数字
if ! [[ "$TG_API_ID" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}错误: API ID 必须是数字${NC}"
    exit 1
fi

# 验证管理员ID是否为数字
if ! [[ "$TG_ADMIN_ID" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}错误: 管理员ID 必须是数字${NC}"
    exit 1
fi

# 设置默认关键词
if [ -z "$TG_KEYWORDS" ]; then
    TG_KEYWORDS="重要 通知"
fi

echo -e "${YELLOW}使用配置:${NC}"
echo "API ID: $TG_API_ID"
echo "API Hash: ${TG_API_HASH:0:8}..."
echo "Bot Token: ${TG_BOT_TOKEN:0:10}..."
echo "管理员ID: $TG_ADMIN_ID"
echo "关键词: $TG_KEYWORDS"
echo "监控源: $TG_WATCH_IDS"
echo "转发目标: $TG_TARGET_IDS"
echo ""

# 处理关键词数组
KEYWORDS_ARRAY=($TG_KEYWORDS)
KEYWORDS_JSON="["
for i in "${!KEYWORDS_ARRAY[@]}"; do
  KEYWORDS_JSON+="\"${KEYWORDS_ARRAY[i]}\""
  if [ $i -lt $((${#KEYWORDS_ARRAY[@]}-1)) ]; then
    KEYWORDS_JSON+=", "
  fi
done
KEYWORDS_JSON+="]"

# 处理监控源数组
WATCH_ARRAY=($TG_WATCH_IDS)
WATCH_JSON="["
for i in "${!WATCH_ARRAY[@]}"; do
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

# 处理转发目标数组
TARGET_ARRAY=($TG_TARGET_IDS)
TARGET_JSON="["
for i in "${!TARGET_ARRAY[@]}"; do
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
echo -e "${YELLOW}创建配置文件...${NC}"
mkdir -p $(dirname $CONFIG_FILE)
cat > $CONFIG_FILE << EOF
{
  "api_id": "${TG_API_ID}",
  "api_hash": "${TG_API_HASH}",
  "bot_token": "${TG_BOT_TOKEN}",
  "target_ids": ${TARGET_JSON},
  "keywords": ${KEYWORDS_JSON},
  "watch_ids": ${WATCH_JSON},
  "whitelist": [${TG_ADMIN_ID}]
}
EOF

echo -e "${GREEN}✅ 配置文件已创建！${NC}"
echo -e "${YELLOW}配置文件位置: ${CONFIG_FILE}${NC}"
echo "" 