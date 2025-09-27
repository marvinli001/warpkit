# WarpKit 安装指南

## 系统要求

### 支持的操作系统
- **Ubuntu** 18.04 LTS 或更高版本
- **Debian** 9 (Stretch) 或更高版本
- **CentOS** 7 或更高版本
- **RHEL** 7 或更高版本
- **Fedora** 30 或更高版本
- **Arch Linux** (Rolling Release)
- **SUSE/openSUSE** 15 或更高版本
- **Alpine Linux** 3.10 或更高版本

### 必需软件
- `bash` (4.0+)
- `curl` 或 `wget`
- `coreutils` (基础 Unix 工具)

### 可选软件
- `git` (用于开发和贡献)
- `systemd` (用于服务管理功能)

## 安装方法

### 方法一：一键安装（推荐）

这是最简单的安装方法，适合大多数用户：

```bash
# 使用 curl
curl -fsSL https://raw.githubusercontent.com/your-username/warpkit/main/install.sh | bash

# 使用 wget
wget -qO- https://raw.githubusercontent.com/your-username/warpkit/main/install.sh | bash
```

安装脚本会自动：
- 检测你的 Linux 发行版
- 选择合适的安装位置
- 配置 PATH 环境变量
- 创建必要的配置文件

### 方法二：手动安装

如果你想要更多控制，可以手动安装：

#### 1. 下载源码
```bash
# 克隆仓库
git clone https://github.com/your-username/warpkit.git
cd warpkit

# 或直接下载脚本
wget https://raw.githubusercontent.com/your-username/warpkit/main/warpkit.sh
```

#### 2. 选择安装位置

**系统级安装（需要 root 权限）：**
```bash
sudo cp warpkit.sh /usr/local/bin/warpkit
sudo chmod +x /usr/local/bin/warpkit
```

**用户级安装：**
```bash
mkdir -p ~/.local/bin
cp warpkit.sh ~/.local/bin/warpkit
chmod +x ~/.local/bin/warpkit
```

#### 3. 配置 PATH
```bash
# 对于 bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 对于 zsh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# 对于 fish
echo 'set -gx PATH $HOME/.local/bin $PATH' >> ~/.config/fish/config.fish
```

### 方法三：从发布包安装

1. 从 [Releases 页面](https://github.com/your-username/warpkit/releases) 下载最新版本
2. 解压并运行安装脚本：

```bash
tar -xzf warpkit-v1.0.0.tar.gz
cd warpkit-v1.0.0
bash install.sh
```

## 验证安装

安装完成后，验证 WarpKit 是否正确安装：

```bash
# 检查版本
warpkit --version

# 启动 WarpKit
warpkit
```

如果看到 WarpKit 的 Logo 和主菜单，说明安装成功！

## 配置

### 配置文件位置
WarpKit 的配置文件位于：
- **用户配置**: `~/.config/warpkit/config.conf`
- **系统配置**: `/etc/warpkit/config.conf`

### 初始配置
首次运行时，WarpKit 会自动创建默认配置文件：

```bash
# 主题设置
THEME=default

# 日志级别
LOG_LEVEL=info

# 自动更新检查
AUTO_UPDATE=true

# 语言设置
LANGUAGE=zh_CN
```

## 常见问题

### Q: 安装时提示"权限被拒绝"
A: 请确保你有写入目标目录的权限，或使用 `sudo` 进行系统级安装。

### Q: 命令找不到
A: 检查 PATH 环境变量是否包含安装目录：
```bash
echo $PATH | grep -o '[^:]*bin[^:]*'
```

### Q: 在某些发行版上字符显示异常
A: 确保你的终端支持 UTF-8 编码：
```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
```

### Q: 安装脚本下载失败
A: 检查网络连接，或手动下载文件：
```bash
# 手动下载
curl -O https://raw.githubusercontent.com/your-username/warpkit/main/warpkit.sh
chmod +x warpkit.sh
./warpkit.sh
```

## 卸载

如果需要卸载 WarpKit：

```bash
# 使用安装脚本卸载
curl -fsSL https://raw.githubusercontent.com/your-username/warpkit/main/install.sh | bash -s -- --uninstall

# 或手动卸载
rm -f /usr/local/bin/warpkit  # 系统级
rm -f ~/.local/bin/warpkit    # 用户级
rm -rf ~/.config/warpkit      # 配置文件
```

## 更新

WarpKit 支持多种更新方式：

### 自动更新
如果在配置中启用了自动更新检查，WarpKit 会在启动时检查新版本。

### 手动更新
```bash
# 重新运行安装脚本
curl -fsSL https://raw.githubusercontent.com/your-username/warpkit/main/install.sh | bash

# 或使用 git 更新
cd /path/to/warpkit
git pull origin main
```

## 开发环境安装

如果你想参与 WarpKit 的开发：

```bash
# 克隆仓库
git clone https://github.com/your-username/warpkit.git
cd warpkit

# 创建开发环境
./scripts/setup-dev.sh

# 运行测试
./tests/run-tests.sh
```

## 下一步

安装完成后，建议阅读：
- [使用手册](usage.md) - 学习如何使用各项功能
- [开发指南](development.md) - 了解如何扩展和定制 WarpKit