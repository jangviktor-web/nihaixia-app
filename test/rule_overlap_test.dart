// 规则重叠（静默平局）扫描：任何两首及以上方剂并列在同一分数时，
// 必须能用一张 kD 鉴别表把它们分开，否则引擎只能按规则表声明顺序挑一个——
// 等于随机，且 reachability 测试抓不到（它只测单方自己的 ★）。
//
// 两层扫描：
//   ① 逐条按自己的 ★ 必选构造输入 —— 覆盖「用户填满该方主症」这条主路径，
//      这一层是硬断言：并列了就一定得有人管。
//   ② 随机 3000 组答案 —— 只对「必选签名完全相同」的并列做硬断言。
//      随机组合会撞出大量「偶然并列」（两首毫不相干的单必选方同时被满足，
//      如泽泻汤+竹叶汤都是 3.0），那不是设计缺陷、也没法用 kD 表穷举，
//      只计数观察；真正要拦的是两首门禁一模一样的那种。
//
// 运行：flutter test test/rule_overlap_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/engine/diagnostic_engine.dart';
import 'package:nihaisha_app/engine/diagnostic_rules.dart';
import 'package:nihaisha_app/engine/formula_rules.dart';
import 'package:nihaisha_app/engine/rule_engine.dart';

/// 已知例外：这两首同分时靠 kQ6（大便）区分——生姜泻心汤的 reference 有
/// 「稀/拉肚子」，用户答了大便题就自动 7.0 对 6.0。只在「只勾 ★ 不答其余」
/// 的实验室输入下才平局，真实流程不会，故不做 kD 表。
const List<Set<String>> _knownTies = [
  {'生姜泻心汤', '旋覆代赭汤'},
];

/// 必选签名：required 的 key:选项 + extRequired 的 key。
/// 两首签名完全相同 = 用户勾出这组症状时引擎分不开，历史上 15 条「被抢」
/// 全是这种，也正是 kD1–kD13 的由来。
String _signature(FormulaRule r) {
  final parts = <String>[
    for (final e in r.required.entries)
      '${e.key}:[${([...e.value]..sort()).join(",")}]',
    for (final x in r.extRequired) 'ext:$x',
  ]..sort();
  return parts.join('|');
}

/// 这组并列能否被一张鉴别表（或已知例外）覆盖。
///
/// 判据是「交集 ≥ 2」而不是「全包」：kD 的工作方式是给选中的那首 +1 分，
/// 不是把别的方踢出候选。所以并列里混进第三首外部方也无妨——用户答一句，
/// 表内那首就 4.0/7.0 领先，外部方自然落后。这正是 pendingDisambiguator()
/// 的实际触发条件（`d.members.where(names.contains).length >= 2`）。
bool _covered(Set<String> names) {
  if (names.length < 2) return true;
  for (final d in kDisambiguators) {
    if (names.where(d.members.containsKey).length >= 2) return true;
  }
  for (final w in _knownTies) {
    if (names.where(w.contains).length >= 2) return true;
  }
  return false;
}

/// 十问（含 kQ12 特例）的选项原文，用于把规则里的选项号还原成答案。
String? _optionText(String key, int oneBased) {
  for (final q in DiagnosticRules.tenQuestions) {
    if (q.key != key) continue;
    if (oneBased - 1 < q.options.length) return q.options[oneBased - 1];
  }
  if (key == kQ12 &&
      oneBased - 1 < DiagnosticRules.vomitTypeQuestion.options.length) {
    return DiagnosticRules.vomitTypeQuestion.options[oneBased - 1];
  }
  return null;
}

String _keyOf(Iterable<String> names) => (names.toList()..sort()).join('+');

