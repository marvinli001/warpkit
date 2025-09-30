#!/bin/bash

# WarpKit - Docker 管理模块
# 命令行版本的 Docker 可视化管理器

# ============================================================================
# 环境检测函数
# ============================================================================

# 检查 Docker 是否已安装
check_docker_installed() {
    if command -v docker >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 检查 Docker 服务是否运行
check_docker_running() {
    if docker info >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# 获取 Docker 版本
get_docker_version() {
    docker --version 2>/dev/null | awk '{print $3}' | tr -d ','
}

# 获取 Docker 状态信息
get_docker_status() {
    if ! check_docker_installed; then
        echo "未安装"
        return 1
    fi

    if check_docker_running; then
        echo "运行中"
        return 0
    else
        echo "未运行"
        return 2
    fi
}

# ============================================================================
# 容器管理函数
# ============================================================================

# 列出容器
list_containers() {
    local filter="$1"  # all, running, stopped

    case "$filter" in
        "running")
            docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
            ;;
        "stopped")
            docker ps -f "status=exited" --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}"
            ;;
        *)
            docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
            ;;
    esac
}

# 获取容器数量统计
get_container_stats() {
    local total=$(docker ps -aq | wc -l)
    local running=$(docker ps -q | wc -l)
    local stopped=$((total - running))

    echo "$running/$total 运行中"
}

# 启动容器
start_container() {
    local container_id="$1"
    docker start "$container_id"
}

# 停止容器
stop_container() {
    local container_id="$1"
    docker stop "$container_id"
}

# 重启容器
restart_container() {
    local container_id="$1"
    docker restart "$container_id"
}

# 删除容器
delete_container() {
    local container_id="$1"
    local force="$2"

    if [[ "$force" == "true" ]]; then
        docker rm -f "$container_id"
    else
        docker rm "$container_id"
    fi
}

# 查看容器日志
view_container_logs() {
    local container_id="$1"
    local lines="${2:-100}"
    docker logs --tail "$lines" "$container_id"
}

# 查看容器详细信息
view_container_inspect() {
    local container_id="$1"
    docker inspect "$container_id"
}

# 进入容器终端
exec_container_shell() {
    local container_id="$1"
    local shell="${2:-/bin/bash}"

    # 尝试 bash，如果失败则尝试 sh
    if ! docker exec -it "$container_id" "$shell" 2>/dev/null; then
        docker exec -it "$container_id" /bin/sh
    fi
}

# ============================================================================
# 容器创建函数
# ============================================================================

