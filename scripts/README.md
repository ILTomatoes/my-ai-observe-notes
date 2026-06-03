# Scripts

辅助脚本。所有脚本假设在仓库根目录运行。

## sync-from-private.sh

从私有仓库 `my-daily-remarks` 拉取指定笔记,做基础脱敏后放到 `docs/articles/`。

```bash
./scripts/sync-from-private.sh summaries/insights/2026-06-03_ai-paradigm-shift.md
```

**只做基础脱敏(已知敏感词替换)**——具体内容的脱敏 + 博文风格改写必须人工完成。

详细脱敏规则在脚本顶部 `DESENSITIZE_RULES` 数组,需要时可调整。