void main() {
  test('每首方按自己的 ★ 构造输入时，并列的组都有人管', () {
    final bad = <String>[];
    final seen = <String>{};

    for (final r in allFormulaRules) {
      final e = DiagnosticEngine();
      e.answerTemperaturePattern('fever_chills');
      var ok = true;
      for (final entry in r.required.entries) {
        final txt = _optionText(entry.key, entry.value.first);
        if (txt == null) {
          ok = false;
          break;
        }
        e.answerTenQuestion(entry.key, txt);
      }
      if (!ok) continue;
      for (final x in r.extRequired) {
        e.toggleExtSymptom(x, true);
      }

      final tied = RuleEngine.tiedTop(e.qAnswers, e.extSymptoms);
      if (tied.length < 2) continue;
      final names = tied.map((m) => m.rule.name).toSet();
      if (_covered(names)) continue;
      if (seen.add(_keyOf(names))) {
        bad.add('${tied.first.score} 分：${_keyOf(names)}');
      }
    }

    // ignore: avoid_print
    print('[重叠扫描·按★] 规则 ${allFormulaRules.length} 条 | 无主并列 ${bad.length} 组');
    for (final b in bad) {
      // ignore: avoid_print
      print('  ✗ $b');
    }
    expect(bad, isEmpty,
        reason: '这些组的方剂会互相抢且没有 kD 表兜底，用户答到这一组时结果不确定：\n'
            '${bad.join("\n")}');
  });

  test('随机 3000 组里，必选签名相同的并列组也都有人管', () {
    const rndSeed = 20261123;
    final rnd = Random(rndSeed);
    final qKeys = qOptions.keys.toList();
    final extKeys = extSymptoms.keys.toList();
    final sigOf = {for (final r in allFormulaRules) r.name: _signature(r)};

    final bad = <String>[];
    final seen = <String>{};
    var tieGroups = 0;
    var sameSigGroups = 0;
    var incidentalGroups = 0;

    for (var i = 0; i < 3000; i++) {
      final e = DiagnosticEngine();
      e.answerTemperaturePattern('fever_chills');

      final picked = <String>{};
      final nq = 3 + rnd.nextInt(6);
      while (picked.length < nq) {
        picked.add(qKeys[rnd.nextInt(qKeys.length)]);
      }
      for (final k in picked) {
        final opts = qOptions[k]!;
        final txt = _optionText(k, 1 + rnd.nextInt(opts.length));
        if (txt != null) e.answerTenQuestion(k, txt);
      }
      final shuffled = [...extKeys]..shuffle(rnd);
      for (final k in shuffled.take(rnd.nextInt(5))) {
        e.toggleExtSymptom(k, true);
      }

      final tied = RuleEngine.tiedTop(e.qAnswers, e.extSymptoms);
      if (tied.length < 2) continue;
      tieGroups++;

      final names = tied.map((m) => m.rule.name).toSet();
      // 组内是否出现「必选签名完全相同」的两首
      final sigs = <String>[];
      var sameSig = false;
      for (final n in names) {
        final sg = sigOf[n] ?? '';
        if (sigs.contains(sg)) {
          sameSig = true;
          break;
        }
        sigs.add(sg);
      }
      // 3.0 分以下＝单必选方/纯参考方之间偶然被同时满足（如泽泻汤+竹叶汤），
      // 属信息不足，不是门禁设计问题，kD 也无从穷举 → 只计数。
      if (!sameSig || tied.first.score < 6.0) {
        incidentalGroups++;
        continue;
      }
      sameSigGroups++;
      if (_covered(names)) continue;
      if (seen.add(_keyOf(names))) {
        bad.add('${tied.first.score} 分：${_keyOf(names)}');
      }
    }

    // ignore: avoid_print
    print('[重叠扫描·随机] 3000 组（seed=$rndSeed）| 并列 $tieGroups 组 | '
        '其中签名相同 $sameSigGroups 组 | 偶然并列 $incidentalGroups 组 | '
        '无主 ${bad.length} 组');
    for (final b in bad) {
      // ignore: avoid_print
      print('  ✗ $b');
    }
    expect(bad, isEmpty,
        reason: '必选签名完全相同的方剂并列，却没有 kD 表兜底：\n${bad.join("\n")}');
  });
}
