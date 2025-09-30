#!/bin/bash

# WarpKit 网络工具模块
# 这个模块提供增强的网络工具功能

# 网络工具主界面
show_network_tools() {
    local network_options=(
        "DNS修复"
        "防火墙管理"
        "网络性能测试"
        "启用BBR内核网络加速"
        "流媒体解锁检测"
        "回程路由检测"
        "返回主菜单"
    )

    while true; do
        local result
        result=$(codex_selector "网络工具" "模块版本 - 增强功能" 0 "${network_options[@]}")

        case "$result" in
            "CANCELLED")
                return
                ;;
            "SELECTOR_ERROR")
                # 切换到文本菜单模式
                show_network_tools_text_menu
                return
                ;;
            0) show_dns_toolbox ;;
            1) show_firewall_management ;;
            2) show_performance_test ;;
            3) enable_bbr_acceleration ;;
            4) show_streaming_unlock_check ;;
            5) show_backtrace_check ;;
            6) return ;;
            *)
                debug_log "network module: 未知选择 $result"
                return
                ;;
        esac
    done
}

# 网络工具文本菜单
show_network_tools_text_menu() {
    while true; do
        clear
        print_logo
        show_system_info

        echo -e "${CYAN}${BOLD}网络工具${NC}"
        echo ""
        echo "1. DNS修复"
        echo "2. 防火墙管理"
        echo "3. 网络性能测试"
        echo "4. 启用BBR内核网络加速"
        echo "5. 流媒体解锁检测"
        echo "6. 回程路由检测"
        echo "0. 返回主菜单"
        echo ""
        echo -n "请选择功能 (0-6): "

        read -r choice
        echo ""

        case "$choice" in
            1) show_dns_toolbox ;;
            2) show_firewall_management ;;
            3) show_performance_test ;;
            4) enable_bbr_acceleration ;;
            5) show_streaming_unlock_check ;;
            6) show_backtrace_check ;;
            0) return ;;
            *)
                echo -e "${RED}无效选择，请输入 0-6${NC}"
                sleep 2
                ;;
        esac
    done
}

# DNS修复工具箱
show_dns_toolbox() {
    local dns_options=(
        "DNS查询测试"
        "DNS配置管理"
        "返回上级菜单"
    )

    while true; do
        local result
        result=$(simple_selector "DNS修复" "${dns_options[@]}")

        case "$result" in
            "CANCELLED"|"SELECTOR_ERROR")
                return
                ;;
            0) dns_query_test ;;
            1) dns_config_management ;;
            2) return ;;
        esac
    done
}

