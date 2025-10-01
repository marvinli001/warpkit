#!/bin/bash

# WarpKit 软件管理模块
# 这个模块提供软件安装和管理功能

# 软件信息保存目录
SOFTWARE_DATA_DIR="${WARPKIT_DIR:-/usr/local/warpkit}/data/software"

# 确保数据目录存在
ensure_data_dir() {
    if [[ ! -d "$SOFTWARE_DATA_DIR" ]]; then
        mkdir -p "$SOFTWARE_DATA_DIR" 2>/dev/null || {
            SOFTWARE_DATA_DIR="/tmp/warpkit_software_data"
            mkdir -p "$SOFTWARE_DATA_DIR"
        }
    fi
}

# 软件管理主界面
show_software_management() {
    ensure_data_dir

    local software_options=(
        "宝塔面板"
        "Hysteria V2"
        "返回主菜单"
    )

    while true; do
        local result
        result=$(codex_selector "软件管理" "一键安装和管理常用软件" 0 "${software_options[@]}")

        case "$result" in
            "CANCELLED")
                return
                ;;
            "SELECTOR_ERROR")
                # 切换到文本菜单模式
                show_software_management_text_menu
                return
                ;;
            0) manage_baota_panel ;;
            1) manage_hysteria2 ;;
            2) return ;;
            *)
                debug_log "software module: 未知选择 $result"
                return
                ;;
        esac
    done
}

# 软件管理文本菜单
show_software_management_text_menu() {
    ensure_data_dir

    while true; do
        clear
        print_logo
        show_system_info

        echo -e "${CYAN}${BOLD}软件管理${NC}"
        echo ""
        echo "1. 宝塔面板"
        echo "2. Hysteria V2"
        echo "0. 返回主菜单"
        echo ""
        echo -n "请选择功能 (0-2): "

        read -r choice
        echo ""

        case "$choice" in
            1) manage_baota_panel ;;
            2) manage_hysteria2 ;;
            0) return ;;
            *)
                echo -e "${RED}无效选择，请输入 0-2${NC}"
                sleep 2
                ;;
        esac
    done
}

# 检测宝塔面板是否已安装
check_baota_installed() {
    if [[ -f /etc/init.d/bt ]] || [[ -f /www/server/panel/pyenv/bin/python ]]; then
        return 0
    else
        return 1
    fi
}

# 宝塔面板管理
manage_baota_panel() {
    clear
    echo -e "${BLUE}${BOLD}宝塔面板管理${NC}"
    echo ""

    if check_baota_installed; then
        # 已安装，显示管理选项
        show_baota_management_menu
    else
        # 未安装，提示安装
        show_baota_install_prompt
    fi
}

# 宝塔面板已安装时的管理菜单
show_baota_management_menu() {
    local baota_options=(
        "查看面板信息"
        "卸载宝塔面板"
        "返回上级菜单"
    )

    while true; do
        local result
        result=$(simple_selector "宝塔面板已安装" "${baota_options[@]}")

        case "$result" in
            "CANCELLED"|"SELECTOR_ERROR")
                # 切换到文本模式
                show_baota_management_text_menu
                return
                ;;
            0) show_baota_panel_info ;;
            1) uninstall_baota_panel ;;
            2) return ;;
            *)
                return
                ;;
        esac
    done
}

# 宝塔管理文本菜单
show_baota_management_text_menu() {
    while true; do
        clear
        echo -e "${BLUE}${BOLD}宝塔面板管理${NC}"
        echo ""
        echo -e "${GREEN}✓ 宝塔面板已安装${NC}"
        echo ""
        echo "1. 查看面板信息"
        echo "2. 卸载宝塔面板"
        echo "0. 返回上级菜单"
        echo ""
        echo -n "请选择功能 (0-2): "

        read -r choice
        echo ""

        case "$choice" in
            1) show_baota_panel_info ;;
            2) uninstall_baota_panel ;;
            0) return ;;
            *)
                echo -e "${RED}无效选择，请输入 0-2${NC}"
                sleep 2
                ;;
        esac
    done
}

# 显示宝塔面板未安装提示和安装选项
show_baota_install_prompt() {
    echo -e "${YELLOW}⚠ 未检测到宝塔面板${NC}"
    echo ""
    echo -e "${CYAN}宝塔面板是一款简单易用的Linux服务器管理面板${NC}"
    echo ""
    echo "功能特性："
    echo "  • 一键部署LNMP/LAMP环境"
    echo "  • 网站、FTP、数据库管理"
    echo "  • 文件管理器"
    echo "  • 安全管理"
    echo "  • 系统监控"
    echo ""
    echo -e "${YELLOW}是否安装宝塔面板? [y/N]${NC}"
    echo -n "请选择: "

    # 恢复终端状态以便正常读取输入
    if ! restore_terminal_state; then
        echo -e "\n${RED}终端状态恢复失败${NC}"
        sleep 2
        return
    fi

    read -r install_choice

    # 重新设置终端为raw模式
    if ! set_raw_terminal; then
        echo -e "${RED}终端模式设置失败${NC}"
        sleep 2
        return
    fi

    case "$install_choice" in
        [yY]|[yY][eE][sS])
            install_baota_panel
            ;;
        *)
            echo -e "\n${YELLOW}取消安装${NC}"
            sleep 1
            return
            ;;
    esac
}

