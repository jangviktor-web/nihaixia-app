#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""README 三语 + 免费指南：GFM 表格结构校验

为什么需要这个脚本
------------------
GFM 规范要求 delimiter row 的 cell 数**必须等于** header row，否则整张表不被识别，
会退化成一段带竖线的纯文本（肉眼看是"表格烂了"）。
数据行 cell 数与表头不等时，GitHub 会静默截断多余列 / 补空缺失列 —— 内容凭空消失。

2026-11-07 实际踩过：加「书生 InternLM」第三列时只改了表头和数据行、
漏了分隔行与简中表头，导致三份 README 的配置对比表全部破损，且已推送。

用法
----
    python tool/check_readme_tables.py          # 校验，不一致则 exit 1
    python tool/check_readme_tables.py -v       # 同时打印每张表的列数

约定
----
- 跳过 ``` 代码块内的内容
- 表格判定：行以 | 开头，且下一行是 |-: 之类的分隔行
"""
import io
import re
import sys

FILES = ['README.md', 'README.zh-Hant.md', 'README.en.md', 'docs/free_api_guide.md']
SEP = re.compile(r'^\s*\|?[\s:|-]+\|[\s:|-]*$')


def cells(line):
    t = line.strip()
    if t.startswith('|'):
        t = t[1:]
    if t.endswith('|'):
        t = t[:-1]
    return t.split('|')


def check(path, verbose=False):
    lines = io.open(path, encoding='utf-8').read().split('\n')
    bad = []
    i = 0
    fences = 0
    tables = 0
    while i < len(lines):
        if lines[i].lstrip().startswith('```'):
            fences ^= 1
        if (fences == 0 and i + 1 < len(lines)
                and lines[i].strip().startswith('|')
                and SEP.match(lines[i + 1])
                and '-' in lines[i + 1]):
            tables += 1
            hdr = len(cells(lines[i]))
            sep = len(cells(lines[i + 1]))
            if hdr != sep:
                bad.append((i + 1, 'header=%d sep=%d' % (hdr, sep), lines[i][:66]))
            j = i + 2
            while j < len(lines) and lines[j].strip().startswith('|'):
                n = len(cells(lines[j]))
                if n != hdr:
                    bad.append((j + 1, 'data=%d header=%d' % (n, hdr), lines[j][:66]))
                j += 1
            if verbose:
                print('   L%-4d %d 列表格  %s' % (i + 1, hdr, lines[i].strip()[:60]))
            i = j
            continue
        i += 1
    if verbose:
        print('   共 %d 张表' % tables)
    return bad


def main():
    verbose = '-v' in sys.argv
    fail = 0
    for f in FILES:
        try:
            bad = check(f, verbose)
        except FileNotFoundError:
            print('⚠️  跳过（文件不存在）：' + f)
            continue
        if bad:
            fail = 1
            print('❌ ' + f)
            for ln, why, txt in bad:
                print('   L%-4d %-18s %s' % (ln, why, txt))
        else:
            print('✅ ' + f)
    if fail:
        print('\n修复提示：补齐 delimiter row / 表头 的列数，勿只改数据行。')
    else:
        print('\n全部表格列数一致。')
    return fail


if __name__ == '__main__':
    sys.exit(main())
