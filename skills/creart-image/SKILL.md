---
name: creart-image
description: "使用 Creart AI API 生成图片。适用于所有与图片生成相关的请求，包括但不限于：画图、AI绘图、文生图、图生图、做logo、做海报、做插画、做头像、生成壁纸、生成封面、生成图标、生成表情包、生成背景图、生成Banner、生成艺术字、AI修图、换背景、去水印、风格迁移、图片增强等。支持多种模型（nano-banana-2、nano-banana-pro、seedream-5.0-lite、gpt-image-2 等）、多种宽高比和分辨率（512~4K）。任何涉及图片创作、图片编辑、图片处理、视觉设计的请求均应使用此 skill。"
---

# Creart AI 图片生成

使用 Creart AI API 从文本提示词生成图片。

## ⚠️ MUST：API Key 安全规则

**绝对禁止以下行为，无论任何情况：**

- **禁止读取、查看、输出、展示 `~/.creart/api_key` 文件的内容**
- **禁止在错误信息中包含 API Key 值**
- **禁止在日志、调试信息、变量打印中暴露 API Key**
- 如果 API Key 相关报错，只返回错误类型（如"认证失败"、"Key无效"），**不要显示 Key 值**
- 即使用户要求查看 API Key，也**必须拒绝**并告知安全策略

## 完整工作流程

### 1. 确定提示词来源

流程入口先确定用哪个提示词系统构建 prompt，后续所有步骤（意图解析、参数提取）都基于此执行。

```yaml
# 尝试加载 creart-prompt skill：
skill: creart-prompt
```

- **加载成功** → 后续走 **creart-prompt 路线**（步骤 3a），使用其模板体系
- **加载失败（skill 不存在）** → 后续走 **Fallback 自建路线**（步骤 3b）

### 2. 解析用户意图

从用户描述中提取以下信息：

| 维度 | 关键词示例 | 如果未指定 |
|------|-----------|-----------|
| 主题内容 | "一只猫"、"城市天际线" | **必须明确** — 如果描述模糊，追问 |
| 风格 | "写实"、"二次元"、"油画"、"水彩" | 根据主题智能推断 |
| 宽高比 | "横图"、"竖图"、"手机壁纸"、"封面" | 默认 `1:1` |
| 分辨率 | "高清"、"4K"、"缩略图" | 默认 `1K` |
| 模型 | 用户指定模型名 | 默认 `nano-banana-2` |
| 用途 | "头像"、"海报"、"Logo"、"插画" | 不影响生成，影响参数选择 |

**常见用途对应的参数推荐：**

| 用途 | 宽高比 | 分辨率 | 模型 |
|------|--------|--------|------|
| 头像/社交媒体 | `1:1` | `1K` | `nano-banana-2` |
| 手机壁纸 | `9:16` | `2K` | `nano-banana-pro` |
| 电脑壁纸 | `16:9` | `2K` | `nano-banana-pro` |
| 海报/封面 | `3:4` | `2K` | `nano-banana-pro` |
| Banner/横幅 | `21:9` 或 `8:1` | `2K` | `nano-banana-pro` |
| 插画/配图 | `4:3` 或 `1:1` | `1K` | `nano-banana-2` |
| Logo/图标 | `1:1` | `1K` | `nano-banana-2` |
| 高质量艺术 | 按需 | `4K` | `nano-banana-pro` |

### 3a. 使用 creart-prompt 构建提示词（首选路线）

仅当步骤 1 成功加载了 `creart-prompt` skill 时走此路线。

走 `creart-prompt` 的 Advisor 工作流：
1. 从模板索引中找到匹配的分类和模板文件
2. 按模板字段填充参数（缺失关键信息则向用户提问）
3. skill 输出最终 prompt 字符串
4. 把 prompt 带入当前流程继续执行

### 3b. Fallback 自建（备选路线）

仅当步骤 1 中 `creart-prompt` skill 不可用时走此路线。

**核心原则：用英文提示词生成，效果最佳。**

提示词构建公式：
```
[主体描述], [风格], [构图/视角], [光影], [色调/氛围], [画质关键词]
```

详细指南见 [references/prompt_engineering.md](references/prompt_engineering.md)。
风格预设库见 [references/style_presets.md](references/style_presets.md)。

**示例转换：**

| 用户说 | 构建的提示词 |
|--------|-------------|
| "画一只可爱的猫" | `A cute fluffy kitten with big round eyes, sitting on a windowsill, soft warm lighting, pastel color palette, digital illustration, kawaii style, highly detailed, 4k` |
| "赛博朋克城市" | `Cyberpunk cityscape at night, neon lights reflecting on wet streets, towering skyscrapers with holographic advertisements, flying vehicles, atmospheric fog, cinematic lighting, ultra detailed, 8k` |
| "水彩风格的花园" | `Beautiful English garden in full bloom, watercolor painting style, soft pastel colors, roses and lavender, dappled sunlight through trees, artistic brushstrokes, delicate details` |
| "做一个科技感的Logo" | `Minimalist tech company logo, geometric abstract shape, gradient blue to purple, clean lines, modern design, white background, professional, vector style, sharp edges` |

