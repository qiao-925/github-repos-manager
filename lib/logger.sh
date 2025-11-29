#!/bin/bash
# 日志输出函数

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_debug() {
    # Debug 模式已关闭
    :
}

print_step() {
    echo -e "${BLUE}→${NC} $1"
}