# 安装宝塔面板
install_baota_panel() {
    clear
    echo -e "${BLUE}${BOLD}安装宝塔面板${NC}"
    echo ""
    echo -e "${YELLOW}正在下载并安装宝塔面板，请稍候...${NC}"
    echo ""

    # 创建临时文件保存安装输出
    local install_log="${SOFTWARE_DATA_DIR}/baota_install_$(date +%Y%m%d_%H%M%S).log"
    local panel_info_file="${SOFTWARE_DATA_DIR}/baota_panel_info.txt"

    # 恢复终端以便安装脚本正常运行
    restore_terminal_state

    # 下载并执行安装脚本
    if command -v curl >/dev/null 2>&1; then
        curl -sSO https://download.bt.cn/install/install_panel.sh
    else
        wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh
    fi

    if [[ ! -f install_panel.sh ]]; then
        echo -e "${RED}✗ 下载安装脚本失败${NC}"
        echo ""
        echo "按任意键返回"
        read -n1
        set_raw_terminal
        return 1
    fi

    # 执行安装并保存输出
    echo -e "${GREEN}开始安装宝塔面板...${NC}"
    echo -e "${CYAN}安装过程中将自动确认安装选项...${NC}"
    echo ""

    # 使用 yes 命令自动向安装脚本提供 'y' 输入
    # 宝塔安装脚本会询问是否确认安装，我们自动回答 y
    yes y | bash install_panel.sh ed8484bec 2>&1 | tee "$install_log"

    local install_status=${PIPESTATUS[1]}

    # 清理安装脚本
    rm -f install_panel.sh

    if [[ $install_status -eq 0 ]]; then
        echo ""
        echo -e "${GREEN}✓ 宝塔面板安装完成${NC}"
        echo ""

        # 提取并保存面板信息
        extract_baota_panel_info "$install_log" "$panel_info_file"

        echo -e "${CYAN}面板信息已保存，可通过 '查看面板信息' 功能查看${NC}"
        echo ""
    else
        echo ""
        echo -e "${RED}✗ 宝塔面板安装失败${NC}"
        echo -e "${YELLOW}安装日志已保存到: $install_log${NC}"
        echo ""
    fi

    echo "按任意键继续"
    read -n1

    # 重新设置终端模式
    set_raw_terminal
}

# 提取宝塔面板登录信息
extract_baota_panel_info() {
    local log_file="$1"
    local info_file="$2"

    if [[ ! -f "$log_file" ]]; then
        return 1
    fi

    # 提取面板信息（通常在日志末尾）
    # 宝塔安装完成后会输出类似以下信息：
    # ==================================================================
    # Congratulations! Installed successfully!
    # ==================================================================
    # 外网面板地址: http://x.x.x.x:8888/xxxxxxxx
    # 内网面板地址: http://x.x.x.x:8888/xxxxxxxx
    # username: xxxxxxxx
    # password: xxxxxxxx
    # ...

    {
        echo "=================================================="
        echo "宝塔面板登录信息"
        echo "安装时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "=================================================="
        echo ""

        # 尝试提取面板地址、用户名和密码
        # 从日志文件中提取包含关键信息的行
        grep -A 20 "Congratulations" "$log_file" | grep -E "(面板地址|username|password|外网面板|内网面板|Initial|安全入口)" || {
            # 如果上面的方法失败，尝试提取日志最后50行中的关键信息
            tail -50 "$log_file" | grep -E "(面板地址|username|password|外网面板|内网面板|http://.*:.*/.+|Initial|安全入口)"
        }

        echo ""
        echo "=================================================="
        echo "完整安装日志: $log_file"
        echo "=================================================="
    } > "$info_file"

    # 如果成功创建了信息文件，显示提示
    if [[ -f "$info_file" ]]; then
        echo -e "${GREEN}✓ 面板信息已保存到: $info_file${NC}"
        return 0
    else
        return 1
    fi
}

