# -*- coding: utf-8 -*-
"""对照宋本 398 条，检查 App 伤寒论模块的条辨缺失 / 编号缺失。

做法：
- 基准：宋本《伤寒论》398 条编号版（外部 md）
- App：assets/shanghan/clause_*.md 全部卡片（标题 + 正文）
- 匹配：对每条宋本原文，在后缀自动机（App 全库归一化文本）上求
        最长连续匹配长度 / 条文长度 = 覆盖率
- 分类：>=0.90 完整；0.60-0.90 部分/异文；<0.60 缺失
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF = (r"C:/Users/jangviktor/AppData/Roaming/AutoClaw-oversea-official/accounts/"
       r"9dcf530ba54dcc70c7e2a759818622b244bfe4c0d708f274a70d84f6db393216/"
       r"projects/Default/宋本伤寒论（简体·398条编号版）.md")

CJK = re.compile(r'[\u4e00-\u9fff0-9]')


def norm(s):
    return ''.join(CJK.findall(s))


# ---------- 1. 解析宋本 398 条 ----------
def parse_ref():
    clauses = {}
    for ln in open(REF, encoding='utf-8'):
        m = re.match(r'^(\d{1,3})．(.*)$', ln.strip())
        if not m:
            continue
        n = int(m.group(1))
        if 1 <= n <= 398:
            clauses.setdefault(n, []).append(m.group(2))
    return {n: norm(''.join(v)) for n, v in clauses.items()}


# ---------- 2. 读 App 卡片 ----------
def read_cards():
    cards = []
    for f in sorted(glob.glob(os.path.join(ROOT, 'assets', 'shanghan', 'clause_*.md'))):
        raw = open(f, encoding='utf-8').read()
        title = ''
        for ln in raw.split('\n'):
            if ln.startswith('####'):
                title = ln.lstrip('#').strip()
                break
        cards.append({
            'file': os.path.basename(f),
            'title': title,
            'norm': norm(raw),
        })
    return cards


# ---------- 3. 后缀自动机 ----------
class SAM:
    def __init__(self):
        self.next = [{}]
        self.link = [-1]
        self.len = [0]
        self.last = 0

    def extend(self, c):
        cur = len(self.next)
        self.next.append({})
        self.len.append(self.len[self.last] + 1)
        self.link.append(0)
        p = self.last
        while p != -1 and c not in self.next[p]:
            self.next[p][c] = cur
            p = self.link[p]
        if p == -1:
            self.link[cur] = 0
        else:
            q = self.next[p][c]
            if self.len[p] + 1 == self.len[q]:
                self.link[cur] = q
            else:
                clone = len(self.next)
                self.next.append(dict(self.next[q]))
                self.len.append(self.len[p] + 1)
                self.link.append(self.link[q])
                while p != -1 and self.next[p].get(c) == q:
                    self.next[p][c] = clone
                    p = self.link[p]
                self.link[q] = clone
                self.link[cur] = clone
        self.last = cur

    def longest(self, s):
        v = 0
        l = 0
        best = 0
        for ch in s:
            while v != 0 and ch not in self.next[v]:
                v = self.link[v]
                l = self.len[v]
            if ch in self.next[v]:
                v = self.next[v][ch]
                l += 1
            else:
                v = 0
                l = 0
            if l > best:
                best = l
        return best


def main():
    ref = parse_ref()
    cards = read_cards()
    corpus = ''.join(c['norm'] for c in cards)
    print('宋本条文 %d 条；App 卡片 %d 张；归一化语料 %d 字'
          % (len(ref), len(cards), len(corpus)))

    sam = SAM()
    for ch in corpus:
        sam.extend(ch)

    # 逐卡 4-gram 覆盖率（对异体字/个别差字鲁棒）
    def grams(s, k=4):
        if len(s) <= k:
            return {s}
        return {s[i:i + k] for i in range(len(s) - k + 1)}

    card_grams = [(c, grams(c['norm'])) for c in cards]

    rows = []
    for n in sorted(ref):
        t = ref[n]
        if not t:
            rows.append((n, 0.0, 0, 0, None, ''))
            continue
        cg = grams(t)
        best, best_hit = None, 0
        for c, g in card_grams:
            hit = len(cg & g)
            if hit > best_hit:
                best_hit, best = hit, c
        cov = best_hit / len(cg) if cg else 0.0
        rows.append((n, cov, best_hit, len(cg),
                     best['file'] if best else None,
                     best['title'] if best else ''))

    miss = [r for r in rows if r[1] < 0.50]
    part = [r for r in rows if 0.50 <= r[1] < 0.80]
    ok = [r for r in rows if r[1] >= 0.80]
    print('\n完整(>=0.80): %d　部分(0.50-0.80): %d　缺失(<0.50): %d'
          % (len(ok), len(part), len(miss)))

    print('\n===== 缺失（4-gram覆盖率<0.50）=====')
    for n, cov, hit, tot, f, t in miss:
        print('第%3d条  cov=%.2f  %d/%d  %s | 最像:%s %s'
              % (n, cov, hit, tot, ref[n][:34], f, t[:24]))

    print('\n===== 部分/异文（0.50-0.80）=====')
    for n, cov, hit, tot, f, t in part:
        print('第%3d条  cov=%.2f  %d/%d  %s | %s %s'
              % (n, cov, hit, tot, ref[n][:34], f, t[:24]))

    return rows


if __name__ == '__main__':
    main()
