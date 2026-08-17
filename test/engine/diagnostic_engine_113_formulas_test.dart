import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/engine/formula_rules.dart';
import 'package:nihaisha_app/engine/rule_engine.dart';

/// 全部方剂规则：数据完整性与可达性扫描。
/// 原文件为「伤寒论113方」旧主诉流程测试，已随 v3.2 收口（移除主诉入口）
/// 重写为本套件：直接以 Q1-Q12 规则数据为准，验证：
///   1) 规则数量与数据边界合法；
///   2) 每首方的最小必选信号都能通过门槛（无死规则/不可达规则）；
///   3) 必选/参考值落在 qOptions 范围内，扩展症状 key 合法；
///   4) 真武汤去重后唯一。
void main() {
  group('规则数据完整性', () {
    test('规则数量 >= 170（当前 v3.2 为 172 方）', () {
      expect(allFormulaRules.length, greaterThanOrEqualTo(170));
    });

    test('必选(★)与参考(Q)的值均在 qOptions 选项范围内', () {
      for (final r in allFormulaRules) {
        for (final e in {...r.required.entries, ...r.reference.entries}) {
          final opts = qOptions[e.key];
          expect(opts, isNotNull,
              reason: '${r.name} 引用未知问键 ${e.key}');
          for (final v in e.value) {
            expect(v, inInclusiveRange(1, opts!.length),
                reason: '${r.name} 的 ${e.key} 选项号 $v 越界（${opts.length}）');
          }
        }
      }
    });

    test('扩展症状 key 均在 extSymptoms 表中', () {
      for (final r in allFormulaRules) {
        for (final s in {...r.extRequired, ...r.extReference}) {
          expect(extSymptoms.containsKey(s), isTrue,
              reason: '${r.name} 引用未知扩展症状 $s');
        }
      }
    });

    test('每首方至少有一个信号（必选/参考/扩展任一）', () {
      for (final r in allFormulaRules) {
        final empty = r.required.isEmpty &&
            r.reference.isEmpty &&
            r.extRequired.isEmpty &&
            r.extReference.isEmpty;
        expect(empty, isFalse, reason: '${r.name} 全空信号，将永远被最小证据门禁排除');
      }
    });

    test('真武汤去重后全局唯一', () {
      final names =
          allFormulaRules.where((r) => r.name == '真武汤').toList();
      expect(names.length, 1, reason: '真武汤应合并为少阴篇单条');
    });

    test('required 为空（纯扩展/外治/妇人坐药方）共 11 首', () {
      final emptyReq =
          allFormulaRules.where((r) => r.required.isEmpty).toList();
      expect(emptyReq.length, 11,
          reason: '大陷胸丸/猪膏发煎/瓜蒂散/皂荚丸/葶苈大枣泻肺汤/橘枳姜汤/'
              '旋覆花汤/柏叶汤/矾石散/蛇床子散/狼牙汤');
    });
  });

  group('规则可达性（最小必选信号 → 过门槛入选）', () {
    test('每首方的最小信号组合都能进入 evaluate 候选', () {
      for (final r in allFormulaRules) {
        final q = <String, int>{};
        for (final e in r.required.entries) {
          q[e.key] = e.value.first;
        }
        // 参考项也取一，保证"仅参考、无必选"的方（8 首外治/妇人坐药方）有证据分
        for (final e in r.reference.entries) {
          q.putIfAbsent(e.key, () => e.value.first);
        }
        final ext = <String>{...r.extRequired, ...r.extReference};

        final candidates = RuleEngine.evaluate(q, ext);
        expect(candidates.any((m) => m.rule.name == r.name), isTrue,
            reason: '规则不可达或未过最小证据门禁: ${r.name}');
      }
    });
  });
}
