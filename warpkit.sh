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
        # 临时恢复终端模式进行输入
        restore_terminal_state
        read -r response
        set_raw_terminal
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

    # 下载新版本
    echo -e "${BLUE}⬇️ 下载新版本...${NC}"
    local temp_file="/tmp/warpkit_update.sh"

    if command -v curl >/dev/null 2>&1; then
        if ! curl -fsSL "https://raw.githubusercontent.com/$GITHUB_REPO/master/warpkit.sh" -o "$temp_file"; then
            echo -e "${RED}❌ 下载失败${NC}"
            return 1
        fi
    elif command -v wget >/dev/null 2>&1; then
        if ! wget -qO "$temp_file" "https://raw.githubusercontent.com/$GITHUB_REPO/master/warpkit.sh"; then
            echo -e "${RED}❌ 下载失败${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ 需要 curl 或 wget 来下载更新${NC}"
        return 1
    fi

    # 验证下载的文件
    if [[ ! -s "$temp_file" ]]; then
        echo -e "${RED}❌ 下载的文件无效${NC}"
        rm -f "$temp_file"
        return 1
    fi

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

# 检测Linux发行版
detect_distro() {
    # 首先尝试从 /etc/os-release 获取信息（最标准的方法）
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        DISTRO="$ID"
        VERSION="${VERSION_ID:-$VERSION}"

    # Ubuntu/Debian 系统的 lsb-release
    elif [[ -f /etc/lsb-release ]]; then
        source /etc/lsb-release
        DISTRO=$(echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]')
        VERSION="$DISTRIB_RELEASE"

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
                source /etc/os-release
                if [[ -n "${ID_LIKE:-}" ]]; then
                    DISTRO="$ID_LIKE"
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

# 打印菜单项
print_menu_item() {
    local index=$1
    local text=$2
    local is_selected=$3

    if [[ $is_selected -eq 1 ]]; then
        echo -e "  ${GREEN}▶ ${BOLD}$text${NC}"
    else
        echo -e "    $text"
    fi
}

# 显示主菜单
show_main_menu() {
    MENU_OPTIONS=(
        "系统监控"
        "包管理"
        "网络工具"
        "日志查看"
        "脚本管理"
        "退出"
    )

    print_logo
    show_system_info

    echo -e "${BOLD}${PURPLE}主菜单:${NC}"
    echo ""

    for i in "${!MENU_OPTIONS[@]}"; do
        if [[ $i -eq $CURRENT_SELECTION ]]; then
            print_menu_item $i "${MENU_OPTIONS[$i]}" 1
        else
            print_menu_item $i "${MENU_OPTIONS[$i]}" 0
        fi
    done

    echo ""
    echo -e "${YELLOW}使用 ↑/↓ 选择，Enter 确认，q 退出${NC}"
}

# 保存和恢复终端状态
save_terminal_state() {
    stty -g > "/tmp/warpkit_terminal_state.$$" 2>/dev/null
}

restore_terminal_state() {
    if [[ -f "/tmp/warpkit_terminal_state.$$" ]]; then
        stty "$(cat "/tmp/warpkit_terminal_state.$$")" 2>/dev/null
        rm -f "/tmp/warpkit_terminal_state.$$" 2>/dev/null
    else
        stty sane 2>/dev/null
    fi
}

# 设置原始终端模式
set_raw_terminal() {
    stty -echo -icanon min 0 time 1 2>/dev/null
}

# 调试输出
debug_log() {
    if [[ "$DEBUG_MODE" == "true" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# 读取单个按键 - 重新设计更可靠的版本
read_key() {
    local key=""
    local keyseq=""

    debug_log "read_key: 开始读取按键"

    # 尝试读取最多3个字符（方向键是3字符序列）
    if IFS= read -r -n3 -t 0.5 keyseq 2>/dev/null; then
        debug_log "read_key: 读取到序列: $(printf '%q' "$keyseq") (长度: ${#keyseq})"

        case "$keyseq" in
            $'\e[A')
                debug_log "read_key: 检测到上方向键"
                echo "UP" ;;
            $'\e[B')
                debug_log "read_key: 检测到下方向键"
                echo "DOWN" ;;
            $'\e[C')
                debug_log "read_key: 检测到右方向键"
                echo "RIGHT" ;;
            $'\e[D')
                debug_log "read_key: 检测到左方向键"
                echo "LEFT" ;;
            'q'|'Q')
                debug_log "read_key: 检测到退出键"
                echo "QUIT" ;;
            '')
                debug_log "read_key: 检测到回车键"
                echo "ENTER" ;;
            $'\n')
                debug_log "read_key: 检测到换行符"
                echo "ENTER" ;;
            $'\r')
                debug_log "read_key: 检测到回车符"
                echo "ENTER" ;;
            *)
                # 如果是单字符
                if [[ ${#keyseq} -eq 1 ]]; then
                    key="$keyseq"
                    case "$key" in
                        'q'|'Q')
                            debug_log "read_key: 检测到单字符退出键"
                            echo "QUIT" ;;
                        '')
                            debug_log "read_key: 检测到单字符回车"
                            echo "ENTER" ;;
                        *)
                            debug_log "read_key: 检测到其他单字符: $(printf '%q' "$key")"
                            echo "OTHER" ;;
                    esac
                else
                    debug_log "read_key: 检测到其他序列: $(printf '%q' "$keyseq")"
                    echo "OTHER"
                fi
                ;;
        esac
    else
        debug_log "read_key: 读取超时或失败"
        echo "OTHER"
    fi
}

