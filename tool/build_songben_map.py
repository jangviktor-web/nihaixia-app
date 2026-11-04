# -*- coding: utf-8 -*-
"""把伤寒论条文卡（讲义编号）对齐到宋本 398 条编号，产出待审对照表。

语料：tool/songben_398.txt（宋本通行本 1-398，来源见 docs/宋本条号对照表.md）
方法：卡内首条 `> 原文` 去标点/去序号 → 与宋本条文前缀做相似度；
      两套编号顺序编排，用 Needleman-Wunsch 全局对齐（允许讲义插入/宋本跳条）。
输出：docs/宋本条号对照表.md + songben_map.json
拆条：同宋本号多卡 → 副号 `二九·一 / 二九·二`（用户选定方案 A）
"""
import difflib
import glob
import io
import json
import os
import re
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STRIP = re.compile(
    r'[，。、；：？！「」『』【】\[\]（）()《》〈〉“”‘’\s—…·,.·:;!?·'
    r'0-9一二三四五六七八九十百零〇]')


def norm(s):
    return STRIP.sub('', s)


def to_cn(n):
    d = '零一二三四五六七八九'
    return ''.join(d[int(c)] for c in str(n))


def main():
    corpus = {}
    for line in io.open(os.path.join(ROOT, 'tool/songben_398.txt'), encoding='utf-8'):
        line = line.strip()
        if '|' in line:
            num, prefix = line.split('|', 1)
            corpus[int(num)] = norm(prefix)

    cards = []
    for path in sorted(glob.glob(os.path.join(ROOT, 'assets/shanghan/clause_*.md'))):
        f = os.path.basename(path)
        seq = int(re.search(r'clause_(\d+)', f).group(1))
        text = io.open(path, encoding='utf-8').read()
        lines = text.split('\n')
        head = re.sub(r'^#+\s*', '', lines[0].strip())
        quotes = [l.strip()[2:].strip() for l in lines if l.strip().startswith('> ')]
        q = quotes[0] if quotes else head
        q = re.sub(r'^(条文\s*\d+|[零一二三四五六七八九十百]{1,6})\s*[：:]\s*', '', q)
        cards.append((seq, f, head, norm(q)[:26], q[:34]))

    n, m = len(cards), len(corpus)
    sim = {}
    for i, c in enumerate(cards):
        nq = c[3]
        for j in range(1, m + 1):
            sim[(i, j)] = difflib.SequenceMatcher(None, nq, corpus[j]).ratio() if nq else 0.0

    MATCH_BONUS, GAP = 0.42, 0.30
    dp = [[-1e9] * (m + 1) for _ in range(n + 1)]
    bp = [[None] * (m + 1) for _ in range(n + 1)]
    dp[0][0] = 0.0
    for i in range(1, n + 1):
        dp[i][0] = dp[i - 1][0] - GAP
        bp[i][0] = 'up'
    for j in range(1, m + 1):
        dp[0][j] = dp[0][j - 1] - GAP
        bp[0][j] = 'left'
    for i in range(1, n + 1):
        row, prev, brow = dp[i], dp[i - 1], bp[i]
        for j in range(1, m + 1):
            s = sim[(i - 1, j)]
            diag = prev[j - 1] + s - MATCH_BONUS
            up = prev[j] - GAP
            left = row[j - 1] - GAP
            if diag >= up and diag >= left:
                row[j], brow[j] = diag, ('diag' if s >= 0.42 else None)
            elif up >= left:
                row[j], brow[j] = up, 'up'
            else:
                row[j], brow[j] = left, 'left'

    align = {}
    i, j = n, m
    while i > 0 and j > 0:
        b = bp[i][j]
        if b == 'diag':
            align[i - 1] = j
            i -= 1
            j -= 1
        elif b == 'up':
            i -= 1
        else:
            j -= 1

    rows = []
    for idx, (seq, f, head, nq, q) in enumerate(cards):
        if seq in (376, 377, 378, 379):
            rows.append(dict(seq=seq, file=f, head=head[:50], songben=None,
                             confidence='—', basis='总结卡/非条文', quote=q))
            continue
        num = align.get(idx)
        if num:
            s = sim[(idx, num)]
            conf = '高' if s >= 0.72 else ('中' if s >= 0.55 else '低')
            basis = '相似度 %.2f' % s
        else:
            conf, basis = '低', '对齐判定：讲义插入/无对应宋本条'
        rows.append(dict(seq=seq, file=f, head=head[:50], songben=num,
                         confidence=conf, basis=basis, quote=q))

    # 拆条识别：不受对齐约束的「全文最佳相似号」被多卡共享 → 视为同一宋本条拆出多卡
    raw = {}
    for idx, r in enumerate(rows):
        best_num, best_s = max(((j, sim[(idx, j)]) for j in range(1, m + 1)),
                               key=lambda x: x[1])
        raw[idx] = (best_num, best_s)
    groups = defaultdict(list)
    for idx, (num, s) in raw.items():
        if s >= 0.60:
            groups[num].append(idx)
    sub = {}
    for num, idxs in groups.items():
        if len(idxs) > 1:
            for k, idx in enumerate(idxs, 1):
                sub[idx] = (num, k)
                rows[idx]['songben'] = num
                rows[idx]['basis'] += '（拆条组·宋本%d）' % num
    for idx, r in enumerate(rows):
        num = r['songben']
        if num is None:
            r['label'] = '—'
        elif idx in sub:
            r['label'] = to_cn(num) + '·' + '零一二三四五六七八九'[sub[idx][1]]
        else:
            r['label'] = to_cn(num)

    high = sum(1 for r in rows if r['confidence'] == '高')
    mid = sum(1 for r in rows if r['confidence'] == '中')
    low = sum(1 for r in rows if r['confidence'] == '低')
    none_ = sum(1 for r in rows if r['songben'] is None)
    split = sum(1 for v in groups.values() if len(v) > 1)

    out = ['# 伤寒论条文卡 → 宋本条号对照表（待审）', '',
           '> 语料：宋本《伤寒论》通行本 398 条（赵开美本编号体系）；本地 `tool/songben_398.txt`',
           '> 来源：微信「伤寒论宋本条文398条」（张仲景·黄门本草，2023-10-01），编号 1–398 连续',
           '> 匹配：卡内首条原文引用 vs 宋本条文前缀，Needleman-Wunsch 全局对齐（允许插入/跳条）',
           '> 拆条方案：**A**（同宋本号多卡 → `二九·一 / 二九·二` 副号）',
           '', '## 统计', '',
           '| 高置信 | 中置信 | 低置信（需人工复核） | 未匹配 | 拆条组 |',
           '|---|---|---|---|---|',
           '| %d | %d | %d | %d | %d |' % (high, mid, low, none_, split), '',
           '## 逐卡对照', '',
           '| # | 文件 | 现标题（讲义号） | 建议宋本号（中文） | 置信 | 依据 | 原文前 34 字 |',
           '|---|---|---|---|---|---|---|']
    for r in rows:
        out.append('| %d | `%s` | %s | **%s** | %s | %s | %s |' %
                   (r['seq'], r['file'], r['head'].replace('|', '｜'), r['label'],
                    r['confidence'], r['basis'], r['quote'].replace('|', '｜')))
    out += ['', '## 特殊说明', '',
            '- 376–379 为六经总结卡，非条文，不编号。',
            '- 255 / 380–383 为原典补录卡，括号内已有宋本号；本表结果需与原括号号核对。',
            '- 「低置信/未匹配」行**不得自动改标题**，需逐条人工核对原文后再定。', '']
    io.open(os.path.join(ROOT, 'docs/宋本条号对照表.md'), 'w', encoding='utf-8',
            newline='\n').write('\n'.join(out))
    json.dump(rows, io.open(os.path.join(ROOT, 'songben_map.json'), 'w', encoding='utf-8'),
              ensure_ascii=False, indent=1)
    print('高 %d / 中 %d / 低 %d / 未匹配 %d / 拆条组 %d' % (high, mid, low, none_, split))
    print('报告 → docs/宋本条号对照表.md')
    for r in rows[:12]:
        print('  #%-3d %-8s %-2s %-18s %s' %
              (r['seq'], r['label'], r['confidence'], r['basis'][:18], r['head'][:28]))


if __name__ == '__main__':
    main()
