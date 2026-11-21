// 自查系统的「合理性」检验——不需要金标准，只看它作为判别器是否成立。
//
// 四类判据：
//   1. 确定性：同一组输入重复跑必须给同一结论（否则「依据」无从谈起）；
//   2. 区分度：随机输入下输出的方剂不能坍缩到少数几个（坍缩=按经套方）；
//   3. 覆盖率：多少输入能给出结果，多少落「信息不足」；
//   4. 方向敏感性：只改寒热总纲一项，结论应当改变（不该对方向不敏感）。
//
// 这四项都不依赖「谁对」，测的是系统内部是否自洽。真正的辨证准确率
// 要靠医案金标准对照（见 llm_case_gt_recall_test.dart 与后续映射管线）。
//
// 运行：flutter test test/diagnose_quality_test.dart
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/acupoint_repository.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/engine/diagnostic_engine.dart';
import 'package:nihaisha_app/engine/diagnostic_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await FormulaRepository.load();
    await AcupointRepository.load();
  });

  /// 按种子生成一组随机但完整的答案（每题随机选一项）。
  DiagnosticEngine randomEngine(Random rnd) {
    final e = DiagnosticEngine();
    final temps = DiagnosticRules.temperaturePatterns;
    e.answerTemperaturePattern(temps[rnd.nextInt(temps.length)].key);
    for (final q in e.getTenQuestions(defaultGender: 'male')) {
      if (q.options.isEmpty) continue;
      e.answerTenQuestion(q.key, q.options[rnd.nextInt(q.options.length)]);
    }
    e.answerTonguePulse();
    return e;
  }

  test('确定性：同输入重复 30 次必须同结论', () {
    final base = DiagnosticEngine();
    final qs = base.getTenQuestions(defaultGender: 'male');
    base.answerTemperaturePattern('chills_no_fever');
    for (final q in qs) {
      if (q.options.isNotEmpty) base.answerTenQuestion(q.key, q.options.first);
    }
    final first = base.diagnose();
    final sig = first == null ? 'null' : '${first.meridian}|${first.pattern}|${first.formula}';

    for (var i = 0; i < 30; i++) {
      final again = DiagnosticEngine();
      again.answerTemperaturePattern('chills_no_fever');
      for (final q in qs) {
        if (q.options.isNotEmpty) again.answerTenQuestion(q.key, q.options.first);
      }
      final r = again.diagnose();
      final s = r == null ? 'null' : '${r.meridian}|${r.pattern}|${r.formula}';
      expect(s, sig, reason: '第 $i 次结果与首次不一致：规则引擎本应是确定性的');
    }
    // ignore: avoid_print
    print('[确定性] 30 次一致 -> $sig');
  });

  test('区分度与覆盖率：随机 500 组输入的方剂分布', () {
    final rnd = Random(20261121);
    final dist = <String, int>{};
    final meridianDist = <String, int>{};
    var nulls = 0;
    const n = 500;

    for (var i = 0; i < n; i++) {
      final e = randomEngine(rnd);
      final r = e.diagnose();
      if (r == null) {
        nulls++;
        continue;
      }
      final f = r.formula.isEmpty ? '（空方）' : r.formula;
      dist[f] = (dist[f] ?? 0) + 1;
      meridianDist[r.meridian] = (meridianDist[r.meridian] ?? 0) + 1;
    }

    final sorted = dist.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.isEmpty ? 0 : sorted.first.value;
    final answered = n - nulls;

    // ignore: avoid_print
    print('[区分度] 出结果 $answered/$n，null $nulls，'
        '不同方剂 ${sorted.length} 个，最高频 ${sorted.isEmpty ? "-" : sorted.first.key} 占 $top/${answered}');
    // ignore: avoid_print
    print('[六经分布] $meridianDist');
    // ignore: avoid_print
    print('[Top10] ${sorted.take(10).map((e) => "${e.key}:${e.value}").join("  ")}');

    expect(nulls / n, lessThan(0.5),
        reason: '超过半数随机输入给不出结果，说明必选门禁过严或定经覆盖不足');
    expect(sorted.length, greaterThan(20),
        reason: '随机输入只能出不到 20 种方，说明规则把大量输入坍缩到少数方');
    if (answered > 0) {
      expect(top / answered, lessThan(0.45),
          reason: '单一方剂占掉近半输入，几乎没有区分度');
    }
  });

  test('方向敏感性：换寒热总纲，结论应当跟着变', () {
    // 同一组十问答案，只换寒热总纲，看结论变化率。
    // 用随机答案而不是「全选第一项」：后者是一组全「正常」的极端输入，
    // 规则引擎会因「必选最少的方命中」而出一个不相干的方，测不出方向的作用。
    final rnd = Random(7);
    var changed = 0;
    var total = 0;
    final samples = <String>[];

    for (var i = 0; i < 20; i++) {
      final fixed = <String, String>{};
      for (final q in DiagnosticEngine().getTenQuestions(defaultGender: 'male')) {
        if (q.options.isNotEmpty) fixed[q.key] = q.options[rnd.nextInt(q.options.length)];
      }
      final outcomes = <String, String>{};
      for (final t in DiagnosticRules.temperaturePatterns) {
        final e = DiagnosticEngine();
        e.answerTemperaturePattern(t.key);
        fixed.forEach(e.answerTenQuestion);
        e.answerTonguePulse();
        final r = e.diagnose();
        outcomes[t.label] = r == null ? 'null' : '${r.meridian}|${r.formula}';
      }
      total++;
      if (outcomes.values.toSet().length > 1) changed++;
      if (i < 3) samples.add(outcomes.values.toSet().join(' / '));
    }

    // ignore: avoid_print
    print('[方向敏感性] 换总纲后结论改变：$changed/$total 组');
    // ignore: avoid_print
    print('[样例] $samples');

    expect(changed, greaterThan(0),
        reason: '七种寒热总纲在任何答案组合下都给出同一结论，'
            '说明第一步「先分阴阳」没有进入主路径，只是 UI 上的摆设');
  });
}
