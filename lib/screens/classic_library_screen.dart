import 'package:flutter/material.dart';

import '../data/zhenjiu_lecture_index.dart';
import '../data/classic_lecture_data.dart';
import 'markdown_doc_screen.dart';

/// 通用「经典讲稿阅读库」屏：按条目列篇目，点按进入 [MarkdownDocScreen] 渲染原文。
///
/// 正文里出现的已知方剂名 / 药材名由 [MarkdownDocScreen] 自动包成链接，
/// 点击直跳方剂 / 药材详情 —— 内经、伤寒论、金匮要略三个阅读库共用此实现。
///
/// 顶部自带库内搜索（按篇名过滤）；正文全文检索由全局搜索页的「经典」分组承担
/// （索引见 `tool/build_classic_search_index.py`）。
class ClassicLibraryScreen extends StatefulWidget {
  final String title;
  final List<LectureIndex> lectures;
  final String? infoText;
  final String? footer;

  /// 左侧序号气泡文字，默认用数字化 seq。
  final String Function(int seq)? seqLabel;

  /// 副标题，默认不显示。
  final String Function(int seq)? seqSubtitle;

  const ClassicLibraryScreen({
    super.key,
    required this.title,
    required this.lectures,
    this.infoText,
    this.footer,
    this.seqLabel,
    this.seqSubtitle,
  });

  @override
  State<ClassicLibraryScreen> createState() => _ClassicLibraryScreenState();
}

class _ClassicLibraryScreenState extends State<ClassicLibraryScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // 预热讲稿↔穴位索引：正文自动链接的排除名单取 json 单一来源；
    // 详情页「讲义讲解」也依赖它。失败静默降级（硬编码名单兜底）。
    ZhenJiuLectureIndex.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<LectureIndex> get _filtered {
    final q = _query.trim();
    if (q.isEmpty) return widget.lectures;
    return widget.lectures.where((l) => l.name.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final lectures = _filtered;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                isDense: true,
                hintText: '搜索篇目…',
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
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                if (widget.infoText != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: cs.tertiaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.menu_book_outlined,
                            size: 18, color: cs.onTertiaryContainer),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.infoText!,
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onTertiaryContainer,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (lectures.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        '没有匹配的篇目',
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
                for (final l in lectures)
                  Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    elevation: 1,
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: cs.primaryContainer,
                        child: Text(
                          widget.seqLabel?.call(l.seq) ?? '${l.seq}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: cs.onPrimaryContainer,
                          ),
                        ),
                      ),
                      title: Text(
                        l.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: widget.seqSubtitle == null
                          ? null
                          : Text(
                              widget.seqSubtitle!(l.seq),
                              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                            ),
                      trailing: const Icon(Icons.chevron_right, size: 18),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MarkdownDocScreen(
                              title: l.name,
                              asset: l.asset,
                              footer: widget.footer,
                              linkFormulas: true,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
