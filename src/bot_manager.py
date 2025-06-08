#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'telegram_env/lib/python3.11/site-packages'))

from telegram import Update
from telegram.ext import ApplicationBuilder, CommandHandler, ContextTypes
import json
import logging

CONFIG_FILE = 'config/config.json'

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
        json.dump(config, f, indent=2, ensure_ascii=False)

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
        f"👤 白名单用户ID：\n{config['whitelist']}"
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
        "/help - 显示帮助菜单"
    )
    await update.message.reply_text(text)

# 启动命令
async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    text = (
        "👋 欢迎使用 Telegram 群组监控转发机器人!\n\n"
        "此机器人可以监控指定群组或频道的消息，"
        "根据关键词筛选并转发到指定目标。\n\n"
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
        logging.info("Bot管理器已启动")
        app.run_polling()
        
    except Exception as e:
        logging.error(f"发生错误: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main() 