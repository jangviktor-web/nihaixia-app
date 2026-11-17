import 'package:flutter/services.dart';

/// 天纪讲义的一节。
///
/// 讲义原文用 Markdown 分节：`##` 是篇/类目，`####` 是具体小节。
/// 阅读页据此切成「一节一卡」，避免整篇连续滚动。
class TianjiSection {
  final int index;

  /// 所属篇名（如「天机道」「堪舆风水」）。
  final String book;

  /// 节标题，含上级类目（如「相术总结 · 色 · 苦冷者死」）。
  final String title;

  /// 正文（保留 Markdown 空行，直接交给 MarkdownDocScreen）。
  final String body;

  const TianjiSection({
    required this.index,
    required this.book,
    required this.title,
    required this.body,
  });

  /// 篇内显示用标题：去掉「篇名 · 」前缀。
  ///
  /// 篇内节列表已经在「篇」这一层里，再带一遍篇名只会挤占一行；
  /// 串联层级（如「北斗星系 · 紫微星」）保留，那个信息有用。
  String get shortTitle {
    final prefix = '$book · ';
    return title.startsWith(prefix) ? title.substring(prefix.length) : title;
  }
}

class TianjiSectionRepository {
  static final Map<String, Future<List<TianjiSection>>> _cache = {};

  /// 解析全部讲义，返回按原文顺序排列的扁平小节列表。
  ///
  /// [docs] 为 `(分组, 篇名, 副标题, 资产路径)`，由列表页统一维护，
  /// 保证「列表里显示的篇」与「解析的资产」不会漂移。
  static Future<List<TianjiSection>> parseAll(
    List<(String, String, String, String)> docs,
  ) async {
    final key = docs.map((d) => d.$4).join('|');
    final cached = _cache[key];
    if (cached != null) return cached;

    final future = () async {
      final out = <TianjiSection>[];
      for (final (_, book, _, asset) in docs) {
        final raw = await rootBundle.loadString(asset);
        out.addAll(parse(raw, book, out.length));
      }
      return out;
    }();
    _cache[key] = future;
    return future;
  }

  /// 指定篇的节列表（复用同一份解析缓存，不重复读文件）。
  static Future<List<TianjiSection>> sectionsOf(
    List<(String, String, String, String)> docs,
    String book,
  ) async {
    final all = await parseAll(docs);
    return all.where((s) => s.book == book).toList();
  }

  /// 按标题切节。
  ///
  /// 层级约定：
  /// - 篇内**第一个 `##` 视为篇标题**（直接用品名，避免「天机道 · 天纪讲稿」这类
  ///   冗余前缀），之后出现的 `##` 才作为类目分组参与拼接；
  /// - `####` 是大类（如「北斗星系」「详解六杀」），记为分组前缀；
  /// - `#####` 是子节（如「紫微星」「化权」），最终标题形如
  ///   「星曜详解 · 北斗星系 · 紫微星」。
  ///
  /// 纯容器标题（正下方紧跟下级标题、自身无正文）不单独成节。
  static List<TianjiSection> parse(String raw, String book, int startIndex) {
    final head = RegExp(r'^(#{2,5})\s+(.*)$');
    final sections = <TianjiSection>[];
    String? group;
    String? title;
    var seenH2 = false;
    final buffer = <String>[];

    String compose(String name) {
      if (name == book) return book;
      if (group != null && name != group) return '$book · $group · $name';
      return '$book · $name';
    }

    void flush() {
      final body = buffer.join('\n').trim();
      buffer.clear();
      if (title == null || body.isEmpty) return;
      sections.add(TianjiSection(
        index: startIndex + sections.length,
        book: book,
        title: title,
        body: body,
      ));
    }

    for (final line in raw.split('\n')) {
      final m = head.firstMatch(line.trim());
      if (m == null) {
        buffer.add(line);
        continue;
      }
      flush();
      final level = m.group(1)!.length;
      final name = m.group(2)!.trim();
      if (level == 2) {
        if (!seenH2) {
          seenH2 = true;
          group = null;
          title = book;
        } else {
          if (name != book) group = name;
          title = compose(name);
        }
      } else if (level == 4) {
        // 大类：记为后续 ##### 子节的分组前缀
        if (name != book) group = name;
        title = compose(name);
      } else {
        title = compose(name);
      }
    }
    flush();
    return sections;
  }

  /// 仅测试用：清空解析缓存。
  static void clearCache() => _cache.clear();
}
