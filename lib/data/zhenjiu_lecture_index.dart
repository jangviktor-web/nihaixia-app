import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'zhenjiu_lecture_data.dart';

/// 针灸讲稿 ↔ 穴位 双向联动索引。
///
/// 数据源 `assets/zhenjiu_lecture/acupoint_index.json`（由
/// tool/import_renji_zhenjiu.py 生成）：
///   { "涌泉": [{"s": 篇seq, "n": 提及次数}, ...], "_excluded": [...] }
///
/// 两个消费方：
///   1. 穴位详情页「讲义讲解」——[hitsFor] 查提及篇列表；
///   2. MarkdownDocScreen 自动链接——[excludedNames] 排除名单
///      （与 tool/import_renji_zhenjiu.py 的 _EXCLUDED 保持同步，
///      json 缺失时回退硬编码，见 [kFallbackExcluded]）。
class ZhenJiuLectureIndex {
  ZhenJiuLectureIndex._(this._map, this._excluded);

  static ZhenJiuLectureIndex? _instance;
  static bool _loading = false;

  final Map<String, List<Map<String, dynamic>>> _map;
  final Set<String> _excluded;

  /// 硬编码回退：与 tool/import_renji_zhenjiu.py 的 _EXCLUDED 同步维护。
  // ponytail: 排除名单本来该从 json 单一来源读，但 _injectLinks 是同步路径；
  // 名单年变化个位数，双处维护可接受，脚本侧以本清单为准回写。
  static const List<String> kFallbackExcluded = ['太阳', '光明', '子宫'];

  static Future<ZhenJiuLectureIndex> load() async {
    if (_instance != null) return _instance!;
    if (_loading) {
      // 极端并发：等上一轮完成（实践中详情页/阅读库不会同时首载）。
      while (_loading) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      return _instance!;
    }
    _loading = true;
    try {
      final raw = await rootBundle
          .loadString('assets/zhenjiu_lecture/acupoint_index.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      final map = <String, List<Map<String, dynamic>>>{};
      data.forEach((k, v) {
        if (k.startsWith('_')) return;
        map[k] = (v as List)
            .map((e) => (e as Map<String, dynamic>))
            .toList(growable: false);
      });
      final excluded = ((data['_excluded'] as List?) ?? const [])
          .cast<String>()
          .toSet();
      _instance = ZhenJiuLectureIndex._(map, excluded);
    } catch (_) {
      // json 缺失/损坏：空索引 + 回退排除名单，页面降级（不显示入口）不崩。
      _instance = ZhenJiuLectureIndex._(
          const {}, kFallbackExcluded.toSet());
    } finally {
      _loading = false;
    }
    return _instance!;
  }

  /// 已加载实例的排除名单（供 _injectLinks 同步读取）。
  /// 未加载时返回 null——消费方应回退 [kFallbackExcluded]。
  static Set<String>? get cachedExcluded => _instance?.excludedNames;

  /// 排除名单（json 的 _excluded 优先，缺失回退硬编码）。
  Set<String> get excludedNames => _excluded;

  /// 穴位名（支持带「穴」后缀）→ 提及篇列表（按次数降序）。
  List<LectureHit> hitsFor(String acupointName) {
    final key = acupointName.replaceAll('穴', '');
    final raw = _map[key];
    if (raw == null || raw.isEmpty) return const [];
    return raw
        .map((e) => LectureHit(
              seq: e['s'] as int,
              count: e['n'] as int,
            ))
        .toList(growable: false);
  }

  /// 篇 seq → 篇名（供 bottom sheet 展示）。
  static String nameOf(int seq) =>
      seq >= 0 && seq < kZhenJiuLectures.length
          ? kZhenJiuLectures[seq].name
          : '第${seq + 1}篇';

  /// 篇 seq → 资产路径。
  static String assetOf(int seq) => kZhenJiuLectures[seq].asset;
}

/// 讲稿命中条目。
class LectureHit {
  final int seq;
  final int count;
  const LectureHit({required this.seq, required this.count});
}
