# Garden 复刻提示词

## 用途

当需要从 `$UPSTREAM_ROOT/skills/gpt-image-2/` 复刻或增量更新到本项目 `garden/` 目录时，按以下流程执行。

**核心原则：先验证，后操作。** 所有验证通过后才执行任何写入。

Mode C = Advisor 模式（纯提示词顾问）。本项只提取 Advisor 相关内容。

## 流程

### 阶段零：确定 upstream 目录

执行前必须先向用户确认 upstream 源目录。可能的值：

- `garden-skills` 仓库根目录（此时内部路径为 `skills/gpt-image-2/`）
- `garden-skills/skills/gpt-image-2/` 直接指向 skill 目录

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

读取 `garden/.garden-sync.json` 中的 `last_sha`。SHA 相同则无需更新。

#### 验证 2：references 目录安全

运行 diff 分析（dry-run，不实际复制）。脚本位于本项目 `scripts/diff-references.sh`：

```bash
UPSTREAM_REF="$UPSTREAM_ROOT/skills/gpt-image-2/references"
LOCAL_REF="garden/references"
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
LOCAL_REF="garden/references"
bash scripts/diff-references.sh "$UPSTREAM_REF" "$LOCAL_REF"
```

#### 执行 2：提取 SKILL.md（Advisor 精简版）

读取 upstream `skills/gpt-image-2/SKILL.md`，按以下规则提取到 `garden/SKILL.md`：

**保留（按语义识别，不依赖标题或步骤编号）**：
- frontmatter → name 改为 `creart-prompt`，description 需适配 advisor-only 语境，但能力描述部分（涵盖的类别、模板数量、场景等）保留原文
- 标题和简介 → 保留原文，仅去掉"模式"措辞
- Advisor 定义段落 → 保留原文，仅去掉"触发条件"措辞
- 用户输入工具相关内容
- 技能结构 → 只列 `references/`
- 输出目录 → 只保留 prompt 目录说明
- 命名规则 → 只保留 prompt 命名
- Prompt 保存规则 → 保留 Mode C 行原文（"用户拿走 prompt 自己执行，不落盘等于白干"），通用规则 4 条保留原文
- Advisor 相关用法示例
- JSON 模板工作方式
- 询问规则
- 模板索引（核心导航，完整保留）
- 提示词工作流 → 保留 Advisor 相关步骤，去掉模式判断/决策步骤，起始改为"直接进入 Advisor 工作流"
- 通用约束（与图片生成无关的部分）
- 提问时机规则

**通用原则**：未标注"保留原文"的保留项，默认保留原文，仅按指定条件做删减/过滤，不主动改写。

**删除（按语义识别）**：
- 图片生成/编辑相关的模式定义和用法
- 模式决策/判断逻辑（决策表、模式不确定时处理等）
- 任何脚本说明（check-mode 等）
- 环境变量配置
- 图片保存规则
- 图片生成专用约束

#### 执行 3：更新跟踪文件

写入 `garden/.garden-sync.json`：

```json
{
  "source": "$UPSTREAM_ROOT",
  "source_path": "skills/gpt-image-2",
  "last_sha": "<当前 SHA>",
  "last_sync_date": "<今天日期>",
  "mode": "advisor-only"
}
```

验证写入成功：`node -e "const s = require('./garden/.garden-sync.json'); console.log('SHA:', s.last_sha);"`

## 安全边界

以下情况暂停并告知用户，不要自动合并：
- upstream SKILL.md 结构性重构（Advisor 相关内容消失或语义合并）
- upstream 新增脚本依赖（不引入，仅提示用户）
