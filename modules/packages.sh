#!/bin/bash

# WarpKit 包管理模块
# 这个模块提供增强的包管理功能

# 包管理主界面
show_package_management() {
    local pkg_manager=$(detect_package_manager)

    local pkg_options=(
        "智能包搜索"
        "包依赖分析"
        "系统更新管理"
        "包安全检查"
        "清理优化"
        "包历史记录"
        "返回主菜单"
    )

    if [[ "$pkg_manager" == "unknown" ]]; then
        clear
        echo -e "${RED}❌ 未检测到支持的包管理器${NC}"
        echo ""
        echo "支持的包管理器："
        echo "  • apt (Debian/Ubuntu)"
        echo "  • yum/dnf (RHEL/CentOS/Fedora)"
        echo "  • pacman (Arch Linux)"
        echo "  • zypper (openSUSE)"
        echo "  • apk (Alpine Linux)"
        echo ""
        echo "按任意键返回主菜单"
        read -n1
        return
    fi

    while true; do
        local result
        result=$(codex_selector "包管理" "检测到: $pkg_manager" 0 "${pkg_options[@]}")

        case "$result" in
            "CANCELLED")
                return
                ;;
            "SELECTOR_ERROR")
                # 切换到文本菜单模式
                show_package_management_text_menu "$pkg_manager"
                return
                ;;
            0) show_smart_search "$pkg_manager" ;;
            1) show_dependency_analysis "$pkg_manager" ;;
            2) show_update_management "$pkg_manager" ;;
            3) show_security_check "$pkg_manager" ;;
            4) show_cleanup_optimization "$pkg_manager" ;;
            5) show_package_history "$pkg_manager" ;;
            6) return ;;
            *)
                debug_log "packages module: 未知选择 $result"
                return
                ;;
        esac
    done
}

# 包管理文本菜单
show_package_management_text_menu() {
    local pkg_manager="$1"

    while true; do
        clear
        print_logo
        show_system_info

        echo -e "${CYAN}${BOLD}包管理${NC}"
        echo -e "${GREEN}检测到包管理器: $pkg_manager${NC}"
        echo ""
        echo "1. 智能包搜索"
        echo "2. 包依赖分析"
        echo "3. 系统更新管理"
        echo "4. 包安全检查"
        echo "5. 清理优化"
        echo "6. 包历史记录"
        echo "0. 返回主菜单"
        echo ""
        echo -n "请选择功能 (0-6): "

        read -r choice
        echo ""

        case "$choice" in
            1) show_smart_search "$pkg_manager" ;;
            2) show_dependency_analysis "$pkg_manager" ;;
            3) show_update_management "$pkg_manager" ;;
            4) show_security_check "$pkg_manager" ;;
            5) show_cleanup_optimization "$pkg_manager" ;;
            6) show_package_history "$pkg_manager" ;;
            0) return ;;
            *)
                echo -e "${RED}无效选择，请输入 0-6${NC}"
                sleep 2
                ;;
        esac
    done
}

