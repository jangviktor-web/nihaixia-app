#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""只重算 acupoint_index.json，不改篇 md。

篇清单以 lib/data/zhenjiu_lecture_data.dart 的 seq→asset 为准，
保证 json 里的 s 字段与 Dart 端 nameOf(seq) 一致。
"""
import glob
import importlib.util
import io
import json
import os
import re

ROOT = os.getcwd()  # 在项目根目录执行
DART = os.path.join(ROOT, 'lib', 'data', 'zhenjiu_lecture_data.dart')
OUT = os.path.join(ROOT, 'assets', 'zhenjiu_lecture', 'acupoint_index.json')


def load_module():
    p = os.path.join(ROOT, 'tool', 'import_renji_zhenjiu.py')
    spec = importlib.util.spec_from_file_location('irj', p)
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def main():
    src = io.open(DART, encoding='utf-8').read()
    pairs = re.findall(
        r"ZhenJiuLecture\(seq: (\d+), name: '([^']*)', asset: '([^']*)'\)", src)
    pairs = [(int(s), n, a) for s, n, a in pairs]
    pairs.sort()
    bodies, titles = [], []
    for seq, name, asset in pairs:
        fp = os.path.join(ROOT, asset)
        bodies.append(io.open(fp, encoding='utf-8').read())
        titles.append(name)
    print('篇数（dart 清单）: %d，seq 连续: %s'
          % (len(pairs), [p[0] for p in pairs] == list(range(len(pairs)))))

    m = load_module()
    idx = m.acupoint_index(bodies, titles)
    io.open(OUT, 'w', encoding='utf-8', newline='\n').write(
        json.dumps(idx, ensure_ascii=False, indent=1))
    keys = [k for k in idx if not k.startswith('_')]
    print('索引穴位数: %d' % len(keys))

    # 验收：错装是否清掉、缺失键是否补上
    def names(k):
        return [titles[h['s']] for h in idx.get(k, [])]

    for k in ['足五里', '手五里', '膝阳关', '腰阳关', '足通谷', '腹通谷',
              '头窍阴', '足窍阴', '譩譆']:
        if k in idx:
            print('  %-5s %d 篇: %s' % (k, len(idx[k]), ' / '.join(names(k)[:5])))
        else:
            print('  %-5s 仍无键' % k)


if __name__ == '__main__':
    main()
