# -*- coding: utf-8 -*-
"""审计条文卡：缺讲解清单 + can 用 nhx 讲稿补的可行性 + 格式不规范项。

用法：
    python tool/audit_clause_lectures.py            # 只出报告
    python tool/audit_clause_lectures.py --json     # 附带机器可读清单
"""
import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NHX = {
    "shanghan": r"D:/nhx/人纪-伤寒论-倪海厦.txt",
    "jingui": r"D:/nhx/人纪-金匮要略-倪海厦.txt",
}
THIN = 100          # 正文（非标题非引用）不足这么多字 → 视为缺讲解
_PUNCT = re.compile(r"[，。、；：？！「」『』【】\[\]（）()《》〈〉“”‘’\s—…·,.·:;!?]")
_CN_NUM = "零一二三四五六七八九十百0-9"


def read(p):
    return io.open(p, encoding="utf-8").read()


def split_card(text):
    """→ (heading, heads, quote, prose)"""
    lines = text.split("\n")
    heading = lines[0].strip() if lines else ""
    heads, quote, prose = [], [], []
    for ln in lines[1:]:
        s = ln.strip()
        if not s:
            continue
        if s.startswith("#"):
            heads.append(s)
        elif s.startswith(">"):
            quote.append(s.lstrip("> ").strip())
        elif s.startswith("---") or s.startswith("<!--"):
            continue
        else:
            prose.append(s)
    return heading, heads, quote, prose


def card_key(text):
    """取用于在 nhx 里检索的原文骨架：优先引用块首行，否则首行标题去掉编号。"""
    heading, heads, quote, prose = split_card(text)
    src = quote[0] if quote else heading
    src = re.sub(r"^#+\s*", "", src)
    src = re.sub(r"^条文\s*[0-9]+\s*[（(][^）)]*[）)]\s*[：:]?\s*", "", src)
    src = re.sub(r"^条文\s*[0-9]+\s*[：:]?\s*", "", src)
    src = re.sub(r"^[%s]{1,4}\s*[：:]\s*" % _CN_NUM, "", src)
    return src.strip()


def norm(s):
    return _PUNCT.sub("", s)


def load_nhx(src):
    path = NHX[src]
    if not os.path.exists(path):
        return None, []
    text = read(path)
    units = []           # (title, body, start)
    lines = text.split("\n")
    idx = [i for i, l in enumerate(lines) if l.startswith("###")]
    for k, i in enumerate(idx):
        end = idx[k + 1] if k + 1 < len(idx) else len(lines)
        units.append((lines[i].strip(), "\n".join(lines[i + 1:end]).strip()))
    return text, units


def find_unit(key, text, units):
    """把卡片的原文骨架拿到 nhx 里定位所属单元。"""
    k = norm(key)[:14]
    if len(k) < 6 or text is None:
        return None
    pos = norm(text).find(k)
    if pos < 0:
        return None
    # norm 后的位置无法直接映射，改用原文前 10 字做定位
    raw = key[:10]
    p = text.find(raw)
    if p < 0:
        return None
    for title, body in units:
        # 用单元标题在 text 里的位置判断包含关系
        tp = text.find(title)
        if tp < 0:
            continue
        if tp <= p <= tp + len(title) + len(body) + 64:
            return title, body
    return None


def scan_formats(path, text, heading, heads, quote, prose):
    issues = []
    if not heading.startswith("#"):
        issues.append("首行不是标题")
    m = re.match(r"^(#+)\s", heading)
    lvl = len(m.group(1)) if m else 0
    if lvl not in (2, 3, 4):
        issues.append(f"标题级别 {lvl}")
    if re.match(r"^#+\s*条文", heading) and lvl != 4:
        issues.append(f"条文卡标题用了 {'#'*lvl}（应为 ####）")
    if re.match(r"^#+\s*[%s]{1,4}[：:]" % _CN_NUM, heading) and lvl == 4:
        issues.append("原文式标题用了 ####（语料惯例 ### ）")
    if re.search(r"[^\s]：$", heading):
        issues.append("标题以冒号结尾")
    if "\n---" in text.rstrip("\n")[-8:] or text.rstrip().endswith("---"):
        issues.append("末尾残留 ---")
    if "<!--" in text:
        issues.append("残留 HTML 注释")
    for ln in text.split("\n"):
        if re.search(r"^[%s]{1,4}:" % _CN_NUM, ln.strip()):
            issues.append("半角冒号序号")
            break
    return issues


def main():
    argv = sys.argv[1:]
    report = {"cards": [], "summary": {}}
    for src in ("shanghan", "jingui"):
        folder = os.path.join(ROOT, "assets", src)
        files = sorted(f for f in os.listdir(folder) if f.endswith(".md"))
        text, units = load_nhx(src)
        thin = 0
        for fn in files:
            p = os.path.join(folder, fn)
            raw = read(p)
            heading, heads, quote, prose = split_card(raw)
            prose_len = sum(len(x) for x in prose)
            if prose_len >= THIN:
                continue
            thin += 1
            key = card_key(raw)
            hit = find_unit(key, text, units)
            rec = {
                "src": src,
                "file": fn,
                "heading": heading,
                "key": key[:60],
                "prose_len": prose_len,
                "quote_len": sum(len(x) for x in quote),
                "nhx_unit": hit[0][:60] if hit else None,
                "nhx_body_len": len(hit[1]) if hit else 0,
                "formats": scan_formats(p, raw, heading, heads, quote, prose),
            }
            report["cards"].append(rec)
        report["summary"][src] = {"files": len(files), "thin": thin}

    cards = report["cards"]
    fillable = [c for c in cards if c["nhx_unit"]]
    unfill = [c for c in cards if not c["nhx_unit"]]
    fmt = [c for c in cards if c["formats"]]
    print(f"条文卡 {sum(v['files'] for v in report['summary'].values())}，缺讲解 {len(cards)}")
    for src, v in report["summary"].items():
        print(f"  {src}: {v['files']} 卡 / 缺讲解 {v['thin']}")
    print(f"\n可用 nhx 补齐: {len(fillable)}")
    print(f"无法补齐:     {len(unfill)}")
    print(f"有格式问题:   {len(fmt)}")

    out = os.path.join(ROOT, "clause_audit_report.json")
    io.open(out, "w", encoding="utf-8", newline="\n").write(
        json.dumps(report, ensure_ascii=False, indent=1))
    print("\n报告 →", out)


if __name__ == "__main__":
    main()
