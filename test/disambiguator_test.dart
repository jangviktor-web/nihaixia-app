// 鉴别追问（kD1–kD7）：规则表 ★ 必选相撞的方组，答一句追问后必须能分出本方。
//
// 覆盖 formula_rule_reachability_test 里「被抢」的那批方：那些方按自己的 ★ 必选
// 输入时引擎分不开（同分平局），本测试验证「补问一句 → 命中本方」。
// 同时校验数据自洽：每首方的 reference[该 kD key] 必须含它在 kDisambiguators 里登记的选项号。
//
// 运行：flutter test test/disambiguator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/acupoint_repository.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/engine/diagnostic_engine.dart';
import 'package:nihaisha_app/engine/diagnostic_rules.dart';
import 'package:nihaisha_app/engine/formula_rules.dart';
import 'package:nihaisha_app/engine/rule_engine.dart';

String? optionText(String qKey, int oneBased) {
  final i = oneBased - 1;
  if (i < 0) return null;
  if (qKey == kQ12) {
    final o = DiagnosticRules.vomitTypeQuestion.options;
    return i < o.length ? o[i] : null;
  }
  for (final q in DiagnosticRules.tenQuestions) {
    if (q.key != qKey) continue;
    return i < q.options.length ? q.options[i] : null;
  }
  return null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await FormulaRepository.load();
    await AcupointRepository.load();
  });

  test('数据自洽：每首方的 reference 必须登记它在鉴别表里的选项号', () {
    final bad = <String>[];
    for (final d in kDisambiguators) {
      d.members.forEach((name, no) {
        final rule = allFormulaRules.where((r) => r.name == name).toList();
        if (rule.isEmpty) {
          bad.add('$name 不在规则表里（${d.key}）');
          return;
        }
        // 同名重复定义（猪苓汤两处）只要有一处登记即可
        if (!rule.any((r) => r.reference[d.key]?.contains(no) ?? false)) {
          bad.add('$name 的 reference 缺 ${d.key}:[$no]');
        }
      });
    }
    expect(bad, isEmpty, reason: bad.join('；'));
    // 每张表的选项都必须在 qOptions 里有定义，否则引擎收不到答案
    for (final d in kDisambiguators) {
      expect(qOptions[d.key], isNotNull, reason: '${d.key} 缺选项表');
      for (final no in d.members.values) {
        expect(no, lessThanOrEqualTo(qOptions[d.key]!.length),
            reason: '${d.key} 选项号 $no 越界');
      }
    }
  });

  test('补问一句后，14 条被抢方都能命中本方', () {
    var tried = 0;
    final fail = <String>[];

    for (final d in kDisambiguators) {
      d.members.forEach((name, no) {
        final rule = allFormulaRules.firstWhere((r) => r.name == name);
        final e = DiagnosticEngine();
        e.answerTemperaturePattern('fever_chills');
        // 1) 按本方自己的 ★ 必选构造输入
        var ok = true;
        for (final entry in rule.required.entries) {
          for (final n in entry.value) {
            final txt = optionText(entry.key, n);
            if (txt == null) {
              ok = false;
              break;
            }
            e.answerTenQuestion(entry.key, txt);
          }
          if (!ok) break;
        }
        if (!ok) return; // 该方另有数据问题，由 reachability 测试负责
        for (final key in rule.extRequired) {
          e.toggleExtSymptom(key, true);
        }
        // 纯参考方（无 required）没有 ★ 门禁，只靠 extReference 兜底入选，
        // 必须把参考兼症也勾上，否则测出来的「未触发」是测试漏配。
        if (rule.required.isEmpty) {
          for (final key in rule.extReference) {
            e.toggleExtSymptom(key, true);
          }
        }

        // 2) 应当触发同一张鉴别表；若本方靠 ext/更严的 ★ 已经单独出线，则不需要问
        final pending = e.pendingDisambiguator();
        if (pending == null) {
          final r0 = e.diagnose();
          tried++;
          if (r0 == null ||
              !(r0.formula == name || r0.recommendedFormulas.contains(name))) {
            fail.add('$name 既未触发 ${d.key}，也没直接出本方（实得 ${r0?.formula ?? "(空)"}）');
          }
          return;
        }
        if (pending.key != d.key) {
          fail.add('$name 触发了别的表（实得 ${pending.key}，应为 ${d.key}）');
          return;
        }

        // 3) 答上本方对应的选项
        e.answerTenQuestion(d.key, qOptions[d.key]![no - 1]);
        final r = e.diagnose();
        tried++;
        if (r == null ||
            !(r.formula == name || r.recommendedFormulas.contains(name))) {
          fail.add('$name 答完追问仍得「${r?.formula ?? "(空)"}」');
        }
        // 4) 不能二次追问
        if (e.pendingDisambiguator() != null) {
          fail.add('$name 答完仍在平局，会二次追问');
        }
      });
    }

    // ignore: avoid_print
    print('[鉴别追问] 可考 $tried 首 | 失败 ${fail.length} 首');
    if (fail.isNotEmpty) {
      // ignore: avoid_print
      print(fail.join('\n'));
    }
    expect(tried, greaterThanOrEqualTo(14), reason: '参与测试的方太少');
    expect(fail, isEmpty, reason: fail.join('；'));
  });

  test('kD9 真实平局：越婢汤 ⇄ 杏子汤、麻黄附子汤 ⇄ 甘草麻黄汤', () {
    // 上一条测试是「按本方自己的 ★ 构造输入」，多数情况下并不触发平局；
    // 这里刻意构造「两首同时满足且同分」的真实场景，验证追问真的会弹出、真能定方。
    final cases = <String, (Map<String, int>, Set<String>, String, int)>{
      // 脉浮 + 不渴 + 出汗 + 浮肿 → 越婢汤（汗出）与杏子汤（脉浮）同为 9.0
      '越婢汤': (
        {kQ4: 4, kQ3: 1, kQ2: 1},
        {'edema'},
        '越婢汤',
        1,
      ),
      // 脉沉 + 但欲寐 + 不渴 + 小便不利 + 浮肿 → 麻黄附子汤与甘草麻黄汤同为 9.0
      '甘草麻黄汤': (
        {kQ2: 2, kQ10: 3, kQ3: 1, kQ7: 5},
        {'edema'},
        '甘草麻黄汤',
        2,
      ),
    };

    for (final e0 in cases.entries) {
      final (q, ext, want, kdNo) = e0.value;
      final e = DiagnosticEngine();
      e.answerTemperaturePattern('fever_chills');
      q.forEach((k, n) {
        final t = optionText(k, n);
        expect(t, isNotNull, reason: '$k[$n] 无对应选项');
        e.answerTenQuestion(k, t!);
      });
      for (final x in ext) {
        e.toggleExtSymptom(x, true);
      }

      final tied = RuleEngine.tiedTop(e.qAnswers, e.extSymptoms);
      expect(tied.length, greaterThanOrEqualTo(2),
          reason: '${e0.key} 场景应形成平局：${tied.map((m) => m.rule.name)}');

      final pending = e.pendingDisambiguator();
      expect(pending?.key, kD9, reason: '${e0.key} 场景应触发 kD9');

      e.answerTenQuestion(kD9, qOptions[kD9]![kdNo - 1]);
      final r = e.diagnose();
      expect(r?.formula, want, reason: '答完 kD9 应定为 $want');
      expect(e.pendingDisambiguator(), isNull, reason: '不应二次追问');
    }
  });

  test('kD12 真实平局：甘草干姜汤 ⇄ 干姜附子汤（阳虚烦躁同源）', () {
    final e = DiagnosticEngine();
    e.answerTemperaturePattern('fever_chills');
    // 手脚冰冷 + 昼日烦躁夜安静 + 吐逆 → 两首都是 2 必选 6.0
    for (final (k, n) in [(kQ1, 6), (kQ12, 4)]) {
      final t = optionText(k, n);
      expect(t, isNotNull, reason: '$k[$n] 无对应选项');
      e.answerTenQuestion(k, t!);
    }
    e.toggleExtSymptom('day_vex_night_calm', true);

    final tied = RuleEngine.tiedTop(e.qAnswers, e.extSymptoms);
    final names = tied.map((m) => m.rule.name).toSet();
    expect(names.contains('甘草干姜汤'), isTrue, reason: '并列应含甘草干姜汤：$names');
    expect(names.contains('干姜附子汤'), isTrue, reason: '并列应含干姜附子汤：$names');

    expect(e.pendingDisambiguator()?.key, kD12);
    e.answerTenQuestion(kD12, qOptions[kD12]![0]); // 误汗后厥冷咽干烦躁而吐
    expect(e.diagnose()?.formula, '甘草干姜汤');
  });
}