# 智能包搜索
show_smart_search() {
    local pkg_manager="$1"
    clear
    echo -e "${BLUE}${BOLD}智能包搜索${NC}"
    echo ""

    echo -e "${CYAN}请输入搜索关键词:${NC}"
    if ! restore_terminal_state; then
        echo -e "${RED}终端状态恢复失败${NC}"
        sleep 2
        return
    fi
    read -r search_term
    if ! set_raw_terminal; then
        echo -e "${RED}终端模式设置失败${NC}"
        sleep 2
        return
    fi

    if [[ -z "$search_term" ]]; then
        echo -e "${YELLOW}搜索词不能为空${NC}"
        sleep 2
        return
    fi

    # 验证输入安全性（基本验证，防止命令注入）
    if [[ "$search_term" =~ [\;\&\|\`\$\(\)] ]]; then
        echo -e "${RED}输入包含非法字符${NC}"
        sleep 2
        return
    fi

    echo ""
    echo -e "${YELLOW}搜索 '$search_term'...${NC}"
    echo ""

    case "$pkg_manager" in
        "apt")
            echo -e "${GREEN}APT 搜索结果:${NC}"
            apt search "$search_term" 2>/dev/null | head -20
            echo ""
            echo -e "${GREEN}已安装的相关包:${NC}"
            dpkg -l | grep -i "$search_term" | head -10
            ;;
        "yum"|"dnf")
            echo -e "${GREEN}${pkg_manager^^} 搜索结果:${NC}"
            $pkg_manager search "$search_term" 2>/dev/null | head -20
            ;;
        "pacman")
            echo -e "${GREEN}Pacman 搜索结果:${NC}"
            pacman -Ss "$search_term" | head -20
            echo ""
            echo -e "${GREEN}已安装的相关包:${NC}"
            pacman -Q | grep -i "$search_term" | head -10
            ;;
        "zypper")
            echo -e "${GREEN}Zypper 搜索结果:${NC}"
            zypper search "$search_term" | head -20
            ;;
        "apk")
            echo -e "${GREEN}APK 搜索结果:${NC}"
            apk search "$search_term" | head -20
            ;;
    esac

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 包依赖分析
show_dependency_analysis() {
    local pkg_manager="$1"
    clear
    echo -e "${BLUE}${BOLD}包依赖分析${NC}"
    echo ""

    echo -e "${CYAN}请输入包名:${NC}"
    if ! restore_terminal_state; then
        echo -e "${RED}终端状态恢复失败${NC}"
        sleep 2
        return
    fi
    read -r package_name
    if ! set_raw_terminal; then
        echo -e "${RED}终端模式设置失败${NC}"
        sleep 2
        return
    fi

    if [[ -z "$package_name" ]]; then
        echo -e "${YELLOW}包名不能为空${NC}"
        sleep 2
        return
    fi

    # 验证包名格式
    if ! validate_package_name "$package_name"; then
        echo -e "${RED}包名格式无效${NC}"
        sleep 2
        return
    fi

    echo ""
    echo -e "${YELLOW}分析 '$package_name' 的依赖关系...${NC}"
    echo ""

    case "$pkg_manager" in
        "apt")
            echo -e "${GREEN}依赖信息:${NC}"
            apt depends "$package_name" 2>/dev/null | head -20
            echo ""
            echo -e "${GREEN}反向依赖:${NC}"
            apt rdepends "$package_name" 2>/dev/null | head -10
            ;;
        "yum"|"dnf")
            echo -e "${GREEN}依赖信息:${NC}"
            $pkg_manager deplist "$package_name" 2>/dev/null | head -20
            ;;
        "pacman")
            echo -e "${GREEN}依赖信息:${NC}"
            pacman -Si "$package_name" 2>/dev/null | grep -E "(Depends|Required)" | head -10
            ;;
        "zypper")
            echo -e "${GREEN}依赖信息:${NC}"
            zypper info --requires "$package_name" 2>/dev/null | head -20
            ;;
        "apk")
            echo -e "${GREEN}依赖信息:${NC}"
            apk info -R "$package_name" 2>/dev/null | head -20
            ;;
    esac

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 系统更新管理
show_update_management() {
    local pkg_manager="$1"
    clear
    echo -e "${BLUE}${BOLD}系统更新管理${NC}"
    echo ""

    local update_options=(
        "检查可用更新"
        "安全更新"
        "完整系统更新"
        "更新历史"
        "返回上级菜单"
    )

    local result
    result=$(simple_selector "选择更新操作" "${update_options[@]}")

    case "$result" in
        "CANCELLED"|"SELECTOR_ERROR")
            return
            ;;
        0) check_available_updates "$pkg_manager" ;;
        1) security_updates "$pkg_manager" ;;
        2) full_system_update "$pkg_manager" ;;
        3) update_history "$pkg_manager" ;;
        4) return ;;
    esac
}

# 检查可用更新
check_available_updates() {
    local pkg_manager="$1"
    clear
    echo -e "${BLUE}${BOLD}检查可用更新${NC}"
    echo ""

    echo -e "${YELLOW}检查更新中...${NC}"

    case "$pkg_manager" in
        "apt")
            apt update >/dev/null 2>&1
            echo -e "${GREEN}可更新的包:${NC}"
            apt list --upgradable 2>/dev/null | head -20
            ;;
        "yum"|"dnf")
            echo -e "${GREEN}可更新的包:${NC}"
            $pkg_manager check-update 2>/dev/null | head -20
            ;;
        "pacman")
            echo -e "${GREEN}可更新的包:${NC}"
            pacman -Qu | head -20
            ;;
        "zypper")
            echo -e "${GREEN}可更新的包:${NC}"
            zypper list-updates | head -20
            ;;
        "apk")
            echo -e "${GREEN}可更新的包:${NC}"
            apk version -l '<' | head -20
            ;;
    esac

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 包安全检查
show_security_check() {
    local pkg_manager="$1"
    clear
    echo -e "${BLUE}${BOLD}包安全检查${NC}"
    echo ""

    echo -e "${YELLOW}执行安全检查...${NC}"
    echo ""

    # GPG密钥检查
    echo -e "${GREEN}检查GPG密钥:${NC}"
    case "$pkg_manager" in
        "apt")
            apt-key list 2>/dev/null | grep -E "(pub|uid)" | head -10 || echo "无法检查GPG密钥"
            ;;
        "yum"|"dnf")
            rpm -q gpg-pubkey 2>/dev/null | head -10 || echo "无法检查GPG密钥"
            ;;
        "pacman")
            pacman-key --list-keys 2>/dev/null | grep -E "(pub|uid)" | head -10 || echo "无法检查GPG密钥"
            ;;
        *)
            echo "此包管理器不支持GPG密钥检查"
            ;;
    esac

    echo ""

    # 验证已安装包的完整性
    echo -e "${GREEN}验证包完整性:${NC}"
    case "$pkg_manager" in
        "apt")
            echo "检查关键系统包..."
            for pkg in bash coreutils libc6; do
                if dpkg -s "$pkg" >/dev/null 2>&1; then
                    echo "✓ $pkg - 已安装"
                else
                    echo "✗ $pkg - 未安装或有问题"
                fi
            done
            ;;
        "rpm")
            echo "验证关键RPM包..."
            rpm -V bash coreutils glibc 2>/dev/null | head -5 || echo "包验证完成"
            ;;
        *)
            echo "此包管理器暂不支持完整性检查"
            ;;
    esac

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 清理优化
show_cleanup_optimization() {
    local pkg_manager="$1"
    clear
    echo -e "${BLUE}${BOLD}清理优化${NC}"
    echo ""

    local cleanup_options=(
        "清理包缓存"
        "移除孤儿包"
        "清理配置文件"
        "磁盘空间分析"
        "返回上级菜单"
    )

    local result
    result=$(simple_selector "选择清理操作" "${cleanup_options[@]}")

    case "$result" in
        "CANCELLED"|"SELECTOR_ERROR")
            return
            ;;
        0) cleanup_cache "$pkg_manager" ;;
        1) remove_orphans "$pkg_manager" ;;
        2) cleanup_configs "$pkg_manager" ;;
        3) disk_analysis "$pkg_manager" ;;
        4) return ;;
    esac
}

# 清理包缓存
cleanup_cache() {
    local pkg_manager="$1"
    clear
    echo -e "${BLUE}${BOLD}清理包缓存${NC}"
    echo ""

    echo -e "${YELLOW}正在清理缓存...${NC}"

    case "$pkg_manager" in
        "apt")
            apt autoclean && apt autoremove -y
            echo -e "${GREEN}✅ APT缓存清理完成${NC}"
            ;;
        "yum"|"dnf")
            $pkg_manager clean all
            echo -e "${GREEN}✅ ${pkg_manager^^}缓存清理完成${NC}"
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

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 包历史记录
show_package_history() {
    local pkg_manager="$1"
    clear
    echo -e "${BLUE}${BOLD}包历史记录${NC}"
    echo ""

    echo -e "${GREEN}最近的包操作:${NC}"

    case "$pkg_manager" in
        "apt")
            if [[ -f /var/log/apt/history.log ]]; then
                tail -30 /var/log/apt/history.log | grep -E "(Install|Remove|Upgrade)"
            else
                echo "无法找到APT历史记录"
            fi
            ;;
        "yum"|"dnf")
            $pkg_manager history list 2>/dev/null | head -20 || echo "无法获取历史记录"
            ;;
        "pacman")
            if [[ -f /var/log/pacman.log ]]; then
                tail -30 /var/log/pacman.log | grep -E "\[(PACMAN|ALPM)\]"
            else
                echo "无法找到Pacman历史记录"
            fi
            ;;
        *)
            echo "此包管理器不支持历史记录查看"
            ;;
    esac

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 模块信息
get_module_info() {
    echo "包管理模块 v1.0 - 提供增强的包管理功能"
}

# 模块初始化
init_packages_module() {
    debug_log "packages module: 模块初始化完成"
    return 0
}