# 处理菜单导航
handle_navigation() {
    while true; do
        show_main_menu

        local key=$(read_key)

        case "$key" in
            "UP")
                if [[ $CURRENT_SELECTION -gt 0 ]]; then
                    ((CURRENT_SELECTION--))
                else
                    CURRENT_SELECTION=$((${#MENU_OPTIONS[@]} - 1))
                fi
                ;;
            "DOWN")
                if [[ $CURRENT_SELECTION -lt $((${#MENU_OPTIONS[@]} - 1)) ]]; then
                    ((CURRENT_SELECTION++))
                else
                    CURRENT_SELECTION=0
                fi
                ;;
            "ENTER")
                handle_menu_selection
                ;;
            "QUIT")
                echo -e "\n${YELLOW}再见！${NC}"
                exit 0
                ;;
            "OTHER")
                # 忽略其他按键，继续循环
                ;;
            *)
                # 对于未识别的按键，也忽略
                ;;
        esac
    done
}

# 处理菜单选择
handle_menu_selection() {
    local selected_option="${MENU_OPTIONS[$CURRENT_SELECTION]}"

    case "$selected_option" in
        "系统监控")
            show_system_monitor
            ;;
        "包管理")
            show_package_management
            ;;
        "网络工具")
            show_network_tools
            ;;
        "日志查看")
            show_log_viewer
            ;;
        "脚本管理")
            show_script_management
            ;;
        "退出")
            echo -e "\n${YELLOW}再见！${NC}"
            exit 0
            ;;
    esac
}

# 系统监控演示
show_system_monitor() {
    clear
    echo -e "${BLUE}${BOLD}系统监控${NC}"
    echo ""

    loading_animation "正在收集系统信息" 2

    update_status "info" "显示系统状态"
    show_command_output "uptime" "获取系统运行时间"
    show_command_output "free -h" "检查内存使用情况"
    show_command_output "df -h" "检查磁盘使用情况"

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

# 包管理菜单
show_package_management() {
    local pkg_selection=0
    local pkg_manager=$(detect_package_manager)
    local pkg_options=(
        "更新软件包列表"
        "检查可更新的包"
        "安装常用软件"
        "搜索软件包"
        "清理包缓存"
        "查看已安装包"
        "返回主菜单"
    )

    while true; do
        clear
        print_logo

        echo -e "${BLUE}${BOLD}包管理${NC}"
        echo ""
        echo -e "${CYAN}检测到的包管理器: ${GREEN}$pkg_manager${NC}"
        echo ""

        if [[ "$pkg_manager" == "unknown" ]]; then
            echo -e "${RED}❌ 未检测到支持的包管理器${NC}"
            echo ""
            echo "按任意键返回主菜单"
            read -n1
            return
        fi

        for i in "${!pkg_options[@]}"; do
            if [[ $i -eq $pkg_selection ]]; then
                echo -e "  ${GREEN}▶ ${pkg_options[$i]}${NC}"
            else
                echo -e "    ${pkg_options[$i]}"
            fi
        done

        echo ""
        echo -e "${YELLOW}使用 ↑/↓ 选择，Enter 确认，q 返回主菜单${NC}"

        local key=$(read_key)
        case "$key" in
            "UP")
                if [[ $pkg_selection -gt 0 ]]; then
                    ((pkg_selection--))
                else
                    pkg_selection=$((${#pkg_options[@]} - 1))
                fi
                ;;
            "DOWN")
                if [[ $pkg_selection -lt $((${#pkg_options[@]} - 1)) ]]; then
                    ((pkg_selection++))
                else
                    pkg_selection=0
                fi
                ;;
            "ENTER")
                case $pkg_selection in
                    0) update_package_list "$pkg_manager" ;;
                    1) check_updates "$pkg_manager" ;;
                    2) install_common_packages "$pkg_manager" ;;
                    3) search_packages "$pkg_manager" ;;
                    4) clean_package_cache "$pkg_manager" ;;
                    5) list_installed_packages "$pkg_manager" ;;
                    6) return ;;
                esac
                ;;
            "QUIT")
                return
                ;;
            "OTHER")
                # 忽略其他按键，继续循环
                ;;
            *)
                # 对于未识别的按键，也忽略
                ;;
        esac
    done
}

# 更新软件包列表
update_package_list() {
    local pkg_manager="$1"
    clear
    echo -e "${BLUE}${BOLD}更新软件包列表${NC}"
    echo ""

    case "$pkg_manager" in
        "apt")
            echo -e "${YELLOW}正在更新APT软件包列表...${NC}"
            apt update 2>&1 | while IFS= read -r line; do
                echo "  $line"
            done
            ;;
        "yum")
            echo -e "${YELLOW}正在更新YUM软件包列表...${NC}"
            yum check-update >/dev/null 2>&1
            echo -e "${GREEN}✅ YUM软件包列表更新完成${NC}"
            ;;
        "dnf")
            echo -e "${YELLOW}正在更新DNF软件包列表...${NC}"
            dnf check-update >/dev/null 2>&1
            echo -e "${GREEN}✅ DNF软件包列表更新完成${NC}"
            ;;
        "pacman")
            echo -e "${YELLOW}正在更新Pacman软件包列表...${NC}"
            pacman -Sy --noconfirm
            ;;
        "zypper")
            echo -e "${YELLOW}正在更新Zypper软件包列表...${NC}"
            zypper refresh
            ;;
        "apk")
            echo -e "${YELLOW}正在更新APK软件包列表...${NC}"
            apk update
            ;;
    esac

    echo ""
    echo "按任意键返回包管理菜单"
    read -n1
}

