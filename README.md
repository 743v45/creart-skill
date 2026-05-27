# Creart Prompt

高质量图像提示词顾问技能（Advisor Only）。基于结构化模板，为用户撰写可直接复用的高质量图像 prompt，涵盖 18 大类、94 个模板，覆盖海报 / UI / 产品 / 信息图 / 学术图 / 技术架构图 / 漫画 / 头像 / 流程板 / 电影分镜 / IP 周边 / 编辑工作流等场景。

## 工作方式

本 Skill 作为"prompt 撰写顾问"——按 **选模板 → 填字段 → 渲染最终 prompt** 流程走，缺信息就问用户，把最终 prompt 直接展示给用户并保存一份到 `creart-prompt/prompt/`。

它只做一件事：**为用户生成可直接复用的高质量图像 prompt**。不假装出图成功，明确告知用户 prompt 已生成，请用自己的图像工具执行。

## 模板覆盖

17 个分类目录 + 1 份方法论总文档，共 94 个模板文件：

| 分类 | 目录 | 典型场景 |
|------|------|----------|
| 方法论 | `prompt-writing.md` | 模板构造指南 |
| UI 样机 | `ui-mockups/` | 电商直播、社交界面、聊天界面、短视频封面、落地页 |
| 产品视觉 | `product-visuals/` | 爆炸视图、白底主图、影棚商业图、包装展示、生活方式场景 |
| 地图 | `maps/` | 美食地图、旅行路线、城市风貌、门店分布 |
| 幻灯片 | `slides-and-visual-docs/` | 讲解 Slide、政策公告、商业报告、教学示意图 |
| 海报 & Campaign | `poster-and-campaigns/` | 品牌海报、Campaign KV、banner、杂志封面 |
| 人物肖像 | `portraits-and-characters/` | 商务肖像、创始人媒体片、虚拟主播、角色设定稿 |
| 场景插画 | `scenes-and-illustrations/` | 治愈场景、概念大场景、绘本、极简氛围图 |
| 编辑工作流 | `editing-workflows/` | 背景替换、局部替换、去杂物、产品精修、人像编辑 |
| 头像 & 人设 | `avatars-and-profile/` | 风格迁移自拍、网格肖像、3D 图标、贴纸套装 |
| 分镜 & 序列 | `storyboards-and-sequences/` | 四格漫画、漫画分镜、TVC 分镜、电影叙事分镜 |
| 网格 & 拼贴 | `grids-and-collages/` | banner 套装、lookbook、多风格拼贴、pitch board |
| 品牌 & 包装 | `branding-and-packaging/` | 品牌识别板、吉祥物套装、化妆品包装、饮料标签 |
| 文字排版 | `typography-and-text-layout/` | 大字主张海报、双语版式 |
| 素材 & 道具 | `assets-and-props/` | 拟物图标集、游戏截图 mockup |
| 学术配图 | `academic-figures/` | 方法总览图、网络架构图、对比网格、Graphical Abstract |
| 信息图 | `infographics/` | 高密度科普、手绘信息图、对比信息图、KPI 仪表盘 |
| 技术图表 | `technical-diagrams/` | 系统架构、流程图、时序图、状态机、ER 图、思维导图、网络拓扑 |

## 目录结构

```
creart-prompt/
├── creart-prompt/
│   ├── SKILL.md              # 技能定义（工作流 + 模板索引 + 约束）
│   └── references/           # 结构化提示词模板（17 类 + 94 个文件）
│       ├── prompt-writing.md
│       ├── ui-mockups/
│       ├── product-visuals/
│       ├── maps/
│       └── ...
├── scripts/
│   └── diff-references.sh    # upstream references 同步 & 安全扫描脚本
├── garden-replicate.md       # 从 upstream 复刻/增量更新的标准流程
└── .garden-sync.json         # upstream 同步状态跟踪
```

## Upstream 同步

本项目从 [garden-skills](https://github.com/ConardLi/garden-skills) 的 `skills/gpt-image-2/` 提取 Advisor 模式相关内容，保持 prompt 模板同步。

同步流程详见 `garden-replicate.md`，核心步骤：

1. 验证 upstream 身份与 SHA
2. 用 `scripts/diff-references.sh` 做 dry-run 安全扫描
3. 确认无 CRITICAL 问题后同步 references 并提取 SKILL.md
4. 更新 `.garden-sync.json` 跟踪文件

```bash
# Dry-run 检查
bash scripts/diff-references.sh --dry-run "$UPSTREAM_ROOT/skills/gpt-image-2/references" "creart-prompt/references"

# 实际同步
bash scripts/diff-references.sh "$UPSTREAM_ROOT/skills/gpt-image-2/references" "creart-prompt/references"
```
