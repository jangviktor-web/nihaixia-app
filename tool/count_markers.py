# -*- coding: utf-8 -*-
"""统计条文卡里所有 **粗体标记** 的种类与数量（定位标记风格差异）。"""
import io
import glob
import os
import re
from collections import Counter

marks = Counter()
samples = {}
for p in glob.glob('assets/*/clause_*.md'):
    t = io.open(p, encoding='utf-8').read()
    for m in re.finditer(r'^\*\*([^*\n]{1,20})\*\*[：:]?', t, re.M):
        k = m.group(1)
        marks[k] += 1
        samples.setdefault(k, os.path.basename(p))

print('**粗体标记** 种类:', len(marks))
for k, n in marks.most_common(16):
    print(f'  {n:>4}  **{k}**   例: {samples[k]}')

# 解读类标记的分布
jiedu = {k: n for k, n in marks.items() if '解读' in k or '讲解' in k or '倪' in k}
print('\n解读类标记:', jiedu)
