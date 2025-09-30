#!/bin/bash

# WarpKit 系统工具模块
# 这个模块提供增强的系统工具功能

# 系统工具主界面
show_system_monitor() {
    local monitor_options=(
        "实时系统状态"
        "进程管理"
        "磁盘使用情况"
        "系统负载历史"
        "软件源管理"
        "SWAP内存管理"
        "返回主菜单"
    )

    while true; do
        local result
        result=$(codex_selector "系统工具" "模块版本 - 增强功能" 0 "${monitor_options[@]}")

        case "$result" in
            "CANCELLED")
                return
                ;;
            "SELECTOR_ERROR")
                # 切换到文本菜单模式
                show_system_monitor_text_menu
                return
                ;;
            0) show_realtime_status ;;
            1) show_process_manager ;;
            2) show_disk_usage ;;
            3) show_load_history ;;
            4) show_mirror_manager ;;
            5) show_swap_manager ;;
            6) return ;;
            *)
                debug_log "system module: 未知选择 $result"
                return
                ;;
        esac
    done
}

# 系统工具文本菜单
show_system_monitor_text_menu() {
    while true; do
        clear
        echo -e "${BLUE}${BOLD}系统工具${NC}"
        echo ""
        echo "1. 实时系统状态"
        echo "2. 进程管理"
        echo "3. 磁盘使用情况"
        echo "4. 系统负载历史"
        echo "5. 软件源管理"
        echo "6. SWAP内存管理"
        echo "7. 返回主菜单"
        echo ""
        echo -n "请选择功能 (1-7): "

        read -r choice
        echo ""

        case "$choice" in
            1) show_realtime_status ;;
            2) show_process_manager ;;
            3) show_disk_usage ;;
            4) show_load_history ;;
            5) show_mirror_manager ;;
            6) show_swap_manager ;;
            7) return ;;
            *)
                echo -e "${RED}无效选择，请输入 1-7${NC}"
                sleep 2
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

