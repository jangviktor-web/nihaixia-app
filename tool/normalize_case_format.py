#!/usr/bin/env python3
"""医案表排版归一（幂等，可重放）。

修两类源导出残留：

1. 区间标记 `N S N` —— 源 RTF 用 `->` 表示区间，导出链路把 `->` 变成 `S>`，
   之后又掉了 `>`，于是「6->7小时」成了「6S7小时」。归一为 `6→7`（与表内
   既有的 `喜按→虚` 同一风格）。
2. 病因分析列尾部的空诊断标签 —— 如 `... 眼诊： 特殊诊断耳诊：`，标签后面
   没有任何内容。连同悬挂的 `1、` 编号与空 `【望诊】` 段头一起清掉。

用法：
    python tool/normalize_case_format.py            # dry-run，只打印将改动的行
    python tool/normalize_case_format.py --apply    # 写回（先备份 .bak-fmt）
"""
import argparse
import os
import re
import shutil

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
APP = os.path.join(REPO, "assets", "medical_cases", "cases_table.md")

COL_DX, COL_FORMULA = 5, 7            # split('|') 后的下标：0 是空，1 起才是列
COL_NAME = ["序号", "日期", "患者", "主要诊断", "病因分析", "西医背景",
            "方剂", "针灸", "治法", "结果", "医嘱", "观点"]
# `6->7` 经导出链路成了 `6S7`；也有 `8S-10` 这种（`->` 掉了 `>`）。统一回 `→`。
RANGE = re.compile(r"(\d)\s*S\s*(?:[-—–]\s*)?(\d)")
# 不跟数字的 `S->` / `S>` / `S-`（源里都是 `->`），如「腿时抽筋 S- 喝蔗糖水」。
# 少数地方连写（「干裂脱皮SS->冬天…」），用 `(?:…)+` 整段吃掉。
# ⚠ 前面必须不是字母：`HTS-2` / `HTS68` 是汉唐方剂编号，不能被误伤。
# ⚠ 箭头尾巴是三种：`->`、`>`、`-`。早先只写了单字符类 `[-<>]`，
# `S->` 会只吃掉 `S-` 把 `>` 留在原地，再被下面的通用 `->`→`→` 处理掉，
# 于是留下「S→」（#1489 实际踩过）。必须整体匹配三字符。
S_RUN = r"(?<![A-Za-z])(?:S{1,2}(?:->|>|-))+"
S_ARROW = re.compile(S_RUN + r"(?=\s*[\u4e00-\u9fff])")     # 后面接汉字 → 是注解箭头
S_JUNK = re.compile(S_RUN + r"(?=\s*[（(→])")               # 后面接括号或箭头 → 纯残渣
# 旧版正则的工伤：`S->` 只吃了 `S-`，剩下的 `>` 被通用规则替换成 `→`，留下「S→」。
S_BROKEN = re.compile(r"(?<![A-Za-z])S→(?=\s*[（(\u4e00-\u9fff])")
# RTF 段落标记解码失败后的残渣（撒玛利亚字母区 U+0800–08FF）。原文是换行，
# 表格单元格里换行已被压平，直接去掉即可（例：「紫ࠂ根」→「紫根」、「2ࠂ钱」→「2钱」）。
MOJIBAKE = re.compile(r"[\u0800-\u08FF]")
LABELS = "舌诊|眼诊|耳诊|触诊|脊柱诊|特殊诊断耳诊|特殊诊断|望诊|问诊|脉诊"
EMPTY_LABEL = re.compile(r"(?:%s)[:：]\s*$" % LABELS)
DANGLING_NO = re.compile(r"\d+、\s*$")
# ⚠ 只清我们自己的分节头。表里还有 `【下焦寒实】` 这类真正的正文标记，
# 不能当成悬挂段头删掉（#616 曾因此丢内容）。
DANGLING_HEAD = re.compile(r"【(?:主诉|问诊|脉诊|望诊|触诊|其他)】\s*$")


def strip_empty_tail(s):
    """清掉尾部空诊断标签，以及因此悬挂的编号与段头。"""
    while True:
        for pat in (EMPTY_LABEL, DANGLING_NO, DANGLING_HEAD):
            t = pat.sub("", s).rstrip()
            if t != s:
                s = t
                break
        else:
            return s


def fix_cell(s, is_dx):
    out = MOJIBAKE.sub("", s)             # 乱码残渣先清，否则会干扰后面的字符类判断
    out = RANGE.sub(r"\1→\2", out)        # 6S7 → 6→7（必须先做，S_ARROW 会吃掉 S）
    out = S_ARROW.sub("→", out)           # 「S->合细辛」→「→合细辛」
    out = S_JUNK.sub("", out)             # 「S-S-S-(除…」→「(除…」
    out = S_BROKEN.sub("→", out)          # 修旧版留下的「S→」
    out = out.replace("-->", "→")         # 双横线箭头要先处理，否则会留半个 `-`
    out = out.replace("->", "→")          # 表内既有风格以 → 为主（方剂 55:36、观点 112:23）
    if is_dx:
        out = strip_empty_tail(out.strip())
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    raw = open(APP, "rb").read()
    crlf = b"\r\n" in raw
    lines = raw.decode("utf-8").replace("\r\n", "\n").split("\n")

    changed = []
    for i, ln in enumerate(lines):
        s = ln.strip()
        if not s.startswith("|") or not s.endswith("|"):
            continue
        c = ln.split("|")
        if len(c) != 14 or not c[1].strip().isdigit():
            continue
        for j in range(1, 13):                 # 全部 12 列；空尾标签规则只对病因分析生效
            old = c[j].strip()
            new = fix_cell(old, j == COL_DX)
            if new != old:
                c[j] = " " + new + " "
                changed.append((i + 1, c[1].strip(), j, old, new))
        lines[i] = "|".join(c)

    if not changed:
        print("无改动：排版已归一 ✓")
        return

    for ln_no, seq, j, old, new in changed:
        name = COL_NAME[j - 1]
        # 只截打印差异附近，避免刷屏
        m = 0
        while m < min(len(old), len(new)) and old[m] == new[m]:
            m += 1
        lo, hi = max(0, m - 18), min(len(old), m + 26)
        print("行%d  #%s  [%s]" % (ln_no, seq, name))
        print("   前…%s…" % old[lo:hi])
        print("   后…%s…" % new[lo:min(len(new), m + 34)])

    print("\n合计 %d 处（%d 行）" % (len(changed), len({x[0] for x in changed})))
    if not args.apply:
        print("dry-run，未写回。确认后加 --apply")
        return

    shutil.copy2(APP, APP + ".bak-fmt")
    out = "\n".join(lines)
    if crlf:
        out = out.replace("\n", "\r\n")
    open(APP, "wb").write(out.encode("utf-8"))
    print("[apply] 备份 -> %s" % (APP + ".bak-fmt"))
    print("[apply] 已写回")


if __name__ == "__main__":
    main()
