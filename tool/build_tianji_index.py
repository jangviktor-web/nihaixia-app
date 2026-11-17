# -*- coding: utf-8 -*-
"""生成《天纪》检索索引（assets/tianji/tianji_index.json.gz）。

与 assets/guji/classic_index.json.gz 同结构、同检索逻辑，但**独立成库**：
天纪属口述命理内容，混进医疗索引会让「失眠」这类医疗提问命中医理口述，
所以隔离成独立索引，只在命理入口检索。

两个源，讲义优先：
  1. assets/tianji/*.md      —— 9 篇人工核过的整理讲义（打包进 App，有分节与分段）
  2. assets/tianji/lecture/*.md —— 99 篇视频字幕转录（不进 App 打包）

同一堂课存在两个版本，整理稿质量明显更高。故索引层做去重：字幕节的标题
归一化后若与讲义某节相同，跳过该字幕节，避免两份相似内容挤占检索配额
（上下文只取前 8 条）。

⚠️ 讲义、字幕或切分脚本变动后必须重跑：
    python tool/build_tianji_index.py
"""

import gzip
import json
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_classic_search_index import ROOT, first_heading, strip_markdown  # noqa: E402

SRC = os.path.join(ROOT, "assets", "tianji", "lecture")
LECTURE_DIR = os.path.join(ROOT, "assets", "tianji")
OUT = os.path.join(ROOT, "assets", "tianji", "tianji_index.json.gz")

# 9 篇整理讲义：(文件名, 篇名)。篇名须与 Dart 侧 TianjiDocListScreen.docs 一致，
# 索引标题才会与列表页显示对得上。
LECTURES = [
    ("1_天机道.md", "天机道"),
    ("2_紫微斗数十二宫.md", "十二宫详解"),
    ("3_星曜详解.md", "星曜详解"),
    ("7_手相.md", "手相"),
    ("12_相术总结.md", "相术总结"),
    ("9_六神占断论.md", "六神占断论"),
    ("8_堪舆风水.md", "堪舆风水"),
    ("8_风水布局.md", "风水布局"),
    ("8_八煞黄泉.md", "八煞黄泉"),
    ("13_地纪游记.md", "地纪游记"),
]

HEAD = re.compile(r"^(#{2,5})\s+(.*)$")
_SUBTITLE_PREFIX = re.compile(r"^第[一二三四五六七八九十百]+[节章]\s*")


def parse_lecture_sections(raw, book):
    """按 ##/####/##### 切节，与 Dart 端 TianjiSectionRepository.parse 同规则。

    返回 [(标题, 正文)]；正文**保留空行分段**——检索片段直接给模型看，
    压成单行会让它读到一大坨。
    """
    sections = []
    group = None
    title = None
    buf = []
    seen_h2 = False

    def compose(name):
        if name == book:
            return book
        if group and name != group:
            return "%s · %s · %s" % (book, group, name)
        return "%s · %s" % (book, name)

    def flush():
        body = "\n".join(buf).strip()
        buf.clear()
        if title and body:
            sections.append((title, body))

    for line in raw.split("\n"):
        m = HEAD.match(line.strip())
        if not m:
            buf.append(line)
            continue
        flush()
        level = len(m.group(1))
        name = m.group(2).strip()
        if level == 2:
            if not seen_h2:
                seen_h2 = True
                group = None
                title = book
            else:
                if name != book:
                    group = name
                title = compose(name)
        elif level == 4:
            if name != book:
                group = name
            title = compose(name)
        else:
            title = compose(name)
    flush()
    return sections


def norm_title(t):
    """归一化标题用于跨源去重：去掉「第X节」前缀、篇名前缀与标点空白。"""
    t = _SUBTITLE_PREFIX.sub("", t)
    t = t.split(" · ")[-1]
    return re.sub(r"[\s（）()、，,。·]", "", t)

