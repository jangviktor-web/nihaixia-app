# 生成 lib/data/dream_data.dart（周公解梦 · 结构化梦境数据集 → Dart 常量表）。
# 数据源：D:/Users/jangviktor/Download/周公解梦大全 - 结构化JSON数据集（412条）.json
#          （用户整理 2026-09-06，412 条，字段已校验非空、id 唯一、吉凶值合法）。
# 用法：python tool/gen_dream_data.py [源JSON路径]
import json
import os
import sys

SRC_DEFAULT = (
    r'D:/Users/jangviktor/Download/周公解梦大全 - 结构化JSON数据集（412条）.json'
)
AUSPICIOUS_LEVELS = ['大吉', '吉', '平', '凶', '大凶']


def esc(s: str) -> str:
    """转义为合法 Dart 单引号字符串：反斜杠 → \\，单引号 → \'，换行 → \\n。"""
    return (s or '').replace('\\', '\\\\').replace("'", r"\'").replace('\n', r'\n')


def main() -> None:
    src = sys.argv[1] if len(sys.argv) > 1 else SRC_DEFAULT
    with open(src, encoding='utf-8') as f:
        data = json.load(f)

    meta = data['meta']
    dreams = list(data['dreams'])
    dreams.sort(key=lambda x: x['id'])  # 按 id 升序

    categories = meta['categories']
    disclaimer = meta['disclaimer']

    out = []
    out.append('// 由 tool/gen_dream_data.py 生成，请勿手工编辑。')
    out.append('// 数据源：《周公解梦大全》结构化数据集（412 条，用户整理 2026-09-06）。')
    out.append('// 属民俗文化参考，解读为潜意识映射，非吉凶指令。')
    out.append('')
    out.append('/// 单条梦境条目。')
    out.append('class DreamEntry {')
    out.append('  final String id;')
    out.append('  final String category;')
    out.append('  final String subcategory;')
    out.append('  final String keyword;')
    out.append('  final String dream;')
    out.append('  final String interpretation;')
    out.append('  final String auspicious;')
    out.append('  final String source;')
    out.append(
        '  const DreamEntry({required this.id, required this.category, '
        'required this.subcategory, required this.keyword, required this.dream, '
        'required this.interpretation, required this.auspicious, required this.source});'
    )
    out.append('}')
    out.append('')
    out.append('/// 梦境分类（取自 meta.categories）。')
    out.append('class DreamCategory {')
    out.append('  final String id;')
    out.append('  final String name;')
    out.append('  final int count;')
    out.append('  const DreamCategory({required this.id, required this.name, required this.count});')
    out.append('}')
    out.append('')
    out.append('const List<DreamEntry> kDreamEntries = [')
    for x in dreams:
        out.append('  DreamEntry(')
        out.append("    id: '{}',".format(esc(x['id'])))
        out.append("    category: '{}',".format(esc(x['category'])))
        out.append("    subcategory: '{}',".format(esc(x['subcategory'])))
        out.append("    keyword: '{}',".format(esc(x['keyword'])))
        out.append("    dream: '{}',".format(esc(x['dream'])))
        out.append("    interpretation: '{}',".format(esc(x['interpretation'])))
        out.append("    auspicious: '{}',".format(esc(x['auspicious'])))
        out.append("    source: '{}',".format(esc(x['source'])))
        out.append('  ),')
    out.append('];')
    out.append('')
    out.append('const List<DreamCategory> kDreamCategories = [')
    for c in categories:
        out.append("  DreamCategory(id: '{}', name: '{}', count: {}),".format(
            esc(c['id']), esc(c['name']), int(c['count'])))
    out.append('];')
    out.append('')
    out.append("const String kDreamDisclaimer = '{}';".format(esc(disclaimer)))
    out.append('')
    out.append('/// 梦境检索：query 为空返回全部；否则按 keyword/dream/interpretation（不区分大小写）匹配。')
    out.append('/// 若 category 非 null 再叠加 category 相等过滤。返回新列表，不改原列表。')
    out.append('List<DreamEntry> searchDreams(String query, [String? category]) {')
    out.append('  final q = query.trim().toLowerCase();')
    out.append('  final result = kDreamEntries.where((e) {')
    out.append('    if (category != null && e.category != category) return false;')
    out.append('    if (q.isEmpty) return true;')
    out.append(
        '    final hay = (e.keyword + e.dream + e.interpretation).toLowerCase();'
    )
    out.append('    return hay.contains(q);')
    out.append('  }).toList();')
    out.append('  return result;')
    out.append('}')
    out.append('')

    out_path = os.path.join(os.path.dirname(__file__), '..',
                            'lib', 'data', 'dream_data.dart')
    with open(out_path, 'w', encoding='utf-8', newline='\n') as f:
        f.write('\n'.join(out))
    print(f'written {os.path.normpath(out_path)}')
    print(f"dreams={len(dreams)} categories={len(categories)}")


if __name__ == '__main__':
    main()
