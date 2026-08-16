import 'dart:convert';
import 'package:flutter/services.dart';

/// 一条更新日志（对应一个版本）。
class ChangelogEntry {
  final String version;
  final String date;
  final String title;
  final List<String> changes;

  const ChangelogEntry({
    required this.version,
    required this.date,
    required this.title,
    required this.changes,
  });

  factory ChangelogEntry.fromJson(Map<String, dynamic> json) {
    return ChangelogEntry(
      version: (json['version'] as String?) ?? '',
      date: (json['date'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      changes: (json['changes'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

/// 加载并缓存 bundled 更新日志（assets/data/changelog.json）。
/// 这是 App「关于」页与「更新后弹窗」的唯一数据源。
class ChangelogRepository {
  static List<ChangelogEntry> _entries = [];
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final jsonStr =
        await rootBundle.loadString('assets/data/changelog.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final list = (data['changelog'] as List<dynamic>? ?? [])
        .map((e) => ChangelogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    // 按版本号倒序（最新在前）；changelog.json 已是最新在前，这里再兜底排序。
    list.sort((a, b) => _compareVersion(b.version, a.version));
    _entries = list;
    _loaded = true;
  }

  static List<ChangelogEntry> getAll() => _entries;

  static ChangelogEntry? getForVersion(String version) {
    try {
      return _entries.firstWhere((e) => e.version == version);
    } catch (_) {
      return null;
    }
  }

  static ChangelogEntry? get latest =>
      _entries.isNotEmpty ? _entries.first : null;

  /// 比较 "x.y.z" 版本号，a>b 返回正数。
  static int _compareVersion(String a, String b) {
    final pa = a.split('.').map(int.tryParse).toList();
    final pb = b.split('.').map(int.tryParse).toList();
    for (var i = 0; i < 3; i++) {
      final va = (i < pa.length) ? (pa[i] ?? 0) : 0;
      final vb = (i < pb.length) ? (pb[i] ?? 0) : 0;
      if (va != vb) return va - vb;
    }
    return 0;
  }
}
