// 外部金标准尝试：用倪师真实医案反过来考规则引擎——以及它为什么考不出来。
//
// 前两个验证（diagnose_quality / formula_rule_reachability）都是「系统自洽」，
// 只能证明它自己说得圆，不能证明它对。要证明「对」，理论上需要一份与规则表
// 无关的第三方答案——`assets/medical_cases/cases_table.md` 里 1450 行医案，
// 每行都有倪师实际开的方（第 7 列）和四诊原文（第 13 列）。
//
// 但实测这条路走不通，且原因本身就是最重要的结论：
//   370 行的方剂列能对上规则表方名，其中 133 行四诊空白、126 行可回填信息
//   不足 3 题，只剩 111 行可考。这 111 行里，正确方进入候选的是 0 行。
//
// 0 行不是引擎答错，是**数学必然**：规则引擎是合取门禁（rule_engine.dart:31，
// 每个 required ★ 必须全部命中），而规则的中位必选数是 2 项、22.7% 要求 ≥3 项；
// 医案原文用关键词只回填得出平均 3.5 题（11 题里）。信息量根本不够撑起门禁。
//
// 所以这个 test 不做「准确率断言」，它做归因：把每一行判成
//   A 门禁不过（正确方连候选都没进）
//   B 进了候选但没排到第一
//   C Top1 命中
// 并统计「最常缺哪个必选 key」——那才是规则表在真实场景里最脆的地方。
//
// 运行：flutter test test/engine_vs_cases_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/acupoint_repository.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/engine/diagnostic_engine.dart';
import 'package:nihaisha_app/engine/diagnostic_rules.dart';
import 'package:nihaisha_app/engine/formula_rules.dart';
import 'package:nihaisha_app/engine/rule_engine.dart';

/// 关键词 → canonical 选项号（1-based）。只有在原文里出现明确关键词时才回填，
/// 拿不准的一律不回填（引擎宁可少一个信号，不要错一个信号）。
const Map<String, List<(List<String>, int)>> _kRules = {
  // 六问大便
  'stool': [
    (['完谷不化', '下利清谷'], 7),
    (['脓血'], 6),
    (['色黑', '黑便'], 8),
    (['先硬后', '先干后'], 4),
    (['便秘', '不大便', '没大便', '无大便'], 2),
    (['水样', '水泻'], 5),
    (['拉肚子', '腹泻', '下利', '稀'], 3),
    (['大便正常', '每天一次', '一天一次'], 1),
  ],
  // 七问小便
  'urine': [
    (['清长'], 7),
    (['不利', '排不出', '尿不出来'], 5),
    (['夜尿'], 4),
    (['黄赤', '很黄', '深黄'], 6),
    (['频尿', '次数多'], 2),
    (['量少', '次数少'], 3),
    (['小便正常', '小便淡黄'], 1),
  ],
  // 三问渴饮（'不渴' 必须先匹配，否则会被 '渴' 吃掉）
  'thirst': [
    (['不渴', '没有口渴'], 1),
    (['大渴'], 7),
    (['消渴'], 6),
    (['口苦', '口干'], 5),
    (['渴', '想喝冷', '喜冷饮', '喜凉饮'], 2),
    (['想喝温', '喜温饮', '喜热饮'], 3),
  ],
  // 八问胃口
  'appetite': [
    (['恶心', '呕吐', '想吐'], 8),
    (['没有胃口', '胃口不好', '胃口差', '食不下', '食欲差', '纳差'], 2),
    (['胃口好', '胃口不错', '食欲好', '胃口很好'], 3),
    (['想吃冷', '喜冷食'], 5),
    (['想吃热', '喜热食'], 6),
  ],
  // 九问睡眠
  'sleep': [
    (['1-3点', '1~3点', '一点到三点', '1点到3点'], 2),
    (['3-5点', '3~5点', '三点到五点', '3点到5点'], 3),
    (['失眠', '睡不着', '不能睡'], 4),
    (['多梦', '易醒', '睡不好', '睡不安'], 5),
    (['嗜睡', '想睡', '但欲寐'], 6),
    (['一觉到天亮', '睡得很好', '睡眠好', '睡好', '通宵睡', '可通宵'], 1),
  ],
  // 十问精神
  'energy': [
    (['但欲寐', '昏昏沉沉'], 3),
    (['烦躁'], 4),
    (['气上撞'], 6),
    (['说话没力', '声音低'], 5),
    (['疲倦', '疲劳', '疲累', '容易累', '很累', '无力', '体力差'], 2),
  ],
  // 一问寒热：定经的入口，只在出现明确词时才回填
  'temperature': [
    (['上半身热下半身冷', '上热下寒', '头热脚冷'], 4),
    (['往来寒热', '忽冷忽热'], 3),
    (['全身怕冷', '畏寒'], 7),
    (['手脚冰冷', '手足冰冷', '手足冷', '手脚冰', '四肢冰冷', '四肢冷', '手脚很冰'], 6),
    (['手心脚心热', '五心烦热'], 2),
    (['手脚温热', '手足温', '四肢温', '手脚温'], 1),
  ],
};

