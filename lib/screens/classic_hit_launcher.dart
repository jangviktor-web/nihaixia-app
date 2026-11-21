import 'package:flutter/material.dart';

import '../data/guji_data.dart';
import '../services/classic_search_service.dart';
import 'guji_library_screen.dart';
import 'markdown_doc_screen.dart';

/// 打开一条经典检索命中——「答案可溯源」的统一入口。
///
/// 三类命中的落地页各不相同：
/// - 讲稿（[ClassicHit.asset] 非空）→ 该篇 markdown 原文；
/// - 古籍原文（[ClassicHit.bookId] 非空）→ 对应章节阅读页；
/// - 医案文章体（`source == 'yianwen'`）→ 段落全文弹层
///   （源语料不打包进 App，完整正文只存在于索引里）。
///
/// 抽成公共函数的原因：搜索页与「问倪师 AI」的回答页都要提供回查，
/// 两处各写一份必然漂移（原先 AI 页只支持 asset，古籍命中点了没反应）。
/// 新增检索库时只改这里一处。
Future<void> openClassicHit(BuildContext context, ClassicHit hit) async {
  if (hit.source == 'yianwen') {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hit.title),
        content: SingleChildScrollView(child: Text(hit.snippet)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
    return;
  }

  if (hit.source == 'guji' || hit.bookId != null) {
    final book = kGujiBooks.firstWhere(
      (b) => b.id == hit.bookId,
      orElse: () => kGujiBooks.first,
    );
    final chapters = await GujiRepository.chaptersOf(book);
    final index = hit.chapterIndex ?? -1;
    if (!context.mounted) return;
    if (index < 0 || index >= chapters.length) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GujiChapterScreen(book: book, chapter: chapters[index]),
      ),
    );
    return;
  }

  final asset = hit.asset;
  if (asset == null || !context.mounted) return;
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MarkdownDocScreen(
        // 带来源前缀：伤寒/金匮讲稿有大量同名条目（「辨太阳病脉证并治」等），
        // 只给 title 会让用户分不清点开的是哪本书。
        title: hit.sourceLabel.isEmpty
            ? hit.title
            : '${hit.sourceLabel}·${hit.title}',
        asset: asset,
        linkFormulas: true,
      ),
    ),
  );
}
