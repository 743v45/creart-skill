#!/usr/bin/env bash
set -euo pipefail

# diff-references.sh — 分析 upstream references 与本地 references 的差异
# 退出码: 0=安全可复制 1=有CRITICAL问题 2=参数错误

FORCE=false
VERBOSE=false
DRY_RUN=false
UPSTREAM=""
LOCAL=""

usage() {
  echo "用法: diff-references.sh [--force] [--verbose] [--dry-run] <upstream_dir> <local_dir>"
  exit 2
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)   FORCE=true; shift ;;
    --verbose) VERBOSE=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    -*)        echo "未知选项: $1"; usage ;;
    *)
      if [[ -z "$UPSTREAM" ]]; then UPSTREAM="$1"
      elif [[ -z "$LOCAL" ]]; then LOCAL="$1"
      else echo "多余参数: $1"; usage
      fi
      shift
    esac
done

[[ -z "$UPSTREAM" || -z "$LOCAL" ]] && usage
[[ ! -d "$UPSTREAM" ]] && { echo "错误: upstream 目录不存在: $UPSTREAM"; exit 2; }

# 转为绝对路径（在 cd 之前）
UPSTREAM="$(cd "$UPSTREAM" && pwd)"
if [[ "$LOCAL" != /* ]]; then
  LOCAL="$(pwd)/$LOCAL"
fi

if command -v shasum &>/dev/null; then
  HASH_CMD="shasum -a 256"
else
  HASH_CMD="sha256sum"
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ── 阶段 A: 文件枚举与 Diff ──

cd "$UPSTREAM"
find . -type f -not -name '.*' | sed 's|^\./||' | sort > "$TMP/upstream.txt"
UP_COUNT=$(wc -l < "$TMP/upstream.txt" | tr -d ' ')

if [[ -d "$LOCAL" ]]; then
  cd "$LOCAL"
  find . -type f -not -name '.*' | sed 's|^\./||' | sort > "$TMP/local.txt"
  LC_COUNT=$(wc -l < "$TMP/local.txt" | tr -d ' ')
  cd "$UPSTREAM"
  comm -23 "$TMP/upstream.txt" "$TMP/local.txt" > "$TMP/added.txt"
  comm -13 "$TMP/upstream.txt" "$TMP/local.txt" > "$TMP/deleted.txt"
  comm -12 "$TMP/upstream.txt" "$TMP/local.txt" > "$TMP/common.txt"
  : > "$TMP/modified.txt"
  while IFS= read -r f; do
    up_h=$($HASH_CMD "$UPSTREAM/$f" 2>/dev/null | cut -d' ' -f1)
    lc_h=$($HASH_CMD "$LOCAL/$f" 2>/dev/null | cut -d' ' -f1)
    [[ "$up_h" != "$lc_h" ]] && echo "$f" >> "$TMP/modified.txt"
  done < "$TMP/common.txt"
else
  cp "$TMP/upstream.txt" "$TMP/added.txt"
  : > "$TMP/deleted.txt"
  : > "$TMP/common.txt"
  : > "$TMP/modified.txt"
  LC_COUNT=0
fi

ADD_COUNT=$(wc -l < "$TMP/added.txt" | tr -d ' ')
DEL_COUNT=$(wc -l < "$TMP/deleted.txt" | tr -d ' ')
MOD_COUNT=$(wc -l < "$TMP/modified.txt" | tr -d ' ')

# ── 阶段 B: 扩展名检查 ──
# 用 grep 一次性检查所有非 .md 文件

EXT_ISSUES=0
SCAN="$TMP/scan.txt"
: > "$SCAN"

# 合并新增+修改文件
cat "$TMP/added.txt" "$TMP/modified.txt" > "$TMP/to_scan.txt"
SCAN_COUNT=$(wc -l < "$TMP/to_scan.txt" | tr -d ' ')

if [[ "$SCAN_COUNT" -gt 0 ]]; then
  # 检查非 .md 扩展名
  NON_MD=$(grep -v '\.md$' "$TMP/to_scan.txt" || true)
  if [[ -n "$NON_MD" ]]; then
    while IFS= read -r f; do
      echo "CRITICAL:non-md-file:$f:" >> "$SCAN"
      EXT_ISSUES=$((EXT_ISSUES + 1))
    done <<< "$NON_MD"
  fi
fi

# ── 阶段 C: 内容安全扫描 ──
# 只扫描 .md 文件，批量 grep 提高效率

if [[ "$SCAN_COUNT" -gt 0 ]]; then
  SCAN_FILES=""
  while IFS= read -r f; do
    [[ -f "$UPSTREAM/$f" ]] && SCAN_FILES="$SCAN_FILES $UPSTREAM/$f"
  done < "$TMP/to_scan.txt"

  if [[ -n "$SCAN_FILES" ]]; then
    # CRITICAL: import 语句
    grep -Pn '^\s*(import\s+.+from|const\s+\S+\s*=\s*require\()' $SCAN_FILES 2>/dev/null | \
      sed 's|'"$UPSTREAM"'/||' | \
      while IFS=: read -r f n content; do
        echo "CRITICAL:import-stmt:$f:$n:$content"
      done >> "$SCAN" || true

    # CRITICAL: script 标签
    grep -Pn '<script' $SCAN_FILES 2>/dev/null | \
      sed 's|'"$UPSTREAM"'/||' | \
      while IFS=: read -r f n content; do
        echo "CRITICAL:script-tag:$f:$n:$content"
      done >> "$SCAN" || true

    # CRITICAL: 安装命令
    grep -Pn '(npm install|yarn add|pnpm add|pip install|brew install|cargo install)' $SCAN_FILES 2>/dev/null | \
      sed 's|'"$UPSTREAM"'/||' | \
      while IFS=: read -r f n content; do
        echo "CRITICAL:install-cmd:$f:$n:$content"
      done >> "$SCAN" || true

    # CRITICAL: 远程下载+管道
    grep -Pn '(curl|wget)\s+.*\|' $SCAN_FILES 2>/dev/null | \
      sed 's|'"$UPSTREAM"'/||' | \
      while IFS=: read -r f n content; do
        echo "CRITICAL:remote-fetch:$f:$n:$content"
      done >> "$SCAN" || true

    # WARNING: require() 引用
    grep -Pn 'require\(' $SCAN_FILES 2>/dev/null | \
      sed 's|'"$UPSTREAM"'/||' | \
      while IFS=: read -r f n content; do
        echo "WARNING:require-call:$f:$n:$content"
      done >> "$SCAN" || true

    # WARNING: 绝对路径
    grep -Pn '/(etc|usr|var|tmp|home)/' $SCAN_FILES 2>/dev/null | \
      sed 's|'"$UPSTREAM"'/||' | \
      while IFS=: read -r f n content; do
        echo "WARNING:absolute-path:$f:$n:$content"
      done >> "$SCAN" || true

    # WARNING: 家目录引用
    grep -Pn '~/[a-zA-Z]' $SCAN_FILES 2>/dev/null | \
      sed 's|'"$UPSTREAM"'/||' | \
      while IFS=: read -r f n content; do
        echo "WARNING:home-path:$f:$n:$content"
      done >> "$SCAN" || true

    # INFO: 外部 URL
    grep -Pn 'https?://' $SCAN_FILES 2>/dev/null | \
      sed 's|'"$UPSTREAM"'/||' | \
      while IFS=: read -r f n content; do
        echo "INFO:external-url:$f:$n:$content"
      done >> "$SCAN" || true
  fi
fi

CRITICAL_COUNT=$(grep -c '^CRITICAL:' "$SCAN" 2>/dev/null || true)
WARNING_COUNT=$(grep -c '^WARNING:' "$SCAN" 2>/dev/null || true)
INFO_COUNT=$(grep -c '^INFO:' "$SCAN" 2>/dev/null || true)
CRITICAL_COUNT=${CRITICAL_COUNT:-0}
WARNING_COUNT=${WARNING_COUNT:-0}
INFO_COUNT=${INFO_COUNT:-0}

# ── 阶段 D: 报告输出 ──

echo ""
echo "=== References Diff 分析 ==="
echo "Upstream: $UPSTREAM"
echo "Local:    $LOCAL"
echo ""
echo "--- 摘要 ---"
echo "Upstream 文件数:  $UP_COUNT"
echo "本地文件数:       $LC_COUNT"
echo "新增:             $ADD_COUNT"
echo "删除:             $DEL_COUNT"
echo "修改:             $MOD_COUNT"

if [[ "$ADD_COUNT" -gt 0 ]]; then
  echo ""
  echo "--- 新增文件 ---"
  while IFS= read -r f; do echo "  + $f"; done < "$TMP/added.txt"
fi

if [[ "$DEL_COUNT" -gt 0 ]]; then
  echo ""
  echo "--- 已删除文件（upstream 中不存在）---"
  while IFS= read -r f; do echo "  - $f"; done < "$TMP/deleted.txt"
fi

if [[ "$MOD_COUNT" -gt 0 ]]; then
  echo ""
  echo "--- 已修改文件 ---"
  while IFS= read -r f; do echo "  ~ $f"; done < "$TMP/modified.txt"
fi

echo ""
echo "--- 扩展名检查 ---"
if [[ "$EXT_ISSUES" -eq 0 ]]; then
  echo "  通过 -- 所有 $SCAN_COUNT 个文件均为 .md 格式"
else
  echo "  失败 -- 发现 $EXT_ISSUES 个非 .md 文件:"
  grep '^CRITICAL:non-md-file:' "$SCAN" | while IFS= read -r line; do
    f=$(echo "$line" | cut -d: -f4)
    echo "    $f"
  done
fi

echo ""
echo "--- CRITICAL 问题 ($CRITICAL_COUNT) ---"
if [[ "$CRITICAL_COUNT" -eq 0 ]]; then
  echo "  无"
else
  grep '^CRITICAL:' "$SCAN" | grep -v 'non-md-file' | while IFS= read -r line; do
    tag=$(echo "$line" | cut -d: -f2)
    f=$(echo "$line" | cut -d: -f3)
    n=$(echo "$line" | cut -d: -f4)
    content=$(echo "$line" | cut -d: -f5-)
    echo "  [$tag] $f:$n"
    echo "    $content"
  done
  [[ "$EXT_ISSUES" -gt 0 ]] && echo "  (另有 $EXT_ISSUES 个非 .md 文件，见上方扩展名检查)"
fi

echo ""
echo "--- WARNING 问题 ($WARNING_COUNT) ---"
if [[ "$WARNING_COUNT" -eq 0 ]]; then
  echo "  无"
else
  grep '^WARNING:' "$SCAN" | while IFS= read -r line; do
    tag=$(echo "$line" | cut -d: -f2)
    f=$(echo "$line" | cut -d: -f3)
    n=$(echo "$line" | cut -d: -f4)
    content=$(echo "$line" | cut -d: -f5-)
    echo "  [$tag] $f:$n"
    echo "    $content"
  done
fi

echo ""
echo "--- INFO 问题 ($INFO_COUNT) ---"
if [[ "$INFO_COUNT" -eq 0 ]]; then
  echo "  无"
elif [[ "$VERBOSE" == "true" ]]; then
  grep '^INFO:' "$SCAN" | while IFS= read -r line; do
    f=$(echo "$line" | cut -d: -f3)
    n=$(echo "$line" | cut -d: -f4)
    content=$(echo "$line" | cut -d: -f5-)
    echo "  [external-url] $f:$n"
    echo "    $content"
  done
else
  echo "  $INFO_COUNT 条 INFO 级别提示（使用 --verbose 查看）"
fi

# 结论
echo ""
echo "--- 结论 ---"
if [[ "$CRITICAL_COUNT" -gt 0 ]]; then
  if [[ "$FORCE" == "true" ]]; then
    echo "状态: FORCE 模式 -- 跳过 $CRITICAL_COUNT 个 CRITICAL 问题"
    echo "请确保你已审核上述所有 CRITICAL 问题。"
  else
    echo "状态: 阻止复制 -- 发现 $CRITICAL_COUNT 个 CRITICAL 问题"
    echo "请审核上述报告。确认安全后使用 --force 覆盖:"
    echo "  bash scripts/diff-references.sh --force \"$UPSTREAM\" \"$LOCAL\""
    exit 1
  fi
else
  echo "状态: 安全同步 (无 CRITICAL 问题)"
  [[ "$WARNING_COUNT" -gt 0 ]] && echo "WARNING 级别问题: $WARNING_COUNT (见上方 -- 审核并确认)"
fi

if [[ "$DRY_RUN" != "true" ]]; then
  if [[ "$CRITICAL_COUNT" -eq 0 || "$FORCE" == "true" ]]; then
    echo ""
    echo "正在复制 references ..."
    mkdir -p "$(dirname "$LOCAL")"
    rm -rf "$LOCAL"
    cp -r "$UPSTREAM" "$LOCAL"
    echo "复制完成: $LOCAL ($(find "$LOCAL" -type f | wc -l | tr -d ' ') 个文件)"
  fi
else
  echo ""
  echo "[dry-run] 未执行复制"
fi

echo ""
echo "完成。"
