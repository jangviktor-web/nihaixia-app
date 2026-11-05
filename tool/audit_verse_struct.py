# -*- coding: utf-8 -*-
"""审计结构缺陷（截断 / 重复），生成 docs/伤寒论原文结构缺陷.md。只读。"""
import glob
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = sorted(glob.glob(os.path.join(ROOT, 'assets', 'shanghan', 'clause_*.md')))


def unclosed(t):
    return (t.count('「') != t.count('」')
            or t.count('【') != t.count('】'))


title_trunc, quote_trunc, dup = [], [], []

for f in FILES:
    name = os.path.basename(f)
    L = [l.rstrip('\n') for l in open(f, encoding='utf-8')]
    for i, l in enumerate(L, 1):
        # 标题截断：以逗号/冒号/顿号/分号结尾，或括号不配对
        if l.startswith('####'):
            t = l[4:].strip()
            if t and (t[-1] in '，：、；' or unclosed(t)):
                title_trunc.append((name, i, t))
    for i, l in enumerate(L):
        if not l.startswith('>'):
            continue
        b = l[1:].strip()
        if not b or b.startswith('**'):
            continue
        # 引用块截断：以句读（非句末）结尾
        if b[-1] in '，、；：' or unclosed(b):
            nxt = ''
            for j in range(i + 1, min(i + 4, len(L))):
                if L[j].strip():
                    nxt = L[j].strip()
                    break
            if not nxt.startswith('>'):
                quote_trunc.append((name, i + 1, b[-40:], nxt[:40]))
    # 重复引用块
    seen = {}
    for i, l in enumerate(L, 1):
        if l.startswith('>') and not l.startswith('> **'):
            k = l[1:].strip()[:16]
            if len(k) >= 12:
                if k in seen:
                    dup.append((name, seen[k], i, k))
                else:
                    seen[k] = i

lines = ['# 伤寒论条文卡结构缺陷清单', '',
         '> 生成时间：2026-11-05　审计脚本：`tool/audit_verse_struct.py`',
         '> 说明：以下**不属于标点问题**，是内容被硬换行截断 / 原文块重复，',
         '> 需对照宋本原文逐条补齐，本次未自动修改。', '']

lines.append('## 一、标题被硬换行截断（%d 处）' % len(title_trunc))
lines.append('')
lines.append('原稿换页处硬断行，导入后标题只剩前半句，后半句掉到正文首行。')
lines.append('')
for n, i, t in title_trunc:
    lines.append('- `%s` L%d　`%s`' % (n, i, t[:100]))
lines.append('')

lines.append('## 二、原文块被截断，尾部掉出引用块（%d 处）' % len(quote_trunc))
lines.append('')
lines.append('引用块以逗号/冒号收尾，真正的后半句在下一行成了普通段落。')
lines.append('')
for n, i, tail, nxt in quote_trunc:
    lines.append('- `%s` L%d　末：…%s' % (n, i, tail))
    lines.append('  　掉出行外：%s' % nxt)
lines.append('')

lines.append('## 三、同一卡内重复引用块（%d 处）' % len(dup))
lines.append('')
lines.append('> 已用 `tool/dedupe_verse_prefix.py` 自动删除 7 处「严格前缀残片」')
lines.append('> （clause_004/006/017/048/051/059/084）；下列为**措辞有差异**、需人工确认的剩余项。')
lines.append('')
for n, a, b, k in dup:
    lines.append('- `%s` L%d 与 L%d　前缀「%s…」' % (n, a, b, k))
lines.append('')
lines.append('---')
lines.append('')
lines.append('合计：标题截断 %d + 原文截断 %d + 重复块 %d' %
             (len(title_trunc), len(quote_trunc), len(dup)))

out = os.path.join(ROOT, 'docs', '伤寒论原文结构缺陷.md')
open(out, 'w', encoding='utf-8', newline='\n').write('\n'.join(lines) + '\n')
print('写入', out)
print('标题截断 %d / 原文截断 %d / 重复块 %d' %
      (len(title_trunc), len(quote_trunc), len(dup)))