# 查看宝塔面板信息
show_baota_panel_info() {
    clear
    echo -e "${BLUE}${BOLD}宝塔面板信息${NC}"
    echo ""

    local panel_info_file="${SOFTWARE_DATA_DIR}/baota_panel_info.txt"

    # 首先尝试从保存的文件读取
    if [[ -f "$panel_info_file" ]]; then
        cat "$panel_info_file"
        echo ""
    else
        echo -e "${YELLOW}未找到已保存的面板信息${NC}"
        echo ""
        echo -e "${CYAN}尝试从宝塔命令获取当前信息...${NC}"
        echo ""

        # 尝试使用宝塔命令获取信息
        if [[ -f /etc/init.d/bt ]]; then
            # 恢复终端状态
            restore_terminal_state

            # 获取面板默认信息
            echo -e "${GREEN}面板管理命令:${NC}"
            echo "bt default   # 查看默认面板信息"
            echo "bt 14        # 查看面板入口"
            echo "bt 5         # 查看面板用户名"
            echo "bt 6         # 查看面板密码"
            echo ""

            # 尝试执行bt命令显示默认信息
            if command -v bt >/dev/null 2>&1; then
                echo -e "${GREEN}正在获取面板信息...${NC}"
                echo ""
                bt default 2>/dev/null || echo "请手动执行 'bt default' 查看面板信息"
            fi

            # 重新设置终端模式
            set_raw_terminal
        else
            echo -e "${RED}无法获取面板信息${NC}"
        fi
        echo ""
    fi

    echo ""
    echo "按任意键返回"
    read -n1
}

# 卸载宝塔面板
uninstall_baota_panel() {
    clear
    echo -e "${BLUE}${BOLD}卸载宝塔面板${NC}"
    echo ""
    echo -e "${RED}${BOLD}警告: 此操作将完全卸载宝塔面板及其所有数据！${NC}"
    echo ""
    echo "这将会："
    echo "  • 删除所有面板数据"
    echo "  • 移除面板程序文件"
    echo "  • 清理相关配置"
    echo ""
    echo -e "${YELLOW}是否确认卸载宝塔面板? [y/N]${NC}"
    echo -n "请选择: "

    # 恢复终端状态
    if ! restore_terminal_state; then
        echo -e "\n${RED}终端状态恢复失败${NC}"
        sleep 2
        set_raw_terminal
        return
    fi

    read -r uninstall_choice

    # 重新设置终端模式
    if ! set_raw_terminal; then
        echo -e "${RED}终端模式设置失败${NC}"
        sleep 2
        return
    fi

    case "$uninstall_choice" in
        [yY]|[yY][eE][sS])
            echo ""
            echo -e "${YELLOW}正在卸载宝塔面板...${NC}"

            # 恢复终端以便卸载脚本正常运行
            restore_terminal_state

            # 下载并执行卸载脚本
            if [[ -f /etc/init.d/bt ]]; then
                # 使用宝塔官方卸载脚本
                if command -v curl >/dev/null 2>&1; then
                    curl -sSO https://download.bt.cn/install/bt-uninstall.sh
                else
                    wget -O bt-uninstall.sh https://download.bt.cn/install/bt-uninstall.sh
                fi

                if [[ -f bt-uninstall.sh ]]; then
                    bash bt-uninstall.sh
                    rm -f bt-uninstall.sh
                else
                    # 如果下载失败，尝试使用本地卸载命令
                    /etc/init.d/bt stop
                    chkconfig --del bt 2>/dev/null
                    rm -f /etc/init.d/bt
                    rm -rf /www/server/panel
                fi

                echo ""
                echo -e "${GREEN}✓ 宝塔面板已卸载${NC}"

                # 清理保存的面板信息
                rm -f "${SOFTWARE_DATA_DIR}/baota_panel_info.txt"
            else
                echo -e "${RED}未找到宝塔面板安装${NC}"
            fi

            echo ""
            echo "按任意键继续"
            read -n1

            # 重新设置终端模式
            set_raw_terminal
            ;;
        *)
            echo ""
            echo -e "${YELLOW}取消卸载${NC}"
            sleep 1
            ;;
    esac
}

#==============================================================================
# Hysteria V2 管理功能
#==============================================================================

# 检测 Hysteria V2 是否已安装
check_hysteria2_installed() {
    if [[ -f /usr/local/bin/hysteria ]] && command -v hysteria >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 检查 Hysteria V2 服务状态
check_hysteria2_service_status() {
    if systemctl is-active --quiet hysteria-server.service 2>/dev/null; then
        echo "running"
    elif systemctl is-enabled --quiet hysteria-server.service 2>/dev/null; then
        echo "stopped"
    else
        echo "inactive"
    fi
}

# 检查开机自启状态
check_hysteria2_autostart() {
    if systemctl is-enabled --quiet hysteria-server.service 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Hysteria V2 主管理界面
manage_hysteria2() {
    clear
    echo -e "${BLUE}${BOLD}Hysteria V2 管理器${NC}"
    echo ""

    # 检测安装状态
    local installed=false
    local service_status="未安装"
    local autostart_status="未知"
    local version_info=""

    if check_hysteria2_installed; then
        installed=true
        version_info=$(hysteria version 2>/dev/null | head -1 || echo "未知版本")
        service_status=$(check_hysteria2_service_status)

        if check_hysteria2_autostart; then
            autostart_status="已启用"
        else
            autostart_status="未启用"
        fi
    fi

    # 显示状态信息
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    if $installed; then
        echo -e "${GREEN}✓ Hysteria V2 已安装${NC}"
        echo -e "${CYAN}版本信息:${NC} $version_info"
        echo ""
        case "$service_status" in
            "running")
                echo -e "${CYAN}服务状态:${NC} ${GREEN}● 运行中${NC}"
                ;;
            "stopped")
                echo -e "${CYAN}服务状态:${NC} ${YELLOW}○ 已停止${NC}"
                ;;
            *)
                echo -e "${CYAN}服务状态:${NC} ${RED}○ 未激活${NC}"
                ;;
        esac
        echo -e "${CYAN}开机自启:${NC} $autostart_status"
    else
        echo -e "${YELLOW}⚠ Hysteria V2 未安装${NC}"
    fi
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if $installed; then
        show_hysteria2_management_menu "$service_status"
    else
        show_hysteria2_install_prompt
    fi
}

