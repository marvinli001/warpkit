#!/bin/bash

# WarpKit 构建脚本
# 用于准备发布包和验证项目

set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 项目信息
PROJECT_NAME="warpkit"
VERSION="1.0.0"

# 路径定义
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/.."
BUILD_DIR="${PROJECT_ROOT}/build"
DIST_DIR="${PROJECT_ROOT}/dist"

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 进度显示
show_progress() {
    local current=$1
    local total=$2
    local message=${3:-"构建中"}
    local width=40

    local percentage=$((current * 100 / total))
    local completed=$((current * width / total))
    local remaining=$((width - completed))

    printf "\r${BLUE}%s: [" "$message"
    printf "%${completed}s" | tr ' ' '▓'
    printf "%${remaining}s" | tr ' ' '░'
    printf "] %d%%${NC}" "$percentage"

    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# 清理构建目录
clean_build() {
    log_info "清理构建目录..."

    if [[ -d "$BUILD_DIR" ]]; then
        rm -rf "$BUILD_DIR"
    fi

    if [[ -d "$DIST_DIR" ]]; then
        rm -rf "$DIST_DIR"
    fi

    mkdir -p "$BUILD_DIR" "$DIST_DIR"
    log_success "构建目录已清理"
}

# 验证项目结构
validate_project() {
    log_info "验证项目结构..."

    local required_files=(
        "warpkit.sh"
        "install.sh"
        "README.md"
        "LICENSE"
        "CHANGELOG.md"
    )

    local missing_files=()

    for file in "${required_files[@]}"; do
        if [[ ! -f "${PROJECT_ROOT}/${file}" ]]; then
            missing_files+=("$file")
        fi
    done

    if [[ ${#missing_files[@]} -gt 0 ]]; then
        log_error "缺少必需文件:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        return 1
    fi

    log_success "项目结构验证通过"
}

# 运行测试
run_tests() {
    log_info "运行测试套件..."

    if [[ -f "${PROJECT_ROOT}/tests/basic_test.sh" ]]; then
        chmod +x "${PROJECT_ROOT}/tests/basic_test.sh"
        if "${PROJECT_ROOT}/tests/basic_test.sh"; then
            log_success "所有测试通过"
        else
            log_error "测试失败"
            return 1
        fi
    else
        log_warning "未找到测试文件，跳过测试"
    fi
}

# 检查脚本语法
check_syntax() {
    log_info "检查脚本语法..."

    local scripts=(
        "${PROJECT_ROOT}/warpkit.sh"
        "${PROJECT_ROOT}/install.sh"
    )

    for script in "${scripts[@]}"; do
        if ! bash -n "$script"; then
            log_error "脚本语法错误: $script"
            return 1
        fi
    done

    log_success "脚本语法检查通过"
}

# 生成版本信息
generate_version_info() {
    log_info "生成版本信息..."

    local version_file="${BUILD_DIR}/VERSION"
    local build_info="${BUILD_DIR}/BUILD_INFO"

    echo "$VERSION" > "$version_file"

    cat > "$build_info" << EOF
# WarpKit 构建信息
VERSION=$VERSION
BUILD_DATE=$(date -u +"%Y-%m-%d %H:%M:%S UTC")
BUILD_HOST=$(hostname)
BUILD_USER=$(whoami)
GIT_COMMIT=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
EOF

    log_success "版本信息已生成"
}

# 复制文件到构建目录
copy_files() {
    log_info "复制文件到构建目录..."

    # 复制主要文件
    cp "${PROJECT_ROOT}/warpkit.sh" "$BUILD_DIR/"
    cp "${PROJECT_ROOT}/install.sh" "$BUILD_DIR/"
    cp "${PROJECT_ROOT}/README.md" "$BUILD_DIR/"
    cp "${PROJECT_ROOT}/LICENSE" "$BUILD_DIR/"
    cp "${PROJECT_ROOT}/CHANGELOG.md" "$BUILD_DIR/"

    # 复制目录
    if [[ -d "${PROJECT_ROOT}/docs" ]]; then
        cp -r "${PROJECT_ROOT}/docs" "$BUILD_DIR/"
    fi

    if [[ -d "${PROJECT_ROOT}/examples" ]]; then
        cp -r "${PROJECT_ROOT}/examples" "$BUILD_DIR/"
    fi

    log_success "文件复制完成"
}

# 设置文件权限
set_permissions() {
    log_info "设置文件权限..."

    # 设置脚本可执行权限
    chmod +x "${BUILD_DIR}/warpkit.sh"
    chmod +x "${BUILD_DIR}/install.sh"

    # 设置示例脚本权限
    if [[ -d "${BUILD_DIR}/examples" ]]; then
        find "${BUILD_DIR}/examples" -name "*.sh" -exec chmod +x {} \;
    fi

    log_success "文件权限设置完成"
}

# 创建发布包
create_release_package() {
    log_info "创建发布包..."

    local package_name="${PROJECT_NAME}-v${VERSION}"
    local tar_file="${DIST_DIR}/${package_name}.tar.gz"
    local zip_file="${DIST_DIR}/${package_name}.zip"

    # 重命名构建目录
    mv "$BUILD_DIR" "${PROJECT_ROOT}/${package_name}"

    # 创建 tar.gz 包
    tar -czf "$tar_file" -C "$PROJECT_ROOT" "$package_name"

    # 创建 zip 包
    if command -v zip >/dev/null; then
        (cd "$PROJECT_ROOT" && zip -r "$zip_file" "$package_name")
    fi

    # 恢复构建目录名称
    mv "${PROJECT_ROOT}/${package_name}" "$BUILD_DIR"

    log_success "发布包已创建:"
    log_info "  - $tar_file"
    if [[ -f "$zip_file" ]]; then
        log_info "  - $zip_file"
    fi
}

# 生成校验和
generate_checksums() {
    log_info "生成校验和..."

    local checksum_file="${DIST_DIR}/checksums.txt"

    (cd "$DIST_DIR" && sha256sum *.tar.gz *.zip 2>/dev/null > "$checksum_file" || true)

    if [[ -f "$checksum_file" ]]; then
        log_success "校验和已生成: $checksum_file"
    fi
}

# 显示构建统计
show_build_stats() {
    log_info "构建统计:"

    echo "  项目名称: $PROJECT_NAME"
    echo "  版本: $VERSION"
    echo "  构建时间: $(date)"

    if [[ -d "$BUILD_DIR" ]]; then
        local file_count=$(find "$BUILD_DIR" -type f | wc -l)
        local total_size=$(du -sh "$BUILD_DIR" | cut -f1)
        echo "  文件数量: $file_count"
        echo "  总大小: $total_size"
    fi

    if [[ -d "$DIST_DIR" ]]; then
        echo "  发布包:"
        ls -lh "$DIST_DIR"/*.tar.gz "$DIST_DIR"/*.zip 2>/dev/null | while read -r line; do
            echo "    $line"
        done
    fi
}

# 主构建流程
main() {
    echo "=== WarpKit 构建脚本 ==="
    echo "版本: $VERSION"
    echo

    local steps=(
        "clean_build"
        "validate_project"
        "check_syntax"
        "run_tests"
        "generate_version_info"
        "copy_files"
        "set_permissions"
        "create_release_package"
        "generate_checksums"
    )

    local step_names=(
        "清理构建目录"
        "验证项目结构"
        "检查脚本语法"
        "运行测试"
        "生成版本信息"
        "复制文件"
        "设置权限"
        "创建发布包"
        "生成校验和"
    )

    for i in "${!steps[@]}"; do
        show_progress $((i+1)) ${#steps[@]} "构建进度"

        if ! "${steps[$i]}"; then
            log_error "构建失败: ${step_names[$i]}"
            exit 1
        fi

        sleep 0.5
    done

    echo
    log_success "构建完成！"
    echo
    show_build_stats
}

# 处理命令行参数
case "${1:-}" in
    clean)
        clean_build
        ;;
    test)
        run_tests
        ;;
    package)
        create_release_package
        ;;
    *)
        main
        ;;
esac