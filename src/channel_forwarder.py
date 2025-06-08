#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'telegram_env/lib/python3.11/site-packages'))

from telethon import TelegramClient, events
from datetime import datetime
import json
import asyncio
import signal

CONFIG_FILE = 'config/config.json'

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
                        
                        # 生成消息链接
                        message_link = ""
                        if hasattr(chat_entity, 'username') and chat_entity.username:
                            # 公开群组/频道的链接格式
                            message_link = f"https://t.me/{chat_entity.username}/{event.message.id}"
                        else:
                            # 私有群组的链接格式
                            # 需要去掉chat_id的负号和前面的100
                            chat_id_str = str(event.chat_id)
                            if chat_id_str.startswith('-100'):
                                chat_id_for_link = chat_id_str[4:]  # 去掉-100
                            elif chat_id_str.startswith('-'):
                                chat_id_for_link = chat_id_str[1:]  # 去掉负号
                            else:
                                chat_id_for_link = chat_id_str
                            message_link = f"https://t.me/c/{chat_id_for_link}/{event.message.id}"
                        
                        # 构建带来源信息的消息（使用HTML格式）
                        source_header = f"📢 <b>消息来源:</b> {source_info}"
                        if sender_info:
                            source_header += f"\n👤 <b>发送者:</b> {sender_info}"
                        source_header += f"\n🕐 <b>时间:</b> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
                        source_header += f"\n🔑 <b>匹配关键词:</b> {keyword}"
                        if message_link:
                            source_header += f"\n🔗 <b>原始消息:</b> <a href=\"{message_link}\">点击查看</a>"
                        source_header += "\n" + "─" * 30 + "\n"
                        
                        # 转发到所有目标
                        for target in config["target_ids"]:
                            try:
                                # 先发送来源信息（使用HTML格式）
                                await client.send_message(target, source_header, parse_mode='html')
                                # 再转发原始消息
                                await client.forward_messages(target, event.message)
                                print(f"✅ 成功转发到 {target} (包含来源信息和链接)")
                            except Exception as e:
                                print(f"❌ 转发到 {target} 失败: {e}")
                                
                    except Exception as e:
                        print(f"❌ 获取来源信息失败: {e}")
                        # 如果获取详细信息失败，使用简单的来源信息
                        simple_source = f"📢 <b>消息来源:</b> {from_chat}\n🕐 <b>时间:</b> {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n🔑 <b>匹配关键词:</b> {keyword}\n" + "─" * 30 + "\n"
                        
                        for target in config["target_ids"]:
                            try:
                                await client.send_message(target, simple_source, parse_mode='html')
                                await client.forward_messages(target, event.message)
                                print(f"✅ 成功转发到 {target} (简单来源信息)")
                            except Exception as e:
                                print(f"❌ 转发到 {target} 失败: {e}")
                    
                    break  # 匹配一个关键词就跳出循环
                    
        except Exception as e:
            print(f"处理消息时发生错误: {e}")
    
    print(">>> 正在监听关键词转发 ...")
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