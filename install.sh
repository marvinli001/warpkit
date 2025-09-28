#!/bin/bash

# WarpKit 安装脚本
# 默认安装完整版本

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

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

install_basic() {
    echo -e "${BLUE}安装基础版本...${NC}"

    # 创建目录
    mkdir -p "$BIN_DIR"
    mkdir -p "$CONFIG_DIR"

    # 复制主程序
    cp "$SCRIPT_DIR/warpkit.sh" "$BIN_DIR/warpkit"
    chmod +x "$BIN_DIR/warpkit"

    echo -e "${GREEN}✅ 基础版本安装完成${NC}"
    echo -e "${CYAN}主程序路径: $BIN_DIR/warpkit${NC}"
}

install_modules() {
    echo -e "${BLUE}安装增强功能...${NC}"

    # 创建程序目录
    mkdir -p "$LIB_DIR/modules"

    # 复制功能文件
    if [[ -d "$SCRIPT_DIR/modules" ]]; then
        cp -r "$SCRIPT_DIR/modules/"* "$LIB_DIR/modules/"
        chmod +x "$LIB_DIR/modules/"*.sh

        echo -e "${GREEN}✅ 增强功能安装完成${NC}"
    else
        echo -e "${RED}❌ 未找到功能文件${NC}"
        return 1
    fi
}

install_full() {
    echo -e "${BLUE}安装WarpKit...${NC}"
    install_basic
    install_modules
    echo -e "${GREEN}${BOLD}🎉 WarpKit安装完成！${NC}"
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

    echo -e "${GREEN}✅ 卸载完成${NC}"
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
        echo -e "${GREEN}✅ 主程序: $warpkit_path${NC}"

        # 测试版本
        local version=$("$warpkit_path" --version 2>/dev/null || echo "unknown")
        echo -e "${CYAN}   版本: $version${NC}"
    else
        echo -e "${RED}❌ 主程序未找到${NC}"
        return 1
    fi

    # 检查模块
    local module_dirs=(
        "$LIB_DIR/modules"
        "$HOME/.local/lib/warpkit/modules"
    )

    local modules_found=false
    for dir in "${module_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local module_count=$(find "$dir" -name "*.sh" | wc -l)
            if [[ $module_count -gt 0 ]]; then
                echo -e "${GREEN}✅ 功能目录: $dir ($module_count 个功能)${NC}"
                modules_found=true
                break
            fi
        fi
    done

    if [[ "$modules_found" == "false" ]]; then
        echo -e "${YELLOW}⚠️  基础版本（只包含核心功能）${NC}"
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

    if [[ -d "$LIB_DIR/modules" ]] || [[ -d "$HOME/.local/lib/warpkit/modules" ]]; then
        echo -e "${GREEN}增强功能:${NC}"
        echo "  - 系统监控增强功能"
        echo "  - 智能包管理"
        echo "  - 网络诊断工具"
        echo "  - 日志分析工具"
        echo ""
    fi

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
            install_full
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