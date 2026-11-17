#!/usr/bin/env python3
"""把天纪讲义里的超长正文行拆成段落（纯排版，零内容改动）。

背景：9 篇讲义中 3 篇把整节内容挤在单行里（最长 2824 字/行），
Markdown 渲染后就是"一大坨"。本脚本只插入换行，不改任何字符。

用法：
    python tool/format_tianji_paragraphs.py            # dry-run，只统计
    python tool/format_tianji_paragraphs.py --apply    # 写回文件

安全：
    - 只处理长度 > MIN_LINE 的正文行（不碰标题、短行、已有的正常段落）
    - 写回前校验"去掉所有空白后字符序列完全一致"，不一致直接拒绝写入
"""

import glob
import os
import re
import sys

MIN_LINE = 200    # 超过这个长度才认为需要切段
TARGET = 90       # 每段累积到约这个字数就断开
MAX_SENT = 150    # 单句超过这个长度就按逗号二次切

SENT = re.compile(r'[^。！？]*[。！？]|[^。！？]+$')
CLAUSE = re.compile(r'[^，、]*[，、]|[^，、]+$')
WS = re.compile(r'\s+')


def cut_sentence(s):
    """超长句按逗号切；正常句子原样返回。"""
    if len(s) <= MAX_SENT:
        return [s]
    parts, buf = [], ''
    for c in CLAUSE.findall(s):
        buf += c
        if len(buf) >= TARGET:
            parts.append(buf)
            buf = ''
    if buf.strip():
        parts.append(buf)
    return parts


def split_line(line):
    """一行 → 多段。拼回去必须与原行逐字一致。"""
    units = []
    for s in SENT.findall(line):
        units.extend(cut_sentence(s))
    out, buf = [], ''
    for u in units:
        buf += u
        if len(buf) >= TARGET:
            out.append(buf)
            buf = ''
    if buf.strip():
        out.append(buf)
    return out


def process(path, apply):
    raw = open(path, encoding='utf-8').read()
    lines = raw.split('\n')
    new_lines, changed = [], 0

    for line in lines:
        if len(line) > MIN_LINE and not line.lstrip().startswith('#'):
            paras = split_line(line)
            if len(paras) > 1:
                new_lines.extend(paras)
                new_lines.append('')      # 段间空行
                changed += 1
                continue
        new_lines.append(line)

    text = '\n'.join(new_lines)

    # 硬校验：去空白后必须与原文字符序列完全一致，否则拒写
    if WS.sub('', text) != WS.sub('', raw):
        raise SystemExit(f'✗ {path} 字符不一致，拒绝写入')

    body = [l for l in new_lines if l.strip() and not l.lstrip().startswith('#')]
    longest = max((len(l) for l in body), default=0)

    if apply and changed:
        open(path, 'w', encoding='utf-8', newline='\n').write(text)

    return changed, len(body), longest


def main():
    apply = '--apply' in sys.argv
    root = os.path.join(os.path.dirname(__file__), '..', 'assets', 'tianji')
    files = sorted(glob.glob(os.path.join(root, '*.md')))
    if not files:
        raise SystemExit('未找到 assets/tianji/*.md')

    total = 0
    for f in files:
        changed, paras, longest = process(f, apply)
        total += changed
        print(f'{os.path.basename(f):26} 切分行={changed:3}  段落={paras:4}  最长={longest:4}')

    mode = '已写入' if apply else 'dry-run（加 --apply 写入）'
    print(f'\n总切分行 {total} · {mode}')


if __name__ == '__main__':
    main()