/// 从一段四诊原文里按关键词回填出 {questionKey: 选项号}。
Map<String, int> parseCase(String text) {
  final out = <String, int>{};
  _kRules.forEach((key, rules) {
    for (final (kws, no) in rules) {
      if (kws.any(text.contains)) {
        out[key] = no;
        return;
      }
    }
  });
  return out;
}

/// 选项号 → 十问原文（引擎只认原文，见 _recordFlatAnswer 的 fail-closed）。
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

  test('真实医案回考：为什么规则引擎在原始医案上出不来正确方', () {
    final byName = {for (final r in allFormulaRules) r.name: r};
    final names = byName.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length)); // 最长优先，「四逆汤」不得吃掉「当归四逆汤」

    final raw = File('assets/medical_cases/cases_table.md').readAsStringSync();
    final lines = raw.split('\n').where((l) => l.trimLeft().startsWith('|')).toList();

    var total = 0, noFourDiag = 0, skippedThin = 0, considered = 0;
    var gateFail = 0, rankMiss = 0, hit1 = 0;
    final missingKeyCount = <String, int>{};
    final coverageList = <double>[];
    final answered = <int>[];

    for (final l in lines) {
      final cells = l.trim().replaceAll(RegExp(r'^\||\|$'), '').split('|');
      if (cells.length < 13) continue;
      final formulaCol = cells[6];
      final fourDiag = cells[12];

      String? truth;
      for (final n in names) {
        if (formulaCol.contains(n)) {
          truth = n;
          break;
        }
      }
      if (truth == null) continue;
      total++;
      if (fourDiag.trim().isEmpty) {
        noFourDiag++;
        continue;
      }

      final a = parseCase(fourDiag);
      if (a.length < 3) {
        skippedThin++;
        continue;
      }
      considered++;
      answered.add(a.length);

      final rule = byName[truth]!;
      // 门禁覆盖率：这条规则的必选 ★ 里，我们能从原文回填出来的占几成
      final need = rule.required.keys.toList();
      final have = need.where((k) {
        final ans = a[k];
        return ans != null && rule.required[k]!.contains(ans);
      }).toList();
      coverageList.add(need.isEmpty ? 1.0 : have.length / need.length);
      for (final k in need) {
        if (!have.contains(k)) missingKeyCount[k] = (missingKeyCount[k] ?? 0) + 1;
      }

      final e = DiagnosticEngine();
      a.forEach((k, v) {
        final txt = optionText(k, v);
        if (txt != null) e.answerTenQuestion(k, txt);
      });
      final r = e.diagnose();
      final cands = RuleEngine.evaluate(e.qAnswers, e.extSymptoms);
      final idx = cands.indexWhere((m) => m.rule.name == truth);
      if (idx < 0) {
        gateFail++;
      } else if (r != null && r.formula == truth) {
        hit1++;
      } else {
        rankMiss++;
      }
    }

    coverageList.sort();
    final medianCov =
        coverageList.isEmpty ? 0.0 : coverageList[coverageList.length ~/ 2];
    final avgAns = answered.isEmpty
        ? 0.0
        : answered.reduce((x, y) => x + y) / answered.length;
    final missSorted = missingKeyCount.entries.toList()
      ..sort((x, y) => y.value.compareTo(x.value));

    // ignore: avoid_print
    print('[医案回考] 方名可对上 $total 行：四诊空白 $noFourDiag、'
        '回填不足 3 题 $skippedThin、可考 $considered 行');
    // ignore: avoid_print
    print('[分诊] A 门禁不过（正确方没进候选）$gateFail | '
        'B 进候选但没排第一 $rankMiss | C Top1 命中 $hit1');
    // ignore: avoid_print
    print('[信息量] 原文平均只能回填 ${avgAns.toStringAsFixed(1)}/11 题；'
        '正确方必选信号覆盖率中位数 ${(medianCov * 100).toStringAsFixed(0)}%');
    // ignore: avoid_print
    print('[最常缺的必选 key Top10]');
    for (final e in missSorted.take(10)) {
      // ignore: avoid_print
      print('  ${e.key}: ${e.value} 行缺');
    }

    expect(considered, greaterThan(80), reason: '可考的行太少，归因没有意义');
    expect(gateFail + rankMiss + hit1, considered, reason: '三类必须覆盖全部可考行');
    // 关键结论：门禁不过占绝对多数，说明「考不出来」的瓶颈是信息量/门禁硬度，
    // 而不是排序算法。这条断言锁住这个归因，防止以后改坏了还以为提升了准确率。
    expect(gateFail / considered, greaterThan(0.8),
        reason: '原始医案上应是「门禁不过」占绝对多数；'
            '若这条不再成立，说明必选门禁被放松了，需重新评估 157/172 的自证口径');
  });
}
