#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""合并医案表里「内容相同」的重复行，md 来源标记并入保留行。

与 merge_duplicate_cases.py 的分工：
  merge_duplicate_cases.py  两行内容不同（一次就诊被拆两条）→ 取并集合成一行，需人工给配对
  本脚本                     两行内容相同 → 无判断空间，直接合并/去重

两道合并，判据都是「内容」，不看编号不看键：
  1 全列相同   除「序号」与 <md:N> 外逐字相同（`--loose` 时连标点空白一起抹平）
               来源：源语料把同一案存了两个条号，如 `第117条 120S1T,R` 与 `第367条 R.T.`，
               后者没编号，按「编号+日期」去重撞不上，同一案就进表两次。
  2 缺日期副本 除「日期」外逐字相同、一侧日期为空、另一侧有日期
               来源：原表里同一案存了一空一有两条，空的那条是残缺副本。

用法：
  python tool/dedupe_identical_rows.py             # 只报告
  python tool/dedupe_identical_rows.py --apply     # 写回（备份 .bak-dup）
  python tool/dedupe_identical_rows.py --strict    # 第一道改为严格逐字（不抹标点）
"""
import argparse
import importlib.util
import os

HERE = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_file_location(
    "fill", os.path.join(HERE, "fill_medical_cases_from_md.py"))
fill = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fill)

APP = fill.APP


def report_same(rows, key):
    groups = {}
    for r in rows:
        k = key(r)
        if not any(k):
            continue
        groups.setdefault(k, []).append(r[0])
    return {k: v for k, v in groups.items() if len(v) > 1}


def report_date(rows):
    groups = {}
    for r in rows:
        k = tuple(fill.loose_key([r[0]] + ["" if n == fill.I_DATE else v
                                           for n, v in enumerate(r)])[1:])
        if not any(k):
            continue
        groups.setdefault(k, []).append(r)
    out = []
    for _k, g in groups.items():
        if len(g) < 2:
            continue
        dated = [r for r in g if r[fill.I_DATE].strip()]
        blank = [r for r in g if not r[fill.I_DATE].strip()]
        if len(dated) == 1 and blank:
            out.append((dated[0], blank))
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--strict", action="store_true", help="不抹平标点空白")
    a = ap.parse_args()

    raw_bytes = open(APP, "rb").read()
    _raw, lines, rows, _idx = fill.read_app(APP)

    key = fill.identical_key if a.strict else fill.loose_key
    same = report_same(rows, key)
    mdate = report_date(rows)

    n_same = sum(len(v) - 1 for v in same.values())
    n_date = sum(len(b) for _d, b in mdate)
    print("读取 %d 行" % len(rows))
    print("① 全列相同       %d 组，可减 %d 行" % (len(same), n_same))
    print("② 缺日期副本     %d 组，可减 %d 行" % (len(mdate), n_date))

    if same:
        print("\n① 明细：")
        for k, v in same.items():
            print("   保留 #%s ← 合并 %s ｜ %s %s %s"
                  % (v[0], "、".join("#" + x for x in v[1:]),
                     (k[0] or "日期空")[:10], (k[1] or "-")[:14], (k[2] or "-")[:26]))
    if mdate:
        print("\n② 明细：")
        for d, bl in mdate:
            print("   保留 #%s（%s）← 丢弃缺日期 %s ｜ %s"
                  % (d[0], d[fill.I_DATE], "、".join("#" + x[0] for x in bl),
                     d[3][:26]))

    if not (same or mdate):
        print("\n没有可合并的行。")
        return
    if not a.apply:
        print("\n[dry-run] 未写文件。加 --apply 执行。")
        return

    bak = APP + ".bak-dup"
    open(bak, "wb").write(raw_bytes)
    out, m1 = fill.collapse_identical(lines, loose=not a.strict)
    out, m2 = fill.merge_missing_date(out)
    text = "\n".join(out)
    if b"\r\n" in raw_bytes:                      # 保留源文件换行风格
        text = text.replace("\r\n", "\n").replace("\n", "\r\n")
    open(APP, "w", encoding="utf-8", newline="").write(text)

    _r2, _l2, rows2, idx2 = fill.read_app(APP)
    assert len(rows2) == len(rows) - m1 - m2, f"写后行数异常 {len(rows2)}"
    assert len(idx2) == len(rows2), "写后序号重复"
    print("\n[apply] 备份 -> %s" % bak)
    print("[apply] ① %d 行 ② %d 行，总行数 %d -> %d ✓" % (m1, m2, len(rows), len(rows2)))


if __name__ == "__main__":
    main()
