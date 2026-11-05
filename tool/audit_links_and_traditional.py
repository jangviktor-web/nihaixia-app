# -*- coding: utf-8 -*-
"""链接完整性 + 繁简往返风险审计。

三件事：
1. 药材别名表 _canonicalOf 的每个「正名」是否真存在于 herbs.json（否则别名点击落空）
2. 穴位短名映射 kShortNameLinkForm 的每个目标是否能被 findByName 解析
3. 所有可注入名称（方剂/药材/别名/穴位短名）里，哪些字不在 496 字繁→简表
   —— 这些字在繁体模式下会导致 href 无法还原、搜索无法命中
"""
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def load_names(path, key='name'):
    d = json.load(open(os.path.join(ROOT, path), encoding='utf-8'))
    items = d if isinstance(d, list) else (d.get('formulas') or d.get('herbs')
                                           or d.get('items') or d.get('acupoints') or [])
    out = []
    for it in items:
        if isinstance(it, dict) and it.get(key):
            out.append(it[key])
        elif isinstance(it, str):
            out.append(it)
    return out


def parse_dart_map(rel_path, map_var):
    """从 Dart 源里抠出 const Map/Map 字面量中的 'k': 'v' 对。"""
    src = open(os.path.join(ROOT, rel_path), encoding='utf-8').read()
    i = src.find(map_var)
    if i < 0:
        return {}
    seg = src[i:]
    # 截到下一个顶层 '};'
    end = seg.find('};')
    seg = seg[:end if end > 0 else len(seg)]
    return dict(re.findall(r"'([^']+)'\s*:\s*'([^']+)'", seg))


herb_names = load_names('assets/data/herbs.json')
formula_names = load_names('assets/data/formulas.json')
acupoint_names = load_names('assets/data/acupoints.json')

# 药材正名可能写作「正名（别名）」
herb_canon = set()
for n in herb_names:
    herb_canon.add(n)
    herb_canon.add(n.split('（')[0].strip())

alias_map = parse_dart_map('lib/data/herb_repository.dart', '_canonicalOf')
short_map = parse_dart_map('lib/data/acupoint_repository.dart', 'kShortNameLinkForm')

print('=== 1. 药材别名 → 正名 是否都有对应药材 ===')
bad_alias = {k: v for k, v in alias_map.items() if v not in herb_canon}
print('别名条目 %d，正名缺失 %d' % (len(alias_map), len(bad_alias)))
for k, v in list(bad_alias.items())[:12]:
    print('   别名「%s」→ 正名「%s」 不存在' % (k, v))

print('\n=== 2. 穴位短名映射是否可解析 ===')
acu_set = set(acupoint_names)
acu_strip = {a.replace('穴', '') for a in acupoint_names}


def acu_resolvable(name):
    if name in acu_set:
        return True
    return name.replace('穴', '') in acu_strip


bad_short = {k: v for k, v in short_map.items() if not acu_resolvable(v)}
print('短名映射 %d，无法解析 %d' % (len(short_map), len(bad_short)))
for k, v in list(bad_short.items())[:12]:
    print('   短名「%s」→ 目标「%s」 不存在' % (k, v))

print('\n=== 3. 繁体模式下的往返风险（496 字表覆盖）===')
conv_src = open(os.path.join(ROOT, 'lib/data/chinese_convert.dart'), encoding='utf-8').read()
pairs = re.findall(r"'([^'])'\s*:\s*'([^'])'", conv_src)
simplified_values = {v for _, v in pairs}
print('繁→简表条目 %d，覆盖简体字 %d 个' % (len(pairs), len(simplified_values)))

candidates = set()
for n in formula_names + list(herb_canon) + list(alias_map.keys()) + list(short_map.keys()):
    candidates.add(n)
chars = set()
for n in candidates:
    chars |= {c for c in n if '\u4e00' <= c <= '\u9fff'}
print('可注入名称 %d 个，去重汉字 %d 个' % (len(candidates), len(chars)))

uncovered = sorted(c for c in chars if c not in simplified_values)
print('其中不在表内（可能无法从繁体还原）：%d 个' % len(uncovered))
print('   ', ''.join(uncovered))
