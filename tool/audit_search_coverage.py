# -*- coding: utf-8 -*-
"""搜索索引完善度审计：磁盘卡片 vs classic_index 覆盖。"""
import gzip
import glob
import json
import os
from collections import Counter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
idx_path = os.path.join(ROOT, 'assets', 'guji', 'classic_index.json.gz')

with gzip.open(idx_path, 'rt', encoding='utf-8') as f:
    data = json.load(f)
items = data['entries']
print('索引总条目:', len(items))
print('按来源:', dict(Counter(e['s'] for e in items)))

idx_assets = {e['a'] for e in items if e.get('a')}

dirs = {
    'shanghan': 'assets/shanghan',
    'jingui': 'assets/jingui',
    'neijing': 'assets/neijing',
    'bencao_lecture': 'assets/bencao_lecture',
    'zhenjiu_lecture': 'assets/zhenjiu_lecture',
}

def rel(p):
    """统一成相对仓库根的 posix 路径，与索引 a 字段一致。"""
    return os.path.relpath(p, ROOT).replace(os.sep, '/')


for k, p in dirs.items():
    full = os.path.join(ROOT, p)
    if not os.path.isdir(full):
        print('%-18s 目录不存在' % k)
        continue
    files = {rel(f) for f in glob.glob(os.path.join(full, '*.md'))}
    inc = {f for f in files if f in idx_assets}
    miss = files - inc
    print('%-18s 磁盘 %4d  已索引 %4d  缺 %3d' % (k, len(files), len(inc), len(miss)))
    if miss:
        print('      未索引样例:', sorted(os.path.basename(m) for m in miss)[:6])

# 索引里有、磁盘没有（悬空条目）
disk_all = set()
for p in dirs.values():
    full = os.path.join(ROOT, p)
    if os.path.isdir(full):
        disk_all |= {rel(f) for f in glob.glob(os.path.join(full, '*.md'))}
dangling = idx_assets - disk_all
print('\n索引中指向不存在文件的条目:', len(dangling))
for d in sorted(dangling)[:8]:
    print('   ', d)
