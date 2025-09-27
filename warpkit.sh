#!/bin/bash

# WarpKit - Linux服务运维工具
# WARPKIT_COMMIT: 0ec9341
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

# 更新相关变量
declare -r GITHUB_REPO="marvinli001/warpkit"
declare -r CONFIG_DIR="$HOME/.config/warpkit"
declare -r CACHE_DIR="$HOME/.cache/warpkit"
declare -r UPDATE_CHECK_FILE="$CACHE_DIR/last_update_check"

# 动态获取当前版本 (Git commit hash)
get_current_version() {
    # 尝试从脚本中提取嵌入的commit hash
    local embedded_hash=$(grep -o "# WARPKIT_COMMIT: [a-f0-9]\{7,\}" "$0" 2>/dev/null | cut -d' ' -f3)
    if [[ -n "$embedded_hash" ]]; then
        echo "$embedded_hash"
        return
    fi

    # 如果在git仓库中，获取当前commit
    if git rev-parse --git-dir >/dev/null 2>&1; then
        git rev-parse --short HEAD 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
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
    echo -e "${YELLOW}Linux服务运维工具 $(get_current_version)${NC}"
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

    # 更新下载文件中的commit hash
    echo -e "${BLUE}🔄 更新版本信息...${NC}"
    sed -i "s/# WARPKIT_COMMIT: [a-f0-9]\{7,\}/# WARPKIT_COMMIT: $new_version/" "$temp_file"

    # 替换当前脚本
    echo -e "${BLUE}🔄 安装新版本...${NC}"
    if cp "$temp_file" "$script_path" && chmod +x "$script_path"; then
        rm -f "$temp_file"
        echo -e "${GREEN}✅ 更新成功！已更新到 $new_version${NC}"
        echo -e "${YELLOW}备份文件保存在: $backup_path${NC}"
        echo -e "${CYAN}重新启动 WarpKit 以使用新版本...${NC}"
        sleep 2
        exec "$script_path" "$@"
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
        "服务管理"
        "包管理"
        "网络工具"
        "安全工具"
        "日志查看"
        "系统更新"
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

# 读取单个按键
read_key() {
    local key
    read -rsn1 key

    case "$key" in
        $'\x1b')  # ESC序列
            read -rsn2 key
            case "$key" in
                '[A') echo "UP" ;;
                '[B') echo "DOWN" ;;
                *) echo "OTHER" ;;
            esac
            ;;
        '') echo "ENTER" ;;
        'q'|'Q') echo "QUIT" ;;
        *) echo "OTHER" ;;
    esac
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
        "服务管理")
            show_service_management
            ;;
        "包管理")
            show_package_management
            ;;
        "网络工具")
            show_network_tools
            ;;
        "安全工具")
            show_security_tools
            ;;
        "日志查看")
            show_log_viewer
            ;;
        "系统更新")
            show_system_update
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

# 服务管理演示
show_service_management() {
    clear
    echo -e "${BLUE}${BOLD}服务管理${NC}"
    echo ""

    local services=("检查服务状态" "列出运行中的服务" "显示服务详情")
    multi_step_task "${services[@]}"

    echo ""
    echo "按任意键返回主菜单"
    read -n1
}

# 包管理演示
show_package_management() {
    clear
    echo -e "${BLUE}${BOLD}包管理${NC}"
    echo ""

    update_status "info" "检测包管理器: $DISTRO"

    case "$DISTRO" in
        "ubuntu"|"debian")
            show_command_output "apt list --upgradable" "检查可更新的包"
            ;;
        "centos"|"rhel"|"fedora")
            show_command_output "yum check-update || true" "检查可更新的包"
            ;;
        "arch")
            show_command_output "pacman -Qu" "检查可更新的包"
            ;;
        *)
            update_status "warning" "未知的包管理器"
            ;;
    esac

    echo ""
    echo "按任意键返回主菜单"
    read -n1
}

# 网络工具演示
show_network_tools() {
    clear
    echo -e "${BLUE}${BOLD}网络工具${NC}"
    echo ""

    loading_animation "初始化网络检测" 1

    update_status "info" "网络连接测试"
    show_command_output "ping -c 3 8.8.8.8" "测试网络连接"
    show_command_output "ss -tulpn" "显示网络连接状态"

    echo ""
    echo "按任意键返回主菜单"
    read -n1
}

# 安全工具演示
show_security_tools() {
    clear
    echo -e "${BLUE}${BOLD}安全工具${NC}"
    echo ""

    local security_checks=("检查登录历史" "分析系统日志" "验证文件权限" "检查开放端口")

    for i in "${!security_checks[@]}"; do
        show_progress $((i+1)) ${#security_checks[@]} "安全检查"
        update_status "working" "${security_checks[$i]}"
        sleep 1
        update_status "success" "${security_checks[$i]} 完成"
    done

    echo ""
    echo "按任意键返回主菜单"
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
            *)
                echo -e "${RED}未知选项: $1${NC}"
                echo "使用 --help 查看可用选项"
                exit 1
                ;;
        esac
    done
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

    # 每日首次启动时检查更新
    check_for_updates

    # 启用终端原始模式以捕获方向键
    stty -echo -icanon

    # 设置退出时恢复终端
    trap 'stty echo icanon; exit' EXIT INT TERM

    # 开始导航
    handle_navigation
}

# 运行主函数
main "$@"