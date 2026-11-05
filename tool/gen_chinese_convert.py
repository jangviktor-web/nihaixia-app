# -*- coding: utf-8 -*-
"""用 OpenCC t2s 生成完整繁→简 1:1 字符表，追加到 chinese_convert.dart。

背景：原表是 522 条手工维护，实测连「傷」都不在表内 →
`toSimplified('傷寒')` 原样返回，繁体搜「傷寒」搜不到。
手工枚举补不完，改为以 OpenCC 全量字典生成，手工条目优先（去重跳过）。

约定：只收「单字 → 单字」且不同的映射，保证长度不变
（`toSimplified` 依赖这一点做原文位置高亮）。
"""
import os
import re

import opencc

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DART = os.path.join(ROOT, 'lib', 'data', 'chinese_convert.dart')

src = open(DART, encoding='utf-8').read()
manual = re.findall(r"'([^'])'\s*:\s*'([^'])'", src)
manual_map = dict(manual)
print('手工条目:', len(manual_map))

cc = opencc.OpenCC('t2s')
generated = {}
for cp in range(0x3400, 0xA000):          # CJK 扩展A + 基本区
    ch = chr(cp)
    r = cc.convert(ch)
    if len(r) == 1 and r != ch and ch not in manual_map:
        generated[ch] = r
print('生成新增条目:', len(generated))

# 只保留能原样放回 Dart 单引号字面量的字符（无引号/反斜杠）
def ok(c):
    return c not in "'\\\n\r" and len(c) == 1


generated = {k: v for k, v in generated.items() if ok(k) and ok(v)}
print('过滤后可用:', len(generated))

items = sorted(generated.items(), key=lambda kv: ord(kv[0]))
lines = []
per = 8
for i in range(0, len(items), per):
    chunk = items[i:i + per]
    lines.append('  ' + ' '.join("'%s': '%s'," % (k, v) for k, v in chunk))

block = ('  // —— 以下由 OpenCC t2s 生成（tool/gen_chinese_convert.py），'
         '手工条目已优先去重 ——\n' + '\n'.join(lines) + '\n')

# 插入到 map 结尾 '};' 之前
idx = src.rindex('};')
new = src[:idx] + block + src[idx:]
open(DART, 'w', encoding='utf-8', newline='\n').write(new)

total = len(re.findall(r"'([^'])'\s*:\s*'([^'])'", new))
print('写入完成，总条目:', total)
# 自检
pairs = dict(re.findall(r"'([^'])'\s*:\s*'([^'])'", new))
for probe, want in [('傷', '伤'), ('蘭', '兰'), ('當', '当'), ('證', '证')]:
    got = pairs.get(probe)
    print('  %s -> %s %s' % (probe, got, 'OK' if got == want else '❌ 期望 %s' % want))
