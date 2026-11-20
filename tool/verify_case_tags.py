#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""校验 App 医案表里的两类溯源标记都能解析到真实源。

  <md:N>              → tool/source/renji_case_md/{医案上,医案下}/ 里第 N 条
  <art:文件#段落号>   → tool/source/article_corpus/文件.md 里第 N 个日期段落

退出码 0 = 全部标记有效。可与 case_verify_source.py 连跑。
"""
import os, re, sys, collections

HERE = os.path.dirname(os.path.abspath(__file__))
APP = os.path.join(os.path.dirname(HERE), "assets", "medical_cases", "cases_table.md")
MD_DIR = os.path.join(HERE, "source", "renji_case_md")
ART_DIR = os.path.join(HERE, "source", "article_corpus")
TAG = re.compile(r"<(md|art):([^>]+)>")


def main():
    lines = open(APP, encoding="utf-8").read().replace("\r\n", "\n").split("\n")
    rows = [l for l in lines if l.startswith("|") and re.match(r"\|\s*\d+\s*\|", l)]

    # md 源条目号
    import importlib.util
    spec = importlib.util.spec_from_file_location("fill", os.path.join(HERE, "fill_medical_cases_from_md.py"))
    fill = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(fill)
    md_keys = set()
    for sub in ("医案上", "医案下"):
        for x in fill.load_dir(os.path.join(MD_DIR, sub)):
            md_keys.add(str(x["srcrow"] or x["file"]))

    # 文章段落数（与 tag_article_source.load_articles 同一切法）
    spec2 = importlib.util.spec_from_file_location("tag", os.path.join(HERE, "tag_article_source.py"))
    tagmod = importlib.util.module_from_spec(spec2)
    spec2.loader.exec_module(tagmod)
    arts = tagmod.load_articles()
    art_keys = collections.Counter(a[0] for a in arts)

    bad, counts = [], collections.Counter()
    for ln in rows:
        seq = ln.split("|")[1].strip()
        for kind, val in TAG.findall(ln):
            counts[kind] += 1
            if kind == "md" and val not in md_keys:
                bad.append((seq, "<md:%s> 源里无此条目" % val))
            elif kind == "art":
                m = re.match(r"(.+)#(\d+)$", val)
                if not m:
                    bad.append((seq, "<art:%s> 格式错" % val))
                    continue
                fn, no = m.group(1) + ".md", int(m.group(2))
                if fn not in art_keys:
                    bad.append((seq, "<art:%s> 文件不存在" % val))
                elif no > art_keys[fn]:
                    bad.append((seq, "<art:%s> 段号超出（共%d段）" % (val, art_keys[fn])))

    print("医案行 %d；标记 <md:> %d 个、<art:> %d 个" %
          (len(rows), counts["md"], counts["art"]))
    print("文章语料 %d 个文件 / %d 段" % (len(art_keys), len(arts)))
    if bad:
        print("无效标记 %d 处：" % len(bad))
        for seq, msg in bad[:20]:
            print("  #%s %s" % (seq, msg))
    else:
        print("✓ 全部标记都能解析到真实源文件与段落")
    print("未标记（仍无溯源）%d 行" % sum(1 for ln in rows if not TAG.search(ln)))
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
