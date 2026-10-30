import 'package:flutter/services.dart';

/// 古籍原文库：与「倪海厦讲稿」并列的经典原文阅读模块。
///
/// 只收 App 内原本没有的书，避免与既有内容重复：
/// - 《灵枢》：内经讲稿只覆盖素问部分篇章，灵枢原文此前完全缺失；
/// - 《针灸大成》：针灸模块只有 408 穴词条与处方，没有明代杨继洲这部针灸全书。
///
/// 本草模块（herbs.json 的 465 味药）与古书库无关，删《神农本草经》不影响本草页。
/// 文本为公版古籍整理本（UTF-8），章节由 `====` 分隔线包裹标题。
class GujiBook {
  final String id;

  /// 书名（展示用）。
  final String title;

  /// 成书/托名信息。
  final String author;

  /// 原文资产路径（txt）。
  final String asset;

  /// 一句话简介。
  final String intro;

  /// 章数（解析后的实测值，用于列表展示）。
  final int chapterCount;

  const GujiBook({
    required this.id,
    required this.title,
    required this.author,
    required this.asset,
    required this.intro,
    required this.chapterCount,
  });
}

const List<GujiBook> kGujiBooks = [
  GujiBook(
    id: 'lingshu',
    title: '黄帝内经·灵枢',
    author: '佚名 · 托名黄帝',
    asset: 'assets/guji/lingshu.txt',
    intro: '与《素问》同为《黄帝内经》两部分，偏重经络腧穴、针法刺法与体质形神，是针灸理论的根本经典。',
    chapterCount: 82,
  ),
  GujiBook(
    id: 'zhenjiudacheng',
    title: '针灸大成',
    author: '明 · 杨继洲',
    asset: 'assets/guji/zhenjiudacheng.txt',
    intro: '明代针灸集大成之作，十卷。辑录《素问》《灵枢》针灸要义与历代歌赋（标幽赋、百症赋、玉龙赋等），'
        '兼收九针手法、子午流注、经穴考证与临证治验，是针灸临床与文献的总汇。',
    chapterCount: 339,
  ),
];

/// 古籍单章。
class GujiChapter {
  final int index;
  final String title;
  final String body;

  const GujiChapter({
    required this.index,
    required this.title,
    required this.body,
  });
}

class GujiRepository {
  static final Map<String, Future<List<GujiChapter>>> _cache = {};

  /// 读取并解析一本书的全部章节（同一本书只解析一次）。
  static Future<List<GujiChapter>> chaptersOf(GujiBook book) {
    return _cache.putIfAbsent(book.id, () async {
      final raw = await rootBundle.loadString(book.asset);
      return parse(raw);
    });
  }

  /// 解析原文：结构为「分隔线 / 章节标题 / 分隔线 / 正文 / 分隔线 / 标题 …」，
  /// 每个标题被一对分隔线夹住，按分隔线切块后成对取（首块是书名/前言）。
  static List<GujiChapter> parse(String raw) {
    final sep = RegExp(r'^=+\s*$');
    final blocks = <List<String>>[];
    var current = <String>[];
    for (final line in raw.split('\n')) {
      final text = line.trim();
      if (sep.hasMatch(text)) {
        blocks.add(current);
        current = <String>[];
      } else {
        current.add(line);
      }
    }
    blocks.add(current);

    final chapters = <GujiChapter>[];
    for (var i = 1; i + 1 < blocks.length; i += 2) {
      final title = blocks[i]
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .join(' ')
          .trim();
      final body = blocks[i + 1]
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .join('\n');
      if (title.isEmpty || body.isEmpty) continue;
      chapters.add(GujiChapter(index: chapters.length, title: title, body: body));
    }
    return chapters;
  }

  /// 仅测试用：清空解析缓存。
  static void clearCache() => _cache.clear();
}
