# 生成 lib/data/yuxiaji_deity_data.dart（玉匣记神仙节日 → 农历日期常量表）。
# 数据源：D:/Users/jangviktor/Download/玉匣记神仙节日.json（最终版）.json
# 维基文库《玉匣记》导出本（东晋·许真人许逊），整理日期 2026-09-05。
# 用法：python tool/gen_yuxiaji_data.py [源JSON路径]
import json
import os
import re
import sys

CN_MONTH = {
    '正': 1, '二': 2, '三': 3, '四': 4, '五': 5, '六': 6,
    '七': 7, '八': 8, '九': 9, '十': 10, '冬': 11, '腊': 12,
    '十一': 11, '十二': 12,
}
DAY_RE = re.compile(
    r'^(十一|十二|正|[二三四五六七八九十冬腊])月'
    r'(初[一二三四五六七八九十]|十[一二三四五六七八九]|二十[一二三四五六七八九]?'
    r'|廿[一二三四五六七八九]?|三十)$'
)


def day_num(s: str) -> int:
    if s == '三十':
        return 30
    if s.startswith('初'):
        return '一二三四五六七八九十'.index(s[1]) + 1
    if s.startswith('十'):
        return 10 + '一二三四五六七八九'.index(s[1]) + 1
    if s.startswith('二十'):
        tail = s[2:]
        return 20 + ('一二三四五六七八九'.index(tail) + 1 if tail else 0)
    if s.startswith('廿'):
        tail = s[1:]
        return 20 + ('一二三四五六七八九'.index(tail) + 1 if tail else 0)
    raise ValueError(s)


def norm_type(t: str) -> str:
    """类型归一：复合类型（圣诞/得道 等）取主类型。"""
    t = (t or '圣诞').strip()
    return t.split('/')[0] if '/' in t else t


def display(e: dict) -> str:
    fest = (e.get('节日') or '').strip()
    deity = (e.get('神祇') or '').strip()
    typ = norm_type(e.get('类型', ''))
    if deity and len(deity) > 8:
        deity = deity.split('、')[0] + '等'
    if fest and deity:
        # 神祇与节日同源（如「诸佛下界探访善恶」+「诸佛」）时不重复拼接
        if deity in fest:
            return f'{fest}（{typ}）' if typ not in fest else fest
        return f'{fest}·{deity}{typ}'
    if fest:
        return f'{fest}（{typ}）' if typ != '圣诞' else fest
    if deity:
        return f'{deity}{typ}'
    return ''


def main() -> None:
    src = sys.argv[1] if len(sys.argv) > 1 else (
        r'D:/Users/jangviktor/Download/玉匣记神仙节日.json（最终版）.json'
    )
    with open(src, encoding='utf-8') as f:
        data = json.load(f)

    table: dict[str, list[str]] = {}
    skipped = []

    def add(lunar_month: int, lunar_day: int, text: str) -> None:
        if not text:
            return
        key = f'{lunar_month:02d}{lunar_day:02d}'
        lst = table.setdefault(key, [])
        if text not in lst:  # 同日去重
            lst.append(text)

    # 一、三元五腊圣诞日期（含五腊/三元/观音，权威明细）
    for _month, entries in data['一、三元五腊圣诞日期'].items():
        for e in entries:
            d = e['日期']
            m = DAY_RE.match(d)
            if m:
                add(CN_MONTH[m.group(1)], day_num(m.group(2)), display(e))
            elif '至' in d:
                # 范围斋期（如 正月初八至十五）按天展开（终点无「月」字）
                a, b = d.split('至')
                ma, da = DAY_RE.match(a).groups()
                db = b.split('月')[-1]
                text = display(e)
                for day in range(day_num(da), day_num(db) + 1):
                    add(CN_MONTH[ma], day, text)
            else:
                skipped.append(d)

    # 二、十殿阎君圣诞（与第一章零重叠，2026-09-05 已核）
    for e in data['二、十殿阎君圣诞日期']:
        m = DAY_RE.match(e['日期'])
        assert m, e['日期']
        add(CN_MONTH[m.group(1)], day_num(m.group(2)),
            f"{e['殿号']}{e['阎君']}{norm_type(e['类型'])}")

    out_lines = []
    out_lines.append('// 由 tool/gen_yuxiaji_data.py 生成，请勿手工编辑。')
    out_lines.append('// 数据源：《玉匣记》（东晋·许真人许逊，维基文库 2026-09-04 导出本，')
    out_lines.append('//       用户整理 2026-09-05）。收录固定农历日期的神仙节日：')
    out_lines.append('//       三元五腊圣诞 114 条（含范围斋期按天展开）、十殿阎君圣诞 10 条。')
    out_lines.append('//       五、六、八、九章为按月循环之斋日/龙神会/九耀下界，非固定节日，不收录。')
    out_lines.append('// 键：农历月日各两位（如 0101 = 正月初一）；闰月不过节（与 FestivalEngine 同口径）。')
    out_lines.append('const Map<String, List<String>> kYuxiajiDeityFestivals = {')
    days = 0
    for key in sorted(table):
        entries = table[key]
        days += len(entries)
        out_lines.append("  '{}': [".format(key))
        for t in entries:
            out_lines.append("    '{}',".format(t))
        out_lines.append('  ],')
    out_lines.append('};')
    out_lines.append('')

    out_path = os.path.join(os.path.dirname(__file__), '..',
                            'lib', 'data', 'yuxiaji_deity_data.dart')
    with open(out_path, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(out_lines))

    print(f'written {os.path.normpath(out_path)}')
    print(f'dates={len(table)} entries={days} skipped={skipped}')


if __name__ == '__main__':
    main()
