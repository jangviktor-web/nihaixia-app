// 规则引擎冒烟测试：验证 六经 + 金匮 公式可正确判出。
import 'package:nihaisha_app/engine/formula_rules.dart';
import 'package:nihaisha_app/engine/rule_engine.dart';

void main() {
  // 期望方名(括号前) -> Q 答案
  final cases = <String, Map<String, int>>{
    '桂枝汤': {kQ1: 1, kQ4: 2, kQ2: 12},
    '麻黄汤': {kQ1: 7, kQ4: 1, kQ2: 1},
    '五苓散': {kQ3: 2, kQ7: 5},
    '理中丸': {kQ1: 6, kQ6: 3, kQ8: 2},
    '四逆汤': {kQ1: 6, kQ2: 10, kQ10: 3},
    '小柴胡汤': {kQ1: 3, kQ5: 5, kQ3: 5},
    '白虎汤': {kQ1: 1, kQ3: 7, kQ4: 7},
    '栝蒌薤白白酒汤': {kQ5: 16, kQ2: 7},
    '八味肾气丸': {kQ1: 6, kQ5: 20, kQ7: 4},
    '小半夏汤': {kQ12: 2, kQ3: 1},
    '泽泻汤': {kQ5: 19},
    '甘麦大枣汤': {kQ10: 4, kQ9: 5},
    '酸枣仁汤': {kQ9: 4, kQ1: 2},
  };
  // 必须附带 ext 症状才能命中的用例
  final extCases = <String, Map<String, int>>{
    '乌梅丸': {kQ1: 4, kQ10: 6, kQ5: 6},
    '桂枝茯苓丸': {kQ11: 3, kQ5: 6},
    '皂荚丸': {kQ1: 1},
    '柏叶汤': {kQ1: 1},
    '旋覆花汤': {kQ10: 2},
  };
  final extSel = <String, Set<String>>{
    '乌梅丸': {'abdomen_colic'},
    '桂枝茯苓丸': {'lesser_abdomen_mass'},
    '皂荚丸': {'wheeze_no_lie'},
    '柏叶汤': {'hematemesis'},
    '旋覆花汤': {'liver_attachment'},
  };

  int pass = 0, total = 0;
  void check(String expect, Map<String, int> q, [Set<String> ext = const {}]) {
    total++;
    final top = RuleEngine.top(q, ext);
    final got = top?.rule.name ?? '无候选';
    final ok = got == expect;
    if (ok) pass++;
    print('${ok ? "✅" : "❌"} 期望[$expect] 实际[$got] '
        'score=${top?.score.toStringAsFixed(1)} req=${top?.requiredHits} ref=${top?.referenceHits}');
  }

  for (final e in cases.entries) check(e.key, e.value);
  for (final e in extCases.entries) check(e.key, e.value, extSel[e.key]!);

  print('\n通过 $pass/$total');
}
