import 'dart:math' as math;
import '../data/formula_oral_hint_repository.dart';
import '../models/formula.dart';

/// 方剂症状匹配器：在原有「keywords/indication/name/alias 双向子串字面匹配」
/// 之上，叠加来自 `formula_oral_hints.json` 的 oral/indicators 加权打分。
///
/// 设计要点见 [enhancementScore] 与 [rank]。
class FormulaMatcher {
  FormulaMatcher._();

  /// 辨证指针（indicators）命中权重。
  ///
  /// indicators 是以「、」分隔的短症状短语，信噪比接近 keywords，但语料只覆盖
  /// 170 首方且多为古文表述，故略低于基线权重。
  static const double indicatorWeight = 0.4;

  /// 患者口语（oral）命中权重。
  ///
  /// oral 是几十字的口语长句，含大量虚词（我、有点、觉得、一直、还），误命中
  /// 风险最高，因此给最低权重——它只在基线无命中时把方剂「捞进」候选，不足以
  /// 单独把一方托到前列。
  static const double oralWeight = 0.15;

  /// 增强分上限。**必须严格小于 1**，这是非劣化不变式的前提（见 [rank]）。
  static const double enhancementCap = 0.9;

  /// 参与匹配的最小片段长度：低于此长度的单字（如脉象「浮」「沉」「数」）
  /// 不参与增强匹配，避免在长句语料中造成大面积误命中。
  static const int minOverlapLength = 2;

  /// 否定前缀字：语料中「无便秘」「不渴」这类否定表述，其被否定的症状词不应
  /// 视为命中。
  static const String _negationChars = '无不未非别沒没';

  /// 基线分：与改造前完全相同的算法，逐字未改。
  ///
  /// 单独暴露出来，既是为了让增强分可以与之相加，也是为了让测试能直接证明
  /// 「改造前后基线分一致」。
  static int baselineScore(Formula f, List<String> terms) {
    final haystack = <String>[...f.keywords, f.indication, f.name, f.alias];
    var score = 0;
    for (final term in terms) {
      for (final k in haystack) {
        if (k.contains(term) || term.contains(k)) score++;
      }
    }
    return score;
  }

  /// 增强分：来自 oral/indicators 的加权命中，值域恒为 [0, enhancementCap]。
  ///
  /// 语料未加载（或该方剂无语料）时返回 0，整体退化回基线行为。
  static double enhancementScore(Formula f, List<String> terms) {
    final hint = FormulaOralHintRepository.getById(f.id);
    if (hint == null) return 0.0;
    var indicatorHits = 0;
    var oralHits = 0;
    for (final term in terms) {
      for (final phrase in hint.indicatorPhrases) {
        if (_matches(phrase, term)) indicatorHits++;
      }
      for (final clause in hint.oralClauses) {
        if (_matches(clause, term)) oralHits++;
      }
    }
    final raw = indicatorHits * indicatorWeight + oralHits * oralWeight;
    return math.min(raw, enhancementCap);
  }

  /// 语料片段与用户症状词是否构成有效命中。
  ///
  /// 两个方向都要求重叠长度 ≥ [minOverlapLength]，杜绝单字级巧合命中。
  static bool _matches(String phrase, String term) {
    if (phrase.isEmpty || term.isEmpty) return false;
    if (term.length >= minOverlapLength && phrase.contains(term)) {
      return !_isNegated(phrase, term);
    }
    return phrase.length >= minOverlapLength && term.contains(phrase);
  }

  /// 语料片段中，命中位置前一个字是否是否定字。
  ///
  /// 例如片段「无便秘」对术语「便秘」命中于位置 1，前一字为「无」→ 判为否定，
  /// 不予计分。术语自身以否定字开头（如用户选的「不渴」）时命中于位置 0，
  /// 不受影响。
  static bool _isNegated(String phrase, String term) {
    final i = phrase.indexOf(term);
    if (i <= 0) return false;
    return _negationChars.contains(phrase[i - 1]);
  }

  /// 按「基线分 + 增强分」降序取 Top-K。
  ///
  /// **非劣化不变式**：设基线分为整数 b，增强分 e ∈ [0, enhancementCap]，且
  /// enhancementCap < 1。则对任意两方 X、Y，若 b(X) > b(Y)，必有
  /// b(X) ≥ b(Y)+1 > b(Y)+e(Y)，即 score(X) > score(Y)。
  ///
  /// 换言之：**基线分更低的一方，无论语料命中多少，都不可能排到基线分更高的
  /// 一方之前。** 增强分只做两件事：
  /// 1. 把原本 0 命中的方剂捞进候选（召回增益）；
  /// 2. 在同一基线分层内，按语料证据重排（排序增益）。
  ///
  /// 排序以方剂名做末位比较，使结果确定性可复现（Dart 的 List.sort 不稳定）。
  static List<(String, double)> rank(
    List<Formula> formulas,
    List<String> queryTerms, {
    int topK = 5,
  }) {
    if (queryTerms.isEmpty) return const [];
    final scored = <(String, double)>[];
    for (final f in formulas) {
      final score =
          baselineScore(f, queryTerms) + enhancementScore(f, queryTerms);
      if (score > 0) scored.add((f.name, score));
    }
    scored.sort((a, b) {
      final byScore = b.$2.compareTo(a.$2);
      return byScore != 0 ? byScore : a.$1.compareTo(b.$1);
    });
    return scored.take(topK).toList();
  }
}
