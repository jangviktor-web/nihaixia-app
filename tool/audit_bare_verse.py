# -*- coding: utf-8 -*-
"""扫描「裸行原文」：疑似仲景条文却没有 `>` 引用块/`####` 标题的行。

背景：clause_375.md 把整个霍乱篇（宋本382-391）的原文写成裸文本行，
与讲解混排——结构审计（audit_verse_struct.py）查的是「原文块是否被截断」，
查不到这种「原文根本没进原文块」的情况。
"""
import glob
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 条文典型结尾/句式（长度设限，避免抓到讲解长段）
PAT = re.compile(r'(主之。|是名霍乱|属阳明也|当愈。|即愈。|小和之。|'
                 r'^问曰：|^答曰：|不可治也。|利之即愈。)')

for book in ('shanghan', 'jingui'):
    hits = []
    for f in sorted(glob.glob(os.path.join(ROOT, 'assets', book, 'clause_*.md'))):
        L = open(f, encoding='utf-8').read().split('\n')
        bare = []
        for i, l in enumerate(L, 1):
            s = l.strip()
            if not s or s.startswith('#') or s.startswith('>'):
                continue
            if len(s) > 110:      # 讲解段落通常很长
                continue
            if PAT.search(s):
                bare.append((i, s))
        if bare:
            hits.append((os.path.basename(f), len(L), len(bare), bare[:3]))
    print('=' * 12, book, ':', len(hits), '张卡含裸行原文')
    for name, n, c, sample in sorted(hits, key=lambda x: -x[2])[:12]:
        print('  %-16s 行%4d  裸行%2d   例: %s' % (name, n, c, sample[0][1][:52]))