# 交互式创建容器
create_container_interactive() {
    clear
    echo -e "${CYAN}${BOLD}创建新容器向导${NC}"
    echo ""
    echo -e "${YELLOW}请按照提示输入容器配置信息${NC}"
    echo ""

    # 1. 容器名称
    echo -e "${BOLD}步骤 1/7: 容器名称${NC}"
    echo -n "请输入容器名称 (留空自动生成): "
    read -r container_name

    # 2. 镜像选择
    echo ""
    echo -e "${BOLD}步骤 2/7: 选择镜像${NC}"
    echo "1. 从本地镜像选择"
    echo "2. 从 Docker Hub 拉取新镜像"
    echo -n "请选择 [1]: "
    read -r image_choice
    image_choice=${image_choice:-1}

    local image_name=""
    if [[ "$image_choice" == "1" ]]; then
        echo ""
        echo -e "${YELLOW}本地镜像列表:${NC}"
        list_images
        echo ""
        echo -n "请输入镜像名称 (格式: repository:tag): "
        read -r image_name
    else
        echo -n "请输入要拉取的镜像名称 (如 nginx:latest): "
        read -r image_name
        if [[ -n "$image_name" ]]; then
            echo -e "${YELLOW}正在拉取镜像 $image_name...${NC}"
            if ! pull_image "$image_name"; then
                echo -e "${RED}镜像拉取失败${NC}"
                sleep 2
                return 1
            fi
        fi
    fi

    if [[ -z "$image_name" ]]; then
        echo -e "${RED}镜像名称不能为空${NC}"
        sleep 2
        return 1
    fi

    # 3. 端口映射
    echo ""
    echo -e "${BOLD}步骤 3/7: 端口映射${NC}"
    echo "格式: 主机端口:容器端口 (如 8080:80)"
    echo "可以添加多个端口，输入空行完成"
    local ports=()
    local port_index=1
    while true; do
        echo -n "端口映射 $port_index (留空跳过): "
        read -r port_mapping
        if [[ -z "$port_mapping" ]]; then
            break
        fi
        ports+=("$port_mapping")
        ((port_index++))
    done

    # 4. 环境变量
    echo ""
    echo -e "${BOLD}步骤 4/7: 环境变量${NC}"
    echo "格式: KEY=VALUE (如 DB_HOST=localhost)"
    echo "可以添加多个变量，输入空行完成"
    local env_vars=()
    local env_index=1
    while true; do
        echo -n "环境变量 $env_index (留空跳过): "
        read -r env_var
        if [[ -z "$env_var" ]]; then
            break
        fi
        env_vars+=("$env_var")
        ((env_index++))
    done

    # 5. 卷挂载
    echo ""
    echo -e "${BOLD}步骤 5/7: 卷挂载${NC}"
    echo "格式: 主机路径:容器路径 (如 /data:/app/data)"
    echo "可以添加多个挂载，输入空行完成"
    local volumes=()
    local vol_index=1
    while true; do
        echo -n "卷挂载 $vol_index (留空跳过): "
        read -r volume
        if [[ -z "$volume" ]]; then
            break
        fi
        volumes+=("$volume")
        ((vol_index++))
    done

    # 6. 网络模式
    echo ""
    echo -e "${BOLD}步骤 6/7: 网络模式${NC}"
    echo "1. bridge (默认)"
    echo "2. host"
    echo "3. none"
    echo "4. 自定义网络"
    echo -n "请选择 [1]: "
    read -r network_choice
    network_choice=${network_choice:-1}

    local network="bridge"
    case "$network_choice" in
        1) network="bridge" ;;
        2) network="host" ;;
        3) network="none" ;;
        4)
            echo -n "请输入自定义网络名称: "
            read -r network
            ;;
    esac

    # 7. 重启策略
    echo ""
    echo -e "${BOLD}步骤 7/7: 重启策略${NC}"
    echo "1. no (不自动重启)"
    echo "2. always (总是重启)"
    echo "3. on-failure (失败时重启)"
    echo "4. unless-stopped (除非手动停止)"
    echo -n "请选择 [1]: "
    read -r restart_choice
    restart_choice=${restart_choice:-1}

    local restart_policy="no"
    case "$restart_choice" in
        1) restart_policy="no" ;;
        2) restart_policy="always" ;;
        3) restart_policy="on-failure" ;;
        4) restart_policy="unless-stopped" ;;
    esac

    # 显示配置摘要
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}配置摘要:${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    [[ -n "$container_name" ]] && echo "容器名称: $container_name"
    echo "镜像: $image_name"
    [[ ${#ports[@]} -gt 0 ]] && echo "端口映射: ${ports[*]}"
    [[ ${#env_vars[@]} -gt 0 ]] && echo "环境变量: ${env_vars[*]}"
    [[ ${#volumes[@]} -gt 0 ]] && echo "卷挂载: ${volumes[*]}"
    echo "网络模式: $network"
    echo "重启策略: $restart_policy"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    echo -n "确认创建容器? [Y/n]: "
    read -r confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo -e "${YELLOW}已取消${NC}"
        sleep 1
        return 1
    fi

    # 构建 docker run 命令
    local docker_cmd="docker run -d"

    [[ -n "$container_name" ]] && docker_cmd+=" --name $container_name"

    for port in "${ports[@]}"; do
        docker_cmd+=" -p $port"
    done

    for env in "${env_vars[@]}"; do
        docker_cmd+=" -e $env"
    done

    for vol in "${volumes[@]}"; do
        docker_cmd+=" -v $vol"
    done

    docker_cmd+=" --network $network"
    docker_cmd+=" --restart $restart_policy"
    docker_cmd+=" $image_name"

    echo ""
    echo -e "${YELLOW}正在创建容器...${NC}"
    echo -e "${CYAN}命令: $docker_cmd${NC}"
    echo ""

    if eval "$docker_cmd"; then
        echo ""
        echo -e "${GREEN}✓ 容器创建成功！${NC}"
        sleep 2
        return 0
    else
        echo ""
        echo -e "${RED}✗ 容器创建失败${NC}"
        sleep 2
        return 1
    fi
}

# ============================================================================
# 镜像管理函数
# ============================================================================

# 列出镜像
list_images() {
    docker images --format "table {{.ID}}\t{{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedSince}}"
}

# 拉取镜像
pull_image() {
    local image_name="$1"
    docker pull "$image_name"
}

# 删除镜像
delete_image() {
    local image_id="$1"
    local force="$2"

    if [[ "$force" == "true" ]]; then
        docker rmi -f "$image_id"
    else
        docker rmi "$image_id"
    fi
}

# 搜索 Docker Hub 镜像
search_dockerhub() {
    local keyword="$1"
    docker search "$keyword" --limit 20
}

# ============================================================================
# 网络管理函数
# ============================================================================

# 列出网络
list_networks() {
    docker network ls --format "table {{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}"
}

# 创建网络
create_network() {
    local network_name="$1"
    local driver="${2:-bridge}"
    docker network create --driver "$driver" "$network_name"
}

# 删除网络
delete_network() {
    local network_id="$1"
    docker network rm "$network_id"
}

# ============================================================================
# 卷管理函数
# ============================================================================

# 列出卷
list_volumes() {
    docker volume ls --format "table {{.Name}}\t{{.Driver}}\t{{.Mountpoint}}"
}

# 创建卷
create_volume() {
    local volume_name="$1"
    docker volume create "$volume_name"
}

# 删除卷
delete_volume() {
    local volume_name="$1"
    docker volume rm "$volume_name"
}

# ============================================================================
# 主菜单函数
# ============================================================================

# 显示 Docker 管理器主菜单
show_docker_manager() {
    while true; do
        clear
        print_logo
        show_system_info

        echo -e "${CYAN}${BOLD}Docker 管理器${NC}"
        echo ""

        # 显示 Docker 状态
        local docker_status=$(get_docker_status)
        local status_color=""

        case "$docker_status" in
            "运行中")
                status_color="${GREEN}"
                ;;
            "未运行")
                status_color="${YELLOW}"
                ;;
            "未安装")
                status_color="${RED}"
                ;;
        esac

        echo -e "${BOLD}Docker 状态:${NC} ${status_color}${docker_status}${NC}"

        if [[ "$docker_status" == "运行中" ]]; then
            local version=$(get_docker_version)
            local container_stats=$(get_container_stats)
            echo -e "${BOLD}Docker 版本:${NC} ${version}"
            echo -e "${BOLD}容器状态:${NC} ${container_stats}"
        fi

        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        if [[ "$docker_status" == "未安装" ]]; then
            echo "1. 安装 Docker"
            echo "0. 返回主菜单"
        elif [[ "$docker_status" == "未运行" ]]; then
            echo "1. 启动 Docker 服务"
            echo "2. 卸载 Docker"
            echo "0. 返回主菜单"
        else
            echo "1. 容器管理"
            echo "2. 镜像管理"
            echo "3. 网络管理"
            echo "4. 卷管理"
            echo "5. 系统信息"
            echo "6. Docker 设置"
            echo "0. 返回主菜单"
        fi

        echo ""
        echo -n "请选择: "
        read -r choice

        case "$choice" in
            1)
                if [[ "$docker_status" == "未安装" ]]; then
                    install_docker
                elif [[ "$docker_status" == "未运行" ]]; then
                    start_docker_service
                else
                    show_container_management
                fi
                ;;
            2)
                if [[ "$docker_status" == "未运行" ]]; then
                    uninstall_docker
                else
                    show_image_management
                fi
                ;;
            3)
                [[ "$docker_status" == "运行中" ]] && show_network_management
                ;;
            4)
                [[ "$docker_status" == "运行中" ]] && show_volume_management
                ;;
            5)
                [[ "$docker_status" == "运行中" ]] && show_docker_system_info
                ;;
            6)
                [[ "$docker_status" == "运行中" ]] && show_docker_settings
                ;;
            0)
                return
                ;;
        esac
    done
}

