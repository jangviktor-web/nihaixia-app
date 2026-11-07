import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'chinese_convert.dart';

/// 一条病名对照。数据源 `assets/data/disease_alias_index.json`
/// （生成脚本 `tool/build_disease_alias_index.py`，勿手改）。
///
/// 每条都由脚本在倪师讲稿 / 医案里找到「古名与现代名同句（或邻句）+ 含对齐动词」
/// 的原文作证据，[note] 就是那句原文，[sources] 是它所在的资产路径。
class DiseaseAlias {
  /// 古病名 / 中医病名（如「消渴」「支饮」「心下痞」）。
  final String ancient;

  /// 今名 / 西医病名（如「糖尿病」「胸水」「肠胃炎」）。
  final List<String> moderns;

  /// 中医别名（如「消瘅」「中暍」）。
  final List<String> aliases;

  /// 'gujin' = 古今病名差异；'zhongxi' = 中西医叫法差异。
  final String kind;

  /// 倪师讲稿原话（脚本从材料里截取的整句，未改写）。
  final String note;

  /// 证据出处（相对 assets 的路径）。
  final List<String> sources;

  DiseaseAlias({
    required this.ancient,
    required this.moderns,
    required this.aliases,
    required this.kind,
    required this.note,
    this.sources = const [],
  });

  bool get isGuiJin => kind == 'gujin';

  /// 古名 + 今名 + 别名（本条的全部叫法），供检索扩展。
  late final List<String> allNames = <String>[
    ancient,
    ...moderns,
    ...aliases,
  ];

  /// 归一（简体 + 小写）后的叫法，匹配时直接用，避免逐次转换。
  late final List<String> normalizedNames =
      [for (final n in allNames) toSimplified(n).toLowerCase()];

  /// 「古/中医 ⇒ 今/西医」或「中医 ⇒ 西医」的展示标签。
  String get kindLabel => isGuiJin ? '古/中医 ⇒ 今/西医' : '中医 ⇒ 西医';
}

/// 古今病名 / 中西医病名对照索引。
///
/// 用途有两个，缺一不可：
/// 1. **检索扩展**：问「糖尿病」要能带出《金匮》「消渴」条文，问「胸水」要能
///    带出「支饮」条文 —— 否则古今叫法不同，用户永远搜不到倪师讲的那一段。
/// 2. **上下文注入**：让模型答「消渴」时点明今天叫糖尿病、答「寒疝」时点明与
///    西医疝气不是一回事，而不是含糊带过。
class DiseaseAliasIndex {
  DiseaseAliasIndex._(this.entries);

  final List<DiseaseAlias> entries;

  static const String assetPath = 'assets/data/disease_alias_index.json';

  static DiseaseAliasIndex? _instance;
  static Future<DiseaseAliasIndex>? _loadingFuture;

  /// 单飞加载：并发调用共享同一 future（避免轮询定时器在 FakeAsync 测试里悬空）。
  static Future<DiseaseAliasIndex> load() {
    if (_instance != null) return Future.value(_instance!);
    return _loadingFuture ??= _doLoad().then((v) {
      _instance = v;
      _loadingFuture = null;
      return v;
    });
  }

  /// 已加载实例（未加载返回 null，调用方可先 load 再取）。
  static DiseaseAliasIndex? get loaded => _instance;

  static Future<DiseaseAliasIndex> _doLoad() async {
    try {
      final raw = await rootBundle.loadString(assetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final list = (decoded['entries'] as List<dynamic>? ?? const []);
      final out = <DiseaseAlias>[
        for (final e in list.cast<Map<String, dynamic>>())
          DiseaseAlias(
            ancient: (e['a'] as String? ?? '').trim(),
            moderns: ((e['m'] as List?) ?? const []).cast<String>(),
            aliases: ((e['al'] as List?) ?? const []).cast<String>(),
            kind: (e['k'] as String? ?? 'gujin'),
            note: (e['note'] as String? ?? '').trim(),
            sources: ((e['src'] as List?) ?? const []).cast<String>(),
          ),
      ].where((e) => e.ancient.isNotEmpty && e.moderns.isNotEmpty).toList();
      return DiseaseAliasIndex._(out);
    } catch (_) {
      // 资产缺失/损坏：空索引，检索扩展与对照块降级为不显示，不崩。
      return DiseaseAliasIndex._(const []);
    }
  }

  /// 提问命中的病名条目，按命中强度降序（古名/今名命中 > 别名命中）。
  List<DiseaseAlias> match(String q, {int max = 3}) {
    if (entries.isEmpty) return const [];
    final text = toSimplified(q).toLowerCase();
    if (text.isEmpty) return const [];
    final scored = <(DiseaseAlias, int)>[];
    for (final e in entries) {
      var score = 0;
      final names = e.normalizedNames;
      for (var i = 0; i < names.length; i++) {
        final n = names[i];
        if (n.isEmpty || !text.contains(n)) continue;
        // ancient / moderns 命中权重高于 aliases
        score += i < 1 + e.moderns.length ? n.length + 4 : n.length + 1;
      }
      if (score > 0) scored.add((e, score));
    }
    if (scored.isEmpty) return const [];
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in scored.take(max)) s.$1];
  }

  /// 检索扩展词：命中的对照条目的全部叫法（古名在前，去重）。
  List<String> expandTerms(List<DiseaseAlias> hit) {
    final out = <String>[];
    for (final e in hit) {
      for (final n in e.allNames) {
        if (n.length < 2) continue;
        if (!out.contains(n)) out.add(n);
      }
    }
    return out;
  }

  /// 生成注入 LLM 的【病名对照】块；空列表返回空串（调用方不渲染）。
  static String brief(List<DiseaseAlias> hit, {int max = 3}) {
    final list = hit.take(max).toList();
    if (list.isEmpty) return '';
    final buf = StringBuffer('【古今·中西医病名对照（倪师讲稿原话，可直接引用）】\n');
    for (final e in list) {
      final names = e.moderns.join('、');
      final al = e.aliases.isEmpty ? '' : '（别名：${e.aliases.join('、')}）';
      buf.writeln('· ${e.ancient}$al ${e.kindLabel} $names：${e.note}');
    }
    return buf.toString().trim();
  }
}