# Hysteria V2 已安装时的管理菜单
show_hysteria2_management_menu() {
    local service_status="$1"

    local hy2_options=(
        "查看服务状态"
        "启动/停止/重启服务"
        "开机自启管理"
        "查看配置信息"
        "编辑配置文件"
        "查看日志"
        "卸载 Hysteria V2"
        "返回上级菜单"
    )

    while true; do
        local result
        result=$(simple_selector "Hysteria V2 管理" "${hy2_options[@]}")

        case "$result" in
            "CANCELLED"|"SELECTOR_ERROR")
                show_hysteria2_management_text_menu "$service_status"
                return
                ;;
            0) show_hysteria2_status ;;
            1) manage_hysteria2_service ;;
            2) manage_hysteria2_autostart ;;
            3) show_hysteria2_config_info ;;
            4) edit_hysteria2_config ;;
            5) show_hysteria2_logs ;;
            6) uninstall_hysteria2 ;;
            7) return ;;
            *)
                return
                ;;
        esac
    done
}

# Hysteria V2 管理文本菜单
show_hysteria2_management_text_menu() {
    local service_status="$1"

    while true; do
        clear
        echo -e "${BLUE}${BOLD}Hysteria V2 管理器${NC}"
        echo ""
        echo -e "${GREEN}✓ Hysteria V2 已安装${NC}"
        echo ""
        echo "1. 查看服务状态"
        echo "2. 启动/停止/重启服务"
        echo "3. 开机自启管理"
        echo "4. 查看配置信息"
        echo "5. 编辑配置文件"
        echo "6. 查看日志"
        echo "7. 卸载 Hysteria V2"
        echo "0. 返回上级菜单"
        echo ""
        echo -n "请选择功能 (0-7): "

        read -r choice
        echo ""

        case "$choice" in
            1) show_hysteria2_status ;;
            2) manage_hysteria2_service ;;
            3) manage_hysteria2_autostart ;;
            4) show_hysteria2_config_info ;;
            5) edit_hysteria2_config ;;
            6) show_hysteria2_logs ;;
            7) uninstall_hysteria2 ;;
            0) return ;;
            *)
                echo -e "${RED}无效选择，请输入 0-7${NC}"
                sleep 2
                ;;
        esac
    done
}

# 显示 Hysteria V2 未安装提示
show_hysteria2_install_prompt() {
    echo -e "${CYAN}Hysteria V2 是新一代的代理工具${NC}"
    echo ""
    echo "功能特性："
    echo "  • 基于 QUIC 协议，性能优异"
    echo "  • 支持多种认证和混淆方式"
    echo "  • 内置流量控制和拥塞控制"
    echo "  • 易于配置和管理"
    echo ""
    echo "安装选项："
    echo "  1) 引导式安装 - 交互式配置向导"
    echo "  2) 快速安装 - 使用默认配置快速安装"
    echo "  0) 返回上级菜单"
    echo ""
    echo -n "请选择安装方式 (0-2): "

    if ! restore_terminal_state; then
        echo -e "\n${RED}终端状态恢复失败${NC}"
        sleep 2
        return
    fi

    read -r install_mode

    if ! set_raw_terminal; then
        echo -e "${RED}终端模式设置失败${NC}"
        sleep 2
        return
    fi

    case "$install_mode" in
        1)
            install_hysteria2_guided
            ;;
        2)
            install_hysteria2_quick
            ;;
        0)
            return
            ;;
        *)
            echo -e "\n${YELLOW}无效选择${NC}"
            sleep 1
            ;;
    esac
}

