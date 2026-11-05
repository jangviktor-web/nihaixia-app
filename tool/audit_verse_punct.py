# -*- coding: utf-8 -*-
"""精确扫描原文块标点异常（只读）。"""
import glob
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = sorted(glob.glob(os.path.join(ROOT, 'assets', 'shanghan', 'clause_*.md')))

ql = []
for f in FILES:
    for i, ln in enumerate(open(f, encoding='utf-8'), 1):
        if ln.startswith('>'):
            ql.append((os.path.basename(f), i, ln[1:]))

RULES = [
    ('R1 【】方括号', re.compile('【[^】]*】')),
    ('R2 []半角括号', re.compile(r'\[[^\]]*\]')),
    ('R3 中文序号含阿拉伯0', re.compile(r'[〇零一二三四五六七八九十]0')),
    ('R4 重复冒号', re.compile('：：')),
    ('R5 半角冒号(中文语境)', re.compile(r'[\u4e00-\u9fff]:')),
    ('R6 句号后跟逗号', re.compile('。，')),
    ('R7 逗号空格', re.compile('，[ \t]+(?=[\u4e00-\u9fff])')),
    ('R8 反斜杠残留', re.compile(r'\\')),
    ('R9 半角右括号', re.compile(r'[\u4e00-\u9fff]\)')),
    ('R10 引号间冒号', re.compile('」：「')),
    ('R11 冒号替逗号(连续短句)', re.compile(r'[\u4e00-\u9fff]：[\u4e00-\u9fff]{1,4}：')),
    ('R12 空格在引号内', re.compile('[「][ \t]|[ \t][」]')),
    ('R13 顿号后空格', re.compile('、[ \t]')),
]

for name, pat in RULES:
    hits = [(f, i, b) for f, i, b in ql if pat.search(b)]
    print('\n=== %s : %d 处 ===' % (name, len(hits)))
    seen = set()
    for f, i, b in hits:
        k = pat.search(b).group(0)
        if k in seen and len(hits) > 25:
            continue
        seen.add(k)
        print('  %-16s L%-3d %s' % (f, i, b.strip()[:88]))