# 容器管理菜单
show_container_management() {
    while true; do
        clear
        print_logo
        show_system_info

        echo -e "${CYAN}${BOLD}容器管理${NC}"
        echo ""

        # 显示容器统计
        local container_stats=$(get_container_stats)
        echo -e "${BOLD}容器状态:${NC} ${container_stats}"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        echo "1. 查看所有容器"
        echo "2. 查看运行中的容器"
        echo "3. 查看已停止的容器"
        echo "4. 管理容器（启动/停止/重启/删除）"
        echo "5. 查看容器详情"
        echo "6. 查看容器日志"
        echo "7. 进入容器终端"
        echo "8. 创建新容器"
        echo "0. 返回上级菜单"
        echo ""
        echo -n "请选择: "
        read -r choice

        case "$choice" in
            1)
                show_containers_list "all"
                ;;
            2)
                show_containers_list "running"
                ;;
            3)
                show_containers_list "stopped"
                ;;
            4)
                manage_container_operations
                ;;
            5)
                view_container_details_menu
                ;;
            6)
                view_container_logs_menu
                ;;
            7)
                enter_container_shell_menu
                ;;
            8)
                create_container_interactive
                ;;
            0)
                return
                ;;
        esac
    done
}

# 显示容器列表
show_containers_list() {
    local filter="$1"
    local title=""

    case "$filter" in
        "running")
            title="运行中的容器"
            ;;
        "stopped")
            title="已停止的容器"
            ;;
        *)
            title="所有容器"
            ;;
    esac

    clear
    echo -e "${CYAN}${BOLD}$title${NC}"
    echo ""

    if ! list_containers "$filter" 2>/dev/null; then
        echo -e "${YELLOW}无法获取容器列表${NC}"
    fi

    echo ""
    read -p "按 Enter 继续..."
}

