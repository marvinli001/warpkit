#!/bin/bash

# WarpKit 基础测试脚本

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

# 测试计数器
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# 测试结果记录
declare -a FAILED_TESTS=()

# 脚本路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WARPKIT_PATH="${SCRIPT_DIR}/../warpkit.sh"

# 日志函数
log_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
}

# 测试函数
run_test() {
    local test_name="$1"
    local test_command="$2"

    ((TESTS_RUN++))

    echo -n "测试 ${TESTS_RUN}: ${test_name}... "

    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}通过${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}失败${NC}"
        ((TESTS_FAILED++))
        FAILED_TESTS+=("$test_name")
    fi
}

# 检查文件是否存在
test_file_exists() {
    [[ -f "$1" ]]
}

# 检查文件是否可执行
test_file_executable() {
    [[ -x "$1" ]]
}

# 检查脚本语法
test_script_syntax() {
    bash -n "$1"
}

# 检查函数是否存在
test_function_exists() {
    local script="$1"
    local function_name="$2"

    source "$script" && declare -f "$function_name" >/dev/null
}

# 测试系统检测功能
test_system_detection() {
    source "$WARPKIT_PATH"
    detect_distro
    [[ -n "$DISTRO" ]] && [[ -n "$VERSION" ]] && [[ -n "$KERNEL" ]] && [[ -n "$ARCH" ]]
}

# 开始测试
echo "=== WarpKit 基础测试 ==="
echo

log_info "开始运行测试套件..."
echo

# 1. 文件存在性测试
run_test "WarpKit 主脚本存在" "test_file_exists '$WARPKIT_PATH'"
run_test "安装脚本存在" "test_file_exists '${SCRIPT_DIR}/../install.sh'"
run_test "README 文件存在" "test_file_exists '${SCRIPT_DIR}/../README.md'"
run_test "许可证文件存在" "test_file_exists '${SCRIPT_DIR}/../LICENSE'"

# 2. 可执行性测试
run_test "WarpKit 脚本可执行" "test_file_executable '$WARPKIT_PATH'"
run_test "安装脚本可执行" "test_file_executable '${SCRIPT_DIR}/../install.sh'"

# 3. 语法检查
run_test "WarpKit 脚本语法正确" "test_script_syntax '$WARPKIT_PATH'"
run_test "安装脚本语法正确" "test_script_syntax '${SCRIPT_DIR}/../install.sh'"

# 4. 函数存在性测试
run_test "detect_distro 函数存在" "test_function_exists '$WARPKIT_PATH' 'detect_distro'"
run_test "show_system_info 函数存在" "test_function_exists '$WARPKIT_PATH' 'show_system_info'"
run_test "show_progress 函数存在" "test_function_exists '$WARPKIT_PATH' 'show_progress'"
run_test "update_status 函数存在" "test_function_exists '$WARPKIT_PATH' 'update_status'"
run_test "loading_animation 函数存在" "test_function_exists '$WARPKIT_PATH' 'loading_animation'"

# 5. 功能测试
run_test "系统检测功能" "test_system_detection"

# 6. 依赖检查
run_test "bash 命令可用" "command -v bash >/dev/null"
run_test "uname 命令可用" "command -v uname >/dev/null"
run_test "date 命令可用" "command -v date >/dev/null"

echo
echo "=== 测试结果 ==="
echo "总计: $TESTS_RUN"
echo -e "通过: ${GREEN}$TESTS_PASSED${NC}"
echo -e "失败: ${RED}$TESTS_FAILED${NC}"

if [[ $TESTS_FAILED -gt 0 ]]; then
    echo
    echo "失败的测试:"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "  ${RED}✗${NC} $test"
    done
    echo
    exit 1
else
    echo
    log_success "所有测试通过！"
    exit 0
fi