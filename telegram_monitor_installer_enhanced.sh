#!/bin/bash

# Telegram 群组监控转发工具安装脚本 - 增强版(带消息超链接)
# 作者: 沙龙新加坡

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
echo -e "${BLUE}      增强版 v3.0 (带消息超链接)     ${NC}"
echo -e "${BLUE}====================================${NC}"
echo ""

# 创建工作目录
WORK_DIR="/opt/telegram-monitor"
echo -e "${YELLOW}创建工作目录: $WORK_DIR${NC}"
mkdir -p $WORK_DIR
cd $WORK_DIR

# 安装依赖
echo -e "${YELLOW}安装系统依赖...${NC}"
apt update
apt install -y python3-pip python3-venv python3-full

# 创建虚拟环境
echo -e "${YELLOW}创建Python虚拟环境...${NC}"
python3 -m venv telegram_env
source telegram_env/bin/activate

echo -e "${YELLOW}安装 Python 依赖...${NC}"
pip install --upgrade pip
pip install telethon python-telegram-bot

# 创建 README.md
echo -e "${YELLOW}创建 README.md${NC}"
cat > $WORK_DIR/README.md << 'EOF'
# Telegram 群组监控转发工具 - 增强版

这是一个基于 Telethon 和 Python-Telegram-Bot 的 Telegram 群组监控和消息转发工具。它能够监控指定的群组或频道，根据关键词过滤消息，并将匹配的消息转发到指定目标。

## 功能特点

- 监控多个群组和频道
- 基于关键词过滤消息
- 支持多个转发目标
- 提供 Telegram Bot 管理界面
- 用户权限白名单控制
- 系统服务自动启动
- 显示消息来源信息
- **🔗 消息直达超链接** - 点击即可跳转到原始消息位置

## 新增功能 v3.0

### 消息超链接功能
- 自动为每条转发消息生成直达链接
- 支持公开频道和私人群组
- 点击链接直接跳转到原消息，无需爬楼
- 智能链接格式识别和构建

### 转发消息格式
```
📢 消息来源: @channelname (频道标题)
👤 发送者: @username
🕐 时间: 2024-XX-XX XX:XX:XX
🔑 匹配关键词: 重要
🔗 [点击直达原消息](https://t.me/channelname/123)
──────────────────────────────
[原始消息内容]
```

## 使用说明

### Bot 命令

- `/addkw <关键词>` - 添加关键词
- `/delkw <关键词>` - 删除关键词
- `/addgroup <群组ID>` - 添加转发目标
- `/delgroup <群组ID>` - 删除目标
- `/addwatch <群组ID或用户名>` - 添加监听群组
- `/delwatch <群组ID或用户名>` - 删除监听群组
- `/allow <用户ID>` - 添加白名单（仅OWNER）
- `/unallow <用户ID>` - 移除白名单（仅OWNER）
- `/show` - 显示当前配置
- `/help` - 帮助菜单

## 注意事项

- 首次运行需要进行 Telegram 登录认证
- 使用个人账号进行自动化操作需谨慎，避免频繁操作导致账号被限制
- 确保配置文件中的白名单至少包含一个管理员ID
- 点击消息链接需要在已加入的群组/频道中才能查看
EOF

# 创建配置文件模板
echo -e "${YELLOW}创建配置文件模板...${NC}"
cat > $WORK_DIR/config.example.json << 'EOF'
{
  "api_id": "YOUR_API_ID",
  "api_hash": "YOUR_API_HASH",
  "bot_token": "YOUR_BOT_TOKEN",
  "target_ids": [-1002243984935, 165067365],
  "keywords": ["example", "keyword1", "keyword2"],
  "watch_ids": ["channelname", "groupname"],
  "whitelist": [123456789]
}
EOF

# 创建带来源信息和消息超链接的 channel_forwarder.py
echo -e "${YELLOW}创建 channel_forwarder.py (带消息超链接)${NC}"
cat > $WORK_DIR/channel_forwarder.py << 'EOF'
#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'telegram_env/lib/python3.11/site-packages'))

from telethon import TelegramClient, events
from datetime import datetime
import json
import asyncio
import signal

CONFIG_FILE = 'config.json'

