#!/bin/bash

# WarpKit 安装脚本

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# 安装路径
INSTALL_PREFIX="/usr/local"
BIN_DIR="$INSTALL_PREFIX/bin"
LIB_DIR="$INSTALL_PREFIX/lib/warpkit"
CONFIG_DIR="$HOME/.config/warpkit"

# GitHub仓库信息
GITHUB_REPO="marvinli001/warpkit"
GITHUB_RAW_URL="https://raw.githubusercontent.com/$GITHUB_REPO/master"

# 脚本目录（兼容管道安装）
if [[ -n "${BASH_SOURCE[0]:-}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="/tmp"
fi

# 检测安装模式
if [[ -f "$SCRIPT_DIR/warpkit.sh" ]] && [[ -d "$SCRIPT_DIR/modules" ]]; then
    INSTALL_MODE="local"
    echo "检测到本地安装模式"
else
    INSTALL_MODE="remote"
    echo "使用远程安装模式"
fi

print_header() {
    echo -e "${CYAN}${BOLD}"
    echo "██╗    ██╗ █████╗ ██████╗ ██████╗ ██╗  ██╗██╗████████╗"
    echo "██║    ██║██╔══██╗██╔══██╗██╔══██╗██║ ██╔╝██║╚══██╔══╝"
    echo "██║ █╗ ██║███████║██████╔╝██████╔╝█████╔╝ ██║   ██║   "
    echo "██║███╗██║██╔══██║██╔══██╗██╔═══╝ ██╔═██╗ ██║   ██║   "
    echo "╚███╔███╔╝██║  ██║██║  ██║██║     ██║  ██╗██║   ██║   "
    echo " ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝╚═╝   ╚═╝   "
    echo -e "${NC}"
    echo -e "${YELLOW}WarpKit 安装程序${NC}"
    echo ""
}

print_usage() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --uninstall  卸载 WarpKit"
    echo "  --help       显示此帮助"
    echo ""
    echo "安装位置:"
    echo "  程序:   $BIN_DIR/warpkit"
    echo "  配置:   $CONFIG_DIR/"
}

check_permissions() {
    if [[ $EUID -eq 0 ]]; then
        echo -e "${YELLOW}检测到root权限，将安装到系统目录${NC}"
    else
        echo -e "${YELLOW}非root用户，将安装到用户目录${NC}"
        BIN_DIR="$HOME/.local/bin"
        LIB_DIR="$HOME/.local/lib/warpkit"
    fi
}

# 下载文件函数
download_file() {
    local url="$1"
    local output="$2"

    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" -o "$output"
    elif command -v wget >/dev/null 2>&1; then
        wget -qO "$output" "$url"
    else
        echo -e "${RED}[ERROR] 需要 curl 或 wget 来下载文件${NC}"
        return 1
    fi
}

# 下载WarpKit文件
download_warpkit_files() {
    echo -e "${BLUE}下载WarpKit文件...${NC}"

    local temp_dir="/tmp/warpkit_install_$$"
    mkdir -p "$temp_dir/modules"

    # 下载主程序
    echo -e "${CYAN}下载主程序...${NC}"
    if ! download_file "$GITHUB_RAW_URL/warpkit.sh" "$temp_dir/warpkit.sh"; then
        echo -e "${RED}[ERROR] 主程序下载失败${NC}"
        rm -rf "$temp_dir"
        return 1
    fi

    # 下载模块
    echo -e "${CYAN}下载功能模块...${NC}"
    local modules=("system.sh" "packages.sh" "network.sh" "logs.sh")
    for module in "${modules[@]}"; do
        echo -e "${CYAN}  下载 $module...${NC}"
        if ! download_file "$GITHUB_RAW_URL/modules/$module" "$temp_dir/modules/$module"; then
            echo -e "${RED}[ERROR] 模块 $module 下载失败${NC}"
            rm -rf "$temp_dir"
            return 1
        fi
    done

    # 更新脚本目录为下载目录
    SCRIPT_DIR="$temp_dir"
    echo -e "${GREEN}[OK] 所有文件下载完成${NC}"
}

install_warpkit() {
    echo -e "${BLUE}安装WarpKit...${NC}"

    # 远程安装模式需要先下载文件
    if [[ "$INSTALL_MODE" == "remote" ]]; then
        if ! download_warpkit_files; then
            return 1
        fi
    fi

    # 检查必要文件是否存在
    if [[ ! -f "$SCRIPT_DIR/warpkit.sh" ]]; then
        echo -e "${RED}[ERROR] 错误: 找不到 warpkit.sh${NC}"
        if [[ "$INSTALL_MODE" == "local" ]]; then
            echo -e "${YELLOW}请确保在WarpKit项目目录中运行安装程序${NC}"
        fi
        return 1
    fi

    # 创建必要目录
    mkdir -p "$BIN_DIR"
    mkdir -p "$CONFIG_DIR"

    # 复制主程序
    cp "$SCRIPT_DIR/warpkit.sh" "$BIN_DIR/warpkit"
    chmod +x "$BIN_DIR/warpkit"

    # 复制程序组件（modules目录）
    if [[ -d "$SCRIPT_DIR/modules" ]]; then
        mkdir -p "$LIB_DIR/modules"
        cp -r "$SCRIPT_DIR/modules/"* "$LIB_DIR/modules/"
        chmod +x "$LIB_DIR/modules/"*.sh
    fi

    # 清理临时文件（仅远程安装，带安全检查）
    if [[ "$INSTALL_MODE" == "remote" ]]; then
        # 严格检查路径安全性
        if [[ "$SCRIPT_DIR" == "/tmp/warpkit_install_"* ]] && \
           [[ -d "$SCRIPT_DIR" ]] && \
           [[ "$SCRIPT_DIR" != "/" ]] && \
           [[ "$SCRIPT_DIR" != "/tmp" ]]; then
            rm -rf "$SCRIPT_DIR"
        fi
    fi

    echo -e "${GREEN}${BOLD}WarpKit安装完成！${NC}"
}

uninstall_warpkit() {
    echo -e "${RED}${BOLD}卸载 WarpKit...${NC}"

    local files_to_remove=(
        "$BIN_DIR/warpkit"
        "$LIB_DIR"
        "$HOME/.local/bin/warpkit"
        "$HOME/.local/lib/warpkit"
    )

    for file in "${files_to_remove[@]}"; do
        if [[ -e "$file" ]]; then
            echo -e "${YELLOW}删除: $file${NC}"
            rm -rf "$file"
        fi
    done

    echo -e "${CYAN}是否删除配置目录 $CONFIG_DIR? [y/N]${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        rm -rf "$CONFIG_DIR"
        echo -e "${YELLOW}配置目录已删除${NC}"
    fi

    echo -e "${GREEN}[SUCCESS] 卸载完成${NC}"
}

verify_installation() {
    echo -e "${BLUE}验证安装...${NC}"

    # 检查主程序
    local warpkit_path=""
    if [[ -x "$BIN_DIR/warpkit" ]]; then
        warpkit_path="$BIN_DIR/warpkit"
    elif [[ -x "$HOME/.local/bin/warpkit" ]]; then
        warpkit_path="$HOME/.local/bin/warpkit"
    fi

    if [[ -n "$warpkit_path" ]]; then
        echo -e "${GREEN}[OK] 主程序: $warpkit_path${NC}"

        # 测试版本
        local version=$("$warpkit_path" --version 2>/dev/null || echo "unknown")
        echo -e "${CYAN}   版本: $version${NC}"
    else
        echo -e "${RED}[ERROR] 主程序未找到${NC}"
        return 1
    fi

    # 程序完整性检查
    local component_dirs=(
        "$LIB_DIR/modules"
        "$HOME/.local/lib/warpkit/modules"
    )

    local components_found=false
    for dir in "${component_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local required_components=("system.sh" "packages.sh" "network.sh" "logs.sh")
            local missing_components=()

            for component in "${required_components[@]}"; do
                if [[ ! -f "$dir/$component" ]]; then
                    missing_components+=("$component")
                fi
            done

            if [[ ${#missing_components[@]} -eq 0 ]]; then
                echo -e "${GREEN}[OK] 程序完整性检查通过${NC}"
                components_found=true
            else
                echo -e "${RED}[ERROR] 程序不完整，缺少组件:${NC}"
                for missing in "${missing_components[@]}"; do
                    echo -e "${RED}   - $missing${NC}"
                done
                return 1
            fi
            break
        fi
    done

    if [[ "$components_found" == "false" ]]; then
        echo -e "${RED}[ERROR] 未找到程序组件目录${NC}"
        return 1
    fi

    echo ""
    echo -e "${CYAN}安装验证完成${NC}"
}

post_install_info() {
    echo ""
    echo -e "${CYAN}${BOLD}安装后说明:${NC}"
    echo ""

    # PATH检查
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        echo -e "${YELLOW}注意: $BIN_DIR 不在 PATH 中${NC}"
        echo "请将以下行添加到 ~/.bashrc 或 ~/.zshrc:"
        echo "  export PATH=\"$BIN_DIR:\$PATH\""
        echo ""
    fi

    echo -e "${GREEN}使用方法:${NC}"
    echo "  warpkit          # 启动交互界面"
    echo "  warpkit --help   # 查看帮助"
    echo "  warpkit --version # 查看版本"
    echo ""

    echo -e "${GREEN}主要功能:${NC}"
    echo "  - 系统监控 (实时状态、进程管理、内存分析)"
    echo "  - 包管理 (智能搜索、依赖分析、安全检查)"
    echo "  - 网络工具 (诊断、SSL检查、防火墙管理)"
    echo "  - 日志分析 (实时监控、搜索、统计)"
    echo ""

    echo -e "${CYAN}配置目录: $CONFIG_DIR${NC}"
    echo -e "${CYAN}GitHub: https://github.com/marvinli001/warpkit${NC}"
}

main() {
    print_header

    case "${1:-}" in
        --uninstall)
            uninstall_warpkit
            ;;
        --help|-h)
            print_usage
            ;;
        "")
            check_permissions
            install_warpkit
            verify_installation
            post_install_info
            ;;
        *)
            echo -e "${RED}未知选项: $1${NC}"
            print_usage
            exit 1
            ;;
    esac
}

# 检查是否在Linux环境中运行
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo -e "${RED}错误: 此安装程序只能在Linux系统中运行${NC}"
    exit 1
fi

# 运行主函数
main "$@"