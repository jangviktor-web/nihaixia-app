# -*- coding: utf-8 -*-
"""生成 lib/data/neijing_lecture_data.dart（内经阅读库索引）"""
import os, re

OUT_DIR = 'assets/neijing'
files = sorted(f for f in os.listdir(OUT_DIR) if f.endswith('.md'))

entries = []
for f in files:
    m = re.match(r'(\d+)_(.+)\.md$', f)
    seq = int(m.group(1))
    name = m.group(2)
    entries.append((seq, name, f))

entries.sort()

lines = []
lines.append('/// 《人纪·黄帝内经》阅读库索引（拆分自倪师内经讲稿书面整理版）。')
lines.append('/// 72 篇正文 + 前言；原文第 25、66-74 篇原稿未收录，不强补。')
lines.append('library;')
lines.append('')
lines.append('class NeiJingLecture {')
lines.append('  final int seq; // 0=前言, 1-81=篇序')
lines.append('  final String name;')
lines.append('  final String asset;')
lines.append('')
lines.append('  const NeiJingLecture({')
lines.append('    required this.seq,')
lines.append('    required this.name,')
lines.append('    required this.asset,')
lines.append('  });')
lines.append('}')
lines.append('')
lines.append('const List<NeiJingLecture> kNeiJingLectures = [')
for seq, name, f in entries:
    title = '前言' if seq == 0 else '第%s篇' % name
    lines.append("  NeiJingLecture(seq: %d, name: '%s', asset: 'assets/neijing/%s'),"
                 % (seq, name, f))
lines.append('];')
lines.append('')
lines.append('/// 按篇序取资源路径；不存在返回 null。')
lines.append('String? neijingAsset(int seq) {')
lines.append('  for (final l in kNeiJingLectures) {')
lines.append('    if (l.seq == seq) return l.asset;')
lines.append('  }')
lines.append('  return null;')
lines.append('}')

body = '\n'.join(lines) + '\n'
with open('lib/data/neijing_lecture_data.dart', 'w', encoding='utf-8', newline='\n') as f:
    f.write(body)
print('生成条目数:', len(entries))
print('文件:', os.path.getsize('lib/data/neijing_lecture_data.dart'), 'bytes')