# 管理容器操作
manage_container_operations() {
    clear
    echo -e "${CYAN}${BOLD}容器操作管理${NC}"
    echo ""

    # 显示所有容器
    echo -e "${YELLOW}当前容器列表:${NC}"
    list_containers "all" 2>/dev/null || echo "无容器"
    echo ""

    echo -n "请输入容器ID或名称 (输入 0 返回): "
    read -r container_id

    if [[ "$container_id" == "0" ]]; then
        return
    fi

    if [[ -z "$container_id" ]]; then
        echo -e "${RED}容器ID不能为空${NC}"
        sleep 2
        return
    fi

    # 检查容器是否存在
    if ! docker ps -a --format "{{.ID}} {{.Names}}" | grep -q "$container_id"; then
        echo -e "${RED}容器不存在: $container_id${NC}"
        sleep 2
        return
    fi

    # 获取容器状态
    local container_status=$(docker ps -a --filter "id=$container_id" --format "{{.Status}}" 2>/dev/null | head -1)
    local is_running=false
    if echo "$container_status" | grep -qi "up"; then
        is_running=true
    fi

    while true; do
        clear
        echo -e "${CYAN}${BOLD}容器操作: $container_id${NC}"
        echo ""
        echo -e "${BOLD}状态:${NC} $container_status"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        if [[ "$is_running" == "true" ]]; then
            echo "1. 停止容器"
            echo "2. 重启容器"
            echo "3. 强制删除容器"
        else
            echo "1. 启动容器"
            echo "2. 删除容器"
        fi
        echo "0. 返回"
        echo ""
        echo -n "请选择操作: "
        read -r operation

        case "$operation" in
            1)
                if [[ "$is_running" == "true" ]]; then
                    echo -e "${YELLOW}正在停止容器...${NC}"
                    if stop_container "$container_id"; then
                        echo -e "${GREEN}✓ 容器已停止${NC}"
                        sleep 2
                        return
                    else
                        echo -e "${RED}✗ 停止失败${NC}"
                        sleep 2
                    fi
                else
                    echo -e "${YELLOW}正在启动容器...${NC}"
                    if start_container "$container_id"; then
                        echo -e "${GREEN}✓ 容器已启动${NC}"
                        sleep 2
                        return
                    else
                        echo -e "${RED}✗ 启动失败${NC}"
                        sleep 2
                    fi
                fi
                ;;
            2)
                if [[ "$is_running" == "true" ]]; then
                    echo -e "${YELLOW}正在重启容器...${NC}"
                    if restart_container "$container_id"; then
                        echo -e "${GREEN}✓ 容器已重启${NC}"
                        sleep 2
                        return
                    else
                        echo -e "${RED}✗ 重启失败${NC}"
                        sleep 2
                    fi
                else
                    echo -e "${RED}确认删除容器 $container_id? [y/N]${NC} "
                    read -r confirm
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        echo -e "${YELLOW}正在删除容器...${NC}"
                        if delete_container "$container_id" "false"; then
                            echo -e "${GREEN}✓ 容器已删除${NC}"
                            sleep 2
                            return
                        else
                            echo -e "${RED}✗ 删除失败${NC}"
                            sleep 2
                        fi
                    fi
                fi
                ;;
            3)
                if [[ "$is_running" == "true" ]]; then
                    echo -e "${RED}确认强制删除运行中的容器 $container_id? [y/N]${NC} "
                    read -r confirm
                    if [[ "$confirm" =~ ^[Yy]$ ]]; then
                        echo -e "${YELLOW}正在强制删除容器...${NC}"
                        if delete_container "$container_id" "true"; then
                            echo -e "${GREEN}✓ 容器已删除${NC}"
                            sleep 2
                            return
                        else
                            echo -e "${RED}✗ 删除失败${NC}"
                            sleep 2
                        fi
                    fi
                fi
                ;;
            0)
                return
                ;;
        esac
    done
}

