#!/bin/bash
# 配置文件解析函数

# 解析分组行，提取分组名和代号
# 格式: ## 分组名 <!-- 代号 -->
parse_group_line() {
    local line=$1
    if echo "$line" | grep -qE '^##[[:space:]]+'; then
        local full_line=$(echo "$line" | sed 's/^##[[:space:]]*//')
        local group_name=$(echo "$full_line" | sed 's/[[:space:]]*<!--.*-->.*$//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        local alias=""
        if echo "$full_line" | grep -qE '<!--.*-->'; then
            alias=$(echo "$full_line" | sed -n 's/.*<!--[[:space:]]*\([^[:space:]]*[^[:space:]]\)[[:space:]]*-->.*/\1/p' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
        fi
        echo "$group_name|$alias"
    fi
}

# 查找分组名（支持完整名称或代号）
find_group_name() {
    local input=$1
    local found_name=""
    
    print_debug "查找分组: 输入='$input'"
    while IFS= read -r line; do
        local parsed=$(parse_group_line "$line")
        if [ -n "$parsed" ]; then
            IFS='|' read -r group_name alias <<< "$parsed"
            print_debug "  比较: 分组名='$group_name', 代号='$alias'"
            if [ "$group_name" = "$input" ] || [ "$alias" = "$input" ]; then
                found_name="$group_name"
                print_debug "  匹配成功: 找到分组 '$group_name'"
                break
            fi
            # 支持去掉"高地"后缀的匹配
            if [ -n "$alias" ]; then
                local alias_without="${alias%高地}"
                if [ "$alias_without" != "$alias" ] && [ "$alias_without" = "$input" ]; then
                    found_name="$group_name"
                    print_debug "  匹配成功（去掉'高地'后缀）: 找到分组 '$group_name'"
                    break
                fi
            fi
        fi
    done < "$CONFIG_FILE"
    
    if [ -z "$found_name" ]; then
        print_debug "  未找到匹配的分组"
    fi
    echo "$found_name"
}

# 获取分组文件夹名
get_group_folder() {
    local group_name=$1
    local group_alias=""
    
    while IFS= read -r line; do
        local parsed=$(parse_group_line "$line")
        if [ -n "$parsed" ]; then
            IFS='|' read -r current_group alias <<< "$parsed"
            if [ "$current_group" = "$group_name" ]; then
                group_alias="$alias"
                break
            fi
        fi
    done < "$CONFIG_FILE"
    
    # 如果有别名，使用别名（保留"高地"后缀）；否则使用分组名
    local folder="${group_alias:-$group_name}"
    echo "$folder"
}

# 获取指定分组的仓库列表
get_group_repos() {
    local group_name=$1
    local in_group=false
    local repos=()
    
    print_debug "获取分组 '$group_name' 的仓库列表"
    while IFS= read -r line; do
        local parsed=$(parse_group_line "$line")
        if [ -n "$parsed" ]; then
            IFS='|' read -r current_group alias <<< "$parsed"
            if [ "$current_group" = "$group_name" ]; then
                in_group=true
                print_debug "  进入分组 '$group_name'"
            else
                in_group=false
            fi
        elif [ "$in_group" = true ] && echo "$line" | grep -qE '^-[[:space:]]+'; then
            local repo_name=$(echo "$line" | sed 's/^-[[:space:]]*//' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
            if [ -n "$repo_name" ]; then
                repos+=("$repo_name")
                print_debug "  找到仓库: $repo_name"
            fi
        fi
    done < "$CONFIG_FILE"
    
    print_debug "分组 '$group_name' 共有 ${#repos[@]} 个仓库"
    printf '%s\n' "${repos[@]}"
}

# 列出所有分组
list_groups() {
    print_step "正在读取配置文件: $CONFIG_FILE"
    if [ ! -f "$CONFIG_FILE" ]; then
        print_error "分类文档不存在: $CONFIG_FILE"
        print_info "请参考 REPO-GROUPS.md.example 创建分类文档"
        print_info "或使用 PROMPT.md 中的 prompt 让 AI 生成"
        return
    fi
    print_debug "配置文件存在，开始解析分组"
    print_info "可用分组："
    local group_count=0
    while IFS= read -r line; do
        local parsed=$(parse_group_line "$line")
        if [ -n "$parsed" ]; then
            IFS='|' read -r group_name alias <<< "$parsed"
            if [ -n "$alias" ]; then
                echo "  $group_name (代号: $alias)"
            else
                echo "  $group_name"
            fi
            ((group_count++))
            print_debug "解析到分组: $group_name (代号: $alias)"
        fi
    done < "$CONFIG_FILE"
    print_info "共找到 $group_count 个分组"
}

# 获取所有分组名称（用于 -a 参数）
get_all_group_names() {
    if [ ! -f "$CONFIG_FILE" ]; then
        return 1
    fi
    
    local group_names=()
    while IFS= read -r line; do
        local parsed=$(parse_group_line "$line")
        if [ -n "$parsed" ]; then
            IFS='|' read -r group_name alias <<< "$parsed"
            group_names+=("$group_name")
        fi
    done < "$CONFIG_FILE"
    
    printf '%s\n' "${group_names[@]}"
}

