# -*- coding: utf-8 -*-
"""按伤寒论模块排版格式重整 clause_375.md（三九七 + 霍乱篇 382-390）。

规则（与 clause_279/301/344 一致）：
- 每条原文：`#### 原文` + 空行 + `> 原文` + 空行 + 讲解
- 方剂：原文块之后的普通段落（不加标题）
- 讲稿未编条号，故用「原文直接做标题」式（同金匮「续伤寒篇」clause_367-369）

不做内容增删：只提升结构、清理考证夹注、繁体字转简。
输出 clause_375.md.new，人工核对后再替换。
"""
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P = os.path.join(ROOT, 'assets', 'shanghan', 'clause_375.md')
L = open(P, encoding='utf-8').read().split('\n')


def seg(a, b):
    """取 [a,b] 1-indexed 的非空行。"""
    return [L[i - 1].strip() for i in range(a, b + 1) if L[i - 1].strip()]


def clause(head, verse, notes=()):
    out = ['#### ' + head, '', '> ' + verse]
    for n in notes:
        out += ['', n]
    return out


blocks = []

# —— 三九七（原样）：标题、原文、讲解/书单/临别 ——
blocks.append(['#### ' + L[0][5:].strip()])
blocks.append(['> ' + L[2][2:].strip()])
for line in seg(5, 37):
    blocks.append([line])

# —— 续篇说明 ——
for line in seg(39, 39):
    blocks.append([line])
blocks.append([
    '> **续篇**：以下「辨霍乱病脉证并治」对应宋本第 382–391 条；讲稿于此未编条号，'
    '同篇亦见金匮「续伤寒篇」。'
])

# —— 382 ——
blocks.append(clause('问曰：病有霍乱者何？答曰：呕吐而利，是名霍乱。',
                     '问曰：病有霍乱者何？答曰：呕吐而利，是名霍乱。'))
for line in seg(43, 51):
    blocks.append([line])

# —— 383 ——
v383 = L[52].strip()
blocks.append(clause(v383, v383))
for line in seg(55, 59):
    blocks.append([line])

# —— 384（L61 + L89 同属宋本 384；L61 含考证夹注，拆出为校注）——
v384a = re.sub(r'\[钱超尘考证[^\]]*\]', '', L[60].strip())
v384a = v384a.replace('便必鞭鞕', '便必鞭')
v384 = v384a + L[88].strip()
blocks.append(clause(v384, v384, notes=(
    '*校注：「便必鞭」之「鞭」，钱超尘考证当作「鞕」（读 ying，隋朝本）。*',
)))
for line in seg(63, 87):
    blocks.append([line])
for line in seg(91, 91):
    blocks.append([line])

# —— 385 ——
v385 = L[92].strip()
blocks.append(clause(v385, v385))
blocks.append([L[94].strip()])          # 四逆加人参汤方
for line in seg(97, 127):
    blocks.append([line])

# —— 386 ——
v386 = L[128].strip()
blocks.append(clause(v386, v386))
for n in (131, 133, 135, 137):          # 理中丸方 + 服法 + 加减
    blocks.append([L[n - 1].strip().replace('食頃', '食顷')])
for line in seg(139, 185):
    blocks.append([line])

# —— 387 ——
v387 = L[186].strip()
blocks.append(clause(v387, v387))
for line in seg(189, 191):
    blocks.append([line])

# —— 388 ——
v388 = L[192].strip()
blocks.append(clause(v388, v388))
for line in seg(195, 201):
    blocks.append([line])

# —— 389 ——
v389 = L[202].strip()
blocks.append(clause(v389, v389))
for line in seg(205, 213):
    blocks.append([line])

# —— 390 ——
v390 = L[214].strip()
blocks.append(clause(v390, v390))
blocks.append([L[216].strip()])         # 通脉四逆加猪胆汁汤方
for line in seg(219, 227):
    blocks.append([line])

# 每条 block 内部行用 \n，block 之间空行
out = '\n\n'.join('\n'.join(b) for b in blocks) + '\n'

# —— 检查：是否残留繁体字（用 3786 条映射表的键来判断）——
conv = open(os.path.join(ROOT, 'lib/data/chinese_convert.dart'), encoding='utf-8').read()
trad_keys = set(re.findall(r"'([^'])'\s*:\s*'[^']'", conv))
leftover = {}
for i, ln in enumerate(out.split('\n'), 1):
    for ch in ln:
        if ch in trad_keys:
            leftover.setdefault(ch, []).append(i)

open(P + '.new', 'w', encoding='utf-8', newline='\n').write(out)

print('原行数 %d → 新行数 %d' % (len(L), len(out.split('\n'))))
print('#### 标题数:', out.count('\n#### ') + (1 if out.startswith('#### ') else 0))
print('> 引用块数:', sum(1 for l in out.split('\n') if l.startswith('> ')))
print('残留繁体字种类:', len(leftover))
for ch, lines in list(leftover.items())[:12]:
    print('   %s  行 %s' % (ch, lines[:6]))
