import 'package:flutter/material.dart';
import 'ziwei_cases_list_screen.dart';
import '../theme/app_colors.dart';

/// 紫微斗数参考：倪师《天纪·天机道》十四主星 / 十二宫位 / 论命理。
/// 内容逐字摘自 nihaixia skill 知识库 modules/09_zhenjiu_bencao.md「天纪·天机道」，
/// 仅作民俗文化参考，不构成任何医疗诊断或健康建议。
class ZiweiReferenceScreen extends StatelessWidget {
  const ZiweiReferenceScreen({super.key});

  static const List<(String, String, String)> _majors = [
    ('紫微', '土', '帝座，主尊贵、权威'),
    ('天机', '木', '智慧星，主聪明、善变'),
    ('太阳', '火', '中天主星，主光明、博爱'),
    ('武曲', '金', '财星，主刚毅、果断'),
    ('天同', '水', '福星，主温和、享受'),
    ('廉贞', '火', '次桃花星，主多情、是非'),
    ('天府', '土', '财库星，主稳重、保守'),
    ('太阴', '水', '田宅主，主阴柔、内敛'),
    ('贪狼', '木', '桃花星，主欲望、才艺'),
    ('巨门', '水', '暗星，主口舌、是非'),
    ('天相', '水', '印星，主辅佐、公正'),
    ('天梁', '土', '荫星，主化解、逢凶化吉'),
    ('七杀', '金', '将星，主冲劲、变革'),
    ('破军', '水', '耗星，主破坏、创新'),
  ];

  static const List<(String, String)> _palaces = [
    ('命宫', '先天格局、性格'),
    ('兄弟宫', '兄弟姐妹关系'),
    ('夫妻宫', '婚姻感情'),
    ('子女宫', '子女缘分'),
    ('财帛宫', '财运理财'),
    ('疾厄宫', '健康疾病'),
    ('迁移宫', '外出际遇'),
    ('交友宫', '人际关系'),
    ('官禄宫', '事业功名'),
    ('田宅宫', '不动产'),
    ('福德宫', '精神生活'),
    ('父母宫', '父母关系'),
  ];

  /// 宫位名 → 主管（供盘面点按宫格时复用，单一数据源）
  static const Map<String, String> palaceMeanings = {
    '命宫': '先天格局、性格',
    '兄弟宫': '兄弟姐妹关系',
    '夫妻宫': '婚姻感情',
    '子女宫': '子女缘分',
    '财帛宫': '财运理财',
    '疾厄宫': '健康疾病',
    '迁移宫': '外出际遇',
    '交友宫': '人际关系',
    '官禄宫': '事业功名',
    '田宅宫': '不动产',
    '福德宫': '精神生活',
    '父母宫': '父母关系',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('紫微斗数参考')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 案例库入口
          Card(
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ZiweiCasesListScreen()),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      size: 28,
                      color: cs.primary,
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '倪师案例与十二宫详解',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '28 例案例 + 紫微十二宫详解 + 总论',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 倪师论命理
          Card(
            color: cs.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '倪师《天纪·天机道》',
                    style: TextStyle(
                      color: cs.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '天机道以紫微斗数为核心，分析人的命运格局。'
                    '倪海厦认为，命理可以让人了解自己的天赋和局限，从而趋吉避凶。',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '「人生于天地之间，秉天地之气而有形，受天地之养以为生。'
                    '未有能离于天地之间而生者。天纪一书，以易经为轴，'
                    '以天文、地理及人间道为辅；发前人之所未发，言前人之所未言。'
                    '复道尽天、人、地三才之关系。」',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.7,
                      fontStyle: FontStyle.italic,
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 十四主星
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '十四主星详解',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final (name, wuxing, trait) in _majors) ...[
                    _RowTile(
                      leading: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      tag: _wuxingTag(context, wuxing, cs),
                      text: trait,
                    ),
                    if (name != _majors.last.$1) const Divider(height: 12),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 十二宫位
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '十二宫位',
                    style: TextStyle(
                      color: cs.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final (name, meaning) in _palaces) ...[
                    _RowTile(
                      leading: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      tag: null,
                      text: '主管：$meaning',
                    ),
                    if (name != _palaces.last.$1) const Divider(height: 12),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '内容摘自倪海厦《天纪》天机道（75页教材）· 民俗文化参考',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: cs.outline),
          ),
        ],
      ),
    );
  }

  Widget? _wuxingTag(BuildContext context, String wuxing, ColorScheme cs) {
    Color? color;
    switch (wuxing) {
      case '木':
        color = context.colors.success;
      case '火':
        color = context.colors.danger;
      case '土':
        color = context.colors.warning;
      case '金':
        color = context.colors.warning;
      case '水':
        color = context.colors.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: (color ?? cs.primary).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        wuxing,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color ?? cs.primary,
        ),
      ),
    );
  }
}

class _RowTile extends StatelessWidget {
  final Widget leading;
  final Widget? tag;
  final String text;

  const _RowTile({required this.leading, this.tag, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 48, child: leading),
          if (tag != null) ...[tag!, const SizedBox(width: 8)],
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
