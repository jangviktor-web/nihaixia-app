# -*- coding: utf-8 -*-
"""伤寒论卡片排版格式校验（格式门禁）。

规范见 `docs/伤寒论文本排版格式规范.md`。本脚本把规范变成可执行检查：
- 默认只报告，不修改
- `--gate` 模式下有任何 error 即退出码 1（供 CI / 发版前使用）
- `--fix-hint` 额外打印每条的修复建议

用法：
    python tool/lint_shanghan_format.py            # 报告
    python tool/lint_shanghan_format.py --gate     # 门禁
    python tool/lint_shanghan_format.py --only clause_143
"""
import argparse
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(ROOT, 'assets', 'shanghan')

CN = '〇零一二三四五六七八九十百'
# 口语标记：只出现在倪师讲解里，不该进原文块。
# 注意排除原文合法用法：「无他病」「以他药下之」的他、「然后复下之」的然后。
ORAL = re.compile(r'(诸位|老师|我们|你们|有没有|对不对|你看|这个|'
                  r'可见|里面|时候|就是|呢[，。]|啊[，。]|嘛[，。]|哦[，。]|甚多|哈[，。])')
# 原文块内禁止的标点（全角规范）
BAD_PUNCT = {',': '半角逗号', '(': '半角括号', ')': '半角括号', ':': '半角冒号',
             ';': '半角分号', '?': '半角问号', '!': '半角叹号',
             '【': '方头括号', '】': '方头括号', '[': '半角方括号', ']': '半角方括号'}
# 条文句式（用于「裸行原文」判定）
VERSE_TAIL = re.compile(r'(主之。|是名霍乱|属阳明也|当愈。|小和之。|利之即愈。)')

def load_conv():
    src = open(os.path.join(ROOT, 'lib/data/chinese_convert.dart'), encoding='utf-8').read()
    return set(re.findall(r"'([^'])'\s*:\s*'[^']'", src))


TRAD_KEYS = load_conv()
# 专名白名单（正确用字，不应简体化）
# 塚：大塚敬节；憹：懊憹；瞤：筋惕肉瞤（通行排印本用字）
TRAD_OK = set('塚憹瞤')


def cn2num(s):
    """中文序号转数字，兼容两种写法：
    逐位式（一四九 / 二〇六 → 149 / 206）与数值式（一百九十一 → 191）。
    """
    d = {'〇': 0, '零': 0, '一': 1, '二': 2, '三': 3, '四': 4,
         '五': 5, '六': 6, '七': 7, '八': 8, '九': 9}
    if not s:
        return None
    if not any(c in '十百千' for c in s):        # 逐位读法
        v = 0
        for c in s:
            if c not in d:
                return None
            v = v * 10 + d[c]
        return v
    total, num = 0, 0                            # 数值读法
    for c in s:
        if c in d:
            num = d[c]
        elif c in '十百千':
            unit = {'十': 10, '百': 100, '千': 1000}[c]
            total += (num or 1) * unit
            num = 0
        else:
            return None
    return total + num