# DNS查询测试
dns_query_test() {
    clear
    echo -e "${BLUE}${BOLD}DNS查询测试${NC}"
    echo ""

    echo -e "${CYAN}请输入要查询的域名:${NC}"
    if ! restore_terminal_state; then
        echo -e "${RED}终端状态恢复失败${NC}"
        sleep 2
        return
    fi
    read -r domain
    if ! set_raw_terminal; then
        echo -e "${RED}终端模式设置失败${NC}"
        sleep 2
        return
    fi

    if [[ -z "$domain" ]]; then
        echo -e "${YELLOW}域名不能为空${NC}"
        sleep 2
        return
    fi

    # 验证域名格式
    if ! validate_domain "$domain"; then
        echo -e "${RED}域名格式无效${NC}"
        sleep 2
        return
    fi

    echo ""
    echo -e "${YELLOW}查询 $domain...${NC}"
    echo ""

    # A记录
    if command -v nslookup >/dev/null 2>&1; then
        echo -e "${GREEN}A记录:${NC}"
        nslookup "$domain" 2>/dev/null | grep -A5 "Name:" || echo "无A记录或查询失败"
        echo ""

        echo -e "${GREEN}MX记录:${NC}"
        nslookup -type=MX "$domain" 2>/dev/null | grep "mail exchanger" || echo "无MX记录"
        echo ""

        echo -e "${GREEN}TXT记录:${NC}"
        nslookup -type=TXT "$domain" 2>/dev/null | grep "text" || echo "无TXT记录"
    elif command -v dig >/dev/null 2>&1; then
        echo -e "${GREEN}DNS记录:${NC}"
        dig "$domain" +short
        echo ""
        echo -e "${GREEN}MX记录:${NC}"
        dig MX "$domain" +short
    else
        echo "nslookup和dig命令都不可用"
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# DNS配置管理
dns_config_management() {
    clear
    echo -e "${BLUE}${BOLD}DNS配置管理${NC}"
    echo ""

    echo -e "${GREEN}当前DNS配置:${NC}"
    if [[ -f /etc/resolv.conf && -r /etc/resolv.conf ]]; then
        cat /etc/resolv.conf
    else
        echo "无法读取DNS配置（文件不存在或无权限）"
    fi

    echo ""
    echo -e "${GREEN}常用DNS服务器:${NC}"
    echo "Google DNS: 8.8.8.8, 8.8.4.4"
    echo "Cloudflare: 1.1.1.1, 1.0.0.1"
    echo "Quad9: 9.9.9.9, 149.112.112.112"
    echo "OpenDNS: 208.67.222.222, 208.67.220.220"

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 防火墙管理
show_firewall_management() {
    clear
    echo -e "${BLUE}${BOLD}防火墙管理${NC}"
    echo ""

    # 检测防火墙类型
    local firewall_type="unknown"
    if command -v ufw >/dev/null 2>&1; then
        firewall_type="ufw"
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall_type="firewalld"
    elif command -v iptables >/dev/null 2>&1; then
        firewall_type="iptables"
    fi

    echo -e "${CYAN}检测到防火墙: $firewall_type${NC}"
    echo ""

    case "$firewall_type" in
        "ufw")
            echo -e "${GREEN}UFW状态:${NC}"
            ufw status verbose 2>/dev/null || echo "需要sudo权限查看UFW状态"
            ;;
        "firewalld")
            echo -e "${GREEN}Firewalld状态:${NC}"
            firewall-cmd --state 2>/dev/null || echo "需要sudo权限查看firewalld状态"
            echo ""
            firewall-cmd --list-all 2>/dev/null || echo "需要sudo权限查看防火墙规则"
            ;;
        "iptables")
            echo -e "${GREEN}iptables规则:${NC}"
            iptables -L -n 2>/dev/null | head -20 || echo "需要sudo权限查看iptables规则"
            ;;
        *)
            echo "未检测到支持的防火墙"
            ;;
    esac

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 网络性能测试
show_performance_test() {
    clear
    echo -e "${BLUE}${BOLD}网络性能测试${NC}"
    echo ""

    echo -e "${YELLOW}正在进行性能测试...${NC}"
    echo ""

    # 延迟测试
    echo -e "${GREEN}延迟测试:${NC}"
    local test_servers=("8.8.8.8" "1.1.1.1")
    for server in "${test_servers[@]}"; do
        echo -n "  $server: "
        if command -v ping >/dev/null 2>&1; then
            ping -c 3 "$server" 2>/dev/null | tail -1 | awk -F'/' '{print $5 "ms avg"}' || echo "测试失败"
        else
            echo "ping命令不可用"
        fi
    done
    echo ""

    # 带宽测试（简单版）
    echo -e "${GREEN}简单带宽测试:${NC}"
    echo "  正在测试下载速度..."
    if command -v wget >/dev/null 2>&1; then
        local test_file="http://speedtest.tele2.net/1MB.zip"
        local start_time=$(date +%s)
        if wget -q -O /dev/null "$test_file" 2>/dev/null; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            if [[ $duration -gt 0 ]]; then
                local speed=$((1024 / duration))
                echo "  大约 ${speed}KB/s"
            else
                echo "  测试时间太短，无法计算"
            fi
        else
            echo "  带宽测试失败"
        fi
    elif command -v curl >/dev/null 2>&1; then
        curl -s -w "  下载速度: %{speed_download} bytes/s\n" -o /dev/null "http://httpbin.org/bytes/1024" 2>/dev/null || echo "  带宽测试失败"
    else
        echo "  wget和curl都不可用，无法进行带宽测试"
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 启用BBR内核网络加速
enable_bbr_acceleration() {
    clear
    echo -e "${BLUE}${BOLD}启用BBR内核网络加速${NC}"
    echo ""

    # 检测系统发行版和版本
    detect_distro
    local distro="$DISTRO"
    local version="$VERSION"

    echo -e "${CYAN}检测到系统: $distro $version${NC}"
    echo ""

    # 检查当前内核版本
    local kernel_version=$(uname -r)
    echo -e "${CYAN}当前内核版本: $kernel_version${NC}"
    echo ""

    # BBR需要内核4.9+
    local kernel_major=$(echo "$kernel_version" | cut -d. -f1)
    local kernel_minor=$(echo "$kernel_version" | cut -d. -f2)

    if [[ $kernel_major -lt 4 ]] || [[ $kernel_major -eq 4 && $kernel_minor -lt 9 ]]; then
        echo -e "${RED}错误: BBR需要Linux内核4.9或更高版本${NC}"
        echo -e "${YELLOW}当前内核版本 $kernel_version 不支持BBR${NC}"
        echo ""
        echo -e "${YELLOW}按任意键返回${NC}"
        read -n1
        return
    fi

    # 检查BBR是否已启用
    local current_congestion=$(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')
    if [[ "$current_congestion" == "bbr" ]]; then
        echo -e "${GREEN}✓ BBR已经启用${NC}"
        echo ""
        echo -e "${YELLOW}按任意键返回${NC}"
        read -n1
        return
    fi

    echo -e "${YELLOW}当前拥塞控制算法: $current_congestion${NC}"
    echo ""
    echo -e "${CYAN}是否启用BBR加速? (y/n):${NC}"
    if ! restore_terminal_state; then
        echo -e "${RED}终端状态恢复失败${NC}"
        sleep 2
        return
    fi
    read -r confirm
    if ! set_raw_terminal; then
        echo -e "${RED}终端模式设置失败${NC}"
        sleep 2
        return
    fi

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        return
    fi

    echo ""
    echo -e "${YELLOW}正在配置BBR...${NC}"
    echo ""

    # 判断配置方法：Debian 11+, Ubuntu 20.04+, CentOS 8+可以快速启用
    local quick_enable=false
    case "$distro" in
        ubuntu)
            if [[ $(echo "$version" | cut -d. -f1) -ge 20 ]]; then
                quick_enable=true
            fi
            ;;
        debian)
            if [[ $(echo "$version" | cut -d. -f1) -ge 11 ]]; then
                quick_enable=true
            fi
            ;;
        centos|rhel|rocky|almalinux)
            if [[ $(echo "$version" | cut -d. -f1) -ge 8 ]]; then
                quick_enable=true
            fi
            ;;
        fedora)
            quick_enable=true
            ;;
        arch|manjaro)
            quick_enable=true
            ;;
        opensuse*|sles)
            quick_enable=true
            ;;
        alpine)
            quick_enable=true
            ;;
    esac

    if [[ "$quick_enable" == "true" ]]; then
        # 快速启用BBR（支持临时+永久）
        echo -e "${GREEN}使用快速配置方式...${NC}"

        # 临时启用
        if sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1 && \
           sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1; then
            echo -e "${GREEN}✓ BBR已临时启用${NC}"
        else
            echo -e "${RED}✗ BBR临时启用失败（需要root权限）${NC}"
            sleep 2
            return
        fi

        # 永久配置
        if [[ -w /etc/sysctl.conf ]]; then
            # 检查是否已有配置
            if ! grep -q "net.core.default_qdisc" /etc/sysctl.conf; then
                echo "net.core.default_qdisc=fq" >> /etc/sysctl.conf
            else
                sed -i 's/^net.core.default_qdisc.*/net.core.default_qdisc=fq/' /etc/sysctl.conf
            fi

            if ! grep -q "net.ipv4.tcp_congestion_control" /etc/sysctl.conf; then
                echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
            else
                sed -i 's/^net.ipv4.tcp_congestion_control.*/net.ipv4.tcp_congestion_control=bbr/' /etc/sysctl.conf
            fi

            echo -e "${GREEN}✓ BBR配置已写入 /etc/sysctl.conf${NC}"
        else
            echo -e "${YELLOW}⚠️ 无法写入 /etc/sysctl.conf（需要root权限）${NC}"
            echo -e "${YELLOW}   BBR仅临时启用，重启后失效${NC}"
        fi
    else
        # 旧版系统需要修改配置文件
        echo -e "${YELLOW}使用配置文件方式...${NC}"

        local config_file="/etc/sysctl.d/99-bbr.conf"

        if [[ -w /etc/sysctl.d/ ]]; then
            cat > "$config_file" <<EOF