# 引导式安装 Hysteria V2
install_hysteria2_guided() {
    clear
    echo -e "${BLUE}${BOLD}Hysteria V2 引导式安装${NC}"
    echo ""
    echo -e "${YELLOW}请按照提示配置 Hysteria V2 服务端${NC}"
    echo ""

    # 恢复终端状态以便用户输入
    restore_terminal_state

    # 1. 监听端口
    local listen_port
    echo -e "${CYAN}[1/6] 配置监听端口${NC}"
    echo -n "请输入监听端口 (默认 443): "
    read -r listen_port
    listen_port=${listen_port:-443}
    echo ""

    # 2. 认证密码
    local auth_password
    echo -e "${CYAN}[2/6] 配置认证密码${NC}"
    echo -n "请输入认证密码 (留空随机生成): "
    read -r auth_password
    if [[ -z "$auth_password" ]]; then
        auth_password=$(openssl rand -base64 16 | tr -d '=+/' | cut -c1-16)
        echo -e "${GREEN}已生成随机密码: $auth_password${NC}"
    fi
    echo ""

    # 3. 混淆密码
    local obfs_enabled
    local obfs_password
    echo -e "${CYAN}[3/6] 是否启用混淆 (obfuscation)?${NC}"
    echo -n "启用混淆可提高隐蔽性 [y/N]: "
    read -r obfs_enabled
    if [[ "$obfs_enabled" =~ ^[yY]$ ]]; then
        echo -n "请输入混淆密码 (留空随机生成): "
        read -r obfs_password
        if [[ -z "$obfs_password" ]]; then
            obfs_password=$(openssl rand -base64 16 | tr -d '=+/' | cut -c1-16)
            echo -e "${GREEN}已生成随机混淆密码: $obfs_password${NC}"
        fi
    fi
    echo ""

    # 4. TLS 证书配置
    local tls_mode
    local domain_name
    local email_addr
    echo -e "${CYAN}[4/6] TLS 证书配置${NC}"
    echo "1) 自签名证书 (推荐用于测试)"
    echo "2) Let's Encrypt 证书 (需要域名)"
    echo -n "请选择 (1-2, 默认 1): "
    read -r tls_mode
    tls_mode=${tls_mode:-1}

    if [[ "$tls_mode" == "2" ]]; then
        echo -n "请输入域名: "
        read -r domain_name
        echo -n "请输入邮箱地址: "
        read -r email_addr
    fi
    echo ""

    # 5. 带宽限制 (可选)
    local bandwidth_limit
    echo -e "${CYAN}[5/6] 带宽限制 (可选)${NC}"
    echo -n "是否设置带宽限制? [y/N]: "
    read -r bandwidth_limit
    local up_speed="1 gbps"
    local down_speed="1 gbps"
    if [[ "$bandwidth_limit" =~ ^[yY]$ ]]; then
        echo -n "上传速度限制 (如: 100 mbps, 1 gbps, 默认 1 gbps): "
        read -r up_speed
        up_speed=${up_speed:-"1 gbps"}
        echo -n "下载速度限制 (如: 100 mbps, 1 gbps, 默认 1 gbps): "
        read -r down_speed
        down_speed=${down_speed:-"1 gbps"}
    fi
    echo ""

    # 6. 确认配置
    echo -e "${CYAN}[6/6] 配置确认${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}监听端口:${NC} $listen_port"
    echo -e "${GREEN}认证密码:${NC} $auth_password"
    if [[ "$obfs_enabled" =~ ^[yY]$ ]]; then
        echo -e "${GREEN}混淆密码:${NC} $obfs_password"
    else
        echo -e "${GREEN}混淆:${NC} 未启用"
    fi
    if [[ "$tls_mode" == "2" ]]; then
        echo -e "${GREEN}TLS 模式:${NC} Let's Encrypt"
        echo -e "${GREEN}域名:${NC} $domain_name"
    else
        echo -e "${GREEN}TLS 模式:${NC} 自签名证书"
    fi
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -n "确认安装? [y/N]: "
    read -r confirm
    echo ""

    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        echo -e "${YELLOW}取消安装${NC}"
        sleep 1
        set_raw_terminal
        return
    fi

    # 执行安装
    echo -e "${GREEN}开始安装 Hysteria V2...${NC}"
    echo ""

    # 下载并执行官方安装脚本
    if ! bash <(curl -fsSL https://get.hy2.sh/); then
        echo ""
        echo -e "${RED}✗ Hysteria V2 安装失败${NC}"
        echo ""
        echo "按任意键返回"
        read -n1
        set_raw_terminal
        return
    fi

    echo ""
    echo -e "${GREEN}✓ Hysteria V2 安装完成${NC}"
    echo ""

    # 生成配置文件
    echo -e "${YELLOW}正在生成配置文件...${NC}"
    generate_hysteria2_config "$listen_port" "$auth_password" "$obfs_enabled" "$obfs_password" \
                              "$tls_mode" "$domain_name" "$email_addr" "$up_speed" "$down_speed"

    # 启动服务并设置开机自启
    echo -e "${YELLOW}正在启动服务...${NC}"
    systemctl enable --now hysteria-server.service

    if systemctl is-active --quiet hysteria-server.service; then
        echo -e "${GREEN}✓ Hysteria V2 服务已启动${NC}"
    else
        echo -e "${YELLOW}⚠ 服务启动失败，请检查配置文件${NC}"
    fi

    # 保存配置信息
    save_hysteria2_info "$listen_port" "$auth_password" "$obfs_password"

    # 显示连接信息
    echo ""
    show_hysteria2_connection_info "$listen_port" "$auth_password" "$obfs_password"

    echo ""
    echo "按任意键继续"
    read -n1
    set_raw_terminal
}

# 快速安装 Hysteria V2 (无引导)
install_hysteria2_quick() {
    clear
    echo -e "${BLUE}${BOLD}Hysteria V2 快速安装${NC}"
    echo ""
    echo -e "${YELLOW}将使用默认配置快速安装 Hysteria V2${NC}"
    echo ""
    echo "默认配置："
    echo "  • 监听端口: 443"
    echo "  • 认证方式: 密码认证（随机生成）"
    echo "  • TLS: 自签名证书"
    echo "  • 混淆: 未启用"
    echo ""
    echo -n "确认安装? [y/N]: "

    restore_terminal_state
    read -r confirm

    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        echo ""
        echo -e "${YELLOW}取消安装${NC}"
        sleep 1
        set_raw_terminal
        return
    fi

    echo ""
    echo -e "${GREEN}开始安装 Hysteria V2...${NC}"
    echo ""

    # 执行官方安装脚本
    if ! bash <(curl -fsSL https://get.hy2.sh/); then
        echo ""
        echo -e "${RED}✗ Hysteria V2 安装失败${NC}"
        echo ""
        echo "按任意键返回"
        read -n1
        set_raw_terminal
        return
    fi

    echo ""
    echo -e "${GREEN}✓ Hysteria V2 安装完成${NC}"
    echo ""

    # 生成随机密码
    local auth_password
    auth_password=$(openssl rand -base64 16 | tr -d '=+/' | cut -c1-16)

    # 生成默认配置
    echo -e "${YELLOW}正在生成配置文件...${NC}"
    generate_hysteria2_config "443" "$auth_password" "n" "" "1" "" "" "1 gbps" "1 gbps"

    # 启动服务
    echo -e "${YELLOW}正在启动服务...${NC}"
    systemctl enable --now hysteria-server.service

    if systemctl is-active --quiet hysteria-server.service; then
        echo -e "${GREEN}✓ Hysteria V2 服务已启动${NC}"
    else
        echo -e "${YELLOW}⚠ 服务启动失败，请检查配置文件${NC}"
    fi

    # 保存配置信息
    save_hysteria2_info "443" "$auth_password" ""

    # 显示连接信息
    echo ""
    show_hysteria2_connection_info "443" "$auth_password" ""

    echo ""
    echo -e "${CYAN}提示: 您可以稍后通过 '编辑配置文件' 选项修改配置${NC}"
    echo ""
    echo "按任意键继续"
    read -n1
    set_raw_terminal
}

# 生成 Hysteria V2 配置文件
generate_hysteria2_config() {
    local port="$1"
    local password="$2"
    local obfs_enabled="$3"
    local obfs_password="$4"
    local tls_mode="$5"
    local domain="$6"
    local email="$7"
    local up_speed="$8"
    local down_speed="$9"

    # 确保配置目录存在
    mkdir -p /etc/hysteria

    # 获取服务器 IP
    local server_ip
    server_ip=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")

    # 生成配置文件
    cat > /etc/hysteria/config.yaml <<EOF
# Hysteria V2 服务端配置
# 由 WarpKit 自动生成

listen: :$port

EOF

    # TLS 配置
    if [[ "$tls_mode" == "2" ]] && [[ -n "$domain" ]]; then
        # ACME 自动证书
        cat >> /etc/hysteria/config.yaml <<EOF
acme:
  domains:
    - $domain
  email: $email

EOF
    else
        # 自签名证书
        # 生成自签名证书
        openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
                -keyout /etc/hysteria/server.key \
                -out /etc/hysteria/server.crt \
                -subj "/CN=$server_ip" \
                -days 36500 2>/dev/null

        cat >> /etc/hysteria/config.yaml <<EOF
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

EOF
    fi

    # 认证配置
    cat >> /etc/hysteria/config.yaml <<EOF
auth:
  type: password
  password: $password

EOF

    # 混淆配置
    if [[ "$obfs_enabled" =~ ^[yY]$ ]] && [[ -n "$obfs_password" ]]; then
        cat >> /etc/hysteria/config.yaml <<EOF
obfs:
  type: salamander
  salamander:
    password: $obfs_password

EOF
    fi

    # 带宽配置
    if [[ -n "$up_speed" ]] && [[ -n "$down_speed" ]]; then
        cat >> /etc/hysteria/config.yaml <<EOF
bandwidth:
  up: $up_speed
  down: $down_speed

EOF
    fi

    # 其他优化配置
    cat >> /etc/hysteria/config.yaml <<EOF
quic:
  initStreamReceiveWindow: 16777216
  maxStreamReceiveWindow: 16777216
  initConnReceiveWindow: 33554432
  maxConnReceiveWindow: 33554432

ignoreClientBandwidth: false
disableUDP: false
udpIdleTimeout: 60s
EOF

    echo -e "${GREEN}✓ 配置文件已生成: /etc/hysteria/config.yaml${NC}"
}

# 保存 Hysteria V2 连接信息
save_hysteria2_info() {
    local port="$1"
    local password="$2"
    local obfs_password="$3"

    local info_file="${SOFTWARE_DATA_DIR}/hysteria2_info.txt"
    local server_ip
    server_ip=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")

    {
        echo "=================================================="
        echo "Hysteria V2 连接信息"
        echo "保存时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "=================================================="
        echo ""
        echo "服务器地址: $server_ip"
        echo "监听端口: $port"
        echo "认证密码: $password"
        if [[ -n "$obfs_password" ]]; then
            echo "混淆密码: $obfs_password"
        fi
        echo ""
        echo "配置文件: /etc/hysteria/config.yaml"
        echo ""
        echo "=================================================="
    } > "$info_file"
}

# 显示连接信息
show_hysteria2_connection_info() {
    local port="$1"
    local password="$2"
    local obfs_password="$3"

    local server_ip
    server_ip=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 icanhazip.com 2>/dev/null || echo "YOUR_SERVER_IP")

    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}${BOLD}Hysteria V2 连接信息${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${CYAN}服务器地址:${NC} $server_ip"
    echo -e "${CYAN}监听端口:${NC} $port"
    echo -e "${CYAN}认证密码:${NC} $password"
    if [[ -n "$obfs_password" ]]; then
        echo -e "${CYAN}混淆密码:${NC} $obfs_password"
    fi
    echo ""
    echo -e "${YELLOW}连接信息已保存到: ${SOFTWARE_DATA_DIR}/hysteria2_info.txt${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 查看 Hysteria V2 服务状态
show_hysteria2_status() {
    clear
    echo -e "${BLUE}${BOLD}Hysteria V2 服务状态${NC}"
    echo ""

    restore_terminal_state

    if systemctl is-active --quiet hysteria-server.service; then
        echo -e "${GREEN}● 服务状态: 运行中${NC}"
        echo ""
        systemctl status hysteria-server.service --no-pager -l
    else
        echo -e "${YELLOW}○ 服务状态: 已停止${NC}"
        echo ""
        systemctl status hysteria-server.service --no-pager -l
    fi

    echo ""
    echo "按任意键返回"
    read -n1
    set_raw_terminal
}

# 管理 Hysteria V2 服务
manage_hysteria2_service() {
    clear
    echo -e "${BLUE}${BOLD}Hysteria V2 服务管理${NC}"
    echo ""
    echo "1. 启动服务"
    echo "2. 停止服务"
    echo "3. 重启服务"
    echo "0. 返回"
    echo ""
    echo -n "请选择 (0-3): "

    restore_terminal_state
    read -r choice

    case "$choice" in
        1)
            echo ""
            echo -e "${YELLOW}正在启动服务...${NC}"
            systemctl start hysteria-server.service
            if systemctl is-active --quiet hysteria-server.service; then
                echo -e "${GREEN}✓ 服务已启动${NC}"
            else
                echo -e "${RED}✗ 服务启动失败${NC}"
            fi
            ;;
        2)
            echo ""
            echo -e "${YELLOW}正在停止服务...${NC}"
            systemctl stop hysteria-server.service
            echo -e "${GREEN}✓ 服务已停止${NC}"
            ;;
        3)
            echo ""
            echo -e "${YELLOW}正在重启服务...${NC}"
            systemctl restart hysteria-server.service
            if systemctl is-active --quiet hysteria-server.service; then
                echo -e "${GREEN}✓ 服务已重启${NC}"
            else
                echo -e "${RED}✗ 服务重启失败${NC}"
            fi
            ;;
        0)
            set_raw_terminal
            return
            ;;
    esac

    echo ""
    echo "按任意键返回"
    read -n1
    set_raw_terminal
}

