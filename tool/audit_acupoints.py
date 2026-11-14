#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""穴位详情数据（assets/data/acupoints.json）审计脚本。

用法：
  python tool/audit_acupoints.py            # 输出报告，有 error 时退出码 1
  python tool/audit_acupoints.py --json     # 输出 JSON 格式报告

规范依据：docs/acupoint_style_guide.md（穴位详情页写法工作流）。
检查项 id 与文档章节对应，修复时按 id 查规范。
"""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / 'assets' / 'data' / 'acupoints.json'

FIELDS = ['name', 'meridian', 'attribute', 'description', 'location',
          'needling', 'moxibustion', 'clinicalNotes', 'contraindication']

# 目录引导点（半角 ··· 连排 + 页码）——真污染；全角 …… 是正常省略号，不算
TOC_DOTS = re.compile(r'·{3,}|…{2,}·')
# 讲稿小节标题行的时间戳（允许存在于 clinicalNotes 中部/开头，末尾 40 字内为截断混入）
TS_LINE = re.compile(r'（\s*\d+-\d{2}:\d{2}:\d{2}\s*）|\(\s*\d+-\d{2}:\d{2}:\d{2}\s*\)')
# 句子终结标点（截断的长文本尾部缺少它）
END_PUNCT = re.compile(r'[。！？…”"』」）)】\.!?]$')
# 灸法格式
JIU_RE = re.compile(r'灸[一二三四五六七八九十百\d]+壮|不[宜可]?灸|禁灸')
# 书证（《铜人》《素注》等）
SHU_RE = re.compile(r'《[^》]+》')
# location 里的讲稿口语/演示特征词——命中说明填的是讲稿正文切片，不是定位
KOUYU_LOC = ['嚎！', '对不对', '我们', '这是膝', '你若要', '画给',
             '病人', '下针', '穿刺', '起针', '故意',
             # 2026-11-13 补：通谷穴.location 曾填成至阴的讲解、阳关穴填成
             # 「再来是阳关。我现在讲的这两个膝盖缝头…」，上述词表全部漏网。
             '再来是', '可以了', '我现在讲']
# location 以标点/助词开头 = 句子被从中间切断
TRUNC_HEAD = re.compile(r'^[的了，。、？）]')

errors = []    # 必须修
warnings = []  # 语义级，需讲稿对照
infos = []     # 统计信息


def check(data):
    pts = data['acupoints']

    # A1 结构一致性
    if data.get('total') != len(pts):
        errors.append(f"A1 total={data.get('total')} 与 acupoints 数量 {len(pts)} 不一致")

    for p in pts:
        name = p.get('name', '?')

        # A2 字段截断混入：时间戳小节标题出现在字段末尾 40 字内
        v = str(p.get('clinicalNotes', '') or '')
        m = TS_LINE.search(v)
        if m and len(v) - m.start() < 40:
            errors.append(f"A2 {name}.clinicalNotes 末尾混入下一章开头（截断残留）：{v[m.start():][:30]}")

        # A3 目录页码行
        for f in FIELDS:
            val = str(p.get(f, '') or '')
            if TOC_DOTS.search(val) and re.search(r'\d{1,3}\s*$', val):
                errors.append(f"A3 {name}.{f} 含目录页码行")

        # A4 clinicalNotes 截断嫌疑：够长且尾部停在半句（原生成期上限 2000 字，补全后无长度上限）
        v = str(p.get('clinicalNotes', '') or '')
        if len(v) >= 1000 and not END_PUNCT.search(v.strip()):
            warnings.append(f"A4 {name}.clinicalNotes 长度 {len(v)} 且尾部为半句，疑似生成期截断，需对照讲稿补全")

        # A7 要点归纳触发阈值（规范 §4.1）：原文 ≥2500 字且无【要点归纳】段 → 建议补归纳；
        # 已有【要点归纳】的，校验其位于文本末尾
        if len(v) >= 2500 and '【要点归纳】' not in v:
            warnings.append(f"A7 {name}.clinicalNotes 原文 {len(v)} 字 ≥2500 阈值，建议追加【要点归纳】段")
        if '【要点归纳】' in v and not re.search(r'【要点归纳】[\s\S]{0,600}$', v):
            warnings.append(f"A7 {name}.clinicalNotes 的【要点归纳】段不在文本末尾，结构异常")

        # A5 灸法张冠李戴启发式：moxibustion 里写「以中脘为主」但穴位不是中脘/上脘
        v = str(p.get('moxibustion', '') or '')
        if '以中脘为主' in v and name not in ('中脘穴', '上脘穴'):
            warnings.append(f"A5 {name}.moxibustion 含「以中脘为主」的梅花灸内容，疑似中脘段错位")

        # A6 针法书证张冠李戴启发式：同一书名断句内同时含「针六分」「留七呼」「得气即泻」，但穴位非巨阙。
        # 2026-11-14 修正：原实现按整串 needling 判断，导致石门误报——石门「留七呼+针六分」出自
        # 《素注》、「得气即泻」出自《甲乙》，分属两个书名，被拼成「巨阙特征」。现改为按句切分，
        # 只有三词落在同一句（同一书证）时才判错位。
        v = str(p.get('needling', '') or '')
        if name != '巨阙穴':
            for seg in re.split(r'[；;。]', v):
                if '针六分' in seg and '留七呼' in seg and '得气即泻' in seg:
                    warnings.append(f"A6 {name}.needling 同一书证内同时含「针六分/留七呼/得气即泻」（巨阙条特征），疑似错位")
                    break

        # A8 location 必须是定位（规范 §1）：不得填讲稿正文切片。
        # 历史教训：2026-11-11 查出 50 处 location 是讲稿口语段（大陵填「就是后跟，这是膝盖」），
        # 旧审计把它们归入「非标准取法·允许变体」而漏判，故单列。
        v = str(p.get('location', '') or '')
        hit = [w for w in KOUYU_LOC if w in v]
        if hit:
            warnings.append(f"A8 {name}.location 含讲稿口语「{'/'.join(hit)}」，疑似正文切片而非定位")
        elif TRUNC_HEAD.match(v):
            warnings.append(f"A8 {name}.location 以「{v[0]}」开头，疑似句中被截断")

        # I1 统计：空字段 / 无书证 / 无灸壮格式（info，供规范落地进度跟踪）
        for f in ['needling', 'moxibustion', 'contraindication', 'attribute']:
            if not str(p.get(f, '') or '').strip():
                infos.append(f"I1 {name}.{f} 为空")
        v = str(p.get('needling', '') or '')
        if v and not SHU_RE.search(v):
            infos.append(f"I2 {name}.needling 无书证（经外奇穴/手部穴位属正常）")
        v = str(p.get('moxibustion', '') or '')
        if v and not JIU_RE.search(v):
            infos.append(f"I3 {name}.moxibustion 无灸壮格式（艾条灸等属正常）")


def main():
    data = json.load(open(DATA, encoding='utf-8'))
    check(data)

    print(f'=== 穴位详情数据审计（{len(data["acupoints"])} 条） ===')
    print(f'error:   {len(errors)}')
    print(f'warning: {len(warnings)}')
    print(f'info:    {len(infos)}')
    for e in errors:
        print('  [E]', e)
    for w in warnings[:20]:
        print('  [W]', w)
    if len(warnings) > 20:
        print(f'  [W] …另有 {len(warnings)-20} 条')
    if '--json' in sys.argv:
        print(json.dumps({'errors': errors, 'warnings': warnings, 'infos': infos},
                         ensure_ascii=False, indent=2))
    sys.exit(1 if errors else 0)


if __name__ == '__main__':
    main()
