#!/bin/bash

# WarpKit - Linux服务运维工具
# Author: Claude Code Assistant

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
declare -r WHITE='\033[0;37m'
declare -r BOLD='\033[1m'
declare -r NC='\033[0m' # No Color

# 全局变量
declare -g CURRENT_SELECTION=0
declare -g MENU_OPTIONS=()
declare -g DISTRO=""
declare -g VERSION=""
declare -g KERNEL=""
declare -g ARCH=""
declare -g DEBUG_MODE=false

# 模块化相关变量
declare -g WARPKIT_MODULES_DIR=""
declare -g LOADED_MODULES=()
declare -g AVAILABLE_MODULES=()

# 更新相关变量
declare -r GITHUB_REPO="marvinli001/warpkit"
declare -r CONFIG_DIR="$HOME/.config/warpkit"
declare -r CACHE_DIR="$HOME/.cache/warpkit"
declare -r UPDATE_CHECK_FILE="$CACHE_DIR/last_update_check"

# 获取当前脚本的版本
get_current_version() {
    local script_dir=$(dirname "$(readlink -f "$0")")
    local version_file="$CONFIG_DIR/current_version"

    # 首先检查是否有存储的版本信息
    if [[ -f "$version_file" ]]; then
        cat "$version_file" 2>/dev/null || echo "unknown"
        return
    fi

    # 检查脚本所在目录是否是git仓库
    if cd "$script_dir" 2>/dev/null && git rev-parse --git-dir >/dev/null 2>&1; then
        # 获取当前脚本文件的最后修改commit
        local script_file=$(basename "$0")
        local version=$(git log -1 --format="%h" -- "$script_file" 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
        if [[ -n "$version" ]]; then
            # 存储版本信息
            mkdir -p "$CONFIG_DIR"
            echo "$version" > "$version_file"
            echo "$version"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
}

# 保存当前版本信息
save_current_version() {
    local version="$1"
    local version_file="$CONFIG_DIR/current_version"

    mkdir -p "$CONFIG_DIR"
    echo "$version" > "$version_file"
}

# 打印Logo
print_logo() {
    clear
    echo -e "${CYAN}${BOLD}"
    echo "██╗    ██╗ █████╗ ██████╗ ██████╗ ██╗  ██╗██╗████████╗"
    echo "██║    ██║██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝██║╚══██╔══╝"
    echo "██║ █╗ ██║███████║██████╔╝██████╔╝█████╔╝ ██║   ██║   "
    echo "██║███╗██║██╔══██║██╔══██╗██╔═══╝ ██╔═██╗ ██║   ██║   "
    echo "╚███╔███╔╝██║  ██║██║  ██║██║     ██║  ██╗██║   ██║   "
    echo " ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝   ╚═╝   "
    echo -e "${NC}"
    echo -e "${YELLOW}WarpKit $(get_current_version)${NC}"
    echo ""
}

# 检查是否需要更新检测（每日首次运行）
should_check_update() {
    local today=$(date +%Y-%m-%d)

    # 创建缓存目录（如果不存在）
    mkdir -p "$CACHE_DIR"

    # 如果没有检查记录文件，则需要检查
    if [[ ! -f "$UPDATE_CHECK_FILE" ]]; then
        return 0
    fi

    # 读取上次检查日期
    local last_check_date=$(cat "$UPDATE_CHECK_FILE" 2>/dev/null || echo "")

    # 如果日期不同，需要检查更新
    if [[ "$last_check_date" != "$today" ]]; then
        return 0
    fi

    return 1
}

# 记录更新检查时间
record_update_check() {
    local today=$(date +%Y-%m-%d)
    echo "$today" > "$UPDATE_CHECK_FILE"
}

# 获取GitHub最新commit hash
get_latest_commit() {
    local latest_commit=""

    # 尝试使用curl获取最新commit
    if command -v curl >/dev/null 2>&1; then
        latest_commit=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/commits/master" | grep '"sha"' | head -1 | cut -d'"' -f4 | cut -c1-7 2>/dev/null)
    # 如果没有curl，尝试wget
    elif command -v wget >/dev/null 2>&1; then
        latest_commit=$(wget -qO- "https://api.github.com/repos/$GITHUB_REPO/commits/master" | grep '"sha"' | head -1 | cut -d'"' -f4 | cut -c1-7 2>/dev/null)
    fi

    echo "$latest_commit"
}

# 比较commit hash
commit_compare() {
    local current="$1"
    local latest="$2"

    # 如果commit hash相同，返回1（不需要更新）
    if [[ "$current" == "$latest" ]]; then
        return 1
    fi

    # 如果当前版本是unknown，则需要更新
    if [[ "$current" == "unknown" ]]; then
        return 0
    fi

    # 如果获取不到最新commit，返回1（不更新）
    if [[ -z "$latest" ]]; then
        return 1
    fi

    # commit hash不同，需要更新
    return 0
}

# 检查更新
check_for_updates() {
    local force_check=${1:-false}

    # 如果不是强制检查且不需要检查更新，则跳过
    if [[ "$force_check" != "true" ]] && ! should_check_update; then
        return
    fi

    echo -e "${YELLOW}🔍 检查更新中...${NC}" >&2

    local current_commit=$(get_current_version)
    local latest_commit=$(get_latest_commit)

    if [[ -z "$latest_commit" ]]; then
        if [[ "$force_check" == "true" ]]; then
            echo -e "${RED}❌ 无法获取最新版本信息，请检查网络连接${NC}" >&2
        fi
        return
    fi

    if commit_compare "$current_commit" "$latest_commit"; then
        echo -e "${GREEN}🎉 发现新版本 $latest_commit（当前版本 $current_commit）${NC}" >&2
        echo -e "${CYAN}是否现在更新？ [y/N] ${NC}" >&2
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            perform_update "$latest_commit"
        fi
    else
        if [[ "$force_check" == "true" ]]; then
            echo -e "${GREEN}✅ 已是最新版本 $current_commit${NC}" >&2
        fi
    fi

    # 记录检查时间
    record_update_check
}

# 执行更新
perform_update() {
    local new_version="$1"
    local script_path="$(readlink -f "$0")"
    local backup_path="${script_path}.backup.$(date +%Y%m%d_%H%M%S)"

    echo -e "${YELLOW}📦 开始更新到 $new_version...${NC}"

    # 备份当前脚本
    echo -e "${BLUE}📋 备份当前版本...${NC}"
    cp "$script_path" "$backup_path"

    # 下载新版本主脚本
    echo -e "${BLUE}⬇️ 下载主程序...${NC}"
    local temp_file="/tmp/warpkit_update.sh"

    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL "https://raw.githubusercontent.com/$GITHUB_REPO/master/warpkit.sh" -o "$temp_file"; then
            echo -e "${RED}❌ 主程序下载失败${NC}"
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -qO "$temp_file" "https://raw.githubusercontent.com/$GITHUB_REPO/master/warpkit.sh"; then
            echo -e "${RED}❌ 主程序下载失败${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ 需要 curl 或 wget 来下载更新${NC}"
        return 1
    fi

    # 验证下载的文件
    if [[ ! -s "$temp_file" ]]; then
        echo -e "${RED}❌ 下载的主程序文件无效${NC}"
        rm -f "$temp_file"
        return 1
    fi

    # 更新模块（如果存在）
    update_modules

    # 替换当前脚本
    echo -e "${BLUE}🔄 安装新版本...${NC}"
    if cp "$temp_file" "$script_path" && chmod +x "$script_path"; then
        rm -f "$temp_file"
        # 保存新版本信息
        save_current_version "$new_version"
        echo -e "${GREEN}✅ 更新成功！已更新到 $new_version${NC}"
        echo -e "${YELLOW}备份文件保存在: $backup_path${NC}"
        echo -e "${CYAN}请重新运行 warpkit 以使用新版本${NC}"
        echo ""
        echo "按任意键退出..."
        restore_terminal_state
        read -n1
        exit 0
    else
        echo -e "${RED}❌ 更新失败，正在恢复备份...${NC}"
        cp "$backup_path" "$script_path"
        rm -f "$temp_file"
        return 1
    fi
}

# 更新模块
update_modules() {
    # 检测模块安装路径
    local module_dirs=(
        "/usr/local/lib/warpkit/modules"
        "$HOME/.local/lib/warpkit/modules"
    )

    local modules_dir=""
    for dir in "${module_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            modules_dir="$dir"
            break
        fi
    done

    # 如果未找到模块目录，直接返回
    if [[ -z "$modules_dir" ]]; then
        echo -e "${YELLOW}⚠️ 未找到模块目录，跳过模块更新${NC}"
        return 0
    fi

    # 确保模块目录有效
    if [[ ! -d "$modules_dir" || ! -w "$modules_dir" ]]; then
        echo -e "${YELLOW}⚠️ 模块目录无效或无写入权限，跳过模块更新${NC}"
        return 0
    fi

    echo -e "${BLUE}⬇️ 更新模块...${NC}"

    # 创建临时目录
    local temp_modules_dir="/tmp/warpkit_modules_update"
    mkdir -p "$temp_modules_dir"

    # 下载模块文件
    local modules=("system.sh" "packages.sh" "network.sh" "logs.sh")
    local download_success=true

    for module in "${modules[@]}"; do
        echo -e "${CYAN}  下载 $module...${NC}"
        if command -v curl >/dev/null 2>&1; then
            if ! curl -fsSL "https://raw.githubusercontent.com/$GITHUB_REPO/master/modules/$module" -o "$temp_modules_dir/$module"; then
                echo -e "${YELLOW}  ⚠️ $module 下载失败${NC}"
                download_success=false
            fi
        elif command -v wget >/dev/null 2>&1; then
            if ! wget -qO "$temp_modules_dir/$module" "https://raw.githubusercontent.com/$GITHUB_REPO/master/modules/$module"; then
                echo -e "${YELLOW}  ⚠️ $module 下载失败${NC}"
                download_success=false
            fi
        fi
    done

    if [[ "$download_success" == "true" ]]; then
        # 备份现有模块
        if [[ -d "$modules_dir" ]]; then
            local modules_backup="${modules_dir}.backup.$(date +%Y%m%d_%H%M%S)"
            if ! cp -r "$modules_dir" "$modules_backup" 2>/dev/null; then
                echo -e "${YELLOW}⚠️ 备份模块失败，继续更新${NC}"
            fi
        fi

        # 安装新模块（带错误检查）
        local install_failed=false
        for module_file in "$temp_modules_dir"/*.sh; do
            if [[ -f "$module_file" ]]; then
                local module_name=$(basename "$module_file")
                if cp "$module_file" "$modules_dir/" 2>/dev/null; then
                    chmod +x "$modules_dir/$module_name" 2>/dev/null || true
                else
                    echo -e "${YELLOW}  ⚠️ 安装 $module_name 失败${NC}"
                    install_failed=true
                fi
            fi
        done

        if [[ "$install_failed" == "false" ]]; then
            echo -e "${GREEN}✅ 模块更新完成${NC}"
        else
            echo -e "${YELLOW}⚠️ 部分模块安装失败${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️ 部分模块更新失败，但主程序更新将继续${NC}"
    fi

    # 清理临时文件
    rm -rf "$temp_modules_dir"
}

# 检测Linux发行版
detect_distro() {
    # 首先尝试从 /etc/os-release 获取信息（最标准的方法）
    if [[ -f /etc/os-release ]]; then
        # 使用子shell避免污染当前环境
        local os_info
        os_info=$(source /etc/os-release 2>/dev/null && echo "$ID|${VERSION_ID:-$VERSION}")
        DISTRO=$(echo "$os_info" | cut -d'|' -f1)
        VERSION=$(echo "$os_info" | cut -d'|' -f2)

    # Ubuntu/Debian 系统的 lsb-release
    elif [[ -f /etc/lsb-release ]]; then
        # 使用子shell避免污染当前环境
        local lsb_info
        lsb_info=$(source /etc/lsb-release 2>/dev/null && echo "$DISTRIB_ID|$DISTRIB_RELEASE")
        DISTRO=$(echo "$lsb_info" | cut -d'|' -f1 | tr '[:upper:]' '[:lower:]')
        VERSION=$(echo "$lsb_info" | cut -d'|' -f2)

    # Red Hat 系列
    elif [[ -f /etc/redhat-release ]]; then
        if grep -qi "centos" /etc/redhat-release; then
            DISTRO="centos"
        elif grep -qi "red hat" /etc/redhat-release; then
            DISTRO="rhel"
        elif grep -qi "fedora" /etc/redhat-release; then
            DISTRO="fedora"
        else
            DISTRO="rhel"
        fi
        VERSION=$(grep -oE '[0-9]+(\.[0-9]+)?' /etc/redhat-release | head -1)

    # SUSE 系列
    elif [[ -f /etc/SuSE-release ]]; then
        DISTRO="suse"
        VERSION=$(grep -i version /etc/SuSE-release | grep -oE '[0-9]+(\.[0-9]+)?')

    # Arch Linux
    elif [[ -f /etc/arch-release ]]; then
        DISTRO="arch"
        VERSION="rolling"

    # Alpine Linux
    elif [[ -f /etc/alpine-release ]]; then
        DISTRO="alpine"
        VERSION=$(cat /etc/alpine-release)

    # Gentoo
    elif [[ -f /etc/gentoo-release ]]; then
        DISTRO="gentoo"
        VERSION=$(cat /etc/gentoo-release | grep -oE '[0-9]+(\.[0-9]+)?')

    # Debian
    elif [[ -f /etc/debian_version ]]; then
        DISTRO="debian"
        VERSION=$(cat /etc/debian_version)

    # 通过 uname 尝试检测
    elif command -v uname >/dev/null 2>&1; then
        local uname_output=$(uname -a | tr '[:upper:]' '[:lower:]')
        if [[ $uname_output == *"ubuntu"* ]]; then
            DISTRO="ubuntu"
        elif [[ $uname_output == *"debian"* ]]; then
            DISTRO="debian"
        elif [[ $uname_output == *"centos"* ]]; then
            DISTRO="centos"
        elif [[ $uname_output == *"red hat"* ]]; then
            DISTRO="rhel"
        else
            DISTRO="unknown"
        fi
        VERSION="unknown"
    else
        DISTRO="unknown"
        VERSION="unknown"
    fi

    # 获取内核和架构信息
    KERNEL=$(uname -r 2>/dev/null || echo "unknown")
    ARCH=$(uname -m 2>/dev/null || echo "unknown")

    # 规范化发行版名称
    case "$DISTRO" in
        "ubuntu"|"debian"|"centos"|"rhel"|"fedora"|"arch"|"suse"|"opensuse"|"alpine"|"gentoo")
            # 已知的发行版，保持原样
            ;;
        *)
            # 未知发行版，尝试从 ID_LIKE 获取兼容信息
            if [[ -f /etc/os-release ]]; then
                local id_like
                id_like=$(source /etc/os-release 2>/dev/null && echo "${ID_LIKE:-}")
                if [[ -n "$id_like" ]]; then
                    DISTRO="$id_like"
                fi
            fi
            ;;
    esac
}

# 显示系统信息
show_system_info() {
    echo -e "${BOLD}${BLUE}系统信息:${NC}"
    echo -e "  发行版: ${GREEN}$DISTRO $VERSION${NC}"
    echo -e "  内核版本: ${GREEN}$KERNEL${NC}"
    echo -e "  架构: ${GREEN}$ARCH${NC}"
    echo ""
}

# 动态进度条显示
show_progress() {
    local current=$1
    local total=$2
    local message=${3:-"处理中"}
    local width=50

    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))

    printf "\r${CYAN}%s: [" "$message"
    printf "%${completed}s" | tr ' ' '▓'
    printf "%${remaining}s" | tr ' ' '░'
    printf "] %d%% (%d/%d)${NC}" "$percentage" "$current" "$total"

    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# 加载动画
loading_animation() {
    local message=${1:-"加载中"}
    local duration=${2:-3}
    local chars="⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏"

    local end_time=$((SECONDS + duration))

    while [[ $SECONDS -lt $end_time ]]; do
        for (( i=0; i<${#chars}; i++ )); do
            printf "\r${YELLOW}%s %s${NC}" "${chars:$i:1}" "$message"
            sleep 0.1
            if [[ $SECONDS -ge $end_time ]]; then
                break 2
            fi
        done
    done
    printf "\r%s ✓ %s 完成!${NC}\n" "${GREEN}" "$message"
}

# 动态状态更新
update_status() {
    local status=$1
    local message=$2
    local timestamp=$(date '+%H:%M:%S')

    case "$status" in
        "info")
            echo -e "${BLUE}[${timestamp}] ℹ️  ${message}${NC}"
            ;;
        "success")
            echo -e "${GREEN}[${timestamp}] ✅ ${message}${NC}"
            ;;
        "warning")
            echo -e "${YELLOW}[${timestamp}] ⚠️  ${message}${NC}"
            ;;
        "error")
            echo -e "${RED}[${timestamp}] ❌ ${message}${NC}"
            ;;
        "working")
            echo -e "${CYAN}[${timestamp}] 🔄 ${message}${NC}"
            ;;
        *)
            echo -e "[${timestamp}] ${message}"
            ;;
    esac
}

# 实时显示命令输出
show_command_output() {
    local command=$1
    local description=${2:-"执行命令"}

    update_status "working" "${description}: $command"

    if eval "$command" 2>&1 | while IFS= read -r line; do
        echo -e "  ${WHITE}│${NC} $line"
    done; then
        update_status "success" "${description}完成"
        return 0
    else
        update_status "error" "${description}失败"
        return 1
    fi
}

# 多步骤任务进度显示
multi_step_task() {
    local steps=("$@")
    local total=${#steps[@]}
    local current=0

    echo -e "${BOLD}${PURPLE}开始执行多步骤任务...${NC}"
    echo ""

    for step in "${steps[@]}"; do
        ((current++))
        show_progress $current $total "步骤 $current/$total"
        update_status "working" "$step"

        # 模拟任务执行时间
        sleep 1

        update_status "success" "$step 完成"
        echo ""
    done

    echo -e "${GREEN}${BOLD}所有步骤完成!${NC}"
}

# 验证域名格式
validate_domain() {
    local domain="$1"
    # 检查是否为空
    if [[ -z "$domain" ]]; then
        return 1
    fi
    # 检查域名格式（允许字母、数字、点、连字符）
    if [[ ! "$domain" =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 1
    fi
    # 检查长度
    if [[ ${#domain} -gt 253 ]]; then
        return 1
    fi
    return 0
}

# 验证包名格式
validate_package_name() {
    local pkg_name="$1"
    # 检查是否为空
    if [[ -z "$pkg_name" ]]; then
        return 1
    fi
    # 检查包名格式（允许字母、数字、点、连字符、下划线、加号）
    if [[ ! "$pkg_name" =~ ^[a-zA-Z0-9][a-zA-Z0-9\.\-_+]*$ ]]; then
        return 1
    fi
    # 检查长度
    if [[ ${#pkg_name} -gt 255 ]]; then
        return 1
    fi
    return 0
}

# 验证文件路径安全性
validate_file_path() {
    local path="$1"
    # 检查是否为空
    if [[ -z "$path" ]]; then
        return 1
    fi
    # 禁止路径遍历
    if [[ "$path" == *".."* ]]; then
        return 1
    fi
    # 检查路径长度
    if [[ ${#path} -gt 4096 ]]; then
        return 1
    fi
    # 必须是绝对路径或相对路径
    if [[ ! "$path" =~ ^(/|\./) ]]; then
        # 如果不是以 / 或 ./ 开头，添加 ./
        path="./$path"
    fi
    return 0
}

# 检测UTF-8支持
detect_utf8_support() {
    if [[ "${LC_ALL:-${LANG:-}}" =~ [Uu][Tt][Ff]-?8 ]] && [[ -t 1 ]]; then
        echo "true"
    else
        echo "false"
    fi
}

# 获取指针符号
get_pointer_symbol() {
    if [[ "$(detect_utf8_support)" == "true" ]]; then
        echo "▶"
    else
        echo ">"
    fi
}

# 渲染单个选项
render_option() {
    local index=$1
    local text=$2
    local is_selected=$3
    local max_width=${4:-60}

    local pointer=$(get_pointer_symbol)
    local padding="  "

    if [[ $is_selected -eq 1 ]]; then
        # 高亮当前选择项
        printf "${padding}${GREEN}${BOLD}%s %s${NC}\n" "$pointer" "$text"
    else
        # 普通选项
        printf "${padding}  %s\n" "$text"
    fi
}

# 清屏并移动光标到顶部
clear_screen() {
    if [[ "$IN_ALTERNATE_SCREEN" == "true" ]]; then
        # 在备用屏缓中，直接清屏
        printf '\e[2J\e[H'
    else
        # 普通模式，清屏
        clear
    fi
}

# 渲染标题
render_title() {
    local title="$1"
    local system_info="$2"

    echo -e "${CYAN}${BOLD}$title${NC}"
    if [[ -n "$system_info" ]]; then
        echo -e "${YELLOW}$system_info${NC}"
    fi
    echo ""
}

# 渲染选项列表
render_options() {
    local current_index=$1
    shift
    local options=("$@")

    for i in "${!options[@]}"; do
        local is_selected=0
        if [[ $i -eq $current_index ]]; then
            is_selected=1
        fi
        render_option "$i" "${options[$i]}" "$is_selected"
    done
}

# 渲染底部提示
render_help() {
    local help_text="${1:-使用 ↑/↓ 或 j/k 选择，回车确认，Esc 或 q 退出}"
    echo ""
    echo -e "${YELLOW}$help_text${NC}"
}

# Codex CLI 风格选择器
# 参数: 标题 [系统信息] [初始索引] [选项...]
codex_selector() {
    local title="$1"
    local system_info="$2"
    local initial_index="${3:-0}"
    shift 3
    local options=("$@")

    # 验证参数
    if [[ ${#options[@]} -eq 0 ]]; then
        echo "SELECTOR_ERROR"
        return 1
    fi

    # 验证初始索引是否为数字
    if ! [[ "$initial_index" =~ ^[0-9]+$ ]]; then
        debug_log "codex_selector: initial_index 不是数字，重置为 0"
        initial_index=0
    fi

    # 验证初始索引范围
    if [[ $initial_index -lt 0 || $initial_index -ge ${#options[@]} ]]; then
        debug_log "codex_selector: initial_index 超出范围，重置为 0"
        initial_index=0
    fi

    local current_index=$initial_index
    local in_selector_mode=true

    # 检查是否是TTY
    if [[ ! -t 0 || ! -t 1 ]]; then
        debug_log "非交互式终端，切换到文本菜单模式"
        echo "SELECTOR_ERROR"
        return 1
    fi

    # 保存终端状态并设置原始模式
    save_terminal_state
    if ! set_raw_terminal; then
        debug_log "设置原始终端模式失败"
        echo "SELECTOR_ERROR"
        return 1
    fi

    # 进入备用屏缓
    enter_alternate_screen

    # 设置信号处理
    trap 'restore_terminal_state; exit 130' INT TERM

    debug_log "codex_selector: 开始选择器，选项数=${#options[@]}, 初始索引=$initial_index"

    # 关闭errexit，避免UI意外退出，但保存原始状态
    local errexit_was_set=false
    if [[ $- =~ e ]]; then
        errexit_was_set=true
    fi
    set +e

    # 主循环
    while [[ "$in_selector_mode" == "true" ]]; do
        # 渲染界面
        clear_screen
        render_title "$title" "$system_info"
        render_options "$current_index" "${options[@]}"
        render_help

        # 读取按键
        local key
        key=$(read_key)
        debug_log "codex_selector: 接收到按键: $key"

        case "$key" in
            "UP")
                if [[ $current_index -gt 0 ]]; then
                    ((current_index--))
                else
                    # 环绕到最后一个选项
                    current_index=$((${#options[@]} - 1))
                fi
                debug_log "codex_selector: 向上移动到索引 $current_index"
                ;;
            "DOWN")
                if [[ $current_index -lt $((${#options[@]} - 1)) ]]; then
                    ((current_index++))
                else
                    # 环绕到第一个选项
                    current_index=0
                fi
                debug_log "codex_selector: 向下移动到索引 $current_index"
                ;;
            "ENTER")
                debug_log "codex_selector: 确认选择索引 $current_index"
                in_selector_mode=false
                ;;
            "ESCAPE"|"QUIT")
                debug_log "codex_selector: 用户取消选择"
                current_index="CANCELLED"
                in_selector_mode=false
                ;;
            "TIMEOUT")
                # 超时继续循环
                debug_log "codex_selector: 读取超时，继续等待"
                ;;
            "OTHER")
                # 忽略其他按键
                debug_log "codex_selector: 忽略未知按键"
                ;;
            *)
                debug_log "codex_selector: 未处理的按键: $key"
                ;;
        esac
    done

    # 恢复errexit（如果之前是开启的）
    if [[ "$errexit_was_set" == "true" ]]; then
        set -e
    fi

    # 恢复终端状态
    restore_terminal_state

    # 返回结果
    echo "$current_index"
    return 0
}

# 简化的选择器接口（仅标题和选项）
simple_selector() {
    local title="$1"
    shift
    local options=("$@")

    codex_selector "$title" "" 0 "${options[@]}"
}

# ==================== 模块化系统 ====================

# 初始化模块系统
init_module_system() {
    local script_dir=$(dirname "$(readlink -f "$0")")

    # 尝试多个可能的模块目录位置
    local possible_dirs=(
        "$script_dir/modules"
        "$HOME/.local/lib/warpkit/modules"
        "/usr/local/lib/warpkit/modules"
        "/opt/warpkit/modules"
    )

    for dir in "${possible_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            WARPKIT_MODULES_DIR="$dir"
            debug_log "找到模块目录: $dir"
            break
        fi
    done

    if [[ -z "$WARPKIT_MODULES_DIR" ]]; then
        debug_log "未找到模块目录，使用内置功能"
        return 1
    fi

    # 扫描可用模块
    scan_available_modules
    return 0
}

# 扫描可用模块
scan_available_modules() {
    AVAILABLE_MODULES=()

    if [[ ! -d "$WARPKIT_MODULES_DIR" ]]; then
        return 1
    fi

    for module_file in "$WARPKIT_MODULES_DIR"/*.sh; do
        if [[ -f "$module_file" ]]; then
            local module_name=$(basename "$module_file" .sh)
            AVAILABLE_MODULES+=("$module_name")
            debug_log "发现模块: $module_name"
        fi
    done
}

# 加载模块
load_module() {
    local module_name="$1"
    local module_file="$WARPKIT_MODULES_DIR/${module_name}.sh"

    # 检查模块是否已加载
    for loaded in "${LOADED_MODULES[@]}"; do
        if [[ "$loaded" == "$module_name" ]]; then
            debug_log "模块 $module_name 已加载"
            return 0
        fi
    done

    # 检查模块文件是否存在
    if [[ ! -f "$module_file" ]]; then
        debug_log "模块文件不存在: $module_file"
        return 1
    fi

    # 加载模块
    debug_log "加载模块: $module_name"
    if source "$module_file" 2>/dev/null; then
        LOADED_MODULES+=("$module_name")
        debug_log "模块 $module_name 加载成功"
        return 0
    else
        debug_log "模块 $module_name 加载失败"
        return 1
    fi
}

# 检查模块是否可用
is_module_available() {
    local module_name="$1"

    for available in "${AVAILABLE_MODULES[@]}"; do
        if [[ "$available" == "$module_name" ]]; then
            return 0
        fi
    done
    return 1
}

# 检查模块是否已加载
is_module_loaded() {
    local module_name="$1"

    for loaded in "${LOADED_MODULES[@]}"; do
        if [[ "$loaded" == "$module_name" ]]; then
            return 0
        fi
    done
    return 1
}

# 调用模块函数（安全调用）
call_module_function() {
    local module_name="$1"
    local function_name="$2"
    shift 2

    # 尝试加载模块
    if ! is_module_loaded "$module_name"; then
        if ! load_module "$module_name"; then
            debug_log "无法加载模块 $module_name"
            return 1
        fi
    fi

    # 检查函数是否存在
    if declare -F "$function_name" >/dev/null; then
        debug_log "调用模块函数: $module_name::$function_name"
        "$function_name" "$@"
        return $?
    else
        debug_log "函数不存在: $function_name"
        return 1
    fi
}

# 模块化的菜单项处理
handle_modular_menu_item() {
    local item="$1"

    case "$item" in
        "系统工具")
            if call_module_function "system" "show_system_monitor"; then
                return 0
            else
                show_system_monitor_builtin
            fi
            ;;
        "包管理")
            if call_module_function "packages" "show_package_management"; then
                return 0
            else
                show_package_management_builtin
            fi
            ;;
        "网络工具")
            if call_module_function "network" "show_network_tools"; then
                return 0
            else
                show_network_tools_builtin
            fi
            ;;
        "日志查看")
            if call_module_function "logs" "show_log_viewer"; then
                return 0
            else
                show_log_viewer_builtin
            fi
            ;;
        *)
            return 1
            ;;
    esac
}

# 显示主菜单 (新选择器版本)
show_main_menu() {
    local main_options=(
        "系统工具"
        "包管理"
        "网络工具"
        "日志查看"
        "脚本管理"
        "退出"
    )

    # 构建系统信息字符串
    local system_info_line="$DISTRO $VERSION | $KERNEL | $ARCH"

    # 使用新的选择器
    local result
    result=$(codex_selector "WarpKit $(get_current_version) - Linux服务运维工具" "$system_info_line" "$CURRENT_SELECTION" "${main_options[@]}")

    debug_log "show_main_menu: 选择器返回结果: $result"

    # 处理选择结果
    case "$result" in
        "CANCELLED")
            debug_log "show_main_menu: 用户取消"
            return 1
            ;;
        "SELECTOR_ERROR")
            debug_log "show_main_menu: 选择器错误，切换到文本菜单"
            show_text_menu
            return 0
            ;;
        [0-9]*)
            # 更新当前选择
            CURRENT_SELECTION=$result
            # 处理选择的菜单项
            handle_menu_selection
            return 0
            ;;
        *)
            debug_log "show_main_menu: 未知选择器结果: $result"
            return 1
            ;;
    esac
}

# 文本菜单模式（当交互式选择器不可用时）
show_text_menu() {
    while true; do
        clear
        print_logo
        show_system_info

        echo -e "${CYAN}${BOLD}主菜单${NC}"
        echo ""
        echo "1. 系统工具"
        echo "2. 包管理"
        echo "3. 网络工具"
        echo "4. 日志查看"
        echo "5. 脚本管理"
        echo "6. 退出"
        echo ""
        echo -n "请选择功能 (1-6): "

        read -r choice
        echo ""

        case "$choice" in
            1)
                CURRENT_SELECTION=0
                handle_menu_selection
                ;;
            2)
                CURRENT_SELECTION=1
                handle_menu_selection
                ;;
            3)
                CURRENT_SELECTION=2
                handle_menu_selection
                ;;
            4)
                CURRENT_SELECTION=3
                handle_menu_selection
                ;;
            5)
                CURRENT_SELECTION=4
                handle_menu_selection
                ;;
            6)
                echo -e "${YELLOW}再见！${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}无效选择，请输入 1-6${NC}"
                sleep 2
                ;;
        esac
    done
}

# 全局终端状态变量
declare -g TERMINAL_STATE_SAVED=false
# 使用更安全的临时文件命名（包含随机数和时间戳）
declare -g TERMINAL_STATE_FILE="/tmp/warpkit_terminal_state.$$.$(date +%s).${RANDOM}"
declare -g IN_ALTERNATE_SCREEN=false

# 保存终端状态
save_terminal_state() {
    if [[ "$TERMINAL_STATE_SAVED" == "false" ]]; then
        if stty -g > "$TERMINAL_STATE_FILE" 2>/dev/null; then
            TERMINAL_STATE_SAVED=true
            debug_log "终端状态已保存到 $TERMINAL_STATE_FILE"
        else
            debug_log "保存终端状态失败"
        fi
    fi
}

# 恢复终端状态
restore_terminal_state() {
    # 退出备用屏缓
    if [[ "$IN_ALTERNATE_SCREEN" == "true" ]]; then
        printf '\e[?1049l' 2>/dev/null
        IN_ALTERNATE_SCREEN=false
        debug_log "已退出备用屏缓"
    fi

    # 显示光标
    printf '\e[?25h' 2>/dev/null

    # 恢复终端设置
    if [[ "$TERMINAL_STATE_SAVED" == "true" && -f "$TERMINAL_STATE_FILE" ]]; then
        if stty "$(cat "$TERMINAL_STATE_FILE")" 2>/dev/null; then
            debug_log "终端状态已恢复"
        else
            stty sane 2>/dev/null
            debug_log "使用sane模式恢复终端"
        fi
        rm -f "$TERMINAL_STATE_FILE" 2>/dev/null
        TERMINAL_STATE_SAVED=false
    else
        stty sane 2>/dev/null
        debug_log "使用sane模式恢复终端"
    fi
}

# 设置原始终端模式
set_raw_terminal() {
    # 关闭回显、规范模式、信号处理和XON/XOFF
    # min 1: 至少读取一个字节
    # time 0: 无超时
    if stty -echo -icanon -isig -ixon min 1 time 0 2>/dev/null; then
        debug_log "原始终端模式设置成功"
    else
        debug_log "原始终端模式设置失败"
        return 1
    fi
}

# 进入备用屏缓并隐藏光标
enter_alternate_screen() {
    if [[ -t 0 && -t 1 ]]; then
        # 检查终端是否支持备用屏缓
        if [[ -n "${TERM:-}" ]] && [[ "$TERM" != "dumb" ]]; then
            printf '\e[?1049h' 2>/dev/null && {
                IN_ALTERNATE_SCREEN=true
                debug_log "已进入备用屏缓"
            } || {
                debug_log "备用屏缓不支持，使用普通清屏"
                clear
            }
        else
            clear
        fi
        # 隐藏光标
        printf '\e[?25l' 2>/dev/null
    fi
}

# 调试输出
debug_log() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# 清空输入缓冲区
flush_input() {
    local dummy
    while IFS= read -r -n1 -t 0.001 dummy 2>/dev/null; do
        debug_log "flush_input: 清除残留字节: $(printf '%q' "$dummy")"
    done
    true
}

# 读取单个字符（原始字节）
read_raw_char() {
    local char=""
    if IFS= read -r -n1 -t 10 char 2>/dev/null; then
        printf '%s' "$char"
        return 0
    else
        return 1
    fi
}

# 解析按键序列
parse_key_sequence() {
    local first_char="$1"
    local timeout=${2:-0.1}

    # 如果不是ESC，直接返回
    if [[ "$first_char" != $'\e' ]]; then
        echo "$first_char"
        return 0
    fi

    # ESC序列处理
    local second_char=""
    if IFS= read -r -n1 -t "$timeout" second_char 2>/dev/null; then
        debug_log "parse_key_sequence: ESC + $(printf '%q' "$second_char")"

        case "$second_char" in
            '[')
                # 标准ANSI序列 ESC[
                local third_char=""
                if IFS= read -r -n1 -t "$timeout" third_char 2>/dev/null; then
                    case "$third_char" in
                        'A') echo "UP"; return 0 ;;
                        'B') echo "DOWN"; return 0 ;;
                        'C') echo "RIGHT"; return 0 ;;
                        'D') echo "LEFT"; return 0 ;;
                        '1'|'2'|'3'|'4'|'5'|'6'|'7'|'8'|'9')
                            # 扩展序列，继续读取直到找到结束字符
                            local extended_seq="$third_char"
                            local char=""
                            while IFS= read -r -n1 -t 0.05 char 2>/dev/null; do
                                extended_seq+="$char"
                                case "$char" in
                                    'A'|'B'|'C'|'D'|'~'|'H'|'F')
                                        # 找到结束字符
                                        case "$char" in
                                            'A') echo "UP"; return 0 ;;
                                            'B') echo "DOWN"; return 0 ;;
                                            'C') echo "RIGHT"; return 0 ;;
                                            'D') echo "LEFT"; return 0 ;;
                                            *) echo "ESCAPE"; return 0 ;;
                                        esac
                                        ;;
                                esac
                                # 防止无限循环
                                if [[ ${#extended_seq} -gt 10 ]]; then
                                    break
                                fi
                            done
                            echo "ESCAPE"
                            return 0
                            ;;
                        *) echo "ESCAPE"; return 0 ;;
                    esac
                else
                    echo "ESCAPE"
                    return 0
                fi
                ;;
            'O')
                # 应用程序键模式 ESCO
                local third_char=""
                if IFS= read -r -n1 -t "$timeout" third_char 2>/dev/null; then
                    case "$third_char" in
                        'A') echo "UP"; return 0 ;;
                        'B') echo "DOWN"; return 0 ;;
                        'C') echo "RIGHT"; return 0 ;;
                        'D') echo "LEFT"; return 0 ;;
                        *) echo "ESCAPE"; return 0 ;;
                    esac
                else
                    echo "ESCAPE"
                    return 0
                fi
                ;;
            *)
                # 其他ESC序列，当做ESC处理
                echo "ESCAPE"
                return 0
                ;;
        esac
    else
        # 单独的ESC
        echo "ESCAPE"
        return 0
    fi
}

# 读取按键并解析
read_key() {
    # 清除输入缓冲
    flush_input

    # 读取第一个字符
    local first_char=""
    if ! first_char=$(read_raw_char); then
        debug_log "read_key: 读取超时或失败"
        echo "TIMEOUT"
        return 0
    fi

    debug_log "read_key: 第一字符: $(printf '%q' "$first_char")"

    # 处理特殊字符
    case "$first_char" in
        '')
            debug_log "read_key: 空字符，忽略"
            echo "OTHER"
            return 0
            ;;
        $'\n'|$'\r')
            debug_log "read_key: 回车/换行"
            echo "ENTER"
            return 0
            ;;
        $'\e')
            # ESC序列处理
            local parsed_key
            parsed_key=$(parse_key_sequence "$first_char")
            debug_log "read_key: ESC序列解析结果: $parsed_key"
            echo "$parsed_key"
            return 0
            ;;
        'q'|'Q')
            debug_log "read_key: 退出键"
            echo "QUIT"
            return 0
            ;;
        'j')
            debug_log "read_key: vim风格下移"
            echo "DOWN"
            return 0
            ;;
        'k')
            debug_log "read_key: vim风格上移"
            echo "UP"
            return 0
            ;;
        ' ')
            debug_log "read_key: 空格键"
            echo "ENTER"
            return 0
            ;;
        $'\x03')
            debug_log "read_key: Ctrl+C"
            echo "QUIT"
            return 0
            ;;
        *)
            debug_log "read_key: 其他字符: $(printf '%q' "$first_char")"
            echo "OTHER"
            return 0
            ;;
    esac
}

# 处理菜单导航 (新选择器版本)
handle_navigation() {
    # 主菜单循环
    while true; do
        if ! show_main_menu; then
            # 用户取消或出错，退出
            echo -e "\n${YELLOW}再见！${NC}"
            exit 0
        fi

        # show_main_menu 已经处理了选择和菜单切换
        # 如果到这里，说明从子菜单返回了，继续显示主菜单
    done
}

# 处理菜单选择
handle_menu_selection() {
    local main_options=(
        "系统工具"
        "包管理"
        "网络工具"
        "日志查看"
        "脚本管理"
        "退出"
    )

    local selected_option="${main_options[$CURRENT_SELECTION]}"

    case "$selected_option" in
        "脚本管理")
            # 脚本管理始终使用内置功能
            show_script_management
            ;;
        "退出")
            echo -e "\n${YELLOW}再见！${NC}"
            exit 0
            ;;
        *)
            # 尝试使用模块化处理，失败则使用内置功能
            if ! handle_modular_menu_item "$selected_option"; then
                case "$selected_option" in
                    "系统工具")
                        show_system_monitor_builtin
                        ;;
                    "包管理")
                        show_package_management_builtin
                        ;;
                    "网络工具")
                        show_network_tools_builtin
                        ;;
                    "日志查看")
                        show_log_viewer_builtin
                        ;;
                esac
            fi
            ;;
    esac
}

# 系统工具演示（内置版本）
show_system_monitor_builtin() {
    clear
    echo -e "${BLUE}${BOLD}系统工具${NC}"
    echo ""
    echo -e "${CYAN}系统信息:${NC}"
    uptime 2>/dev/null || echo "系统运行时间: 不可用"
    free -h 2>/dev/null || echo "内存信息: 不可用"
    df -h 2>/dev/null | head -5 || echo "磁盘信息: 不可用"
    echo ""
    echo "按任意键返回主菜单"
    read -n1
}

# 检测包管理器
detect_package_manager() {
    local pkg_manager=""

    # 按优先级检测包管理器
    if command -v apt >/dev/null 2>&1; then
        pkg_manager="apt"
    elif command -v yum >/dev/null 2>&1; then
        pkg_manager="yum"
    elif command -v dnf >/dev/null 2>&1; then
        pkg_manager="dnf"
    elif command -v pacman >/dev/null 2>&1; then
        pkg_manager="pacman"
    elif command -v zypper >/dev/null 2>&1; then
        pkg_manager="zypper"
    elif command -v apk >/dev/null 2>&1; then
        pkg_manager="apk"
    elif command -v emerge >/dev/null 2>&1; then
        pkg_manager="portage"
    else
        pkg_manager="unknown"
    fi

    echo "$pkg_manager"
}

# 包管理菜单（内置版本）
show_package_management_builtin() {
    clear
    echo -e "${BLUE}${BOLD}包管理${NC}"
    echo ""
    local pkg_manager=$(detect_package_manager)
    echo -e "${CYAN}包管理器: ${GREEN}$pkg_manager${NC}"
    echo ""
    echo "按任意键返回主菜单"
    read -n1
}



# 网络工具菜单（内置版本）
show_network_tools_builtin() {
    clear
    echo -e "${BLUE}${BOLD}网络工具${NC}"
    echo ""
    echo -e "${CYAN}网络状态:${NC}"
    ping -c 1 8.8.8.8 >/dev/null 2>&1 && echo "✓ 网络连接正常" || echo "✗ 网络连接异常"
    echo ""
    echo "按任意键返回主菜单"
    read -n1
}

# 日志查看演示（内置版本）
show_log_viewer_builtin() {
    clear
    echo -e "${BLUE}${BOLD}日志查看${NC}"
    echo ""
    echo -e "${CYAN}系统日志:${NC}"
    if command -v journalctl >/dev/null 2>&1; then
        journalctl -n 10 --no-pager 2>/dev/null | head -5 || echo "系统日志: 不可用"
    elif [[ -f /var/log/messages ]]; then
        tail -5 /var/log/messages 2>/dev/null || echo "系统日志: 不可用"
    else
        echo "系统日志: 不可用"
    fi
    echo ""
    echo "按任意键返回主菜单"
    read -n1
}


# 系统更新演示
show_system_update() {
    clear
    echo -e "${BLUE}${BOLD}系统更新${NC}"
    echo ""

    local update_steps=("检查更新源" "下载更新列表" "分析依赖关系" "准备更新包" "完成更新检查")

    echo -e "${YELLOW}注意: 这是更新检查演示，不会实际更新系统${NC}"
    echo ""

    for i in "${!update_steps[@]}"; do
        show_progress $((i+1)) ${#update_steps[@]} "系统更新检查"
        update_status "working" "${update_steps[$i]}"
        sleep 1
        update_status "success" "${update_steps[$i]} 完成"
    done

    echo ""
    update_status "info" "系统更新检查完成，没有发现可用更新"

    echo ""
    echo "按任意键返回主菜单"
    read -n1
}

# 显示帮助信息
show_help() {
    echo -e "${CYAN}${BOLD}WarpKit - Linux服务运维工具 $(get_current_version)${NC}"
    echo ""
    echo -e "${YELLOW}用法:${NC}"
    echo "  warpkit [选项]"
    echo ""
    echo -e "${YELLOW}选项:${NC}"
    echo "  -h, --help        显示此帮助信息"
    echo "  -v, --version     显示版本信息"
    echo "  -u, --update      检查并更新到最新版本"
    echo "  --config          指定配置文件路径"
    echo "  --theme           设置主题 (default, dark, light)"
    echo "  --lang            设置语言 (zh_CN, en_US)"
    echo ""
    echo -e "${YELLOW}示例:${NC}"
    echo "  warpkit           # 启动交互式界面"
    echo "  warpkit --update  # 检查更新"
    echo "  warpkit --version # 显示版本"
    echo ""
}

# 显示版本信息
show_version() {
    echo "WarpKit $(get_current_version)"
}

# 处理命令行参数
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                show_version
                exit 0
                ;;
            -u|--update)
                check_for_updates true
                exit 0
                ;;
            --config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            --theme)
                THEME="$2"
                shift 2
                ;;
            --lang)
                LANGUAGE="$2"
                shift 2
                ;;
            --debug)
                DEBUG_MODE=true
                shift
                ;;
            *)
                echo -e "${RED}未知选项: $1${NC}"
                echo "使用 --help 查看可用选项"
                exit 1
                ;;
        esac
    done
}

# 脚本管理菜单
show_script_management() {
    while true; do
        clear
        print_logo

        echo -e "${BLUE}${BOLD}脚本管理${NC}"
        echo ""
        echo -e "${CYAN}当前版本: $(get_current_version)${NC}"
        echo ""

        echo "1. 检查更新"
        echo "2. 卸载WarpKit"
        echo "3. 查看版本信息"
        echo "4. 清理缓存文件"
        echo "5. 返回主菜单"
        echo ""
        echo -n "请选择功能 (1-5): "

        read -r choice
        echo ""

        case "$choice" in
            1)
                manual_check_update
                ;;
            2)
                uninstall_warpkit
                ;;
            3)
                show_version_info
                ;;
            4)
                clean_cache_files
                ;;
            5)
                return
                ;;
            *)
                echo -e "${RED}无效选择，请输入 1-5${NC}"
                sleep 2
                ;;
        esac
    done
}

# 手动检查更新
manual_check_update() {
    clear
    echo -e "${BLUE}${BOLD}检查更新${NC}"
    echo ""

    echo -e "${YELLOW}正在检查WarpKit更新...${NC}"
    check_for_updates true

    echo ""
    echo "按任意键返回脚本管理菜单"
    read -n1
}

# 卸载WarpKit
uninstall_warpkit() {
    clear
    echo -e "${BLUE}${BOLD}卸载WarpKit${NC}"
    echo ""

    echo -e "${RED}${BOLD}警告: 这将完全卸载WarpKit及其所有相关文件！${NC}"
    echo ""
    echo -e "${YELLOW}将删除以下内容:${NC}"
    echo "  • WarpKit主程序"
    echo "  • 配置文件目录: ~/.config/warpkit"
    echo "  • 缓存文件目录: ~/.cache/warpkit"
    echo "  • DNS备份文件"
    echo "  • 版本信息文件"
    echo ""

    echo -e "${CYAN}确定要卸载WarpKit吗？ [y/N]${NC}"
    # 临时恢复终端模式进行输入
    local old_stty=""
    old_stty=$(stty -g 2>/dev/null)
    stty echo icanon 2>/dev/null || true
    read -r response
    # 恢复之前的终端状态
    if [[ -n "$old_stty" ]]; then
        stty "$old_stty" 2>/dev/null || stty -echo -icanon 2>/dev/null || true
    else
        stty -echo -icanon 2>/dev/null || true
    fi

    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${YELLOW}正在卸载WarpKit...${NC}"

        # 删除主程序
        local script_path="$(readlink -f "$0")"
        local script_dir=$(dirname "$script_path")
        local script_name=$(basename "$script_path")

        echo -e "${BLUE}删除主程序...${NC}"
        if [[ -f "$script_path" ]]; then
            # 创建一个临时脚本来删除自己
            local temp_uninstall="/tmp/warpkit_uninstall.sh"
            cat > "$temp_uninstall" << 'EOF'
#!/bin/bash
sleep 1
rm -f "$1" 2>/dev/null || {
    echo "无法删除主程序文件，可能需要管理员权限"
    echo "请手动删除: $1"
}
rm -f "$0"
EOF
            chmod +x "$temp_uninstall"
        fi

        # 删除配置文件
        echo -e "${BLUE}删除配置文件...${NC}"
        if [[ -d "$CONFIG_DIR" ]]; then
            rm -rf "$CONFIG_DIR" && echo -e "${GREEN}✅ 配置文件删除完成${NC}" || echo -e "${YELLOW}⚠️ 配置文件删除失败${NC}"
        fi

        # 删除缓存文件
        echo -e "${BLUE}删除缓存文件...${NC}"
        if [[ -d "$CACHE_DIR" ]]; then
            rm -rf "$CACHE_DIR" && echo -e "${GREEN}✅ 缓存文件删除完成${NC}" || echo -e "${YELLOW}⚠️ 缓存文件删除失败${NC}"
        fi

        # 删除备份文件
        echo -e "${BLUE}删除备份文件...${NC}"
        find /etc -name "resolv.conf.backup.*" -type f 2>/dev/null | while read backup_file; do
            rm -f "$backup_file" 2>/dev/null && echo -e "${GREEN}✅ 删除备份: $(basename "$backup_file")${NC}"
        done

        find /usr/local/bin -name "warpkit.backup.*" -type f 2>/dev/null | while read backup_file; do
            rm -f "$backup_file" 2>/dev/null && echo -e "${GREEN}✅ 删除备份: $(basename "$backup_file")${NC}"
        done

        echo ""
        echo -e "${GREEN}${BOLD}🎉 WarpKit卸载完成！${NC}"
        echo -e "${YELLOW}感谢您使用WarpKit！${NC}"
        echo ""

        # 执行临时卸载脚本并退出
        if [[ -f "$temp_uninstall" ]]; then
            exec "$temp_uninstall" "$script_path"
        else
            exit 0
        fi
    else
        echo -e "${YELLOW}取消卸载操作${NC}"
        echo ""
        echo "按任意键返回脚本管理菜单"
        read -n1
    fi
}

# 显示版本信息
show_version_info() {
    clear
    echo -e "${BLUE}${BOLD}版本信息${NC}"
    echo ""

    echo -e "${CYAN}WarpKit 详细信息:${NC}"
    echo ""
    echo -e "${GREEN}版本: $(get_current_version)${NC}"
    echo -e "${GREEN}脚本路径: $(readlink -f "$0")${NC}"
    echo -e "${GREEN}配置目录: $CONFIG_DIR${NC}"
    echo -e "${GREEN}缓存目录: $CACHE_DIR${NC}"

    if [[ -f "$CONFIG_DIR/current_version" ]]; then
        local stored_version=$(cat "$CONFIG_DIR/current_version" 2>/dev/null)
        echo -e "${GREEN}存储版本: $stored_version${NC}"
    fi

    echo ""
    echo -e "${CYAN}系统信息:${NC}"
    echo -e "${GREEN}操作系统: $DISTRO $VERSION${NC}"
    echo -e "${GREEN}内核版本: $KERNEL${NC}"
    echo -e "${GREEN}架构: $ARCH${NC}"

    echo ""
    echo -e "${CYAN}GitHub仓库: ${GREEN}https://github.com/$GITHUB_REPO${NC}"

    echo ""
    echo "按任意键返回脚本管理菜单"
    read -n1
}

# 清理缓存文件
clean_cache_files() {
    clear
    echo -e "${BLUE}${BOLD}清理缓存文件${NC}"
    echo ""

    local cache_size=0
    if [[ -d "$CACHE_DIR" ]]; then
        cache_size=$(du -sh "$CACHE_DIR" 2>/dev/null | cut -f1)
        echo -e "${YELLOW}当前缓存大小: $cache_size${NC}"
    else
        echo -e "${YELLOW}未找到缓存目录${NC}"
    fi

    echo ""
    echo -e "${CYAN}确定要清理所有缓存文件吗？ [y/N]${NC}"
    # 临时恢复终端模式进行输入
    local old_stty=""
    old_stty=$(stty -g 2>/dev/null)
    stty echo icanon 2>/dev/null || true
    read -r response
    # 恢复之前的终端状态
    if [[ -n "$old_stty" ]]; then
        stty "$old_stty" 2>/dev/null || stty -echo -icanon 2>/dev/null || true
    else
        stty -echo -icanon 2>/dev/null || true
    fi

    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${YELLOW}正在清理缓存...${NC}"

        if [[ -d "$CACHE_DIR" ]]; then
            rm -rf "$CACHE_DIR"/* 2>/dev/null && {
                echo -e "${GREEN}✅ 缓存文件清理完成${NC}"
            } || {
                echo -e "${YELLOW}⚠️ 缓存文件清理失败${NC}"
            }
        fi

        # 重建必要的缓存目录
        mkdir -p "$CACHE_DIR"
        echo -e "${GREEN}✅ 缓存目录重建完成${NC}"
    else
        echo -e "${YELLOW}取消清理操作${NC}"
    fi

    echo ""
    echo "按任意键返回脚本管理菜单"
    read -n1
}

# 主函数
main() {
    # 处理命令行参数
    parse_arguments "$@"

    # 检查是否在Linux环境中运行
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        echo -e "${RED}错误: 此工具只能在Linux系统中运行${NC}"
        exit 1
    fi

    # 检测系统信息
    detect_distro

    # 初始化模块系统
    init_module_system && debug_log "模块系统初始化成功" || debug_log "模块系统初始化失败，使用内置功能"

    # 设置退出时恢复终端
    trap 'restore_terminal_state; exit' EXIT INT TERM

    # 每日首次启动时检查更新（在设置终端模式之前）
    check_for_updates

    # 开始导航（新的选择器不需要预先设置终端模式）
    handle_navigation
}

# 运行主函数
main "$@"