# 管理开机自启
manage_hysteria2_autostart() {
    clear
    echo -e "${BLUE}${BOLD}Hysteria V2 开机自启管理${NC}"
    echo ""

    if check_hysteria2_autostart; then
        echo -e "${GREEN}当前状态: 已启用开机自启${NC}"
        echo ""
        echo "1. 禁用开机自启"
        echo "0. 返回"
    else
        echo -e "${YELLOW}当前状态: 未启用开机自启${NC}"
        echo ""
        echo "1. 启用开机自启"
        echo "0. 返回"
    fi

    echo ""
    echo -n "请选择 (0-1): "

    restore_terminal_state
    read -r choice

    case "$choice" in
        1)
            echo ""
            if check_hysteria2_autostart; then
                echo -e "${YELLOW}正在禁用开机自启...${NC}"
                systemctl disable hysteria-server.service
                echo -e "${GREEN}✓ 已禁用开机自启${NC}"
            else
                echo -e "${YELLOW}正在启用开机自启...${NC}"
                systemctl enable hysteria-server.service
                echo -e "${GREEN}✓ 已启用开机自启${NC}"
            fi
            ;;
        0)
            set_raw_terminal
            return
            ;;
    esac

    echo ""
    echo "按任意键返回"
    read -n1
    set_raw_terminal
}

