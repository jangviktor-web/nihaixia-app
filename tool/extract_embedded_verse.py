# -*- coding: utf-8 -*-
"""把「讲义编号 + 原文」夹在讲解段落里的句子抽出来，改成统一的 `> 原文` 引用块。

同类问题样本：clause_134 讲义一四〇「…宜『抵当丸』。」原本埋在 139 条卡的讲解里，
导致方剂索引扫不到、读者也看不到独立原文。

默认只预览（docs/夹在讲解里的原文.md），--apply 才写卡；幂等（已存在的引用不重复插）。
"""
import glob
import io
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
P = re.compile(
    r'(?<![零一二三四五六七八九十百〇0-9])'
    r'([零一二三四五六七八九十百〇]{1,6}|\d{1,3})\s*[：:]\s*'
    r'[「『【]?[^，。；！？]{0,24}[，。；]')
BAD = ('这个', '诸位', '打一打', '所以', '为什么', '实际上', '我们', '你看',
       '有没有', '就是', '如何分', '舒服', '可见', '抱歉', '大家', '意思',
       '比如说', '若人在', '将大肠', '它的比例')
CUE = re.compile(r'(诸位|这个|所以|我们|大家|第一|第二|看这个|条辨|处方|实际上|你看|'
                 r'抱歉|这里讲|讲的是|作比较|前文已有|有没有|为什么|比例|它的|当你|若人|'
                 r'\d+\s*条)')
EXCLUDE_FILES = {'clause_287.md'}          # 剂量比例「2：2：3」，非原文
# 自动判据漏掉的一条（编号前带「二0 」前缀、且原文内含「所以然者」被讲解提示词误截）
MANUAL = {'clause_191.md': [
    '二0 七：【阳明病】，若【中寒】，不能食，小便不利，手足濈濈然汗出，此欲作固瘕】，'
    '必大便初鞭后溏，所以然者，以胃中冷，水榖不别故也。',
]}
VERSE_WORDS = re.compile(r'(主之|宜|者|脉|汤|丸|散|病|利|汗|发热|恶寒|下之)')


def extract(line):
    """返回该行里所有夹着的原文句（按出现顺序）。"""
    s = line.strip()
    if s.startswith('> ') or s.startswith('#'):
        return []
    out = []
    for m in P.finditer(s):
        seg = s[m.start():]
        if len(seg) < 22 or any(b in seg[:28] for b in BAD):
            continue
        if not VERSE_WORDS.search(seg[:90]):
            continue
        cue = CUE.search(seg, 25)
        window = seg[:cue.start()] if cue else seg[:260]
        end = window.rfind('。')
        if end < 12:
            continue
        text = seg[:end + 1].strip()
        text = re.sub(r'（前文已有）$', '', text).strip()
        out.append(text)
    return out


def main():
    apply = '--apply' in sys.argv
    report = []
    total = 0
    for d in ('shanghan', 'jingui'):
        for path in sorted(glob.glob(os.path.join(ROOT, 'assets', d, 'clause_*.md'))):
            f = os.path.basename(path)
            if f in EXCLUDE_FILES:
                continue
            text = io.open(path, encoding='utf-8').read()
            lines = text.split('\n')
            found = []
            for i, l in enumerate(lines):
                for v in extract(l):
                    if v not in found:
                        found.append((i, v))
            for extra in MANUAL.get(f, []):
                if any(extra in l for l in lines):
                    idx = next(i for i, l in enumerate(lines) if extra in l)
                    found.append((idx, extra))
            if not found:
                continue
            # 只保留尚未成为引用块的
            existing = {l.strip()[2:].strip() for l in lines if l.strip().startswith('> ')}
            todo = [(i, v) for i, v in found if v not in existing]
            if not todo:
                continue
            total += len(todo)
            report.append('## `%s`（%d 处）' % (f, len(todo)))
            for i, v in todo:
                report.append('- L%d：`%s`' % (i, v[:90]))
            if not apply:
                continue
            # ① 从散文里删掉这些原句；② 在首段引用块之后插入统一格式引用
            new_lines = []
            for i, l in enumerate(lines):
                for _, v in todo:
                    if v in l:
                        l = l.replace(v, '')
                new_lines.append(l.rstrip())
            # 找首个引用块结束位置
            i = 1
            while i < len(new_lines) and not new_lines[i].strip():
                i += 1
            while i < len(new_lines) and new_lines[i].strip().startswith('> '):
                i += 1
            pos = i
            while pos < len(new_lines) and not new_lines[pos].strip():
                pos += 1
            block = ['']
            for _, v in todo:
                block += ['> ' + v, '']
            out = new_lines[:i] + block + new_lines[pos:]
            cleaned = '\n'.join(out)
            cleaned = re.sub(r'\n{3,}', '\n\n', cleaned)
            io.open(path, 'w', encoding='utf-8', newline='\n').write(cleaned)
    head = ['# 夹在讲解里的原文 · 抽取清单', '',
            '> `tool/extract_embedded_verse.py` 生成；默认预览，`--apply` 才写卡。',
            '> 处理方式：把原句从散文段落中移除，改成 `> 原文` 引用块，置于该卡首段引用块之后。', '',
            '**共 %d 处**' % total, '']
    io.open(os.path.join(ROOT, 'docs/夹在讲解里的原文.md'), 'w', encoding='utf-8',
            newline='\n').write('\n'.join(head + report + ['']))
    print(('已写入卡片' if apply else '预览') + ' → docs/夹在讲解里的原文.md，共 %d 处' % total)


if __name__ == '__main__':
    main()
