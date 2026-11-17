import 'package:flutter/material.dart';

import 'tianji_section_list_screen.dart';

/// 倪师《天纪》讲义阅读入口。
///
/// 三层结构：**讲义 → 篇 → 节 → 正文**。
/// 点某篇进入该篇的节目录（[TianjiSectionListScreen]），再点某节看正文。
///
/// 2026-11-17 用户要求：先把 9 篇分开列，点进去才是篇内的小节。
/// 此前把 166 节混成一个扁平列表，篇与篇之间没有分界。
///
/// 内容逐字摘自倪师天纪口述讲义（天机道 / 紫微斗数 / 相术 / 地脉道），
/// 属民俗文化参考，不构成任何医疗诊断或人生决策建议。
class TianjiDocListScreen extends StatelessWidget {
  const TianjiDocListScreen({super.key});

  /// (分组, 篇名, 副标题, 资产路径)
  ///
  /// public 供测试遍历，保证「列表里的路径」与「真实资产」不会漂移；
  /// 同时作为 [TianjiSectionRepository] 的唯一篇清单来源。
  static const List<(String, String, String, String)> docs = [
    ('天纪总纲', '天机道', '天纪与真理 / 形与神 / 什么是「易」/ 命相同参',
        'assets/tianji/1_天机道.md'),
    ('紫微斗数', '十二宫详解', '兄弟父母 / 夫妻 / 疾厄 / 仆役 / 田宅宫',
        'assets/tianji/2_紫微斗数十二宫.md'),
    ('紫微斗数', '星曜详解', '四化星（科权禄忌）/ 北斗星系 / 南斗星系',
        'assets/tianji/3_星曜详解.md'),
    ('相术 · 命相同参', '手相', '掌形与掌纹',
        'assets/tianji/7_手相.md'),
    ('相术 · 命相同参', '相术总结', '面相归纳',
        'assets/tianji/12_相术总结.md'),
    ('相术 · 命相同参', '六神占断论', '面部六神 / 六神之形',
        'assets/tianji/9_六神占断论.md'),
    ('地脉道 · 堪舆', '堪舆风水', '地理基础',
        'assets/tianji/8_堪舆风水.md'),
    ('地脉道 · 堪舆', '风水布局', '阳宅布局',
        'assets/tianji/8_风水布局.md'),
    ('地脉道 · 堪舆', '八煞黄泉', '水法八煞',
        'assets/tianji/8_八煞黄泉.md'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final children = <Widget>[];
    String? lastGroup;
    for (final (group, title, subtitle, _) in docs) {
      if (group != lastGroup) {
        lastGroup = group;
        children.add(Padding(
          padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
          child: Text(
            group,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
        ));
      }
      children.add(Card(
        elevation: 0,
        color: cs.surfaceContainerHighest,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          title: Text(title),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
          trailing: const Icon(Icons.chevron_right, size: 18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TianjiSectionListScreen(book: title),
            ),
          ),
        ),
      ));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('天纪讲义')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            '内容摘自倪师《天纪》口述讲义，属民俗文化参考，'
            '不构成任何医疗诊断或人生决策建议。',
            style:
                TextStyle(fontSize: 12, height: 1.5, color: cs.onSurfaceVariant),
          ),
          ...children,
        ],
      ),
    );
  }
}