# 查看配置信息
show_hysteria2_config_info() {
    clear
    echo -e "${BLUE}${BOLD}Hysteria V2 配置信息${NC}"
    echo ""

    local info_file="${SOFTWARE_DATA_DIR}/hysteria2_info.txt"

    if [[ -f "$info_file" ]]; then
        cat "$info_file"
    else
        echo -e "${YELLOW}未找到已保存的配置信息${NC}"
        echo ""
        echo -e "${CYAN}当前配置文件内容:${NC}"
        echo ""
        if [[ -f /etc/hysteria/config.yaml ]]; then
            cat /etc/hysteria/config.yaml
        else
            echo -e "${RED}配置文件不存在${NC}"
        fi
    fi

    echo ""
    echo "按任意键返回"
    restore_terminal_state
    read -n1
    set_raw_terminal
}

# 编辑配置文件
edit_hysteria2_config() {
    clear
    echo -e "${BLUE}${BOLD}编辑 Hysteria V2 配置${NC}"
    echo ""
    echo -e "${YELLOW}配置文件路径: /etc/hysteria/config.yaml${NC}"
    echo ""
    echo -e "${CYAN}修改配置后需要重启服务才能生效${NC}"
    echo ""
    echo -n "是否打开编辑器? [y/N]: "

    restore_terminal_state
    read -r confirm

    if [[ "$confirm" =~ ^[yY]$ ]]; then
        # 尝试使用可用的编辑器
        if command -v nano >/dev/null 2>&1; then
            nano /etc/hysteria/config.yaml
        elif command -v vi >/dev/null 2>&1; then
            vi /etc/hysteria/config.yaml
        else
            echo ""
            echo -e "${RED}未找到可用的文本编辑器${NC}"
            echo "请手动编辑: /etc/hysteria/config.yaml"
        fi

        echo ""
        echo -n "是否重启服务使配置生效? [y/N]: "
        read -r restart_confirm

        if [[ "$restart_confirm" =~ ^[yY]$ ]]; then
            echo ""
            echo -e "${YELLOW}正在重启服务...${NC}"
            systemctl restart hysteria-server.service
            if systemctl is-active --quiet hysteria-server.service; then
                echo -e "${GREEN}✓ 服务已重启${NC}"
            else
                echo -e "${RED}✗ 服务重启失败，请检查配置文件${NC}"
            fi
        fi
    fi

    echo ""
    echo "按任意键返回"
    read -n1
    set_raw_terminal
}

