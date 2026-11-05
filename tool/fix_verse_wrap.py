# -*- coding: utf-8 -*-
"""修复条文卡「原稿硬换行」造成的截断。

根因：讲义原稿在固定宽度处断行，导入脚本按行处理，导致
  - `#### <序号>：原文前半句`  标题被切
  - `> 原文前半句`            引用块被切
  - 后半句掉成裸段落
同一处断行产生三个症状，所以一个脚本一起修：

  1. 引用块以「，、；：」收尾或引号/括号未闭合 → 把紧随的裸段落接回引用块
  2. 原文式标题（`中文序号：原文`）→ 用接好的引用块文本重写标题
  3. 删「截断残片 + 完整版」重复引用块（仅当短句严格包含于长句）

用法：
    python tool/fix_verse_wrap.py            # 预览
    python tool/fix_verse_wrap.py --apply    # 落盘
"""
import argparse
import glob
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FILES = sorted(glob.glob(os.path.join(ROOT, 'assets', 'shanghan', 'clause_*.md')))

SEQ_TITLE = re.compile(r'^(####\s*)([〇零一二三四五六七八九十0-9]+[：:])(.*)$')
NOT_CONTINUATION = ('#', '>', '-', '*', '|', '!', '[')


def norm(s):
    return re.sub(r'[\s，。、；：「」【】（）()\[\]]', '', s)


def is_open(text):
    """句子未结束：剥掉收尾引号/括号后，末字不是句末标点。"""
    t = text.rstrip().rstrip('」』】）)')
    return bool(t) and t[-1] not in '。！？'


def merge_wrapped(lines, log):
    """把截断的引用块与其续行合并。"""
    i = 0
    while i < len(lines):
        ln = lines[i]
        if not ln.startswith('>') or ln.startswith('> **'):
            i += 1
            continue
        body = ln[1:].strip()
        if not body or not is_open(body):
            i += 1
            continue
        # 找下一条非空行
        j = i + 1
        while j < len(lines) and not lines[j].strip():
            j += 1
        if j >= len(lines) or lines[j].startswith(NOT_CONTINUATION):
            i += 1
            continue
        cont = lines[j].strip()
        merged = body + cont
        log.append(('合并引用块', lines[i], '>' + (' ' if ln[1:2] == ' ' else '') + merged))
        lines[i] = '>' + (' ' if ln[1:2] == ' ' else '') + merged
        del lines[i + 1:j + 1]          # 删除空行 + 续行
        # 不 i++：合并后可能仍需继续接下一行
    return lines


def sync_title(lines, log):
    """原文式标题用引用块全文重写。"""
    if not lines or not lines[0].startswith('####'):
        return lines
    m = SEQ_TITLE.match(lines[0])
    if not m:
        return lines
    prefix, seq, head = m.group(1), m.group(2), m.group(3).strip()
    quote = next((l[1:].strip() for l in lines[1:]
                  if l.startswith('>') and not l.startswith('> **')), '')
    if not quote:
        return lines
    nq, nh = norm(quote), norm(head)
    if not nh or not nq.startswith(nh) or nq == nh:
        return lines
    new = '%s%s%s' % (prefix, seq, quote)
    log.append(('同步标题', lines[0], new))
    lines[0] = new
    return lines


def dedupe(lines, log):
    """删除「截断残片 + 完整版」中的残片。"""
    idx = [i for i, l in enumerate(lines)
           if l.startswith('>') and not l.startswith('> **')]
    for a, b in zip(idx, idx[1:]):
        na, nb = norm(lines[a]), norm(lines[b])
        if not na or not nb:
            continue
        if na == nb or nb.startswith(na):
            log.append(('删除残片', lines[a], '（保留）' + lines[b]))
            end = a + 1
            if end < len(lines) and not lines[end].strip():
                end += 1
            del lines[a:end]
            return lines
    return lines


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--apply', action='store_true')
    args = ap.parse_args()

    total = 0
    touched = 0
    for f in FILES:
        name = os.path.basename(f)
        lines = open(f, encoding='utf-8').read().split('\n')
        log = []
        merge_wrapped(lines, log)
        sync_title(lines, log)
        dedupe(lines, log)
        if not log:
            continue
        touched += 1
        total += len(log)
        print('\n--- %s ---' % name)
        for kind, a, b in log:
            print('  [%s] 旧 %s' % (kind, a.strip()[:94]))
            print('  %s新 %s' % (' ' * (len(kind) + 3), b.strip()[:94]))
        if args.apply:
            open(f, 'w', encoding='utf-8', newline='\n').write('\n'.join(lines))

    print('\n%s：%d 处 / %d 文件' % ('已写入' if args.apply else '待修复',
                                    total, touched))


if __name__ == '__main__':
    main()
