#!/bin/bash

# WarpKit 安装脚本
# 使用方法: curl -fsSL https://raw.githubusercontent.com/marvinli001/warpkit/master/install.sh | bash

set -euo pipefail

# 设置UTF-8编码支持中文
export LANG=C.UTF-8
export LC_ALL=C.UTF-8

# 颜色定义
declare -r RED='\033[0;31m'
declare -r GREEN='\033[0;32m'
declare -r YELLOW='\033[0;33m'
declare -r BLUE='\033[0;34m'
declare -r PURPLE='\033[0;35m'
declare -r CYAN='\033[0;36m'
declare -r BOLD='\033[1m'
declare -r NC='\033[0m'

# 配置变量
declare -r WARPKIT_VERSION="1.0.0"
declare -r GITHUB_REPO="marvinli001/warpkit"
declare -r INSTALL_DIR="/usr/local/bin"
declare -r CONFIG_DIR="$HOME/.config/warpkit"
declare -r SCRIPT_NAME="warpkit"

# 打印Logo
print_logo() {
    echo -e "${CYAN}${BOLD}"
    echo "██╗    ██╗ █████╗ ██████╗ ██████╗ ██╗  ██╗██╗████████╗"
    echo "██║    ██║██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝██║╚══██╔══╝"
    echo "██║ █╗ ██║███████║██████╔╝██████╔╝█████╔╝ ██║   ██║   "
    echo "██║███╗██║██╔══██║██╔══██╗██╔═══╝ ██╔═██╗ ██║   ██║   "
    echo "╚███╔███╔╝██║  ██║██║  ██║██║     ██║  ██╗██║   ██║   "
    echo " ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝   ╚═╝   "
    echo -e "${NC}"
    echo -e "${YELLOW}WarpKit 安装程序 v${WARPKIT_VERSION}${NC}"
    echo ""
}

# 状态信息
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1" >&2
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# 进度条
show_progress() {
    local current=$1
    local total=$2
    local message=${3:-"安装中"}
    local width=40

    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))

    printf "\r${CYAN}%s: [" "$message"
    printf "%${completed}s" | tr ' ' '#'
    printf "%${remaining}s" | tr ' ' '-'
    printf "] %d%%${NC}" "$percentage"

    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# 检查系统要求
check_requirements() {
    log_info "检查系统要求..."

    # 检查操作系统
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        log_error "WarpKit 只支持 Linux 系统"
        exit 1
    fi

    # 检查必要命令
    local required_commands=("curl" "wget" "bash")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log_error "缺少必要命令: $cmd"
            exit 1
        fi
    done

    # 检查权限
    if [[ $EUID -eq 0 ]]; then
        log_warning "检测到以root用户运行，将安装到系统目录"
    else
        log_info "以普通用户运行，将安装到用户目录"
        INSTALL_DIR="$HOME/.local/bin"
    fi

    log_success "系统要求检查完成"
}

# 检测Linux发行版
detect_distro() {
    log_info "检测Linux发行版..."

    local distro="unknown"
    local version="unknown"

    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        distro="$ID"
        version="${VERSION_ID:-$VERSION}"
    elif [[ -f /etc/lsb-release ]]; then
        source /etc/lsb-release
        distro=$(echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]')
        version="$DISTRIB_RELEASE"
    fi

    log_success "检测到发行版: $distro $version"
}

# 创建目录
create_directories() {
    log_info "创建安装目录..."

    # 创建安装目录
    if [[ ! -d "$INSTALL_DIR" ]]; then
        mkdir -p "$INSTALL_DIR" || {
            log_error "无法创建安装目录: $INSTALL_DIR"
            exit 1
        }
    fi

    # 创建配置目录
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR" || {
            log_warning "无法创建配置目录: $CONFIG_DIR"
        }
    fi

    log_success "目录创建完成"
}

# 下载WarpKit脚本
download_warpkit() {
    log_info "下载WarpKit主脚本..."

    local temp_file="/tmp/warpkit_download.sh"
    local download_url="https://raw.githubusercontent.com/${GITHUB_REPO}/master/warpkit.sh"

    # 尝试使用curl下载
    if command -v curl >/dev/null 2>&1; then
        if curl -fsSL "$download_url" -o "$temp_file"; then
            log_success "使用curl下载完成"
        else
            log_error "curl下载失败，尝试使用wget"
            download_with_wget "$download_url" "$temp_file"
        fi
    # 否则使用wget
    elif command -v wget >/dev/null 2>&1; then
        download_with_wget "$download_url" "$temp_file"
    else
        log_error "无法找到curl或wget下载工具"
        exit 1
    fi

    # 验证下载文件
    if [[ ! -f "$temp_file" ]] || [[ ! -s "$temp_file" ]]; then
        log_error "下载文件验证失败"
        exit 1
    fi

    # 只输出文件路径，不输出日志信息到stdout
    printf "%s" "$temp_file"
}

# 使用wget下载
download_with_wget() {
    local url=$1
    local output=$2

    if wget -q "$url" -O "$output"; then
        log_success "使用wget下载完成"
    else
        log_error "wget下载失败"
        exit 1
    fi
}

