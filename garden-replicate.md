# Garden 复刻提示词

## 用途

`creart-prompt` 是一个 Advisor-only 提示词技能：基于结构化模板为用户撰写可直接复用的高质量图像 prompt。模板素材来源于 upstream `@conardli/garden-skills` 的 `skills/gpt-image-2/references/`。

当需要从 upstream 同步 references 或更新 SKILL.md 时，按以下流程执行。

**核心原则：先验证，后操作，再审查。** 验证通过才操作，操作完成后必须审查并向用户分级报告。

## 审查结果分级

审查阶段发现的问题按以下分级告知用户：

| 级别 | 标记 | 含义 | 处理方式 |
|------|------|------|----------|
| 💡 提示 | `[INFO]` | 仅供参考，无需行动 | 直接报告，继续 |
| ⚠️ 警告 | `[WARN]` | 建议关注，非阻塞 | 报告并询问是否调整 |
| 🚫 必须调整 | `[MUST]` | 阻塞问题，不修复则不可交付 | 暂停，修复后重新审查 |

## 流程

### 阶段零：确定 upstream 目录

执行前必须先向用户确认 upstream 源目录。可能的值：

- upstream 仓库根目录（此时内部路径为 `skills/gpt-image-2/`）
- 直接指向 upstream skill 目录

使用 `AskUserQuestion` 询问用户，提供以下选项：

1. 让用户输入完整路径
2. 检测本机常见位置并让用户确认

将用户提供的路径存储为 `UPSTREAM_ROOT`，后续所有 `$UPSTREAM_ROOT` 替换为该值。

**不自动搜索、不猜测路径。**

### 阶段一：验证（全部通过才继续）

#### 验证 1：upstream 身份 + SHA

验证目标目录确实是 garden-skills：

```bash
node -e "const p = require('$UPSTREAM_ROOT/package.json'); if (p.name !== '@conardli/garden-skills') { console.error('Not garden-skills:', p.name); process.exit(1); } console.log('OK:', p.name, 'v' + p.version);"
```

读取当前 HEAD SHA：

```bash
cd $UPSTREAM_ROOT && git rev-parse HEAD
```

读取 `.garden-sync.json` 中的 `last_sha`。SHA 相同则无需更新。

#### 验证 2：references 目录安全

运行 diff 分析（dry-run，不实际复制）。脚本位于本项目 `scripts/diff-references.sh`：

```bash
UPSTREAM_REF="$UPSTREAM_ROOT/skills/gpt-image-2/references"
LOCAL_REF="creart-prompt/references"
bash scripts/diff-references.sh --dry-run "$UPSTREAM_REF" "$LOCAL_REF"
```

确认无 CRITICAL 问题。有 CRITICAL 则暂停，审核后决定是否 `--force`。

#### 验证 3：SKILL.md 核心内容完整

确认 upstream SKILL.md 存在且包含 Advisor 所需的核心内容：

```bash
SKILL="$UPSTREAM_ROOT/skills/gpt-image-2/SKILL.md"

# 文件存在
test -f "$SKILL" || { echo "错误: SKILL.md 不存在"; exit 1; }

# 核心语义检查（不依赖具体标题文本）
grep -qi 'advisor\|顾问' "$SKILL" || echo "警告: 未找到 Advisor 相关内容"
grep -qi '模板\|template' "$SKILL" || echo "警告: 未找到模板相关内容"
grep -qi '提示词\|prompt.*workflow\|工作流' "$SKILL" || echo "警告: 未找到提示词工作流相关内容"
grep -qi '约束\|constraint\|限制' "$SKILL" || echo "警告: 未找到约束相关内容"
```

任何核心内容缺失 → 暂停，报告问题，不自动合并。

---

### 阶段二：执行（验证全部通过后）

> 以下操作仅在阶段一全部验证通过后执行。

#### 执行 1：同步 references/

脚本位于本项目 `scripts/diff-references.sh`：

```bash
UPSTREAM_REF="$UPSTREAM_ROOT/skills/gpt-image-2/references"
LOCAL_REF="creart-prompt/references"
bash scripts/diff-references.sh "$UPSTREAM_REF" "$LOCAL_REF"
```

#### 执行 2：生成 SKILL.md

`creart-prompt/SKILL.md` 是 Advisor-only 技能定义。从 upstream `skills/gpt-image-2/SKILL.md` 提取，按以下规则适配。

**SKILL.md 包含的内容**：

