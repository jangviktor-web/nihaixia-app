#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""合并同一就诊被拆成的两行医案（保留一行，另一行内容并入后删除）。

场景：App 原有的一行是「多次就诊叠加 + 句子被切断的蒸馏残行」，补入时又按 md
新增了一行完整记录，于是同一就诊出现两条。合并方向固定为「保留原序号那行」，
把新行的内容并进去，再删新行——原序号不挪位，历史溯源标记也留在原处。

并规则（只为「不丢东西」，不重写、不润色）：
  主要诊断  保留行优先，若为空才取对方
  病因分析  保留行若等于诊断（占位复述）→ 换成对方的三诊；否则有差异就追加
  方剂/结果/医嘱/观点  保留行为空取对方；两边近似同一段文字→取较完整的那份；
                        确实不同才追加，中间用「 ｜ 」
  针灸      保留行是「无/未提及/空」时取对方；两侧都是空义词则保持原值（空优先）
  治法      两边 <md:N> 标记去重合并

为什么要有「近似同一段文字」这道：D1a 判出来的两个行，方剂本来就是同一张方，
差异只在标点与 `HT-2`／`HTS2` 这类字符级退化。只做子串包含判断的话，这种会走
「追加」分支，拼出两遍近似重复的方剂。

用法：
    python tool/merge_duplicate_cases.py                 # dry-run，打印合并后各列
    python tool/merge_duplicate_cases.py --apply          # 写回（备份 .bak-merge）
