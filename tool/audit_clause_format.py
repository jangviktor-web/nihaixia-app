# -*- coding: utf-8 -*-
"""条文卡内容格式一致性审计（只出报告，不改文件）。

用法：python tool/audit_clause_format.py
输出：终端摘要 + format_audit.json（机器可读明细）
"""
import glob
import io
import json
import os
import re
from collections import Counter, defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def classify_heading(head):
    if re.match(r'^条文\s*\d+\s*（[零一二三四五六七八九〇0-9]{2,5}）\s*[：:]', head):
        return 'H3 双号式（条文180（一八零）：…）'
    if re.match(r'^条文\s*\d+\s*[（(][^）)]*[）)]\s*[：:]', head):
        return 'H2 条文N（注）：描述'
    if re.match(r'^条文\s*\d+\s*(续|≈|—)?', head):
        return 'H1 条文N：描述/概括'
    if re.match(r'^[零一二三四五六七八九十]{1,4}\s*[：:]', head):
        return 'H4 原文式（中文序号：原文）'
    if re.match(r'^[\u4e00-\u9fff]{2,10}(（[^）]*）)?$', head) and \
            ('汤' in head or '丸' in head or '散' in head):
        return 'H5 方名式（炙甘草汤）'
    if re.search(r'第[一二三四五六七八九十]+篇?$|前言|总结|续伤寒篇', head):
        return 'H0 篇首/总结卡'
    if re.match(r'^[\u4e00-\u9fff]{2,12}', head) and len(head) <= 14:
        return 'H0 篇首/总结卡'
    return 'H6 其他'


def main():
    result = defaultdict(list)
    fam_counter = Counter()
    for d, lib in (('assets/shanghan', '伤寒'), ('assets/jingui', '金匮')):
        folder = os.path.join(ROOT, d)
        for p in sorted(glob.glob(folder + '/clause_*.md')):
            f = os.path.basename(p)
            t = io.open(p, encoding='utf-8').read()
            lines = t.split('\n')
            head = re.sub(r'^#+\s*', '', lines[0].strip())
            body = lines[1:]
            fam = classify_heading(head)
            fam_counter[(lib, fam)] += 1

            prose = [l for l in body if l.strip() and not l.strip().startswith(('>', '#', '-'))]
            bullets = [l for l in body if l.strip().startswith('- ')]
            has_std = any('**倪海厦解读**' in l for l in body)
            has_sel = any('**倪师讲解' in l for l in body)
            prose_len = sum(len(l.strip()) for l in prose)

            if has_sel:
                result['B 解读标记为「倪师讲解（讲稿节选）」'].append((lib, f, fam[:14]))
            elif not has_std and prose_len > 60:
                result['A 解读无统一标记（直接散文，无「**倪海厦解读**」）'].append((lib, f, fam[:14]))
            if has_std and len(bullets) == 0 and prose_len > 300:
                result['C 标记下为散文段落（非 bullet 列表）'].append((lib, f, fam[:14]))

            half_bold = [l.strip()[:44] for l in body if re.match(r'^\*\*[^*\n]{1,14}\*\*:', l)]
            if half_bold:
                result['D 粗体分节用半角冒号 **X**:'].append((lib, f, str(half_bold[:2])))

            if body and body[0].strip() and not body[0].strip().startswith('>'):
                result['E 标题后无空行直接接正文'].append((lib, f, body[0].strip()[:26]))

            if any(l.strip().startswith('#### ') for l in body):
                result['F 一卡内含多个 #### 子标题'].append((lib, f, fam[:14]))

            if t.rstrip().endswith('---') or t.count('\n---\n'):
                result['G 正文含 --- 分隔线'].append((lib, f, ''))

    print('=== 标题族分布 ===')
    for (lib, fam), n in sorted(fam_counter.items()):
        print(f'  {lib}｜{fam}: {n}')
    print()
    for k in sorted(result):
        v = result[k]
        print(f'=== {k}: {len(v)} 张 ===')
        for x in v[:8]:
            print('   ', x)
        if len(v) > 8:
            print(f'    …另有 {len(v) - 8}')
        print()
    json.dump({k: v for k, v in result.items()},
              io.open(os.path.join(ROOT, 'format_audit.json'), 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    print('明细 → format_audit.json')


if __name__ == '__main__':
    main()
