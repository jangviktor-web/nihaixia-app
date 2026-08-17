import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/engine/formula_rules.dart';
import 'package:nihaisha_app/engine/rule_engine.dart';

/// 同症状并列推荐（co-recommended）全量组验证。
/// 统计口径与 scan_173.py 一致：以「必选(★)签名（键升序+值升序）」分组，
/// 仅统计 ≥2 首的并列组。空必选签名组（11 首外治/妇人坐药方）单独验证带下三证。
void main() {
  group('必选签名并列组', () {
    test('多首并列组数量为 17（空签名组不计；总 18 组含外治方组）', () {
      final multi = _multiMemberGroups();
      expect(multi.values.where((g) => g.length >= 2).length, 17,
          reason: '当前数据并列组数（与 scan_173.py 扫描一致）');
    });

    test('每组并列方在最小必选信号下全部同时入选（可同证共现）', () {
      for (final group in _multiMemberGroups().values) {
        if (group.length < 2) continue;
        final q = <String, int>{};
        final ext = <String>{};
        for (final r in group) {
          for (final e in r.required.entries) {
            q[e.key] = e.value.first;
          }
          ext.addAll(r.extRequired);
        }
        final names = RuleEngine.evaluate(q, ext).map((m) => m.rule.name).toSet();
        final expected = group.map((r) => r.name).toSet();
        expect(expected.difference(names), isEmpty,
            reason: '并列组成员未全部通过门槛: ${expected.difference(names).join('/')}');
      }
    });

    test('已知并列组：{kQ1:7,kQ5:8} → 桂枝附子汤/桂枝芍药知母汤/乌头汤', () {
      final q = {kQ1: 7, kQ5: 8};
      final co = RuleEngine.coRecommended(q, const {}).map((m) => m.rule.name).toSet();
      expect(co, {'桂枝附子汤', '桂枝芍药知母汤', '乌头汤'});
    });

    test('已知并列组：{kQ3:2,kQ7:5} → 五苓散/猪苓汤/文蛤散', () {
      final q = {kQ3: 2, kQ7: 5};
      final co = RuleEngine.coRecommended(q, const {}).map((m) => m.rule.name).toSet();
      expect(co, {'五苓散', '猪苓汤', '文蛤散'});
    });

    test('已知并列组：{kQ5:7,kQ6:2} → 小承气汤/桂枝加大黄汤/厚朴三物汤', () {
      final q = {kQ5: 7, kQ6: 2};
      final co = RuleEngine.coRecommended(q, const {}).map((m) => m.rule.name).toSet();
      expect(co, {'小承气汤', '桂枝加大黄汤', '厚朴三物汤'});
    });

    test('空必选组：带下三证 → 蛇床子散/狼牙汤/矾石散', () {
      final co = RuleEngine.coRecommended(const {}, {'leukorrhea', 'vulva_cold', 'vulva_ulcer'})
          .map((m) => m.rule.name)
          .toSet();
      expect(co, {'蛇床子散', '狼牙汤', '矾石散'});
    });

    test('真武汤签名组去重后仅 1 首', () {
      final q = {kQ1: 6, kQ7: 5, kQ5: 19};
      final co = RuleEngine.coRecommended(q, const {}).map((m) => m.rule.name).toList();
      expect(co, ['真武汤']);
    });
  });
}

/// 必选签名分组（排除空签名 = 纯扩展/外治/妇人坐药方）
Map<String, List<FormulaRule>> _multiMemberGroups() {
  final groups = <String, List<FormulaRule>>{};
  for (final r in allFormulaRules) {
    if (r.required.isEmpty) continue;
    final sig = _sig(r.required);
    groups.putIfAbsent(sig, () => []).add(r);
  }
  return groups;
}

String _sig(Map<String, List<int>> req) {
  final keys = req.keys.toList()..sort();
  return keys.map((k) {
    final vs = [...req[k]!]..sort();
    return '$k:[${vs.join(',')}]';
  }).join('|');
}
