# -*- coding: utf-8 -*-
"""删除条文卡内「截断残片 + 完整原文」中的残片引用块。

判定：同一卡有两个相邻引用块，且前者的去标点文本是后者的前缀（或完全相等），
则前者是导入残留的截断残片，可无损删除。

用法：
    python tool/dedupe_verse_prefix.py            # 预览
    python tool/dedupe_verse_prefix.py --apply    # 落盘
"""
import argparse
import glob
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = sorted(glob.glob(os.path.join(ROOT, 'assets', 'shanghan', 'clause_*.md')))


def norm(s):
    return re.sub(r'[\s，。、；：「」【】（）()\[\]]', '', s)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true')
    args = ap.parse_args()

    hits = 0
    for f in FILES:
        name = os.path.basename(f)
        L = [l.rstrip('\n') for l in open(f, encoding='utf-8')]
        idx = [i for i, l in enumerate(L)
               if l.startswith('>') and not l.startswith('> **')]
        drop = None
        for a, b in zip(idx, idx[1:]):
            na, nb = norm(L[a][1:]), norm(L[b][1:])
            if not na or not nb or na == nb:
                if na == nb and na:
                    drop = (a, b)
                    break
                continue
            if nb.startswith(na):
                drop = (a, b)
                break
        if drop is None:
            continue
        a, b = drop
        hits += 1
        print('\n--- %s ---' % name)
        print('  删除 L%-3d %s' % (a + 1, L[a][1:].strip()[:96]))
        print('  保留 L%-3d %s' % (b + 1, L[b][1:].strip()[:96]))
        if args.apply:
            # 连同其后的空行一并移除，避免留下双空行
            end = a + 1
            if end < len(L) and not L[end].strip():
                end += 1
            open(f, 'w', encoding='utf-8', newline='\n').write(
                '\n'.join(L[:a] + L[end:]))

    print('\n%s：%d 个文件' % ('已删除' if args.apply else '待删除', hits))


if __name__ == '__main__':
    main()
