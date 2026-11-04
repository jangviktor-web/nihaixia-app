# -*- coding: utf-8 -*-
"""给伤寒论条文卡正文加「宋本第 X 条」标注（不改标题）。

用法：
  python tool/annotate_songben.py            # 预览：docs/宋本标注预览.md
  python tool/annotate_songben.py --apply    # 实际写入 384 张卡

标注规则：
- 插在首段 `> 原文` 引用块之后、讲解之前，单行 `【宋本标注】…`
- 保留旧讲义号做副标注，保住历史检索
- 拆条组标 `·拆条N`；总结卡（376-379）不加；无宋本号标「讲义插入条」
"""
import glob
import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MARK = '【宋本标注】'
D = '零一二三四五六七八九'


def cn_readable(n):
    """1-398 → 中文读法：72→七十二，268→二百六十八，380→三百八十。"""
    if n < 10:
        return D[n]
    if n < 20:
        return '十' + (D[n % 10] if n % 10 else '')
    if n < 100:
        return D[n // 10] + '十' + (D[n % 10] if n % 10 else '')
    h, rest = n // 100, n % 100
    s = D[h] + '百'
    if rest == 0:
        return s
    if rest < 10:
        return s + '零' + D[rest]
    if rest < 20:
        return s + '一十' + (D[rest % 10] if rest % 10 else '')
    return s + D[rest // 10] + '十' + (D[rest % 10] if rest % 10 else '')


def cn_digits(s):
    """讲义号阿拉伯 → 逐位中文（与原有 112 张中文序号卡写法一致）。"""
    return ''.join(D[int(c)] for c in str(s))


def lecture_no(head):
    m = re.match(r'^条文\s*(\d+)', head)
    if m:
        return cn_digits(m.group(1))
    m = re.match(r'^([零一二三四五六七八九十百]{1,6})\s*[：:]', head)
    return m.group(1) if m else ''


def annotation(r):
    # 总结卡不标；低置信/未匹配不标（宁缺勿错，避免把讲义插入条误标成宋本条）
    if r['seq'] in (376, 377, 378, 379) or r['confidence'] not in ('高', '中'):
        return None
    num = r['songben']
    if not num:
        return None
    old = lecture_no(r['head'])
    is_appendix = r['seq'] in (255, 380, 381, 382, 383)
    parts = ['宋本第%s条' % cn_readable(num)]
    if old:
        parts.append('讲义%s' % old)
    if '·' in r['label'] and not is_appendix:
        parts.append('拆条%s' % r['label'].split('·')[1])
    if is_appendix:
        parts.append('原典补录')
    return MARK + parts[0] + '（' + '，'.join(parts[1:]) + '）' if len(parts) > 1 else MARK + parts[0]


def insert_line(text, line):
    lines = text.split('\n')
    # 找首个 `> ` 连续块结束位置
    i = 1
    while i < len(lines) and not lines[i].strip():
        i += 1
    start = i
    while i < len(lines) and lines[i].strip().startswith('> '):
        i += 1
    if i == start:  # 无引用块 → 标题后
        i = 1
    pos = i
    while pos < len(lines) and not lines[pos].strip():
        pos += 1
    out = lines[:i] + ['', line, ''] + [l for l in lines[pos:] if True]
    return '\n'.join(out)


def main():
    apply = '--apply' in sys.argv
    rows = json.load(io.open(os.path.join(ROOT, 'songben_map.json'), encoding='utf-8'))
    by = {r['seq']: r for r in rows}
    stats = {'annotated': 0, 'low_confidence_skipped': 0, 'summary_skipped': 0, 'already': 0}
    samples = (1, 8, 83, 90, 262, 352, 376, 382, 383)
    skipped_shown = set()
    preview = ['# 宋本条号标注 · 改完预览', '',
               '> 生成：`tool/annotate_songben.py`（`--apply` 才实际写卡）',
               '> 位置：首段原文引用块之后、讲解之前；**标题完全不动**', '']
    for path in sorted(glob.glob(os.path.join(ROOT, 'assets/shanghan/clause_*.md'))):
        seq = int(re.search(r'clause_(\d+)', os.path.basename(path)).group(1))
        text = io.open(path, encoding='utf-8').read()
        r = by[seq]
        if MARK in text:
            stats['already'] += 1
            continue
        line = annotation(r)
        if line is None:
            if r['seq'] in (376, 377, 378, 379):
                stats['summary_skipped'] += 1
            else:
                stats['low_confidence_skipped'] += 1
        else:
            new = insert_line(text, line)
            stats['annotated'] += 1
            if apply:
                io.open(path, 'w', encoding='utf-8', newline='\n').write(new)
        if seq in samples:
            head = text.split('\n')[0]
            preview += ['---', '', '## `%s` — %s' % (os.path.basename(path), head), '',
                        '**改前（前 6 行）**', '', '```markdown']
            preview += text.split('\n')[:6]
            preview += ['```', '']
            if line is None:
                why = '总结卡' if r['seq'] in (376, 377, 378, 379) else '低置信/无可靠宋本号，宁缺勿错'
                preview += ['**改后**：**不改动**（%s）' % why, '']
            else:
                preview += ['**改后（前 9 行）**', '', '```markdown']
                preview += new.split('\n')[:9]
                preview += ['```', '']
    preview += ['---', '', '## 全量执行后的统计', '',
                '| 加宋本标注（高+中置信） | 低置信/无号跳过 | 总结卡跳过 | 已有标注 |',
                '|---|---|---|---|',
                '| %d | %d | %d | %d |' % (stats['annotated'], stats['low_confidence_skipped'],
                                            stats['summary_skipped'], stats['already']), '',
                '> 低置信行**不写任何标注**，避免把讲义插入内容或半句条文误标成宋本号；'
                '这些卡保留原讲义编号，后续人工核对后再补。', '']
    io.open(os.path.join(ROOT, 'docs/宋本标注预览.md'), 'w', encoding='utf-8',
            newline='\n').write('\n'.join(preview))
    print(('已写入卡片' if apply else '预览已生成') + ' → docs/宋本标注预览.md')
    print(stats)


if __name__ == '__main__':
    main()
