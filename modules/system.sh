#!/bin/bash

# WarpKit 系统监控模块
# 这个模块提供增强的系统监控功能

# 系统监控主界面
show_system_monitor() {
    local monitor_options=(
        "实时系统状态"
        "进程管理"
        "内存分析"
        "磁盘使用情况"
        "网络连接状态"
        "系统负载历史"
        "返回主菜单"
    )

    while true; do
        local result
        result=$(codex_selector "系统监控" "模块版本 - 增强功能" 0 "${monitor_options[@]}")

        case "$result" in
            "CANCELLED"|"SELECTOR_ERROR")
                return
                ;;
            0) show_realtime_status ;;
            1) show_process_manager ;;
            2) show_memory_analysis ;;
            3) show_disk_usage ;;
            4) show_network_status ;;
            5) show_load_history ;;
            6) return ;;
            *)
                debug_log "system module: 未知选择 $result"
                return
                ;;
        esac
    done
}

# 实时系统状态
show_realtime_status() {
    clear
    echo -e "${BLUE}${BOLD}实时系统状态${NC}"
    echo ""

    echo -e "${CYAN}正在收集系统信息...${NC}"

    # CPU信息
    if command -v lscpu >/dev/null 2>&1; then
        echo -e "${GREEN}CPU信息:${NC}"
        lscpu | grep -E "(Architecture|CPU\(s\)|Model name|CPU MHz)" | head -4
        echo ""
    fi

    # 内存信息
    if command -v free >/dev/null 2>&1; then
        echo -e "${GREEN}内存使用:${NC}"
        free -h
        echo ""
    fi

    # 系统负载
    if command -v uptime >/dev/null 2>&1; then
        echo -e "${GREEN}系统负载:${NC}"
        uptime
        echo ""
    fi

    # 磁盘使用
    if command -v df >/dev/null 2>&1; then
        echo -e "${GREEN}磁盘使用:${NC}"
        df -h | head -6
        echo ""
    fi

    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 进程管理
show_process_manager() {
    clear
    echo -e "${BLUE}${BOLD}进程管理${NC}"
    echo ""

    if command -v ps >/dev/null 2>&1; then
        echo -e "${GREEN}CPU使用率最高的进程:${NC}"
        ps aux --sort=-%cpu | head -11
        echo ""

        echo -e "${GREEN}内存使用率最高的进程:${NC}"
        ps aux --sort=-%mem | head -11
        echo ""
    else
        echo -e "${YELLOW}ps命令不可用${NC}"
    fi

    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 内存分析
show_memory_analysis() {
    clear
    echo -e "${BLUE}${BOLD}内存分析${NC}"
    echo ""

    if command -v free >/dev/null 2>&1; then
        echo -e "${GREEN}详细内存信息:${NC}"
        free -m
        echo ""
    fi

    # 如果有 /proc/meminfo，显示更详细信息
    if [[ -f /proc/meminfo ]]; then
        echo -e "${GREEN}内存详细统计:${NC}"
        echo "总内存:     $(grep MemTotal /proc/meminfo | awk '{print $2/1024 "MB"}')"
        echo "可用内存:   $(grep MemAvailable /proc/meminfo | awk '{print $2/1024 "MB"}' 2>/dev/null || echo "N/A")"
        echo "缓存:       $(grep "^Cached:" /proc/meminfo | awk '{print $2/1024 "MB"}')"
        echo "缓冲区:     $(grep Buffers /proc/meminfo | awk '{print $2/1024 "MB"}')"
        echo "交换空间:   $(grep SwapTotal /proc/meminfo | awk '{print $2/1024 "MB"}')"
        echo ""
    fi

    # 显示最大内存使用进程
    if command -v ps >/dev/null 2>&1; then
        echo -e "${GREEN}内存使用TOP 5:${NC}"
        ps aux --sort=-%mem | head -6 | awk '{print $11 "\t" $4 "%\t" $6/1024 "MB"}' | column -t
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 磁盘使用情况
show_disk_usage() {
    clear
    echo -e "${BLUE}${BOLD}磁盘使用情况${NC}"
    echo ""

    if command -v df >/dev/null 2>&1; then
        echo -e "${GREEN}文件系统使用情况:${NC}"
        df -h
        echo ""
    fi

    # 显示目录大小（安全检查）
    if command -v du >/dev/null 2>&1; then
        echo -e "${GREEN}大目录占用（/var, /usr, /home前5个）:${NC}"
        for dir in /var /usr /home; do
            if [[ -d "$dir" ]]; then
                echo -n "$dir: "
                du -sh "$dir" 2>/dev/null | cut -f1 || echo "无法访问"
            fi
        done
        echo ""

        # 当前目录下的大文件夹
        echo -e "${GREEN}当前目录大小分布:${NC}"
        du -sh ./* 2>/dev/null | sort -hr | head -5 || echo "无法访问当前目录"
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 网络连接状态
show_network_status() {
    clear
    echo -e "${BLUE}${BOLD}网络连接状态${NC}"
    echo ""

    # 网络接口
    if command -v ip >/dev/null 2>&1; then
        echo -e "${GREEN}网络接口:${NC}"
        ip addr show | grep -E "(inet |^[0-9]+:)" | head -10
        echo ""
    elif command -v ifconfig >/dev/null 2>&1; then
        echo -e "${GREEN}网络接口:${NC}"
        ifconfig | grep -E "(inet |^[a-z])" | head -10
        echo ""
    fi

    # 活动连接
    if command -v ss >/dev/null 2>&1; then
        echo -e "${GREEN}活动TCP连接:${NC}"
        ss -tuln | head -10
        echo ""
    elif command -v netstat >/dev/null 2>&1; then
        echo -e "${GREEN}活动TCP连接:${NC}"
        netstat -tuln | head -10
        echo ""
    fi

    # 路由表
    if command -v ip >/dev/null 2>&1; then
        echo -e "${GREEN}路由表:${NC}"
        ip route show | head -5
    elif command -v route >/dev/null 2>&1; then
        echo -e "${GREEN}路由表:${NC}"
        route -n | head -5
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 系统负载历史
show_load_history() {
    clear
    echo -e "${BLUE}${BOLD}系统负载历史${NC}"
    echo ""

    # 当前负载
    if command -v uptime >/dev/null 2>&1; then
        echo -e "${GREEN}当前系统负载:${NC}"
        uptime
        echo ""
    fi

    # 如果有 w 命令
    if command -v w >/dev/null 2>&1; then
        echo -e "${GREEN}当前登录用户:${NC}"
        w
        echo ""
    fi

    # CPU统计（如果有iostat）
    if command -v iostat >/dev/null 2>&1; then
        echo -e "${GREEN}CPU统计:${NC}"
        iostat -c 1 1 2>/dev/null || echo "iostat不可用"
        echo ""
    fi

    # 简单的负载监控
    echo -e "${GREEN}负载测试（5秒监控）:${NC}"
    for i in {1..5}; do
        if [[ -f /proc/loadavg ]]; then
            echo "时刻 $i: $(cat /proc/loadavg)"
        else
            uptime | awk '{print "时刻 '$i': " $8 $9 $10}' 2>/dev/null || echo "时刻 $i: 负载信息不可用"
        fi
        sleep 1
    done

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 模块信息
get_module_info() {
    echo "系统监控模块 v1.0 - 提供增强的系统监控功能"
}

# 模块初始化（如果需要）
init_system_module() {
    debug_log "system module: 模块初始化完成"
    return 0
}

# 导出主要函数供外部调用
# show_system_monitor 函数已定义，可以被模块加载器调用