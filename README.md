# Telegram 群组监控转发工具

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python Version](https://img.shields.io/badge/python-3.8%2B-blue)](https://www.python.org/downloads/)

一个基于 Telethon 和 Python-Telegram-Bot 的 Telegram 群组监控和消息转发工具。支持关键词过滤、多目标转发、消息超链接等功能。

## ✨ 功能特点

- 📡 监控多个群组和频道
- 🔍 基于关键词过滤消息
- 📤 支持多个转发目标
- 🤖 提供 Telegram Bot 管理界面
- 🔐 用户权限白名单控制
- 🚀 系统服务自动启动
- 📎 生成原始消息的超链接
- 💬 显示详细的消息来源信息

## 📋 系统要求

- Ubuntu/Debian 系统
- Python 3.8+
- Root 权限（用于安装系统服务）
- Telegram API 凭据

## 🚀 快速开始

### 1. 获取 Telegram API 凭据

1. 访问 https://my.telegram.org/apps
2. 登录您的 Telegram 账号
3. 创建一个新应用
4. 记录 `api_id` 和 `api_hash`

### 2. 创建 Telegram Bot

1. 在 Telegram 中找到 [@BotFather](https://t.me/botfather)
2. 发送 `/newbot` 创建新机器人
3. 按提示设置机器人名称和用户名
4. 记录机器人的 `token`

### 3. 安装方式

#### 方式一：本地安装

```bash
# 克隆仓库
git clone https://github.com/Kevin9181/telegram-monitor.git
cd telegram-monitor

# 设置执行权限
chmod +x install.sh scripts/*.sh

# 运行安装脚本
sudo bash install.sh
```

#### 方式二：SSH远程安装

通过SSH连接远程服务器进行安装：

```bash
# 下载SSH安装脚本
wget https://raw.githubusercontent.com/Kevin9181/telegram-monitor/main/ssh_install.sh

# 使用SSH密钥认证
bash ssh_install.sh -h <服务器IP> -u <用户名> -k <私钥路径>

# 使用密码认证
bash ssh_install.sh -h <服务器IP> -u <用户名> -p

# 指定SSH端口
bash ssh_install.sh -h <服务器IP> -u <用户名> -k <私钥路径> -P 2222
```

#### 方式三：一键在线安装

直接从网络运行安装脚本：

```bash
# 快速安装（推荐 - 修复版）
export TG_API_ID='你的API_ID'
export TG_API_HASH='你的API_Hash'
export TG_BOT_TOKEN='你的Bot_Token'
export TG_ADMIN_ID='你的用户ID'
export TG_KEYWORDS='重要 通知 紧急'
export TG_WATCH_IDS='channelname -1001234567890'
export TG_TARGET_IDS='123456789 -1009876543210'
curl -sSL https://raw.githubusercontent.com/Kevin9181/telegram-monitor/main/quick_install_fixed.sh | bash

# 或者SSH自动安装
curl -sSL https://raw.githubusercontent.com/Kevin9181/telegram-monitor/main/ssh_auto_install.sh | bash -s -- -h <服务器IP> -u <用户名> -k <私钥路径>
```

#### 方式四：增强版安装脚本（🔗 消息源定位功能）

使用带有消息源定位功能的增强版安装脚本：

```bash
# 下载增强版安装脚本
curl -sSL https://raw.githubusercontent.com/Kevin9181/telegram-monitor/main/telegram_monitor_installer_enhanced.sh -o telegram_installer.sh

# 设置执行权限并运行
chmod +x telegram_installer.sh
sudo bash telegram_installer.sh
```

**增强版特性：**
- 🔗 自动生成消息直达超链接
- 📍 支持公开频道和私人群组的精确定位
- 🎯 一键跳转到原始消息位置，无需手动爬楼
- 📋 完整的消息来源信息显示
- ⚡ 集成完整的安装和配置流程

#### 方式五：一键SSH安装指令（🚀 最简单）

直接在服务器终端运行一条命令完成所有安装：

```bash
apt update && apt install -y python3-pip && \
wget https://raw.githubusercontent.com/Kevin9181/telegram-monitor/main/telegram_monitor_installer_enhanced.sh -O install.sh && \
chmod +x install.sh && \
pip3 install --break-system-packages telethon python-telegram-bot && \
./install.sh
```

**适用场景：**
- ✅ 新服务器快速部署
- ✅ 一键完成所有步骤
- ✅ 自动安装系统依赖
- ✅ 包含增强版消息定位功能

安装过程中会提示您输入：
- Telegram API ID
- Telegram API Hash
- Bot Token
- 管理员 ID
- 监控关键词
- 监控群组/频道
- 转发目标

### 4. 手动配置（可选）

如果需要手动配置，复制配置模板：

```bash
cp config/config.example.json config/config.json
```

编辑配置文件：

```json
{
  "api_id": "YOUR_API_ID",
  "api_hash": "YOUR_API_HASH",
  "bot_token": "YOUR_BOT_TOKEN",
  "target_ids": [-1002243984935, 165067365],
  "keywords": ["重要", "通知", "紧急"],
  "watch_ids": ["channelname", "-1001234567890"],
  "whitelist": [123456789]
}
```

## 📱 Bot 命令

| 命令 | 说明 | 权限 |
|------|------|------|
| `/start` | 启动机器人 | 所有用户 |
| `/help` | 显示帮助菜单 | 白名单用户 |
| `/show` | 显示当前配置 | 白名单用户 |
| `/addkw <关键词>` | 添加关键词 | 白名单用户 |
| `/delkw <关键词>` | 删除关键词 | 白名单用户 |
| `/addgroup <群组ID>` | 添加转发目标 | 白名单用户 |
| `/delgroup <群组ID>` | 删除转发目标 | 白名单用户 |
| `/addwatch <群组ID/用户名>` | 添加监听群组 | 白名单用户 |
| `/delwatch <群组ID/用户名>` | 删除监听群组 | 白名单用户 |
| `/allow <用户ID>` | 添加白名单用户 | 仅管理员 |
| `/unallow <用户ID>` | 移除白名单用户 | 仅管理员 |

## 🔧 系统管理

### 服务管理

```bash
# 启动服务
sudo systemctl start channel_forwarder
sudo systemctl start bot_manager

# 停止服务
sudo systemctl stop channel_forwarder
sudo systemctl stop bot_manager

# 重启服务
sudo systemctl restart channel_forwarder
sudo systemctl restart bot_manager

# 查看服务状态
sudo systemctl status channel_forwarder
sudo systemctl status bot_manager
```

### 查看日志

```bash
# 实时查看转发服务日志
sudo journalctl -u channel_forwarder -f

# 实时查看Bot管理器日志
sudo journalctl -u bot_manager -f
```

### 更新程序

```bash
# 拉取最新代码
git pull

# 运行更新脚本
sudo bash scripts/update.sh
```

## 🚀 SSH远程安装详解

### SSH安装优势

- ✅ 无需登录远程服务器
- ✅ 自动检测系统类型
- ✅ 一键完成所有配置
- ✅ 支持密钥和密码认证
- ✅ 自动启动系统服务

### SSH安装步骤

#### 1. 准备SSH连接信息

确保你有以下信息：
- 服务器IP地址或域名
- SSH用户名（建议使用root或有sudo权限的用户）
- SSH私钥文件路径 或 准备输入密码

#### 2. 运行SSH安装脚本

**使用SSH密钥（推荐）：**
```bash
# 下载并运行
curl -sSL https://raw.githubusercontent.com/Kevin9181/telegram-monitor/main/ssh_auto_install.sh | bash -s -- -h 192.168.1.100 -u root -k ~/.ssh/id_rsa

# 或者分步执行
wget https://raw.githubusercontent.com/Kevin9181/telegram-monitor/main/ssh_install.sh
bash ssh_install.sh -h 192.168.1.100 -u root -k ~/.ssh/id_rsa
```

**使用密码认证：**
```bash
bash ssh_install.sh -h 192.168.1.100 -u root -p
```

**自定义SSH端口：**
```bash
bash ssh_install.sh -h example.com -u ubuntu -k ~/.ssh/id_rsa -P 2222
```

#### 3. 配置过程

脚本会自动：
1. 测试SSH连接
2. 检查系统类型和权限
3. 安装系统依赖（git, python3等）
4. 下载项目代码
5. 引导你配置Telegram API信息
6. 自动完成安装和启动服务

#### 4. 配置信息

安装过程中需要提供：
- **Telegram API ID** - 从 https://my.telegram.org/apps 获取
- **Telegram API Hash** - 从同一页面获取
- **Bot Token** - 从 @BotFather 获取
- **管理员用户ID** - 使用 @userinfobot 获取
- **监控关键词** - 空格分隔，如：重要 通知 紧急
- **监控群组** - 空格分隔，如：channelname -1001234567890
- **转发目标** - 空格分隔的用户ID或群组ID

### SSH安装示例

```bash
# 完整示例
curl -sSL https://raw.githubusercontent.com/Kevin9181/telegram-monitor/main/ssh_auto_install.sh | bash -s -- -h 192.168.1.100 -u root -k ~/.ssh/id_rsa

# 按提示输入配置信息
Telegram API ID: 12345678
Telegram API Hash: abcdef1234567890abcdef1234567890
Bot Token: 1234567890:ABCdefGHIjklMNOpqrsTUVwxyz
管理员用户ID: 123456789
监控关键词(空格分隔): 重要 通知 紧急 警告
监控群组/频道(空格分隔): techchannel -1001234567890
转发目标ID(空格分隔): 123456789 -1009876543210
```

### 安装后管理

```bash
# 查看服务状态
ssh root@192.168.1.100 'systemctl status channel_forwarder'

# 查看实时日志
ssh root@192.168.1.100 'journalctl -u channel_forwarder -f'

# 重启服务
ssh root@192.168.1.100 'systemctl restart channel_forwarder bot_manager'

# 停止服务
ssh root@192.168.1.100 'systemctl stop channel_forwarder bot_manager'
```

## 📂 项目结构

```
telegram-monitor/
├── README.md              # 项目说明文档
├── LICENSE               # MIT 开源协议
├── install.sh            # 一键安装脚本
├── telegram_monitor_installer_enhanced.sh  # 增强版安装脚本（带消息源定位）
├── .gitignore           # Git 忽略文件
├── requirements.txt      # Python 依赖
├── src/                 # 源代码目录
│   ├── channel_forwarder.py  # 消息监控转发
│   ├── bot_manager.py        # Bot 管理器
│   └── login_helper.py       # 登录助手
├── config/              # 配置文件目录
│   └── config.example.json   # 配置模板
├── scripts/             # 脚本目录
│   ├── update.sh            # 更新脚本
│   ├── start_services.sh    # 启动脚本
│   └── stop_services.sh     # 停止脚本
└── systemd/             # 系统服务文件
    ├── channel_forwarder.service
    └── bot_manager.service
```

## 🔗 消息转发格式

转发的消息包含以下信息：

```
📢 消息来源: @channelname (频道名称)
👤 发送者: @username
🕐 时间: 2024-01-01 12:00:00
🔑 匹配关键词: 重要
🔗 原始消息: 点击查看
──────────────────────────────
[转发的原始消息内容]
```

## ⚠️ 注意事项

1. **账号安全**：使用个人账号进行自动化操作需谨慎，避免频繁操作导致账号被限制
2. **隐私保护**：请勿监控未经授权的私有群组
3. **消息链接**：
   - 公开群组/频道的链接任何人都可以访问
   - 私有群组的链接仅群组成员可以访问
4. **配置备份**：建议定期备份 `config/config.json` 文件

## 🛠️ 故障排除

### 常见问题

#### 1. 无限循环错误 "API ID 不能为空且必须是数字"

**问题**: 在SSH或非交互式环境中运行时出现无限循环

**解决方案**: 使用修复版安装脚本
```bash
# 方法1: 使用环境变量配置
export TG_API_ID='你的API_ID'
export TG_API_HASH='你的API_Hash'
export TG_BOT_TOKEN='你的Bot_Token'
export TG_ADMIN_ID='你的用户ID'
export TG_WATCH_IDS='channelname -1001234567890'
export TG_TARGET_IDS='123456789 -1009876543210'
curl -sSL https://raw.githubusercontent.com/Kevin9181/telegram-monitor/main/quick_install_fixed.sh | bash

# 方法2: 手动配置
cd /tmp/telegram-monitor
cp config/config.example.json config/config.json
# 编辑配置文件后运行
SKIP_CONFIG=1 sudo bash install.sh
```

#### 2. SSH连接失败

**问题**: SSH连接被拒绝或超时

**解决方案**: 
- 检查服务器IP和端口
- 验证SSH密钥或密码
- 确保服务器允许SSH连接

#### 3. Python依赖安装失败

**问题**: pip安装失败

**解决方案**:
```bash
# Ubuntu/Debian
sudo apt update && sudo apt install -y python3-pip python3-venv python3-full

# 使用--break-system-packages参数
pip3 install --break-system-packages telethon python-telegram-bot
```

#### 4. 服务启动失败

**问题**: systemctl服务无法启动

**解决方案**:
```bash
# 检查日志
journalctl -u channel_forwarder -n 50
journalctl -u bot_manager -n 50

# 手动测试
cd /opt/telegram-monitor
./start_forwarder.sh
```

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🙏 致谢

- [Telethon](https://github.com/LonamiWebs/Telethon) - Telegram 客户端库
- [python-telegram-bot](https://github.com/python-telegram-bot/python-telegram-bot) - Telegram Bot API 库

---

如有问题或建议，请提交 [Issue](https://github.com/Kevin9181/telegram-monitor/issues) 