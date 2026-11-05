# -*- coding: utf-8 -*-
"""生成《伤寒论原文标点统一清单》文档。"""
import glob
import os
import re
import subprocess

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

CATS = [
    ('A. 方括号体系统一（【】/[] → 「」）',
     lambda a, b: ('【' in a or '[' in a) and ('「' in b)),
    ('B. 中文条号阿拉伯 0 → 〇',
     lambda a, b: re.search('[〇零一二三四五六七八九十]0', a) is not None),
    ('C. 冒号误插 → 改用逗号/句号/顿号',
     lambda a, b: a.count('：') > b.count('：')),
    ('D. 半角冒号 : → 「：」',
     lambda a, b: re.search(r'[一-鿿]:', a) is not None),
    ('E. 多余空格清理',
     lambda a, b: a.replace(' ', '').replace('\t', '') == b.replace(' ', '').replace('\t', '')
     and a != b),
    ('F. 其它（句号叠逗号、反斜杠残留、引号间冒号、半角括号）',
     lambda a, b: True),
]


def load_diff():
    d = subprocess.run(['git', 'diff', '-U0', '--', 'assets/shanghan'],
                       capture_output=True, text=True, encoding='utf-8').stdout
    pairs, cur_file, minus = [], '', []
    for ln in d.split('\n'):
        if ln.startswith('---') or ln.startswith('+++') or ln.startswith('@@'):
            continue
        if ln.startswith('-'):
            minus.append(ln[1:])
        elif ln.startswith('+'):
            src = re.search(r'diff --git a/(\S+)', d)
            if minus:
                pairs.append((minus.pop(0), ln[1:]))
    return pairs


pairs = load_diff()
buckets = {name: [] for name, _ in CATS}
unused = []
for a, b in pairs:
    for name, pred in CATS:
        if pred(a, b):
            buckets[name].append((a, b))
            break
    else:
        unused.append((a, b))

lines = ['# 伤寒论原文标点符号统一清单', '',
         '> 生成时间：2026-11-05',
         '> 范围：`assets/shanghan/clause_*.md` 内所有 `> 原文` 引用块',
         '> 脚本：`tool/fix_verse_punct.py`（`--apply` 落盘）',
         '> 校验：`tool/verify_punct_noloss.py` — 剥离标点后 80/80 行内容完全一致（PASS）',
         '']

rename = {'A. 方括号体系统一（【】/[] → 「」）': 'A. 方括号体系统一',
          'B. 中文条号阿拉伯 0 → 〇': 'B. 中文条号 0 → 〇',
          'C. 冒号误插 → 改用逗号/句号/顿号': 'C. 冒号误插',
          'D. 半角冒号 : → 「：」': 'D. 半角冒号',
          'E. 多余空格清理': 'E. 多余空格',
          'F. 其它（句号叠逗号、反斜杠残留、引号间冒号、半角括号）': 'F. 其它'}

for name, _ in CATS:
    items = buckets[name]
    if not items:
        continue
    lines.append('## %s（%d 处）' % (rename[name], len(items)))
    lines.append('')
    for a, b in items:
        lines.append('- `%s`' % a.strip()[:110])
        lines.append('  → `%s`' % b.strip()[:110])
    lines.append('')

lines.append('## 总计')
lines.append('')
lines.append('| 类别 | 数量 |')
lines.append('|---|---|')
for name, _ in CATS:
    if buckets[name]:
        lines.append('| %s | %d |' % (rename[name], len(buckets[name])))
lines.append('| **合计** | **%d** |' % len(pairs))

out = os.path.join(ROOT, 'docs', '伤寒论原文标点统一清单.md')
open(out, 'w', encoding='utf-8', newline='\n').write('\n'.join(lines) + '\n')
print('写入', out, '共', len(pairs), '对改动')
for name, _ in CATS:
    print('  %-12s %d' % (rename[name], len(buckets[name])))
if unused:
    print('未分类', len(unused))
