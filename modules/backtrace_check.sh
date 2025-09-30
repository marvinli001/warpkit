#!/bin/bash
# WarpKit - 回程路由检测模块
# 基于 oneclickvirt/backtrace 项目
# 项目地址: https://github.com/oneclickvirt/backtrace

BACKTRACE_VERSION="output"
GITHUB_REPO="oneclickvirt/backtrace"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 检测系统架构
detect_arch() {
    local os=$(uname -s)
    local arch=$(uname -m)

    case $os in
        Linux)
            OS_TYPE="linux"
            ;;
        Darwin)
            OS_TYPE="darwin"
            ;;
        FreeBSD)
            OS_TYPE="freebsd"
            ;;
        OpenBSD)
            OS_TYPE="openbsd"
            ;;
        *)
            echo -e "${RED}不支持的操作系统: $os${NC}"
            return 1
            ;;
    esac

    case $arch in
        "x86_64" | "x86" | "amd64" | "x64")
            ARCH_TYPE="amd64"
            ;;
        "i386" | "i686")
            ARCH_TYPE="386"
            ;;
        "armv7l" | "armv8" | "armv8l" | "aarch64" | "arm64")
            ARCH_TYPE="arm64"
            ;;
        *)
            echo -e "${RED}不支持的架构: $arch${NC}"
            return 1
            ;;
    esac

    BINARY_NAME="backtrace-${OS_TYPE}-${ARCH_TYPE}"
    return 0
}

# 下载 backtrace 二进制文件
download_backtrace() {
    local temp_dir="$1"
    local binary_path="${temp_dir}/backtrace"

    echo -e "${CYAN}正在下载 backtrace 工具...${NC}"

    # 尝试的下载源
    local download_urls=(
        "https://github.com/${GITHUB_REPO}/releases/download/${BACKTRACE_VERSION}/${BINARY_NAME}"
        "https://ghproxy.com/https://github.com/${GITHUB_REPO}/releases/download/${BACKTRACE_VERSION}/${BINARY_NAME}"
        "https://mirror.ghproxy.com/https://github.com/${GITHUB_REPO}/releases/download/${BACKTRACE_VERSION}/${BINARY_NAME}"
    )

    for url in "${download_urls[@]}"; do
        echo -e "${YELLOW}尝试: $url${NC}"
        if curl -fsSL "$url" -o "$binary_path" --max-time 30 2>/dev/null; then
            if [[ -f "$binary_path" ]] && [[ -s "$binary_path" ]]; then
                chmod +x "$binary_path"
                echo -e "${GREEN}✓ 下载成功${NC}"
                return 0
            fi
        fi
        echo -e "${YELLOW}⚠ 此源失败，尝试下一个...${NC}"
    done

    echo -e "${RED}✗ 所有下载源均失败${NC}"
    return 1
}

# 运行回程路由检测
run_backtrace() {
    local binary_path="$1"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}开始回程路由检测...${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # 执行 backtrace
    "$binary_path"
    local exit_code=$?

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    return $exit_code
}

# 主函数
main() {
    # 检测系统架构
    if ! detect_arch; then
        return 1
    fi

    echo -e "${BLUE}检测到系统: ${OS_TYPE} ${ARCH_TYPE}${NC}"
    echo ""

    # 创建临时目录
    local temp_dir=$(mktemp -d)
    local binary_path="${temp_dir}/backtrace"

    # 下载工具
    if ! download_backtrace "$temp_dir"; then
        echo -e "${RED}下载失败，无法继续${NC}"
        rm -rf "$temp_dir"
        return 1
    fi

    # 运行检测
    run_backtrace "$binary_path"
    local result=$?

    # 清理临时文件
    rm -rf "$temp_dir"

    if [[ $result -eq 0 ]]; then
        echo -e "${GREEN}检测完成！${NC}"
    else
        echo -e "${YELLOW}检测完成（部分项可能失败）${NC}"
    fi

    return $result
}

# 执行主函数
main