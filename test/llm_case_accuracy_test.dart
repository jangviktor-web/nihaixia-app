// 「问倪师AI」解答准确性回归：用倪师医案做 ground truth，量「正确答案的材料
// 能否进入上下文」。这是回答准确性的**必要条件**——材料进不去，模型再强也答不准。
//
// 判据只看可达性（确定性、不联网、可重复）：
//   P1 讲稿可达：ground truth 方剂是否出现在【讲义片段】或【方剂清单】
//   P2 医案可达：ground truth 方剂是否出现在命中的医案里
//   P3 病机可达：医案病机的关键词片段是否出现在上下文
//
// 基线（2026-11-07，优化前 → 优化后，60 条样本）：P1 16% → 92%。
// 运行：flutter test test/llm_case_accuracy_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/data/medical_case_data.dart';
import 'package:nihaisha_app/services/llm_service.dart';

const int _sampleSize = 60;

/// 阈值比实测低 5–8 个百分点：允许合理抖动，但不允许出现「材料又进不去」的退步。
const int _minClassicRate = 85;
const int _minCaseRate = 80;
const int _minMechanismRate = 85;

bool _hit(String text, List<String> needles) =>
    needles.any((n) => n.isNotEmpty && text.contains(n));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('症状型提问：ground truth 材料必须进上下文', () async {
    await FormulaRepository.load();
    final all = await getAllMedicalCases();

    // 「效不更方 / 作疗程中 / 病人进步许多」这类是复诊记录，不是诊断，排除。
    const noise = ['效不更方', '作疗程中', '进步', '好转', '仍有', '不变', '同上'];
    final pool = all.where((c) {
      if (c.diagnosis.trim().length < 2) return false;
      if (noise.any(c.diagnosis.contains)) return false;
      return c.formulaNames.isNotEmpty;
    }).toList();
    expect(pool.length, greaterThan(100),
        reason: '可用医案太少，评估集不成立');

    final step = pool.length ~/ _sampleSize;
    final picked = <MedicalCase>[
      for (var i = 0; i < _sampleSize; i++) pool[i * step],
    ];

    var p1 = 0, p2 = 0, p3 = 0;
    final misses = <String>[];

    for (final c in picked) {
      final gt = c.formulaNames.take(2).toList();
      final q = '西医诊断我是${c.diagnosis}，中医该怎么辨、用什么方？';
      final r = await LlmService.prepare(q);

      final classicText =
          r.classics.map((h) => '${h.title}${h.snippet}').join('\n');
      final inClassic =
          _hit(classicText, gt) || _hit(r.formulas.join('、'), gt);
      final caseText = r.cases
          .map((e) => '${e.diagnosis}${e.mechanism}${e.formula}')
          .join('\n');
      final inCase = _hit(caseText, gt);

      // 病机关键术语：抽 2–4 字片段，要求至少 2 个能落地
      final mech = c.mechanism;
      final bits = <String>{
        for (var len = 4; len >= 2; len--)
          for (var i = 0; i + len <= mech.length; i++)
            mech.substring(i, i + len),
      }.take(8).toList();
      final ctx = '$classicText\n${r.formulas.join('、')}\n$caseText'
          '\n${r.diseaseBrief}';
      final mechHits = bits.where((b) => ctx.contains(b)).length;

      if (inClassic) p1++;
      if (inCase) p2++;
      if (mechHits >= 2) p3++;
      if (!inClassic) {
        misses.add('#${c.seq} ${c.diagnosis} → ${gt.join('/')}');
      }
    }

    final r1 = p1 * 100 ~/ _sampleSize;
    final r2 = p2 * 100 ~/ _sampleSize;
    final r3 = p3 * 100 ~/ _sampleSize;
    // ignore: avoid_print
    print('P1 讲稿可达 $r1% ｜ P2 医案可达 $r2% ｜ P3 病机可达 $r3%');
    if (misses.isNotEmpty) {
      // ignore: avoid_print
      print('讲稿未命中：\n  ${misses.join('\n  ')}');
    }

    expect(r1, greaterThanOrEqualTo(_minClassicRate),
        reason: '讲稿可达率跌破 $_minClassicRate%：二跳检索断开或关键词过滤过严');
    expect(r2, greaterThanOrEqualTo(_minCaseRate),
        reason: '医案可达率跌破 $_minCaseRate%：医案检索召回退化');
    expect(r3, greaterThanOrEqualTo(_minMechanismRate),
        reason: '病机可达率跌破 $_minMechanismRate%：上下文与医案字段脱节');
  }, timeout: const Timeout(Duration(minutes: 10)));

  test('persona 必须禁止复述医案剂量（安全性硬规则）', () async {
    final persona = await LlmService.loadPersona();
    expect(persona, contains('禁止复述医案里的剂量'),
        reason: '上下文会带出医案剂量，不禁止复述会诱导患者照抄');
    expect(persona, contains('禁止把【讲义片段】'),
        reason: '不禁止罗列，模型会把检索材料当答案整串倒出来');
    expect(persona, contains('按固定五步走'),
        reason: '症状型提问需要有确定的推理顺序');
  });
}