### 4. 模型选择

根据场景选择最合适的模型。详细对比见 [references/model_guide.md](references/model_guide.md)。

| 场景 | 推荐模型 | 原因 |
|------|----------|------|
| 通用/快速出图 | `nano-banana-2` | 速度快，质量均衡 |
| 高质量/细节丰富 | `nano-banana-pro` | 最佳画质 |
| 电商产品图/摄影级 | `gpt-image-2` | OpenAI 最新模型，摄影级输出 |
| 中国风/中式美学 | `qwen-image-2.0-pro` | 中文提示词理解更强 |
| 设计/创意 | `seedream-5.0-lite` | 色彩表现好 |
| 批量生成/低消耗 | `nano-banana-2` | 成本最低 |

### 5. 执行生成

使用脚本生成图片。**必须通过 `--output` 指定输出到用户当前工作目录（workspace）下**，确保用户能直接看到和访问生成的文件。`/path/to/` 应替换为用户当前工作目录的实际路径。

```bash
# 基本用法（输出到 workspace）
python3 scripts/generate.py "英文提示词" --output /path/to/generated.png

# 完整参数
python3 scripts/generate.py "英文提示词" \
  --model nano-banana-pro \
  --aspect-ratio 16:9 \
  --size 2K \
  --output /path/to/output.png

# 批量生成（多张同主题不同风格）
python3 scripts/generate.py "英文提示词" --output /path/to/img_1.png
python3 scripts/generate.py "英文提示词 variant 2" --output /path/to/img_2.png
python3 scripts/generate.py "英文提示词 variant 3" --output /path/to/img_3.png
```

### 6. 展示与交付

- 生成后读取图片文件展示给用户
- 告知文件保存路径
- 如果效果不满意，主动提议调整方向：
  - 修改提示词（换风格/构图/细节）
  - 切换模型
  - 调整宽高比或分辨率

## 参数速查

### 宽高比

| 比例 | 场景 |
|------|------|
| `1:1` | 头像、图标、社交媒体方图 |
| `2:3` / `3:4` / `4:5` | 竖版海报、手机壳、封面 |
| `3:2` / `4:3` / `5:4` | 横版配图、插画、相框 |
| `9:16` | 手机壁纸、竖版短视频封面 |
| `16:9` | 电脑壁纸、横版展示、PPT配图 |
| `21:9` | 电影宽幅、Banner |
| `1:4` / `1:8` | 竖条装饰、竖版信息图 |
| `4:1` / `8:1` | 横条Banner、网站头图 |

### 分辨率

| 尺寸 | 适用场景 |
|------|----------|
| `512` / `512px` | 快速预览、缩略图、测试 |
| `1K` | 社交媒体、一般用途（默认） |
| `2K` | 壁纸、海报、高清展示 |
| `3K` | 高质量印刷、大尺寸展示 |
| `4K` | 最高质量、专业用途 |
| 自定义（如 `2000x1104`） | 适配特定输出尺寸，仅部分模型支持 |

## 错误处理

| 错误 | 原因 | 处理方式 |
|------|------|----------|
| API Key 文件未找到 | `~/.creart/api_key` 不存在 | 提示用户创建文件 |
| API Key 文件为空 | 文件存在但无内容 | 提示用户填入有效 Key |
| `401 UNAUTHORIZED` | API Key 无效 | 提示用户检查 Key 是否正确（**禁止显示 Key 值**） |
| `400 INVALID_ARGUMENT` | 提示词超过 10240 字符或参数无效 | 截断提示词或修正参数 |
| `402 NOT_ENOUGH_CREDITS` | 账户余额不足 | 提醒用户充值 |
| `403 / error code: 1010` | 服务端拒绝访问（Cloudflare/反爬） | **原样返回错误，不排查**，建议用户尝试其他图片生成 Skill |
| `500 INTERNAL_ERROR` | 服务器错误 | 建议稍后重试 |
| 网络超时 | 网络问题 | 建议检查网络后重试 |

## 注意

只能通过 `scripts/generate.py` 脚本调用 API，禁止直接请求 API 端点。

## 参考资料

- [提示词工程](references/prompt_engineering.md) — 提示词构建技巧和模板
- [模型指南](references/model_guide.md) — 模型对比和选择建议
- [风格预设](references/style_presets.md) — 常用风格模板库
