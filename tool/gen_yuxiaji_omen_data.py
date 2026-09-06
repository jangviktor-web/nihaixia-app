# 生成 lib/data/yuxiaji_omen_data.dart（玉匣记·身体兆占 → Dart 常量表）。
# 数据源：D:/Users/jangviktor/Download/玉匣记_身体兆占.json（用户整理 2026-09-05，
# 玉匣记 杂占篇，维基文库本，讹字已校）。
# 用法：python tool/gen_yuxiaji_omen_data.py [源JSON路径]
import json
import os
import sys

HOURS = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥']


def esc(s: str) -> str:
    return (s or '').replace('\\', '\\\\').replace("'", r"\'").replace('\n', r'\n')


def main() -> None:
    src = sys.argv[1] if len(sys.argv) > 1 else (
        r'D:/Users/jangviktor/Download/玉匣记_身体兆占.json'
    )
    with open(src, encoding='utf-8') as f:
        data = json.load(f)

    out = []
    out.append('// 由 tool/gen_yuxiaji_omen_data.py 生成，请勿手工编辑。')
    out.append('// 数据源：《玉匣记》杂占篇·身体兆占与物象兆占（东晋·许真人许逊，')
    out.append('//       维基文库本，讹字已由整理者校正，校正标注保留在占断文字中）。')
    out.append('// 时辰索引：0=子 1=丑 … 11=亥（duanByHour 与之一一对应）。')
    out.append('')
    out.append('/// 十二时辰身体兆占法：某一体征在某时辰出现的占断。')
    out.append('class ShiChenOmen {')
    out.append('  final String name; // 占法名，如「占面热法」')
    out.append('  final String target; // 占断对象描述')
    out.append('  final List<String> duanByHour; // 12 条，索引 0=子时 … 11=亥时')
    out.append('  const ShiChenOmen(this.name, this.target, this.duanByHour);')
    out.append('}')
    out.append('')
    out.append('/// 特殊兆占法（非按十二时辰，按方向/形态占断）。')
    out.append('class OmenSpecial {')
    out.append('  final String name;')
    out.append('  final String target;')
    out.append('  final String body; // 已排版的方法论/步骤/经文等全文')
    out.append('  const OmenSpecial(this.name, this.target, this.body);')
    out.append('}')
    out.append('')
    out.append('const List<ShiChenOmen> kYuXiaJiShiChenOmens = [')
    for e in data['十二时辰占法']:
        def duan_of(x: dict) -> str:
            if '占断' in x:
                return x['占断']
            # 分左右占法（眼跳/耳鸣）：合并为两行
            pairs = [f'{k}：{x[k]}' for k in ('左眼', '右眼', '左耳', '右耳') if k in x]
            return '；'.join(pairs)

        by_hour = {x['时辰'][0]: duan_of(x) for x in e['时辰占断']}
        assert set(by_hour) == set(HOURS), e['名称']
        duan = [by_hour[h] for h in HOURS]
        out.append("  ShiChenOmen('{}', '{}', [".format(esc(e['名称']), esc(e['占断对象'])))
        for d in duan:
            out.append("    '{}',".format(esc(d)))
        out.append('  ]),')
    out.append('];')
    out.append('')
    out.append('const List<OmenSpecial> kYuXiaJiSpecialOmens = [')
    for e in data['特殊占法']:
        parts = []
        title_map = {
            '方法论': '方法论', '占法步骤': '占法步骤', '经文': '经文',
            '禳解咒': '禳解咒', '注意': '注意', '总则': '总则',
        }
        for k, v in e.items():
            if k in ('名称', '占断对象'):
                continue
            if k == '形态占断':
                lines = '；\n'.join(
                    f"【{x['形态']}】{x['占断']}" for x in v
                )
                parts.append(f"【形态占断】\n{lines}")
            elif k == '占法步骤':
                steps = ' → '.join(v)
                parts.append(f"【占法步骤】{steps}")
            elif k in title_map:
                parts.append(f"【{title_map[k]}】{v}")
        body = '\n\n'.join(parts)
        out.append("  OmenSpecial('{}', '{}',".format(esc(e['名称']), esc(e['占断对象'])))
        out.append("      '{}'),".format(esc(body)))
    out.append('];')
    out.append('')

    out_path = os.path.join(os.path.dirname(__file__), '..',
                            'lib', 'data', 'yuxiaji_omen_data.dart')
    with open(out_path, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(out))
    print(f'written {os.path.normpath(out_path)}')
    print(f"shichen={len(data['十二时辰占法'])} special={len(data['特殊占法'])}")


if __name__ == '__main__':
    main()