# 查看容器详情菜单
view_container_details_menu() {
    clear
    echo -e "${CYAN}${BOLD}查看容器详情${NC}"
    echo ""

    list_containers "all" 2>/dev/null || echo "无容器"
    echo ""

    echo -n "请输入容器ID或名称 (输入 0 返回): "
    read -r container_id

    if [[ "$container_id" == "0" ]] || [[ -z "$container_id" ]]; then
        return
    fi

    clear
    echo -e "${CYAN}${BOLD}容器详细信息: $container_id${NC}"
    echo ""
    view_container_inspect "$container_id" 2>/dev/null | less

    read -p "按 Enter 继续..."
}

# 查看容器日志菜单
view_container_logs_menu() {
    clear
    echo -e "${CYAN}${BOLD}查看容器日志${NC}"
    echo ""

    list_containers "all" 2>/dev/null || echo "无容器"
    echo ""

    echo -n "请输入容器ID或名称 (输入 0 返回): "
    read -r container_id

    if [[ "$container_id" == "0" ]] || [[ -z "$container_id" ]]; then
        return
    fi

    echo -n "显示最后多少行日志? [100]: "
    read -r lines
    lines=${lines:-100}

    clear
    echo -e "${CYAN}${BOLD}容器日志: $container_id (最后 $lines 行)${NC}"
    echo ""
    view_container_logs "$container_id" "$lines" 2>/dev/null | less

    read -p "按 Enter 继续..."
}

# 进入容器终端菜单
enter_container_shell_menu() {
    clear
    echo -e "${CYAN}${BOLD}进入容器终端${NC}"
    echo ""

    echo -e "${YELLOW}运行中的容器:${NC}"
    list_containers "running" 2>/dev/null || echo "无运行中的容器"
    echo ""

    echo -n "请输入容器ID或名称 (输入 0 返回): "
    read -r container_id

    if [[ "$container_id" == "0" ]] || [[ -z "$container_id" ]]; then
        return
    fi

    echo -e "${YELLOW}正在进入容器终端...${NC}"
    echo -e "${CYAN}(使用 'exit' 退出容器终端)${NC}"
    echo ""
    sleep 1

    exec_container_shell "$container_id"

    echo ""
    read -p "按 Enter 继续..."
}

