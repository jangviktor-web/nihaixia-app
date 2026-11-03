import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'bencao_lecture_data.dart';

/// 本草讲稿 ↔ 药材 双向联动索引（反向：药材详情页 → 讲稿提及篇目）。
///
/// 数据源 `assets/bencao_lecture/herb_index.json`（由
/// tool/import_renji_bencao.py 生成）：
///   { "药库正名(含别名括号)": [{"s": 篇seq, "n": 提及次数}, ...], "_excluded": [] }
///
/// 消费方：药材详情页「讲义讲解」——[hitsFor] 查提及本药的篇列表。
/// （正向：讲稿 → 药材 已由 MarkdownDocScreen._injectLinks 借 HerbRepository 自动覆盖，无需本类参与。）
class BenCaoLectureIndex {
  BenCaoLectureIndex._(this._map);

  static BenCaoLectureIndex? _instance;
  static Future<BenCaoLectureIndex>? _loadingFuture;

  final Map<String, List<Map<String, dynamic>>> _map;

  /// 单飞加载：并发调用共享同一 future，避免轮询定时器（FakeAsync 测试下挂死）。
  static Future<BenCaoLectureIndex> load() {
    if (_instance != null) return Future.value(_instance!);
    if (_loadingFuture != null) return _loadingFuture!;
    _loadingFuture = _doLoad().then((v) {
      _instance = v;
      _loadingFuture = null;
      return v;
    });
    return _loadingFuture!;
  }

  static Future<BenCaoLectureIndex> _doLoad() async {
    final map = <String, List<Map<String, dynamic>>>{};
    try {
      final raw = await rootBundle
          .loadString('assets/bencao_lecture/herb_index.json');
      final data = json.decode(raw) as Map<String, dynamic>;
      data.forEach((k, v) {
        if (k.startsWith('_')) return;
        map[k] = (v as List)
            .map((e) => (e as Map<String, dynamic>))
            .toList(growable: false);
      });
    } catch (_) {
      // json 缺失/损坏：空索引，页面降级（不显示入口）不崩。
      return BenCaoLectureIndex._(const {});
    }
    return BenCaoLectureIndex._(map);
  }

  /// 药材名（支持完整名 / 主名）→ 提及篇列表（按次数降序）。
  /// key 为 herbs.json 完整名（含「（别名）」），故先试全名，再试去掉括号的主名。
  List<LectureHit> hitsFor(String herbName) {
    List<Map<String, dynamic>>? raw = _map[herbName];
    if (raw == null || raw.isEmpty) {
      final main = herbName.split('（')[0].trim();
      if (main != herbName) raw = _map[main];
    }
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
      seq >= 0 && seq < kBenCaoLectures.length
          ? kBenCaoLectures[seq].name
          : '第${seq + 1}篇';

  /// 篇 seq → 资产路径。
  static String assetOf(int seq) => kBenCaoLectures[seq].asset;
}

/// 讲稿命中条目。
class LectureHit {
  final int seq;
  final int count;
  const LectureHit({required this.seq, required this.count});
}
