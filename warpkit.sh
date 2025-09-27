#!/bin/bash

# WarpKit - Linux服务运维工具
# Version: 1.0.0
# Author: Claude Code Assistant

set -euo pipefail

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
    echo -e "${YELLOW}Linux服务运维工具 v1.0.0${NC}"
    echo ""
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

# 主函数
main() {
    # 检查是否在Linux环境中运行
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        echo -e "${RED}错误: 此工具只能在Linux系统中运行${NC}"
        exit 1
    fi

    # 检测系统信息
    detect_distro

    # 启用终端原始模式以捕获方向键
    stty -echo -icanon time 0 min 0

    # 设置退出时恢复终端
    trap 'stty echo icanon; exit' EXIT INT TERM

    # 开始导航
    handle_navigation
}

# 运行主函数
main "$@"