- **frontmatter** — name 为 `creart-prompt`；description 适配 advisor-only 语境，能力描述部分（涵盖的类别、模板数量、场景等）保留原文
- **标题和简介** — 保留原文，去掉"模式"措辞，表述为"这是一个面向图像提示词撰写的聚焦型技能"
- **Advisor 定义** — 保留原文行为描述，去掉"触发条件"措辞
- **用户输入工具** — 原文保留
- **技能结构** — 只列 `references/`，删除 upstream 中的所有脚本条目（check-mode.js、generate.js、edit.js、shared.js）
- **输出目录** — 只保留 prompt 目录（`creart-prompt/prompt/`）
- **命名规则** — 只保留 prompt 命名
- **Prompt 保存规则** — 将 Mode C 行的标签改为 `Advisor`，保留说明文字原文（"用户拿走 prompt 自己执行，不落盘等于白干"），通用规则 4 条保留原文
- **Advisor 用法** — 保留原文行为描述和使用建议
- **JSON 模板工作方式** — 原文保留
- **询问规则** — 原文保留
- **模板索引** — 原文完整保留（核心导航），但需过滤掉 `editing-workflows` 整个分类（advisor-only 模式无 `scripts/edit.js`，编辑模板无意义）以及对脚本的引用（如 `（对应 scripts/edit.js）`）；删除后重新编号，frontmatter 大类数量同步更新
- **提示词工作流** — 保留 Advisor 相关步骤，起始改为"直接进入 Advisor 工作流"，去掉模式判断/决策步骤
- **通用约束** — 与图片生成无关的部分保留
- **提问时机规则** — 原文保留

**SKILL.md 不包含的内容**：

- 图片生成/编辑相关的模式定义和用法（Mode A、Mode B）
- 模式决策/判断逻辑（决策表、模式不确定时处理等）
- 脚本说明（check-mode、generate.js、edit.js 等）
- `editing-workflows` 模板索引条目（依赖 `scripts/edit.js`，advisor-only 不携带）
- 环境变量配置
- 图片保存规则
- 图片生成专用约束

**通用原则**：如无必要，不改原文。仅做必要的删减（去掉与图片生成/编辑相关的段落）和适配（路径、名称、去掉模式措辞），不主动改写表述。

**upstream 新增 section 的判断原则**：如果 upstream 新增了上述 "包含" / "不包含" 列表之外的段落，按以下规则判断——内容在 advisor-only 语境下仍然适用（不依赖脚本调用、图片生成 API、模式决策）则保留，否则排除。不确定时报告用户。

**路径替换**：upstream 中所有 `garden-gpt-image-2/prompt/` 替换为 `creart-prompt/prompt/`。

#### 执行 3：更新跟踪文件

写入 `.garden-sync.json`（项目根目录）：

```json
{
  "source": "$UPSTREAM_ROOT",
  "source_path": "skills/gpt-image-2",
  "last_sha": "<当前 SHA>",
  "last_sync_date": "<今天日期>",
  "mode": "advisor-only"
}
```

验证写入成功：`node -e "const s = require('./.garden-sync.json'); console.log('SHA:', s.last_sha);"`

---

### 阶段三：审查（执行完成后必须执行）

对照以下检查项逐项审查，结果按分级标准（`[INFO]` / `[WARN]` / `[MUST]`）汇总报告给用户。

#### 审查 1：references 完整性

```bash
UPSTREAM_COUNT=$(find "$UPSTREAM_ROOT/skills/gpt-image-2/references" -name '*.md' | wc -l | tr -d ' ')
LOCAL_COUNT=$(find creart-prompt/references -name '*.md' | wc -l | tr -d ' ')
echo "upstream: $UPSTREAM_COUNT, local: $LOCAL_COUNT"
```

- `[MUST]` 本地文件数 < upstream 文件数 → 有文件丢失，不可交付
- `[INFO]` 数量一致 → 正常

#### 审查 1.5：references 不含不适用分类

advisor-only 模式不携带任何脚本。逐一检查 `creart-prompt/references/` 下的分类目录，确认其中模板不依赖不存在的脚本或功能：

