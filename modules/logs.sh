#!/bin/bash

# WarpKit 日志查看模块
# 这个模块提供增强的日志查看功能

# 日志查看主界面
show_log_viewer() {
    local log_options=(
        "系统日志分析"
        "应用日志查看"
        "日志搜索"
        "实时日志监控"
        "日志统计"
        "日志清理"
        "返回主菜单"
    )

    while true; do
        local result
        result=$(codex_selector "日志查看" "模块版本 - 增强功能" 0 "${log_options[@]}")

        case "$result" in
            "CANCELLED")
                return
                ;;
            "SELECTOR_ERROR")
                # 切换到文本菜单模式
                show_log_viewer_text_menu
                return
                ;;
            0) show_system_log_analysis ;;
            1) show_application_logs ;;
            2) show_log_search ;;
            3) show_realtime_monitor ;;
            4) show_log_statistics ;;
            5) show_log_cleanup ;;
            6) return ;;
            *)
                debug_log "logs module: 未知选择 $result"
                return
                ;;
        esac
    done
}

# 日志查看文本菜单
show_log_viewer_text_menu() {
    while true; do
        clear
        print_logo
        show_system_info

        echo -e "${CYAN}${BOLD}日志查看${NC}"
        echo ""
        echo "1. 系统日志分析"
        echo "2. 应用日志查看"
        echo "3. 日志搜索"
        echo "4. 实时日志监控"
        echo "5. 日志统计"
        echo "6. 日志清理"
        echo "0. 返回主菜单"
        echo ""
        echo -n "请选择功能 (0-6): "

        read -r choice
        echo ""

        case "$choice" in
            1) show_system_log_analysis ;;
            2) show_application_logs ;;
            3) show_log_search ;;
            4) show_realtime_monitor ;;
            5) show_log_statistics ;;
            6) show_log_cleanup ;;
            0) return ;;
            *)
                echo -e "${RED}无效选择，请输入 0-6${NC}"
                sleep 2
                ;;
        esac
    done
}

# 系统日志分析
show_system_log_analysis() {
    clear
    echo -e "${BLUE}${BOLD}系统日志分析${NC}"
    echo ""

    # 检测可用的日志系统
    local log_system="unknown"
    if command -v journalctl >/dev/null 2>&1; then
        log_system="systemd"
    elif [[ -f /var/log/messages ]]; then
        log_system="syslog-messages"
    elif [[ -f /var/log/syslog ]]; then
        log_system="syslog"
    fi

    echo -e "${CYAN}检测到日志系统: $log_system${NC}"
    echo ""

    case "$log_system" in
        "systemd")
            echo -e "${GREEN}最近的系统日志:${NC}"
            journalctl -n 20 --no-pager 2>/dev/null || echo "需要权限查看系统日志"
            echo ""

            echo -e "${GREEN}错误日志:${NC}"
            journalctl -p err -n 10 --no-pager 2>/dev/null || echo "需要权限查看错误日志"
            echo ""

            echo -e "${GREEN}启动日志:${NC}"
            journalctl -b -n 10 --no-pager 2>/dev/null || echo "需要权限查看启动日志"
            ;;
        "syslog-messages")
            echo -e "${GREEN}最近的系统日志:${NC}"
            tail -20 /var/log/messages 2>/dev/null || echo "无法读取 /var/log/messages"
            echo ""

            echo -e "${GREEN}错误日志:${NC}"
            grep -i error /var/log/messages | tail -10 2>/dev/null || echo "无法搜索错误日志"
            ;;
        "syslog")
            echo -e "${GREEN}最近的系统日志:${NC}"
            tail -20 /var/log/syslog 2>/dev/null || echo "无法读取 /var/log/syslog"
            echo ""

            echo -e "${GREEN}错误日志:${NC}"
            grep -i error /var/log/syslog | tail -10 2>/dev/null || echo "无法搜索错误日志"
            ;;
        *)
            echo "未检测到支持的日志系统"
            echo "尝试查看常见日志文件..."
            for log_file in /var/log/messages /var/log/syslog /var/log/system.log; do
                if [[ -f "$log_file" ]]; then
                    echo -e "${GREEN}$log_file (最后10行):${NC}"
                    tail -10 "$log_file" 2>/dev/null || echo "无法读取"
                    echo ""
                fi
            done
            ;;
    esac

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 应用日志查看
show_application_logs() {
    clear
    echo -e "${BLUE}${BOLD}应用日志查看${NC}"
    echo ""

    local app_log_options=(
        "Web服务器日志"
        "数据库日志"
        "SSH日志"
        "认证日志"
        "自定义日志"
        "返回上级菜单"
    )

    local result
    result=$(simple_selector "选择日志类型" "${app_log_options[@]}")

    case "$result" in
        "CANCELLED"|"SELECTOR_ERROR")
            return
            ;;
        0) show_web_logs ;;
        1) show_database_logs ;;
        2) show_ssh_logs ;;
        3) show_auth_logs ;;
        4) show_custom_logs ;;
        5) return ;;
    esac
}

