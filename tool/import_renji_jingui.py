#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""《人纪·金匮要略》书面整理版讲稿入库脚本。

源: D:/nhx/人纪-金匮要略-倪海厦.txt（书面化授课实录，## 按篇分章）
产物:
  1. assets/jingui_lecture/NNN_篇名.md   —— 按篇切分；>4 万字的篇按空行段落
     均分为（上/中/下），保证手机端 markdown 渲染不卡。
  2. lib/data/jingui_lecture_data.dart   —— JinGuiBookLecture + kJinGuiBookLectures。

源文件三处已知缺陷（2026-11-03 实测）：
  - 第三篇（百合狐惑阴阳毒）缺 `## ` 标题，正文内联介绍行「接来下介绍第三篇」；
  - 第九篇（胸痹）标题与正文粘连在一行，且带 `-[这篇治所有心脏病]` 注；
  - 第十五篇（黄疸）缺 `## ` 标题，起始行「黄疸病，意思就是黄色的病」。
  脚本用文本锚点注入边界（一次性入库，锚点写死可接受）。
"""

import io
import json
import os
import re

SRC = r"D:/nhx/人纪-金匮要略-倪海厦.txt"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "jingui_lecture")
DART_OUT = os.path.join(ROOT, "lib", "data", "jingui_lecture_data.dart")
MAX_CHARS = 40000  # 单文件字数上限，超出按空行段落均分

# 缺失标题的文本锚点 → 注入的篇名（按文中出现顺序）
INJECTED = [
    (re.compile(r"^接来下介绍第三篇"), "百合狐惑阴阳毒病脉证治第三"),
    (re.compile(r"^黄疸病，意思就是"), "黄疸病脉证并治第十五"),
]
# 标题与正文粘连的行（第九篇）：匹配即以此行为界，行内 [注] 后的文字归正文
GLUED = re.compile(r"^胸痹心痛短气病脉证并治第九-\[([^\]]*)\](.*)$")


def clean_title(s: str) -> str:
    """去拼音注/空格，得篇名。"""
    s = re.sub(r"\[[^\]]*\]", "", s)          # 痉湿暍[yē]… → 痉湿暍…
    s = re.sub(r"\s+", "", s)
    return s.strip()


def split_sections(lines):
    """按 `## ` 标题 + 3 处锚点切成 [(篇名, 正文行列表)]。"""
    sections = []
    cur_title = None
    cur_body = []

    def flush():
        if cur_title is not None and cur_body:
            sections.append((cur_title, list(cur_body)))
        cur_body.clear()

    for ln in lines:
        if ln.startswith("## "):
            flush()
            cur_title = clean_title(ln[3:])
            continue
        m = GLUED.match(ln)
        if m:
            flush()
            cur_title = clean_title("胸痹心痛短气病脉证并治第九")
            note, rest = m.group(1), m.group(2).strip()
            if rest:
                cur_body.append(f"> 注：{note}" if note else "")
                cur_body.append(rest)
            continue
        hit = next((t for p, t in INJECTED if p.match(ln)), None)
        if hit:
            flush()
            cur_title = hit
            cur_body.append(ln)  # 介绍行保留为正文首段
            continue
        cur_body.append(ln)
    flush()
    return sections


def clean_body(text: str) -> str:
    """正文清洗：网页垃圾块 / B 站视频集标记 / 时间戳链接 / 裸 URL。"""
    # ① 网页粘贴垃圾块（藜芦百科段）：起始锚行 → 落款行整块删除（带 200 行保险）
    out, skip, guard = [], False, 0
    for ln in text.split("\n"):
        if not skip and re.search(r"的功效与作用.*http", ln):
            skip, guard = True, 0
            continue
        if skip:
            guard += 1
            if "本文由中医药网整理或引用" in ln or guard > 200:
                skip = False
            continue
        out.append(ln)
    text = "\n".join(out)
    # ② markdown 链接解包（保留标签；兼容半/全角右括号）
    text = re.sub(r"\[([^\]]*)\]\(https?://[^\s）)]*[）)]?", r"\1", text)
    # ③ 视频集标记：独立引用行删整行；段内粘连删片段；（第N集视频完）删
    text = re.sub(r"^\s*>\s*\*\*视频第\d+集\*\*（[^）]*）\s*$", "", text, flags=re.M)
    text = re.sub(r"\s*\*?\*?视频第\d+集\*?\*?（DVD\d*）", "", text)
    text = re.sub(r"（第\d+集视频完）", "", text)
    # ④ 时间戳 token 与裸 URL
    text = re.sub(r"（\d{1,2}:\d{2}）", "", text)
    text = re.sub(r"https?://\S+", "", text)
    # ⑤ 连续空行压缩
    return re.sub(r"\n{3,}", "\n\n", text).strip()


def split_big(title, body_lines):
    """超长篇按空行段落边界均分；返回 [(子篇名, 正文)]。"""
    text = "\n".join(body_lines).strip()
    if len(text) <= MAX_CHARS:
        return [(title, text)]
    # 段落 = 空行分隔的块
    paras = re.split(r"\n\s*\n", text)
    n_parts = -(-len(text) // MAX_CHARS)  # ceil
    target = len(text) / n_parts
    parts, buf, size = [], [], 0
    for p in paras:
        buf.append(p)
        size += len(p)
        if size >= target and len(parts) < n_parts - 1:
            parts.append("\n\n".join(buf))
            buf, size = [], 0
    if buf:
        parts.append("\n\n".join(buf))
    suffixes = ["上", "中", "下"] if n_parts == 3 else (
        ["上", "下"] if n_parts == 2 else [f"（{c}）" for c in "一二三四五六"])
    assert len(parts) <= len(suffixes), f"{title} 切 {len(parts)} 段超上限"
    return [(f"{title}·{s}" if n_parts <= 3 else f"{title}{s}", t)
            for s, t in zip(suffixes, parts)]


def sanitize_filename(s: str) -> str:
    return re.sub(r"[\\/:*?\"<>|]", "", s)


def write_dart(items):
    lines = [
        "/// 《人纪·金匮要略》书面整理版讲稿索引（由 tool/import_renji_jingui.py 生成，勿手改）。",
        "/// 篇文件 assets/jingui_lecture/NNN_篇名.md。与 assets/jingui/ 条文卡并列：",
        "/// 条文卡=逐条速查（「见于经典」依赖），本库=书面版系统通读。",
        "library;",
        "",
        "import 'classic_lecture_data.dart';",
        "",
        "class JinGuiBookLecture implements LectureIndex {",
        "  @override",
        "  final int seq;",
        "  @override",
        "  final String name;",
        "  @override",
        "  final String asset;",
        "",
        "  const JinGuiBookLecture({",
        "    required this.seq,",
        "    required this.name,",
        "    required this.asset,",
        "  });",
        "}",
        "",
        "const List<JinGuiBookLecture>kJinGuiBookLectures = [",
    ]
    for it in items:
        lines.append(
            "  JinGuiBookLecture(seq: %d, name: '%s', asset: '%s'),"
            % (it["seq"], it["name"], it["asset"])
        )
    lines.append("];")
    io.open(DART_OUT, "w", encoding="utf-8", newline="\n").write(
        "\n".join(lines) + "\n"
    )


def main():
    src = io.open(SRC, encoding="utf-8").read()
    lines = src.split("\n")

    # 1) 切篇（含锚点补标）
    sections = split_sections(lines)

    # 2) 超长篇二次均分
    items, seq = [], 0
    for title, body in sections:
        if title == "倪海厦传记":
            display = "总论·倪海厦传记"
        else:
            display = title
        for sub_title, sub_text in split_big(display, body):
            sub_text = clean_body(sub_text)
            if len(sub_text) < 500:  # 清洗后只剩空壳的段不落盘
                continue
            name = sanitize_filename(sub_title)
            asset = f"assets/jingui_lecture/{seq:03d}_{name}.md"
            items.append({"seq": seq, "name": sub_title, "asset": asset,
                          "text": f"# {sub_title}\n\n{sub_text}\n"})
            seq += 1

    # 3) 落盘（孤儿清理：删掉不在本次产物内的旧 md）
    os.makedirs(OUT_DIR, exist_ok=True)
    keep = {os.path.basename(it["asset"]) for it in items}
    for old in os.listdir(OUT_DIR):
        if old.endswith(".md") and old not in keep:
            os.remove(os.path.join(OUT_DIR, old))
    for it in items:
        path = os.path.join(ROOT, it["asset"])
        io.open(path, "w", encoding="utf-8", newline="\n").write(it["text"])

    write_dart(items)

    print(f"篇数: {len(items)}")
    total = sum(len(it["text"]) for it in items)
    print(f"总字数: {total}")
    for it in items:
        print(f"{it['seq']:>4} {it['name']}  ({len(it['text'])})")


if __name__ == "__main__":
    main()
