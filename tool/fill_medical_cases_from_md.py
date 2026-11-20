#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 renji_web 转出的医案 md 补入 App 的 cases_table.md（stdlib，幂等）。

用法：
  python tool/fill_medical_cases_from_md.py            # dry-run，只出报告
  python tool/fill_medical_cases_from_md.py --apply     # 写回（自动备份）

数据源默认见 MD_DIR；App 表固定为 assets/medical_cases/cases_table.md。
 ponytail: 阈值/目录写死在本文件顶部，不建 config 层——改判据就改这三个常量。
"""
import os, re, sys, shutil, argparse
from collections import defaultdict

MD_DIR = r"C:\Users\jangviktor\DoubaoWork\chats\2026-11-19\new-chat-5\renji_kb_md\03_医学\医案上"
MD_DOWN = r"C:\Users\jangviktor\DoubaoWork\chats\2026-11-19\new-chat-5\renji_kb_md\03_医学\医案下"
APP = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                   "assets", "medical_cases", "cases_table.md")
DECISIONS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "case_review_decisions.tsv")
HIGH, LOW = 0.62, 0.35          # 回填 / 人工复核 阈值
COLS = 13
I_DATE = 1                      # 日期列下标（0 是序号）

def load_decisions():
    """人工复核判定：文件名 -> 同一案/不同案/存疑。逐条累积，可重放。"""
    d = {}
    if os.path.exists(DECISIONS):
        for ln in open(DECISIONS, encoding="utf-8"):
            if not ln.strip() or ln.startswith("#"): continue
            p = ln.rstrip("\n").split("\t")
            if len(p) >= 3: d[p[1].strip()] = p[2].strip()
    return d

# ---------- 通用 ----------
def clean_cell(s):
    """表格单元格：去换行、压缩空白、转义竖线，保证一行一格。"""
    s = re.sub(r"\s*\n\s*", " ", str(s or ""))
    s = re.sub(r"[ \t]+", " ", s).strip()
    return s.replace("|", "／")

def scrub_brackets(s):
    """四诊正文自带的【】会与【主诉】等标签混淆，统一换成〔〕。

    实测源讲义里有 `体内积【水】`、`吃【interferon】`、`Tarceva【Target drug】`、
    `【瘀血】` 这类强调写法，不换掉的话「按标签取某一段」的正则会提前截断。
    """
    return str(s or "").replace("【", "〔").replace("】", "〕")

def to_iso(s):
    s = str(s or "").strip()
    d = re.search(r"(?<!\d)(20\d{2})(\d{2})(\d{2})(?!\d)", s)
    if d: return f"{d.group(1)}-{d.group(2)}-{d.group(3)}"
    n = re.findall(r"\d+", s)
    if len(n) < 3: return ""
    a, b, c = n[:3]
    if len(a) == 4: y, x, z = a, b, c
    elif len(c) == 4: y, x, z = c, a, b
    elif len(c) == 2: y, x, z = "20" + c, a, b
    else: return ""
    x, z = int(x), int(z)
    if x > 12 and z <= 12: x, z = z, x
    return f"{int(y):04d}-{x:02d}-{z:02d}" if 1 <= x <= 12 and 1 <= z <= 31 else ""

def code(s):
    s = re.sub(r"\s", "", str(s or "")).upper()
    m = re.match(r"^0*(\d{1,4})[-S]?0*(\d*)", s)
    return m.group(1).lstrip("0") + "-" + (m.group(2).lstrip("0") or "0") if m else None

def words(s):
    s = re.sub(r"[a-zA-Z0-9\s，。、；：\"'（）()【】\[\]—\-－_/\\:.,·|]", "", str(s or ""))
    return set(s[i:i+2] for i in range(len(s)-1))
def jac(a, b):
    a, b = words(a), words(b); return len(a & b) / len(a | b) if a and b else 0.0
def cover(small, big):
    a, b = words(small), words(big); return len(a & b) / len(a) if a else 0.0

# ---------- md ----------
def read_md(path):
    txt = open(path, encoding="utf-8").read()
    fm = {}
    if txt.startswith("---"):
        end = txt.find("\n---", 3)
        for ln in txt[3:end].split("\n"):
            m = re.match(r'(\w+):\s*"?(.*?)"?\s*$', ln)
            if m: fm[m.group(1)] = m.group(2)
    body = txt[end+4:] if end > 0 else txt
    sec = {}
    for m in re.finditer(r"^## (.+)$", body, re.M):
        nxt = body.find("\n## ", m.end())
        sec[m.group(1).strip()] = body[m.end():nxt if nxt > 0 else len(body)].strip()
    src = fm.get("source", "")
    if not ("1234567 ›" in src or "1234567_的副本 ›" in src):
        return None                                  # 忽略非医案 md
    title_parts = fm.get("title", "").split("｜")
    diag = title_parts[2].strip() if len(title_parts) > 2 else ""
    who = (title_parts[0] + "｜" + title_parts[1]) if len(title_parts) > 1 else title_parts[0]
    m = re.search(r"第(\d+)条", fm.get("source", ""))
    return {"fm": fm, "sec": sec, "diag": diag, "who": who,
            "code": code(title_parts[0]), "date": to_iso(fm.get("date", "")),
            "srcrow": int(m.group(1)) if m else None,
            "raw": txt, "file": os.path.basename(path)}

def load_dir(d):
    out = []
    if not os.path.isdir(d): return out
    for f in sorted(os.listdir(d)):
        if f.endswith(".md"):
            r = read_md(os.path.join(d, f))
            if r: out.append(r)
    return out

def md_to_row(x, seq):
    """md 7 字段 -> App 13 列；四诊单独进第 13 列，病因分析只放病机。"""
    s = x["sec"]
    patient = clean_cell(s.get("性别", "") + "，" + s.get("年龄及体型", "")).strip("，")
    diag = clean_cell(x["diag"])
    # 四诊：顺序固定「主诉 → 问诊 → 望诊 → 脉诊」（望在脉前，合望闻问切）。
    # 与 tool/split_case_four_diagnoses.py 的 FOUR 常量必须保持一致。
    four = []
    for key, lab in (("来诊原因", "主诉"), ("问诊", "问诊"),
                     ("望诊", "望诊"), ("脉诊", "脉诊")):
        if s.get(key):
            four.append("【%s】%s" % (lab, scrub_brackets(clean_cell(s[key]))))
    formula = clean_cell(s.get("中药处方", ""))
    acu = clean_cell(s.get("针灸处方", "")) or "未提及"
    # 解说：部分 md 用「备注」承载倪师按语，二者等价
    view = clean_cell(s.get("解说", "") or s.get("备注", ""))
    # 来源标记写入「治法」列：既是溯源，也是幂等指纹（ponytail: 一列两用，不加字段）
    src = "<md:%s>" % (x["srcrow"] or x["file"])
    return [str(seq), x["date"], patient, diag, "", "", formula, acu, src, "", "",
            view, " ".join(four)]

def sig(x):
    # 身份键：编号代号优先，无编号则用标题首段（英文患者名）；配合日期即一次就诊
    who = x["code"] or clean_cell(x["fm"].get("title", "").split("｜")[0])
    return who + "|" + x["date"]

def sig_body(x):
    # 无身份无日期时的兜底：正文全字段签名
    s = x["sec"]
    return "|".join(s.get(k, "") for k in ("性别", "年龄及体型", "来诊原因", "问诊", "脉诊", "望诊", "中药处方", "针灸处方", "解说"))

# ---------- App 表 ----------
def read_app(path):
    raw = open(path, encoding="utf-8").read()
    lines = raw.split("\n")
    rows, idx = [], {}
    for i, ln in enumerate(lines):
        c = [v.strip() for v in ln.strip().strip("|").split("|")]
        if len(c) < 2 or not c[0].isdigit(): continue
        c += [""] * (COLS - len(c))
        rows.append(c)
        idx[int(c[0])] = i
    return raw, lines, rows, idx

def render(cells):
    return "| " + " | ".join(cells) + " |"

def score(x, r):
    s, ap = x["sec"], r[3] + r[4]
    rp = s.get("诊断", "") + s.get("来诊原因", "") + s.get("解说", "")
    best = max(jac(ap, rp), cover(r[3], rp))
    best = max(best, jac(r[6], s.get("中药处方", "")) * 1.15)
    best = max(best, jac(r[7], s.get("针灸处方", "")) * 1.15)
    best = max(best, cover(r[11], s.get("解说", "")))
    return best

def dedupe_cases(up):
    """同「身份＋日期」且正文相近才合并；同键但差异大的保留独立（留给复核，绝不丢案）。"""
    def dup_same(a, b):
        sa, sb = sig_body(a), sig_body(b)
        if not sa or not sb: return True          # 一侧正文空，保留有内容的那份
        return jac(sa, sb) >= 0.5 or sa in sb or sb in sa

    best, order, collapsed, conflict = {}, [], 0, []
    for x in up:
        k = sig(x)
        if not k.strip("|") or k.endswith("|"):
            k = "txt:" + (sig_body(x) or x["file"])
        if k not in best:
            best[k] = x; order.append(k)
        elif dup_same(best[k], x):
            collapsed += 1
            if len(x["raw"]) > len(best[k]["raw"]):
                best[k] = x
        else:
            ck = k + "#" + (str(x["srcrow"]) or x["file"])
            best[ck] = x; order.append(ck); conflict.append(k)
    return [best[k] for k in order], collapsed, conflict

# ---------- 同内容去重 ----------
def identical_key(c):
    """13 列去掉「序号」与 <md:N> 标记后的比对键（严格：逐字比对）。"""
    return tuple(re.sub(r"<md:[^>]+>", "", v).strip()
                 for n, v in enumerate(c) if n != 0)

def loose_key(c):
    """13 列去掉序号、md 标记、空白与全部标点后的比对键。

    源语料同一案常有两份，差异只是标点写法：一份写 `重(脾) 腹筋`，
    另一份写 `重(脾);腹筋`。严格比对抓不住，抹平标点后才是同一段文字。
    """
    out = []
    for n, v in enumerate(c):
        if n == 0:
            continue
        out.append(re.sub(r"[\W_]+", "", re.sub(r"<md:[^>]+>", "", v)))
    return tuple(out)

def collapse_identical(newlines, loose=False):
    """内容完全相同（仅差序号与来源标记）的行只留第一行，标记并入治法列。

    为什么必须单独一道：源语料把同一案存了两个条号——如 `第117条 120S1T,R` 与
    `第367条 R.T.`，后者没编号。dedupe_cases 的键是「编号+日期」，缺编号就撞不上，
    于是同一案进表两次。内容比对不看键，所以能兜住这类重号。

    loose=True 时连标点差异也一并抹平；全空行不参与合并（避免空壳行互相吞掉）。
    """
    key = loose_key if loose else identical_key
    keep, out, merged = {}, [], 0
    for ln in newlines:
        c = [v.strip() for v in ln.strip().strip("|").split("|")]
        if len(c) < 2 or not c[0].isdigit():
            out.append(ln)
            continue
        c += [""] * (COLS - len(c))
        k = key(c)
        if not any(k):                       # 空壳行：不参与
            out.append(ln)
            continue
        if k not in keep:
            keep[k] = len(out)
            out.append(ln)
            continue
        a = [v.strip() for v in out[keep[k]].strip().strip("|").split("|")]
        marks = sorted({m for row in (a, c)
                        for m in re.findall(r"<md:([^>]+)>", row[8])},
                       key=lambda z: (len(z), z))
        plain = re.sub(r"<md:[^>]+>", "", a[8]).strip()
        a[8] = " ".join([plain] + ["<md:%s>" % m for m in marks]).strip()
        out[keep[k]] = render(a)
        merged += 1
    return out, merged


def merge_missing_date(newlines):
    """除「日期」外逐字相同、且一侧日期为空 → 并入日期非空的那行。

    原表里有 8 组这样的残缺副本：#50 日期空、#160 写 2008-03-07，其余 11 列一字不差。
    只按内容比对，日期一列不参与，所以能认出来；保留带日期的那条，丢弃空壳。
    """
    groups, out, merged = {}, [], 0
    for i, ln in enumerate(newlines):
        c = [v.strip() for v in ln.strip().strip("|").split("|")]
        if len(c) < 2 or not c[0].isdigit():
            continue
        c += [""] * (COLS - len(c))
        k = tuple(re.sub(r"<md:[^>]+>", "", v).strip()
                  for n, v in enumerate(c) if n not in (0, I_DATE))
        if not any(k):
            continue
        groups.setdefault(k, []).append(i)

    drop = set()
    for k, ids in groups.items():
        if len(ids) < 2:
            continue
        dated = [i for i in ids if cell_of(newlines[i], I_DATE)]
        blank = [i for i in ids if not cell_of(newlines[i], I_DATE)]
        if len(dated) == 1 and blank:          # 只有一个日期，其余全空 → 空的是副本
            for i in blank:
                drop.add(i)
                merged += 1
    out = [ln for i, ln in enumerate(newlines) if i not in drop]
    return out, merged


def cell_of(ln, i):
    c = [v.strip() for v in ln.strip().strip("|").split("|")]
    return c[i] if len(c) > i else ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    args = ap.parse_args()

    up = load_dir(MD_DIR)
    down = load_dir(MD_DOWN)
    upcodes = {(x["code"], x["date"]) for x in up}

    # 去重：同「身份＋日期」且正文相近才合并（保留最完整的一份）；
    # 同键但正文差异大的（如同日两次记录、续方改方）保留独立，留给复核，绝不丢案。
    uniq, collapsed, conflict = dedupe_cases(up)
    down_only = [x for x in down if (x["code"], x["date"]) not in upcodes]

    raw_bytes = open(APP, "rb").read()          # 换行符需从原始字节判断，文本模式会吃掉 \r
    raw, lines, rows, idx = read_app(APP)
    acodes, adates = defaultdict(list), defaultdict(list)
    for r in rows:
        c = code(r[2])
        if c: acodes[c].append(r)
        if r[1]: adates[r[1][:10]].append(r)

    # 幂等：读 App 行里的 <md:N> 来源标记，已补入的直接跳过
    existing = set()
    for r in rows:
        for v in r:
            existing.update(re.findall(r"<md:([^>]+)>", v))

    decisions = load_decisions()
    fill, review, add, skip = [], [], [], []
    for x in uniq:
        tag = str(x["srcrow"] or x["file"])
        if tag in existing:
            skip.append(x)
            continue
        cand = list(acodes.get(x["code"], [])) if x["code"] else []
        if cand and x["date"]:
            cand = [r for r in cand if r[1][:10] == x["date"]] or cand
        if not cand and x["date"]: cand = list(adates.get(x["date"], []))
        best, bs = None, 0.0
        for r in cand:
            v = score(x, r)
            if v > bs: best, bs = r, v
        # 同身份同日期即同一次就诊：即使文本改写再大，也必须回填而非新增（防重复补入）
        same_visit = bool(x["code"] and x["date"] and any(
            code(r[2]) == x["code"] and r[1][:10] == x["date"] for r in cand))
        # 人工判定优先（final=True 才允许占位替换，避免批量改动未审视数据）
        dec = decisions.get(x["file"], "")
        if dec == "不同案":
            add.append(x); continue
        if dec == "存疑":
            review.append((max(bs, LOW), x, best)); continue
        if dec == "同一案":
            tgt = best or next((r for r in rows if x["code"] and code(r[2]) == x["code"]
                                and r[1][:10] == x["date"]), None)
            if tgt is not None:
                fill.append((max(bs, HIGH), x, tgt, True)); continue
            add.append(x); continue
        if same_visit and best is not None:
            fill.append((max(bs, HIGH), x, best, False)); continue
        if bs >= HIGH: fill.append((bs, x, best, False))
        elif bs >= LOW: review.append((bs, x, best))
        else: add.append(x)

    total = len(fill) + len(review) + len(add) + len(skip)
    assert total == len(uniq), f"守恒失败 {total}!={len(uniq)}"
    assert len(rows) == len(idx), "App 表序号重复"

    print(f"医案上 {len(up)} 份 -> 去重 {len(uniq)}（合并重复导出 {collapsed}）")
    print(f"医案下 {len(down)} 份，独有 {len(down_only)} 份")
    print(f"回填 {len(fill)} / 复核 {len(review)} / 新增 {len(add)} / 已补跳过 {len(skip)}  = {total} ✓")

    if not args.apply:
        print("\n[dry-run] 未写文件。复核清单：")
        for v, x, r in review[:40]:
            print(f"  {v:.2f} {x['fm'].get('title','')[:30]:30s} <- app#{r[0]} {r[3][:20]}")
        print("\n新增清单（前10）：")
        for x in add[:10]:
            print(f"  {x['date']} {x['fm'].get('title','')[:34]}")
        return

    # ---- 写回 ----
    bak = APP + ".bak-fill-md"
    shutil.copy2(APP, bak)
    newlines = list(lines)
    for _, x, r, manual in fill:
        i = idx[int(r[0])]
        row = newlines[i].strip().strip("|").split("|")
        row = [v.strip() for v in row]
        row += [""] * (COLS - len(row))
        mapped = md_to_row(x, r[0])
        for j in (4, 6, 7, 11):
            # 空列可填；仅人工判定「同一案」的条目，允许把「病因分析=诊断复述」的占位替换为 md 三诊
            placeholder = manual and j == 4 and clean_cell(row[j]) == clean_cell(row[3])
            if not row[j] or row[j] == "未提及" or placeholder:
                if mapped[j] and mapped[j] != "未提及": row[j] = mapped[j]
        if mapped[8] not in "".join(row):          # 治法列打来源标记
            row[8] = (row[8] + " " + mapped[8]).strip()
        newlines[i] = render(row)

    maxseq = max(idx) if idx else 0
    for n, x in enumerate(add, 1):
        newlines.append(render(md_to_row(x, maxseq + n)))

    # 同内容去重：源语料重号（第117条 120S1T,R / 第367条 R.T.）会漏过键去重，此处兜底
    newlines, merged_dup = collapse_identical(newlines, loose=True)

    out = "\n".join(newlines)
    # ponytail: 保留源文件换行风格，避免整文件换行符 diff
    if b"\r\n" in raw_bytes:
        out = out.replace("\r\n", "\n").replace("\n", "\r\n")
    open(APP, "w", encoding="utf-8", newline="").write(out)

    # 写后校验
    _, _, rows2, idx2 = read_app(APP)
    assert len(rows2) == len(rows) + len(add) - merged_dup, \
        f"写后行数异常 {len(rows2)}"
    assert len(idx2) == len(rows2), "写后序号重复"
    print(f"[apply] 备份 -> {bak}")
    print(f"[apply] 回填 {len(fill)} 行，新增 {len(add)} 行，"
          f"同内容合并 {merged_dup} 行，总行数 {len(rows)} -> {len(rows2)} ✓")

if __name__ == "__main__":
    main()
