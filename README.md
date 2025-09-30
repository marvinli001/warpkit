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
- **模块化设计** - 系统工具、网络工具、包管理等独立模块
- **美观界面** - 丰富的颜色主题和现代化的终端 UI
- **一键安装** - 支持 curl/wget 远程安装，全局命令调用
- **自动更新** - 智能更新检测，自动保持最新版本
- **跨平台支持** - 支持主流 Linux 发行版和多种架构

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

#### 🛠️ 系统工具
- **实时系统状态** - CPU、内存、磁盘实时监控
- **进程管理** - 查看和管理系统进程
- **磁盘使用情况** - 文件系统和目录大小分析
- **系统负载历史** - 负载监控和性能分析
- **软件源管理** 🌟
  - 支持 100+ 国内外镜像源（阿里云、腾讯云、清华、MIT等）
  - 三大区域选择：国内、教育网、海外
  - 自动检测公网/内网地址切换
  - 支持 Ubuntu/Debian、CentOS/RHEL/Fedora、Arch/Manjaro
  - 自动备份原配置
- **SWAP内存管理** 🌟
  - 自定义大小创建SWAP
  - 自动检测可用磁盘空间
  - 单个/批量释放SWAP
  - SWAP状态查看
  - 开机自动挂载配置

#### 📦 包管理
- 自动检测包管理器 (apt, yum, pacman 等)
- 软件包搜索和安装
- 系统更新检查
- 依赖关系分析
- 包缓存清理

#### 🌐 网络工具
- **DNS修复** - DNS查询测试和配置管理
- **防火墙管理** - 防火墙规则配置和状态查看
- **网络性能测试** - 带宽和延迟测试
- **BBR内核加速** - 一键启用BBR TCP拥塞控制
- **流媒体解锁检测** 🌟
  - 检测 Netflix、Disney+、YouTube、Hulu 等平台
  - 动态下载最新检测脚本
  - 支持 IPv4/IPv6 测试
- **回程路由检测** 🌟
  - 检测三大运营商（电信、联通、移动）回程路由
  - 自动安装检测工具
  - 智能路径分析

#### 📋 日志查看
- 系统日志实时查看
- 日志过滤和搜索
- 多种日志格式支持
- 日志导出功能
- 错误日志快速定位

#### 🔧 脚本管理
- 自定义脚本管理
- 快速执行常用脚本
- 脚本模板创建

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

### v1.1.0 (2025-01-XX)

#### 新增
- 🌟 软件源管理功能
  - 100+ 国内外镜像源支持
  - 自动检测公网/内网地址
  - 跨发行版支持
- 🌟 SWAP内存管理功能
  - 自定义大小创建
  - 空间验证和自动检测
  - 批量管理和状态监控
- 🌟 流媒体解锁检测
  - 集成 RegionRestrictionCheck 项目
  - 支持主流流媒体平台检测
- 🌟 回程路由检测
  - 集成 oneclickvirt/backtrace 工具
  - 三网回程路由分析

#### 优化
- 重命名"系统监控"为"系统工具"
- 移除冗余的内存分析和网络连接功能
- 改进错误处理和用户提示
- 增强跨平台兼容性

### v1.0.0 (2024-12-XX)

#### 新增
- 初始版本发布
- 支持主流 Linux 发行版自动检测
- 交互式方向键导航界面
- 动态进度条和状态显示
- 系统工具模块
- 包管理功能
- 网络工具集
- 日志查看器
- 一键安装脚本
- BBR内核加速
- DNS修复和防火墙管理

## 故障排除

### 模块功能无法加载

如果菜单选项没有显示完整功能（比如网络工具只显示简单网络状态），可能是模块加载问题。

**启用调试模式查看详情**：
```bash
# 临时启用调试模式
WARPKIT_DEBUG=true warpkit

# 或导出环境变量
export WARPKIT_DEBUG=true
warpkit
```

**手动更新所有文件**：
```bash
# 使用内置更新功能（推荐）
warpkit --update

# 或重新安装
curl -fsSL https://raw.githubusercontent.com/marvinli001/warpkit/master/install.sh | bash
```

**检查模块文件**：
```bash
# 检查模块目录
ls -la /usr/local/lib/warpkit/modules/
# 或
ls -la ~/.local/lib/warpkit/modules/

# 确保模块文件有执行权限
chmod +x /usr/local/lib/warpkit/modules/*.sh
```

### 更新后功能不可用

更新功能会自动更新主程序和所有模块文件。如果更新后功能仍不可用：

1. 检查是否有多个安装位置
2. 清除旧的安装
3. 重新执行安装脚本

```bash
# 查找所有warpkit安装
which -a warpkit

# 重新安装
curl -fsSL https://raw.githubusercontent.com/marvinli001/warpkit/master/install.sh | bash
```

## 问题反馈

如果你发现了 bug 或有功能建议，请通过以下方式反馈：

- [GitHub Issues](https://github.com/marvinli001/warpkit/issues)
- [GitHub Discussions](https://github.com/marvinli001/warpkit/discussions)

## 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 致谢

- 感谢 [Claude Code CLI](https://claude.ai/code) 提供的交互设计灵感
- 感谢 [RegionRestrictionCheck](https://github.com/lmc999/RegionRestrictionCheck) 提供流媒体检测功能
- 感谢 [oneclickvirt/backtrace](https://github.com/oneclickvirt/backtrace) 提供回程路由检测工具
- 感谢所有开源社区的贡献者

## 相关链接

- [项目主页](https://github.com/marvinli001/warpkit)
- [文档网站](https://marvinli001.github.io/warpkit)
- [发布页面](https://github.com/marvinli001/warpkit/releases)

---

<div align="center">

**如果这个项目对你有帮助，请给个 Star 支持一下！**

</div>