def check(path):
    name = os.path.basename(path)
    lines = open(path, encoding='utf-8').read().split('\n')
    errs, warns = [], []

    def err(ln, rule, msg):
        errs.append((ln, rule, msg))

    def warn(ln, rule, msg):
        warns.append((ln, rule, msg))

    # I1 首行必须是 #### 标题
    if not lines[0].startswith('#### '):
        err(1, 'I1', '首行不是 `#### 标题`')

    # 收集小节：#### 行 + 其后第一个非空行 + 该节的「原文块」行号
    # 原文块 = 该节内第一个 `>` 行（`> **` 除外）；后续 `>` 行属讲解段落，不受原文规则约束。
    sections = []
    verse_idx = set()
    for i, l in enumerate(lines):
        if not l.startswith('#### '):
            continue
        nxt = next(((j, lines[j]) for j in range(i + 1, min(i + 5, len(lines)))
                    if lines[j].strip()), None)
        sections.append((i + 1, l[5:].strip(), nxt))
        for j in range(i + 1, len(lines)):
            if lines[j].startswith('#### '):
                break
            if lines[j].startswith('> ') and not lines[j].startswith('> **'):
                verse_idx.add(j + 1)
                break

    # I2 条文类小节后必须有原文块。
    # 「方剂小节 / 篇首主题小节 / 总结卡」不适用（模块本来就允许一卡多节）。
    NON_VERSE = re.compile(r'(方([（(]|$|：|:)|总结|原理|病机|对比|警示|详解|'
                           r'概述|总纲|前言|续|加减|补遗|鉴别|要点)')

    def is_formula_section(nxt):
        if nxt is None:
            return False
        return bool(re.match(r'^[^\s，。]{2,14}方[：:]?', nxt[1].strip()))

    def is_verse_section(head):
        """条文类：中文序号开头 / 问曰答曰 / 明显是原文句（长且含仲景句式）。"""
        if re.match(r'^[%s]+\s*[：:]' % CN, head):
            return True
        if re.match(r'^(问曰|答曰|师曰|太阳病|伤寒|阳明病|少阳病|太阴病|少阴病|厥阴病|霍乱)', head):
            return True
        return False

    for ln, head, nxt in sections:
        if nxt is not None and nxt[1].startswith('>'):
            continue
        if is_formula_section(nxt) or NON_VERSE.search(head):
            continue
        if not is_verse_section(head):
            continue
        err(ln, 'I2', '「%s」后没有原文块（`>`）' % head[:24])

    # I9 标题为「中文序号：原文」时，原文块必须一致
    for ln, head, nxt in sections:
        m = re.match(r'^(%s+)\s*[：:]\s*(.+)$' % CN, head)
        if m and nxt and nxt[1].startswith('> '):
            body = nxt[1][2:].strip()
            if body != m.group(2).strip():
                err(ln, 'I9', '标题序号后正文与原文块不一致')
        # I5 序号本身：不得混阿拉伯数字/拉丁 O/空格
        if m and re.search(r'[0-9A-Za-z ]', m.group(1)):
            err(ln, 'I5', '中文序号混入阿拉伯数字/拉丁字母/空格：%r' % m.group(1))

    # I10 双号式：条文N 与（中文）一致
    for ln, head, _ in sections:
        m = re.match(r'^条文(\d+)（([%s]+)）' % CN, head)
        if m:
            a, b = int(m.group(1)), cn2num(m.group(2))
            if b is not None and a != b:
                warn(ln, 'I10', '条文号 %d 与中文序号「%s」不一致' % (a, m.group(2)))

    # 原文块内容检查（I3/I4/I5）——只查真原文块，讲解段落（后续 `>` 行）不适用
    for i, l in enumerate(lines, 1):
        if i not in verse_idx:
            continue
        body = l[2:]
        om = ORAL.search(body)
        if om:
            err(i, 'I3', '原文块混入口语「%s」' % om.group(1))
        for ch, why in BAD_PUNCT.items():
            if ch in body:
                err(i, 'I4', '原文块出现%s「%s」' % (why, ch))
        if '【' in body or '】' in body:
            err(i, 'I4', '原文块出现方头括号')
        if not re.match(r'^[%s]' % CN, body) and re.search(r'[%s][0-9O]' % CN, body):
            err(i, 'I5', '原文块中文序号混写')

    # I6 简体（残留繁体字）
    trad = {}
    for i, l in enumerate(lines, 1):
        if l.startswith('####') or l.startswith('>'):
            for ch in l:
                if ch in TRAD_KEYS and ch not in TRAD_OK:
                    trad.setdefault(ch, i)
    for ch, ln in list(trad.items())[:6]:
        warn(ln, 'I6', '残留繁体字「%s」' % ch)

    # I7 裸行条文（列表项 `- `/`* ` 属讲解，不参与判定）
    for i, l in enumerate(lines, 1):
        s = l.strip()
        if not s or s.startswith('#') or s.startswith('>') or s.startswith('- ') or s.startswith('* '):
            continue
        if len(s) <= 90 and VERSE_TAIL.search(s) and not ORAL.search(s):
            err(i, 'I7', '裸行条文（应放进 `>` 原文块）：%s' % s[:40])

    # I11 孤儿残片：裸行只剩序号字符（如「二0」「二〇」），是截断/清洗残留
    ORPHAN = re.compile(r'^[%s0Oo\s]{1,8}$' % CN)
    for i, l in enumerate(lines, 1):
        s = l.strip()
        if not s or s.startswith('#') or s.startswith('>') or s.startswith('- ') or s.startswith('* '):
            continue
        if ORPHAN.match(s):
            err(i, 'I11', '孤儿残片（只剩序号字符）：%r' % s)

    # I8 同卡重复原文块
    seen = {}
    for i, l in enumerate(lines, 1):
        if l.startswith('> ') and not l.startswith('> **'):
            body = l[2:].strip()
            if len(body) >= 12:
                if body in seen:
                    err(i, 'I8', '原文块与第 %d 行重复' % seen[body])
                else:
                    seen[body] = i

    return errs, warns


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--gate', action='store_true', help='有 error 即退出码 1')
    ap.add_argument('--only', default='', help='只查文件名包含该串的卡')
    ap.add_argument('--quiet', action='store_true', help='只输出汇总')
    a = ap.parse_args()

    files = sorted(glob.glob(os.path.join(DIR, 'clause_*.md')))
    if a.only:
        files = [f for f in files if a.only in f]

    total_err = total_warn = 0
    bad_files = 0
    for f in files:
        e, w = check(f)
        total_err += len(e)
        total_warn += len(w)
        if e:
            bad_files += 1
        if (e or w) and not a.quiet:
            print('── %s  (error %d / warn %d)' % (os.path.basename(f), len(e), len(w)))
            for ln, rule, msg in e:
                print('   ✗ L%-3d [%s] %s' % (ln, rule, msg))
            for ln, rule, msg in w:
                print('   ⚠ L%-3d [%s] %s' % (ln, rule, msg))

    print('\n卡片 %d 张；error %d 条（%d 张卡）／warn %d 条'
          % (len(files), total_err, bad_files, total_warn))
    if a.gate and total_err:
        sys.exit(1)


if __name__ == '__main__':
    main()
