# -*- coding: utf-8 -*-
"""把《天纪》视频字幕切成按节独立的讲义 md（assets/tianji/lecture/）。

来源（只读）：D:/nhx/倪海厦/天纪/天纪视频字幕.md  （3637 行 / 1.3 MB）

清洗规则（结构经实测验证）：
  1. 目录区丢弃：首个「第X节 标题」（节后有空格）之前的全部内容。
     目录条目形如「第八节命相同参…………8」（节后直接接标题、带省略号与页码），
     正文标题形如「第八节 命相同参」（节后必有一个以上空格）——两类可精确区分。
  2. 页码行删除：整行仅 1-3 位数字（实测 300 行）。
  3. 按 ^第[一二三四五六七八九十百]+[节章]\\s+ 切分成节。

用法：
    python tool/import_tianji_lecture.py            # dry-run，只打印统计
    python tool/import_tianji_lecture.py --apply    # 真正写文件
"""

import os
import re
import sys

SRC = "D:/nhx/倪海厦/天纪/天纪视频字幕.md"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "tianji", "lecture")

HEAD = re.compile(r"^第([一二三四五六七八九十百]+)([节章])\s+")
PAGE = re.compile(r"^\s*\d{1,3}\s*$")
UNSAFE = re.compile(r'[\\/:*?"<>|“”‘’\'《》〈〉（）()、，。；：！？　]+')


def read_lines(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read().split("\n")


def split_sections(lines):
    """返回 [(标题, [正文行])]，自动丢弃目录区与页码行。"""
    start = next((i for i, l in enumerate(lines) if HEAD.match(l.strip())), None)
    if start is None:
        raise SystemExit("未找到正文起始标题（第X节 标题），请检查源文件格式")

    sections = []
    title, buf = None, []
    for raw in lines[start:]:
        line = raw.strip()
        m = HEAD.match(line)
        if m:
            if title is not None:
                sections.append((title, buf))
            title, buf = line, []
            continue
        if PAGE.match(line) or not line:
            continue
        buf.append(line)
    if title is not None:
        sections.append((title, buf))
    return sections


def safe_name(title):
    return UNSAFE.sub("", title).replace(" ", "_")


# 单篇上限：超过则按「整行（段落）累积」二次切分，绝不切断段落。
# 依据：原第五节之后无节级标题，整章 18 万字若作一篇，检索时只占 1 个命中位。
MAX_CHARS = 8000


def split_long(title, body_lines, limit=MAX_CHARS):
    """超长节按行累积切分，返回 [(标题, 行列表)]。"""
    if sum(len(l) for l in body_lines) <= limit:
        return [(title, body_lines)]
    chunks, cur, cur_len = [], [], 0
    for line in body_lines:
        if cur and cur_len + len(line) > limit:
            chunks.append(cur)
            cur, cur_len = [], 0
        cur.append(line)
        cur_len += len(line)
    if cur:
        chunks.append(cur)
    return [("%s（%d）" % (title, i + 1), c) for i, c in enumerate(chunks)]


def main():
    apply = "--apply" in sys.argv
    if not os.path.exists(SRC):
        raise SystemExit("源文件不存在: " + SRC)

    sections = split_sections(read_lines(SRC))

    # 展开超长节；丢弃无正文的纯章标题（如「第三章 人间道」后直接接节标题）
    expanded = []
    for title, body in sections:
        if not body:
            continue
        expanded.extend(split_long(title, body))

    print("切分结果：原始 %d 节 → 丢弃空章后 → 二次切分后 %d 篇"
          % (len(sections), len(expanded)))

    out = []
    short = []
    for idx, (title, body) in enumerate(expanded, 1):
        text = "\n\n".join(body).strip()
        chars = len(text)
        if chars < 200:
            short.append((idx, title, chars))
        name = "tianji_%02d_%s.md" % (idx, safe_name(title))
        out.append((name, title, text, chars))
        print("  %2d. %-26s %6d 字  %s" % (idx, title[:26], chars, name))

    total = sum(c for _, _, _, c in out)
    print("\n合计 %d 篇 / %d 字 / 平均 %d 字 / 最大 %d 字"
          % (len(out), total, total // max(1, len(out)), max(c for _, _, _, c in out)))
    if short:
        print("⚠️ 疑似过短（<200 字）：")
        for idx, title, chars in short:
            print("   %2d. %s (%d 字)" % (idx, title, chars))

    if not apply:
        print("\n[dry-run] 未写入。加 --apply 落盘到 assets/tianji/lecture/")
        return

    os.makedirs(OUT_DIR, exist_ok=True)
    for name, title, text, _ in out:
        with open(os.path.join(OUT_DIR, name), "w", encoding="utf-8", newline="\n") as f:
            f.write("# %s\n\n%s\n" % (title, text))
    print("\n已写入 %d 篇 → %s" % (len(out), OUT_DIR))


if __name__ == "__main__":
    main()