# 检查可更新的包
check_updates() {
    local pkg_manager="$1"
    clear
    echo -e "${BLUE}${BOLD}检查可更新的包${NC}"
    echo ""

    case "$pkg_manager" in
        "apt")
            echo -e "${YELLOW}检查APT可更新的包...${NC}"
            apt list --upgradable 2>/dev/null | head -20
            ;;
        "yum")
            echo -e "${YELLOW}检查YUM可更新的包...${NC}"
            yum check-update 2>/dev/null | head -20
            ;;
        "dnf")
            echo -e "${YELLOW}检查DNF可更新的包...${NC}"
            dnf check-update 2>/dev/null | head -20
            ;;
        "pacman")
            echo -e "${YELLOW}检查Pacman可更新的包...${NC}"
            pacman -Qu | head -20
            ;;
        "zypper")
            echo -e "${YELLOW}检查Zypper可更新的包...${NC}"
            zypper list-updates | head -20
            ;;
        "apk")
            echo -e "${YELLOW}检查APK可更新的包...${NC}"
            apk version -l '<' | head -20
            ;;
    esac

    echo ""
    echo "按任意键返回包管理菜单"
    read -n1
}

# 安装常用软件
install_common_packages() {
    local pkg_manager="$1"
    clear
    echo -e "${BLUE}${BOLD}安装常用软件${NC}"
    echo ""

    local common_tools=("curl" "wget" "vim" "git" "htop" "tree" "unzip")

    echo -e "${YELLOW}常用软件包:${NC}"
    for tool in "${common_tools[@]}"; do
        echo "  • $tool"
    done

    echo ""
    echo -e "${CYAN}是否安装这些常用软件包？ [y/N]${NC}"
    # 临时恢复终端模式进行输入
    stty echo icanon 2>/dev/null
    read -r response
    stty -echo -icanon 2>/dev/null

    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${YELLOW}正在安装常用软件...${NC}"

        case "$pkg_manager" in
            "apt")
                apt install -y "${common_tools[@]}"
                ;;
            "yum")
                yum install -y "${common_tools[@]}"
                ;;
            "dnf")
                dnf install -y "${common_tools[@]}"
                ;;
            "pacman")
                pacman -S --noconfirm "${common_tools[@]}"
                ;;
            "zypper")
                zypper install -y "${common_tools[@]}"
                ;;
            "apk")
                apk add "${common_tools[@]}"
                ;;
        esac

        echo -e "${GREEN}✅ 常用软件安装完成${NC}"
    else
        echo -e "${YELLOW}取消安装操作${NC}"
    fi

    echo ""
    echo "按任意键返回包管理菜单"
    read -n1
}

# 搜索软件包
search_packages() {
    local pkg_manager="$1"
    clear
    echo -e "${BLUE}${BOLD}搜索软件包${NC}"
    echo ""

    echo -e "${CYAN}请输入要搜索的软件包名称:${NC}"
    # 临时恢复终端模式进行输入
    restore_terminal_state
    read -r search_term
    set_raw_terminal

    if [[ -n "$search_term" ]]; then
        echo ""
        echo -e "${YELLOW}搜索结果 '$search_term':${NC}"
        echo ""

        case "$pkg_manager" in
            "apt")
                apt search "$search_term" 2>/dev/null | head -20
                ;;
            "yum")
                yum search "$search_term" 2>/dev/null | head -20
                ;;
            "dnf")
                dnf search "$search_term" 2>/dev/null | head -20
                ;;
            "pacman")
                pacman -Ss "$search_term" | head -20
                ;;
            "zypper")
                zypper search "$search_term" | head -20
                ;;
            "apk")
                apk search "$search_term" | head -20
                ;;
        esac
    fi

    echo ""
    echo "按任意键返回包管理菜单"
    read -n1
}

