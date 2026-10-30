# -*- coding: utf-8 -*-
"""把《针灸大成》Wikisource 导出文本整理成 App 古籍库的规范格式。

用法：
    python tool/import_zhenjiudacheng.py "D:/下载/針灸大成.txt"

源文件（UTF-8，约 25.7 万字）是 wikitext 导出：
  - 章标题是 `### 标题`
  - 卷标记是单独一行 `卷一` … `卷十二`
  - 夹着「目錄 / **針灸大成** / ◀上一卷 / 下一卷▶ / ---」等导航与版权行
  - 繁体

处理：
  1. 按 `###` 提章、按 `卷X` 归卷，标题合成 `卷X·章名`；
  2. 剔除目录、上下卷导航、版权与空章；
  3. 繁体 → 简体（zhconv，与 App 其余内容一致，保证简体关键词能搜到）；
  4. 输出 `assets/guji/zhenjiudacheng.txt`，格式与《灵枢》一致：
         ========================================
         卷一·鍼道源流（已转简）
         ========================================
         正文

⚠️ 换源或重新整理后，必须再跑 tool/build_classic_search_index.py 重建检索索引。
"""

import os
import re
import sys

import zhconv

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "guji", "zhenjiudacheng.txt")
DEFAULT_SRC = "D:/下载/針灸大成.txt"

_VOLUME = re.compile(r"^卷[一二三四五六七八九十]+$")
_IGNORED = {"目錄", "全書始", "**針灸大成**", "**針灸大成**"}


def parse(src_path):
    """返回 [(卷, 章名, 正文)]。"""
    with open(src_path, encoding="utf-8") as f:
        lines = f.read().splitlines()

    chapters = []
    volume = ""
    title = None
    body = []

    def flush():
        nonlocal title, body
        if title and body:
            chapters.append((volume, title, "\n".join(body)))
        title = None
        body = []

    for raw in lines:
        s = raw.strip()
        if not s:
            continue
        # 分隔线
        if set(s) <= {"-"}:
            continue
        # 章标题
        if s.startswith("### "):
            flush()
            title = s[4:].strip()
            continue
        # 卷标记
        if _VOLUME.match(s):
            flush()
            volume = s
            continue
        # 导航 / 目录 / 版权噪声
        if s in _IGNORED or s.startswith("◀") or s.startswith("下一卷"):
            continue
        if s.startswith("- "):  # 顶部目录的 bullet 列表
            continue
        if title is None:
            continue
        body.append(s)

    flush()
    return chapters


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SRC
    if not os.path.isfile(src):
        raise SystemExit("源文件不存在: " + src)

    chapters = parse(src)

    # 同名章去重（同一卷内重复出现时加序号，保留全部内容）
    seen = {}
    normalized = []
    for volume, title, body in chapters:
        key = (volume, title)
        seen[key] = seen.get(key, 0) + 1
        if seen[key] > 1:
            title = f"{title}（{seen[key]}）"
        normalized.append((volume, title, body))

    # 整本转简体
    out_lines = ["《针灸大成》", "", "明·杨继洲 著 · 针灸专著 · 原文（公版古籍）", ""]
    for volume, title, body in normalized:
        full_title = f"{volume}·{title}" if volume else title
        out_lines.append("=" * 40)
        out_lines.append(full_title)
        out_lines.append("=" * 40)
        out_lines.append(body)
        out_lines.append("")

    text = zhconv.convert("\n".join(out_lines).strip() + "\n", "zh-hans")
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)

    sizes = sum(len(b) for _, _, b in normalized)
    print(f"[OK] chapters={len(normalized)} chars={sizes}")
    print(f"[OK] -> {OUT}")


if __name__ == "__main__":
    sys.exit(main())
