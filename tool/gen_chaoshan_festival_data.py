# 生成 lib/data/chaoshan_festival_data.dart（潮汕神仙节日 → 农历日期常量表）。
# 数据源：D:/Users/jangviktor/Download/潮汕神仙节日.json（用户整理 2026-09-05）。
# 用法：python tool/gen_chaoshan_festival_data.py [源JSON路径]
import json
import os
import sys

CN_MONTH = {
    '正月': 1, '二月': 2, '三月': 3, '四月': 4, '五月': 5, '六月': 6,
    '七月': 7, '八月': 8, '九月': 9, '十月': 10, '十一月': 11, '十二月': 12,
}


def day_num(s: str) -> int:
    if s == '三十':
        return 30
    if s.startswith('初'):
        return '一二三四五六七八九十'.index(s[1]) + 1
    if s.startswith('十') and len(s) > 1:
        return 10 + '一二三四五六七八九'.index(s[1]) + 1
    if s.startswith('二十'):
        tail = s[2:]
        return 20 + ('一二三四五六七八九'.index(tail) + 1 if tail else 0)
    if s.startswith('廿'):
        tail = s[1:]
        return 20 + ('一二三四五六七八九'.index(tail) + 1 if tail else 0)
    raise ValueError(s)


def region_tag(region: str) -> str:
    """地域标注：普遍通行不加注，地方性日期加注地名。"""
    region = (region or '').strip()
    if not region or region.startswith('普遍'):
        return ''
    return region.split('（')[0]


def main() -> None:
    src = sys.argv[1] if len(sys.argv) > 1 else (
        r'D:/Users/jangviktor/Download/潮汕神仙节日.json'
    )
    with open(src, encoding='utf-8') as f:
        data = json.load(f)

    table: dict[str, list[str]] = {}
    skipped = []

    def add(month: int, day: int, text: str) -> None:
        if not text:
            return
        key = f'{month:02d}{day:02d}'
        lst = table.setdefault(key, [])
        if text not in lst:
            lst.append(text)

    def days_of(spec: str) -> list[int] | None:
        """解析日期写法：初一 / 廿五 / 廿三/廿四 / 十四至十五。
        「中至后」「中至尾」等模糊写法返回 None（跳过）。"""
        spec = spec.strip()
        if '至' in spec:
            a, b = spec.split('至')
            if a in ('中',) or b in ('后', '尾', '中'):
                return None
            return list(range(day_num(a), day_num(b) + 1))
        if '/' in spec:
            return [day_num(x) for x in spec.split('/')]
        return [day_num(spec)]

    # 按月份神诞
    n_fixed = 0
    for month_name, entries in data['按月份神诞'].items():
        month = CN_MONTH[month_name]
        for e in entries:
            days = days_of(e['农历日期'])
            if days is None:
                skipped.append(f"{month_name}{e['农历日期']}:{e['神明/节日']}")
                continue
            name = e['神明/节日'].strip()
            tag = region_tag(e.get('地域', ''))
            text = f'{name}·{tag}' if tag else name
            for day in days:
                add(month, day, text)
                n_fixed += 1

    # 每月固定拜神日：初一/十五 拜伯公，初二/十六 拜地主爷
    n_monthly = 0
    for month in range(1, 13):
        for day in (1, 15):
            add(month, day, '拜伯公（土地公）')
            n_monthly += 1
        for day in (2, 16):
            add(month, day, '拜地主爷（地基主）')
            n_monthly += 1

    out = []
    out.append('// 由 tool/gen_chaoshan_festival_data.py 生成，请勿手工编辑。')
    out.append('// 数据源：《潮汕地区神仙节日与神诞一览》（用户整理 2026-09-05，覆盖')
    out.append('//       汕头/潮州/揭阳/汕尾潮汕文化圈）。收录按月份神诞 63 条（含日期')
    out.append('//       区间展开）与每月固定拜神日（初一十五拜伯公、初二十六拜地主爷）。')
    out.append('//       「中至后/中至尾」等择日不定的模糊日期不收录。')
    out.append('// 键：农历月日各两位；地方性条目带「·地名」后缀；闰月不过节。')
    out.append('const Map<String, List<String>> kChaoshanFestivals = {')
    total = 0
    for key in sorted(table):
        entries = table[key]
        total += len(entries)
        out.append("  '{}': [".format(key))
        for t in entries:
            out.append("    '{}',".format(t))
        out.append('  ],')
    out.append('};')
    out.append('')

    out_path = os.path.join(os.path.dirname(__file__), '..',
                            'lib', 'data', 'chaoshan_festival_data.dart')
    with open(out_path, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(out))
    print(f'written {os.path.normpath(out_path)}')
    print(f'dates={len(table)} fixed={n_fixed} monthly={n_monthly} skipped={skipped}')


if __name__ == '__main__':
    main()