# 镜像管理菜单
show_image_management() {
    while true; do
        clear
        print_logo
        show_system_info

        echo -e "${CYAN}${BOLD}镜像管理${NC}"
        echo ""

        # 显示镜像统计
        local image_count=$(docker images -q | wc -l)
        echo -e "${BOLD}本地镜像数量:${NC} $image_count"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        echo "1. 查看所有镜像"
        echo "2. 拉取新镜像"
        echo "3. 删除镜像"
        echo "4. 搜索 Docker Hub"
        echo "5. 清理未使用的镜像"
        echo "0. 返回上级菜单"
        echo ""
        echo -n "请选择: "
        read -r choice

        case "$choice" in
            1)
                show_images_list
                ;;
            2)
                pull_image_interactive
                ;;
            3)
                delete_image_interactive
                ;;
            4)
                search_dockerhub_interactive
                ;;
            5)
                prune_images_interactive
                ;;
            0)
                return
                ;;
        esac
    done
}

# 显示镜像列表
show_images_list() {
    clear
    echo -e "${CYAN}${BOLD}本地镜像列表${NC}"
    echo ""

    if ! list_images 2>/dev/null; then
        echo -e "${YELLOW}无法获取镜像列表${NC}"
    fi

    echo ""
    read -p "按 Enter 继续..."
}

# 拉取镜像
pull_image_interactive() {
    clear
    echo -e "${CYAN}${BOLD}拉取 Docker 镜像${NC}"
    echo ""

    echo -n "请输入镜像名称 (如 nginx:latest, ubuntu:22.04): "
    read -r image_name

    if [[ -z "$image_name" ]]; then
        echo -e "${RED}镜像名称不能为空${NC}"
        sleep 2
        return
    fi

    echo ""
    echo -e "${YELLOW}正在拉取镜像: $image_name${NC}"
    echo ""

    if pull_image "$image_name"; then
        echo ""
        echo -e "${GREEN}✓ 镜像拉取成功${NC}"
    else
        echo ""
        echo -e "${RED}✗ 镜像拉取失败${NC}"
    fi

    sleep 2
}

# 删除镜像
delete_image_interactive() {
    clear
    echo -e "${CYAN}${BOLD}删除镜像${NC}"
    echo ""

    echo -e "${YELLOW}本地镜像列表:${NC}"
    list_images 2>/dev/null || echo "无镜像"
    echo ""

    echo -n "请输入镜像ID或名称 (输入 0 返回): "
    read -r image_id

    if [[ "$image_id" == "0" ]] || [[ -z "$image_id" ]]; then
        return
    fi

    echo -n "是否强制删除? [y/N]: "
    read -r force
    local force_flag="false"
    [[ "$force" =~ ^[Yy]$ ]] && force_flag="true"

    echo ""
    echo -e "${YELLOW}正在删除镜像...${NC}"

    if delete_image "$image_id" "$force_flag"; then
        echo -e "${GREEN}✓ 镜像已删除${NC}"
    else
        echo -e "${RED}✗ 删除失败${NC}"
    fi

    sleep 2
}

# 搜索 Docker Hub
search_dockerhub_interactive() {
    clear
    echo -e "${CYAN}${BOLD}搜索 Docker Hub${NC}"
    echo ""

    echo -n "请输入搜索关键词: "
    read -r keyword

    if [[ -z "$keyword" ]]; then
        echo -e "${RED}关键词不能为空${NC}"
        sleep 2
        return
    fi

    echo ""
    echo -e "${YELLOW}搜索结果:${NC}"
    echo ""

    search_dockerhub "$keyword"

    echo ""
    read -p "按 Enter 继续..."
}

# 清理未使用的镜像
prune_images_interactive() {
    clear
    echo -e "${CYAN}${BOLD}清理未使用的镜像${NC}"
    echo ""

    echo -e "${YELLOW}这将删除所有未被容器使用的镜像${NC}"
    echo -n "确认继续? [y/N]: "
    read -r confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi

    echo ""
    echo -e "${YELLOW}正在清理...${NC}"
    docker image prune -af

    echo ""
    read -p "按 Enter 继续..."
}

