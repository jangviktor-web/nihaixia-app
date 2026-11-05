# -*- coding: utf-8 -*-
"""对比伤寒论 / 金匮要略 原文块的标点异常。只读。"""
import glob
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

RULES = [
    ('【】方括号', '【[^】]*】'),
    ('[]半角括号', r'\[[^\]]*\]'),
    ('中文数字含0', '[〇零一二三四五六七八九十]0'),
    ('双冒号', '：：'),
    ('半角冒号', '[一-鿿]:'),
    ('句号逗号', '。，'),
    ('逗号空格', '，[ \\t]+'),
    ('反斜杠', '\\\\'),
    ('半角右括号', '[一-鿿]\\)'),
    ('引号间冒号', '」：「'),
]

for d in ('shanghan', 'jingui'):
    files = sorted(glob.glob(os.path.join(ROOT, 'assets', d, 'clause_*.md')))
    q = []
    for f in files:
        for l in open(f, encoding='utf-8'):
            if l.startswith('>') and not l.startswith('> **'):
                q.append(l)
    print('\n【%s】原文块 %d 行 / %d 文件' % (d, len(q), len(files)))
    for name, pat in RULES:
        p = re.compile(pat)
        c = sum(1 for l in q if p.search(l))
        if c:
            print('   %-12s %d 行' % (name, c))
