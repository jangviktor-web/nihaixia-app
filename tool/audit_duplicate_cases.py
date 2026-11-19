#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""医案重复体检：只读，不动数据，按「日期 / 患者 / 标题 / 方剂」四维打分层规则。

回答的问题只有一个：App 里还有没有「日期和标题（患者＋主要诊断）都对得上」的重复医案。

归一（比对前统一做，避免同一条因写法差异漏判）
  患者  「女，50岁，+ 瘦小」「F，50+ 瘦小」「女50岁」→ F50+瘦小
        男女统一 M/F，去「岁」「+」与标点，拉丁字母转大写
  诊断  全半角统一、去标点与空白
  方剂  去 <md:N> 标记与空白；以「同」开头的续诊引用（同前 / 同4/8方）判为引用型，
        不参与方剂重合计算——否则每个病人的历次续诊都会互撞

患者三态（关键，早期版本在这里误判）
  same     两边都能认出是同一人（含年龄缺失只写 M/F 的情况）
  diff     两边都认得出，且明显不是同一人
  unknown  至少一边患者信息为空 / 无意义 —— 不能据此判「不同人」，只能判「无法判断」

规则（同日整对内部级联，每对只落一个桶，不重复计数）
  D5  全字段重复   12 列（去标记后）完全一致                  → 纯复制行，删一即可
  D1  高疑重复     同日 + 患者不冲突 + 下面的证据之一：
       D1a  标题同 + 方剂重合 ≥ 0.80                            → 同一次就诊被拆两条，可合并
       D1b  标题同 + 方剂是引用型（无法比对）                    → 同一次的可能性高，人工确认
       D1c  标题写法不同 + 方剂重合 ≥ 0.80                       → 同一次，标题写岔了，可合并
  D2  同人同日异方  同日 + 患者不冲突 + 标题同，但方剂重合 < 0.80 → 同次两方 / 抄错一行，人工确认
  D3  同病不同人     同日 + 标题同，但患者是两个人                  → 双胞胎、夫妻同病，多为真实两案
  D4  同人同日异诊   同日 + 同人 + 标题不同 + 方剂不像               → 同次多主诉，多为真实两案
  D6  跨日同人同方   日期不同 + 同人 + 标题同 + 方剂重合 ≥ 0.95      → 复制时忘了改日期，人工确认

用法
  python tool/audit_duplicate_cases.py            # 汇总 + D5/D1 明细
  python tool/audit_duplicate_cases.py --write     # 另存 docs/duplicate_case_audit_<日期>.md
  python tool/audit_duplicate_cases.py --show D2   # 只看某一层的明细