def load_config():
    try:
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"错误: 未找到配置文件 {CONFIG_FILE}")
        print("请从 config.example.json 复制一份并填写相关信息")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"错误: 配置文件 {CONFIG_FILE} 格式不正确")
        sys.exit(1)

# 全局变量
client = None
running = True

def signal_handler(signum, frame):
    global running, client
    print("\n收到停止信号，正在优雅关闭...")
    running = False
    if client and client.is_connected():
        asyncio.create_task(client.disconnect())

# 注册信号处理器
signal.signal(signal.SIGINT, signal_handler)
signal.signal(signal.SIGTERM, signal_handler)

async def get_message_link(chat, message_id):
    """构建消息链接"""
    try:
        if hasattr(chat, 'username') and chat.username:
            # 公开频道/群组，使用 @username
            return f"https://t.me/{chat.username}/{message_id}"
        else:
            # 私人群组或频道，使用 c/ 格式
            # 移除负号并转换为正数
            chat_id_str = str(chat.id).lstrip('-')
            if chat_id_str.startswith('100'):
                # 超级群组或频道，移除前缀 100
                chat_id_str = chat_id_str[3:]
            return f"https://t.me/c/{chat_id_str}/{message_id}"
    except Exception as e:
        print(f"构建消息链接失败: {e}")
        return None

async def main():
    global client, running
    
    # 加载配置
    config = load_config()
    
    # 从配置文件获取API凭据
    api_id = config.get('api_id')
    api_hash = config.get('api_hash')
    
    if not api_id or not api_hash:
        print("错误: 请在配置文件中设置有效的 api_id 和 api_hash")
        print("您可以从 https://my.telegram.org/apps 获取这些信息")
        sys.exit(1)
    
    # 创建客户端实例
    client = TelegramClient('channel_forward_session', api_id, api_hash)
    
    @client.on(events.NewMessage)
    async def handler(event):
        if not running:
            return
            
        try:
            # 每次处理消息时重新加载配置，以便实时更新关键词等
            config = load_config()
            
            # 获取消息文本
            msg = event.message.message
            if not msg:
                return
            
            # 获取来源信息
            from_chat = getattr(event.chat, 'username', None) or str(getattr(event, 'chat_id', ''))
            
            # 检查是否为监控目标
            if from_chat not in config["watch_ids"] and str(event.chat_id) not in config["watch_ids"]:
                return
            
            # 检查关键词
            for keyword in config["keywords"]:
                if keyword.lower() in msg.lower():
                    print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] 命中关键词: {keyword}")
                    print(f"来源: {from_chat}")
                    print(f"消息内容: {msg[:100]}...")  # 只显示消息前100个字符
                    
                    # 获取详细的来源信息
                    try:
                        chat_entity = await client.get_entity(event.chat_id)
                        
                        # 构建来源信息
                        if hasattr(chat_entity, 'username') and chat_entity.username:
                            source_info = f"@{chat_entity.username}"
                            if hasattr(chat_entity, 'title'):
                                source_info += f" ({chat_entity.title})"
                        elif hasattr(chat_entity, 'title'):
                            source_info = chat_entity.title
                        else:
                            source_info = f"群组ID: {event.chat_id}"
                        
                        # 获取发送者信息
                        sender_info = ""
                        if event.sender:
                            if hasattr(event.sender, 'username') and event.sender.username:
                                sender_info = f"@{event.sender.username}"
                            elif hasattr(event.sender, 'first_name'):
                                sender_info = event.sender.first_name
                                if hasattr(event.sender, 'last_name') and event.sender.last_name:
                                    sender_info += f" {event.sender.last_name}"
                            else:
                                sender_info = f"用户ID: {event.sender_id}"
                        
                        # 构建消息链接
                        message_link = await get_message_link(chat_entity, event.message.id)
                        
                        # 构建带来源信息和链接的消息
                        source_header = f"📢 消息来源: {source_info}"
                        if sender_info:
                            source_header += f"\n👤 发送者: {sender_info}"
                        source_header += f"\n🕐 时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
                        source_header += f"\n🔑 匹配关键词: {keyword}"
                        
                        # 添加消息链接
                        if message_link:
                            source_header += f"\n🔗 [点击直达原消息]({message_link})"
                        
                        source_header += "\n" + "─" * 30 + "\n"
                        
                        # 转发到所有目标
                        for target in config["target_ids"]:
                            try:
                                # 先发送来源信息（使用 Markdown 格式以支持超链接）
                                await client.send_message(target, source_header, parse_mode='markdown')
                                # 再转发原始消息
                                await client.forward_messages(target, event.message)
                                print(f"✅ 成功转发到 {target} (包含来源信息和消息链接)")
                            except Exception as e:
                                print(f"❌ 转发到 {target} 失败: {e}")
                                # 如果 Markdown 解析失败，尝试使用纯文本
                                try:
                                    simple_header = source_header.replace('[点击直达原消息]', '点击直达原消息').replace('(', '').replace(')', '')
                                    if message_link:
                                        simple_header = simple_header.replace('点击直达原消息', f'点击直达原消息: {message_link}')
                                    await client.send_message(target, simple_header)
                                    await client.forward_messages(target, event.message)
                                    print(f"✅ 成功转发到 {target} (纯文本格式)")
                                except Exception as e2:
                                    print(f"❌ 纯文本转发也失败: {e2}")
                                
                    except Exception as e:
                        print(f"❌ 获取来源信息失败: {e}")
                        # 如果获取详细信息失败，使用简单的来源信息
                        simple_source = f"📢 消息来源: {from_chat}\n🕐 时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n🔑 匹配关键词: {keyword}\n" + "─" * 30 + "\n"
                        
                        for target in config["target_ids"]:
                            try:
                                await client.send_message(target, simple_source)
                                await client.forward_messages(target, event.message)
                                print(f"✅ 成功转发到 {target} (简单来源信息)")
                            except Exception as e:
                                print(f"❌ 转发到 {target} 失败: {e}")
                    
                    break  # 匹配一个关键词就跳出循环
                    
        except Exception as e:
            print(f"处理消息时发生错误: {e}")
    
    print(">>> 正在监听关键词转发 ...")
    print(">>> 支持消息直达超链接功能")
    print(">>> 如果是首次运行，请按照提示完成 Telegram 登录")
    print(">>> 按 Ctrl+C 可停止运行")
    
    try:
        await client.start()
        print("✅ 客户端启动成功，开始监听...")
        
        # 保持运行
        while running:
            await asyncio.sleep(1)
            
    except KeyboardInterrupt:
        print("\n收到键盘中断信号")
    except Exception as e:
        print(f"发生错误: {e}")
    finally:
        if client and client.is_connected():
            await client.disconnect()
        print("程序已停止")

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n程序已停止")
        sys.exit(0)
    except Exception as e:
        print(f"发生错误: {e}")
        sys.exit(1)
