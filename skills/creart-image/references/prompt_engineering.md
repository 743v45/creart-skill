# 提示词工程指南

## 各维度关键词库

### 主体描述

直接描述画面内容，要具体而非抽象：

| 级别 | 示例 |
|------|------|
| 太模糊 | "一只猫" |
| 一般 | "一只橘猫坐在窗台上" |
| 好 | "一只毛茸茸的橘猫坐在阳光明媚的窗台上，窗外是花园" |

### 风格关键词

| 风格 | 英文关键词 |
|------|-----------|
| 写实摄影 | `photorealistic, DSLR photo, shot on Canon EOS, natural photography` |
| 数字插画 | `digital illustration, digital art, concept art` |
| 油画 | `oil painting, canvas texture, classical painting, brush strokes` |
| 水彩 | `watercolor painting, soft washes, wet on wet technique, paper texture` |
| 二次元/动漫 | `anime style, cel shading, manga illustration, vibrant colors` |
| 3D 渲染 | `3D render, CGI, octane render, unreal engine, ray tracing` |
| 像素风 | `pixel art, retro game style, 8-bit, low resolution aesthetic` |
| 线稿 | `line art, sketch, pencil drawing, monochrome, clean lines` |
| 极简 | `minimalist, flat design, simple shapes, limited color palette` |
| 赛博朋克 | `cyberpunk, neon lights, futuristic, dark atmosphere, high tech` |
| 蒸汽朋克 | `steampunk, brass gears, Victorian era, mechanical, copper tones` |
| 中国风 | `Chinese ink painting, traditional oriental style, ink wash, silk scroll` |
| 扁平插画 | `flat illustration, vector style, geometric shapes, bold colors` |
| 照片级渲染 | `hyperrealistic, ultra detailed, macro photography, studio lighting` |

### 构图与视角

| 类型 | 英文关键词 |
|------|-----------|
| 特写 | `close-up, macro shot, extreme close-up` |
| 半身 | `portrait shot, upper body, medium shot` |
| 全身 | `full body shot, head to toe` |
| 广角 | `wide angle, panoramic view, sweeping vista` |
| 鸟瞰 | `bird's eye view, aerial view, top-down perspective` |
| 仰视 | `low angle shot, looking up, worm's eye view` |
| 居中对称 | `centered composition, symmetrical, front view` |
| 三分法 | `rule of thirds, off-center subject` |
| 前景遮挡 | `foreground framing, depth of field, bokeh background` |

### 光影效果

| 类型 | 英文关键词 |
|------|-----------|
| 自然光 | `natural lighting, soft diffused light` |
| 黄金时刻 | `golden hour, warm sunset light, amber glow` |
| 蓝调时刻 | `blue hour, twilight, cool tones` |
| 工作室灯光 | `studio lighting, professional lighting setup, softbox` |
| 逆光 | `backlit, silhouette, rim lighting, halo effect` |
| 戏剧性 | `dramatic lighting, chiaroscuro, high contrast` |
| 霓虹 | `neon lighting, colorful glow, RGB lights` |
| 体积光 | `volumetric lighting, god rays, light shafts` |
| 月光 | `moonlight, night scene, cool blue tones` |

### 色调与氛围

| 类型 | 英文关键词 |
|------|-----------|
| 温暖 | `warm tones, amber, golden, cozy atmosphere` |
| 冷调 | `cool tones, blue, teal, cold atmosphere` |
| 柔和 | `pastel colors, soft palette, gentle, dreamy` |
| 鲜艳 | `vibrant colors, saturated, bold, eye-catching` |
| 黑白 | `black and white, monochrome, noir` |
| 复古 | `vintage color grading, film grain, faded, retro` |
| 暗黑 | `dark mood, moody, desaturated, somber` |
| 梦幻 | `ethereal, dreamlike, fantasy, magical glow` |

### 画质关键词

始终在提示词末尾添加：

```
highly detailed, sharp focus, 8k resolution, masterpiece
```

根据风格选择性添加：
- 写实：`RAW photo, realistic, natural`
- 插画：`clean lines, crisp details`
- 艺术风格：`artistic, expressive, skillfully crafted`

## 提示词模板

### 人像

```
Portrait of [人物描述], [表情/动作], [服装/配饰], [背景环境], [风格], [光影], [色调], highly detailed, sharp focus, 8k
```

### 风景

```
[场景描述], [天气/时间], [自然元素], [风格], [视角], [光影], [色调], highly detailed, panoramic, 8k
```

### 产品/物体

```
[物品描述], [材质/纹理], [背景], [风格], studio lighting, [色调], highly detailed, professional product photography, 8k
```

### Logo/图标

```
[品牌/概念] logo design, [形状描述], [配色], [风格], clean background, minimalist, professional, vector style, sharp edges
```

### 建筑/室内

```
[建筑/空间描述], [风格], [视角], [光影], [氛围], architectural photography, highly detailed, 8k
```

### 抽象/概念

```
Abstract [概念], [形状/纹理], [色彩], [风格], [氛围], artistic, creative, flowing forms
```

## 注意事项

- 提示词最长 10240 字符，一般 100-300 词效果最佳
- 英文提示词效果通常优于中文
- 避免使用否定词（"no"、"without"），改用正面描述
- 同一种概念不要重复描述，选一个最精确的表达
- 主体描述放在最前面，画质关键词放在最后面
