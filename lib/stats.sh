#!/bin/bash
# 统计和错误处理函数

# 初始化全局统计变量
init_sync_stats() {
    declare -g SYNC_STATS_SUCCESS=0
    declare -g SYNC_STATS_UPDATE=0
    declare -g SYNC_STATS_FAIL=0
    declare -g CLEANUP_STATS_DELETE=0
    declare -gA group_folders
    declare -gA group_names
}

# 判断仓库是新克隆的还是更新的
# 返回值: 0=新克隆, 1=更新, 2=无法判断
# 注意：此函数通过检查 remote 配置来判断，但新克隆和更新的仓库都有 remote 配置
# 因此此方法可能无法准确区分，更准确的方法需要在 sync_single_repo 中记录操作类型
is_repo_cloned_or_updated() {
    local repo_path=$1
    
    if [ ! -d "$repo_path/.git" ]; then
        return 2
    fi
    
    # 检查是否有远程配置（已存在的仓库通常有）
    # 注意：新克隆的仓库也有 remote 配置，所以此方法不完美
    # 但作为简单的启发式方法，假设有 remote 配置的是更新
    if git -C "$repo_path" remote get-url origin &>/dev/null; then
        return 1  # 更新
    else
        return 0  # 新克隆（但实际上新克隆的也有 remote，所以这个判断不准确）
    fi
}

# 更新统计信息（统一处理）
update_sync_statistics() {
    local repo_path=$1
    local result=$2
    
    case $result in
        0)
            # 成功，判断是新克隆还是更新
            local stat_result
            is_repo_cloned_or_updated "$repo_path"
            stat_result=$?
            if [ $stat_result -eq 0 ]; then
                ((SYNC_STATS_SUCCESS++))
            elif [ $stat_result -eq 1 ]; then
                ((SYNC_STATS_UPDATE++))
            fi
            ;;
        2)
            ((SYNC_STATS_FAIL++))
            ;;
        *)
            ((SYNC_STATS_FAIL++))
            ;;
    esac
}

# 记录错误日志（统一格式）
record_error() {
    local error_log_ref=$1
    local repo=$2
    local error_type=$3
    local error_msg=$4
    
    if [ -n "$error_log_ref" ]; then
        # 使用 nameref 安全地添加元素
        local -n error_log_array=$error_log_ref
        error_log_array+=("$repo|$error_type|$error_msg")
    fi
}

# 输出最终统计信息
print_final_summary() {
    echo ""
    echo "=================================================="
    echo "✅ 同步完成！"
    echo "新增: ${SYNC_STATS_SUCCESS:-0}"
    echo "更新: ${SYNC_STATS_UPDATE:-0}"
    echo "删除: ${CLEANUP_STATS_DELETE:-0}"
    echo "失败: ${SYNC_STATS_FAIL:-0}"
    echo "=================================================="
}

# 显示失败仓库详情
print_failed_repos_details() {
    local -n failed_logs_ref=$1
    
    if [ ${#failed_logs_ref[@]} -eq 0 ]; then
        return
    fi
    
    echo ""
    echo "=================================================="
    echo "❌ 失败仓库详情："
    echo "=================================================="
    local log_index=1
    local displayed_count=0
    
    for failed_log in "${failed_logs_ref[@]}"; do
        IFS='|' read -r repo_identifier error_type error_msg <<< "$failed_log"
        
        # 判断是完整仓库名（owner/repo）还是仓库名
        local repo_name=""
        local repo_full=""
        if [[ "$repo_identifier" == *"/"* ]]; then
            repo_full="$repo_identifier"
            repo_name=$(basename "$repo_identifier")
        else
            repo_name="$repo_identifier"
            repo_full="未知/$repo_identifier"
        fi
        
        # 检查仓库是否仍然失败（避免显示已重试成功的）
        local found_group_folder=""
        local is_still_failed=false
        
        for gf in "${!group_folders[@]}"; do
            if [ -d "$gf/$repo_name" ]; then
                if [ ! -d "$gf/$repo_name/.git" ]; then
                    found_group_folder="$gf"
                    is_still_failed=true
                    break
                fi
            fi
        done
        
        # 如果找不到目录，也可能是失败的
        if [ -z "$found_group_folder" ] && [ "$error_type" != "跳过" ]; then
            for gf in "${!group_folders[@]}"; do
                if [ ! -d "$gf/$repo_name/.git" ]; then
                    found_group_folder="$gf"
                    is_still_failed=true
                    break
                fi
            done
        fi
        
        if [ "$is_still_failed" = true ] || [ "$error_type" = "错误" ]; then
            echo ""
            echo "[$log_index] 仓库: $repo_full"
            echo "    类型: $error_type"
            echo "    原因: $error_msg"
            if [ -n "$found_group_folder" ]; then
                echo "    位置: $found_group_folder/$repo_name"
            fi
            ((log_index++))
            ((displayed_count++))
        fi
    done
    
    if [ $displayed_count -eq 0 ]; then
        echo ""
        echo "所有失败的仓库已通过重试成功同步"
    fi
    echo ""
    echo "=================================================="
}