EOF

# 创建 bot_manager.py
echo -e "${YELLOW}创建 bot_manager.py${NC}"
cat > $WORK_DIR/bot_manager.py << 'EOF'
#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'telegram_env/lib/python3.11/site-packages'))

from telegram import Update
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes
import json
import logging

CONFIG_FILE = 'config.json'

# 设置日志记录
logging.basicConfig(
    format='%(asctime)s - %(levelname)s - %(message)s',
    level=logging.INFO
)

def load_config():
    try:
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        logging.error(f"未找到配置文件 {CONFIG_FILE}")
        logging.error("请从 config.example.json 复制一份并填写相关信息")
        sys.exit(1)
    except json.JSONDecodeError:
        logging.error(f"配置文件 {CONFIG_FILE} 格式不正确")
        sys.exit(1)

def save_config(config):
    with open(CONFIG_FILE, 'w') as f:
        json.dump(config, f, indent=2)

def is_allowed(uid):
    """检查用户是否在白名单中"""
    return uid in load_config().get("whitelist", [])

async def add_common(update, context, key):
    """添加通用配置项"""
    if not is_allowed(update.effective_user.id):
        await update.message.reply_text("❌ 权限不足")
        return
    
    try:
        value = context.args[0]
        config = load_config()
        
        # 如果是数字ID，转换为整数
        if key in ["target_ids", "whitelist"] and value.lstrip('-').isdigit():
            value = int(value)
        
        if value not in config[key]:
            config[key].append(value)
            save_config(config)
            await update.message.reply_text(f"✅ 已添加到 {key}: {value}")
        else:
            await update.message.reply_text("⚠️ 已存在")
    except IndexError:
        await update.message.reply_text("❌ 格式错误，请提供参数")
    except Exception as e:
        await update.message.reply_text(f"❌ 发生错误: {e}")