"""
import argparse
import datetime
import importlib.util
import os
import re
from collections import defaultdict
from itertools import combinations

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
spec = importlib.util.spec_from_file_location(
    "fill", os.path.join(HERE, "fill_medical_cases_from_md.py"))
fill = importlib.util.module_from_spec(spec)
spec.loader.exec_module(fill)

DECIDED = os.path.join(os.path.dirname(os.path.abspath(__file__)),
                       "case_pair_decisions.tsv")
APP = fill.APP
COLS = 12
I_NO, I_DATE, I_PT, I_DX, I_FORM = 0, 1, 2, 3, 6

D1_MIN = 0.80          # 方剂重合达到此值即认定「同一个方」
D6_MIN = 0.95          # 跨日要比同日更严，防止把「守方续诊」全抓出来
REF_LEN = 8            # 方剂正文短于此或「同」开头，视为引用型

ORDER = ["D5", "D1a", "D1b", "D1c", "D2", "D3", "D4", "D6a", "D6b"]
NAME = {
    "D5": "全字段重复",
    "D1a": "高疑重复·标题同+方同",
    "D1b": "高疑重复·标题同+方引用",
    "D1c": "高疑重复·标题异+方同",
    "D2": "同人同日异方",
    "D3": "同病不同人",
    "D4": "同人同日异诊",
    "D6a": "残缺行·缺日期+同方",
    "D6b": "跨日同人同方",
}
ACT = {
    "D5": "可直接删一",
    "D1a": "可合并（保留序号小者，内容取并集）",
    "D1b": "人工确认后合并",
    "D1c": "可合并（标题写法不同，实为同次）",
    "D2": "人工确认（同次两方或抄错）",
    "D3": "大概率真实两案，不合并",
    "D4": "大概率真实两案，不合并",
    "D6a": "补日期后与另一行合并",
    "D6b": "人工确认（疑似忘改日期/守方续诊）",
}


# ---------- 归一 ----------
def tidy(s):
    s = re.sub(r"<md:[^>]+>", "", str(s or ""))
    for a, b in (("；", ";"), ("，", ","), ("：", ":"), ("。", "."),
                 ("（", "("), ("）", ")"), ("、", ","), ("　", " ")):
        s = s.replace(a, b)
    return re.sub(r"\s+", "", s)


def pkey(s):
    """患者归一：女→F 男→M，去「岁」「+」与标点，拉丁转大写。"""
    s = tidy(s).replace("女", "F").replace("男", "M")
    s = re.sub(r"[岁+＋.,:;()\[\]/\-]", "", s)
    return s.upper()


EMPTY_PT = {"", "-", "?", "无", "未提及", "不详", "未知"}
EMPTY_PT2 = EMPTY_PT | {"空", "同上", "待补"}
CODE_PT = re.compile(r"^\d{2,}")                       # 0612LYL / 008S3 / 117S12
NARR_PT = ("一位", "一个", "病人", "太太", "先生", "老太太", "妈妈", "爸爸",
           "妇人", "小孩", "母亲", "父亲", "儿子", "女儿", "小姐")


def ptoks(s):
    """患者拆词集：按标点切，去「岁」「+」，用于「女,三十岁,三十余岁,瘦 ⊇ F,三十余岁,瘦」。"""
    t = tidy(s).replace("女", "F").replace("男", "M").replace("岁", "").replace("+", "")
    return {x for x in re.split(r"[.,:;()\[\]/\-]", t) if x}


def pstate(a, b):
    """same / diff / unknown —— 三态。unknown 表示「无法判断」，绝不等于 diff。

    四道闸门：
      1 空 / 无意义          → unknown
      2 两边都带性别且性别不同 → diff（最强反证）
      3 任一侧是编号或叙述句   → unknown（061-2L,YL、「一位尿毒症的黑人」不可比）
      4 任一侧只剩性别        → unknown（「男」对「男,41岁」比不出是不是同一人）
    过关后才做 精确 / 前缀 / 词集包含 三种同人判定。
    """
    ka, kb = pkey(a), pkey(b)
    if ka in EMPTY_PT or kb in EMPTY_PT:
        return "unknown"
    ga = ka[0] if ka[:1] in ("M", "F") else ""
    gb = kb[0] if kb[:1] in ("M", "F") else ""
    if ga and gb and ga != gb:
        return "diff"
    # 只剩性别（`男` vs `男`）必须拦在相等判定**之前**：两个都只写「男」的人
    # 比不出是不是同一人，`ka == kb` 先跑就会把它们认成 same（2026-11-20 踩过：
    # #184 与 #1358 同日都只写「男」、标题不同，被误判成 D4 同人同日异诊）
    if len(ka) <= 1 or len(kb) <= 1:
        return "unknown"
    if ka == kb:
        return "same"
    if (CODE_PT.match(ka) or CODE_PT.match(kb)
            or any(w in a or w in b for w in NARR_PT)):
        return "unknown"
    if ka.startswith(kb) or kb.startswith(ka):
        short, long_ = (ka, kb) if len(ka) <= len(kb) else (kb, ka)
        # 「M32中等」不能因为前缀是「M3」就认成「M3岁」——短串末尾是数字时必须卡在数字边界
        if not (short[-1:].isdigit() and long_[len(short):len(short) + 1].isdigit()):
            return "same"
    ta, tb = ptoks(a), ptoks(b)
    if ta and tb and (ta <= tb or tb <= ta) and len(ta & tb) >= 2:
        return "same"
    return "diff"


def is_ref(f):
    t = tidy(f)
    return len(t) < REF_LEN or t.startswith("同")


def form_j(a, b):
    """方剂重合度；任一侧是引用型则返回 None（不可比，不是 0）。"""
    if is_ref(a) or is_ref(b):
        return None
    return round(fill.jac(a, b), 4)


# ---------- 数据 ----------
def load_decided():
    """人工已定性的对 → {"a,b": (判定, 备注)}。这些对不再计入各层组数，
    否则每跑一次报告都要重新读一遍同样的结论。"""
    out = {}
    if not os.path.exists(DECIDED):
        return out
    for ln in open(DECIDED, encoding="utf-8-sig"):
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        p = ln.rstrip("\n").split("\t")
        if len(p) >= 3 and p[0].strip().isdigit() and p[1].strip().isdigit():
            a, b = sorted([p[0].strip(), p[1].strip()], key=int)
            out["%s,%s" % (a, b)] = (p[2].strip(), p[3].strip() if len(p) > 3 else "")
    return out


def load():
    _raw, _lines, rows, _idx = fill.read_app(APP)
    return [r for r in rows if len(r) >= COLS and r[I_NO].isdigit()]


def identical(a, b):
    """除「序号」外 12 列去标记后完全一致。序号必须排除——它本来就不同。"""
    return all(tidy(a[i]) == tidy(b[i]) for i in range(1, COLS))


def dstate(a, b):
    """标题三态：same / diff / unknown（任一侧标题为空或占位符）。"""
    ta, tb = tidy(a[I_DX]), tidy(b[I_DX])
    if ta in EMPTY_PT2 or tb in EMPTY_PT2:
        return "unknown"
    return "same" if ta == tb else "diff"


def classify(a, b):
    """同日一对 → (桶名, 方剂重合 or None)。桶名 None 表示不构成嫌疑。"""
    if identical(a, b):
        return "D5", None
    ds = dstate(a, b)
    ps = pstate(a[I_PT], b[I_PT])
    j = form_j(a[I_FORM], b[I_FORM])

    if ps == "diff":
        return ("D3", j) if ds == "same" else (None, j)

    if ds == "same":
        if j is None:
            return "D1b", None
        if j >= D1_MIN:
            return "D1a", j
        return "D2", j

    # 标题不同或未知：只能靠方剂证据
    if j is not None and j >= D1_MIN:
        return "D1c", j
    if ps == "same" and ds == "diff":
        return "D4", j
    return None, j


def cross_date(rows):
    """跨日同人同方：先按患者分桶，桶内两两比，避免全表 O(n^2)。"""
    buckets = defaultdict(list)
    for r in rows:
        k = pkey(r[I_PT])
        if k in EMPTY_PT or is_ref(r[I_FORM]):
            continue
        buckets[k].append(r)
    out = []
    for _k, grp in buckets.items():
        if len(grp) < 2:
            continue
        for a, b in combinations(grp, 2):
            if tidy(a[I_DATE]) == tidy(b[I_DATE]):
                continue
            if tidy(a[I_DX]) != tidy(b[I_DX]):
                continue
            j = form_j(a[I_FORM], b[I_FORM])
            if j is not None and j >= D6_MIN:
                out.append((a, b, j))
    return out


def visit_label(i):
    """链内第 i 次就诊的叫法：0 → 初诊，其余 → 复诊②③④…"""
    if i == 0:
        return "**初诊**"
    return "复诊" + ("②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳"[i - 1] if i <= 20 else "(%d)" % (i + 1))


def d6b_chains(g):
    """把 D6b 的两两配对折成「同人 + 同标题」的就诊链，链内按日期排序。

    D6b 判据是「跨日 + 同人 + 标题同 + 方剂几乎一致」，典型是守方续诊。
    逐对罗列会让一个三诊病人出现成两对、同一条记录在一对里是初诊、在另一对里是复诊，
    所以先按 (患者归一, 标题) 收成链，链内按日期编号再标初诊/复诊。
    """
    cl = {}
    for x, y, _j in g:
        k = (pkey(x[I_PT]), tidy(x[I_DX]))
        d = cl.setdefault(k, {})
        for r in (x, y):
            d.setdefault(r[I_NO], r)
    out = []
    for k, d in cl.items():
        rs = sorted(d.values(), key=lambda r: (tidy(r[I_DATE]), int(r[I_NO])))
        out.append((k, rs))
    out.sort(key=lambda t: (t[1][0][I_DATE], t[0][0]))
    return out


# ---------- 输出 ----------
def brief(r, j=None, cut=120):
    f = re.sub(r"\s+", " ", tidy(r[I_FORM]))
    s = "#%s　%s　患者:%s　标题:%s　方:%s" % (
        r[I_NO], r[I_DATE], tidy(r[I_PT]) or "-",
        (tidy(r[I_DX]) or "-")[:34], (f or "-")[:cut])
    if j is not None:
        s += "　重合%.2f" % j
    return s


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--show", default="", help="只看某层明细，如 D2")
    a = ap.parse_args()

    rows = load()
    no_date = [r for r in rows if not tidy(r[I_DATE])]
    by_date = defaultdict(list)
    for r in rows:
        d = tidy(r[I_DATE])
        if d:                       # 日期为空无法谈「同日」，单独计数，不参与两两比对
            by_date[d].append(r)

    hits = defaultdict(list)      # 桶 → [(a, b, j)]
    for date, grp in by_date.items():
        for x, y in combinations(grp, 2):
            k, j = classify(x, y)
            if k:
                hits[k].append((x, y, j))

    for x, y, j in cross_date(rows):
        # 一侧日期为空 → 不是「跨日重复」，是同一条被拆成两份、一份丢了日期
        k = "D6a" if not tidy(x[I_DATE]) or not tidy(y[I_DATE]) else "D6b"
        hits[k].append((x, y, j))

    # 人工已定性的对：从各层剔掉，另列一节，免得每轮重复读同一批结论
    dcd = []
    decided = load_decided()
    if decided:
        for k in list(hits):
            keep = []
            for x, y, j in hits[k]:
                key = "%s,%s" % tuple(sorted([x[I_NO], y[I_NO]], key=int))
                if key in decided:
                    dcd.append((k, x, y) + decided[key])
                else:
                    keep.append((x, y, j))
            hits[k] = keep
        dcd.sort(key=lambda t: (t[0], t[1][I_DATE], int(t[1][I_NO])))

    for k in hits:
        hits[k].sort(key=lambda t: (t[0][I_DATE], int(t[0][I_NO])))

    print("读取 %d 行（其中日期为空 %d 行，不参与同日比对）；%d 个日期桶\n"
          % (len(rows), len(no_date), len(by_date)))
    for k in ORDER:
        print("%-4s %-26s %3d 组   %s" % (k, NAME[k], len(hits[k]), ACT[k]))
    print()
    d1 = sum(len(hits[k]) for k in ("D1a", "D1b"))
    same_title = d1 + len(hits["D2"]) + len(hits["D3"])
    same_day = sum(len(hits[k]) for k in ("D1a", "D1b", "D1c", "D2", "D3", "D4"))
    print("「日期＋标题都一致」%d 组（D1a %d + D1b %d + D2 %d + D3 %d）"
          % (same_title, len(hits["D1a"]), len(hits["D1b"]),
             len(hits["D2"]), len(hits["D3"])))
    print("「日期一致、标题不同但方剂一致」D1c %d 组" % len(hits["D1c"]))
    print("同日全部嫌疑 %d 组；日期为空 %d 行已排除同类比较" % (same_day, len(no_date)))

    show = a.show or ("" if a.write else "D1a")
    if show:
        for k in [show] if show in NAME else ORDER:
            print("\n===== %s %s（%d 组）=====" % (k, NAME[k], len(hits[k])))
            if k == "D6b":
                for _key, rs in d6b_chains(hits[k])[:8]:
                    for i, r in enumerate(rs):
                        print("  %-5s %s" % (visit_label(i).strip("*"), brief(r)))
                    print("  " + ACT[k] + "\n")
                if len(d6b_chains(hits[k])) > 8:
                    print("  …… 其余 %d 链见报告" % (len(d6b_chains(hits[k])) - 8))
                continue
            for x, y, j in hits[k][:12]:
                print("  " + brief(x, None if j is None else j))
                print("  " + brief(y, None if j is None else j))
                print("  " + ACT[k] + "\n")
            if len(hits[k]) > 12:
                print("  …… 其余 %d 组见报告" % (len(hits[k]) - 12))

    if not a.write:
        return

    day = datetime.date.today().isoformat()
    L = ["# 医案重复体检报告", "",
         "- 生成时间：%s；数据：`assets/medical_cases/cases_table.md`（%d 行）"
         % (day, len(rows)),
         "- 只读检查，未改动任何数据",
         "- 已处理：① 源语料重号同内容 12 行　② 缺日期副本 9 行"
         "（`tool/dedupe_identical_rows.py`）　③ D1a 4 组　④ D1b 3 组　⑤ D1b 余下 + D1c 8 组"
         "（`tool/merge_duplicate_cases.py`，共 15 组 / 15 行）　"
         "⑥ 串行 2 组（`#184←#1289`、`#468←#1351`，后者 pin 掉串栏的方剂与观点）",
         "- 回归入口：`python tool/audit_duplicate_cases.py --write`", "",
         "## 一、结论", "",
         "| 层 | 判据 | 组数 | 处置 |", "|---|---|---|---|"]
    for k in ORDER:
        L.append("| **%s** %s | %s | %d | %s |"
                 % (k, NAME[k], JUDGE[k], len(hits[k]), ACT[k]))
    L += ["",
          "**「日期＋标题都一致」%d 组**（D1a %d + D1b %d + D2 %d + D3 %d）；"
          "另有 D1c %d 组「标题写法不同但方剂完全一致」。"
          % (same_title, len(hits["D1a"]), len(hits["D1b"]),
             len(hits["D2"]), len(hits["D3"]), len(hits["D1c"])),
          "",
          "「日期为空」%d 行、「患者为空或无意义」%d 行——这两类无法参与同日比对，"
          "属数据质量缺口，见第五节。"
          % (len(no_date), sum(1 for r in rows if pkey(r[I_PT]) in EMPTY_PT)),
          "",
          "## 二、归一与三态", "",
          "| 项 | 归一方式 |", "|---|---|",
          "| 患者 | 男女→M/F，「女，50岁，+瘦小」≡「F，50+瘦小」→ `F50+瘦小`；去「岁」「+」与标点 |",
          "| 患者三态 | `same` / `diff` / `unknown`。**任一侧患者为空或「无/未提及」记 unknown，不记 diff** |",
          "| 标题 | 主要诊断列，全半角统一、去标点与空白 |",
          "| 方剂 | 去 `<md:N>` 与空白；「同前 / 同4/8方」等引用型不参与重合计算（返回 None，不是 0） |", "",
          "两个阈值：同日 D1 判同方用 **≥ %.2f**；跨日 D6 抬到 **≥ %.2f**，"
          "因为跨日同方常是「守方续诊」而非复制。" % (D1_MIN, D6_MIN), ""]

    for k in ORDER:
        g = hits[k]
        L.append("## %s %s（%d 组）" % (k, NAME[k], len(g)))
        L.append("")
        L.append("> %s　判据：%s" % (ACT[k], JUDGE[k]))
        L.append("")
        if not g:
            L += ["无。", ""]
            continue
        if k == "D4":
            # D4 是同一天里同一人的多条不同诊次，按患者聚集看比逐对列更有用
            cl = defaultdict(list)
            for x, y, _j in g:
                cl[(x[I_DATE], pkey(x[I_PT]))].append(x[0] + "/" + y[0])
            L.append("| 日期 | 患者 | 对数 | 涉及序号 |")
            L.append("|---|---|---|---|")
            for (d, pk), v in sorted(cl.items(), key=lambda t: -len(t[1])):
                nos = sorted({z for s in v for z in s.split("/")}, key=int)
                L.append("| %s | %s | %d | %s |"
                         % (d, pk, len(v), "、".join("#" + z for z in nos)))
            L += ["", "> 这类不是重复：同一天同一个人有多条不同标题的记录，"
                  "多为原始表缺日期导致多个诊次压在同一天。整批核对日期比逐对合并有意义。", ""]
            continue
        if k == "D6b":
            # 跨日同人同方 = 守方续诊。逐对列分不清谁是谁的初诊，改成一链一行
            ch = d6b_chains(g)
            L.append("| 次 | 序号 | 日期 | 与初诊方剂重合 | 患者 | 标题 |")
            L.append("|---|---|---|---|---|---|")
            for (_pk, _dx), rs in ch:
                base = rs[0]
                for i, r in enumerate(rs):
                    jj = form_j(base[I_FORM], r[I_FORM])
                    L.append("| %s | #%s | %s | %s | %s | %s |"
                             % (visit_label(i) if i == 0 else visit_label(i),
                                r[I_NO], r[I_DATE], "—" if i == 0 else "%.2f" % jj,
                                tidy(r[I_PT]) or "-", (tidy(r[I_DX]) or "-")[:30]))
            L += ["", "> 共 %d 条链 / %d 条记录（原两两配对 %d 组）。"
                  "链内按日期排序：**日期在前 = 初诊，在后 = 复诊**。"
                  "同方跨日多为守方续诊，不是重复记录，一般不合并；"
                  "若两诊日期只差几天且内容雷同，才怀疑忘改日期。" % (
                      len(ch), sum(len(rs) for _k, rs in ch), len(g)), ""]
            # 间隔分布：守方续诊一般 1~4 周；隔半年以上还一模一样，是重复录入而不是复诊
            def _gap(rs):
                try:
                    a = [int(x) for x in tidy(rs[0][I_DATE]).split("-")[:3]]
                    b = [int(x) for x in tidy(rs[1][I_DATE]).split("-")[:3]]
                    return (datetime.date(*b) - datetime.date(*a)).days
                except (ValueError, TypeError):
                    return None
            bk = {"≤3天": 0, "4–30天": 0, "31–180天": 0, ">180天": 0}
            for _k, rs in ch:
                g_ = _gap(rs)
                if g_ is None:
                    continue
                bk["≤3天" if g_ <= 3 else "4–30天" if g_ <= 30
                   else "31–180天" if g_ <= 180 else ">180天"] += 1
            full = sum(1 for _k, rs in ch if form_j(rs[0][I_FORM], rs[1][I_FORM]) == 1.0)
            L += ["| 两诊间隔 | 组数 | 判读 |", "|---|---|---|",
                  "| ≤3 天 | %d | 几乎同日，疑忘改日期 |" % bk["≤3天"],
                  "| 4–30 天 | %d | 典型守方续诊 |" % bk["4–30天"],
                  "| 31–180 天 | %d | 守方续诊（间隔偏长） |" % bk["31–180天"],
                  "| >180 天 | %d | 更像重复录入 / 年份笔误 |" % bk[">180天"],
                  "",
                  "> 方剂**逐字完全一致**（重合 1.00）%d / %d 条链。隔半年以上还一字不差的，"
                  "基本是同一案被录了两次，不是两次开方。" % (full, len(ch)), ""]
            mix = [(p, rs) for p, rs in ch
                   if len({tidy(r[I_DATE])[5:10] for r in rs}) == 1 and len(rs) > 1]
            if mix:
                L.append("- **同月同日不同年 → 年份疑似笔误**：%s" % "；".join(
                    "、".join("#%s %s" % (r[I_NO], r[I_DATE]) for r in rs)
                    for _k, rs in mix))
                L.append("")
            L.append("")
            continue
        for x, y, j in g:
            L.append("- " + brief(x, j, 160))
            L.append("- " + brief(y, j, 160))
            if k == "D6b" and x[I_DATE][5:10] and x[I_DATE][5:10] == y[I_DATE][5:10]:
                L.append("- **同月同日不同年 → 年份疑似笔误（%s / %s）**"
                         % (x[I_DATE][:4], y[I_DATE][:4]))
            L.append("")
        L.append("")

    if dcd:
        L += ["## 附、已判定（不计入上面的组数）", "",
              "> 人工看过、结论已定，登记在 `tool/case_pair_decisions.tsv`，"
              "体检时自动从各层剔除。", "",
              "| 层 | 序号 | 日期 | 患者 | 判定 | 理由 |", "|---|---|---|---|---|---|"]
        for k, x, y, verdict, note in dcd:
            L.append("| %s | #%s ↔ #%s | %s | %s | **%s** | %s |"
                     % (k, x[I_NO], y[I_NO], x[I_DATE], tidy(x[I_PT]) or "-",
                        verdict, note.replace("|", "／")[:120]))
        L.append("")

    # 第五节：数据质量缺口
    L.append("## 五、数据质量缺口（不参与重复判定）")
    L.append("")
    if no_date:
        L.append("- **日期为空 %d 行**：%s" % (
            len(no_date), "、".join("#" + r[I_NO] for r in no_date)))
        L.append("")
    nopt = [r for r in rows if pkey(r[I_PT]) in EMPTY_PT]
    if nopt:
        L.append("- **患者为空或无意义 %d 行**（占 %.0f%%）：无法做同人判定，"
                 "其同类比对只能靠「日期＋标题＋方剂」三项"
                 % (len(nopt), 100.0 * len(nopt) / len(rows)))
        L.append("")
    L.append("")

    p = os.path.join(REPO, "docs", "duplicate_case_audit_%s.md" % day)
    open(p, "w", encoding="utf-8", newline="\n").write("\n".join(L))
    print("\n报告: %s" % p)


JUDGE = {
    "D5": "12 列去标记后完全一致",
    "D1a": "同日 + 标题同 + 患者不冲突 + 方剂重合 ≥ 0.80",
    "D1b": "同日 + 标题同 + 患者不冲突 + 方剂为引用型",
    "D1c": "同日 + 标题异 + 患者不冲突 + 方剂重合 ≥ 0.80",
    "D2": "同日 + 患者不冲突 + 标题同 + 方剂重合 < 0.80",
    "D3": "同日 + 标题同 + 患者确为两人",
    "D4": "同日 + 患者同一人 + 标题不同 + 方剂不像",
    "D6a": "患者同一人 + 标题同 + 方剂重合 ≥ 0.95，且一侧日期为空",
    "D6b": "跨日 + 患者同一人 + 标题同 + 方剂重合 ≥ 0.95，两侧日期都非空",
}


if __name__ == "__main__":
    main()
