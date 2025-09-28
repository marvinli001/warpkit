#!/bin/bash

# WarpKit 网络工具模块
# 这个模块提供增强的网络工具功能

# 网络工具主界面
show_network_tools() {
    local network_options=(
        "网络诊断"
        "连接监控"
        "DNS工具箱"
        "防火墙管理"
        "网络性能测试"
        "SSL/TLS检查"
        "返回主菜单"
    )

    while true; do
        local result
        result=$(codex_selector "网络工具" "模块版本 - 增强功能" 0 "${network_options[@]}")

        case "$result" in
            "CANCELLED"|"SELECTOR_ERROR")
                return
                ;;
            0) show_network_diagnostics ;;
            1) show_connection_monitor ;;
            2) show_dns_toolbox ;;
            3) show_firewall_management ;;
            4) show_performance_test ;;
            5) show_ssl_check ;;
            6) return ;;
            *)
                debug_log "network module: 未知选择 $result"
                return
                ;;
        esac
    done
}

# 网络诊断
show_network_diagnostics() {
    clear
    echo -e "${BLUE}${BOLD}网络诊断${NC}"
    echo ""

    echo -e "${YELLOW}正在进行网络诊断...${NC}"
    echo ""

    # 基本连通性测试
    echo -e "${GREEN}1. 基本连通性测试:${NC}"
    local test_hosts=("8.8.8.8" "1.1.1.1" "google.com")
    for host in "${test_hosts[@]}"; do
        if ping -c 1 -W 3 "$host" >/dev/null 2>&1; then
            echo "  ✓ $host - 可达"
        else
            echo "  ✗ $host - 不可达"
        fi
    done
    echo ""

    # DNS解析测试
    echo -e "${GREEN}2. DNS解析测试:${NC}"
    local dns_test_domains=("google.com" "github.com" "cloudflare.com")
    for domain in "${dns_test_domains[@]}"; do
        if nslookup "$domain" >/dev/null 2>&1; then
            echo "  ✓ $domain - 解析成功"
        else
            echo "  ✗ $domain - 解析失败"
        fi
    done
    echo ""

    # 网络接口状态
    echo -e "${GREEN}3. 网络接口状态:${NC}"
    if command -v ip >/dev/null 2>&1; then
        ip link show | grep -E "(^[0-9]+:|state)" | while read line; do
            echo "  $line"
        done
    elif command -v ifconfig >/dev/null 2>&1; then
        ifconfig | grep -E "(^[a-z]|inet )" | head -10
    else
        echo "  无法获取网络接口信息"
    fi
    echo ""

    # 默认网关
    echo -e "${GREEN}4. 默认网关:${NC}"
    if command -v ip >/dev/null 2>&1; then
        ip route show default | head -3
    elif command -v route >/dev/null 2>&1; then
        route -n | grep "^0.0.0.0" | head -3
    else
        echo "  无法获取网关信息"
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 连接监控
show_connection_monitor() {
    clear
    echo -e "${BLUE}${BOLD}连接监控${NC}"
    echo ""

    local monitor_options=(
        "活动连接"
        "监听端口"
        "网络统计"
        "实时连接监控"
        "返回上级菜单"
    )

    local result
    result=$(simple_selector "选择监控类型" "${monitor_options[@]}")

    case "$result" in
        "CANCELLED"|"SELECTOR_ERROR")
            return
            ;;
        0) show_active_connections ;;
        1) show_listening_ports ;;
        2) show_network_statistics ;;
        3) show_realtime_monitor ;;
        4) return ;;
    esac
}

# 活动连接
show_active_connections() {
    clear
    echo -e "${BLUE}${BOLD}活动连接${NC}"
    echo ""

    if command -v ss >/dev/null 2>&1; then
        echo -e "${GREEN}TCP连接:${NC}"
        ss -t -a | head -20
        echo ""
        echo -e "${GREEN}UDP连接:${NC}"
        ss -u -a | head -10
    elif command -v netstat >/dev/null 2>&1; then
        echo -e "${GREEN}TCP连接:${NC}"
        netstat -t -a | head -20
        echo ""
        echo -e "${GREEN}UDP连接:${NC}"
        netstat -u -a | head -10
    else
        echo "无法获取连接信息"
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 监听端口
show_listening_ports() {
    clear
    echo -e "${BLUE}${BOLD}监听端口${NC}"
    echo ""

    if command -v ss >/dev/null 2>&1; then
        echo -e "${GREEN}监听中的端口:${NC}"
        ss -tuln | column -t
    elif command -v netstat >/dev/null 2>&1; then
        echo -e "${GREEN}监听中的端口:${NC}"
        netstat -tuln | column -t
    else
        echo "无法获取端口信息"
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# DNS工具箱
show_dns_toolbox() {
    local dns_options=(
        "DNS查询测试"
        "DNS配置管理"
        "DNS性能测试"
        "DNS记录查看"
        "返回上级菜单"
    )

    while true; do
        local result
        result=$(simple_selector "DNS工具箱" "${dns_options[@]}")

        case "$result" in
            "CANCELLED"|"SELECTOR_ERROR")
                return
                ;;
            0) dns_query_test ;;
            1) dns_config_management ;;
            2) dns_performance_test ;;
            3) dns_record_lookup ;;
            4) return ;;
        esac
    done
}

# DNS查询测试
dns_query_test() {
    clear
    echo -e "${BLUE}${BOLD}DNS查询测试${NC}"
    echo ""

    echo -e "${CYAN}请输入要查询的域名:${NC}"
    restore_terminal_state
    read -r domain
    set_raw_terminal

    if [[ -z "$domain" ]]; then
        echo -e "${YELLOW}域名不能为空${NC}"
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
    if [[ -f /etc/resolv.conf ]]; then
        cat /etc/resolv.conf
    else
        echo "无法读取DNS配置"
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

# SSL/TLS检查
show_ssl_check() {
    clear
    echo -e "${BLUE}${BOLD}SSL/TLS检查${NC}"
    echo ""

    echo -e "${CYAN}请输入要检查的域名 (如: google.com):${NC}"
    restore_terminal_state
    read -r domain
    set_raw_terminal

    if [[ -z "$domain" ]]; then
        echo -e "${YELLOW}域名不能为空${NC}"
        sleep 2
        return
    fi

    echo ""
    echo -e "${YELLOW}检查 $domain 的SSL证书...${NC}"
    echo ""

    if command -v openssl >/dev/null 2>&1; then
        echo -e "${GREEN}SSL证书信息:${NC}"
        echo | openssl s_client -servername "$domain" -connect "$domain":443 2>/dev/null | openssl x509 -noout -text 2>/dev/null | grep -E "(Subject:|Issuer:|Not Before|Not After)" || echo "SSL证书检查失败"
    else
        echo "openssl命令不可用"
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 实时连接监控
show_realtime_monitor() {
    clear
    echo -e "${BLUE}${BOLD}实时连接监控${NC}"
    echo ""
    echo -e "${YELLOW}监控5秒，按Ctrl+C停止...${NC}"
    echo ""

    for i in {1..5}; do
        echo -e "${GREEN}时刻 $i:${NC}"
        if command -v ss >/dev/null 2>&1; then
            ss -t | wc -l | xargs echo "  TCP连接数:"
        elif command -v netstat >/dev/null 2>&1; then
            netstat -t | wc -l | xargs echo "  TCP连接数:"
        else
            echo "  无法获取连接数"
        fi
        sleep 1
    done

    echo ""
    echo -e "${YELLOW}监控完成，按任意键返回${NC}"
    read -n1
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