# BBR网络加速配置
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
            echo -e "${GREEN}✓ 配置已写入 $config_file${NC}"

            # 应用配置
            if sysctl -p "$config_file" >/dev/null 2>&1; then
                echo -e "${GREEN}✓ 配置已应用${NC}"
            else
                echo -e "${YELLOW}⚠️ 配置应用失败，可能需要重启系统${NC}"
            fi
        else
            echo -e "${RED}✗ 无法写入配置文件（需要root权限）${NC}"
            sleep 2
            return
        fi
    fi

    echo ""
    echo -e "${GREEN}BBR配置完成！${NC}"
    echo ""

    # 验证配置
    echo -e "${CYAN}当前配置状态:${NC}"
    echo "  拥塞控制: $(sysctl net.ipv4.tcp_congestion_control 2>/dev/null | awk '{print $3}')"
    echo "  队列调度: $(sysctl net.core.default_qdisc 2>/dev/null | awk '{print $3}')"

    # 检查BBR模块
    if lsmod | grep -q tcp_bbr; then
        echo -e "${GREEN}  ✓ BBR模块已加载${NC}"
    else
        echo -e "${YELLOW}  ⚠️ BBR模块未加载（可能需要重启）${NC}"
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 流媒体解锁检测
show_streaming_unlock_check() {
    clear
    echo -e "${BLUE}${BOLD}流媒体解锁检测${NC}"
    echo ""
    echo -e "${CYAN}此功能将检测当前服务器IP对各流媒体平台的访问解锁情况${NC}"
    echo -e "${CYAN}包括: Netflix、Disney+、YouTube、Hulu等主流平台${NC}"
    echo ""
    echo -e "${YELLOW}注意: 检测过程可能需要几分钟时间${NC}"
    echo ""
    echo -n "是否开始检测? [Y/n] "
    read -r start_check

    if [[ "$start_check" =~ ^[Nn]$ ]]; then
        return
    fi

    clear
    echo -e "${BLUE}${BOLD}流媒体解锁检测${NC}"
    echo ""
    echo -e "${CYAN}正在下载检测脚本...${NC}"
    echo ""

    # 检查依赖
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}错误: 未找到 curl 命令${NC}"
        echo -e "${YELLOW}请先安装 curl:${NC}"
        echo "  Ubuntu/Debian: sudo apt install curl"
        echo "  CentOS/RHEL:   sudo yum install curl"
        echo ""
        echo -e "${YELLOW}按任意键返回${NC}"
        read -n1
        return
    fi

    # 创建临时目录
    local temp_dir=$(mktemp -d)
    local script_path="${temp_dir}/region_check.sh"

    # 下载检测脚本
    if ! curl -fsSL "https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh" -o "$script_path" 2>/dev/null; then
        echo -e "${RED}下载检测脚本失败${NC}"
        echo -e "${YELLOW}请检查网络连接或稍后重试${NC}"
        rm -rf "$temp_dir"
        echo ""
        echo -e "${YELLOW}按任意键返回${NC}"
        read -n1
        return
    fi

    # 设置执行权限
    chmod +x "$script_path"

    echo -e "${GREEN}下载完成，开始检测...${NC}"
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # 执行检测脚本
    bash "$script_path"

    local exit_code=$?

    # 清理临时文件
    rm -rf "$temp_dir"

    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}检测完成！${NC}"
    else
        echo -e "${YELLOW}检测完成（部分项可能失败）${NC}"
    fi

    echo ""
    echo -e "${YELLOW}按 Enter 键返回网络工具菜单...${NC}"
    read -r

    # 返回时清屏重新显示菜单
    return
}

