#!/usr/bin/env python3
"""Creart AI 图片生成脚本"""

import argparse
import base64
import json
import os
import sys
import urllib.request
import urllib.error


API_URL = "https://creart.ai/api/v1/image/generate"
_REDACT = "[REDACTED]"

VALID_RATIOS = [
    "1:1", "2:3", "3:2", "3:4", "4:3", "4:5", "5:4",
    "9:16", "16:9", "21:9", "1:4", "4:1", "1:8", "8:1",
]
VALID_SIZES = ["512", "512px", "1K", "2K", "3K", "4K"]
VALID_MODELS = [
    "nano-banana-pro", "nano-banana-2", "seedream-5.0-lite",
    "gpt-image-2",
    "qwen-image-plus", "qwen-image-2.0", "qwen-image-2.0-pro", "seedream-4.5",
]


def get_api_key():
    key_path = os.path.expanduser("~/.creart/api_key")
    try:
        with open(key_path, "r") as f:
            return f.read().strip()
    except FileNotFoundError:
        print("错误: 未找到 API Key 文件 (~/.creart/api_key)", file=sys.stderr)
        sys.exit(1)


def _resolve_output_path(path: str) -> str:
    directory = os.path.dirname(path) or "."
    os.makedirs(directory, exist_ok=True)
    if not os.path.exists(path):
        return path
    base, ext = os.path.splitext(path)
    i = 1
    while True:
        candidate = f"{base}_{i}{ext}"
        if not os.path.exists(candidate):
            return candidate
        i += 1


def generate(prompt: str, model: str, aspect_ratio: str, size: str, output: str):
    if not prompt.strip():
        print("错误: 提示词不能为空", file=sys.stderr)
        sys.exit(1)

    api_key = get_api_key()
    if not api_key:
        print("错误: API Key 文件为空 (~/.creart/api_key)", file=sys.stderr)
        sys.exit(1)

    body = {
        "contents": [{"parts": [{"text": prompt}]}],
        "generationConfig": {
            "responseModalities": ["IMAGE"],
            "imageConfig": {
                "aspectRatio": aspect_ratio,
                "imageSize": size,
            },
        },
        "model": model,
    }

    req = urllib.request.Request(
        API_URL,
        data=json.dumps(body).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req) as resp:
            result = json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8", errors="replace")
        try:
            err = json.loads(error_body)
            code = err.get("error", {}).get("code", "UNKNOWN")
            msg = err.get("error", {}).get("message", error_body)
        except json.JSONDecodeError:
            code = f"HTTP_{e.code}"
            msg = error_body
        print(f"错误 [{code}]: {msg}", file=sys.stderr)
        sys.exit(1)

    image_data = None
    for candidate in result.get("candidates", []):
        for part in candidate.get("content", {}).get("parts", []):
            if "inlineData" in part:
                image_data = part["inlineData"]["data"]
                break
        if image_data:
            break

    if not image_data:
        print("错误: 响应中未找到图片数据", file=sys.stderr)
        sys.exit(1)

    output = _resolve_output_path(output)
    with open(output, "wb") as f:
        f.write(base64.b64decode(image_data))

    print(f"图片已保存: {output}")


def main():
    parser = argparse.ArgumentParser(description="Creart AI 图片生成")
    parser.add_argument("prompt", help="图片描述提示词")
    parser.add_argument("--model", default="nano-banana-2", choices=VALID_MODELS, help="模型")
    parser.add_argument("--aspect-ratio", default="1:1", choices=VALID_RATIOS, help="宽高比")
    parser.add_argument("--size", default="1K", help="分辨率（预设：512, 512px, 1K, 2K, 3K, 4K；或自定义 WIDTHxHEIGHT 如 2000x1104）")
    parser.add_argument("--output", default="/tmp/creart_generated.png", help="输出文件路径")
    args = parser.parse_args()
    generate(args.prompt, args.model, args.aspect_ratio, args.size, args.output)


if __name__ == "__main__":
    main()