async def del_common(update, context, key):
    """删除通用配置项"""
    if not is_allowed(update.effective_user.id):
        await update.message.reply_text("❌ 权限不足")
        return
    
    try:
        value = context.args[0]
        config = load_config()
        
        # 如果是数字ID，转换为整数
        if key in ["target_ids", "whitelist"] and value.lstrip('-').isdigit():
            value = int(value)
        
        if value in config[key]:
            config[key].remove(value)
            save_config(config)
            await update.message.reply_text(f"✅ 已从 {key} 删除: {value}")
        else:
            await update.message.reply_text("⚠️ 不存在")
    except IndexError:
        await update.message.reply_text("❌ 格式错误，请提供参数")
    except Exception as e:
        await update.message.reply_text(f"❌ 发生错误: {e}")

# 添加关键词
async def add_kw(update, context):
    await add_common(update, context, "keywords")

# 删除关键词
async def del_kw(update, context):
    await del_common(update, context, "keywords")

# 添加转发目标
async def add_group(update, context):
    await add_common(update, context, "target_ids")

# 删除转发目标
async def del_group(update, context):
    await del_common(update, context, "target_ids")

# 添加监听源
async def add_watch(update, context):
    await add_common(update, context, "watch_ids")

# 删除监听源
async def del_watch(update, context):
    await del_common(update, context, "watch_ids")

