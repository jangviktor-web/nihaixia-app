/// 方剂「患者口语」语料模型（倪海厦《人纪》经方治症公式）。
///
/// 语料四个字段的分工：
/// - [oral]       患者口语大白话长句 → 需先切分再匹配，低权重
/// - [indicators] 辨证指针，以「、」分隔的短症状短语 → 高权重
/// - [treatment]  核心治法 → 仅展示，不参与打分
/// - [sourceText] 原文条文 → 仅展示，不参与打分
///
/// 只让 [oral] 与 [indicators] 参与匹配，是因为治法（如「解肌祛风」）与
/// 条文（如「太阳病项背强几几」）描述的是病机与来源，而非患者可自述的症状；
/// 把它们放进匹配池只会引入与用户勾选无关的噪声。
class FormulaOralHint {
  /// 与 `assets/data/formulas.json` 的 `id` 一一对应。
  final String id;
  final String oral;
  final String indicators;
  final String treatment;
  final String sourceText;

  List<String>? _indicatorPhrases;
  List<String>? _oralClauses;

  FormulaOralHint({
    required this.id,
    required this.oral,
    required this.indicators,
    required this.treatment,
    required this.sourceText,
  });

  factory FormulaOralHint.fromJson(String id, Map<String, dynamic> json) {
    return FormulaOralHint(
      id: id,
      oral: json['oral'] as String? ?? '',
      indicators: json['indicators'] as String? ?? '',
      treatment: json['treatment'] as String? ?? '',
      sourceText: json['sourceText'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'oral': oral,
        'indicators': indicators,
        'treatment': treatment,
        'sourceText': sourceText,
      };

  /// [indicators] 按「、」等分隔符切出的症状短语。
  ///
  /// 不切分则整串（如「脉搏宽缓、没动也出虚汗、特别怕风」）作为一个条目参与
  /// 匹配，反向包含（用户词包含该串）几乎永不成立，语料等于失效。
  List<String> get indicatorPhrases =>
      _indicatorPhrases ??= _segment(indicators);

  /// [oral] 按句读切出的短句。
  ///
  /// 长句整体参与 `contains` 时，句中的虚词（我、有点、觉得、一直、还）会让
  /// 无关术语误命中；切成短句后可逐句判定，并由匹配器施加最小重叠长度限制。
  List<String> get oralClauses => _oralClauses ??= _segment(oral);

  /// 按中文句读与顿号切分，丢弃空片段与纯空白片段。
  static List<String> _segment(String text) {
    final parts = <String>[];
    for (final raw in text.split(_delimiters)) {
      final s = raw.trim();
      if (s.isNotEmpty) parts.add(s);
    }
    return parts;
  }

  static final RegExp _delimiters = RegExp(r'[、，。；：！？,;!?]');
}
