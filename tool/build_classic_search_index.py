# -*- coding: utf-8 -*-
"""生成「经典全文检索」索引（assets/guji/classic_index.json.gz）。

覆盖范围：
  - 倪师讲稿：assets/shanghan/*.md（伤寒论）、assets/jingui/*.md（金匮要略）、
    assets/neijing/*.md（黄帝内经）
  - 古籍原文：assets/guji/{lingshu,zhenjiudacheng}.txt
    （《针灸大成》由 tool/import_zhenjiudacheng.py 从 Wikisource 导出文本整理而来）

为什么要预生成：讲稿共 900+ 个 markdown、约 7MB，运行时逐个 rootBundle 读取会
卡顿数秒；预生成成单个 gzip 索引后，App 只需解压一次并在内存中做子串检索。

⚠️ 讲稿或古书有增删改时，必须重跑本脚本，否则搜索会漏内容：
    D:/Python310/python.exe tool/build_classic_search_index.py

输出结构：
  {"v": 1, "entries": [
     {"s": "shanghan|jingui|neijing", "t": 标题, "a": 资产路径, "x": 正文纯文本},
     {"s": "guji", "b": 书名 id, "t": 章节标题, "i": 章节序号, "x": 正文纯文本}
  ]}
"""

import gzip
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "guji", "classic_index.json.gz")

LECTURE_SOURCES = [
    ("shanghan", os.path.join(ROOT, "assets", "shanghan")),
    ("jingui", os.path.join(ROOT, "assets", "jingui")),
    ("neijing", os.path.join(ROOT, "assets", "neijing")),
]

GUJI_SOURCES = [
    ("lingshu", os.path.join(ROOT, "assets", "guji", "lingshu.txt")),
    ("zhenjiudacheng", os.path.join(ROOT, "assets", "guji", "zhenjiudacheng.txt")),
]

_MD_LINK = re.compile(r"\[([^\]]*)\]\([^)]*\)")
_SEP = re.compile(r"^=+\s*$")


def strip_markdown(text: str) -> str:
    """把 markdown 讲稿压成便于检索与摘要展示的纯文本。"""
    out = []
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            continue
        if line.startswith("#"):
            continue  # 标题行单独取
        line = line.lstrip("> ").strip()
        line = re.sub(r"^\s*([-*+]|\d+\.)\s+", "", line)
        line = _MD_LINK.sub(r"\1", line)
        line = line.replace("**", "").replace("`", "").replace("__", "")
        if line:
            out.append(line)
    return "\n".join(out)


def first_heading(text: str, fallback: str) -> str:
    for raw in text.splitlines():
        line = raw.strip()
        if line.startswith("#"):
            title = line.lstrip("#").strip()
            if title:
                return title
    return fallback


def build_lecture_entries():
    entries = []
    for src, folder in LECTURE_SOURCES:
        if not os.path.isdir(folder):
            raise SystemExit("缺少讲稿目录: " + folder)
        names = sorted(
            n for n in os.listdir(folder) if n.endswith(".md")
        )
        for name in names:
            path = os.path.join(folder, name)
            with open(path, encoding="utf-8") as f:
                raw = f.read()
            title = first_heading(raw, os.path.splitext(name)[0])
            body = strip_markdown(raw)
            if not body:
                # 部分讲稿文件只有一行标题（如单条伤寒条文），标题本身就是全部内容
                body = title
            entries.append(
                {
                    "s": src,
                    "t": title,
                    "a": "assets/" + src + "/" + name,
                    "x": body,
                }
            )
    return entries


def parse_guji(path: str):
    """解析古书原文，返回 [(章节标题, 正文)]。

    文本结构是「分隔线 / 章节标题 / 分隔线 / 正文 / 分隔线 / 标题 / 分隔线 / 正文…」，
    即每个标题被一对分隔线夹住。按分隔线切块后，第 1 块是书名，往后按
    (标题, 正文) 成对取。
    """
    with open(path, encoding="utf-8") as f:
        lines = f.read().splitlines()

    blocks = []
    current = []
    for raw in lines:
        if _SEP.match(raw.strip()):
            blocks.append(current)
            current = []
        else:
            current.append(raw)
    blocks.append(current)

    chapters = []
    # blocks[0] 是书名/前言，从 blocks[1] 起按 标题、正文 成对出现
    for i in range(1, len(blocks) - 1, 2):
        title = " ".join(x.strip() for x in blocks[i] if x.strip()).strip()
        body_lines = [x.strip() for x in blocks[i + 1] if x.strip()]
        body = "\n".join(body_lines)
        if title and body:
            chapters.append((title, body))
    return chapters


def build_guji_entries():
    entries = []
    for book_id, path in GUJI_SOURCES:
        if not os.path.isfile(path):
            raise SystemExit("缺少古书文件: " + path)
        for idx, (title, body) in enumerate(parse_guji(path)):
            entries.append({"s": "guji", "b": book_id, "t": title, "i": idx, "x": body})
    return entries


def main():
    lecture = build_lecture_entries()
    guji = build_guji_entries()
    payload = {"v": 1, "entries": lecture + guji}
    raw = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "wb") as fp:
        with gzip.GzipFile(filename="", mode="wb", fileobj=fp, mtime=0) as gz:
            gz.write(raw)

    chars = sum(len(e["x"]) for e in lecture + guji)
    print("[OK] entries=%d (lecture=%d, guji=%d)" % (len(lecture + guji), len(lecture), len(guji)))
    print("[OK] raw=%.1fMB gz=%.2fMB chars=%d" % (len(raw) / 1048576.0, os.path.getsize(OUT) / 1048576.0, chars))
    print("[OK] -> " + OUT)


if __name__ == "__main__":
    sys.exit(main())
