# -*- coding: utf-8 -*-
"""校验硬换行合并未吞字：非空白字符总量对比 HEAD 与工作树。

预期差异 = 手工/自动删除的重复残片字符数（可枚举），其余应为 0。
"""
import re
import subprocess

FILES = subprocess.run(['git', 'ls-files', 'assets/shanghan'],
                       capture_output=True, text=True, encoding='utf-8').stdout.split()


def now_chars():
    tot = 0
    for f in FILES:
        s = open(f, encoding='utf-8').read()
        tot += len(re.sub(r'\s', '', s))
    return tot


def head_chars():
    tot = 0
    for f in FILES:
        s = subprocess.run(['git', 'show', 'HEAD:' + f],
                           capture_output=True, text=True, encoding='utf-8').stdout
        tot += len(re.sub(r'\s', '', s))
    return tot


a, b = head_chars(), now_chars()
print('HEAD 非空白字符：%d' % a)
print('当前非空白字符：%d' % b)
print('净变化：%d' % (b - a))

# 统计自动去重（dedupe）删掉的字符
d = subprocess.run(['git', 'diff', '-U0', '--', 'assets/shanghan'],
                   capture_output=True, text=True, encoding='utf-8').stdout
removed = [l[1:] for l in d.split('\n')
           if l.startswith('-') and not l.startswith('---')]
added = [l[1:] for l in d.split('\n')
         if l.startswith('+') and not l.startswith('+++')]
na = sum(len(re.sub(r'\s', '', x)) for x in removed)
nb = sum(len(re.sub(r'\s', '', x)) for x in added)
print('\n删除行字符：%d　新增行字符：%d' % (na, nb))
print('删除-新增：%d（应等于被删重复残片 + 标点压缩量）' % (na - nb))