# 软件源管理
show_mirror_manager() {
    # 软件源列表
    local mirror_list_default=(
        "阿里云@mirrors.aliyun.com"
        "腾讯云@mirrors.tencent.com"
        "华为云@mirrors.huaweicloud.com"
        "网易@mirrors.163.com"
        "火山引擎@mirrors.volces.com"
        "清华大学@mirrors.tuna.tsinghua.edu.cn"
        "北京大学@mirrors.pku.edu.cn"
        "浙江大学@mirrors.zju.edu.cn"
        "南京大学@mirrors.nju.edu.cn"
        "兰州大学@mirror.lzu.edu.cn"
        "上海交通大学@mirror.sjtu.edu.cn"
        "重庆邮电大学@mirrors.cqupt.edu.cn"
        "中国科学技术大学@mirrors.ustc.edu.cn"
        "中国科学院软件研究所@mirror.iscas.ac.cn"
    )

    local mirror_list_edu=(
        "北京大学@mirrors.pku.edu.cn"
        "北京交通大学@mirror.bjtu.edu.cn"
        "北京外国语大学@mirrors.bfsu.edu.cn"
        "北京邮电大学@mirrors.bupt.edu.cn"
        "重庆大学@mirrors.cqu.edu.cn"
        "重庆邮电大学@mirrors.cqupt.edu.cn"
        "大连东软信息学院@mirrors.neusoft.edu.cn"
        "电子科技大学@mirrors.uestc.cn"
        "华南农业大学@mirrors.scau.edu.cn"
        "华中科技大学@mirrors.hust.edu.cn"
        "吉林大学@mirrors.jlu.edu.cn"
        "荆楚理工学院@mirrors.jcut.edu.cn"
        "江西理工大学@mirrors.jxust.edu.cn"
        "兰州大学@mirror.lzu.edu.cn"
        "南京大学@mirrors.nju.edu.cn"
        "南京工业大学@mirrors.njtech.edu.cn"
        "南京邮电大学@mirrors.njupt.edu.cn"
        "南方科技大学@mirrors.sustech.edu.cn"
        "南阳理工学院@mirror.nyist.edu.cn"
        "齐鲁工业大学@mirrors.qlu.edu.cn"
        "清华大学@mirrors.tuna.tsinghua.edu.cn"
        "山东大学@mirrors.sdu.edu.cn"
        "上海科技大学@mirrors.shanghaitech.edu.cn"
        "上海交通大学（思源）@mirror.sjtu.edu.cn"
        "上海交通大学（致远）@mirrors.sjtug.sjtu.edu.cn"
        "武昌首义学院@mirrors.wsyu.edu.cn"
        "西安交通大学@mirrors.xjtu.edu.cn"
        "西北农林科技大学@mirrors.nwafu.edu.cn"
        "浙江大学@mirrors.zju.edu.cn"
        "中国科学技术大学@mirrors.ustc.edu.cn"
    )

    local mirror_list_abroad=(
        "亚洲 · xTom · 香港@mirrors.xtom.hk"
        "亚洲 · 01Link · 香港@mirror.01link.hk"
        "亚洲 · 新加坡国立大学(NUS) · 新加坡@download.nus.edu.sg/mirror"
        "亚洲 · SG.GS · 新加坡@mirror.sg.gs"
        "亚洲 · xTom · 新加坡@mirrors.xtom.sg"
        "亚洲 · 自由软件实验室(NCHC) · 台湾@free.nchc.org.tw"
        "亚洲 · OSS Planet · 台湾@mirror.ossplanet.net"
        "亚洲 · 国立阳明交通大学 · 台湾@linux.cs.nctu.edu.tw"
        "亚洲 · 淡江大学 · 台湾@ftp.tku.edu.tw"
        "亚洲 · AniGil Linux Archive · 韩国@mirror.anigil.com"
        "亚洲 · 工业网络安全中心(ICSCoE) · 日本@ftp.udx.icscoe.jp/Linux"
        "亚洲 · 北陆先端科学技术大学院大学(JAIST) · 日本@ftp.jaist.ac.jp/pub/Linux"
        "亚洲 · 山形大学 · 日本@linux2.yz.yamagata-u.ac.jp/pub/Linux"
        "亚洲 · xTom · 日本@mirrors.xtom.jp"
        "亚洲 · GB Network Solutions · 马来西亚@mirrors.gbnetwork.com"
        "亚洲 · 孔敬大学 · 泰国@mirror.kku.ac.th"
        "欧洲 · Vorboss Ltd · 英国@mirror.vorboss.net"
        "欧洲 · QuickHost · 英国@mirror.quickhost.uk"
        "欧洲 · dogado · 德国@mirror.dogado.de"
        "欧洲 · xTom · 德国@mirrors.xtom.de"
        "欧洲 · 亚琛工业大学(RWTH Aachen) · 德国@ftp.halifax.rwth-aachen.de"
        "欧洲 · 德累斯顿大学(AG DSN) · 德国@ftp.agdsn.de"
        "欧洲 · CCIN2P3 · 法国@mirror.in2p3.fr/pub/linux"
        "欧洲 · Ircam · 法国@mirrors.ircam.fr/pub"
        "欧洲 · Crans · 法国@eclats.crans.org"
        "欧洲 · CRIHAN · 法国@ftp.crihan.fr"
        "欧洲 · xTom · 荷兰@mirrors.xtom.nl"
        "欧洲 · DataPacket · 荷兰@mirror.datapacket.com"
        "欧洲 · Linux Kernel · 荷兰@eu.edge.kernel.org"
        "欧洲 · xTom · 爱沙尼亚@mirrors.xtom.ee"
        "欧洲 · netsite · 丹麦@mirror.netsite.dk"
        "欧洲 · Dotsrc · 丹麦@mirrors.dotsrc.org"
        "欧洲 · Academic Computer Club · 瑞典@mirror.accum.se"
        "欧洲 · Lysator · 瑞典@ftp.lysator.liu.se"
        "欧洲 · Yandex · 俄罗斯@mirror.yandex.ru"
        "欧洲 · ia64 · 俄罗斯@mirror.linux-ia64.org"
        "欧洲 · Truenetwork · 俄罗斯@mirror.truenetwork.ru"
        "欧洲 · Belgian Research Network · 比利时@ftp.belnet.be/mirror"
        "欧洲 · 克里特大学计算机中心 · 希腊@ftp.cc.uoc.gr/mirrors/linux"
        "欧洲 · 马萨里克大学信息学院 · 捷克@ftp.fi.muni.cz/pub/linux"
        "欧洲 · 捷克理工大学学生会俱乐部(Silicon Hill) · 捷克@ftp.sh.cvut.cz"
        "欧洲 · Vodafone · 捷克@mirror.karneval.cz/pub/linux"
        "欧洲 · CZ.NIC · 捷克@mirrors.nic.cz"
        "欧洲 · 苏黎世联邦理工学院 · 瑞士@mirror.ethz.ch"
        "北美 · Linux Kernel · 美国@mirrors.kernel.org"
        "北美 · 麻省理工学院(MIT) · 美国@mirrors.mit.edu"
        "北美 · 普林斯顿大学数学系 · 美国@mirror.math.princeton.edu/pub"
        "北美 · 俄勒冈州立大学开源实验室 · 美国@ftp-chi.osuosl.org/pub"
        "北美 · Fremont Cabal Internet Exchange(FCIX) · 美国@mirror.fcix.net"
        "北美 · xTom · 美国@mirrors.xtom.com"
        "北美 · Steadfast · 美国@mirror.steadfast.net"
        "北美 · 不列颠哥伦比亚大学 · 加拿大@mirror.it.ubc.ca"
        "北美 · GoCodeIT · 加拿大@mirror.xenyth.net"
        "北美 · Switch · 加拿大@mirrors.switch.ca"
        "南美 · PoP-SC · 巴西@mirror.pop-sc.rnp.br/mirror"
        "南美 · 蓬塔格罗萨州立大学 · 巴西@mirror.uepg.br"
        "南美 · UFSCar · 巴西@mirror.ufscar.br"
        "南美 · Sysarmy Community · 阿根廷@mirrors.eze.sysarmy.com"
        "大洋 · Fremont Cabal Internet Exchange(FCIX) · 澳大利亚@gsl-syd.mm.fcix.net"
        "大洋 · AARNet · 澳大利亚@mirror.aarnet.edu.au/pub"
        "大洋 · DataMossa · 澳大利亚@mirror.datamossa.io"
        "大洋 · Amaze · 澳大利亚@mirror.amaze.com.au"
        "大洋 · xTom · 澳大利亚@mirrors.xtom.au"
        "大洋 · Over the Wire · 澳大利亚@mirror.overthewire.com.au"
        "大洋 · Free Software Mirror Group · 新西兰@mirror.fsmg.org.nz"
        "非洲 · Liquid Telecom · 肯尼亚@mirror.liquidtelecom.com"
        "非洲 · Dimension Data · 南非@mirror.dimensiondata.com"
    )

    # 软件源公网地址列表
    local mirror_list_extranet=(
        "mirrors.aliyun.com"
        "mirrors.tencent.com"
        "mirrors.huaweicloud.com"
        "mirrors.volces.com"
    )

    # 软件源内网地址列表
    local mirror_list_intranet=(
        "mirrors.cloud.aliyuncs.com"
        "mirrors.tencentyun.com"
        "mirrors.myhuaweicloud.com"
        "mirrors.ivolces.com"
    )

    local region_options=(
        "国内镜像源"
        "教育网镜像源"
        "海外镜像源"
        "返回"
    )

    while true; do
        local result
        result=$(codex_selector "软件源管理" "选择镜像源区域" 0 "${region_options[@]}")

        case "$result" in
            "CANCELLED"|"SELECTOR_ERROR")
                return
                ;;
            0) select_and_change_mirror "国内" "${mirror_list_default[@]}" ;;
            1) select_and_change_mirror "教育网" "${mirror_list_edu[@]}" ;;
            2) select_and_change_mirror "海外" "${mirror_list_abroad[@]}" ;;
            3) return ;;
            *)
                debug_log "mirror manager: 未知选择 $result"
                return
                ;;
        esac
    done
}

