#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""只补「观点」列的空格（stdlib，幂等，默认 dry-run）。

为什么单独一个脚本，而不是改 `fill_medical_cases_from_md.py`：
后者的幂等判据是**条目级**——只要某条源的 `<md:N>` 标记已出现在表里任一行，
整条就 `skip`，于是「行已存在但观点列为空」的情况永远补不上（早期观点的
字段映射还没写，所以有 119 行留空）。修它要动 378 行的匹配/判分链路，
风险高于收益；这里只做一件事，可单独验证、可单独回滚。

取源规则：`## 解说` 优先，无则 `## 备注`（与 fill 的 view 字段一致）。
上下两册条目号重叠，先上册后下册，取第一个非空的。

用法：
    python tool/fill_case_view_column.py           # dry-run，打印将补的内容
    python tool/fill_case_view_column.py --apply    # 写回（备份 .bak-view）
"""
import argparse
import glob
import os
import re
import shutil

_HERE = os.path.dirname(os.path.abspath(__file__))
_SRC = os.path.join(_HERE, "source", "renji_case_md")
APP = os.path.join(os.path.dirname(_HERE), "assets", "medical_cases", "cases_table.md")

COL_VIEW = 11  # 0 基：序号 0 / 日期 1 / 患者 2 / 诊断 3 / 病机 4 / 西医 5 /
               # 方剂 6 / 针灸 7 / 治法 8 / 结果 9 / 医嘱 10 / 观点 11 / 四诊 12
COL_TAG = 8


def load_source(sub):
    out = {}
    for p in glob.glob(os.path.join(_SRC, sub, "*.md")):
        m = re.match(r"(\d{4})_", os.path.basename(p))
        if not m:
            continue
        out.setdefault(int(m.group(1)), []).append(
            open(p, encoding="utf-8").read())
    return out


def section(text, name):
    m = re.search(r"^## " + name + r"\s*\n(.*?)(?=^## |\Z)", text, re.M | re.S)
    return m.group(1).strip() if m else ""


def clean(s):
    """压成单行单元格：表格里不能有换行与裸竖线。"""
    s = re.sub(r"<(?:md:\d+|art:[^>]+)>", "", s)
    s = re.sub(r"\s*\n\s*", " ", s)
    s = s.replace("|", "／")
    return re.sub(r"\s{2,}", " ", s).strip()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    a = ap.parse_args()

    up = load_source("医案上")
    dn = load_source("医案下")

    raw = open(APP, "rb").read()
    crlf = b"\r\n" in raw
    lines = raw.decode("utf-8").replace("\r\n", "\n").split("\n")

    plan, no_src, no_tag = [], 0, 0
    for i, ln in enumerate(lines):
        if not ln.strip().startswith("|"):
            continue
        c = ln.split("|")
        if len(c) < 14 or not c[1].strip().isdigit():
            continue
        if c[COL_VIEW + 1].strip():          # split 后整体右移一位
            continue
        m = re.search(r"<md:(\d+)>", c[COL_TAG + 1])
        if not m:
            no_tag += 1
            continue
        n = int(m.group(1))
        val = ""
        for t in up.get(n, []) + dn.get(n, []):
            val = clean(section(t, "解说") or section(t, "备注"))
            if val:
                break
        if not val:
            no_src += 1
            continue
        plan.append((i, c, n, val))

    print("观点为空且有溯源标记：可补 %d 行 | 源无解说/备注 %d 行 | 该行无标记 %d 行"
          % (len(plan), no_src, no_tag))
    for i, c, n, val in plan[:8]:
        print("  #%s  <md:%d>  %s" % (c[1].strip(), n, val[:56]))
    if len(plan) > 8:
        print("  …… 其余 %d 行" % (len(plan) - 8))

    if not a.apply:
        print("\ndry-run，未写回。确认后加 --apply")
        return
    if not plan:
        print("\n无可补项，未改动文件。")
        return

    bak = APP + ".bak-view"
    shutil.copy2(APP, bak)
    for i, c, n, val in plan:
        c[COL_VIEW + 1] = " " + val + " "
        lines[i] = "|".join(c)
    out = "\n".join(lines)
    if crlf:
        out = out.replace("\n", "\r\n")
    open(APP, "wb").write(out.encode("utf-8"))
    print("\n[apply] 备份 -> %s\n[apply] 已补 %d 行" % (bak, len(plan)))


if __name__ == "__main__":
    main()