# 显示当前配置
async def show_config(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_allowed(update.effective_user.id):
        await update.message.reply_text("❌ 权限不足")
        return
    
    config = load_config()
    text = (
        f"📋 当前配置:\n\n"
        f"🔑 关键词：\n{config['keywords']}\n\n"
        f"🎯 转发目标：\n{config['target_ids']}\n\n"
        f"👀 监听源群组/频道：\n{config['watch_ids']}\n\n"
        f"👤 白名单用户ID：\n{config['whitelist']}\n\n"
        f"🔗 增强功能：支持消息直达超链接"
    )
    await update.message.reply_text(text)

# 允许用户使用机器人
async def allow_user(update: Update, context: ContextTypes.DEFAULT_TYPE):
    config = load_config()
    
    # 只允许第一个白名单用户(管理员)添加其他用户
    if update.effective_user.id != config['whitelist'][0]:
        await update.message.reply_text("❌ 权限不足")
        return
    
    try:
        uid = int(context.args[0])
        if uid not in config["whitelist"]:
            config["whitelist"].append(uid)
            save_config(config)
            await update.message.reply_text(f"✅ 已允许用户 {uid}")
        else:
            await update.message.reply_text("⚠️ 该用户已在白名单中")
    except IndexError:
        await update.message.reply_text("❌ 格式错误，请提供用户ID")
    except ValueError:
        await update.message.reply_text("❌ 用户ID必须为数字")
    except Exception as e:
        await update.message.reply_text(f"❌ 发生错误: {e}")

# 移除白名单用户
async def unallow_user(update: Update, context: ContextTypes.DEFAULT_TYPE):
    config = load_config()
    
    # 只允许第一个白名单用户(管理员)移除其他用户
    if update.effective_user.id != config['whitelist'][0]:
        await update.message.reply_text("❌ 权限不足")
        return
    
    try:
        uid = int(context.args[0])
        # 防止移除自己(第一个白名单用户)
        if uid == config['whitelist'][0]:
            await update.message.reply_text("❌ 不能移除首个白名单用户(管理员)")
            return
            
        if uid in config["whitelist"]:
            config["whitelist"].remove(uid)
            save_config(config)
            await update.message.reply_text(f"✅ 已移除用户 {uid}")
        else:
            await update.message.reply_text("⚠️ 该用户不在白名单中")
    except IndexError:
        await update.message.reply_text("❌ 格式错误，请提供用户ID")
    except ValueError:
        await update.message.reply_text("❌ 用户ID必须为数字")
    except Exception as e:
        await update.message.reply_text(f"❌ 发生错误: {e}")

# 帮助命令
async def help_cmd(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not is_allowed(update.effective_user.id):
        await update.message.reply_text("❌ 权限不足")
        return
    
    text = (
        "🔍 命令列表:\n\n"
        "/addkw <关键词> - 添加关键词\n"
        "/delkw <关键词> - 删除关键词\n"
        "/addgroup <群组ID> - 添加转发目标\n"
        "/delgroup <群组ID> - 删除转发目标\n"
        "/addwatch <群组ID或用户名> - 添加监听群组\n"
        "/delwatch <群组ID或用户名> - 删除监听群组\n"
        "/allow <用户ID> - 添加白名单用户（仅管理员）\n"
        "/unallow <用户ID> - 移除白名单用户（仅管理员）\n"
        "/show - 显示当前配置\n"
        "/help - 显示帮助菜单\n\n"
        "🔗 v3.0 新功能：\n"
        "• 转发消息现在包含直达原消息的超链接\n"
        "• 点击链接可直接跳转到原始消息位置\n"
        "• 无需再手动爬楼寻找消息"
    )
    await update.message.reply_text(text)

# 启动命令
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    text = (
        "👋 欢迎使用 Telegram 群组监控转发机器人!\n\n"
        "🔗 v3.0 增强版特性：\n"
        "• 智能关键词监控和转发\n"
        "• 消息直达超链接功能\n"
        "• 一键跳转到原始消息\n"
        "• 完整的来源信息显示\n\n"
        "此机器人可以监控指定群组或频道的消息，"
        "根据关键词筛选并转发到指定目标，"
        "转发的消息包含可点击的直达链接。\n\n"
        "使用 /help 查看可用命令。"
    )
    await update.message.reply_text(text)

def main():
    try:
        # 从配置文件获取机器人令牌
        config = load_config()
        token = config.get('bot_token')
        
        if not token:
            logging.error("错误: 请在配置文件中设置有效的 bot_token")
            sys.exit(1)
        
        # 检查白名单是否为空
        if not config.get('whitelist'):
            logging.error("错误: 请在配置文件中添加至少一个白名单用户ID")
            sys.exit(1)
        
        # 创建应用
        app = ApplicationBuilder().token(token).build()
        
        # 添加命令处理程序
        app.add_handler(CommandHandler("start", start))
        app.add_handler(CommandHandler("addkw", add_kw))
        app.add_handler(CommandHandler("delkw", del_kw))
        app.add_handler(CommandHandler("addgroup", add_group))
        app.add_handler(CommandHandler("delgroup", del_group))
        app.add_handler(CommandHandler("addwatch", add_watch))
        app.add_handler(CommandHandler("delwatch", del_watch))
        app.add_handler(CommandHandler("allow", allow_user))
        app.add_handler(CommandHandler("unallow", unallow_user))
        app.add_handler(CommandHandler("show", show_config))
        app.add_handler(CommandHandler("help", help_cmd))
        
        # 启动机器人
        logging.info("Bot管理器已启动 - v3.0 增强版")
        app.run_polling()
        
    except Exception as e:
        logging.error(f"发生错误: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
EOF

# 创建登录助手
echo -e "${YELLOW}创建登录助手 login_helper.py${NC}"
cat > $WORK_DIR/login_helper.py << 'EOF'
#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'telegram_env/lib/python3.11/site-packages'))

import asyncio
from telethon import TelegramClient
import json

CONFIG_FILE = 'config.json'

def load_config():
    try:
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    except FileNotFoundError:
        print(f"错误: 未找到配置文件 {CONFIG_FILE}")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"错误: 配置文件 {CONFIG_FILE} 格式不正确")
        sys.exit(1)

async def login_telegram():
    config = load_config()
    
    api_id = config.get('api_id')
    api_hash = config.get('api_hash')
    
    if not api_id or not api_hash:
        print("错误: 请在配置文件中设置有效的 api_id 和 api_hash")
        sys.exit(1)
    
    print("开始Telegram登录过程...")
    print("创建客户端连接...")
    
    client = TelegramClient('channel_forward_session', api_id, api_hash)
    
    try:
        print("正在连接到Telegram...")
        await client.connect()
        
        if not await client.is_user_authorized():
            print("需要进行用户认证")
            
            # 请求手机号
            phone = input("请输入您的手机号码（包括国家代码，如 +8613812345678）: ")
            
            try:
                sent_code = await client.send_code_request(phone)
                print(f"验证码已发送到 {phone}")
                
                # 请求验证码
                code = input("请输入验证码: ")
                
                try:
                    await client.sign_in(phone, code)
                    print("✅ 登录成功！")
                    
                except Exception as e:
                    if "Two-steps verification" in str(e) or "password" in str(e).lower():
                        password = input("请输入两步验证密码: ")
                        await client.sign_in(password=password)
                        print("✅ 登录成功！")
                    else:
                        print(f"登录失败: {e}")
                        return False
                        
            except Exception as e:
                print(f"发送验证码失败: {e}")
                return False
        else:
            print("✅ 已经登录！")
        
        # 测试连接
        me = await client.get_me()
        print(f"当前登录用户: {me.first_name} (@{me.username})")
        
        return True
        
    except Exception as e:
        print(f"连接失败: {e}")
        return False
    finally:
        await client.disconnect()

if __name__ == "__main__":
    try:
        result = asyncio.run(login_telegram())
        if result:
            print("\n🎉 登录完成！现在可以启动服务了。")
            print("\n运行以下命令启动服务:")
            print("systemctl start channel_forwarder")
            print("systemctl start bot_manager")
        else:
            print("\n❌ 登录失败，请检查配置或网络连接")
    except KeyboardInterrupt:
        print("\n操作已取消")
    except Exception as e:
        print(f"\n发生错误: {e}")
EOF

# 创建启动脚本
echo -e "${YELLOW}创建启动脚本${NC}"
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
echo -e "${YELLOW}设置文件权限...${NC}"
chmod +x $WORK_DIR/channel_forwarder.py
chmod +x $WORK_DIR/bot_manager.py
chmod +x $WORK_DIR/login_helper.py
chmod +x $WORK_DIR/start_forwarder.sh
chmod +x $WORK_DIR/start_bot_manager.sh
chmod +x $WORK_DIR/start_login_helper.sh

# 创建服务文件
echo -e "${YELLOW}创建系统服务...${NC}"

# 创建channel_forwarder服务
cat > /etc/systemd/system/channel_forwarder.service << EOF
[Unit]
Description=Telegram Channel Forwarder Service (Enhanced with Message Links)
After=network.target

[Service]
ExecStart=${WORK_DIR}/start_forwarder.sh
WorkingDirectory=${WORK_DIR}
Restart=always
RestartSec=10
User=root
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
WantedBy=multi-user.target
EOF

# 创建bot_manager服务
cat > /etc/systemd/system/bot_manager.service << EOF
[Unit]
Description=Telegram Bot Manager Service (Enhanced v3.0)
After=network.target

[Service]
ExecStart=${WORK_DIR}/start_bot_manager.sh
WorkingDirectory=${WORK_DIR}
Restart=always
RestartSec=10
User=root
Environment=PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
WantedBy=multi-user.target
EOF

# 重新加载systemd
systemctl daemon-reload

# 启用服务
systemctl enable channel_forwarder.service
systemctl enable bot_manager.service

# 交互式配置部分
echo ""
echo -e "${GREEN}现在进行Telegram API配置${NC}"
echo ""

# 获取Telegram API ID
echo -e "${YELLOW}请输入您的 Telegram API ID${NC}"
echo "可从 https://my.telegram.org/apps 获取"
while true; do
    read -p "API ID: " API_ID
    if [ ! -z "$API_ID" ] && [[ "$API_ID" =~ ^[0-9]+$ ]]; then
        break
    else
        echo -e "${RED}API ID 不能为空且必须是数字${NC}"
    fi
done

# 获取Telegram API Hash
echo -e "${YELLOW}请输入您的 Telegram API Hash${NC}"
while true; do
    read -p "API Hash: " API_HASH
    if [ ! -z "$API_HASH" ]; then
        break
    else
        echo -e "${RED}API Hash 不能为空${NC}"
    fi
done

# 获取Bot Token
echo -e "${YELLOW}请输入您的 Telegram Bot Token${NC}"
echo "从 BotFather 获取"
while true; do
    read -p "Bot Token: " BOT_TOKEN
    if [ ! -z "$BOT_TOKEN" ]; then
        break
    else
        echo -e "${RED}Bot Token 不能为空${NC}"
    fi
done

# 获取管理员ID
echo -e "${YELLOW}请输入管理员的 Telegram 用户ID${NC}"
echo "可以使用 @userinfobot 获取您的用户ID"
while true; do
    read -p "管理员ID: " ADMIN_ID
    if [ ! -z "$ADMIN_ID" ] && [[ "$ADMIN_ID" =~ ^[0-9]+$ ]]; then
        break
    else
        echo -e "${RED}管理员ID 不能为空且必须是数字${NC}"
    fi
done

# 设置监控关键词
echo -e "${YELLOW}请输入要监控的关键词 (用空格分隔)${NC}"
echo "例如: 重要 通知 紧急"
read -p "关键词: " KEYWORDS

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
while true; do
    read -p "监控源: " WATCH_IDS
    if [ ! -z "$WATCH_IDS" ]; then
        break
    else
        echo -e "${RED}至少需要一个监控源${NC}"
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
while true; do
    read -p "转发目标: " TARGET_IDS
    if [ ! -z "$TARGET_IDS" ]; then
        break
    else
        echo -e "${RED}至少需要一个转发目标${NC}"
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
cat > $WORK_DIR/config.json << EOF
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
echo -e "${BLUE}🔗 v3.0 增强功能:${NC}"
echo -e "• 转发消息包含直达原消息的超链接"
echo -e "• 点击链接可直接跳转到原始消息位置"
echo -e "• 无需手动爬楼寻找消息"
echo ""

# 现在进行Telegram登录
echo -e "${GREEN}现在进行Telegram账号登录...${NC}"
echo -e "${YELLOW}请按照提示完成 Telegram 登录认证${NC}"
echo ""

cd $WORK_DIR

# 运行登录助手
echo -e "${BLUE}启动登录助手...${NC}"
./start_login_helper.sh

# 询问是否登录成功
echo ""
while true; do
    read -p "登录是否成功？(y/n): " yn
    case $yn in
        [Yy]* ) 
            echo -e "${GREEN}开始启动系统服务...${NC}"
            
            # 启动服务
            echo -e "${YELLOW}启动转发服务...${NC}"
            systemctl start channel_forwarder
            sleep 3
            
            echo -e "${YELLOW}启动Bot管理服务...${NC}"
            systemctl start bot_manager
            sleep 3
            
            # 检查服务状态
            echo ""
            echo -e "${GREEN}检查服务状态:${NC}"
            echo -e "${BLUE}转发服务状态:${NC}"
            systemctl --no-pager status channel_forwarder
            
            echo ""
            echo -e "${BLUE}Bot管理服务状态:${NC}"
            systemctl --no-pager status bot_manager
            
            break
            ;;
        [Nn]* ) 
            echo -e "${RED}请重新运行登录助手:${NC}"
            echo -e "${BLUE}cd ${WORK_DIR} && ./start_login_helper.sh${NC}"
            break
            ;;
        * ) echo "请输入 y 或 n";;
    esac
