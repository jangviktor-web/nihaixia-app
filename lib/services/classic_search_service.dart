import 'dart:convert';

import 'package:flutter/services.dart';

import '../data/guji_data.dart';
import 'gzip_codec_stub.dart' if (dart.library.io) 'gzip_codec_io.dart';

/// 经典（讲稿 + 古籍原文）全文检索。
///
/// 索引是构建期产物 `assets/guji/classic_index.json.gz`
/// （生成脚本 `tool/build_classic_search_index.py`），覆盖：
/// 伤寒论讲稿 380 条、金匮要略讲稿 453 条、内经讲稿 73 篇，
/// 以及古籍原文《灵枢》《针灸大成》共 421 章。
///
/// ⚠️ 讲稿或古书有增删改后必须重跑脚本，否则搜索漏内容。
class ClassicHit {
  /// shanghan / jingui / neijing / guji
  final String source;

  /// 展示用来源名（如「伤寒论讲稿」「针灸大成」）。
  final String sourceLabel;

  final String title;

  /// 讲稿条目对应的 markdown 资产（古籍原文为 null）。
  final String? asset;

  /// 古籍原文书名 id 与章节序号（讲稿为 null）。
  final String? bookId;
  final int? chapterIndex;

  /// 命中位置的上下文摘要。
  final String snippet;

  const ClassicHit({
    required this.source,
    required this.sourceLabel,
    required this.title,
    required this.snippet,
    this.asset,
    this.bookId,
    this.chapterIndex,
  });
}

class ClassicSearchResult {
  /// 命中总数（[hits] 只保留前若干条用于展示）。
  final int total;
  final List<ClassicHit> hits;

  const ClassicSearchResult({required this.total, required this.hits});

  static const ClassicSearchResult empty =
      ClassicSearchResult(total: 0, hits: []);
}

class _IndexEntry {
  final String source;
  final String title;
  final String? asset;
  final String? bookId;
  final int? chapterIndex;
  final String text;

  const _IndexEntry({
    required this.source,
    required this.title,
    required this.text,
    this.asset,
    this.bookId,
    this.chapterIndex,
  });
}

class ClassicSearchService {
  static const String assetPath = 'assets/guji/classic_index.json.gz';

  /// 展示条数上限（命中总数另外统计）。
  static const int maxHits = 40;

  static List<_IndexEntry>? _entries;
  static Future<void>? _loading;

  /// 索引是否已加载（供 UI 判断是否显示加载态）。
  static bool get isLoaded => _entries != null;

  static const Map<String, String> _sourceLabels = {
    'shanghan': '伤寒论讲稿',
    'jingui': '金匮要略讲稿',
    'neijing': '内经讲稿',
  };

  static String _labelOf(String source, String? bookId) {
    if (source == 'guji') {
      for (final b in kGujiBooks) {
        if (b.id == bookId) return b.title;
      }
      return '古籍原文';
    }
    return _sourceLabels[source] ?? source;
  }

  /// 首次调用解压并解析索引（约 1.8MB gzip → 5MB 文本），之后走内存缓存。
  static Future<void> ensureLoaded() async {
    if (_entries != null) return;
    _loading ??= _load();
    await _loading;
  }

  static Future<void> _load() async {
    final data = await rootBundle.load(assetPath);
    final bytes = gunzipBytes(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final list = (decoded['entries'] as List<dynamic>).cast<Map<String, dynamic>>();
    _entries = [
      for (final e in list)
        _IndexEntry(
          source: e['s'] as String,
          title: (e['t'] as String?) ?? '',
          asset: e['a'] as String?,
          bookId: e['b'] as String?,
          chapterIndex: e['i'] as int?,
          text: (e['x'] as String?) ?? '',
        ),
    ];
  }

  /// 检索：标题命中优先，其次正文命中；正文命中给出关键词上下文摘要。
  static Future<ClassicSearchResult> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) return ClassicSearchResult.empty;
    await ensureLoaded();
    final entries = _entries!;
    final needle = q.toLowerCase();

    final titleHits = <ClassicHit>[];
    final bodyHits = <ClassicHit>[];
    var total = 0;

    for (final e in entries) {
      final inTitle = e.title.toLowerCase().contains(needle);
      final idx = e.text.toLowerCase().indexOf(needle);
      if (!inTitle && idx < 0) continue;
      total++;
      if (titleHits.length + bodyHits.length >= maxHits) continue;
      final hit = ClassicHit(
        source: e.source,
        sourceLabel: _labelOf(e.source, e.bookId),
        title: e.title,
        asset: e.asset,
        bookId: e.bookId,
        chapterIndex: e.chapterIndex,
        snippet: _snippet(e.text, inTitle ? -1 : idx, q.length),
      );
      if (inTitle) {
        titleHits.add(hit);
      } else {
        bodyHits.add(hit);
      }
    }

    return ClassicSearchResult(
      total: total,
      hits: [...titleHits, ...bodyHits],
    );
  }

  /// 取命中位置前后各 32 字做摘要；[idx] < 0 表示只在标题命中，取正文开头。
  static String _snippet(String text, int idx, int queryLength) {
    const span = 32;
    if (text.isEmpty) return '';
    final start = idx < 0 ? 0 : (idx - span).clamp(0, text.length);
    final end = idx < 0
        ? (span * 2).clamp(0, text.length)
        : (idx + queryLength + span).clamp(0, text.length);
    final raw = text.substring(start, end).replaceAll('\n', ' ').trim();
    final prefix = start > 0 ? '…' : '';
    final suffix = end < text.length ? '…' : '';
    return '$prefix$raw$suffix';
  }
}
