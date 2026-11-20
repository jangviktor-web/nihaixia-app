#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把 App 医案表的「无源」行映射到文章体语料的段落，并写入溯源标记。

背景：cases_table.md 里 621 行没有 <md:N>（病案表格体标记），它们是
从倪师诊疗日志/文章里蒸馏出来的。本工具用「日期 + 诊断关键词」定位到
tool/source/article_corpus/ 下文章的段落，写成 <art:文件#段落序号> 标记，
让这 621 行也变成可追溯、可核对。

标记放在第 8 列（治法列），与该列已有的 <md:N> 并列使用同一「一列两用」
机制；Dart 侧 _mdTag 正则需同步扩展到 <art:...> 才不会漏给用户。

用法：
  python tool/tag_article_source.py                    # dry-run 报告
  python tool/tag_article_source.py --apply            # 写回（自动备份）
  python tool/tag_article_source.py --apply --min 2    # 只写证据>=2的

 ponytail: 不建新列、不建索引文件；段落现场切、标记复用现有第 8 列。
"""
import os, re, sys, argparse

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CORPUS = os.path.join(os.path.dirname(os.path.abspath(__file__)), "source", "article_corpus")
APP = os.path.join(ROOT, "assets", "medical_cases", "cases_table.md")
TAG = re.compile(r"<(?:md|art):[^>]+>")
DATE_ART = re.compile(r"(?<!\d)(\d{1,2})/(\d{1,2})/((?:19|20)\d{2})(?!\d)")


def norm(s):
    """比对用：去空白与常见繁简/异体差异，避免蒸馏时的改写影响命中。"""
    s = re.sub(r"\s+", "", str(s or ""))
    return s


def load_articles():
    """→ [(文件名, 段落序号, 标题, 日期, 正文)]。"""
    arts = []
    for fn in sorted(os.listdir(CORPUS)):
        if not fn.endswith(".md"):
            continue
        lines = open(os.path.join(CORPUS, fn), encoding="utf-8").read().split("\n")
        # 段落起点：正文里 "MM/DD/YYYY" 开头的行；标题取往上最近的短非空行
        for i, ln in enumerate(lines):
            m = DATE_ART.match(ln.strip())
            if not m:
                continue
            mo, d, y = int(m.group(1)), int(m.group(2)), m.group(3)
            if mo > 12 or d > 31:
                continue
            date = "%s-%02d-%02d" % (y, mo, d)
            title = ""
            for j in range(i - 1, max(-1, i - 8), -1):
                t = lines[j].strip()
                if t and len(t) < 40 and not DATE_ART.search(t):
                    title = t
                    break
            # 正文截止到下一段落的日期行或 200+ 行之后
            end = min(len(lines), i + 200)
            for j in range(i + 1, min(len(lines), i + 200)):
                if DATE_ART.match(lines[j].strip()):
                    end = j
                    break
            body = "\n".join(lines[i:end])
            arts.append((fn, len(arts) + 1, title, date, body))
    return arts


def evidence(row, art):
    """一条 App 行与一个段落的证据强度：日期匹配 + 诊断/观点关键词命中数。"""
    date, diag, view = row[1][:10], row[3], row[11]
    if date != art[3]:
        return 0
    body = norm(art[4])
    score = 1                                  # 日期一致本身算 1 分
    # 诊断列取 2 字粒度词，观点列取 4 字粒度；蒸馏会改写，不用整句
    for src, n in ((diag, 2), (view, 4)):
        txt = norm(src)
        for k in range(len(txt) - n + 1):
            frag = txt[k:k + n]
            if len(frag) == n and frag in body:
                score += 1
            if score >= 6:
                break
        if score >= 6:
            break
    return score


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--min", type=int, default=2, help="最低证据分，默认 2（日期+1个词）")
    a = ap.parse_args()

    arts = load_articles()
    print("文章语料 %d 个文件，切出 %d 个日期段落" %
          (len(set(x[0] for x in arts)), len(arts)))

    txt = open(APP, encoding="utf-8").read()
    crlf = "\r\n" in txt
    lines = txt.replace("\r\n", "\n").split("\n")
    out, tagged, skipped = [], [], 0
    for ln in lines:
        if not ln.startswith("|"):
            out.append(ln)
            continue
        c = [x.strip() for x in ln.strip("|").split("|")]
        if len(c) < 13 or not c[0].isdigit() or TAG.search(c[8]):
            out.append(ln)
            skipped += 1
            continue
        best, bs = None, 0
        for art in arts:
            s = evidence(c, art)
            if s > bs:
                best, bs = art, s
        if best and bs >= a.min:
            fn, no, title, date, _body = best
            tag = "<art:%s#%d>" % (os.path.splitext(fn)[0], no)
            c[8] = (c[8] + " " + tag).strip()
            # 保持原表的 `| 内容 |` 每格带空格格式，不能写成 `|内容|`：
            # 混用会让下游按固定格式切分的工具漏读这些行。
            out.append("| " + " | ".join(c) + " |")
            tagged.append((c[0], date, title, bs, tag))
        else:
            out.append(ln)

    print("已标记行总数（含原有 <md:>）: %d，跳过 %d 行" % (skipped, len(lines) - skipped))
    print("本次可定位: %d 行" % len(tagged))
    from collections import Counter
    print("证据分分布:", dict(sorted(Counter(t[3] for t in tagged).items())))
    for t in tagged[:12]:
        print("  #%-5s %s  证据%d  %s  %s" % (t[0], t[1], t[3], t[2][:20], t[4]))
    if len(tagged) > 12:
        print("  ... 共 %d 行" % len(tagged))

    if a.apply:
        bak = APP + ".bak-art-tag"
        open(bak, "w", encoding="utf-8", newline="").write(txt)
        joined = "\n".join(out)
        if crlf:
            joined = joined.replace("\r\n", "\n").replace("\n", "\r\n")
        open(APP, "w", encoding="utf-8", newline="").write(joined)
        print("已写回，备份:", bak)
    else:
        print("\n[dry-run] 未写文件")
    return 0


if __name__ == "__main__":
    sys.exit(main())
