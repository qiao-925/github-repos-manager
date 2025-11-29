#!/bin/bash
# GitHub 仓库按分组同步脚本
# 功能：按分组同步 GitHub 仓库，保持本地仓库与远程仓库完全同步（增删改查）
# 使用方法: 
#   bash sync-groups-v2.sh <分组名1> [分组名2] ...
#   分组名可以是完整名称（如"Go 学习"）或代号（如"597.9"或"597.9高地"）
#   使用 --list 或 -l 查看所有可用分组
#   使用 -a 或 --all 同步所有分组
#
# 加速配置：
#   Git 缓冲区：自动配置 500MB HTTP 缓冲区

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# 加载所有模块
source "$LIB_DIR/config.sh"
source "$LIB_DIR/logger.sh"
source "$LIB_DIR/parser.sh"
source "$LIB_DIR/github.sh"
source "$LIB_DIR/sync.sh"
source "$LIB_DIR/cleanup.sh"
source "$LIB_DIR/stats.sh"
source "$LIB_DIR/retry.sh"
source "$LIB_DIR/main_helpers.sh"

# 主函数
main() {
    # 1. 参数解析
    local parsed_args_output=$(parse_arguments "$@")
    local parsed_exit_code=$?
    
    if [ $parsed_exit_code -ne 0 ]; then
        exit $parsed_exit_code
    fi
    
    # 将解析后的参数转换为数组
    local groups_array=()
    while IFS= read -r line; do
        [ -n "$line" ] && groups_array+=("$line")
    done <<< "$parsed_args_output"
    
    # 2. 初始化同步环境
    initialize_sync
    
    # 3. 执行同步
    execute_sync "${groups_array[@]}"
    
    # 4. 构建同步仓库映射（用于清理检查）
    declare -A sync_repos_map
    build_sync_repos_map sync_repos_map
    
    # 5. 清理删除远程已不存在的本地仓库
    cleanup_deleted_repos group_folders sync_repos_map
    
    # 6. 输出最终统计
    print_final_summary
    
    # 7. 显示失败仓库详情
    if [ -n "$ALL_FAILED_LOGS_ARRAY" ]; then
        local -n failed_logs=$ALL_FAILED_LOGS_ARRAY
        print_failed_repos_details failed_logs
    fi
}

# 执行主函数
main "$@"