# 网络管理菜单
show_network_management() {
    while true; do
        clear
        print_logo
        show_system_info

        echo -e "${CYAN}${BOLD}网络管理${NC}"
        echo ""

        # 显示网络统计
        local network_count=$(docker network ls -q | wc -l)
        echo -e "${BOLD}网络数量:${NC} $network_count"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        echo "1. 查看所有网络"
        echo "2. 创建网络"
        echo "3. 删除网络"
        echo "4. 查看网络详情"
        echo "0. 返回上级菜单"
        echo ""
        echo -n "请选择: "
        read -r choice

        case "$choice" in
            1)
                show_networks_list
                ;;
            2)
                create_network_interactive
                ;;
            3)
                delete_network_interactive
                ;;
            4)
                inspect_network_interactive
                ;;
            0)
                return
                ;;
        esac
    done
}

# 显示网络列表
show_networks_list() {
    clear
    echo -e "${CYAN}${BOLD}Docker 网络列表${NC}"
    echo ""

    if ! list_networks 2>/dev/null; then
        echo -e "${YELLOW}无法获取网络列表${NC}"
    fi

    echo ""
    read -p "按 Enter 继续..."
}

# 创建网络
create_network_interactive() {
    clear
    echo -e "${CYAN}${BOLD}创建 Docker 网络${NC}"
    echo ""

    echo -n "请输入网络名称: "
    read -r network_name

    if [[ -z "$network_name" ]]; then
        echo -e "${RED}网络名称不能为空${NC}"
        sleep 2
        return
    fi

    echo ""
    echo "选择网络驱动:"
    echo "1. bridge (默认)"
    echo "2. host"
    echo "3. overlay"
    echo "4. macvlan"
    echo -n "请选择 [1]: "
    read -r driver_choice
    driver_choice=${driver_choice:-1}

    local driver="bridge"
    case "$driver_choice" in
        1) driver="bridge" ;;
        2) driver="host" ;;
        3) driver="overlay" ;;
        4) driver="macvlan" ;;
    esac

    echo ""
    echo -e "${YELLOW}正在创建网络: $network_name (驱动: $driver)${NC}"

    if create_network "$network_name" "$driver"; then
        echo -e "${GREEN}✓ 网络创建成功${NC}"
    else
        echo -e "${RED}✗ 网络创建失败${NC}"
    fi

    sleep 2
}

# 删除网络
delete_network_interactive() {
    clear
    echo -e "${CYAN}${BOLD}删除网络${NC}"
    echo ""

    echo -e "${YELLOW}网络列表:${NC}"
    list_networks 2>/dev/null || echo "无网络"
    echo ""

    echo -n "请输入网络ID或名称 (输入 0 返回): "
    read -r network_id

    if [[ "$network_id" == "0" ]] || [[ -z "$network_id" ]]; then
        return
    fi

    echo ""
    echo -e "${YELLOW}正在删除网络...${NC}"

    if delete_network "$network_id"; then
        echo -e "${GREEN}✓ 网络已删除${NC}"
    else
        echo -e "${RED}✗ 删除失败${NC}"
    fi

    sleep 2
}

# 查看网络详情
inspect_network_interactive() {
    clear
    echo -e "${CYAN}${BOLD}查看网络详情${NC}"
    echo ""

    list_networks 2>/dev/null || echo "无网络"
    echo ""

    echo -n "请输入网络ID或名称 (输入 0 返回): "
    read -r network_id

    if [[ "$network_id" == "0" ]] || [[ -z "$network_id" ]]; then
        return
    fi

    clear
    echo -e "${CYAN}${BOLD}网络详细信息: $network_id${NC}"
    echo ""
    docker network inspect "$network_id" 2>/dev/null | less

    read -p "按 Enter 继续..."
}

# 卷管理菜单
show_volume_management() {
    while true; do
        clear
        print_logo
        show_system_info

        echo -e "${CYAN}${BOLD}卷管理${NC}"
        echo ""

        # 显示卷统计
        local volume_count=$(docker volume ls -q | wc -l)
        echo -e "${BOLD}卷数量:${NC} $volume_count"
        echo ""
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""

        echo "1. 查看所有卷"
        echo "2. 创建卷"
        echo "3. 删除卷"
        echo "4. 查看卷详情"
        echo "5. 清理未使用的卷"
        echo "0. 返回上级菜单"
        echo ""
        echo -n "请选择: "
        read -r choice

        case "$choice" in
            1)
                show_volumes_list
                ;;
            2)
                create_volume_interactive
                ;;
            3)
                delete_volume_interactive
                ;;
            4)
                inspect_volume_interactive
                ;;
            5)
                prune_volumes_interactive
                ;;
            0)
                return
                ;;
        esac
    done
}