# 查看日志
show_hysteria2_logs() {
    clear
    echo -e "${BLUE}${BOLD}Hysteria V2 服务日志${NC}"
    echo ""

    restore_terminal_state

    echo -e "${CYAN}最近 50 条日志:${NC}"
    echo ""
    journalctl -u hysteria-server.service -n 50 --no-pager

    echo ""
    echo "按任意键返回"
    read -n1
    set_raw_terminal
}

# 卸载 Hysteria V2
uninstall_hysteria2() {
    clear
    echo -e "${BLUE}${BOLD}卸载 Hysteria V2${NC}"
    echo ""
    echo -e "${RED}${BOLD}警告: 此操作将完全卸载 Hysteria V2！${NC}"
    echo ""
    echo "这将会："
    echo "  • 停止 Hysteria V2 服务"
    echo "  • 删除 Hysteria V2 程序"
    echo "  • 删除配置文件"
    echo "  • 删除证书文件"
    echo ""
    echo -n "确认卸载? [y/N]: "

    restore_terminal_state
    read -r confirm

    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
        echo ""
        echo -e "${YELLOW}取消卸载${NC}"
        sleep 1
        set_raw_terminal
        return
    fi

    echo ""
    echo -e "${YELLOW}正在卸载 Hysteria V2...${NC}"

    # 停止并禁用服务
    systemctl stop hysteria-server.service 2>/dev/null
    systemctl disable hysteria-server.service 2>/dev/null

    # 删除程序文件
    rm -f /usr/local/bin/hysteria
    rm -f /etc/systemd/system/hysteria-server.service
    rm -f /etc/systemd/system/hysteria-server@.service

    # 删除配置目录
    rm -rf /etc/hysteria

    # 重新加载 systemd
    systemctl daemon-reload

    # 删除保存的信息
    rm -f "${SOFTWARE_DATA_DIR}/hysteria2_info.txt"

    echo -e "${GREEN}✓ Hysteria V2 已卸载${NC}"

    echo ""
    echo "按任意键返回"
    read -n1
    set_raw_terminal
}

#==============================================================================
# 模块信息和初始化
#==============================================================================

# 模块信息
get_module_info() {
    echo "软件管理模块 v1.1 - 一键安装和管理常用软件 (宝塔面板, Hysteria V2)"
}

# 模块初始化
init_software_module() {
    ensure_data_dir
    debug_log "software module: 模块初始化完成，数据目录: $SOFTWARE_DATA_DIR"
    return 0
}
