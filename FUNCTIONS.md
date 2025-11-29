# 函数索引

本文档列出了所有函数的定义位置，方便快速查找和跳转。

## 配置和常量 (lib/config.sh)
- `CONFIG_FILE` - 配置文件路径

## 日志函数 (lib/logger.sh)
- `print_info()` - 输出信息
- `print_warning()` - 输出警告
- `print_error()` - 输出错误
- `print_success()` - 输出成功
- `print_debug()` - 输出调试信息
- `print_step()` - 输出步骤信息

## 配置文件解析 (lib/parser.sh)
- `parse_group_line()` - 解析分组行
- `find_group_name()` - 查找分组名
- `get_group_folder()` - 获取分组文件夹名
- `get_group_repos()` - 获取指定分组的仓库列表
- `list_groups()` - 列出所有分组
- `get_all_group_names()` - 获取所有分组名称

## GitHub 操作 (lib/github.sh)
- `init_github_connection()` - 初始化 GitHub 连接
- `fetch_remote_repos()` - 获取所有远程仓库列表
- `find_repo_full_name()` - 查找仓库的完整名称

## 同步操作 (lib/sync.sh)
- `clone_repo()` - 克隆仓库
- `update_repo()` - 更新已有仓库
- `sync_single_repo()` - 同步单个仓库

## 清理操作 (lib/cleanup.sh)
- `cleanup_deleted_repos()` - 清理远程已删除的本地仓库

## 统计和错误处理 (lib/stats.sh)
- `init_sync_stats()` - 初始化全局统计变量
- `is_repo_cloned_or_updated()` - 判断仓库是新克隆还是更新
- `update_sync_statistics()` - 更新统计信息
- `record_error()` - 记录错误日志
- `print_final_summary()` - 输出最终统计信息
- `print_failed_repos_details()` - 显示失败仓库详情

## 重试机制 (lib/retry.sh)
- `retry_repo_sync()` - 通用重试函数
- `batch_retry_repos()` - 批量重试失败的仓库

## 主执行流程 (lib/main_helpers.sh)
- `parse_arguments()` - 解析命令行参数
- `initialize_sync()` - 初始化同步环境
- `build_sync_repos_map()` - 构建同步仓库映射
- `sync_group_repos_main()` - 同步单个分组的所有仓库
- `collect_still_failed_repos()` - 收集仍然失败的仓库
- `sync_group_repos()` - 同步分组中的仓库（主入口）
- `execute_sync()` - 执行同步操作（遍历所有分组）

## 主脚本 (sync-groups-v2.sh)
- `main()` - 主函数

