# -*- coding: utf-8 -*-
"""用 nhx 人纪讲稿给「缺讲解」的条文卡补讲解（仅限高置信部分）。

覆盖两类：
  ① 金匮「篇首卡」（## 篇名 / 现已统一 ####）：取该篇开头、第一个原文段之前的讲解段
  ② 金匮「问曰/师曰」问答条：在该篇内定位该原文段，取其后紧跟的讲解段（最多 2 段 / 900 字）
另补：伤寒中讲稿确有实质讲解（≥300 字）的少数卡片。

用法：
    python tool/fill_clause_from_nhx.py --dry    # 只报数 + 抽样
    python tool/fill_clause_from_nhx.py          # 写入
"""
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
JG = r"D:/nhx/人纪-金匮要略-倪海厦.txt"
SH = r"D:/nhx/人纪-伤寒论-倪海厦.txt"
MAXLEN = 900
_P = re.compile(r"[，。、；：？！「」『』【】\[\]（）()《》〈〉“”‘’\s—…·,.·:;!?·]")
MARK = "**倪师讲解（人纪讲稿节选）**：\n\n"


def norm(s):
    return _P.sub("", s)


def is_yuanwen(p):
    """粗判一段是不是「原文」而非讲解。"""
    s = p.strip()
    if not s or len(s) > 150:
        return False
    if s.startswith(("问曰", "师曰", "夫")):
        return True
    return "主之" in s and len(s) <= 90


def chapters(path):
    lines = io.open(path, encoding="utf-8").read().split("\n")
    idx = [(i, l[3:].strip()) for i, l in enumerate(lines) if l.startswith("## ")]
    out = []
    for k, (i, t) in enumerate(idx):
        end = idx[k + 1][0] if k + 1 < len(idx) else len(lines)
        paras = [x.strip() for x in lines[i + 1:end] if x.strip()]
        out.append((t, paras))
    return out


def paragraph_units(path, marker="###"):
    lines = io.open(path, encoding="utf-8").read().split("\n")
    idx = [i for i, l in enumerate(lines) if l.startswith(marker)]
    out = []
    for k, i in enumerate(idx):
        end = idx[k + 1] if k + 1 < len(idx) else len(lines)
        out.append((lines[i].strip(), "\n".join(lines[i + 1:end]).strip()))
    return out


def card_head(path):
    lines = io.open(path, encoding="utf-8").read().split("\n")
    head = lines[0].strip()
    quote = next((l.strip().lstrip("> ").strip() for l in lines[1:]
                  if l.strip().startswith(">")), "")
    return head, quote


def card_key(head, quote):
    src = quote or head
    src = re.sub(r"^#+\s*", "", src)
    src = re.sub(r"^条文\s*\d+\s*[（(][^）)]*[）)]\s*[：:]?\s*", "", src)
    src = re.sub(r"^条文\s*\d+\s*[：:]?\s*", "", src)
    src = re.sub(r"^[零一二三四五六七八九十百0-9]{1,4}\s*[：:]\s*", "", src)
    return src.strip()


def prose_len(path):
    t = io.open(path, encoding="utf-8").read()
    n = 0
    for ln in t.split("\n")[1:]:
        s = ln.strip()
        if not s or s.startswith(("#", ">", "---", "<!--")):
            continue
        n += len(s)
    return n


def find_para(paras, key, nk_len=12):
    nk = norm(key)[:nk_len]
    if len(nk) < 6:
        return None
    for i, p in enumerate(paras):
        if norm(p).startswith(nk) or nk in norm(p)[:40]:
            return i
    return None


def build_jg():
    """返回 {文件名: 讲解文本}"""
    chs = chapters(JG)
    plan = {}
    folder = os.path.join(ROOT, "assets", "jingui")
    for fn in sorted(os.listdir(folder)):
        if not fn.endswith(".md"):
            continue
        p = os.path.join(folder, fn)
        if prose_len(p) > 0:
            continue
        head, quote = card_head(p)
        title = re.sub(r"^#+\s*", "", head).strip()
        key = card_key(head, quote)
        # ① 篇首卡：原标题为 `## 篇名`
        ch = next((c for c in chs if norm(c[0])[:6] == norm(title)[:6]), None)
        if ch and norm(key) and norm(ch[0]).startswith(norm(key)[:6]):
            paras = ch[1]
            lead = []
            for para in paras:
                if is_yuanwen(para):
                    break
                lead.append(para)
                if sum(len(x) for x in lead) >= MAXLEN:
                    break
            if lead:
                plan[fn] = "\n\n".join(lead)[:MAXLEN]
            continue
        # ② 问答条：在所有篇里定位该原文段
        hit_ch, i = None, None
        for c in chs:
            j = find_para(c[1], key)
            if j is not None:
                hit_ch, i = c, j
                break
        if hit_ch is None:
            continue
        ch = hit_ch
        if i is None:
            continue
        got, total = [], 0
        for para in ch[1][i + 1:]:
            if is_yuanwen(para):
                break
            got.append(para)
            total += len(para)
            if total >= MAXLEN or len(got) >= 2:
                break
        if got:
            plan[fn] = "\n\n".join(got)[:MAXLEN]
    return plan


def build_sh():
    """伤寒：仅取讲稿单元确为同一条、且有实质讲解（≥300 字）的卡。"""
    units = paragraph_units(SH, "###")
    plan = {}
    folder = os.path.join(ROOT, "assets", "shanghan")
    for fn in sorted(os.listdir(folder)):
        if not fn.endswith(".md"):
            continue
        p = os.path.join(folder, fn)
        if prose_len(p) > 0:
            continue
        head, quote = card_head(p)
        key = card_key(head, quote)
        nk = norm(key)[:10]
        if len(nk) < 6:
            continue
        for title, body in units:
            if nk in norm(title):
                body = body.strip()
                if len(body) >= 300:
                    plan[fn] = body[:MAXLEN]
                break
    return plan


def main():
    dry = "--dry" in sys.argv
    for src, plan in (("jingui", build_jg()), ("shanghan", build_sh())):
        print(f"=== {src}: 待补 {len(plan)} 张 ===")
        for fn, txt in plan.items():
            print(f"  {fn:<18} {len(txt):>4}字 | {txt[:60]}…")
        if dry:
            continue
        folder = os.path.join(ROOT, "assets", src)
        for fn, txt in plan.items():
            p = os.path.join(folder, fn)
            raw = io.open(p, encoding="utf-8").read().rstrip("\n")
            if "倪师讲解（人纪讲稿节选）" in raw:
                continue
            io.open(p, "w", encoding="utf-8", newline="\n").write(
                raw + "\n\n" + MARK + txt.strip() + "\n")
        print(f"  已写入 {src}：{len(plan)} 张")


if __name__ == "__main__":
    main()
