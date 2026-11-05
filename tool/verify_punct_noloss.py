# -*- coding: utf-8 -*-
"""验证标点统一未丢失任何文字内容：剥离标点后逐行比对。"""
import re
import subprocess

PUNCT = '，。、；：「」『』【】（）()[]！？·—…"\'\\ \t'


def norm(s):
    # 先做等价归一化（数字 0→〇、半角冒号→全角），再剥离标点
    s = s.replace('0', '〇').replace(':', '：')
    return ''.join(c for c in s if c not in PUNCT)


d = subprocess.run(['git', 'diff', '-U0', '--', 'assets/shanghan'],
                   capture_output=True, text=True, encoding='utf-8').stdout

old, new = [], []
for ln in d.split('\n'):
    if ln.startswith('---') or ln.startswith('+++'):
        continue
    if ln.startswith('-'):
        old.append(norm(ln[1:]))
    elif ln.startswith('+'):
        new.append(norm(ln[1:]))

print('变更行对：%d / %d' % (len(old), len(new)))
bad = [(a, b) for a, b in zip(old, new) if a != b]
print('剥标点后不一致：%d' % len(bad))
for a, b in bad[:20]:
    print('  旧:', a)
    print('  新:', b)
print('内容零丢失：%s' % ('PASS' if not bad else 'FAIL'))