done

echo ""
echo -e "${GREEN}✅ 安装和配置完成！${NC}"
echo ""
echo -e "${BLUE}🔗 v3.0 增强版特性:${NC}"
echo -e "• 智能关键词监控和消息转发"
echo -e "• 消息直达超链接功能"
echo -e "• 完整的来源信息显示"
echo -e "• 一键跳转到原始消息"
echo ""
echo -e "${YELLOW}常用命令:${NC}"
echo -e "${BLUE}手动登录: ${NC}cd ${WORK_DIR} && ./start_login_helper.sh"
echo -e "${BLUE}启动服务: ${NC}systemctl start channel_forwarder && systemctl start bot_manager"
echo -e "${BLUE}停止服务: ${NC}systemctl stop channel_forwarder && systemctl stop bot_manager"
echo -e "${BLUE}查看日志: ${NC}journalctl -u channel_forwarder -f"
echo -e "${BLUE}重启服务: ${NC}systemctl restart channel_forwarder"
echo ""
echo -e "${YELLOW}使用您的Bot进行管理:${NC}"
echo -e "在Telegram中找到您的Bot，发送 /start 开始使用"
echo -e "发送 /help 查看所有可用命令"
echo ""
echo -e "${GREEN}项目文件位置: ${WORK_DIR}${NC}"
echo -e "${GREEN}配置文件: ${WORK_DIR}/config.json${NC}"
echo ""
echo -e "${BLUE}🎉 转发消息现在包含可点击的超链接，点击即可直达原消息！${NC}"
echo ""