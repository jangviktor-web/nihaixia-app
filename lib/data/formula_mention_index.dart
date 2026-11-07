import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'bencao_lecture_data.dart';
import 'zhenjiu_lecture_data.dart';

/// 方剂提及预索引（由 tool/build_formula_index.py 生成，勿手改）。
///
/// 数据源 `assets/data/formula_index.json`：
///   { "四逆汤": {"s":[伤寒seq], "j":[金匮seq],
///                "z":[{"s":针灸seq,"n":次数}], "b":[{"s":本草seq,"n":次数}] } }
///
/// 「s/j」= 「见于经典」条文 seq（判定=原 clauseIntroducesFormula，脚本
/// selfcheck 与旧 Dart 测试逐位一致）；「z/b」= 讲稿提及篇目（最大匹配
/// 归属计数）。取代 formula_detail_screen 的运行时全量扫描（833 文件现算）。
class FormulaMentionIndex {
  FormulaMentionIndex._(this._map);

  static FormulaMentionIndex? _instance;
  static Future<FormulaMentionIndex>? _loadingFuture;

  final Map<String, dynamic> _map;

  /// 单飞加载：并发调用共享同一 future，避免轮询定时器（FakeAsync 测试下挂死）。
  static Future<FormulaMentionIndex> load() {
    if (_instance != null) return Future.value(_instance!);
    if (_loadingFuture != null) return _loadingFuture!;
    _loadingFuture = _doLoad().then((v) {
      _instance = v;
      _loadingFuture = null;
      return v;
    });
    return _loadingFuture!;
  }

  static Future<FormulaMentionIndex> _doLoad() async {
    final map = <String, dynamic>{};
    try {
      final raw =
          await rootBundle.loadString('assets/data/formula_index.json');
      map.addAll(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      // json 缺失/损坏：空索引，「见于经典」降级为不显示，不崩。
      return FormulaMentionIndex._(const {});
    }
    return FormulaMentionIndex._(map);
  }

  /// 某个字段下有记录的方剂数（去重方剂名计数）。
  ///
  /// 供「金匮有多少方剂」这类计数提问给出确定性数字：'j' = 金匮要略讲稿、
  /// 's' = 伤寒论讲稿、'z' = 针灸讲稿、'b' = 本草讲稿。
  int countWith(String key) {
    var n = 0;
    for (final v in _map.values) {
      if (v is! Map) continue;
      final list = v[key];
      if (list is List && list.isNotEmpty) n++;
    }
    return n;
  }

  /// 方剂名 → 提及结构（未命中返回 null，调用方不渲染任何分组）。
  FormulaMentions? hitsFor(String name) {
    final v = _map[name];
    if (v is! Map<String, dynamic>) return null;
    List<int> seqs(String key) =>
        ((v[key] as List?) ?? const []).cast<int>().toList(growable: false);
    List<MentionHit> counted(String key) => ((v[key] as List?) ?? const [])
        .map((e) => MentionHit(
            seq: (e as Map<String, dynamic>)['s'] as int,
            count: e['n'] as int))
        .toList(growable: false);
    return FormulaMentions(
      shanghan: seqs('s'),
      jingui: seqs('j'),
      zhenjiu: counted('z'),
      bencao: counted('b'),
    );
  }

  /// 讲稿 seq → 篇名。
  static String zhenjiuNameOf(int seq) =>
      seq >= 0 && seq < kZhenJiuLectures.length
          ? kZhenJiuLectures[seq].name
          : '第${seq + 1}篇';

  static String zhenjiuAssetOf(int seq) => kZhenJiuLectures[seq].asset;

  static String bencaoNameOf(int seq) =>
      seq >= 0 && seq < kBenCaoLectures.length
          ? kBenCaoLectures[seq].name
          : '第${seq + 1}篇';

  static String bencaoAssetOf(int seq) => kBenCaoLectures[seq].asset;
}

/// 单个方剂的提及集合。
class FormulaMentions {
  /// 「见于经典」条文 seq（伤寒 / 金匮）。
  final List<int> shanghan;
  final List<int> jingui;

  /// 讲稿提及篇目（针灸 / 本草，按次数降序）。
  final List<MentionHit> zhenjiu;
  final List<MentionHit> bencao;

  bool get isEmpty =>
      shanghan.isEmpty && jingui.isEmpty && zhenjiu.isEmpty && bencao.isEmpty;

  const FormulaMentions({
    required this.shanghan,
    required this.jingui,
    required this.zhenjiu,
    required this.bencao,
  });
}

/// 讲稿命中条目。
class MentionHit {
  final int seq;
  final int count;
  const MentionHit({required this.seq, required this.count});
}
