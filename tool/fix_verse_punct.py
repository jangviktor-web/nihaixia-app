# -*- coding: utf-8 -*-
"""统一伤寒论条文卡 `> 原文` 引用块的标点格式。

只改引用块（以 `>` 开头、且不是 `> **` 讲解块的）行，不碰标题与讲解段落。
冒号误插采用「逐条精确补丁」，不做泛化替换，避免误伤「问曰：」「汤方：」。

用法：
    python tool/fix_verse_punct.py            # 预览
    python tool/fix_verse_punct.py --apply    # 落盘
"""
import argparse
import glob
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = sorted(glob.glob(os.path.join(ROOT, 'assets', 'shanghan', 'clause_*.md')))

CJK = '\u4e00-\u9fff'

# ---- 冒号误插：逐条精确补丁（文件 → [(旧, 新), ...]）----
PATCH = {
    'clause_125.md': [('其腹必满：自汗出', '其腹必满，自汗出')],
    'clause_132.md': [('慎不可灸：因火为邪', '慎不可灸，因火为邪')],
    'clause_158.md': [('乃可攻之：其人', '乃可攻之。其人')],
    'clause_207.md': [('潮热：大便已鞕者', '潮热，大便已鞕者')],
    'clause_256.md': [('口苦：咽干：目眩也', '口苦，咽干，目眩也')],
    'clause_257.md': [('不可吐：下，吐：下则', '不可吐下，吐下则')],
    'clause_258.md': [('脉弦细：头痛：发热者', '脉弦细，头痛，发热者')],
    'clause_259.md': [('脉弦细：头痛：发热者', '脉弦细，头痛，发热者')],
    'clause_260.md': [('尚未吐：下', '尚未吐下')],
    'clause_261.md': [('已吐：下，发汗。温针', '已吐、下、发汗、温针')],
    'clause_293.md': [('腹痛：小便不利：下利不止：便脓血者',
                        '腹痛，小便不利，下利不止，便脓血者')],
    'clause_189.md': [('问曰：：恶寒', '问曰：恶寒')],
    'clause_191.md': [('此欲作固瘕】', '此欲作「固瘕」')],
}

# ---- 通用规范化（安全，可全量套用）----
GENERIC = [
    (re.compile('【([^】]*)】'), r'「\1」'),        # 【病名】→「病名」
    (re.compile(r'\[([^\]]*)\]'), r'「\1」'),      # [汤]   →「汤」
    (re.compile('」：「'), '」「'),                  # 引号之间用冒号 → 连排
    (re.compile(r'([%s])\)' % CJK), r'\1）'),      # 半角 ) → 全角 ）
    (re.compile(r'([%s]):' % CJK), r'\1：'),        # 半角 : → 全角 ：
    (re.compile(r'。，+'), '。'),                    # 。， → 。
    (re.compile(r'，{2,}'), '，'),
    (re.compile(r'。[ \t]+'), '。'),                 # 句号后空格
]

# 序号前缀：中文数字（含 ○ 与阿拉伯 0）+ 顿号
SEQ_RE = re.compile(r'^([〇零一二三四五六七八九十0-9、 ]{1,10})[：:](.*)$')

# 原文式标题：`#### 中文序号：原文`
VERSE_TITLE = re.compile(r'^####\s*[〇零一二三四五六七八九十0-9]+[：:]\S')


def norm_seq(prefix, rest):
    """中文序号规范化：阿拉伯 0 → 〇；顿号副号保留。"""
    p = prefix.replace(' ', '').replace('　', '').replace('0', '〇')
    return '%s：%s' % (p, rest)


def fix_line(name, body):
    # 1) 精确补丁
    for a, b in PATCH.get(name, ()):
        body = body.replace(a, b)
    # 2) 行尾反斜杠残留
    body = re.sub(r'[ \t]*\\[ \t]*$', '', body)
    # 3) 逗号 / 句号后多余空格（只在中文之间）
    body = re.sub(r'([，。；、])[ \t]+(?=[%s「【])' % CJK, r'\1', body)
    # 4) 序号前缀规范化
    m = SEQ_RE.match(body)
    if m and re.match(r'^[〇零一二三四五六七八九十0-9、 ]+$', m.group(1)):
        body = norm_seq(m.group(1), m.group(2))
    # 5) 通用替换
    for pat, rep in GENERIC:
        body = pat.sub(rep, body)
    return body


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true')
    args = ap.parse_args()

    total_lines = 0
    changed_files = 0
    for f in FILES:
        name = os.path.basename(f)
        src = open(f, encoding='utf-8').read()
        out = []
        local = []
        for i, ln in enumerate(src.split('\n'), 1):
            if ln.startswith('>') and not ln.startswith('> **'):
                body = ln[1:]
                led = ' ' if body.startswith(' ') else ''
                new = '>' + led + fix_line(name, body.lstrip())
                if new != ln:
                    local.append((i, ln, new))
                out.append(new)
            elif VERSE_TITLE.match(ln):
                # 原文式标题（`#### 中文序号：原文`）同样是原文，套同一套规则
                new = '#### ' + fix_line(name, ln[5:].strip())
                if new != ln:
                    local.append((i, ln, new))
                out.append(new)
            else:
                out.append(ln)
        if local:
            changed_files += 1
            total_lines += len(local)
            if args.apply:
                open(f, 'w', encoding='utf-8', newline='\n').write('\n'.join(out))
            else:
                print('\n--- %s (%d 行) ---' % (name, len(local)))
                for i, a, b in local:
                    print('  旧 %s' % a.strip()[:100])
                    print('  新 %s' % b.strip()[:100])

    print('\n%s：%d 行 / %d 文件' % ('已写入' if args.apply else '待改动',
                                    total_lines, changed_files))


if __name__ == '__main__':
    main()
