#!/usr/bin/env bash
# scripts/sync-from-private.sh
# 从 my-daily-remarks (私有) 拉取指定笔记,做基础脱敏,放到 docs/articles/
#
# 用法:
#   ./scripts/sync-from-private.sh <private_note_path>
#
# 示例:
#   ./scripts/sync-from-private.sh summaries/insights/2026-06-03_ai-paradigm-shift.md
#   ./scripts/sync-from-private.sh notes/2026/2026-06/2026-06-03_coze-agent-teams.md
#
# 重要: 这个脚本只做"基础脱敏"(已知敏感词),具体内容的人工脱敏
#       + 博文风格改写必须人工完成。脚本跑完后:
#         1. 打开生成的文件 review
#         2. 调整 frontmatter (title/tags/authors)
#         3. 重写为博文风格
#         4. 更新 docs/articles.md 索引
#         5. git add + commit + push 触发部署

set -euo pipefail

# ---------- 配置 ----------
PRIVATE_REPO="${PRIVATE_REPO:-/root/my-workspace/my-daily-remarks}"
PUBLIC_REPO="$(cd "$(dirname "$0")/.." && pwd)"
ARTICLES_DIR="$PUBLIC_REPO/docs/articles"

# 脱敏规则: 左边是敏感词 (扩展正则), 右边是替换
# 多行用 | 分隔, 空格会被 trim
DESENSITIZE_RULES=(
  's/刘国栋/[本人]/g'
  's/普联软件/某软件公司/g'
  's/普联/某软件公司/g'
  's/平台事业部/某事业部/g'
  's/AI ?组/AI 团队/g'
  's/秦立丛|[杨旭][森森]|丁硕|康献磊|杨永谦/[同事]/g'
  's/aip-workspace/某 AI 工作空间/g'
  's/aip-server/某 AI 后端项目/g'
  's/minimax/MiniMax/g'  # 模型名保留, 统一大小写
)

# ---------- 校验输入 ----------
NOTE_PATH="${1:-}"
if [[ -z "$NOTE_PATH" ]]; then
  cat <<EOF
用法: $0 <private_note_path>

示例:
  $0 summaries/insights/2026-06-03_ai-paradigm-shift.md
  $0 notes/2026/2026-06/2026-06-03_coze-agent-teams.md

参数:
  NOTE_PATH  私有仓库内的相对路径 (相对于 my-daily-remarks/)
EOF
  exit 1
fi

SRC="$PRIVATE_REPO/$NOTE_PATH"
if [[ ! -f "$SRC" ]]; then
  echo "❌ 源文件不存在: $SRC" >&2
  echo "   请检查路径是否正确, 仓库根目录: $PRIVATE_REPO" >&2
  exit 1
fi

# ---------- 派生目标文件名 ----------
BASENAME=$(basename "$NOTE_PATH")
DATE_PREFIX=$(echo "$BASENAME" | grep -oE '^[0-9]{4}-[0-9]{2}-[0-9]{2}' || echo "")
SLUG=$(echo "$BASENAME" | sed -E "s/^${DATE_PREFIX}_//; s/\.md$//")

if [[ -n "$DATE_PREFIX" ]]; then
  TARGET_NAME="${DATE_PREFIX}_${SLUG}.md"
else
  TARGET_NAME="${SLUG}.md"
fi

DEST="$ARTICLES_DIR/$TARGET_NAME"

# 防止覆盖
if [[ -f "$DEST" ]]; then
  echo "⚠️  目标文件已存在: $DEST" >&2
  echo "   如要重新同步, 请先删除或重命名旧文件" >&2
  exit 1
fi

mkdir -p "$ARTICLES_DIR"

# ---------- 脱敏 + 生成 frontmatter ----------
TEMP=$(mktemp)
trap "rm -f $TEMP" EXIT

# 1. 应用脱敏规则
sed "${DESENSITIZE_RULES[@]}" "$SRC" > "$TEMP"

# 2. 从源文件提取关键 metadata (做 best-effort)
SRC_DATE=$(grep -oE '^\| \*\*日期\*\* \| [0-9-]+' "$SRC" | head -1 | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || echo "$DATE_PREFIX")
SRC_AUTHOR=$(grep -oE '^\| \*\*作者\*\* \| [^|]+' "$SRC" | head -1 | sed 's/^| \*\*作者\*\* | //' | sed 's/|$//' || echo "")
SRC_TAGS=$(grep -oE '^\| \*\*标签\*\* \| [^|]+' "$SRC" | head -1 | sed 's/^| \*\*标签\*\* | //' | sed 's/|$//' || echo "")

# 3. 标题: 优先用 frontmatter 里的 H1
TITLE=$(head -1 "$TEMP" | sed 's/^# //' | sed 's/[[:space:]]*$//')
if [[ -z "$TITLE" ]]; then
  TITLE=$(echo "$SLUG" | tr '-' ' ')
fi

# 4. 生成目标文件 (加 frontmatter)
cat > "$DEST" <<EOF
---
title: "$TITLE"
date: $SRC_DATE
original_author: "$SRC_AUTHOR"
original_tags: $SRC_TAGS
public: true
desensitized: basic-only  # 仅做了基础脱敏, 人工 review 必须
---

EOF
cat "$TEMP" >> "$DEST"

# ---------- 报告 ----------
echo "✅ 同步完成"
echo "   源: $SRC"
echo "   目标: $DEST"
echo
echo "📋 下一步 (人工):"
echo "   1. 打开文件 review 脱敏结果: $DEST"
echo "   2. 修改 frontmatter 的 title / tags"
echo "   3. 重写为博文风格 (去 AI 味, 调整 frontmatter 上的 desensitized: manual)"
echo "   4. 更新索引: $PUBLIC_REPO/docs/articles.md"
echo "   5. 提交触发部署:"
echo "        cd $PUBLIC_REPO"
echo "        git add docs/articles/$TARGET_NAME docs/articles.md"
echo "        git commit -m 'publish: $BASENAME'"
echo "        git push"