# Web服务器日志
show_web_logs() {
    clear
    echo -e "${BLUE}${BOLD}Web服务器日志${NC}"
    echo ""

    # 检查常见的web服务器日志
    local web_logs=(
        "/var/log/nginx/access.log"
        "/var/log/nginx/error.log"
        "/var/log/apache2/access.log"
        "/var/log/apache2/error.log"
        "/var/log/httpd/access_log"
        "/var/log/httpd/error_log"
    )

    local found_logs=()
    for log_file in "${web_logs[@]}"; do
        if [[ -f "$log_file" ]]; then
            found_logs+=("$log_file")
        fi
    done

    if [[ ${#found_logs[@]} -eq 0 ]]; then
        echo -e "${YELLOW}未找到常见的Web服务器日志文件${NC}"
    else
        echo -e "${GREEN}找到的Web服务器日志:${NC}"
        for log_file in "${found_logs[@]}"; do
            echo ""
            echo -e "${CYAN}$log_file (最后10行):${NC}"
            tail -10 "$log_file" 2>/dev/null || echo "无法读取"
        done
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# SSH日志
show_ssh_logs() {
    clear
    echo -e "${BLUE}${BOLD}SSH日志${NC}"
    echo ""

    # SSH日志通常在系统日志中
    if command -v journalctl >/dev/null 2>&1; then
        echo -e "${GREEN}SSH连接日志:${NC}"
        journalctl -u ssh -n 20 --no-pager 2>/dev/null || \
        journalctl -u sshd -n 20 --no-pager 2>/dev/null || \
        echo "无法获取SSH日志"
    elif [[ -f /var/log/auth.log ]]; then
        echo -e "${GREEN}SSH连接日志:${NC}"
        grep -i ssh /var/log/auth.log | tail -20 2>/dev/null || echo "无法读取SSH日志"
    elif [[ -f /var/log/secure ]]; then
        echo -e "${GREEN}SSH连接日志:${NC}"
        grep -i ssh /var/log/secure | tail -20 2>/dev/null || echo "无法读取SSH日志"
    else
        echo "未找到SSH日志"
    fi

    echo ""
    echo -e "${GREEN}最近的登录尝试:${NC}"
    if command -v lastb >/dev/null 2>&1; then
        lastb | head -10 2>/dev/null || echo "无法获取失败登录记录"
    else
        echo "lastb命令不可用"
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 日志搜索
show_log_search() {
    clear
    echo -e "${BLUE}${BOLD}日志搜索${NC}"
    echo ""

    echo -e "${CYAN}请输入搜索关键词 (ESC 取消):${NC}"

    # 读取输入，支持 ESC 取消
    local search_term=""
    local char
    while IFS= read -r -s -n1 char; do
        # ESC 键 (ASCII 27)
        if [[ $char == $'\x1b' ]]; then
            echo ""
            return
        fi
        # Enter 键
        if [[ -z $char ]]; then
            break
        fi
        # Backspace
        if [[ $char == $'\x7f' ]]; then
            if [[ -n $search_term ]]; then
                search_term="${search_term%?}"
                echo -ne "\b \b"
            fi
            continue
        fi
        # 正常字符
        search_term+="$char"
        echo -n "$char"
    done
    echo ""

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

    # 在多个日志文件中搜索
    local log_locations=(
        "/var/log/messages"
        "/var/log/syslog"
        "/var/log/system.log"
        "/var/log/auth.log"
        "/var/log/secure"
    )

    local found_results=false

    # 使用journalctl搜索（如果可用）
    if command -v journalctl >/dev/null 2>&1; then
        echo -e "${GREEN}Systemd日志搜索结果:${NC}"
        if journalctl -g "$search_term" -n 10 --no-pager 2>/dev/null; then
            found_results=true
            echo ""
        else
            echo "无法搜索systemd日志或无结果"
            echo ""
        fi
    fi

    # 在传统日志文件中搜索
    for log_file in "${log_locations[@]}"; do
        if [[ -f "$log_file" ]]; then
            local results=$(grep -i "$search_term" "$log_file" 2>/dev/null | tail -5)
            if [[ -n "$results" ]]; then
                echo -e "${GREEN}$log_file 中的结果:${NC}"
                echo "$results"
                echo ""
                found_results=true
            fi
        fi
    done

    if [[ "$found_results" == "false" ]]; then
        echo -e "${YELLOW}未找到相关日志记录${NC}"
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 实时日志监控
show_realtime_monitor() {
    clear
    echo -e "${BLUE}${BOLD}实时日志监控${NC}"
    echo ""

    local monitor_options=(
        "系统日志实时监控"
        "自定义文件监控"
        "错误日志监控"
        "返回上级菜单"
    )

    local result
    result=$(simple_selector "选择监控类型" "${monitor_options[@]}")

    case "$result" in
        "CANCELLED"|"SELECTOR_ERROR")
            return
            ;;
        0) realtime_system_logs ;;
        1) realtime_custom_file ;;
        2) realtime_error_logs ;;
        3) return ;;
    esac
}

# 实时系统日志监控
realtime_system_logs() {
    clear
    echo -e "${BLUE}${BOLD}实时系统日志监控${NC}"
    echo ""
    echo -e "${YELLOW}监控5秒，显示新的日志条目...${NC}"
    echo ""

    if command -v journalctl >/dev/null 2>&1; then
        echo -e "${GREEN}使用journalctl监控:${NC}"
        timeout 5 journalctl -f 2>/dev/null || echo "需要权限或journalctl不可用"
    elif [[ -f /var/log/messages ]]; then
        echo -e "${GREEN}监控 /var/log/messages:${NC}"
        timeout 5 tail -f /var/log/messages 2>/dev/null || echo "无法监控messages文件"
    elif [[ -f /var/log/syslog ]]; then
        echo -e "${GREEN}监控 /var/log/syslog:${NC}"
        timeout 5 tail -f /var/log/syslog 2>/dev/null || echo "无法监控syslog文件"
    else
        echo "未找到可监控的系统日志文件"
    fi

    echo ""
    echo -e "${YELLOW}监控完成，按任意键返回${NC}"
    read -n1
}

# 日志统计
show_log_statistics() {
    clear
    echo -e "${BLUE}${BOLD}日志统计${NC}"
    echo ""

    # 统计不同级别的日志
    echo -e "${GREEN}日志级别统计:${NC}"

    if command -v journalctl >/dev/null 2>&1; then
        echo "今日日志条目数:"
        journalctl --since today -q --no-pager 2>/dev/null | wc -l | xargs echo "  总计:"

        echo "错误级别统计:"
        for level in emerg alert crit err warning notice info debug; do
            local count=$(journalctl -p "$level" --since today -q --no-pager 2>/dev/null | wc -l)
            if [[ $count -gt 0 ]]; then
                echo "  $level: $count"
            fi
        done
    else
        echo "使用传统日志文件统计..."
        local log_file=""
        if [[ -f /var/log/messages ]]; then
            log_file="/var/log/messages"
        elif [[ -f /var/log/syslog ]]; then
            log_file="/var/log/syslog"
        fi

        if [[ -n "$log_file" ]]; then
            echo "今日 $log_file 统计:"
            local today=$(date '+%b %d')
            grep "$today" "$log_file" 2>/dev/null | wc -l | xargs echo "  今日条目:"

            echo "关键词统计:"
            for keyword in error warning info debug; do
                local count=$(grep -i "$keyword" "$log_file" 2>/dev/null | grep "$today" | wc -l)
                if [[ $count -gt 0 ]]; then
                    echo "  $keyword: $count"
                fi
            done
        else
            echo "未找到可统计的日志文件"
        fi
    fi

    echo ""
    echo -e "${GREEN}磁盘使用统计:${NC}"
    if [[ -d /var/log ]]; then
        echo "日志目录大小:"
        du -sh /var/log 2>/dev/null | xargs echo "  /var/log:"

        echo "最大的日志文件:"
        find /var/log -name "*.log" -type f -exec ls -lh {} \; 2>/dev/null | sort -k5 -hr | head -5 | awk '{print "  " $9 ": " $5}' || echo "  无法统计文件大小"
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 日志清理
show_log_cleanup() {
    while true; do
        clear
        echo -e "${BLUE}${BOLD}日志清理${NC}"
        echo ""

        echo -e "${RED}${BOLD}警告: 日志清理操作需要谨慎执行${NC}"
        echo -e "${YELLOW}建议在清理前备份重要日志${NC}"
        echo ""

        local cleanup_options=(
            "查看可清理的日志"
            "清理旧的归档日志"
            "清理journal日志"
            "查看日志配置"
            "返回上级菜单"
        )

        local result
        result=$(simple_selector "选择清理操作" "${cleanup_options[@]}")

        case "$result" in
            "CANCELLED"|"SELECTOR_ERROR")
                return
                ;;
            0) show_cleanable_logs ;;
            1) cleanup_archived_logs ;;
            2) cleanup_journal_logs ;;
            3) show_log_config ;;
            4) return ;;
        esac
    done
}

