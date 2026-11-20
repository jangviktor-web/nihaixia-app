#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把「中医病因分析」列里的四诊内容拆进独立的第 13 列「四诊记录」。

现状：入口的病因分析列混着两类东西——
  · 235 行整条是 `【主诉】…【问诊】…【脉诊】…【望诊】…`（回填时拼进去的）
  · 592 行是纯病机短句（「肝功能未恢复」「乳癌已破口」）
后果：详情页「中医病机」一栏对前 235 行显示成四诊流水账；llm_service 只取这列
前 40 字当「病机」，四诊信息全丢。

本脚本：源 md 有来诊原因/问诊/望诊/脉诊的，统一拼成
`【主诉】…【问诊】…【望诊】…【脉诊】…`（望在脉前，合「望闻问切」，段间单空格）
写入新的第 13 列；病因分析列只保留病机（原本纯四诊的行清空）。
源里缺哪一段就跳过哪一段，不补空标签。加在末尾是为了前 12 列下标全部不变。

用法：
  python tool/split_case_four_diagnoses.py            # dry-run，只出统计与样例
  python tool/split_case_four_diagnoses.py --apply     # 写回（自动备份）

 ponytail: 标签顺序、列名、分隔符全写死在本文件顶部，不建 config 层。
"""
import os
import re
import sys
import shutil
import argparse
from collections import Counter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fill_medical_cases_from_md as fill          # 复用 md 解析与清洗

COLS = 13                     # 12 + 四诊记录
NEW_COL = "四诊记录"
I_MECH, I_TAG = 4, 8          # 病因分析、治法（承载 <md:N>）

# 顺序即输出顺序：主诉 → 问诊 → 望诊 → 脉诊
FOUR = (("来诊原因", "主诉"), ("问诊", "问诊"), ("望诊", "望诊"), ("脉诊", "脉诊"))
TAG = re.compile(r"【(主诉|问诊|望诊|脉诊)】")
MD_TAG = re.compile(r"<md:(\d+)>")


def build_four(x):
    """源 md 记录 → 统一格式的四诊串；一段都没有则返回空串。"""
    out = []
    for key, lab in FOUR:
        v = x["sec"].get(key)
        if v:
            out.append("【%s】%s" % (lab, fill.scrub_brackets(fill.clean_cell(v))))
    return " ".join(out)


def split_cells(line):
    """`| a | b |` → ['a','b']（去首尾外框竖线，保留内部空单元格）。"""
    s = line.strip()
    if not s.startswith("|"):
        return None
    cells = [x.strip() for x in s.strip("|").split("|")]
    return cells


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    # 源：与 fill 完全同源同去重，保证取到的是「保留的那一份」
    up = fill.load_dir(fill.MD_DIR)
    down = fill.load_dir(fill.MD_DOWN)
    uniq, _, _ = fill.dedupe_cases(up)
    src = {r["srcrow"]: r for r in uniq}
    for r in down:
        src.setdefault(r["srcrow"], r)

    text = open(fill.APP, encoding="utf-8", newline="").read()
    crlf = text.count("\r\n") > text.count("\n") // 2
    lines = text.split("\n")

    out, stat = [], Counter()
    samples = []
    for ln in lines:
        body = ln.rstrip("\r")
        cells = split_cells(body)
        if cells is None or not cells:
            out.append(ln)
            continue

        # 主表表头 / 分隔行（恰好 12 列，或已是 13 列的旧产物）
        if cells[0] == "序号":
            base = [c for c in cells][:12]
            out.append("| " + " | ".join(base + [NEW_COL]) + " |")
            stat["表头"] += 1
            continue
        if all(set(c) <= {"-"} for c in cells):
            base = cells[:12]
            out.append("| " + " | ".join(base + ["---"]) + " |")
            stat["分隔"] += 1
            continue
        if not cells[0].isdigit():
            out.append(ln)
            continue

        # 数据行：幂等——已是 13 列就丢掉旧的四诊列重算
        c = (cells + [""] * COLS)[:COLS]
        mech, tagcell = c[I_MECH], c[I_TAG]
        m = MD_TAG.search(tagcell)
        four = build_four(src[int(m.group(1))]) if (m and int(m.group(1)) in src) else ""

        if TAG.search(mech):
            # 整条都是四诊 → 搬走，病机留空
            if not four:
                four = mech                       # 源里取不到就保留原文，别丢内容
                stat["搬走（源无四诊，保留原文）"] += 1
            else:
                stat["搬走"] += 1
            mech = ""
        elif four:
            stat["病机 + 新增四诊"] += 1
        else:
            stat["原样（无四诊可补）"] += 1

        if four and len(samples) < 3:
            samples.append((c[0], four))

        row = c[:12]
        row[I_MECH] = mech
        out.append("| " + " | ".join(row + [four]) + " |")

    stat["数据行"] = sum(v for k, v in stat.items()
                     if k in ("搬走", "搬走（源无四诊，保留原文）", "病机 + 新增四诊", "原样（无四诊可补）"))
    stat["四诊非空"] = stat["搬走"] + stat["病机 + 新增四诊"]

    print("== 统计")
    for k in ("数据行", "搬走", "搬走（源无四诊，保留原文）", "病机 + 新增四诊", "原样（无四诊可补）", "四诊非空"):
        print("  %-26s %d" % (k, stat[k]))
    print("  %-26s %d" % ("表头/分隔改写", stat["表头"] + stat["分隔"]))

    print("\n== 样例")
    for seq, four in samples:
        print("  #%-5s %s" % (seq, four[:140]))

    # 自检：13 列、无 ||、四诊列首段必是【主诉】或【问诊】
    bad = []
    for ln in out:
        cells = split_cells(ln.rstrip("\r"))
        if not cells or not cells[0].isdigit():
            continue
        if len(cells) != COLS:
            bad.append(("列数", cells[0], len(cells)))
            continue
        f = cells[12]
        if f and not re.match(r"^【(主诉|问诊|望诊|脉诊)】", f):
            bad.append(("四诊首段", cells[0], f[:30]))
        extra = [t for t in re.findall(r"【([^】]+)】", f)
                 if t not in ("主诉", "问诊", "望诊", "脉诊")]
        if extra:
            bad.append(("四诊含异物标签", cells[0], extra[:3]))
    assert not bad, bad[:5]
    print("\n自检：13 列对齐、四诊列标签开头 — 通过")

    if not args.apply:
        print("\n[dry-run] 未写文件。加 --apply 写回。")
        return

    bak = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                       ".workbuddy", "backup", "20261120_case_md",
                       "cases_table.md.before-fourdx")
    os.makedirs(os.path.dirname(bak), exist_ok=True)
    if not os.path.exists(bak):
        shutil.copy2(fill.APP, bak)
        print("\n备份 ->", os.path.basename(bak),
              "（放 .workbuddy，不要放 assets——目录声明会把 .bak 一起打进包）")
    nl = "\r\n" if crlf else "\n"
    with open(fill.APP, "w", encoding="utf-8", newline="") as f:
        f.write(nl.join(x.rstrip("\r") for x in out))
    raw = open(fill.APP, "rb").read()
    print("已写回：%d 字节 | CRLF %d | 裸 LF %d | `||` %d"
          % (len(raw), raw.count(b"\r\n"),
             raw.count(b"\n") - raw.count(b"\r\n"), raw.decode("utf-8").count("||")))


if __name__ == "__main__":
    assert build_four({"sec": {}}) == ""
    assert build_four({"sec": {"问诊": "a", "脉诊": "b"}}) == "【问诊】a 【脉诊】b"
    assert TAG.search("【望诊】舌淡") and not TAG.search("【下焦寒实】x")
    assert fill.scrub_brackets("体内积【水】") == "体内积〔水〕"
    main()
