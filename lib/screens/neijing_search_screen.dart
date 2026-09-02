import 'package:flutter/material.dart';
import '../widgets/state_view.dart';
import 'package:flutter/services.dart';

import '../data/neijing_lecture_data.dart';
import 'markdown_doc_screen.dart';

/// 《人纪·黄帝内经》全文搜索：关键词 → 命中篇目 + 上下文片段。
/// 懒加载缓存 73 篇文本（约 0.8MB），线性扫描匹配。
class NeijingSearchScreen extends StatefulWidget {
  const NeijingSearchScreen({super.key});

  @override
  State<NeijingSearchScreen> createState() => _NeijingSearchScreenState();
}

class _NeijingSearchScreenState extends State<NeijingSearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  Map<String, String> _cache = {}; // asset -> 全文
  List<NeiJingLecture>? _docs;
  bool _loading = false;
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _ensureLoaded() async {
    if (_docs != null) return;
    setState(() => _loading = true);
    final docs = <NeiJingLecture>[];
    final cache = <String, String>{};
    for (final l in kNeiJingLectures) {
      cache[l.asset] = await rootBundle.loadString(l.asset);
      docs.add(l);
    }
    if (!mounted) return;
    setState(() {
      _docs = docs;
      _cache = cache;
      _loading = false;
    });
  }

  void _onChanged(String v) {
    setState(() => _query = v.trim());
  }

  List<({NeiJingLecture doc, int hits, String snippet})> _results() {
    final q = _query;
    if (q.isEmpty) return const [];
    final out = <({NeiJingLecture doc, int hits, String snippet})>[];
    for (final l in kNeiJingLectures) {
      final text = _cache[l.asset];
      if (text == null) continue;
      final idx = text.indexOf(q);
      if (idx < 0) continue;
      // 命中计数
      var count = 0;
      var from = 0;
      while (true) {
        final i = text.indexOf(q, from);
        if (i < 0) break;
        count++;
        from = i + q.length;
      }
      // 上下文片段（首处命中前后各 24 字）
      final start = (idx - 24).clamp(0, text.length);
      final end = (idx + q.length + 24).clamp(0, text.length);
      final snippet = (start > 0 ? '…' : '') +
          text.substring(start, end).replaceAll('\n', ' ') +
          (end < text.length ? '…' : '');
      out.add((doc: l, hits: count, snippet: snippet));
    }
    out.sort((a, b) => b.hits.compareTo(a.hits));
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final results = _results();
    return Scaffold(
      appBar: AppBar(
        title: const Text('内经 · 全文搜索'),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                _onChanged('');
              },
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _ctrl,
              autofocus: true,
              onChanged: _onChanged,
              onTap: _ensureLoaded,
              decoration: InputDecoration(
                hintText: '输入关键词，如：脉、心包、伤寒、阴阳…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: StateView.loading(),
              ),
            )
          else if (_query.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.manage_search, size: 40, color: cs.outline),
                  const SizedBox(height: 8),
                  Text(
                    '已收录《素问》72 篇 + 前言（倪师讲稿）\n输入关键词检索全文',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: cs.outline),
                  ),
                ],
              ),
            )
          else if (results.isEmpty)
            StateView.empty(title: '未找到「$_query」相关篇章')
          else
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: results.length,
                itemBuilder: (context, i) {
                  final r = results[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    elevation: 1,
                    child: ListTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.doc.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${r.hits} 处',
                              style: TextStyle(
                                fontSize: 10,
                                color: cs.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          r.snippet,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MarkdownDocScreen(
                              title: r.doc.name,
                              asset: r.doc.asset,
                              footer: '出处：《人纪·黄帝内经》倪师讲稿 · 传统文化参考',
                              linkFormulas: true,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
