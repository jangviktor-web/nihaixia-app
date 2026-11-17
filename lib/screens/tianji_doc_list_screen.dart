import 'package:flutter/material.dart';

import '../data/tianji_section_repository.dart';
import 'markdown_doc_screen.dart';

/// 倪师《天纪》讲义阅读入口。
///
/// 内容逐字摘自倪师天纪口述讲义（天机道 / 紫微斗数 / 相术 / 地脉道），
/// 属民俗文化参考，不构成任何医疗诊断或人生决策建议。
///
/// 2026-11-17 用户要求按「一节一卡」浏览（同针灸大成章节目录），
/// 不再整篇连续滚动：列表由各篇 Markdown 的 `##` / `####` 标题切出。
class TianjiDocListScreen extends StatefulWidget {
  const TianjiDocListScreen({super.key});

  /// (分组, 标题, 副标题, 资产路径)
  ///
  /// public 供测试遍历，保证「列表里的路径」与「真实资产」不会漂移。
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
  State<TianjiDocListScreen> createState() => _TianjiDocListScreenState();
}

class _TianjiDocListScreenState extends State<TianjiDocListScreen> {
  late final Future<List<TianjiSection>> _future =
      TianjiSectionRepository.parseAll(TianjiDocListScreen.docs);
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<TianjiSection> _filter(List<TianjiSection> all) {
    final q = _query.trim();
    if (q.isEmpty) return all;
    return all
        .where((s) => s.title.contains(q) || s.body.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('天纪讲义')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              '内容摘自倪师《天纪》口述讲义，属民俗文化参考，'
              '不构成任何医疗诊断或人生决策建议。',
              style: TextStyle(
                  fontSize: 12, height: 1.5, color: cs.onSurfaceVariant),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                isDense: true,
                hintText: '搜索章节名、正文…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<TianjiSection>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('加载失败：${snapshot.error}',
                        style: TextStyle(color: cs.error)),
                  );
                }
                final sections = _filter(snapshot.data ?? const []);
                if (sections.isEmpty) {
                  return const Center(child: Text('没有匹配的章节'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: sections.length,
                  itemBuilder: (context, i) {
                    final s = sections[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: cs.primaryContainer,
                          child: Text(
                            '${s.index + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          s.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          s.body.replaceAll('\n', ' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MarkdownDocScreen(
                              title: s.title,
                              content: s.body,
                              footer: '内容摘自倪师《天纪》口述讲义（${s.book}），'
                                  '属民俗文化参考，不构成医疗或人生决策建议。',
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
