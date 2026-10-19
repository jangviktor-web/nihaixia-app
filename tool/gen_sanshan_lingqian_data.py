#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从命语(Brhiza/mingyu) ssgw-data/signs-full.ts 抽取三山国王灵签 92 签传统签谱，
生成 lib/data/sanshan_lingqian_data.dart。

只抽取传统签谱本身四样：签号 / 签题 / 签诗原文 / 吉凶等级。
命语自带的 story(典故) 与 details(现代解读) 一律不取 —— 那是该项目的 AGPL
生成内容，且属现代 AI 解读，非祖庙签谱原文。

数据源：广东省揭西县河婆街道三山国王祖庙传承 92 签签谱。
"""
import io
import re
import sys

SRC = sys.argv[1] if len(sys.argv) > 1 else 'D:/tmp-mingyu/mingyu/packages/core/src/divination/ssgw-data/signs-full.ts'
OUT = sys.argv[2] if len(sys.argv) > 2 else 'D:/AndroidProjects/nihaisha_app/lib/data/sanshan_lingqian_data.dart'

text = io.open(SRC, encoding='utf-8').read()

# 每条签是一个对象字面量：{ id: N, title: '...', qianwen: '...', story: '...', details: {...} }
# 只取 id/title/qianwen 三个顶层字段 + details 里的「吉凶」。
blocks = re.findall(r"\{\s*id:\s*(\d+),\s*title:\s*'((?:[^'\\]|\\.)*)',\s*qianwen:\s*'((?:[^'\\]|\\.)*)',", text)
print('matched blocks: %d' % len(blocks))

# 吉凶按出现顺序逐条对应（details 紧随 qianwen 之后）
jiqiong = re.findall(r"吉凶:\s*'([^']*)'", text)
print('matched 吉凶: %d' % len(jiqiong))

if len(blocks) != 92 or len(jiqiong) != 92:
    raise SystemExit('FAIL: expect 92/92, got %d/%d' % (len(blocks), len(jiqiong)))

LUCK = {'上签（大吉）': '上签·大吉', '中签（平）': '中签·平',
        '下签（凶）': '下签·凶', '无事签（平安）': '无事签·平安'}

seen = set()
lines = []
for (sid, title, qianwen), luck in zip(blocks, jiqiong):
    sid = int(sid)
    if sid in seen:
        raise SystemExit('FAIL: duplicate id %d' % sid)
    seen.add(sid)
    if luck not in LUCK:
        raise SystemExit('FAIL: unknown 吉凶 %r' % luck)
    title = title.replace("\\'", "'")
    qianwen = qianwen.replace("\\'", "'").replace('\\n', '\\n')
    lines.append(
        "  LingqianSign(%d, '%s', '%s', LingqianLuck.%s)," % (
            sid, title, qianwen, {'上签（大吉）': 'daJi', '中签（平）': 'ping',
                                  '下签（凶）': 'xiong', '无事签（平安）': 'pingAn'}[luck]))

if sorted(seen) != list(range(1, 93)):
    raise SystemExit('FAIL: ids not 1..92 contiguous')

header = """// 由 tool/gen_sanshan_lingqian_data.py 生成，请勿手工编辑。
// 数据源：广东省揭西县河婆街道三山国王祖庙传承 92 签签谱（签号/签题/签诗/吉凶）。
//   签谱正文整理参考 github.com/Brhiza/mingyu 的 ssgw-data（该项目 AGPL-3.0）；
//   此处仅取祖庙签谱的传统文本字段，其自带的现代解读内容一律未采用，
//   解读文案与全部代码为本项目自行撰写（Apache-2.0）。
// 三山国王为潮汕与客家地区重要民间信仰；本数据属民俗文化参考，非吉凶指令。

/// 灵签吉凶等级。
enum LingqianLuck {
  /// 上签·大吉
  daJi,

  /// 中签·平
  ping,

  /// 下签·凶
  xiong,

  /// 无事签·平安
  pingAn;

  String get label => switch (this) {
        LingqianLuck.daJi => '上签 · 大吉',
        LingqianLuck.ping => '中签 · 平',
        LingqianLuck.xiong => '下签 · 凶',
        LingqianLuck.pingAn => '无事签 · 平安',
      };
}

/// 一签：[id] 签号（1-92）、[title] 签题、[verse] 签诗原文、[luck] 吉凶等级。
class LingqianSign {
  final int id;
  final String title;
  final String verse;
  final LingqianLuck luck;
  const LingqianSign(this.id, this.title, this.verse, this.luck);
}

/// 三山国王灵签 92 签签谱，索引 i 对应第 i+1 签。
const List<LingqianSign> kSanShanLingqian = [
"""

footer = "];\n"

io.open(OUT, 'w', encoding='utf-8').write(header + '\n'.join(lines) + '\n' + footer)
print('wrote %s (%d signs)' % (OUT, len(lines)))
