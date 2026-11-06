#!/usr/bin/env python3
"""从 assets/shanghan/ 重建 kShangHanLectures 清单。

切换到 shanghan_unified 后，文件名即宋本条号：
  clause_001.md .. clause_390.md  → 宋本 1..390
  appendix_001..004               → 4 篇六经总结附录
共 394 条。name 加「宋本N·」前缀，保证阿拉伯数字条号在阅读库列表里可搜
（正文标题用的是中文序号，如「一七六、」，阿拉伯数字命中不了）。

用法：
  python tool/rebuild_shanghan_lecture_index.py          # 只产 .new 预览
  python tool/rebuild_shanghan_lecture_index.py --apply # 落地
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DIR = os.path.join(ROOT, 'assets', 'shanghan')
DART = os.path.join(ROOT, 'lib', 'data', 'classic_lecture_data.dart')
START = 'const List<ClassicLecture> kShangHanLectures = ['
NEXT = 'const List<ClassicLecture> kJinguiLectures = ['
MAX_NAME = 32


def esc(s):
    """转成 Dart 单引号字符串字面量内容。"""
    return s.replace('\\', '\\\\').replace("'", r"\'")


def clip(s, n=MAX_NAME):
    s = s.strip()
    return s if len(s) <= n else s[:n] + '…'


def title_of(path):
    with open(path, encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if line.startswith('#'):
                return line.lstrip('#').strip()
    raise SystemExit('无标题行: ' + path)


def clause_files():
    fs = glob.glob(os.path.join(DIR, 'clause_*.md'))
    fs.sort(key=lambda p: int(re.search(r'clause_(\d+)\.md$', p).group(1)))
    return fs


def appendix_files():
    fs = glob.glob(os.path.join(DIR, 'appendix_*.md'))
    fs.sort(key=lambda p: int(re.search(r'appendix_(\d+)[_.]', p).group(1)))
    return fs


def build_lines():
    lines = []
    seq = 0
    for p in clause_files():
        n = int(re.search(r'clause_(\d+)\.md$', p).group(1))
        t = title_of(p)
        # 标题形如「一七六、原文」，去掉中文序号前缀，改挂「宋本N·」
        body = t.split('、', 1)[1] if '、' in t else t
        name = '宋本%d·%s' % (n, clip(body))
        rel = 'assets/shanghan/' + os.path.basename(p)
        lines.append("  ClassicLecture(seq: %d, name: '%s', asset: '%s'),"
                     % (seq, esc(name), rel))
        seq += 1
    for p in appendix_files():
        name = clip(title_of(p))
        rel = 'assets/shanghan/' + os.path.basename(p)
        lines.append("  ClassicLecture(seq: %d, name: '%s', asset: '%s'),"
                     % (seq, esc(name), rel))
        seq += 1
    return lines, seq


def main():
    with open(DART, encoding='utf-8') as f:
        src = f.read()
    if START not in src or NEXT not in src:
        raise SystemExit('清单边界标记缺失，拒绝改写')
    head = src.split(START, 1)[0]
    tail = NEXT + src.split(NEXT, 1)[1]
    lines, n = build_lines()
    block = START + '\n' + '\n'.join(lines) + '\n];\n\n'
    out = head + block + tail

    # 自检：条数、唯一性、资产真实存在
    assets = re.findall(r"asset: '([^']+)'", block)
    assert len(assets) == n, ('条数不符', len(assets), n)
    assert len(set(assets)) == n, '资产路径重复'
    for a in assets:
        assert os.path.isfile(os.path.join(ROOT, a)), '资产不存在: ' + a

    print('生成 %d 条，资产全部存在且唯一' % n)
    print('--- 前 2 条 ---')
    print('\n'.join(lines[:2]))
    print('--- 末 5 条 ---')
    print('\n'.join(lines[-5:]))
    if '--apply' in sys.argv:
        with open(DART, 'w', encoding='utf-8', newline='\n') as f:
            f.write(out)
        print('已落地: ' + DART)
    else:
        preview = DART + '.new'
        with open(preview, 'w', encoding='utf-8', newline='\n') as f:
            f.write(out)
        print('预览已写入: ' + preview)


if __name__ == '__main__':
    main()
