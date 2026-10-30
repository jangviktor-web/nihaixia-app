import 'package:flutter/material.dart';

import '../data/guji_data.dart';
import 'markdown_doc_screen.dart';

/// 古籍原文书库：书 → 章节目录（可搜索）→ 章节阅读。
///
/// 定位与「倪海厦讲稿」并列：讲稿是倪师的逐条讲解，这里是经典原文本身。
/// 只收 App 内原本没有的书（灵枢 / 针灸大成），避免内容重复。
class GujiLibraryScreen extends StatelessWidget {
  const GujiLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('古籍原文')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_stories_outlined,
                    size: 18, color: cs.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '收录《灵枢》《针灸大成》原文。与「倪师讲稿」并列：讲稿是讲解，这里是经典本身。内容供学习参考，非医疗建议。',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          for (final book in kGujiBooks)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.menu_book,
                      size: 20, color: cs.onPrimaryContainer),
                ),
                title: Text(
                  book.title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${book.author} · ${book.chapterCount} 章',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GujiBookScreen(book: book),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 单本书的章节目录，支持按章名与正文搜索。
class GujiBookScreen extends StatefulWidget {
  final GujiBook book;

  const GujiBookScreen({super.key, required this.book});

  @override
  State<GujiBookScreen> createState() => _GujiBookScreenState();
}

class _GujiBookScreenState extends State<GujiBookScreen> {
  late Future<List<GujiChapter>> _future;
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = GujiRepository.chaptersOf(widget.book);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<GujiChapter> _filter(List<GujiChapter> all) {
    final q = _query.trim();
    if (q.isEmpty) return all;
    return all
        .where((c) => c.title.contains(q) || c.body.contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.book.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                isDense: true,
                hintText: '搜索本章书名、正文…',
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
            child: FutureBuilder<List<GujiChapter>>(
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
                final chapters = _filter(snapshot.data ?? const []);
                if (chapters.isEmpty) {
                  return const Center(child: Text('没有匹配的章节'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                  itemCount: chapters.length,
                  itemBuilder: (context, i) {
                    final c = chapters[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: cs.primaryContainer,
                          child: Text(
                            '${c.index + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ),
                        title: Text(
                          c.title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          c.body.replaceAll('\n', ' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                        ),
                        trailing:
                            const Icon(Icons.chevron_right, size: 18),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GujiChapterScreen(
                              book: widget.book,
                              chapter: c,
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

/// 单章阅读页：正文以 Markdown 渲染，方剂 / 药材名仍可点击跳转。
class GujiChapterScreen extends StatelessWidget {
  final GujiBook book;
  final GujiChapter chapter;

  const GujiChapterScreen({
    super.key,
    required this.book,
    required this.chapter,
  });

  @override
  Widget build(BuildContext context) {
    // 原文按行分段，Markdown 需要空行隔开段落
    final content = chapter.body
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .join('\n\n');
    return MarkdownDocScreen(
      title: chapter.title,
      content: content,
      linkFormulas: true,
      footer: '原文出自《${book.title}》（公版古籍），仅供学习参考，非医疗建议。',
    );
  }
}
