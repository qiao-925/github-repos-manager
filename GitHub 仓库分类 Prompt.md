# GitHub 仓库分类 Prompt

## Prompt 模板

```
请根据以下 GitHub 仓库列表，按照合理的逻辑进行分类。

仓库所有者: [你的用户名]
仓库列表:
[仓库列表]

要求：
1. 使用 Markdown 格式
2. 每个分类格式：`## 分组名 <!-- 代号 -->`
   - 分组名：中文描述（如"AI-Practice"）
   - 代号：军事代号风格（如"597.9高地"、"54高地"），参考 `高地编号参考.md`
3. 分类下使用无序列表列出仓库
4. 分类逻辑：按编程语言、学习阶段、项目类型、用途等
```

## 使用方法

**执行分类**
1. 在 Cursor 中执行：`@PROMPT.md 执行当前prompt`
2. 检查并调整分类
3. 确认后告诉 AI "保存"，会保存为 `REPO-GROUPS.md`

**同步分组**
```bash
bash sync-groups.sh 597.9          # 同步单个分组
bash sync-groups.sh 597.9 537.7 54 # 同步多个分组
bash sync-groups.sh --list         # 列出所有分组
```

