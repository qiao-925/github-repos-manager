#!/bin/bash
# GitHub 仓库操作函数

# 初始化 GitHub 连接（添加 SSH 密钥）
init_github_connection() {
    print_step "检查 SSH 配置..."
    if [ ! -f ~/.ssh/known_hosts ] || ! grep -q "github.com" ~/.ssh/known_hosts 2>/dev/null; then
        print_info "正在添加 GitHub 主机密钥..."
        mkdir -p ~/.ssh
        ssh-keyscan -t rsa,ecdsa,ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null || true
        print_debug "GitHub 主机密钥已添加到 known_hosts"
    else
        print_debug "GitHub 主机密钥已存在"
    fi
    
    # 配置 Git 加速选项
    print_step "配置 Git 加速选项..."
    git config --global http.postBuffer 524288000 2>/dev/null || true  # 500MB 缓冲区
    git config --global http.lowSpeedLimit 0 2>/dev/null || true
    git config --global http.lowSpeedTime 0 2>/dev/null || true
    git config --global core.preloadindex true 2>/dev/null || true
    git config --global core.fscache true 2>/dev/null || true
    print_info "  HTTP 缓冲区: 500MB"
    print_info "  Git 加速配置已应用"
    print_info "使用官方 GitHub (github.com)"
}

# 获取所有远程仓库列表
fetch_remote_repos() {
    print_step "通过 GitHub CLI 获取仓库列表..."
    local all_repos=$(gh repo list --limit 1000 --json nameWithOwner --jq '.[].nameWithOwner')
    
    if [ $? -ne 0 ]; then
        print_error "无法获取仓库列表。请确保已登录 GitHub CLI (运行: gh auth login)"
        exit 1
    fi
    
    local repo_count=$(echo "$all_repos" | wc -l | tr -d ' ')
    print_success "成功获取 $repo_count 个远程仓库"
    print_debug "远程仓库列表: $(echo "$all_repos" | head -5 | tr '\n' ', ')..."
    
    echo "$all_repos"
}

# 查找仓库的完整名称（owner/repo）
find_repo_full_name() {
    local repo_name=$1
    local repo_owner=$(gh api user --jq '.login' 2>/dev/null || echo "")
    
    if [ -z "$repo_owner" ]; then
        return 1
    fi
    
    # 尝试检查仓库是否存在
    if gh repo view "$repo_owner/$repo_name" &>/dev/null; then
        echo "$repo_owner/$repo_name"
        return 0
    fi
    
    return 1
}

