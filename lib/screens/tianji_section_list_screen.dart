import 'package:flutter/material.dart';

import '../data/tianji_section_repository.dart';
import 'markdown_doc_screen.dart';
import 'tianji_doc_list_screen.dart';

/// 某一篇天纪讲义的节目录（三层结构：讲义 → 篇 → 节 → 正文）。
///
/// 交互与《针灸大成》的章节目录一致：搜索框 + 序号 + 节名 + 一行预览 + 箭头。
/// 原先把 166 节混成一个扁平列表，篇与篇之间没有分界，找某一篇得靠搜索。
class TianjiSectionListScreen extends StatefulWidget {
  /// 篇名（如「天机道」），与 [TianjiDocListScreen.docs] 的第二项一致。
  final String book;

  const TianjiSectionListScreen({super.key, required this.book});

  @override
  State<TianjiSectionListScreen> createState() =>
      _TianjiSectionListScreenState();
}

class _TianjiSectionListScreenState extends State<TianjiSectionListScreen> {
  late final Future<List<TianjiSection>> _future =
      TianjiSectionRepository.sectionsOf(
    TianjiDocListScreen.docs,
    widget.book,
  );
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
        .where((s) => s.shortTitle.contains(q) || s.body.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.book)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                isDense: true,
                hintText: '搜索本节标题、正文…',
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
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          s.shortTitle,
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
                              title: s.shortTitle,
                              content: s.body,
                              // 用全名做进度键：不同篇可能有同名小节，
                              // 只按短标题存会互相覆盖
                              progressKey: s.title,
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
