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

### 3. 一键安装

```bash
# 克隆仓库
git clone https://github.com/yourusername/telegram-monitor.git
cd telegram-monitor

# 运行安装脚本
sudo bash install.sh
```

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

## 📂 项目结构

```
telegram-monitor/
├── README.md              # 项目说明文档
├── LICENSE               # MIT 开源协议
├── install.sh            # 一键安装脚本
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

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🙏 致谢

- [Telethon](https://github.com/LonamiWebs/Telethon) - Telegram 客户端库
- [python-telegram-bot](https://github.com/python-telegram-bot/python-telegram-bot) - Telegram Bot API 库

---

如有问题或建议，请提交 [Issue](https://github.com/yourusername/telegram-monitor/issues) 