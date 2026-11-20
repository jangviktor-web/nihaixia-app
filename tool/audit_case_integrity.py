#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""医案表完整性与「串行」体检（只读）。

串行 = 一行里的字段来自两个不同患者（源语料缝合错），判重九层抓不到，
只能靠「表头 vs 正文」互证。三处证据：

  1 标记  每行「治法」里的 `<md:N>` 指向某个源 md；该 md 的性别与本行患者
          性别冲突 → 这一行或这个标记被缝过。
  2 语汇  患者写「男」而正文出现女性专属语汇（月经/奶水/乳房/怀孕…）→ 疑。
          只收不会在别的词里当子串的词：`白带` 会被「苍白带黄」误命中，已剔除。
  3 源语料 同一患者码出现两种性别，或同一方剂指纹落在不同性别的人身上
          → 源数据本身缝过。

完整性另查：列数 / 序号 / 日期 / 门禁可见性 / 标记唯一 / 空列率。

用法：
    python tool/audit_case_integrity.py          # 全部检查，只打印
"""
import collections
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import fill_medical_cases_from_md as fill          # 复用 md 解析与 App 读取

COLS = 13
I_NO, I_DATE, I_PT, I_FORM, I_TAGS = 0, 1, 2, 6, 8

# 已逐条查证、判定为「源语料自身瑕疵，App 侧值正确」的项，不再计入待处理。
# 键用「序号」或「患者码 / 方剂指纹」的原文片段，值写判定依据（保留，防止下次重查）。
KNOWN_SRC_FLAW = {
    "530": "md 0011_165S4C,MC（165 号男，弱视）是幂等指纹误挂，内容与患者栏均属 "
           "060 号女（双侧乳癌，50岁瘦小）；标记必须保留——删掉会让 fill 重跑时"
           "把 165 号男性的内容回填进来",
    "590": "md 0856_117S11SS,T（117 号男，肺积水）同上，内容属 060 号女；同上需保留标记",
    "756": "md 0899_SStephen,Nicholas 性别误写 F；Stephen/Nicholas 为男名、"
           "病程为肝癌，App「男，62岁」为准",
    "245W,T": "源语料编号 245 被两人共用：36 岁高个男（阳明经腑热，md 0283/0528 "
              "重复文件）与 43 岁丰腴女（脑瘤术后，md 0284）；"
              "App #608 / #671 各自正确，无串行",
    "同4/16方去当归防己五钱茯苓五钱入": "117 号男性（117S1SS,T）的记录里混进了 060 号女性"
                                       "（060S9L,ML）的处方；App 侧已由 "
                                       "case_merge_map.tsv 的 468←1351 pin=7,12 修正",
}

# ponytail: 词表够用就行，不加词典、不做 NLP。误报按「人工看一眼」处理。
F_ONLY = re.compile(r"月经|月事|经期|经水|奶水|母乳|哺乳|乳汁|乳房|左乳|右乳|"
                    r"子宫|停经|怀孕|妊娠|流产|堕胎|更年期|卵巢|阴道|分娩|产后")
M_ONLY = re.compile(r"阴茎|睾丸|前列腺|精虫|阳痿|包皮|阴囊")


def sex_of(s):
    s = (s or "").strip()
    if re.match(r"^(女|f|female)", s, re.I):
        return "女"
    if re.match(r"^(男|m|male)", s, re.I):
        return "男"
    return "?"


def load_rows():
    _raw, _lines, rows, _idx = fill.read_app(fill.APP)
    return rows


def load_md():
    """srcrow → md 记录。同一 srcrow 出现在医案上/下时取先到的那个（与 fill 一致）。"""
    rec = {}
    for r in fill.load_dir(fill.MD_DIR) + fill.load_dir(fill.MD_DOWN):
        rec.setdefault(r["srcrow"], r)
    return rec


def md_who(r):
    return (r["sec"].get("性别", "") + "，" + r["sec"].get("年龄及体型", "")).strip("，")


def main():
    raw = open(fill.APP, "rb").read()
    text = raw.decode("utf-8")
    rows = load_rows()
    md = load_md()
    bad_total = 0

    def bad(msg, items=()):
        nonlocal bad_total
        if not items:
            print("  ✓ %s：0" % msg)
            return
        print("  ✗ %s：%d" % (msg, len(items)))
        for x in items:
            print("      " + str(x))
        bad_total += len(items)

    def split_known(items):
        """剔出已定性为「源语料自身瑕疵、App 侧正确」的项，单列一行。"""
        keep, hit = [], 0
        for it in items:
            s = str(it)
            if any(k in s for k in KNOWN_SRC_FLAW):
                hit += 1
            else:
                keep.append(it)
        if hit:
            print("  · 已知源语料瑕疵 %d 项（见 KNOWN_SRC_FLAW，App 侧无需改动）" % hit)
        return keep

    print("== 一、完整性")
    print("  行数 %d | 字节 %d | CRLF %d | 裸 LF %d | `||` %d"
          % (len(rows), len(raw), raw.count(b"\r\n"),
             raw.count(b"\n") - raw.count(b"\r\n"), text.count("||")))
    bad("列数不是 %d 的数据行" % COLS,
        [r[0] for r in rows if len(r) != COLS])
    nos = [r[I_NO] for r in rows]
    bad("序号重复", [k for k, v in collections.Counter(nos).items() if v > 1])
    bad("序号未升序", [(nos[i], nos[i + 1]) for i in range(len(nos) - 1)
                   if int(nos[i]) > int(nos[i + 1])])
    gaps = sorted(set(range(1, int(nos[-1]) + 1)) - {int(x) for x in nos})
    print("  序号 1..%s，断号 %d 个（合并删行留下的，正常）"
          % (nos[-1], len(gaps)))
    dates = [r[I_DATE].strip() for r in rows]
    D_RE = re.compile(r"\d{4}-\d{2}-\d{2}(?: ~ \d{4}-\d{2}-\d{2})?")
    bad("日期格式不是 YYYY-MM-DD（或病程区间 A ~ B）",
        [(r[I_NO], d) for r, d in zip(rows, dates) if d and not D_RE.fullmatch(d)])
    bad("日期不存在（如 2 月 30）",
        [(r[I_NO], d) for r, d in zip(rows, dates) if d and not _is_date(d)])
    yr = collections.Counter(d[:4] for d in dates if d)
    print("  年份分布 %s；日期为空 %d 行" % (dict(sorted(yr.items())), dates.count("")))

    tags = re.findall(r"<md:(\d+)>", text)
    bad("md 标记重复", [k for k, v in collections.Counter(tags).items() if v > 1])
    bad("md 标记指向的条号不存在", [t for t in tags if int(t) not in md])
    gate = [r[I_NO] for r in rows
            if not r[I_FORM].strip() or "未公开" in r[I_FORM] or r[I_FORM].strip() == "未提及"]
    print("  门禁不可见（方剂空/未公开/未提及）：%d 行，App 内看不到" % len(gate))
    for i, nm in enumerate(["日期", "患者", "主要诊断", "病因分析", "西医背景",
                            "方剂", "针灸", "治法", "结果", "医嘱", "观点", "四诊记录"]):
        n = sum(1 for r in rows if not r[i + 1].strip())
        if n * 100 // len(rows) >= 5:
            print("  空列 %-6s %4d 行（%2d%%）" % (nm, n, n * 100 // len(rows)))

    print("\n== 二、串行：标记的源 md 与患者性别冲突")
    bad("冲突", split_known(
        [(r[I_NO], "App 患者=%s" % r[I_PT], rec["file"][:44],
          "md 性别=%s" % rec["sec"].get("性别", ""))
         for r in rows
         for t in re.findall(r"<md:(\d+)>", r[I_TAGS] or "")
         for rec in [md.get(int(t))]
         if rec and sex_of(r[I_PT]) not in "?" and sex_of(rec["sec"].get("性别", "")) not in "?"
         and sex_of(r[I_PT]) != sex_of(rec["sec"].get("性别", ""))]))

    print("\n== 三、串行：正文语汇与患者性别冲突")
    hits = []
    for r in rows:
        s = sex_of(r[I_PT])
        body = " ".join(r[3:12])
        if s == "男" and F_ONLY.search(body):
            hits.append((r[I_NO], "患者=男，出现「%s」" % F_ONLY.search(body).group(0), r[I_DATE]))
        elif s == "女" and M_ONLY.search(body):
            hits.append((r[I_NO], "患者=女，出现「%s」" % M_ONLY.search(body).group(0), r[I_DATE]))
    bad("疑", hits)

    print("\n== 四、串行：源语料自身（同患者码 / 同方剂）")
    byc = collections.defaultdict(list)
    for r in md.values():
        # 按标题首段原文归组。不能用 fill.code()——它抹前导 0，
        # 会把 11SS,R 与 011C,L 归成同一个「11-0」，产生假阳性。
        byc[re.sub(r"\s", "", r["fm"].get("title", "").split("｜")[0]).upper()].append(r)
    bad("同一患者码出现两种性别", split_known(
        [(c, sorted({sex_of(md_who(r)) for r in rs}),
          [(r["date"], r["file"][:38]) for r in rs][:3])
         for c, rs in byc.items()
         if c and len({sex_of(md_who(r)) for r in rs} - {"?"}) > 1]))
    grp = collections.defaultdict(set)
    for r in md.values():
        f = r["sec"].get("中药处方", "")
        if len(re.sub(r"\s", "", f)) >= 30:
            grp[re.sub(r"\s", "", f)[:24]].add((r["code"], sex_of(md_who(r)), r["file"][:34]))
    bad("同一方剂指纹落在不同性别的人身上", split_known(
        [(k[:18], sorted(v)[:3]) for k, v in grp.items()
         if len({c for c, _s, _f in v if c}) > 1 and len({s for _c, s, _f in v} - {"?"}) > 1]))

    print("\n== 五、日期分布（主区间 2005–2009，区间外仅提示不算缺陷）")
    # 区间外不是错误：2000–2004 是佛州开诊早年，2010–2011 是台北诊期，
    # 倪师 1990 年代已在佛州执业、2012 年初辞世，这些年份都真实存在。
    # 逐条核实过 12 行（患者栏多为「黄女士」「一位61岁的女性」这类描述式，
    # 源讲义本就没有规范患者名），全部为就诊日，无需改动。
    # 唯一硬错误判据是 >2012（辞世后不可能有记录）。
    out_of_main = [(r[I_NO], r[I_DATE], r[I_PT][:18]) for r in rows
                   if r[I_DATE][:4].isdigit()
                   and not 2005 <= int(r[I_DATE][:4]) <= 2009]
    must = [x for x in out_of_main if int(x[1][:4]) > 2012]
    print("  区间外 %d 行（真实早年/台北诊期，非缺陷）；其中晚于 2012（必错）%d 行"
          % (len(out_of_main), len(must)))
    for no, d, pt in out_of_main:
        print("      #%-6s %s  %s%s" % (no, d, pt, "   ← 必错" if (no, d, pt) in must else ""))

    print("\n合计待处理 %d 项" % bad_total)
    return 1 if bad_total else 0


def _is_date(d):
    """单日 YYYY-MM-DD，或病程区间 `A ~ B`（App 的年份筛选取前 4 位，区间合法）。"""
    import datetime
    parts = [p.strip() for p in d.split("~")]
    if len(parts) == 2 and all(parts):
        return _is_date(parts[0]) and _is_date(parts[1]) and parts[0] <= parts[1]
    if len(parts) != 1:
        return False
    try:
        y, m, dd = (int(x) for x in d.split("-"))
        datetime.date(y, m, dd)
        return True
    except (ValueError, TypeError):
        return False


if __name__ == "__main__":
    assert sex_of("女，50岁") == "女" and sex_of("F，70") == "女"
    assert sex_of("男") == "男" and sex_of("MALE，42岁") == "男"
    assert sex_of("072 L,J") == "?" and sex_of("") == "?"
    assert not F_ONLY.search("气色仍苍白带黄")          # 「白带」已剔出词表
    assert F_ONLY.search("月经不规则")
    assert _is_date("2008-02-29") and not _is_date("2009-02-30")
    assert _is_date("2006-05-09 ~ 2007-10-30")          # #2 病程区间
    assert not _is_date("2007-10-30 ~ 2006-05-09")      # 区间逆序
    sys.exit(main())