# 显示卷列表
show_volumes_list() {
    clear
    echo -e "${CYAN}${BOLD}Docker 卷列表${NC}"
    echo ""

    if ! list_volumes 2>/dev/null; then
        echo -e "${YELLOW}无法获取卷列表${NC}"
    fi

    echo ""
    read -p "按 Enter 继续..."
}

# 创建卷
create_volume_interactive() {
    clear
    echo -e "${CYAN}${BOLD}创建 Docker 卷${NC}"
    echo ""

    echo -n "请输入卷名称: "
    read -r volume_name

    if [[ -z "$volume_name" ]]; then
        echo -e "${RED}卷名称不能为空${NC}"
        sleep 2
        return
    fi

    echo ""
    echo -e "${YELLOW}正在创建卷: $volume_name${NC}"

    if create_volume "$volume_name"; then
        echo -e "${GREEN}✓ 卷创建成功${NC}"
    else
        echo -e "${RED}✗ 卷创建失败${NC}"
    fi

    sleep 2
}

# 删除卷
delete_volume_interactive() {
    clear
    echo -e "${CYAN}${BOLD}删除卷${NC}"
    echo ""

    echo -e "${YELLOW}卷列表:${NC}"
    list_volumes 2>/dev/null || echo "无卷"
    echo ""

    echo -n "请输入卷名称 (输入 0 返回): "
    read -r volume_name

    if [[ "$volume_name" == "0" ]] || [[ -z "$volume_name" ]]; then
        return
    fi

    echo ""
    echo -e "${YELLOW}正在删除卷...${NC}"

    if delete_volume "$volume_name"; then
        echo -e "${GREEN}✓ 卷已删除${NC}"
    else
        echo -e "${RED}✗ 删除失败${NC}"
    fi

    sleep 2
}

# 查看卷详情
inspect_volume_interactive() {
    clear
    echo -e "${CYAN}${BOLD}查看卷详情${NC}"
    echo ""

    list_volumes 2>/dev/null || echo "无卷"
    echo ""

    echo -n "请输入卷名称 (输入 0 返回): "
    read -r volume_name

    if [[ "$volume_name" == "0" ]] || [[ -z "$volume_name" ]]; then
        return
    fi

    clear
    echo -e "${CYAN}${BOLD}卷详细信息: $volume_name${NC}"
    echo ""
    docker volume inspect "$volume_name" 2>/dev/null | less

    read -p "按 Enter 继续..."
}

# 清理未使用的卷
prune_volumes_interactive() {
    clear
    echo -e "${CYAN}${BOLD}清理未使用的卷${NC}"
    echo ""

    echo -e "${YELLOW}这将删除所有未被容器使用的卷${NC}"
    echo -n "确认继续? [y/N]: "
    read -r confirm

    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi

    echo ""
    echo -e "${YELLOW}正在清理...${NC}"
    docker volume prune -f

    echo ""
    read -p "按 Enter 继续..."
}

# Docker 系统信息
show_docker_system_info() {
    clear
    echo -e "${CYAN}${BOLD}Docker 系统信息${NC}"
    echo ""
    docker info
    echo ""
    read -p "按 Enter 继续..."
}

# Docker 设置
show_docker_settings() {
    echo "Docker 设置 - 待实现"
    read -p "按 Enter 继续..."
}

# 安装 Docker
install_docker() {
    echo "Docker 安装 - 待实现"
    read -p "按 Enter 继续..."
}

# 卸载 Docker
uninstall_docker() {
    echo "Docker 卸载 - 待实现"
    read -p "按 Enter 继续..."
}

# 启动 Docker 服务
start_docker_service() {
    echo "启动 Docker 服务 - 待实现"
    read -p "按 Enter 继续..."
}

# ============================================================================
# 模块信息
# ============================================================================

get_module_info() {
    echo "Docker 管理模块 v1.0 - 命令行版 Docker 可视化管理器"
}