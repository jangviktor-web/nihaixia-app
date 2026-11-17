# -*- coding: utf-8 -*-
"""生成《天纪》视频字幕检索索引（assets/tianji/tianji_index.json.gz）。

与 assets/guji/classic_index.json.gz 同结构、同检索逻辑，但**独立成库**：
天纪属口述命理内容，混进医疗索引会让「失眠」这类医疗提问命中医理口述，
所以隔离成独立索引，只在命理入口检索。

源：assets/tianji/lecture/*.md（由 tool/import_tianji_lecture.py 生成，不进 App 打包）

⚠️ 字幕或切分脚本变动后必须重跑：
    python tool/build_tianji_index.py
"""

import gzip
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from build_classic_search_index import ROOT, first_heading, strip_markdown  # noqa: E402

SRC = os.path.join(ROOT, "assets", "tianji", "lecture")
OUT = os.path.join(ROOT, "assets", "tianji", "tianji_index.json.gz")

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
    total_fixed = 0
    for name in sorted(os.listdir(SRC)):
        if not name.endswith(".md"):
            continue
        with open(os.path.join(SRC, name), encoding="utf-8") as f:
            raw = f.read()
        title = first_heading(raw, os.path.splitext(name)[0])
        body = strip_markdown(raw) or title
        body, fixed = apply_fixups(body)
        if fixed:
            print("  [fix] %s: %d 处" % (name, fixed))
        total_fixed += fixed
        # 不写 "a"（资产路径）：lecture/*.md 不打包，来源卡片不应出现"可点开"
        entries.append({"s": "tianji", "t": title, "x": body})
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
