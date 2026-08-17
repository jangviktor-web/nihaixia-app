// 规则判定引擎：依据《问诊公式_全量修正版》的必选(★)/参考(Q)信号，筛选+打分排序方剂。
import 'formula_rules.dart';

class RuleMatch {
  final FormulaRule rule;
  final int requiredHits;
  final int referenceHits;
  final int extRequiredHits;
  final double score;
  RuleMatch({
    required this.rule,
    required this.requiredHits,
    required this.referenceHits,
    this.extRequiredHits = 0,
    required this.score,
  });
}

class RuleEngine {
  /// 输入：qAnswers = {qKey: 选项号(1-based)}，ext = 已选扩展症状 key 集合
  /// 返回：所有「必选信号全部满足」的候选，按得分降序。
  static List<RuleMatch> evaluate(Map<String, int> q, Set<String> ext) {
    final List<RuleMatch> candidates = [];

    for (final r in allFormulaRules) {
      // —— 必选(★)门禁：每个 required 信号都必须命中 ——
      bool ok = true;
      int reqHits = 0;
      int extReqHits = 0;

      for (final e in r.required.entries) {
        final ans = q[e.key];
        if (ans == null || !e.value.contains(ans)) {
          ok = false;
          break;
        }
        reqHits++;
      }
      if (ok) {
        for (final s in r.extRequired) {
          if (!ext.contains(s)) {
            ok = false;
            break;
          }
          reqHits++;
          extReqHits++;
        }
      }
      if (!ok) continue;

      // —— 参考(Q)打分 ——
      int refHits = 0;
      for (final e in r.reference.entries) {
        final ans = q[e.key];
        if (ans != null && e.value.contains(ans)) refHits++;
      }
      for (final s in r.extReference) {
        if (ext.contains(s)) refHits++;
      }

      // 无任何命中信号（必选与参考皆零）→ 视为无证据，排除。
      // 防止纯外治/杂疗/妇人坐药方（无必选★、仅靠参考）在空输入或零匹配时以 0 分入选成噪声。
      if (reqHits == 0 && refHits == 0) continue;

      final score = reqHits * 3.0 + refHits * 1.0;
      candidates.add(RuleMatch(
        rule: r,
        requiredHits: reqHits,
        referenceHits: refHits,
        extRequiredHits: extReqHits,
        score: score,
      ));
    }

    candidates.sort((a, b) => b.score.compareTo(a.score));
    return candidates;
  }

  /// 取最佳方；同级歧义用鉴别链优先序消解。
  static RuleMatch? top(Map<String, int> q, Set<String> ext) {
    final c = evaluate(q, ext);
    if (c.isEmpty) return null;

    // 找出得分并列的最高分组
    final topScore = c.first.score;
    final topGroup = c.where((m) => m.score >= topScore - 0.001).toList();
    if (topGroup.length == 1) return topGroup.first;

    // 同分：必选扩展症状(ext★)命中更多者特异性更高，优先（如桂枝茯苓丸 vs 当归芍药散）
    topGroup.sort((a, b) => b.extRequiredHits.compareTo(a.extRequiredHits));
    final topExt = topGroup.first.extRequiredHits;
    final extTier = topGroup.where((m) => m.extRequiredHits == topExt).toList();
    if (extTier.length == 1) return extTier.first;

    // 同分且同 ext 特异性层级：才用鉴别链优先序消解
    for (final chain in differentialChains.values) {
      for (final name in chain) {
        final hit = extTier.where((m) => m.rule.name == name);
        if (hit.isNotEmpty) return hit.first;
      }
    }
    return extTier.first;
  }

  /// 与最佳方「必选(★)症状签名完全相同」的所有满足候选（含最佳方本身）。
  /// 用于需求：规则症状相同则同时推荐，不再静默只取一个。
  static List<RuleMatch> coRecommended(Map<String, int> q, Set<String> ext) {
    final c = evaluate(q, ext);
    if (c.isEmpty) return const [];
    final best = top(q, ext);
    if (best == null) return const [];
    final sig = _requiredSignature(best.rule.required);
    return c.where((m) => _requiredSignature(m.rule.required) == sig).toList();
  }

  /// 必选症状的规范化签名：键升序 + 各值升序，用于判定「症状是否相同」。
  static String _requiredSignature(Map<String, List<int>> req) {
    final keys = req.keys.toList()..sort();
    return keys.map((k) => '$k:[${req[k]!.join(',')}]').join('|');
  }
}
