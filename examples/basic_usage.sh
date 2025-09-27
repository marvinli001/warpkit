#!/bin/bash

# WarpKit 基础使用示例
# 这个脚本展示了如何在其他脚本中集成 WarpKit 的功能

# 设置脚本路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WARPKIT_PATH="${SCRIPT_DIR}/../warpkit.sh"

# 检查 WarpKit 是否存在
if [[ ! -f "$WARPKIT_PATH" ]]; then
    echo "错误: 找不到 WarpKit 脚本"
    exit 1
fi

# 导入 WarpKit 的功能函数
source "$WARPKIT_PATH"

echo "=== WarpKit 功能演示 ==="
echo

# 1. 系统信息检测
echo "1. 检测系统信息..."
detect_distro
show_system_info
echo

# 2. 进度条演示
echo "2. 进度条演示..."
for i in {1..10}; do
    show_progress $i 10 "处理任务"
    sleep 0.2
done
echo

# 3. 状态消息演示
echo "3. 状态消息演示..."
update_status "info" "开始处理任务"
sleep 1
update_status "working" "正在执行操作"
sleep 1
update_status "success" "任务完成"
update_status "warning" "发现警告"
update_status "error" "遇到错误"
echo

# 4. 加载动画演示
echo "4. 加载动画演示..."
loading_animation "数据处理中" 3
echo

# 5. 多步骤任务演示
echo "5. 多步骤任务演示..."
steps=(
    "初始化环境"
    "检查依赖"
    "下载资源"
    "配置系统"
    "启动服务"
)
multi_step_task "${steps[@]}"
echo

echo "=== 演示完成 ==="