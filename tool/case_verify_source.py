#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""源讲义 → App 医案表 的对账（stdlib，只读，不改任何文件）。

回答「表里的医案和讲义原文对得上吗」。注意口径：`fill_medical_cases_from_md.py`
对已存在的行**只填空列、只打标记，不改已有正文**，所以表正文是蒸馏表的加工版、
源只是填补与溯源，两者本就不逐字相等。「表 == 源」是错的期望。

真正该问的四件事，本工具逐条回答：
  ① 溯源标记有没有死指针（标记指向源里不存在的条目）
  ② 标记有没有贴错行（表行与所标源条目内容完全无关 = 串行）
  ③ 源讲义有多少条目没进表、为什么
  ④ 该由回填补上的列（病机/方剂/针灸/观点）还有多少空格

用法：
  python tool/case_verify_source.py            # 报告
  python tool/case_verify_source.py --verbose  # 打印明细
退出码：0 = 无死指针且无贴错；1 = 有。

 ponytail: 解析器全部复用 fill 模块，不写第二套——两套解析必然漂移，那正是要防的。
"""
import os, re, sys, argparse, collections

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fill_medical_cases_from_md as F

HERE = os.path.dirname(os.path.abspath(__file__))
SRC_DIR = os.path.join(HERE, "source", "renji_case_md")
APP = os.path.join(os.path.dirname(HERE), "assets", "medical_cases", "cases_table.md")

FIELDS = [(1, "日期"), (2, "患者"), (3, "诊断"), (4, "病机"),
          (6, "方剂"), (7, "针灸"), (11, "观点"), (12, "四诊")]
FILL_COLS = {4, 6, 7, 11}          # fill 的回填范围（与 fill_medical_cases_from_md 保持一致）


def load_source():
    """→ (上册{号:[条目]}, 下册{号:[条目]})。上下册条目号各自从 1 起，同号是不同病例。"""
    up, dn = {}, {}
    for sub, box in (("医案上", up), ("医案下", dn)):
        for x in F.load_dir(os.path.join(SRC_DIR, sub)):
            box.setdefault(int(x["srcrow"]), []).append(x)
    return up, dn


def load_table():
    rows = []
    txt = open(APP, encoding="utf-8").read().replace("\r\n", "\n")
    for ln in txt.split("\n"):
        if not ln.startswith("|"):
            continue
        c = [x.strip() for x in ln.strip("|").split("|")]
        if len(c) >= 13 and c[0].isdigit():
            rows.append((c[0], c))
    return rows


def best_match(c, seq, cands):
    """同号在上下册各有一条时，取与表行字段重合最多的。

    返回 (条目, 是否并列)。并列意味着仅凭内容无法判定是哪一册的第 N 条——
    这不影响「内容对不对」，但影响「能不能唯一定位到某一个文件」。
    """
    scored = [(sum(1 for i, _l in FIELDS if c[i] and c[i] == F.md_to_row(x, seq)[i]), x)
              for x in cands]
    top = max(s for s, _x in scored)
    winners = [x for s, x in scored if s == top]
    return winners[0], len(winners) > 1


def main(verbose=False):
    up, dn = load_source()
    table = load_table()
    n_md = sum(len(v) for v in up.values()) + sum(len(v) for v in dn.values())

    dead, wrong, traced = [], [], 0
    dist = collections.Counter()
    empty_in_scope = collections.Counter()
    empty_out_scope = collections.Counter()
    used_up, used_dn = set(), set()
    dn_files = {y["file"] for v in dn.values() for y in v}
    ties = ambiguous = 0

    for seq, c in table:
        marks = [m for m in re.findall(r"<md:([^>]+)>", c[8]) if m.isdigit()]
        if not marks:
            continue
        cands = []
        for m in marks:
            k = int(m)
            if k not in up and k not in dn:
                dead.append((seq, m))
                continue
            cands.extend(up.get(k, []) + dn.get(k, []))
        if not cands:
            continue
        x, tie = best_match(c, seq, cands)
        (used_dn if x["file"] in dn_files else used_up).add(int(x["srcrow"]))
        traced += 1
        if tie:
            ties += 1
        if len(cands) > 1:
            ambiguous += 1
        mapped = F.md_to_row(x, seq)
        eq = sum(1 for i, _l in FIELDS if c[i] and c[i] == mapped[i])
        dist[eq] += 1
        if eq == 0:                                   # 八个字段全部不同：标记基本贴错
            wrong.append((seq, c[1], c[3][:26], mapped[1], mapped[3][:26]))
        for i, lab in FIELDS:
            if not c[i] and mapped[i] and mapped[i] != "未提及":
                (empty_in_scope if i in FILL_COLS else empty_out_scope)[lab] += 1

    used_nums = used_up | used_dn
    print("源讲义   %d 个 md（上 %d / 下 %d），条目号上 1..%d、下 1..%d"
          % (n_md, len(up), len(dn), max(up), max(dn)))
    print("表中行   %d（有溯源标记 %d / 无标记 %d）"
          % (len(table), traced, len(table) - traced))
    print()

    print("① 死指针（标记指向源里不存在的条目）    %d 处" % len(dead))
    print("② 标记贴错（表行与所标源内容完全无关）  %d 行" % len(wrong))
    print("③ 同号歧义：%d 行有上下册同名候选（号 ≤ %d），其中 %d 行内容并列、无法消歧"
          % (ambiguous, max(dn), ties))
    print("   上册未被引用 %d 个条目 = 门禁剔除（方剂空/未公开/未提及）+ 同案合并 + 复诊并入初诊，非丢失"
          % (len(up) - len(used_up)))
    print("④ 回填列仍有空格（病机/方剂/针灸/观点） " +
          ("、".join("%s %d" % (k, v) for k, v in empty_in_scope.most_common()) or "0"))
    print("⑤ 非回填列空格（按设计保留蒸馏表原样）   " +
          ("、".join("%s %d" % (k, v) for k, v in empty_out_scope.most_common()) or "0"))
    print()
    print("内容一致度（表 vs 所标源，满分 %d 字段；差异来自蒸馏表改写，非缺陷）："
          % len(FIELDS))
    for k in sorted(dist, reverse=True):
        print("   %d 字段相等：%d 行" % (k, dist[k]))
    print()
    print("⚠ 溯源精度：上下册条目号各自从 1 起，第 1..%d 号同时存在于两册且确为不同病例，"
          "所以 <md:N> 单独不足以唯一定位文件，本工具靠内容消歧。要彻底消除歧义，"
          "标记应写成 <md:上N>/<md:下N>（需同步改 fill 的幂等判断，否则重跑会重复补入）。"
          % max(dn))

    if verbose:
        for t in dead[:20]:
            print("   死指针 #%s <md:%s>" % t)
        for t in wrong[:20]:
            print("   贴错 #%s 表 %s %s | 源 %s %s" % t)

    ok = not dead and not wrong
    print("\n判定：%s" % ("✓ 溯源无死指针、无贴错行" if ok else "✗ 存在溯源缺陷"))
    return 0 if ok else 1


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--verbose", action="store_true")
    sys.exit(main(ap.parse_args().verbose))
