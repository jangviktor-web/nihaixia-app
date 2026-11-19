#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成医案补入的工作交付稿与复核清单（消费 fill_medical_cases_from_md.py 的判据）。

用法：
  python tool/gen_case_fill_report.py [--base HEAD]
产出：
  docs/medical_case_fill_report_<日期>.md     工作交付稿
  docs/medical_case_review_list_<日期>.md     待复核清单
 ponytail: 只读 git 与现有文件，不修改任何数据；日期写死为运行日。
"""
import os, re, sys, subprocess, argparse, datetime
from collections import defaultdict, Counter
import importlib.util

HERE = os.path.dirname(os.path.abspath(__file__))
REPO = os.path.dirname(HERE)
spec = importlib.util.spec_from_file_location("fill", os.path.join(HERE, "fill_medical_cases_from_md.py"))
fill = importlib.util.module_from_spec(spec); spec.loader.exec_module(fill)
spec2 = importlib.util.spec_from_file_location("norm", os.path.join(HERE, "normalize_case_format.py"))
norm = importlib.util.module_from_spec(spec2); spec2.loader.exec_module(norm)

def canon(v, idx):
    """比对前把排版归一抵消掉：纯格式变化（箭头统一、乱码清理、空尾标签）
    不算「补了内容」，否则 60 多行会被误报成实质回填。"""
    return norm.fix_cell(str(v or "").strip(), idx == 4)

COL = ["序号", "日期", "患者", "主要诊断(中医)", "中医病因分析(关键病机)", "西医背景与观点",
       "具体方剂剂量/治疗组成", "针灸方案", "中医治疗方法(原则)", "疗程/结果", "生活医嘱", "倪师核心观点/评论"]
# 回填列 -> 对应的 md 小节
COL2SEC = {4: ["来诊原因", "问诊", "脉诊", "望诊"], 6: ["中药处方"], 7: ["针灸处方"], 11: ["解说"]}

def rows_of(text):
    out = {}
    for ln in text.split("\n"):
        c = [v.strip() for v in ln.strip().strip("|").split("|")]
        if len(c) < 2 or not c[0].isdigit(): continue
        c += [""] * (12 - len(c))
        out[int(c[0])] = c
    return out

def clip(s, n=140):
    s = re.sub(r"\s+", " ", str(s or "")).strip()
    return s if len(s) <= n else s[:n] + "…"

def cell(s, n=200):
    return clip(s, n).replace("|", "／")

def srckey(x):
    """稳定标识：优先后取 yixue 行号，退化取 md 文件序号。"""
    src = str(x["fm"].get("source", ""))
    m = re.search(r"第(\d+)条", src)
    if m: return "第%s条" % m.group(1)
    m = re.match(r"(\d+)_", x["file"])
    return m.group(1) if m else "?"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--base", default="HEAD")
    args = ap.parse_args()

    before_txt = subprocess.run(["git", "show", f"{args.base}:assets/medical_cases/cases_table.md"],
                                cwd=REPO, capture_output=True, text=True, encoding="utf-8").stdout
    after_txt = open(fill.APP, encoding="utf-8").read()
    b, a = rows_of(before_txt), rows_of(after_txt)
    if not b: sys.exit(f"无法从 {args.base} 取到补入前基线")

    # md 源索引：srcrow -> 记录
    md_by_row = {}
    for x in fill.load_dir(fill.MD_DIR):
        if x["srcrow"]: md_by_row[x["srcrow"]] = x

    # 差异分类
    real_fill, tag_only, added = [], [], []
    for seq in sorted(set(b) & set(a)):
        diffs = [(i, b[seq][i], a[seq][i]) for i in range(12)
                 if canon(b[seq][i], i) != canon(a[seq][i], i)]
        if not diffs: continue
        src = re.search(r"<md:([^>]+)>", a[seq][8])
        row = (seq, diffs, src.group(1) if src else "")
        if all(i == 8 for i, _, _ in diffs): tag_only.append(row)
        else: real_fill.append(row)
    for seq in sorted(set(a) - set(b)):
        src = re.search(r"<md:([^>]+)>", a[seq][8])
        added.append((seq, a[seq], src.group(1) if src else ""))

    # 复核清单：复现三分类
    up = fill.load_dir(fill.MD_DIR)
    uniq, _, _ = fill.dedupe_cases(up)
    acodes, adates = defaultdict(list), defaultdict(list)
    for r in fill.read_app(fill.APP)[2]:
        c = fill.code(r[2])
        if c: acodes[c].append(r)
        if r[1]: adates[r[1][:10]].append(r)
    existing = set()
    for r in fill.read_app(fill.APP)[2]:
        for v in r: existing.update(re.findall(r"<md:([^>]+)>", v))
    review = []
    decisions = fill.load_decisions()
    for x in uniq:
        if decisions.get(x["file"]): continue             # 已人工判定，不再进复核清单
        if str(x["srcrow"] or x["file"]) in existing: continue
        cand = list(acodes.get(x["code"], [])) if x["code"] else []
        if cand and x["date"]:
            cand = [r for r in cand if r[1][:10] == x["date"]] or cand
        if not cand and x["date"]: cand = list(adates.get(x["date"], []))
        best, bs = None, 0.0
        for r in cand:
            v = fill.score(x, r)
            if v > bs: best, bs = r, v
        same_visit = bool(x["code"] and x["date"] and any(
            fill.code(r[2]) == x["code"] and r[1][:10] == x["date"] for r in cand))
        if same_visit and best is not None: continue      # 已判回填，不进复核
        if fill.LOW <= bs < fill.HIGH: review.append((bs, x, best))
    review.sort(key=lambda t: -t[0])

    day = datetime.date.today().isoformat()
    head = subprocess.run(["git", "rev-parse", "--short", args.base], cwd=REPO,
                          capture_output=True, text=True).stdout.strip()
    branch = subprocess.run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=REPO,
                            capture_output=True, text=True).stdout.strip()

    # ---------------- 交付稿 ----------------
    L = []
    L.append("# 医案补入工作交付稿\n")
    L.append(f"- 生成时间：{day}")
    L.append(f"- 分支：`{branch}`　补入前基线：`{args.base}`（{head}）")
    L.append(f"- 数据源：`{fill.MD_DIR}`（医案上）")
    L.append(f"- 目标：`assets/medical_cases/cases_table.md`\n")
    L.append("## 一、总体结果\n")
    L.append("| 项目 | 数量 |")
    L.append("|---|---|")
    L.append(f"| 补入前医案行 | {len(b)} |")
    L.append(f"| 补入后医案行 | {len(a)} |")
    L.append(f"| 新增医案（App 原本没有） | {len(added)} |")
    L.append(f"| 实质内容回填（真正补了空列） | {len(real_fill)} |")
    L.append(f"| 仅补溯源标记（原内容已完整） | {len(tag_only)} |")
    L.append(f"| 待人工复核（未写入） | {len(review)} |\n")
    L.append(f"> 说明：回填判定共 {len(real_fill) + len(tag_only)} 条属同一案，其中绝大多数 App 原有内容已完整，"
             f"按「只填空列不覆盖」原则仅写入 `<md:行号>` 溯源标记；真正补充内容的只有 {len(real_fill)} 行。\n")

    L.append("## 二、判据与口径\n")
    L.append("- 去重：source 行号 + 正文全字段签名；医案下 1269 份为医案上副本（零独有），不单独导入")
    L.append(f"- 分类阈值：≥{fill.HIGH} 判同一案回填；{fill.LOW}–{fill.HIGH} 人工复核；<{fill.LOW} 新增")
    L.append("- 守恒：`回填 + 复核 + 新增 + 已补跳过 == 去重后 md 数`，不成立即断言失败")
    L.append("- 幂等：每行治法列写 `<md:行号>`，重复运行不新增、不覆盖\n")
    L.append("字段映射：\n")
    L.append("| md 小节 | App 列 |")
    L.append("|---|---|")
    L.append("| 性别 + 年龄及体型 | 患者 |")
    L.append("| 标题诊断段 | 主要诊断(中医) |")
    L.append("| 来诊原因 + 问诊 + 脉诊 + 望诊 | 中医病因分析（`【主诉】【问诊】【脉诊】【望诊】`） |")
    L.append("| 中药处方 | 具体方剂剂量/治疗组成 |")
    L.append("| 针灸处方 | 针灸方案 |")
    L.append("| 解说 | 倪师核心观点/评论 |")
    L.append("| 来源行号 | 中医治疗方法(原则) 列 `<md:N>` |\n")

    L.append(f"## 三、实质内容回填 {len(real_fill)} 行（补入前 → 补入后）\n")
    for seq, diffs, src in real_fill:
        md = md_by_row.get(int(src)) if src.isdigit() else None
        L.append(f"### 序号 {seq}　{a[seq][1]}　{a[seq][3] or '（无诊断）'}\n")
        L.append(f"- 来源：`{md['file'] if md else src}`\n")
        for i, old, new in diffs:
            if i == 8: continue
            L.append(f"**{COL[i]}**\n")
            L.append(f"- 补入前：{old if old.strip() else '（空）'}")
            L.append(f"- 补入后：{new}\n")
            if md:
                s = md["sec"]
                for k in COL2SEC.get(i, []):
                    if s.get(k): L.append(f"- md 原文〔{k}〕：{s[k]}\n")
        L.append("")

    L.append(f"## 四、新增医案 {len(added)} 条\n")
    L.append("| 序号 | 日期 | 患者 | 主要诊断 | 方剂（摘要） | 针灸 | 来源 md |")
    L.append("|---|---|---|---|---|---|---|")
    for seq, r, src in added:
        fn = md_by_row[int(src)]["file"] if src.isdigit() and int(src) in md_by_row else src
        L.append(f"| {seq} | {r[1]} | {cell(r[2], 40)} | {cell(r[3], 40) or '（源标题无诊断）'} | "
                 f"{cell(r[6], 120)} | {cell(r[7], 40)} | `{fn}` |")
    L.append("")
    L.append(f"<details>\n<summary>展开新增医案全文（{len(added)} 条）</summary>\n")
    for seq, r, src in added:
        L.append(f"### {seq}　{r[1]}　{r[3] or '（无诊断）'}\n")
        L.append(f"- 患者：{r[2] or '（空）'}")
        for i in (4, 6, 7, 11):
            if r[i]: L.append(f"- {COL[i]}：{r[i]}")
        L.append(f"- 来源：`{src}`\n")
    L.append("</details>\n")

    L.append(f"## 五、仅补溯源标记 {len(tag_only)} 行\n")
    L.append("这些 App 原有医案的四类内容列均已非空，按「不覆盖已有内容」原则未改动，仅在治法列写入来源行号。\n")
    L.append("| 序号 | 日期 | 主要诊断 | 来源 md |")
    L.append("|---|---|---|---|")
    for seq, _, src in tag_only:
        fn = md_by_row[int(src)]["file"] if src.isdigit() and int(src) in md_by_row else src
        L.append(f"| {seq} | {a[seq][1]} | {cell(a[seq][3], 50) or '（无诊断）'} | `{fn}` |")
    L.append("")

    p1 = os.path.join(REPO, "docs", f"medical_case_fill_report_{day}.md")
    open(p1, "w", encoding="utf-8", newline="\n").write("\n".join(L))

    # ---------------- 复核清单 ----------------
    R = []
    R.append("# 医案待复核清单\n")
    R.append(f"- 生成时间：{day}　分支：`{branch}`")
    R.append(f"- 共 **{len(review)}** 条：md 与 App 现有医案相似度落在 {fill.LOW}–{fill.HIGH}，脚本未自动写入")
    R.append("- 判定方式：逐条勾选「同一案」则回填三诊字段，「不同案」则作为新增，存疑则暂不处理\n")
    R.append("| # | 源行号 | 相似度 | md 标题 | App 疑似序号 | 判定 |")
    R.append("|---|---|---|---|---|---|")
    for n, (v, x, r) in enumerate(review, 1):
        R.append(f"| {n} | {srckey(x)} | {v:.2f} | {cell(x['fm'].get('title',''), 60)} | {r[0] if r else '无'} | □同一案 □不同案 □存疑 |")
    R.append("")
    R.append("> `#` 是本次清单的顺序号，判定后条目会移出、编号会前移；回复判定时请用**源行号**或标题，避免对不上。\n")
    R.append("---\n")
    for n, (v, x, r) in enumerate(review, 1):
        s = x["sec"]
        R.append(f"## {n}. {x['fm'].get('title','')}　`{srckey(x)}`\n")
        R.append(f"- **相似度**：{v:.2f}　**来源**：`{x['file']}`　`{x['fm'].get('source','')}`")
        R.append(f"- **md 日期**：{x['date']}　**患者**：{s.get('性别','')} {s.get('年龄及体型','')}")
        for k in ("来诊原因", "问诊", "脉诊", "望诊", "中药处方", "针灸处方", "解说"):
            if s.get(k): R.append(f"- **md〔{k}〕**：{clip(s[k], 260)}")
        if r:
            R.append(f"\n**App 疑似对应 # {r[0]}**（{r[1]}　{r[3] or '无诊断'}）")
            for i in (4, 6, 7, 11):
                if r[i]: R.append(f"- App〔{COL[i]}〕：{clip(r[i], 260)}")
        R.append("\n- 判定：□ 同一案（应回填）　□ 不同案（应新增）　□ 存疑\n")
        R.append("---\n")

    p2 = os.path.join(REPO, "docs", f"medical_case_review_list_{day}.md")
    open(p2, "w", encoding="utf-8", newline="\n").write("\n".join(R))

    print(f"交付稿: {p1}  ({len(added)} 新增 / {len(real_fill)} 实质回填 / {len(tag_only)} 仅标记)")
    print(f"复核单: {p2}  ({len(review)} 条)")

if __name__ == "__main__":
    main()
