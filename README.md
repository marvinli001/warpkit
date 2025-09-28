# WarpKit

<div align="center">

```
██╗    ██╗ █████╗ ██████╗ ██████╗ ██╗  ██╗██╗████████╗
██║    ██║██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝██║╚══██╔══╝
██║ █╗ ██║███████║██████╔╝██████╔╝█████╔╝ ██║   ██║
██║███╗██║██╔══██║██╔══██╗██╔═══╝ ██╔═██╗ ██║   ██║
╚███╔███╔╝██║  ██║██║  ██║██║     ██║  ██╗██║   ██║
 ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝   ╚═╝
```

**现代化的 Linux 服务运维工具**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/Platform-Linux-blue.svg)](https://www.linux.org/)
[![Shell](https://img.shields.io/badge/Shell-Bash-green.svg)](https://www.gnu.org/software/bash/)

</div>

## 特性

- **智能检测** - 自动识别 Linux 发行版、内核版本和系统架构
- **交互式界面** - 类似 Claude Code CLI 的方向键导航体验
- **动态显示** - 实时进度条、状态更新和加载动画
- **多功能集成** - 系统监控、服务管理、包管理等一站式解决方案
- **美观界面** - 丰富的颜色主题和现代化的终端 UI
- **一键安装** - 简单的安装脚本，支持全局命令调用
- **自动更新** - 智能更新检测，自动保持最新版本

## 支持的系统

| 发行版 | 版本 | 状态 |
|--------|------|------|
| Ubuntu | 18.04+ | 完全支持 |
| Debian | 9+ | 完全支持 |
| CentOS | 7+ | 完全支持 |
| RHEL | 7+ | 完全支持 |
| Fedora | 30+ | 完全支持 |
| Arch Linux | Rolling | 完全支持 |
| SUSE/openSUSE | 15+ | 完全支持 |
| Alpine Linux | 3.10+ | 完全支持 |

## 快速开始

### 一键安装

```bash
# 使用 curl
curl -fsSL https://raw.githubusercontent.com/marvinli001/warpkit/master/install.sh | bash

# 或使用 wget
wget -qO- https://raw.githubusercontent.com/marvinli001/warpkit/master/install.sh | bash
```

### 手动安装

```bash
# 克隆仓库
git clone https://github.com/marvinli001/warpkit.git
cd warpkit

# 推荐使用安装脚本
sudo bash install.sh

# 或手动安装到系统
sudo cp warpkit.sh /usr/local/bin/warpkit
sudo mkdir -p /usr/local/lib/warpkit
sudo cp -r modules /usr/local/lib/warpkit/
sudo chmod +x /usr/local/bin/warpkit
sudo chmod +x /usr/local/lib/warpkit/modules/*.sh

# 或手动安装到用户目录
mkdir -p ~/.local/bin ~/.local/lib/warpkit
cp warpkit.sh ~/.local/bin/warpkit
cp -r modules ~/.local/lib/warpkit/
chmod +x ~/.local/bin/warpkit
chmod +x ~/.local/lib/warpkit/modules/*.sh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### 验证安装

```bash
warpkit --version
```

## 使用方法

### 启动 WarpKit

```bash
warpkit
```

### 界面导航

- **↑/↓** - 上下选择菜单项
- **Enter** - 确认选择
- **q/Q** - 退出程序

### 主要功能

#### 系统监控
- 实时系统状态显示
- 内存使用情况
- 磁盘空间监控
- 系统负载信息

#### 服务管理
- 查看系统服务状态
- 启动/停止/重启服务
- 服务配置管理
- 自启动设置

#### 包管理
- 自动检测包管理器 (apt, yum, pacman 等)
- 软件包搜索和安装
- 系统更新检查
- 依赖关系分析

#### 网络工具
- 网络连接测试
- 端口扫描
- 网络配置查看
- 防火墙状态检查

#### 安全工具
- 登录历史分析
- 系统日志检查
- 文件权限验证
- 安全配置审计

#### 日志查看
- 系统日志实时查看
- 日志过滤和搜索
- 多种日志格式支持
- 日志导出功能

## 配置

WarpKit 的配置文件位于 `~/.config/warpkit/config.conf`

```bash
# 主题设置
THEME=default

# 日志级别 (debug, info, warning, error)
LOG_LEVEL=info

# 自动更新检查（每日首次启动时检查）
AUTO_UPDATE=true

# 更新检查频率（daily, weekly, never）
UPDATE_FREQUENCY=daily

# 语言设置
LANGUAGE=zh_CN
```

## 命令行选项

```bash
warpkit [选项]

选项:
  -h, --help     显示帮助信息
  -v, --version  显示版本信息
  -u, --update   检查并更新到最新版本
  --config       指定配置文件路径
  --theme        设置主题 (default, dark, light)
  --lang         设置语言 (zh_CN, en_US)
```

### 自动更新

WarpKit 内置了智能更新系统：

- **每日检查**: 每天首次启动时自动检查更新
- **手动更新**: 使用 `warpkit --update` 手动检查更新
- **安全备份**: 更新前自动备份当前版本
- **一键更新**: 发现新版本时可选择立即更新

```bash
# 检查并更新到最新版本
warpkit --update

# 查看当前版本
warpkit --version
```

## 开发

### 项目结构

```
warpkit/
├── warpkit.sh          # 主脚本文件
├── install.sh          # 安装脚本
├── README.md           # 项目文档
├── LICENSE             # 开源许可证
├── CHANGELOG.md        # 更新日志
├── docs/               # 详细文档
│   ├── installation.md # 安装指南
│   ├── usage.md        # 使用手册
│   └── development.md  # 开发指南
├── examples/           # 使用示例
├── tests/              # 测试脚本
└── scripts/            # 辅助脚本
    ├── build.sh        # 构建脚本
    └── deploy.sh       # 部署脚本
```

### 本地开发

```bash
# 克隆项目
git clone https://github.com/marvinli001/warpkit.git
cd warpkit

# 直接运行
./warpkit.sh

# 或者安装到本地测试
bash install.sh
```

### 测试

```bash
# 运行基础测试
./tests/basic_test.sh

# 运行兼容性测试
./tests/compatibility_test.sh
```

## 贡献

欢迎贡献代码！请遵循以下步骤：

1. Fork 这个仓库
2. 创建你的特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开一个 Pull Request

### 贡献指南

- 确保代码符合项目的编码规范
- 添加适当的测试用例
- 更新相关文档
- 遵循 [Conventional Commits](https://www.conventionalcommits.org/) 规范

## 更新日志

查看 [CHANGELOG.md](CHANGELOG.md) 了解详细的版本更新信息。

### v1.0.0 (2024-XX-XX)

#### 新增
- 初始版本发布
- 支持主流 Linux 发行版自动检测
- 交互式方向键导航界面
- 动态进度条和状态显示
- 系统监控功能
- 服务管理功能
- 包管理功能
- 网络工具集
- 安全工具集
- 日志查看器
- 一键安装脚本

## 问题反馈

如果你发现了 bug 或有功能建议，请通过以下方式反馈：

- [GitHub Issues](https://github.com/marvinli001/warpkit/issues)
- [GitHub Discussions](https://github.com/marvinli001/warpkit/discussions)

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 致谢

- 感谢 [Claude Code CLI](https://claude.ai/code) 提供的交互设计灵感
- 感谢所有开源社区的贡献者

## 相关链接

- [项目主页](https://github.com/marvinli001/warpkit)
- [文档网站](https://marvinli001.github.io/warpkit)
- [发布页面](https://github.com/marvinli001/warpkit/releases)

---

<div align="center">

**如果这个项目对你有帮助，请给个 Star 支持一下！**

</div>