# 清理包缓存
clean_package_cache() {
    local pkg_manager="$1"
    clear
    echo -e "${BLUE}${BOLD}清理包缓存${NC}"
    echo ""

    echo -e "${YELLOW}这将清理软件包管理器的缓存文件${NC}"
    echo -e "${CYAN}是否继续？ [y/N]${NC}"
    # 临时恢复终端模式进行输入
    stty echo icanon 2>/dev/null
    read -r response
    stty -echo -icanon 2>/dev/null

    if [[ "$response" =~ ^[Yy]$ ]]; then
        echo ""
        echo -e "${YELLOW}正在清理缓存...${NC}"

        case "$pkg_manager" in
            "apt")
                apt autoclean && apt autoremove -y
                echo -e "${GREEN}✅ APT缓存清理完成${NC}"
                ;;
            "yum")
                yum clean all
                echo -e "${GREEN}✅ YUM缓存清理完成${NC}"
                ;;
            "dnf")
                dnf clean all
                echo -e "${GREEN}✅ DNF缓存清理完成${NC}"
                ;;
            "pacman")
                pacman -Sc --noconfirm
                echo -e "${GREEN}✅ Pacman缓存清理完成${NC}"
                ;;
            "zypper")
                zypper clean -a
                echo -e "${GREEN}✅ Zypper缓存清理完成${NC}"
                ;;
            "apk")
                rm -rf /var/cache/apk/*
                echo -e "${GREEN}✅ APK缓存清理完成${NC}"
                ;;
        esac
    else
        echo -e "${YELLOW}取消清理操作${NC}"
    fi

    echo ""
    echo "按任意键返回包管理菜单"
    read -n1
}

# 查看已安装包
list_installed_packages() {
    local pkg_manager="$1"
    clear
    echo -e "${BLUE}${BOLD}已安装的软件包${NC}"
    echo ""

    echo -e "${YELLOW}显示前20个已安装的软件包:${NC}"
    echo ""

    case "$pkg_manager" in
        "apt")
            dpkg -l | head -20
            ;;
        "yum")
            yum list installed | head -20
            ;;
        "dnf")
            dnf list installed | head -20
            ;;
        "pacman")
            pacman -Q | head -20
            ;;
        "zypper")
            zypper search --installed-only | head -20
            ;;
        "apk")
            apk info | head -20
            ;;
    esac

    echo ""
    echo "按任意键返回包管理菜单"
    read -n1
}


# 网络工具菜单
show_network_tools() {
    local network_selection=0
    local network_options=(
        "DNS服务器修复"
        "BBR加速配置"
        "网络连接测试"
        "网络配置查看"
        "端口扫描工具"
        "返回主菜单"
    )

    while true; do
        clear
        print_logo

        echo -e "${BLUE}${BOLD}网络工具${NC}"
        echo ""

        for i in "${!network_options[@]}"; do
            if [[ $i -eq $network_selection ]]; then
                echo -e "  ${GREEN}▶ ${network_options[$i]}${NC}"
            else
                echo -e "    ${network_options[$i]}"
            fi
        done

        echo ""
        echo -e "${YELLOW}使用 ↑/↓ 选择，Enter 确认，q 返回主菜单${NC}"

        local key=$(read_key)
        case "$key" in
            "UP")
                if [[ $network_selection -gt 0 ]]; then
                    ((network_selection--))
                else
                    network_selection=$((${#network_options[@]} - 1))
                fi
                ;;
            "DOWN")
                if [[ $network_selection -lt $((${#network_options[@]} - 1)) ]]; then
                    ((network_selection++))
                else
                    network_selection=0
                fi
                ;;
            "ENTER")
                case $network_selection in
                    0) show_dns_repair_menu ;;
                    1) show_bbr_config ;;
                    2) test_network_connection ;;
                    3) show_network_config ;;
                    4) show_port_scanner ;;
                    5) return ;;
                esac
                ;;
            "QUIT")
                return
                ;;
            "OTHER")
                # 忽略其他按键，继续循环
                ;;
            *)
                # 对于未识别的按键，也忽略
                ;;
        esac
    done
}

# BBR加速配置菜单
show_bbr_config() {
    local bbr_selection=0
    local bbr_options=(
        "检查BBR状态"
        "启用BBR加速"
        "禁用BBR加速"
        "返回网络工具菜单"
    )

    while true; do
        clear
        print_logo

        echo -e "${BLUE}${BOLD}BBR加速配置${NC}"
        echo ""

        for i in "${!bbr_options[@]}"; do
            if [[ $i -eq $bbr_selection ]]; then
                echo -e "  ${GREEN}▶ ${bbr_options[$i]}${NC}"
            else
                echo -e "    ${bbr_options[$i]}"
            fi
        done

        echo ""
        echo -e "${YELLOW}使用 ↑/↓ 选择，Enter 确认，q 返回${NC}"

        local key=$(read_key)
        case "$key" in
            "UP")
                if [[ $bbr_selection -gt 0 ]]; then
                    ((bbr_selection--))
                else
                    bbr_selection=$((${#bbr_options[@]} - 1))
                fi
                ;;
            "DOWN")
                if [[ $bbr_selection -lt $((${#bbr_options[@]} - 1)) ]]; then
                    ((bbr_selection++))
                else
                    bbr_selection=0
                fi
                ;;
            "ENTER")
                case $bbr_selection in
                    0) check_bbr_status ;;
                    1) enable_bbr ;;
                    2) disable_bbr ;;
                    3) return ;;
                esac
                ;;
            "QUIT")
                return
                ;;
            "OTHER")
                # 忽略其他按键，继续循环
                ;;
            *)
                # 对于未识别的按键，也忽略
                ;;
        esac
    done
}

# 检查BBR状态
check_bbr_status() {
    clear
    echo -e "${BLUE}${BOLD}BBR状态检查${NC}"
    echo ""

    # 检查内核版本
    local kernel_version=$(uname -r)
    echo -e "${CYAN}当前内核版本: ${GREEN}$kernel_version${NC}"

    # 检查BBR是否可用
    if [[ -f /proc/sys/net/ipv4/tcp_available_congestion_control ]]; then
        local available_cc=$(cat /proc/sys/net/ipv4/tcp_available_congestion_control)
        echo -e "${CYAN}可用拥塞控制算法: ${YELLOW}$available_cc${NC}"

        if echo "$available_cc" | grep -q "bbr"; then
            echo -e "${GREEN}✅ BBR算法可用${NC}"
        else
            echo -e "${RED}❌ BBR算法不可用${NC}"
        fi
    fi

    # 检查当前使用的拥塞控制算法
    if [[ -f /proc/sys/net/ipv4/tcp_congestion_control ]]; then
        local current_cc=$(cat /proc/sys/net/ipv4/tcp_congestion_control)
        echo -e "${CYAN}当前拥塞控制算法: ${GREEN}$current_cc${NC}"

        if [[ "$current_cc" == "bbr" ]]; then
            echo -e "${GREEN}✅ BBR已启用${NC}"
        else
            echo -e "${YELLOW}⚠️  BBR未启用${NC}"
        fi
    fi

    # 检查内核模块
    echo ""
    echo -e "${CYAN}BBR模块状态:${NC}"
    if lsmod | grep -q "tcp_bbr"; then
        echo -e "${GREEN}✅ tcp_bbr模块已加载${NC}"
    else
        echo -e "${YELLOW}⚠️  tcp_bbr模块未加载${NC}"
    fi

    echo ""
    echo "按任意键返回BBR配置菜单"
    read -n1
}

# 启用BBR
enable_bbr() {
    clear
    echo -e "${BLUE}${BOLD}启用BBR加速${NC}"
    echo ""

    # 检查内核版本支持
    local kernel_version=$(uname -r)
    local major_version=$(echo "$kernel_version" | cut -d'.' -f1)
    local minor_version=$(echo "$kernel_version" | cut -d'.' -f2)

    echo -e "${CYAN}检查内核版本支持...${NC}"
    echo -e "${YELLOW}当前内核: $kernel_version${NC}"

    # BBR需要内核4.9+
    if [[ $major_version -lt 4 ]] || [[ $major_version -eq 4 && $minor_version -lt 9 ]]; then
        echo -e "${RED}❌ BBR需要内核版本4.9或更高${NC}"
        echo -e "${YELLOW}当前内核版本过低，需要升级内核${NC}"
        echo ""
        echo -e "${CYAN}是否尝试安装新内核？ [y/N]${NC}"
        # 临时恢复终端模式进行输入
        stty echo icanon 2>/dev/null
        read -r install_kernel
        stty -echo -icanon 2>/dev/null

        if [[ "$install_kernel" =~ ^[Yy]$ ]]; then
            install_kernel_for_bbr
        else
            echo -e "${YELLOW}取消BBR启用${NC}"
        fi
        echo ""
        echo "按任意键返回BBR配置菜单"
        read -n1
        return
    fi

    echo -e "${GREEN}✅ 内核版本支持BBR${NC}"
    echo ""

    # 检查BBR是否已经启用
    if [[ -f /proc/sys/net/ipv4/tcp_congestion_control ]]; then
        local current_cc=$(cat /proc/sys/net/ipv4/tcp_congestion_control)
        if [[ "$current_cc" == "bbr" ]]; then
            echo -e "${GREEN}✅ BBR已经启用${NC}"
            echo ""
            echo "按任意键返回BBR配置菜单"
            read -n1
            return
        fi
    fi

    echo -e "${YELLOW}正在启用BBR...${NC}"

    # 加载BBR模块
    echo -e "${CYAN}加载tcp_bbr模块...${NC}"
    if modprobe tcp_bbr 2>/dev/null; then
        echo -e "${GREEN}✅ tcp_bbr模块加载成功${NC}"
    else
        echo -e "${YELLOW}⚠️  模块加载失败，继续尝试配置${NC}"
    fi

    # 配置内核参数
    echo -e "${CYAN}配置内核参数...${NC}"

    # 备份原始配置
    if [[ ! -f /etc/sysctl.conf.backup.warpkit ]]; then
        cp /etc/sysctl.conf /etc/sysctl.conf.backup.warpkit 2>/dev/null || true
    fi

    # 添加BBR配置到sysctl.conf
    {
        echo ""
        echo "# WarpKit BBR Configuration"
        echo "net.core.default_qdisc=fq"
        echo "net.ipv4.tcp_congestion_control=bbr"
    } >> /etc/sysctl.conf

    # 应用配置
    echo -e "${CYAN}应用配置...${NC}"
    sysctl -p >/dev/null 2>&1

    # 立即启用BBR
    echo "fq" > /proc/sys/net/core/default_qdisc 2>/dev/null || true
    echo "bbr" > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || true

    # 验证配置
    echo ""
    echo -e "${CYAN}验证BBR状态...${NC}"

    local current_cc=$(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo "unknown")
    local current_qdisc=$(cat /proc/sys/net/core/default_qdisc 2>/dev/null || echo "unknown")

    if [[ "$current_cc" == "bbr" ]]; then
        echo -e "${GREEN}✅ BBR启用成功${NC}"
        echo -e "${GREEN}   拥塞控制: $current_cc${NC}"
        echo -e "${GREEN}   队列调度: $current_qdisc${NC}"
        echo ""
        echo -e "${YELLOW}注意: 配置已写入/etc/sysctl.conf，重启后自动生效${NC}"
    else
        echo -e "${RED}❌ BBR启用失败${NC}"
        echo -e "${YELLOW}当前拥塞控制: $current_cc${NC}"
    fi

    echo ""
    echo "按任意键返回BBR配置菜单"
    read -n1
}

# 禁用BBR
disable_bbr() {
    clear
    echo -e "${BLUE}${BOLD}禁用BBR加速${NC}"
    echo ""

    # 检查BBR是否已启用
    local current_cc=$(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo "unknown")

    if [[ "$current_cc" != "bbr" ]]; then
        echo -e "${YELLOW}⚠️  BBR当前未启用${NC}"
        echo -e "${CYAN}当前拥塞控制算法: $current_cc${NC}"
        echo ""
        echo "按任意键返回BBR配置菜单"
        read -n1
        return
    fi

    echo -e "${YELLOW}当前BBR已启用，确定要禁用吗？ [y/N]${NC}"
    # 临时恢复终端模式进行输入
    stty echo icanon 2>/dev/null
    read -r confirm
    stty -echo -icanon 2>/dev/null

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}取消禁用操作${NC}"
        echo ""
        echo "按任意键返回BBR配置菜单"
        read -n1
        return
    fi

    echo ""
    echo -e "${YELLOW}正在禁用BBR...${NC}"

    # 恢复到cubic算法
    echo -e "${CYAN}切换到cubic算法...${NC}"
    echo "cubic" > /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || true
    echo "pfifo_fast" > /proc/sys/net/core/default_qdisc 2>/dev/null || true

    # 从sysctl.conf中移除BBR配置
    if [[ -f /etc/sysctl.conf ]]; then
        echo -e "${CYAN}移除sysctl.conf中的BBR配置...${NC}"
        sed -i '/# WarpKit BBR Configuration/,+2d' /etc/sysctl.conf 2>/dev/null || true
        sysctl -p >/dev/null 2>&1
    fi

    # 验证
    local new_cc=$(cat /proc/sys/net/ipv4/tcp_congestion_control 2>/dev/null || echo "unknown")
    echo ""
    echo -e "${CYAN}当前拥塞控制算法: ${GREEN}$new_cc${NC}"

    if [[ "$new_cc" != "bbr" ]]; then
        echo -e "${GREEN}✅ BBR已成功禁用${NC}"
    else
        echo -e "${RED}❌ BBR禁用失败${NC}"
    fi

    echo ""
    echo "按任意键返回BBR配置菜单"
    read -n1
}

# 为BBR安装新内核
install_kernel_for_bbr() {
    echo ""
    echo -e "${YELLOW}正在检测系统并安装新内核...${NC}"

    # 检测发行版
    local distro=$(detect_linux_distro)
    echo -e "${CYAN}检测到系统: $distro${NC}"

    case "$distro" in
        "centos6"|"centos7")
            echo -e "${YELLOW}CentOS 6/7 需要安装ELRepo内核${NC}"
            install_elrepo_kernel
            ;;
        "debian8"|"debian9"|"debian10")
            echo -e "${YELLOW}Debian 8/9/10 需要安装backports内核${NC}"
            install_debian_backports_kernel
            ;;
        "ubuntu16"|"ubuntu18")
            echo -e "${YELLOW}Ubuntu 16/18 需要安装HWE内核${NC}"
            install_ubuntu_hwe_kernel
            ;;
        *)
            echo -e "${RED}❌ 不支持的系统版本或系统已支持BBR${NC}"
            echo -e "${YELLOW}请手动升级内核到4.9+版本${NC}"
            ;;
    esac
}

# 检测Linux发行版详细信息
detect_linux_distro() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        local distro_id=$(echo "$ID" | tr '[:upper:]' '[:lower:]')
        local version_id="$VERSION_ID"

        case "$distro_id" in
            "centos")
                if [[ "$version_id" =~ ^6 ]]; then
                    echo "centos6"
                elif [[ "$version_id" =~ ^7 ]]; then
                    echo "centos7"
                else
                    echo "centos"
                fi
                ;;
            "debian")
                if [[ "$version_id" =~ ^8 ]]; then
                    echo "debian8"
                elif [[ "$version_id" =~ ^9 ]]; then
                    echo "debian9"
                elif [[ "$version_id" =~ ^10 ]]; then
                    echo "debian10"
                else
                    echo "debian"
                fi
                ;;
            "ubuntu")
                if [[ "$version_id" =~ ^16 ]]; then
                    echo "ubuntu16"
                elif [[ "$version_id" =~ ^18 ]]; then
                    echo "ubuntu18"
                else
                    echo "ubuntu"
                fi
                ;;
            *)
                echo "$distro_id"
                ;;
        esac
    else
        echo "unknown"
    fi
}

# 安装ELRepo内核 (CentOS 6/7)
install_elrepo_kernel() {
    echo -e "${CYAN}安装ELRepo源和新内核...${NC}"

    # 导入GPG密钥
    rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org

    # 安装ELRepo源
    local centos_version=$(rpm -q --queryformat '%{VERSION}' centos-release)
    if [[ "$centos_version" =~ ^6 ]]; then
        yum install -y https://www.elrepo.org/elrepo-release-6.el6.elrepo.noarch.rpm
    else
        yum install -y https://www.elrepo.org/elrepo-release-7.el7.elrepo.noarch.rpm
    fi

    # 安装最新内核
    yum --enablerepo=elrepo-kernel install -y kernel-ml

    echo -e "${GREEN}✅ 新内核安装完成${NC}"
    echo -e "${YELLOW}⚠️  请重启系统并选择新内核后再启用BBR${NC}"
}

# 安装Debian backports内核
install_debian_backports_kernel() {
    echo -e "${CYAN}添加Debian backports源并安装新内核...${NC}"

    # 添加backports源
    echo "deb http://deb.debian.org/debian $(lsb_release -sc)-backports main" > /etc/apt/sources.list.d/backports.list

    # 更新包列表
    apt update

    # 安装新内核
    apt install -y -t $(lsb_release -sc)-backports linux-image-amd64

    echo -e "${GREEN}✅ 新内核安装完成${NC}"
    echo -e "${YELLOW}⚠️  请重启系统后再启用BBR${NC}"
}

# 安装Ubuntu HWE内核
install_ubuntu_hwe_kernel() {
    echo -e "${CYAN}安装Ubuntu HWE内核...${NC}"

    # 安装HWE内核
    apt update
    apt install -y linux-generic-hwe-$(lsb_release -rs | cut -d'.' -f1).04

    echo -e "${GREEN}✅ HWE内核安装完成${NC}"
    echo -e "${YELLOW}⚠️  请重启系统后再启用BBR${NC}"
}

# DNS修复菜单
show_dns_repair_menu() {
    local dns_selection=0
    local dns_options=(
        "Google DNS (8.8.8.8, 8.8.4.4)"
        "Cloudflare DNS (1.1.1.1, 1.0.0.1)"
        "查看当前DNS配置"
        "恢复默认DNS配置"
        "返回网络工具菜单"
    )

    while true; do
        clear
        print_logo

        echo -e "${BLUE}${BOLD}DNS服务器修复${NC}"
        echo ""
        echo -e "${YELLOW}选择要设置的DNS服务器:${NC}"
        echo ""

        for i in "${!dns_options[@]}"; do
            if [[ $i -eq $dns_selection ]]; then
                echo -e "  ${GREEN}▶ ${dns_options[$i]}${NC}"
            else
                echo -e "    ${dns_options[$i]}"
            fi
        done

        echo ""
        echo -e "${YELLOW}使用 ↑/↓ 选择，Enter 确认，q 返回${NC}"

        local key=$(read_key)
        case "$key" in
            "UP")
                if [[ $dns_selection -gt 0 ]]; then
                    ((dns_selection--))
                else
                    dns_selection=$((${#dns_options[@]} - 1))
                fi
                ;;
            "DOWN")
                if [[ $dns_selection -lt $((${#dns_options[@]} - 1)) ]]; then
                    ((dns_selection++))
                else
                    dns_selection=0
                fi
                ;;
            "ENTER")
                case $dns_selection in
                    0) set_google_dns ;;
                    1) set_cloudflare_dns ;;
                    2) show_current_dns ;;
                    3) restore_default_dns ;;
                    4) return ;;
                esac
                ;;
            "QUIT")
                return
                ;;
            "OTHER")
                # 忽略其他按键，继续循环
                ;;
            *)
                # 对于未识别的按键，也忽略
                ;;
        esac
    done
}

# 设置Google DNS
set_google_dns() {
    clear
    echo -e "${BLUE}${BOLD}设置Google DNS${NC}"
    echo ""

    echo -e "${YELLOW}正在备份当前DNS配置...${NC}"
    backup_dns_config

    echo -e "${YELLOW}正在设置Google DNS (8.8.8.8, 8.8.4.4)...${NC}"

    # 备份原始resolv.conf
    if [[ -f /etc/resolv.conf ]]; then
        cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    fi

    # 写入新的DNS配置
    cat > /etc/resolv.conf << EOF
# Google DNS Configuration
# Generated by WarpKit $(date)
nameserver 8.8.8.8
nameserver 8.8.4.4
EOF

    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Google DNS设置成功！${NC}"
        echo ""
        echo -e "${CYAN}新的DNS配置:${NC}"
        echo "  主DNS: 8.8.8.8"
        echo "  备DNS: 8.8.4.4"
    else
        echo -e "${RED}❌ DNS设置失败，可能需要管理员权限${NC}"
    fi

    echo ""
    echo -e "${YELLOW}正在测试DNS解析...${NC}"
    test_dns_resolution

    echo ""
    echo "按任意键返回DNS菜单"
    read -n1
}

# 设置Cloudflare DNS
set_cloudflare_dns() {
    clear
    echo -e "${BLUE}${BOLD}设置Cloudflare DNS${NC}"
    echo ""

    echo -e "${YELLOW}正在备份当前DNS配置...${NC}"
    backup_dns_config

    echo -e "${YELLOW}正在设置Cloudflare DNS (1.1.1.1, 1.0.0.1)...${NC}"

    # 备份原始resolv.conf
    if [[ -f /etc/resolv.conf ]]; then
        cp /etc/resolv.conf /etc/resolv.conf.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    fi

    # 写入新的DNS配置
    cat > /etc/resolv.conf << EOF
# Cloudflare DNS Configuration
# Generated by WarpKit $(date)
nameserver 1.1.1.1
nameserver 1.0.0.1
EOF

    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Cloudflare DNS设置成功！${NC}"
        echo ""
        echo -e "${CYAN}新的DNS配置:${NC}"
        echo "  主DNS: 1.1.1.1"
        echo "  备DNS: 1.0.0.1"
    else
        echo -e "${RED}❌ DNS设置失败，可能需要管理员权限${NC}"
    fi

    echo ""
    echo -e "${YELLOW}正在测试DNS解析...${NC}"
    test_dns_resolution

    echo ""
    echo "按任意键返回DNS菜单"
    read -n1
}

# 备份DNS配置
backup_dns_config() {
    local backup_dir="$CONFIG_DIR/dns_backups"
    local backup_file="$backup_dir/resolv.conf.backup.$(date +%Y%m%d_%H%M%S)"

    mkdir -p "$backup_dir"

    if [[ -f /etc/resolv.conf ]]; then
        cp /etc/resolv.conf "$backup_file" 2>/dev/null && {
            echo -e "${GREEN}✅ DNS配置已备份到: $backup_file${NC}"
        } || {
            echo -e "${YELLOW}⚠️ 无法备份DNS配置，继续执行...${NC}"
        }
    fi
}

# 显示当前DNS配置
show_current_dns() {
    clear
    echo -e "${BLUE}${BOLD}当前DNS配置${NC}"
    echo ""

    if [[ -f /etc/resolv.conf ]]; then
        echo -e "${CYAN}/etc/resolv.conf 内容:${NC}"
        echo ""
        cat /etc/resolv.conf | while IFS= read -r line; do
            if [[ $line =~ ^nameserver ]]; then
                echo -e "${GREEN}  $line${NC}"
            elif [[ $line =~ ^# ]]; then
                echo -e "${YELLOW}  $line${NC}"
            else
                echo "  $line"
            fi
        done
    else
        echo -e "${RED}❌ 未找到 /etc/resolv.conf 文件${NC}"
    fi

    echo ""
    echo -e "${YELLOW}正在测试DNS解析性能...${NC}"
    test_dns_resolution

    echo ""
    echo "按任意键返回DNS菜单"
    read -n1
}

# 恢复默认DNS配置
restore_default_dns() {
    clear
    echo -e "${BLUE}${BOLD}恢复默认DNS配置${NC}"
    echo ""

    local backup_dir="$CONFIG_DIR/dns_backups"
    local latest_backup=$(ls -t "$backup_dir"/resolv.conf.backup.* 2>/dev/null | head -1)

    if [[ -n "$latest_backup" ]]; then
        echo -e "${YELLOW}发现备份文件: $(basename "$latest_backup")${NC}"
        echo -e "${CYAN}是否恢复此备份？ [y/N]${NC}"
        # 临时恢复终端模式进行输入
        restore_terminal_state
        read -r response
        set_raw_terminal

        if [[ "$response" =~ ^[Yy]$ ]]; then
            cp "$latest_backup" /etc/resolv.conf 2>/dev/null && {
                echo -e "${GREEN}✅ DNS配置已恢复${NC}"
            } || {
                echo -e "${RED}❌ 恢复失败，可能需要管理员权限${NC}"
            }
        else
            echo -e "${YELLOW}取消恢复操作${NC}"
        fi
    else
        echo -e "${YELLOW}未找到备份文件，恢复为基本配置...${NC}"
        cat > /etc/resolv.conf << EOF
# Default DNS Configuration
# Restored by WarpKit $(date)
nameserver 8.8.8.8
nameserver 1.1.1.1
EOF
        echo -e "${GREEN}✅ 已设置为默认DNS配置${NC}"
    fi

    echo ""
    echo "按任意键返回DNS菜单"
    read -n1
}

# 测试DNS解析
test_dns_resolution() {
    local test_domains=("google.com" "cloudflare.com" "github.com")

    echo ""
    echo -e "${CYAN}DNS解析测试结果:${NC}"

    for domain in "${test_domains[@]}"; do
        local start_time=$(date +%s%N)
        if nslookup "$domain" >/dev/null 2>&1; then
            local end_time=$(date +%s%N)
            local duration=$(( (end_time - start_time) / 1000000 ))
            echo -e "${GREEN}  ✅ $domain - ${duration}ms${NC}"
        else
            echo -e "${RED}  ❌ $domain - 解析失败${NC}"
        fi
    done
}

# 网络连接测试
test_network_connection() {
    clear
    echo -e "${BLUE}${BOLD}网络连接测试${NC}"
    echo ""

    loading_animation "初始化网络检测" 1

    update_status "info" "网络连接测试"
    show_command_output "ping -c 3 8.8.8.8" "测试网络连接"
    show_command_output "ss -tulpn" "显示网络连接状态"

    echo ""
    echo "按任意键返回网络工具菜单"
    read -n1
}

# 显示网络配置
show_network_config() {
    clear
    echo -e "${BLUE}${BOLD}网络配置查看${NC}"
    echo ""

    echo -e "${CYAN}网络接口信息:${NC}"
    ip addr show | grep -E "(inet |inet6 )" | head -10

    echo ""
    echo -e "${CYAN}路由表信息:${NC}"
    ip route show | head -5

    echo ""
    echo -e "${CYAN}DNS配置:${NC}"
    cat /etc/resolv.conf 2>/dev/null || echo "无法读取DNS配置"

    echo ""
    echo "按任意键返回网络工具菜单"
    read -n1
}

# 端口扫描工具
show_port_scanner() {
    clear
    echo -e "${BLUE}${BOLD}端口扫描工具${NC}"
    echo ""

    echo -e "${YELLOW}常用端口检查:${NC}"
    local common_ports=(22 80 443 3306 5432 6379 27017)

    for port in "${common_ports[@]}"; do
        if ss -tuln | grep -q ":$port "; then
            echo -e "${GREEN}  ✅ 端口 $port - 开放${NC}"
        else
            echo -e "${RED}  ❌ 端口 $port - 关闭${NC}"
        fi
    done

    echo ""
    echo "按任意键返回网络工具菜单"
    read -n1
}

# 日志查看演示
show_log_viewer() {
    clear
    echo -e "${BLUE}${BOLD}日志查看${NC}"
    echo ""

    loading_animation "准备日志查看器" 1

    show_command_output "journalctl -n 10 --no-pager" "显示最近的系统日志"

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
    local script_selection=0
    local script_options=(
        "检查更新"
        "卸载WarpKit"
        "查看版本信息"
        "清理缓存文件"
        "返回主菜单"
    )

    while true; do
        clear
        print_logo

        echo -e "${BLUE}${BOLD}脚本管理${NC}"
        echo ""
        echo -e "${CYAN}当前版本: $(get_current_version)${NC}"
        echo ""

        for i in "${!script_options[@]}"; do
            if [[ $i -eq $script_selection ]]; then
                echo -e "  ${GREEN}▶ ${script_options[$i]}${NC}"
            else
                echo -e "    ${script_options[$i]}"
            fi
        done

        echo ""
        echo -e "${YELLOW}使用 ↑/↓ 选择，Enter 确认，q 返回主菜单${NC}"

        local key=$(read_key)
        case "$key" in
            "UP")
                if [[ $script_selection -gt 0 ]]; then
                    ((script_selection--))
                else
                    script_selection=$((${#script_options[@]} - 1))
                fi
                ;;
            "DOWN")
                if [[ $script_selection -lt $((${#script_options[@]} - 1)) ]]; then
                    ((script_selection++))
                else
                    script_selection=0
                fi
                ;;
            "ENTER")
                case $script_selection in
                    0) manual_check_update ;;
                    1) uninstall_warpkit ;;
                    2) show_version_info ;;
                    3) clean_cache_files ;;
                    4) return ;;
                esac
                ;;
            "QUIT")
                return
                ;;
            "OTHER")
                # 忽略其他按键，继续循环
                ;;
            *)
                # 对于未识别的按键，也忽略
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
    stty echo icanon 2>/dev/null
    read -r response
    stty -echo -icanon 2>/dev/null

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
    stty echo icanon 2>/dev/null
    read -r response
    stty -echo -icanon 2>/dev/null

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

    # 保存当前终端状态
    save_terminal_state

    # 设置退出时恢复终端
    trap 'restore_terminal_state; exit' EXIT INT TERM

    # 每日首次启动时检查更新（在设置终端模式之前）
    check_for_updates

    # 设置原始终端模式
    set_raw_terminal

    # 开始导航
    handle_navigation
}

# 运行主函数
main "$@"