#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成「医案文章体」全文检索索引 assets/medical_cases/article_index.json.gz。

源是 tool/source/article_corpus/ 的诊疗日志文章（已随仓库入库）。段落切分
直接复用 tag_article_source.load_articles()，因此索引里的段号与 cases_table.md
里 `<art:文件#段号>` 标记中的段号是同一个编号——检索命中后能回指到具体
医案的溯源标记。

与 classic_index / tianji_index 同结构（{"v":1,"entries":[{s,t,x}]}），
Dart 侧 ClassicSearchService 传 path 即可检索，不写新检索器。

⚠️ 语料增删改后必须重跑：
    python tool/build_medical_article_index.py
"""
import gzip, json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
sys.path.insert(0, HERE)
from tag_article_source import load_articles  # noqa: E402

OUT = os.path.join(ROOT, "assets", "medical_cases", "article_index.json.gz")


def main():
    arts = load_articles()
    entries = [
        {
            "s": "yianwen",                 # 医案文章体，Dart 侧加标签用
            "t": ("%s · %s · %s" % (os.path.splitext(fn)[0], date, title)).strip(" ·"),
            "x": body,
            # 不写 a：源语料在 tool/source 下、不打包进 App，无可点开资产
        }
        for fn, no, title, date, body in arts
    ]
    payload = {"v": 1, "entries": entries}
    raw = json.dumps(payload, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "wb") as fp:
        with gzip.GzipFile(filename="", mode="wb", fileobj=fp, mtime=0) as gz:
            gz.write(raw)
    chars = sum(len(e["x"]) for e in entries)
    print("[OK] entries=%d 段，chars=%d" % (len(entries), chars))
    print("[OK] raw=%.1fMB gz=%.0fKB" % (len(raw) / 1048576.0, os.path.getsize(OUT) / 1024.0))
    print("[OK] -> " + os.path.relpath(OUT, ROOT))
    # 自检：症状词必须能命中（否则索引是空的或切错了）
    blob = raw.decode("utf-8")
    for kw in ("镜面舌", "一息三至", "胃口", "脉象"):
        print("  %-5s %d 处" % (kw, blob.count(kw)))


if __name__ == "__main__":
    main()
