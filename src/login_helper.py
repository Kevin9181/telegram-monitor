#!/usr/bin/env python3
import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'telegram_env/lib/python3.11/site-packages'))

import asyncio
from telethon import TelegramClient
import json

CONFIG_FILE = 'config/config.json'

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