# 安装脚本
install_script() {
    local temp_file=$1
    local target_file="$INSTALL_DIR/$SCRIPT_NAME"

    log_info "安装WarpKit到 $target_file..."

    # 复制文件
    if cp "$temp_file" "$target_file"; then
        log_success "脚本复制完成"
    else
        log_error "脚本复制失败"
        exit 1
    fi

    # 设置执行权限
    if chmod +x "$target_file"; then
        log_success "权限设置完成"
    else
        log_error "权限设置失败"
        exit 1
    fi

    # 清理临时文件
    rm -f "$temp_file"
}

# 配置PATH环境变量
configure_path() {
    log_info "配置PATH环境变量..."

    # 检查是否已在PATH中
    if echo "$PATH" | grep -q "$INSTALL_DIR"; then
        log_success "安装目录已在PATH中"
        return
    fi

    # 确定shell配置文件
    local shell_config=""
    case "$SHELL" in
        */bash)
            shell_config="$HOME/.bashrc"
            [[ -f "$HOME/.bash_profile" ]] && shell_config="$HOME/.bash_profile"
            ;;
        */zsh)
            shell_config="$HOME/.zshrc"
            ;;
        */fish)
            shell_config="$HOME/.config/fish/config.fish"
            ;;
        *)
            shell_config="$HOME/.profile"
            ;;
    esac

    # 添加到PATH
    if [[ -n "$shell_config" ]] && [[ -w "$shell_config" ]]; then
        echo "" >> "$shell_config"
        echo "# WarpKit PATH" >> "$shell_config"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$shell_config"
        log_success "PATH配置已添加到 $shell_config"
        log_warning "请运行 'source $shell_config' 或重新打开终端来生效"
    else
        log_warning "无法自动配置PATH，请手动添加 $INSTALL_DIR 到PATH环境变量"
    fi
}

# 创建配置文件
create_config() {
    log_info "创建配置文件..."

    local config_file="$CONFIG_DIR/config.conf"

    cat > "$config_file" << 'EOF'
# WarpKit 配置文件
# 创建时间: $(date)

# 主题设置
THEME=default

# 日志级别 (debug, info, warning, error)
LOG_LEVEL=info

# 自动更新检查
AUTO_UPDATE=true

# 语言设置
LANGUAGE=zh_CN
EOF

    log_success "配置文件创建完成: $config_file"
}

# 验证安装
verify_installation() {
    log_info "验证安装..."

    local warpkit_path=$(which warpkit 2>/dev/null || echo "")

    if [[ -n "$warpkit_path" ]] && [[ -x "$warpkit_path" ]]; then
        log_success "WarpKit安装成功: $warpkit_path"
        log_info "运行 'warpkit' 开始使用"
        return 0
    else
        log_warning "WarpKit安装完成，但未在PATH中找到"
        log_info "请确保 $INSTALL_DIR 在你的PATH环境变量中"
        log_info "或直接运行: $INSTALL_DIR/$SCRIPT_NAME"
        return 1
    fi
}

# 卸载功能
uninstall() {
    echo -e "${YELLOW}开始卸载WarpKit...${NC}"

    # 删除脚本文件
    if [[ -f "$INSTALL_DIR/$SCRIPT_NAME" ]]; then
        rm -f "$INSTALL_DIR/$SCRIPT_NAME"
        log_success "删除主脚本"
    fi

    # 删除配置目录
    if [[ -d "$CONFIG_DIR" ]]; then
        rm -rf "$CONFIG_DIR"
        log_success "删除配置目录"
    fi

    log_success "WarpKit卸载完成"
}

# 显示帮助
show_help() {
    echo "WarpKit 安装脚本"
    echo ""
    echo "用法:"
    echo "  $0                安装WarpKit"
    echo "  $0 --uninstall    卸载WarpKit"
    echo "  $0 --help         显示此帮助"
    echo ""
    echo "示例:"
    echo "  curl -fsSL https://raw.githubusercontent.com/$GITHUB_REPO/master/install.sh | bash"
    echo "  wget -qO- https://raw.githubusercontent.com/$GITHUB_REPO/master/install.sh | bash"
    echo ""
}

# 主安装流程
main_install() {
    local steps=(
        "检查系统要求"
        "检测发行版"
        "创建目录"
        "下载脚本"
        "安装脚本"
        "配置PATH"
        "创建配置"
        "验证安装"
    )

    print_logo

    echo -e "${BOLD}开始安装WarpKit...${NC}"
    echo ""

    local temp_file=""

    for i in "${!steps[@]}"; do
        show_progress $((i+1)) ${#steps[@]} "安装进度"
        sleep 0.5

        case $i in
            0) check_requirements ;;
            1) detect_distro ;;
            2) create_directories ;;
            3) temp_file=$(download_warpkit) ;;
            4) install_script "$temp_file" ;;
            5) configure_path ;;
            6) create_config ;;
            7) verify_installation ;;
        esac
    done

    echo ""
    echo -e "${GREEN}${BOLD}🎉 WarpKit安装完成！${NC}"
    echo ""
    echo -e "${CYAN}使用方法:${NC}"
    echo -e "  ${YELLOW}warpkit${NC}         启动WarpKit"
    echo -e "  ${YELLOW}warpkit --help${NC}  查看帮助"
    echo ""
}

# 主函数
main() {
    case "${1:-}" in
        --uninstall)
            uninstall
            ;;
        --help|-h)
            show_help
            ;;
        "")
            main_install
            ;;
        *)
            echo "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
}

# 捕获中断信号
trap 'echo -e "\n${YELLOW}安装被中断${NC}"; exit 1' INT TERM

# 运行主函数
main "$@"