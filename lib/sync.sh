#!/bin/bash
# 仓库同步操作函数

# 克隆仓库（完整克隆，带第一层重试）
clone_repo() {
    local repo=$1
    local repo_path=$2
    local current_index=$3
    local total_sync=$4
    local is_retry=${5:-false}
    local error_log_ref=${6:-""}
    
    if [ "$is_retry" = "true" ]; then
        echo "[$current_index/$total_sync] [克隆-重试] $repo -> $(dirname "$repo_path")/..."
        print_info "  正在重试克隆仓库: $repo"
    else
        echo "[$current_index/$total_sync] [克隆] $repo -> $(dirname "$repo_path")/..."
        print_info "  正在克隆仓库: $repo"
    fi
    print_info "  目标路径: $repo_path"
    
    local repo_url="https://github.com/$repo.git"
    print_info "  仓库 URL: $repo_url"
    
    # 使用官方 GitHub 进行完整克隆，捕获错误信息
    print_info "  开始执行 git clone..."
    local clone_start_time=$(date +%s)
    local clone_output=$(git clone "$repo_url" "$repo_path" 2>&1)
    local clone_exit_code=$?
    local clone_end_time=$(date +%s)
    local clone_duration=$((clone_end_time - clone_start_time))
    
    if [ $clone_exit_code -eq 0 ]; then
        if [ "$is_retry" = "true" ]; then
            echo "✓ 成功（重试，耗时 ${clone_duration}秒）"
        else
            echo "✓ 成功（耗时 ${clone_duration}秒）"
        fi
        print_success "  克隆成功: $repo_path"
        return 0
    else
        # 第一层重试：如果失败且不是重试，立即重试一次
        if [ "$is_retry" != "true" ]; then
            print_warning "  克隆失败，立即重试一次..."
            sleep 1
            [ -d "$repo_path" ] && rm -rf "$repo_path" 2>/dev/null || true
            clone_repo "$repo" "$repo_path" "$current_index" "$total_sync" "true" "$error_log_ref"
            return $?
        else
            echo "✗ 失败（耗时 ${clone_duration}秒）"
            local error_msg=$(echo "$clone_output" | tail -5 | tr '\n' ' ' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            if [ -z "$error_msg" ]; then
                error_msg="克隆失败，退出代码: $clone_exit_code"
            fi
            print_error "  克隆失败: $error_msg"
            print_error "  完整错误信息:"
            echo "$clone_output" | while IFS= read -r line; do
                print_error "    $line"
            done
            # 记录失败日志
            if [ -n "$error_log_ref" ]; then
                # 使用 nameref 安全地添加元素
                local -n error_log_array=$error_log_ref
                error_log_array+=("$repo|克隆失败|$error_msg")
            fi
            return 1
        fi
    fi
}

# 更新已有仓库（带第一层重试）
update_repo() {
    local repo=$1
    local repo_path=$2
    local group_folder=$3
    local current_index=$4
    local total_sync=$5
    local is_retry=${6:-false}
    local error_log_ref=${7:-""}
    
    if [ "$is_retry" = "true" ]; then
        echo -n "[$current_index/$total_sync] [更新-重试] $repo ($group_folder)... "
        print_info "  正在重试更新仓库: $repo"
    else
        echo -n "[$current_index/$total_sync] [更新] $repo ($group_folder)... "
        print_info "  正在更新仓库: $repo"
    fi
    print_info "  仓库路径: $repo_path"
    
    # 保存当前目录
    local original_dir=$(pwd)
    
    cd "$repo_path" || {
        local error_msg="无法进入仓库目录: $repo_path"
        print_error "  错误: $error_msg"
        if [ -n "$error_log_ref" ]; then
            # 使用 nameref 安全地添加元素
            local -n error_log_array=$error_log_ref
            error_log_array+=("$repo|更新失败|$error_msg")
        fi
        return 1
    }
    
    # 检查是否在分支上，如果不在则切换到默认分支
    local current_branch=$(git symbolic-ref -q HEAD 2>&1)
    print_info "    当前分支状态: ${current_branch:-detached HEAD}"
    
    if [ -z "$current_branch" ]; then
        print_warning "    检测到 detached HEAD，尝试切换到默认分支"
        local default_branch_output=$(git remote show origin 2>&1 | grep "HEAD branch" | sed 's/.*: //' || echo "")
        local default_branch="${default_branch_output:-main}"
        print_info "    默认分支: $default_branch"
        
        print_debug "    执行: git checkout -b $default_branch"
        local checkout_output=$(git checkout -b "$default_branch" 2>&1)
        local checkout_exit=$?
        if [ $checkout_exit -ne 0 ]; then
            print_debug "    创建分支失败，尝试切换: git checkout $default_branch"
            checkout_output=$(git checkout "$default_branch" 2>&1)
            checkout_exit=$?
        fi
        
        if [ $checkout_exit -eq 0 ]; then
            print_success "    已切换到分支: $default_branch"
        else
            print_warning "    切换分支失败: $checkout_output"
            print_warning "    继续尝试拉取（可能仍在 detached HEAD 状态）"
        fi
    fi
    
    # 获取当前分支名并拉取
    local branch=$(git rev-parse --abbrev-ref HEAD 2>&1 || echo "main")
    print_info "    准备拉取分支: $branch"
    
    # 获取拉取前的提交哈希
    local before_hash=$(git rev-parse HEAD 2>&1 || echo "")
    print_info "    拉取前提交: ${before_hash:0:8}"
    
    # 直接执行 git pull，捕获错误信息
    print_info "    开始执行 git pull..."
    local pull_start_time=$(date +%s)
    # 先尝试从 origin 拉取，如果失败则尝试直接拉取（可能没有设置 remote）
    local pull_output=$(git pull origin "$branch" 2>&1)
    local pull_exit_code=$?
    
    # 如果从 origin 拉取失败，尝试直接拉取（可能 remote 名称不是 origin）
    if [ $pull_exit_code -ne 0 ]; then
        print_warning "    从 origin 拉取失败，尝试直接拉取..."
        pull_output=$(git pull 2>&1)
        pull_exit_code=$?
    fi
    
    local pull_end_time=$(date +%s)
    local pull_duration=$((pull_end_time - pull_start_time))
    
    if [ $pull_exit_code -eq 0 ]; then
        local after_hash=$(git rev-parse HEAD 2>&1 || echo "")
        print_info "    拉取后提交: ${after_hash:0:8}"
        
        if [ "$before_hash" != "$after_hash" ] && [ -n "$before_hash" ] && [ -n "$after_hash" ]; then
            print_success "    仓库已更新（从 ${before_hash:0:8} 到 ${after_hash:0:8}）"
        else
            print_info "    仓库已是最新（无新提交）"
        fi
        if [ "$is_retry" = "true" ]; then
            echo "✓ 成功（重试，耗时 ${pull_duration}秒）"
        else
            echo "✓ 成功（耗时 ${pull_duration}秒）"
        fi
        cd "$original_dir" || true
        return 0
    else
        # 第一层重试：如果失败且不是重试，立即重试一次
        if [ "$is_retry" != "true" ]; then
            echo ""
            print_warning "  更新失败，立即重试一次..."
            cd "$original_dir" || true
            sleep 1
            update_repo "$repo" "$repo_path" "$group_folder" "$current_index" "$total_sync" "true" "$error_log_ref"
            return $?
        else
            echo "✗ 失败（耗时 ${pull_duration}秒）"
            local error_msg=$(echo "$pull_output" | tail -5 | tr '\n' ' ' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            if [ -z "$error_msg" ]; then
                error_msg="拉取失败，退出代码: $pull_exit_code"
            fi
            print_error "  拉取失败: $error_msg"
            print_error "  完整错误信息:"
            echo "$pull_output" | while IFS= read -r line; do
                print_error "    $line"
            done
            # 记录失败日志
            if [ -n "$error_log_ref" ]; then
                # 使用 nameref 安全地添加元素
                local -n error_log_array=$error_log_ref
                error_log_array+=("$repo|更新失败|$error_msg")
            fi
            cd "$original_dir" || true
            return 1
        fi
    fi
}

# 同步单个仓库（克隆或更新）
sync_single_repo() {
    local repo=$1
    local repo_name=$2
    local group_folder=$3
    local current_index=$4
    local total_sync=$5
    local error_log_ref=${6:-""}
    
    # 创建分组文件夹
    if [ ! -d "$group_folder" ]; then
        mkdir -p "$group_folder"
        print_info "创建分组文件夹: $group_folder"
    fi
    
    local repo_path="$group_folder/$repo_name"
    
    # 检查是否已存在
    if [ -d "$repo_path" ]; then
        # 检查是否是 git 仓库
        if [ -d "$repo_path/.git" ]; then
            print_info "  检测到已存在的 git 仓库，执行更新操作"
            update_repo "$repo" "$repo_path" "$group_folder" "$current_index" "$total_sync" "false" "$error_log_ref"
            return $?
        else
            echo "[$current_index/$total_sync] [跳过] $repo - 目录已存在但不是 git 仓库"
            print_warning "  目录 $repo_path 存在但不是 git 仓库，跳过同步"
            print_warning "  如需同步此仓库，请先删除或重命名该目录"
            if [ -n "$error_log_ref" ]; then
                # 使用 nameref 安全地添加元素
                local -n error_log_array=$error_log_ref
                error_log_array+=("$repo|跳过|目录已存在但不是 git 仓库")
            fi
            return 2
        fi
    else
        print_info "  检测到新仓库，执行克隆操作"
        clone_repo "$repo" "$repo_path" "$current_index" "$total_sync" "false" "$error_log_ref"
        return $?
    fi
}

