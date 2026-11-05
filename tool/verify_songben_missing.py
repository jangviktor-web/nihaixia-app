# -*- coding: utf-8 -*-
"""对 coverage<0.50 的候选，逐条给出：最长连续匹配长度、所属卡片、该卡原文块。"""
import glob
import os
import re
import difflib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REF = (r"C:/Users/jangviktor/AppData/Roaming/AutoClaw-oversea-official/accounts/"
       r"9dcf530ba54dcc70c7e2a759818622b244bfe4c0d708f274a70d84f6db393216/"
       r"projects/Default/宋本伤寒论（简体·398条编号版）.md")
CJK = re.compile(r'[\u4e00-\u9fff0-9]')
CAND = [4, 6, 16, 19, 20, 23, 79, 92, 101, 116, 117, 119, 120, 121, 122, 123,
        160, 176, 206, 210, 257, 288, 310, 326, 361, 374, 391, 392, 394, 396, 398]


def norm(s):
    return ''.join(CJK.findall(s))


def parse_ref():
    cl = {}
    for ln in open(REF, encoding='utf-8'):
        m = re.match(r'^(\d{1,3})．(.*)$', ln.strip())
        if m and 1 <= int(m.group(1)) <= 398:
            cl.setdefault(int(m.group(1)), []).append(m.group(2))
    return {n: norm(''.join(v)) for n, v in cl.items()}


cards = []
for f in sorted(glob.glob(os.path.join(ROOT, 'assets', 'shanghan', 'clause_*.md'))):
    raw = open(f, encoding='utf-8').read()
    title = ''
    verse = []
    for ln in raw.split('\n'):
        if ln.startswith('####') and not title:
            title = ln.lstrip('#').strip()
        if ln.startswith('>') and not ln.startswith('> **'):
            verse.append(ln.lstrip('> ').strip())
    cards.append({'f': os.path.basename(f), 't': title,
                  'v': norm(' '.join(verse)), 'raw': raw})

ref = parse_ref()
for n in CAND:
    t = ref[n]
    best, bestlen = None, 0
    for c in cards:
        m = difflib.SequenceMatcher(None, t, c['v'], autojunk=False)
        bl = m.find_longest_match(0, len(t), 0, len(c['v']))
        if bl.size > bestlen:
            bestlen, best = bl.size, (c, bl, t[bl.a:bl.a + bl.size])
    if best:
        c, bl, sub = best
        print('第%3d条 最长=%2d/%d  %s' % (n, bestlen, len(t), t[:40]))
        print('     卡片:%s  %s' % (c['f'], c['t'][:34]))
        print('     最长片段:%s' % sub)
        print('     该卡原文:%s' % c['v'][:52])
    else:
        print('第%3d条 无匹配  %s' % (n, t[:40]))
    print()