# 回程路由检测
show_backtrace_check() {
    clear
    echo -e "${BLUE}${BOLD}回程路由检测${NC}"
    echo ""
    echo -e "${CYAN}此功能将检测服务器到国内三大运营商的回程路由线路${NC}"
    echo -e "${CYAN}包括: 电信、联通、移动的回程路由路径和线路类型${NC}"
    echo ""
    echo -e "${YELLOW}注意: 检测过程可能需要几分钟时间${NC}"
    echo ""
    echo -n "是否开始检测? [Y/n] "
    read -r start_check

    if [[ "$start_check" =~ ^[Nn]$ ]]; then
        return
    fi

    clear
    echo -e "${BLUE}${BOLD}回程路由检测${NC}"
    echo ""

    # 检查是否已安装backtrace工具
    if command -v backtrace >/dev/null 2>&1; then
        echo -e "${GREEN}检测到已安装 backtrace 工具${NC}"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        # 直接运行backtrace
        backtrace

        local exit_code=$?

        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        if [[ $exit_code -eq 0 ]]; then
            echo -e "${GREEN}检测完成！${NC}"
        else
            echo -e "${YELLOW}检测完成（部分项可能失败）${NC}"
        fi
    else
        echo -e "${CYAN}正在下载并安装 backtrace 工具...${NC}"
        echo ""

        # 检查依赖
        if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
            echo -e "${RED}错误: 未找到 curl 或 wget 命令${NC}"
            echo -e "${YELLOW}请先安装其中之一:${NC}"
            echo "  Ubuntu/Debian: sudo apt install curl"
            echo "  CentOS/RHEL:   sudo yum install curl"
            echo ""
            echo -e "${YELLOW}按任意键返回${NC}"
            read -n1
            return
        fi

        # 下载并安装backtrace
        echo -e "${CYAN}正在执行安装脚本...${NC}"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        if curl -fsSL "https://raw.githubusercontent.com/oneclickvirt/backtrace/main/backtrace_install.sh" 2>/dev/null | bash; then
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            echo -e "${GREEN}安装完成，开始检测...${NC}"
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""

            # 运行backtrace检测
            if command -v backtrace >/dev/null 2>&1; then
                backtrace
                local exit_code=$?

                echo ""
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo ""

                if [[ $exit_code -eq 0 ]]; then
                    echo -e "${GREEN}检测完成！${NC}"
                else
                    echo -e "${YELLOW}检测完成（部分项可能失败）${NC}"
                fi
            else
                echo ""
                echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
                echo ""
                echo -e "${RED}安装失败，无法运行 backtrace 命令${NC}"
            fi
        else
            echo ""
            echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            echo -e "${RED}下载或安装脚本失败${NC}"
            echo -e "${YELLOW}请检查网络连接或稍后重试${NC}"
        fi
    fi

    echo ""
    echo -e "${CYAN}提示: backtrace 工具已安装到系统，下次检测将直接运行${NC}"
    echo ""
    echo -e "${YELLOW}按 Enter 键返回网络工具菜单...${NC}"
    read -r

    # 返回时清屏重新显示菜单
    return
}

# 模块信息
get_module_info() {
    echo "网络工具模块 v1.0 - 提供增强的网络工具功能"
}

# 模块初始化
init_network_module() {
    debug_log "network module: 模块初始化完成"
    return 0
}