# 显示可清理的日志
show_cleanable_logs() {
    clear
    echo -e "${BLUE}${BOLD}可清理的日志${NC}"
    echo ""

    echo -e "${GREEN}旧的归档日志文件:${NC}"
    find /var/log -name "*.gz" -o -name "*.old" -o -name "*.[0-9]" 2>/dev/null | head -10 | while read file; do
        ls -lh "$file" 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    done || echo "  未找到归档日志文件"

    echo ""
    echo -e "${GREEN}Journal日志占用:${NC}"
    if command -v journalctl >/dev/null 2>&1; then
        journalctl --disk-usage 2>/dev/null | sed 's/^/  /' || echo "  无法获取journal大小"
    else
        echo "  journalctl不可用"
    fi

    echo ""
    echo -e "${GREEN}大型日志文件 (>10MB):${NC}"
    find /var/log -name "*.log" -size +10M -type f 2>/dev/null | head -5 | while read file; do
        ls -lh "$file" 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    done || echo "  未找到大型日志文件"

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 清理旧的归档日志
cleanup_archived_logs() {
    # 恢复终端状态以便用户输入
    if ! restore_terminal_state; then
        echo -e "${RED}终端状态恢复失败${NC}"
        sleep 2
        return
    fi

    clear
    echo -e "${BLUE}${BOLD}清理归档日志${NC}"
    echo ""

    echo -e "${YELLOW}正在查找归档日志...${NC}"
    local archived_logs=$(find /var/log -name "*.gz" -o -name "*.old" -o -name "*.[0-9]" 2>/dev/null)

    if [[ -z "$archived_logs" ]]; then
        echo -e "${GREEN}未找到归档日志文件${NC}"
        echo ""
        echo -e "${YELLOW}按任意键返回${NC}"
        read -n1
        return
    fi

    echo "$archived_logs" | head -20 | while read file; do
        ls -lh "$file" 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
    done

    echo ""
    echo -e "${RED}警告: 这将删除以上归档日志文件${NC}"
    echo -n "确认删除? [y/N]: "
    read -r confirm

    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "$archived_logs" | xargs rm -f 2>/dev/null
        echo -e "${GREEN}归档日志已清理${NC}"
    else
        echo "已取消"
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 清理journal日志
cleanup_journal_logs() {
    # 恢复终端状态以便用户输入
    if ! restore_terminal_state; then
        echo -e "${RED}终端状态恢复失败${NC}"
        sleep 2
        return
    fi

    clear
    echo -e "${BLUE}${BOLD}清理Journal日志${NC}"
    echo ""

    if ! command -v journalctl >/dev/null 2>&1; then
        echo -e "${YELLOW}journalctl不可用${NC}"
        echo ""
        echo -e "${YELLOW}按任意键返回${NC}"
        read -n1
        return
    fi

    echo -e "${GREEN}当前Journal占用:${NC}"
    journalctl --disk-usage 2>/dev/null || echo "无法获取大小"
    echo ""

    echo -e "${CYAN}清理选项:${NC}"
    echo "1. 保留最近7天"
    echo "2. 保留最近30天"
    echo "3. 限制大小为100M"
    echo "0. 取消"
    echo ""
    echo -n "请选择: "
    read -r choice

    case "$choice" in
        1)
            sudo journalctl --vacuum-time=7d 2>/dev/null && echo -e "${GREEN}清理完成${NC}" || echo -e "${RED}清理失败${NC}"
            ;;
        2)
            sudo journalctl --vacuum-time=30d 2>/dev/null && echo -e "${GREEN}清理完成${NC}" || echo -e "${RED}清理失败${NC}"
            ;;
        3)
            sudo journalctl --vacuum-size=100M 2>/dev/null && echo -e "${GREEN}清理完成${NC}" || echo -e "${RED}清理失败${NC}"
            ;;
        0)
            return
            ;;
    esac

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 查看日志配置
show_log_config() {
    clear
    echo -e "${BLUE}${BOLD}日志配置${NC}"
    echo ""

    echo -e "${GREEN}Journal配置:${NC}"
    if [[ -f /etc/systemd/journald.conf ]]; then
        grep -v "^#" /etc/systemd/journald.conf | grep -v "^$" || echo "使用默认配置"
    else
        echo "配置文件不存在"
    fi

    echo ""
    echo -e "${GREEN}Logrotate配置:${NC}"
    if [[ -f /etc/logrotate.conf ]]; then
        echo "主配置文件: /etc/logrotate.conf"
        echo "配置目录: /etc/logrotate.d/"
        ls -1 /etc/logrotate.d/ 2>/dev/null | head -10 | sed 's/^/  /'
    else
        echo "Logrotate未安装"
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 数据库日志
show_database_logs() {
    clear
    echo -e "${BLUE}${BOLD}数据库日志${NC}"
    echo ""

    # 检查常见数据库日志
    local db_logs=(
        "/var/log/mysql/error.log"
        "/var/log/mysql.log"
        "/var/log/postgresql/postgresql.log"
        "/var/log/mongodb/mongod.log"
    )

    local found_logs=()
    for log_file in "${db_logs[@]}"; do
        if [[ -f "$log_file" ]]; then
            found_logs+=("$log_file")
        fi
    done

    if [[ ${#found_logs[@]} -eq 0 ]]; then
        echo -e "${YELLOW}未找到常见的数据库日志文件${NC}"
    else
        echo -e "${GREEN}找到的数据库日志:${NC}"
        for log_file in "${found_logs[@]}"; do
            echo ""
            echo -e "${CYAN}$log_file (最后10行):${NC}"
            tail -10 "$log_file" 2>/dev/null || echo "无法读取"
        done
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 认证日志
show_auth_logs() {
    clear
    echo -e "${BLUE}${BOLD}认证日志${NC}"
    echo ""

    if [[ -f /var/log/auth.log ]]; then
        echo -e "${GREEN}认证日志 (最后20行):${NC}"
        tail -20 /var/log/auth.log 2>/dev/null || echo "无法读取"
    elif [[ -f /var/log/secure ]]; then
        echo -e "${GREEN}认证日志 (最后20行):${NC}"
        tail -20 /var/log/secure 2>/dev/null || echo "无法读取"
    else
        echo -e "${YELLOW}未找到认证日志文件${NC}"
    fi

    echo ""
    echo -e "${GREEN}最近的登录成功:${NC}"
    last | head -10 2>/dev/null || echo "无法获取登录记录"

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 实时自定义文件监控
realtime_custom_file() {
    clear
    echo -e "${BLUE}${BOLD}自定义文件监控${NC}"
    echo ""

    echo -e "${CYAN}请输入要监控的日志文件路径 (ESC 取消):${NC}"

    # 读取输入，支持 ESC 取消
    local log_path=""
    local char
    while IFS= read -r -s -n1 char; do
        # ESC 键
        if [[ $char == $'\x1b' ]]; then
            echo ""
            return
        fi
        # Enter 键
        if [[ -z $char ]]; then
            break
        fi
        # Backspace
        if [[ $char == $'\x7f' ]]; then
            if [[ -n $log_path ]]; then
                log_path="${log_path%?}"
                echo -ne "\b \b"
            fi
            continue
        fi
        # 正常字符
        log_path+="$char"
        echo -n "$char"
    done
    echo ""

    if [[ -z "$log_path" ]]; then
        return
    fi

    if [[ ! -f "$log_path" ]]; then
        echo -e "${RED}文件不存在: $log_path${NC}"
        sleep 2
        return
    fi

    clear
    echo -e "${BLUE}${BOLD}监控: $log_path${NC}"
    echo ""
    echo -e "${YELLOW}监控5秒，按Ctrl+C停止...${NC}"
    echo ""

    timeout 5 tail -f "$log_path" 2>/dev/null || echo "无法监控文件"

    echo ""
    echo -e "${YELLOW}监控完成，按任意键返回${NC}"
    read -n1
}

# 实时错误日志监控
realtime_error_logs() {
    clear
    echo -e "${BLUE}${BOLD}实时错误日志监控${NC}"
    echo ""
    echo -e "${YELLOW}监控5秒，显示错误级别的日志...${NC}"
    echo ""

    if command -v journalctl >/dev/null 2>&1; then
        echo -e "${GREEN}使用journalctl监控错误:${NC}"
        timeout 5 journalctl -f -p err 2>/dev/null || echo "需要权限或journalctl不可用"
    elif [[ -f /var/log/syslog ]]; then
        echo -e "${GREEN}监控 /var/log/syslog 错误:${NC}"
        timeout 5 tail -f /var/log/syslog 2>/dev/null | grep -i error || echo "无法监控"
    else
        echo "未找到可监控的错误日志"
    fi

    echo ""
    echo -e "${YELLOW}监控完成，按任意键返回${NC}"
    read -n1
}

# 自定义日志查看
show_custom_logs() {
    clear
    echo -e "${BLUE}${BOLD}自定义日志查看${NC}"
    echo ""

    echo -e "${CYAN}请输入日志文件路径 (ESC 取消):${NC}"

    # 读取输入，支持 ESC 取消
    local log_path=""
    local char
    while IFS= read -r -s -n1 char; do
        # ESC 键
        if [[ $char == $'\x1b' ]]; then
            echo ""
            return
        fi
        # Enter 键
        if [[ -z $char ]]; then
            break
        fi
        # Backspace
        if [[ $char == $'\x7f' ]]; then
            if [[ -n $log_path ]]; then
                log_path="${log_path%?}"
                echo -ne "\b \b"
            fi
            continue
        fi
        # 正常字符
        log_path+="$char"
        echo -n "$char"
    done
    echo ""

    if [[ -z "$log_path" ]]; then
        echo -e "${YELLOW}路径不能为空${NC}"
        sleep 2
        return
    fi

    # 验证文件路径安全性
    if ! validate_file_path "$log_path"; then
        echo -e "${RED}文件路径无效或不安全${NC}"
        sleep 2
        return
    fi

    if [[ ! -f "$log_path" ]]; then
        echo -e "${RED}文件不存在: $log_path${NC}"
        sleep 2
        return
    fi

    if [[ ! -r "$log_path" ]]; then
        echo -e "${RED}无权限读取文件: $log_path${NC}"
        sleep 2
        return
    fi

    clear
    echo -e "${BLUE}${BOLD}$log_path${NC}"
    echo ""
    echo -e "${GREEN}最后20行:${NC}"
    tail -20 "$log_path" 2>/dev/null || echo "无法读取文件"

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 模块信息
get_module_info() {
    echo "日志查看模块 v1.0 - 提供增强的日志查看功能"
}

# 模块初始化
init_logs_module() {
    debug_log "logs module: 模块初始化完成"
    return 0
}