# 录音转录的同音/形近误录纠正。只收**已联网核实、确属笔误**的少数几条。
#
# 刻意不收的：
#   - 口语词（这个/那/呢/啊/诸位/有没有/对不对）—— 倪师讲课语感本身，
#     属讲义特色内容，剔除即失真（项目红线）。
#   - 「墓宅逢之一且休」—— 八煞黄泉歌诀存在流派版本差异（旦/齐/切/且），
#     于都杨公风水师传版正是「一且休」，与本片一致，不得擅自统一。
#   - 「我是肚量很大的人」—— 口语里「肚量」可用，仅「如何去肚量」是误录。
FIXUPS = [
    ("骑龙葬的肘候", "骑龙葬的时候"),
    ("假使l2个地支", "假使12个地支"),
    ("专门管挣伐", "专门管征伐"),
    ("开那个门干吧", "开那个门干嘛"),
    ("如何去肚量", "如何去度量"),
]


def apply_fixups(text):
    fixed = 0
    for wrong, right in FIXUPS:
        n = text.count(wrong)
        if n:
            text = text.replace(wrong, right)
            fixed += n
    return text, fixed


def build_entries():
    if not os.path.isdir(SRC):
        raise SystemExit("缺少讲义目录：" + SRC + "（先跑 tool/import_tianji_lecture.py）")
    entries = []
    seen = set()
    total_fixed = 0

    # 1) 整理讲义优先：质量高、有分节与分段，先占住去重表
    for fn, book in LECTURES:
        path = os.path.join(LECTURE_DIR, fn)
        if not os.path.exists(path):
            print("  [warn] 缺少讲义 %s，跳过" % fn)
            continue
        with open(path, encoding="utf-8") as f:
            raw = f.read()
        for title, body in parse_lecture_sections(raw, book):
            body, fixed = apply_fixups(body)
            if fixed:
                print("  [fix] %s · %s: %d 处" % (fn, title, fixed))
            total_fixed += fixed
            # 不写 "a"：讲义虽打包，但检索卡片按「讲稿片段」展示即可，
            # 避免同一节既跳列表页又跳正文造成两套入口
            entries.append({"s": "tianji", "t": title, "x": body})
            seen.add(norm_title(title))
    lecture_count = len(entries)
    print("[lecture] 讲义 %d 节" % lecture_count)

    # 2) 视频字幕：与讲义实质同名的节跳过
    skipped = 0
    for name in sorted(os.listdir(SRC)):
        if not name.endswith(".md"):
            continue
        with open(os.path.join(SRC, name), encoding="utf-8") as f:
            raw = f.read()
        title = first_heading(raw, os.path.splitext(name)[0])
        if norm_title(title) in seen:
            skipped += 1
            continue
        body = strip_markdown(raw) or title
        body, fixed = apply_fixups(body)
        if fixed:
            print("  [fix] %s: %d 处" % (name, fixed))
        total_fixed += fixed
        # 不写 "a"（资产路径）：lecture/*.md 不打包，来源卡片不应出现"可点开"
        entries.append({"s": "tianji", "t": title, "x": body})
    print("[subtitle] 字幕 %d 篇（跳过与讲义重复 %d 篇）"
          % (len(entries) - lecture_count, skipped))
    print("[fixup] 共纠正 %d 处（源 md 未改动）" % total_fixed)
    return entries


def main():
    entries = build_entries()
    payload = {"v": 1, "entries": entries}
    raw = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "wb") as fp:
        with gzip.GzipFile(filename="", mode="wb", fileobj=fp, mtime=0) as gz:
            gz.write(raw)
    chars = sum(len(e["x"]) for e in entries)
    print("[OK] entries=%d chars=%d" % (len(entries), chars))
    print("[OK] raw=%.1fMB gz=%.0fKB" % (len(raw) / 1048576.0, os.path.getsize(OUT) / 1024.0))
    print("[OK] -> " + os.path.relpath(OUT, ROOT))


if __name__ == "__main__":
    main()