# 选择并更换镜像源
select_and_change_mirror() {
    local region_name="$1"
    shift
    local mirror_list=("$@")

    # 准备镜像源选项（仅显示名称）
    local mirror_names=()
    for item in "${mirror_list[@]}"; do
        mirror_names+=("${item%%@*}")
    done
    mirror_names+=("返回")

    local result
    result=$(codex_selector "选择${region_name}镜像源" "请选择要使用的软件源" 0 "${mirror_names[@]}")

    if [[ "$result" == "CANCELLED" || "$result" == "SELECTOR_ERROR" || "$result" -eq $((${#mirror_names[@]} - 1)) ]]; then
        return
    fi

    # 获取选中的镜像源地址
    local selected_item="${mirror_list[$result]}"
    local mirror_url="${selected_item#*@}"

    # 检查是否需要切换为内网地址
    local use_intranet=false
    for i in "${!mirror_list_extranet[@]}"; do
        if [[ "${mirror_list_extranet[$i]}" == "$mirror_url" ]]; then
            clear
            echo -e "${YELLOW}检测到该镜像源支持内网访问${NC}"
            echo -e "${CYAN}公网地址: ${mirror_url}${NC}"
            echo -e "${CYAN}内网地址: ${mirror_list_intranet[$i]}${NC}"
            echo ""
            echo -n "是否使用内网地址？[y/N] "
            read -r use_intranet_choice
            if [[ "$use_intranet_choice" =~ ^[Yy]$ ]]; then
                mirror_url="${mirror_list_intranet[$i]}"
                use_intranet=true
            fi
            break
        fi
    done

    # 执行镜像源更换
    change_system_mirror "$mirror_url"
}

# 更换系统镜像源
change_system_mirror() {
    local mirror_url="$1"

    clear
    echo -e "${BLUE}${BOLD}更换系统软件源${NC}"
    echo ""
    echo -e "${CYAN}目标镜像源: ${mirror_url}${NC}"
    echo ""

    # 检测系统类型
    local os_type=""
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        os_type="$ID"
    elif [[ -f /etc/redhat-release ]]; then
        os_type="centos"
    elif [[ -f /etc/debian_version ]]; then
        os_type="debian"
    else
        echo -e "${RED}无法检测系统类型${NC}"
        echo ""
        echo -e "${YELLOW}按任意键返回${NC}"
        read -n1
        return
    fi

    echo -e "${GREEN}检测到系统类型: ${os_type}${NC}"
    echo ""

    # 备份原有配置
    local backup_file=""
    case "$os_type" in
        ubuntu|debian)
            backup_file="/etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)"
            echo -e "${CYAN}备份原有配置到: ${backup_file}${NC}"
            sudo cp /etc/apt/sources.list "$backup_file" 2>/dev/null || {
                echo -e "${RED}备份失败，需要sudo权限${NC}"
                echo ""
                echo -e "${YELLOW}按任意键返回${NC}"
                read -n1
                return
            }

            # 生成新的sources.list
            echo -e "${CYAN}正在生成新的软件源配置...${NC}"

            local version_codename="${VERSION_CODENAME:-$(lsb_release -cs 2>/dev/null)}"
            [[ -z "$version_codename" ]] && version_codename="focal"

            sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb http://${mirror_url}/ubuntu/ ${version_codename} main restricted universe multiverse
deb http://${mirror_url}/ubuntu/ ${version_codename}-updates main restricted universe multiverse
deb http://${mirror_url}/ubuntu/ ${version_codename}-backports main restricted universe multiverse
deb http://${mirror_url}/ubuntu/ ${version_codename}-security main restricted universe multiverse
EOF

            echo -e "${GREEN}软件源配置已更新${NC}"
            echo ""
            echo -e "${CYAN}正在更新软件包列表...${NC}"
            sudo apt update
            ;;

        centos|rhel|fedora|rocky|almalinux)
            backup_file="/etc/yum.repos.d/backup_$(date +%Y%m%d_%H%M%S)"
            echo -e "${CYAN}备份原有配置到: ${backup_file}${NC}"
            sudo mkdir -p "$backup_file"
            sudo cp /etc/yum.repos.d/*.repo "$backup_file/" 2>/dev/null || {
                echo -e "${RED}备份失败，需要sudo权限${NC}"
                echo ""
                echo -e "${YELLOW}按任意键返回${NC}"
                read -n1
                return
            }

            echo -e "${CYAN}正在生成新的软件源配置...${NC}"

            # 根据不同的发行版生成配置
            if [[ "$os_type" == "centos" ]]; then
                local version="${VERSION_ID:-7}"
                sudo sed -e "s|^mirrorlist=|#mirrorlist=|g" \
                         -e "s|^#baseurl=http://mirror.centos.org|baseurl=http://${mirror_url}|g" \
                         -i.bak \
                         /etc/yum.repos.d/CentOS-*.repo
            elif [[ "$os_type" == "fedora" ]]; then
                sudo sed -e "s|^metalink=|#metalink=|g" \
                         -e "s|^#baseurl=http://download.example/pub/fedora/linux|baseurl=http://${mirror_url}/fedora|g" \
                         -i.bak \
                         /etc/yum.repos.d/fedora*.repo
            fi

            echo -e "${GREEN}软件源配置已更新${NC}"
            echo ""
            echo -e "${CYAN}正在清理并更新缓存...${NC}"
            sudo yum clean all
            sudo yum makecache
            ;;

        arch|manjaro)
            backup_file="/etc/pacman.d/mirrorlist.backup.$(date +%Y%m%d_%H%M%S)"
            echo -e "${CYAN}备份原有配置到: ${backup_file}${NC}"
            sudo cp /etc/pacman.d/mirrorlist "$backup_file" 2>/dev/null || {
                echo -e "${RED}备份失败，需要sudo权限${NC}"
                echo ""
                echo -e "${YELLOW}按任意键返回${NC}"
                read -n1
                return
            }

            echo -e "${CYAN}正在生成新的软件源配置...${NC}"
            echo "Server = http://${mirror_url}/archlinux/\$repo/os/\$arch" | sudo tee /etc/pacman.d/mirrorlist > /dev/null

            echo -e "${GREEN}软件源配置已更新${NC}"
            echo ""
            echo -e "${CYAN}正在更新软件包数据库...${NC}"
            sudo pacman -Sy
            ;;

        *)
            echo -e "${YELLOW}暂不支持该系统类型的自动配置${NC}"
            echo -e "${CYAN}镜像源地址: ${mirror_url}${NC}"
            echo -e "${CYAN}请手动配置系统软件源${NC}"
            ;;
    esac

    echo ""
    echo -e "${GREEN}操作完成！${NC}"
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

# SWAP内存管理
show_swap_manager() {
    local swap_options=(
        "设置SWAP"
        "释放SWAP"
        "查看SWAP状态"
        "返回"
    )

    while true; do
        local result
        result=$(codex_selector "SWAP内存管理" "管理系统交换空间" 0 "${swap_options[@]}")

        case "$result" in
            "CANCELLED"|"SELECTOR_ERROR")
                return
                ;;
            0) setup_swap ;;
            1) remove_swap ;;
            2) show_swap_status ;;
            3) return ;;
            *)
                debug_log "swap manager: 未知选择 $result"
                return
                ;;
        esac
    done
}

# 查看SWAP状态
show_swap_status() {
    clear
    echo -e "${BLUE}${BOLD}SWAP状态${NC}"
    echo ""

    if command -v swapon >/dev/null 2>&1; then
        echo -e "${GREEN}当前SWAP信息:${NC}"
        swapon --show 2>/dev/null || echo "未找到活动的SWAP"
        echo ""
    fi

    if command -v free >/dev/null 2>&1; then
        echo -e "${GREEN}内存和SWAP使用情况:${NC}"
        free -h
        echo ""
    fi

    # 检查SWAP文件
    if [[ -f /swapfile ]]; then
        echo -e "${GREEN}SWAP文件信息:${NC}"
        ls -lh /swapfile
        echo ""
    fi

    # 显示可用磁盘空间
    echo -e "${GREEN}根分区可用空间:${NC}"
    df -h / | tail -1
    echo ""

    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 设置SWAP
setup_swap() {
    clear
    echo -e "${BLUE}${BOLD}设置SWAP内存${NC}"
    echo ""

    # 检查是否已存在SWAP
    local existing_swap=$(swapon --show 2>/dev/null | grep -v "^NAME" | wc -l)
    if [[ $existing_swap -gt 0 ]]; then
        echo -e "${YELLOW}检测到系统已存在SWAP:${NC}"
        swapon --show
        echo ""
        echo -n "是否继续创建新的SWAP? [y/N] "
        read -r continue_choice
        if [[ ! "$continue_choice" =~ ^[Yy]$ ]]; then
            return
        fi
        echo ""
    fi

    # 显示当前可用空间
    echo -e "${GREEN}当前根分区可用空间:${NC}"
    local available_space_line=$(df -BG / | tail -1)
    echo "$available_space_line"
    local available_gb=$(echo "$available_space_line" | awk '{print $4}' | sed 's/G//')
    echo ""
    echo -e "${CYAN}可用空间: ${available_gb}GB${NC}"
    echo ""

    # 输入SWAP大小
    while true; do
        echo -n "请输入要创建的SWAP大小(GB，整数): "
        read -r swap_size

        # 验证输入是否为整数
        if ! [[ "$swap_size" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}错误: 请输入有效的整数${NC}"
            echo ""
            continue
        fi

        # 验证是否超出可用空间（预留1GB安全空间）
        if [[ $swap_size -ge $available_gb ]]; then
            echo -e "${RED}错误: 设置的SWAP大小(${swap_size}GB)超出可用空间(${available_gb}GB)${NC}"
            echo -e "${YELLOW}建议设置为 $((available_gb - 1))GB 或更小${NC}"
            echo ""
            continue
        fi

        if [[ $swap_size -le 0 ]]; then
            echo -e "${RED}错误: SWAP大小必须大于0${NC}"
            echo ""
            continue
        fi

        break
    done

    echo ""
    echo -e "${CYAN}将创建 ${swap_size}GB 的SWAP文件${NC}"
    echo -n "确认创建? [y/N] "
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}已取消${NC}"
        echo ""
        echo -e "${YELLOW}按任意键返回${NC}"
        read -n1
        return
    fi

    echo ""
    echo -e "${CYAN}正在创建SWAP，请稍候...${NC}"
    echo ""

    # 创建SWAP文件
    local swap_file="/swapfile_${swap_size}g"

    # 如果已存在同名文件，使用时间戳
    if [[ -f "$swap_file" ]]; then
        swap_file="/swapfile_${swap_size}g_$(date +%s)"
    fi

    echo -e "${CYAN}1. 分配磁盘空间...${NC}"
    if ! sudo fallocate -l ${swap_size}G "$swap_file" 2>/dev/null; then
        echo -e "${YELLOW}fallocate失败，尝试使用dd命令...${NC}"
        if ! sudo dd if=/dev/zero of="$swap_file" bs=1G count=$swap_size status=progress 2>/dev/null; then
            echo -e "${RED}创建SWAP文件失败${NC}"
            echo ""
            echo -e "${YELLOW}按任意键返回${NC}"
            read -n1
            return
        fi
    fi

    echo -e "${CYAN}2. 设置文件权限...${NC}"
    sudo chmod 600 "$swap_file"

    echo -e "${CYAN}3. 格式化为SWAP...${NC}"
    if ! sudo mkswap "$swap_file" >/dev/null 2>&1; then
        echo -e "${RED}格式化SWAP失败${NC}"
        sudo rm -f "$swap_file"
        echo ""
        echo -e "${YELLOW}按任意键返回${NC}"
        read -n1
        return
    fi

    echo -e "${CYAN}4. 启用SWAP...${NC}"
    if ! sudo swapon "$swap_file" 2>/dev/null; then
        echo -e "${RED}启用SWAP失败${NC}"
        sudo rm -f "$swap_file"
        echo ""
        echo -e "${YELLOW}按任意键返回${NC}"
        read -n1
        return
    fi

    echo ""
    echo -e "${GREEN}SWAP创建成功！${NC}"
    echo ""
    echo -e "${GREEN}当前SWAP状态:${NC}"
    swapon --show
    echo ""
    free -h | grep -E "^(Mem|Swap)"
    echo ""

    echo -e "${CYAN}是否设置开机自动挂载? [y/N]${NC}"
    echo -n "> "
    read -r auto_mount
    if [[ "$auto_mount" =~ ^[Yy]$ ]]; then
        # 检查是否已存在该条目
        if ! grep -q "$swap_file" /etc/fstab 2>/dev/null; then
            echo "$swap_file none swap sw 0 0" | sudo tee -a /etc/fstab >/dev/null
            echo -e "${GREEN}已添加到 /etc/fstab${NC}"
        else
            echo -e "${YELLOW}该SWAP已在 /etc/fstab 中${NC}"
        fi
    fi

    echo ""
    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 释放SWAP
remove_swap() {
    clear
    echo -e "${BLUE}${BOLD}释放SWAP内存${NC}"
    echo ""

    # 检查是否存在SWAP
    local swap_list=$(swapon --show 2>/dev/null | grep -v "^NAME")
    if [[ -z "$swap_list" ]]; then
        echo -e "${YELLOW}未检测到活动的SWAP${NC}"
        echo ""
        echo -e "${YELLOW}按任意键返回${NC}"
        read -n1
        return
    fi

    echo -e "${GREEN}当前活动的SWAP:${NC}"
    swapon --show
    echo ""

    # 获取SWAP文件列表
    local swap_files=($(swapon --show 2>/dev/null | grep -v "^NAME" | awk '{print $1}'))

    if [[ ${#swap_files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}未找到可释放的SWAP文件${NC}"
        echo ""
        echo -e "${YELLOW}按任意键返回${NC}"
        read -n1
        return
    fi

    # 准备选择列表
    local swap_options=()
    for swap_file in "${swap_files[@]}"; do
        local size=$(swapon --show 2>/dev/null | grep "$swap_file" | awk '{print $3}')
        swap_options+=("${swap_file} (${size})")
    done
    swap_options+=("释放所有SWAP")
    swap_options+=("返回")

    local result
    result=$(codex_selector "选择要释放的SWAP" "请选择" 0 "${swap_options[@]}")

    if [[ "$result" == "CANCELLED" || "$result" == "SELECTOR_ERROR" ]]; then
        return
    fi

    if [[ "$result" -eq $((${#swap_options[@]} - 1)) ]]; then
        return
    fi

    clear
    echo -e "${BLUE}${BOLD}释放SWAP${NC}"
    echo ""

    if [[ "$result" -eq $((${#swap_options[@]} - 2)) ]]; then
        # 释放所有SWAP
        echo -e "${YELLOW}将释放所有SWAP，确认? [y/N]${NC}"
        echo -n "> "
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            return
        fi

        echo ""
        for swap_file in "${swap_files[@]}"; do
            echo -e "${CYAN}正在释放: ${swap_file}${NC}"
            sudo swapoff "$swap_file" 2>/dev/null

            # 询问是否删除文件
            if [[ -f "$swap_file" ]]; then
                echo -n "是否删除文件 ${swap_file}? [y/N] "
                read -r del_choice
                if [[ "$del_choice" =~ ^[Yy]$ ]]; then
                    sudo rm -f "$swap_file"
                    # 从fstab中移除
                    sudo sed -i "\|$swap_file|d" /etc/fstab 2>/dev/null
                    echo -e "${GREEN}已删除${NC}"
                fi
            fi
            echo ""
        done
        echo -e "${GREEN}所有SWAP已释放${NC}"
    else
        # 释放选中的SWAP
        local selected_swap="${swap_files[$result]}"
        echo -e "${CYAN}选择释放: ${selected_swap}${NC}"
        echo -n "确认释放? [y/N] "
        read -r confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            return
        fi

        echo ""
        echo -e "${CYAN}正在释放SWAP...${NC}"
        if sudo swapoff "$selected_swap" 2>/dev/null; then
            echo -e "${GREEN}SWAP已释放${NC}"

            # 询问是否删除文件
            if [[ -f "$selected_swap" ]]; then
                echo ""
                echo -n "是否删除文件 ${selected_swap}? [y/N] "
                read -r del_choice
                if [[ "$del_choice" =~ ^[Yy]$ ]]; then
                    sudo rm -f "$selected_swap"
                    # 从fstab中移除
                    sudo sed -i "\|$selected_swap|d" /etc/fstab 2>/dev/null
                    echo -e "${GREEN}文件已删除${NC}"
                fi
            fi
        else
            echo -e "${RED}释放SWAP失败${NC}"
        fi
    fi

    echo ""
    echo -e "${GREEN}当前SWAP状态:${NC}"
    swapon --show 2>/dev/null || echo "无活动SWAP"
    echo ""

    echo -e "${YELLOW}按任意键返回${NC}"
    read -n1
}

# 模块信息
get_module_info() {
    echo "系统工具模块 v1.0 - 提供增强的系统工具功能"
}

# 模块初始化（如果需要）
init_system_module() {
    debug_log "system module: 模块初始化完成"
    return 0
}

# 导出主要函数供外部调用
# show_system_monitor 函数已定义，可以被模块加载器调用