```bash
# 检查每个本地目录在过滤配置中是否有对应条目
# 过滤配置: scripts/sync-filter.txt
# 如果某个分类的模板依赖脚本（如 scripts/edit.js）但过滤配置未排除它，则报告

# 示例：扫描所有已同步目录，检查是否包含脚本引用
grep -rl 'scripts/' creart-prompt/references/ 2>/dev/null | \
  sed 's|creart-prompt/references/||;s|/.*||' | sort -u | \
  while read -r dir; do
    grep -q "$dir" scripts/sync-filter.txt 2>/dev/null || echo "[MUST] $dir 包含脚本引用但未在 sync-filter.txt 中排除"
  done
```

发现不适用分类时的处理流程：

1. 将该分类目录加入 `scripts/sync-filter.txt`（一行一个 rsync exclude 模式）
2. 删除 `creart-prompt/references/` 下对应目录
3. 从 SKILL.md 模板索引中移除该条目，重新编号
4. 重新执行本审查

- `[MUST]` 存在依赖脚本但未过滤的分类 → 按上述流程处理后重新审查
- `[INFO]` 无不适用分类 → 正常

#### 审查 2：SKILL.md 结构检查

逐项确认生成的 SKILL.md 包含所有必要段落：

```bash
SKILL="creart-prompt/SKILL.md"
grep -qi 'advisor\|顾问' "$SKILL" || echo "[WARN] 缺少 Advisor 定义"
grep -qi '模板索引' "$SKILL" || echo "[WARN] 缺少模板索引"
grep -qi '工作流' "$SKILL" || echo "[WARN] 缺少提示词工作流"
grep -qi '约束' "$SKILL" || echo "[WARN] 缺少约束"
grep -qi '询问规则' "$SKILL" || echo "[WARN] 缺少询问规则"
grep -qi 'JSON.*模板' "$SKILL" || echo "[WARN] 缺少 JSON 模板工作方式"
grep -qi '用户输入工具' "$SKILL" || echo "[WARN] 缺少用户输入工具"
grep -qi '技能结构' "$SKILL" || echo "[WARN] 缺少技能结构"
grep -qi '输出目录' "$SKILL" || echo "[WARN] 缺少输出目录"
grep -qi '命名规则' "$SKILL" || echo "[WARN] 缺少命名规则"
grep -qi '保存规则' "$SKILL" || echo "[WARN] 缺少 Prompt 保存规则"
grep -qi '何时提问' "$SKILL" || echo "[WARN] 缺少提问时机规则"
```

- `[MUST]` 缺少 Advisor 定义或模板索引 → 核心内容丢失，不可交付
- `[WARN]` 缺少其他段落 → 建议补全

#### 审查 3：SKILL.md 无残留

确认 SKILL.md 中不包含应删除的内容：

```bash
SKILL="creart-prompt/SKILL.md"
grep -qi 'Mode A\|Mode B\|Mode C\|模式决策\|三种模式\|仅 Mode A\|check-mode\|generate\.js\|edit\.js\|shared\.js\|ENABLE_GARDEN\|OPENAI_API\|OPENAI_BASE\|images/generations\|images/edits\|scripts/' "$SKILL" && echo "[MUST] SKILL.md 包含应删除的图片生成相关内容" || echo "[INFO] 无残留"
```

- `[MUST]` 存在残留 → 必须清理后重新审查

#### 审查 4：路径已替换

```bash
SKILL="creart-prompt/SKILL.md"
grep -q 'garden-gpt-image-2' "$SKILL" && echo "[MUST] 路径未替换，仍包含 garden-gpt-image-2" || echo "[INFO] 路径替换完成"
```

- `[MUST]` 存在旧路径 → 必须替换后重新审查

#### 审查 5：跟踪文件有效

```bash
node -e "const s = require('./.garden-sync.json'); console.log('SHA:', s.last_sha, 'date:', s.last_sync_date, 'mode:', s.mode);"
```

- `[MUST]` SHA 为空或字段缺失 → 跟踪文件无效，不可交付
- `[INFO]` 字段完整 → 正常

#### 审查汇总

所有检查项完成后，按级别汇总输出。示例格式：

```
## 审查报告

[MUST] x 0
[WARN] x 2
  - 缺少询问规则段落
  - 缺少 JSON 模板工作方式段落
[INFO] x 3
  - references 数量一致（94/94）
  - 无残留内容
  - 路径替换完成

结论：🚫 有 WARN 项需确认是否调整
```

存在 `[MUST]` 项 → 修复后重新执行阶段三。
仅存在 `[WARN]` 项 → 报告用户，询问是否调整。
仅有 `[INFO]` 项 → 审查通过，交付完成。