映射文件：tool/case_merge_map.tsv（保留序号<TAB>被并序号<TAB>备注）
"""
import argparse
import difflib
import os
import re
import shutil
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = os.path.join(REPO, "assets", "medical_cases", "cases_table.md")
MAP = os.path.join(os.path.dirname(os.path.abspath(__file__)), "case_merge_map.tsv")

# ⚠ 这里是原始 split('|') 的下标（0 是行首的空串），不是 read_app 那种去首尾竖线的下标。
# 早先按 COL[j-1] 取名导致整体错位一列，把「患者」当「诊断」合并（已修）。
COL = ["", "序号", "日期", "患者", "主要诊断", "病因分析", "西医背景",
       "方剂", "针灸", "治法", "结果", "医嘱", "观点"]
IDX_DX, IDX_TAGS = 5, 9          # 病因分析 / 治法
KEEP_AS_IS = (2, 3, 4)           # 日期 / 患者 / 主要诊断：同一就诊，保留原值不拼
EMPTY_ISH = ("", "无", "未提及", "（空）")
SEP = " ｜ "


def load_map():
    out = []
    if not os.path.exists(MAP):
        return out
    for ln in open(MAP, encoding="utf-8-sig"):
        if not ln.strip() or ln.lstrip().startswith("#"):
            continue
        p = [x.strip() for x in ln.rstrip("\n").split("\t")]
        if len(p) >= 2 and p[0].isdigit() and p[1].isdigit():
            out.append((p[0], p[1], p[2] if len(p) > 2 else ""))
    return out


def _flat(s):
    """抹掉标点空白，只留字。保留数字与拉丁字母——剂量 `3钱`/`5钱`、`HT-2`/`HTS2`
    的差异正是要保住的信息，不能跟着标点一起抹掉。"""
    return re.sub(r"[\s，。、；：""''（）()【】\[\]{}—\-－_/\\:.,·|!！?？~～]+", "", s)


def _cprefix(a, b):
    """共同前缀长度。"""
    n = 0
    for x, y in zip(a, b):
        if x != y:
            break
        n += 1
    return n


def kinship(a, b):
    """两段文字的关系：same / longer / differ（在抹平标点后判断）。

    same   视为同一段文字，别拼（免得同一段出现两遍）
    longer 一方是另一方的子串，或共同前缀占短串 ≥ 85%（尾部被扩写）→ 取较完整那份
    differ 确实两段不同 → 才拼 ` ｜ `
    """
    if not a or not b:
        return "differ"
    fa, fb = _flat(a), _flat(b)
    if not fa or not fb:
        return "same" if a == b else "differ"
    if fa == fb:
        return "same"
    if fa in fb or fb in fa:
        return "longer"
    if _cprefix(fa, fb) >= 0.85 * min(len(fa), len(fb)):
        return "longer"
    if difflib.SequenceMatcher(None, fa, fb).ratio() >= 0.90:
        return "same"
    return "differ"


def pick(keep, drop, is_dx=False, keep_dx=None, is_acup=False):
    """返回合并后的单元格。只为「不丢东西」，不重写、不润色。"""
    k, d = keep.strip(), drop.strip()
    if is_acup:
        # 「无 / 未提及」都是空义词。两侧都空义时保留原值，空为空（详情页才会隐藏该栏）
        if k in EMPTY_ISH:
            return d if d not in EMPTY_ISH else k
        if d in EMPTY_ISH or d in k:
            return k
        return k + SEP + d
    if is_dx:
        # 保留行的病因分析若只是诊断的复述，视为占位，换掉
        if k and keep_dx is not None and k == keep_dx.strip():
            return d or k
    if not k:
        return d
    if not d:
        return k
    rel = kinship(k, d)
    if rel == "same":
        return k
    if rel == "longer":
        return d if len(d) > len(k) else k
    return k + SEP + d


def merge_tags(*cells):
    tags = []
    for c in cells:
        for t in re.findall(r"<md:[^>]+>", c or ""):
            if t not in tags:
                tags.append(t)
    return tags


def render(c):
    """把 split('|') 的 14 元素写回标准表格行 `| a | b | … |`。

    `"|".join(c)` 也能还原成合法表格，但空列会变成 `||`，与表内其余行的
    `|  |` 风格不一致，读起来像缺列。统一走这里。
    """
    return "| " + " | ".join(x.strip() for x in c[1:-1]) + " |"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    pairs = load_map()
    if not pairs:
        print("映射文件为空或不存在：%s" % MAP)
        return

    raw = open(APP, "rb").read()
    crlf = b"\r\n" in raw
    lines = raw.decode("utf-8").replace("\r\n", "\n").split("\n")

    rows = {}
    for i, ln in enumerate(lines):
        c = ln.split("|")
        if len(c) == 14 and c[1].strip().isdigit():
            rows[c[1].strip()] = (i, c)

    plan = []
    dead = set()
    for keep_seq, drop_seq, note in pairs:
        if keep_seq not in rows or drop_seq not in rows:
            print("⚠ 跳过 %s←%s：序号不存在（已合并过？）" % (keep_seq, drop_seq))
            continue
        ki, kc = rows[keep_seq]
        di, dc = rows[drop_seq]
        new = list(kc)
        for j in range(2, 13):
            if j in KEEP_AS_IS:
                # 同一就诊：非空就不动（不拼），但保留行为空时必须取对方，
                # 否则 #1186 那种只剩诊断的骨架行永远补不上患者与日期
                if not kc[j].strip():
                    new[j] = dc[j].strip()
                continue
            new[j] = pick(kc[j], dc[j],
                          is_dx=(j == IDX_DX), keep_dx=kc[4], is_acup=(j == 8))
        # 治法：先剥掉原有标记再拼去重后的全集，否则会出现 `<md:1223> … <md:1223>`
        base = re.sub(r"<md:[^>]+>", "", kc[IDX_TAGS]).strip()
        new[IDX_TAGS] = " ".join([base] + merge_tags(kc[IDX_TAGS], dc[IDX_TAGS])).strip()
        plan.append((keep_seq, drop_seq, kc, new, note))
        dead.add(di)

    if not plan:
        print("无可合并项。")
        return

    for keep_seq, drop_seq, kc, new, note in plan:
        print("=" * 96)
        print("保留 #%s　并入 #%s　%s" % (keep_seq, drop_seq, note))
        for j in range(2, 13):
            a, b = kc[j].strip(), new[j].strip()
            if a != b:
                if j == IDX_DX and a == kc[4].strip():
                    mark = "占位替换"
                elif not a:
                    mark = "空→补"
                else:
                    mark = "追加"
                print("  [%s] %s" % (COL[j], mark))
                print("     旧: %s" % (a[:150] or "（空）"))
                print("     新: %s" % (b[:300] or "（空）"))
        print("  → 删除 #%s 整行" % drop_seq)

    print("\n合计 %d 组，将删除 %d 行" % (len(plan), len(dead)))
    if not args.apply:
        print("dry-run，未写回。确认后加 --apply")
        return

    for keep_seq, drop_seq, kc, new, note in plan:
        ki = rows[keep_seq][0]
        lines[ki] = render(new)
    out_lines = [ln for i, ln in enumerate(lines) if i not in dead]

    shutil.copy2(APP, APP + ".bak-merge")
    out = "\n".join(out_lines)
    if crlf:
        out = out.replace("\n", "\r\n")
    open(APP, "wb").write(out.encode("utf-8"))
    print("[apply] 备份 -> %s" % (APP + ".bak-merge"))
    print("[apply] 已写回，行数 %d -> %d" % (len(lines), len(out_lines)))


if __name__ == "__main__":
    main()
