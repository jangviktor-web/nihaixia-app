// 针灸问答准确性回归：用倪师医案里 361 条「针灸方案」做 ground truth。
//
//   A1 配穴可达：该案的针灸穴位是否以原文形式进了上下文
//   A2 穴位事实：GT 穴位是否有定位/手法可引用（穴位库命中）
//   A3 讲稿可达：针灸类提问是否真的拿到针灸讲稿片段
//
// 运行：flutter test test/llm_acu_accuracy_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/data/acupoint_repository.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/data/medical_case_data.dart';
import 'package:nihaisha_app/services/llm_service.dart';

const int _sampleSize = 30;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // 穴位表必须先加载：未加载时 allNames 为空（且不会污染缓存）
    await AcupointRepository.load();
  });

  // 带针灸方案、且**诊断非空**的医案。
  // 诊断为空的行（复诊记录）不能进评估集：提问会退化成「西医诊断我是，针灸怎么取穴」，
  // 检索无从下手，测出来的分数是评测集缺陷不是能力。
  const noise = ['效不更方', '作疗程中', '进步', '好转', '仍有', '不变', '同上'];
  List<MedicalCase> withAcu(List<MedicalCase> all) => all
      .where((c) => c.acupuncture.trim().length >= 2)
      .where((c) => c.acupuncture != '未提及')
      .where((c) => c.diagnosis.trim().length >= 2)
      .where((c) => !noise.any(c.diagnosis.contains))
      .toList();

  test('针灸意图识别：含针/灸词与只点穴位名都要认出来', () {
    expect(LlmService.isAcupunctureQuery('失眠针灸扎什么穴？'), isTrue);
    expect(LlmService.isAcupunctureQuery('足三里主治什么？'), isTrue,
        reason: '句子里一个针/灸字都没有，只能靠穴位名识别');
    expect(LlmService.isAcupunctureQuery('合谷能治牙痛吗'), isTrue);
    expect(LlmService.isAcupunctureQuery('桂枝汤证的辨证要点'), isFalse);
  });

  test('点名的穴位能取到穴位库里的事实', () {
    final pts = LlmService.retrieveAcupoints('足三里和合谷一起用行吗');
    // 穴位库正名带「穴」字（足三里穴 / 合谷穴），医案里写的是去穴形式，两者混用无碍。
    expect(pts.map((p) => p.name.replaceAll('穴', '')),
        containsAll(<String>['足三里', '合谷']));
    for (final p in pts) {
      expect(p.location, isNotEmpty, reason: '${p.name} 缺定位');
    }
    // 不在句里的穴位不该被误命中
    expect(LlmService.retrieveAcupoints('桂枝汤证的辨证要点'), isEmpty);
  });

  test('针灸讲稿必须在上下文里出现（不能被伤寒条文挤掉）', () async {
    final r = await LlmService.prepare('失眠针灸该扎哪些穴？');
    expect(r.classics.any((h) => h.source == 'zhenjiu'), isTrue,
        reason: '针灸讲稿只有 72 条，不限定来源就会被 394 条伤寒挤掉');
  });

  test('第三跳：症状 → 穴位 → 医案', () async {
    // 针灸讲稿按经络组织、不按病证，所以这类提问只能靠第三跳：
    // 症状词反查穴位库主治 → 穴位反查医案配穴。
    final r = await LlmService.prepare('带状疱疹后遗神经痛，针灸该取哪些穴？');
    expect(r.acupoints, isNotEmpty, reason: '症状没能反查到任何穴位');
    final names = r.acupoints.map((p) => p.name).toSet();
    expect(r.cases, isNotEmpty);
    expect(r.cases.any((c) => c.acupointNames.any(names.contains)), isTrue,
        reason: '穴位没能反查到用过这些穴的医案');
  });

  test('医案召回：诊断对上的案例必须排在前面', () async {
    // 「带状疱疹后遗神经痛」曾召回到 5 条全不相干的案（只沾了「痛」字），
    // #299（诊断就是带状疱疹，配穴公孙/内关/神门…）排在 6 名之外。
    final cases = await LlmService.retrieveCases(
      '带状疱疹后遗神经痛，针灸该取哪些穴？',
      max: 5,
    );
    expect(cases.map((c) => c.seq), contains(299));
    expect(cases.first.acupuncture, isNotEmpty);
  });

  test('医案针灸方案：ground truth 穴位必须进上下文', () async {
    await FormulaRepository.load();
    final all = await getAllMedicalCases();
    final pool = withAcu(all);
    expect(pool.length, greaterThan(150), reason: '带针灸方案且诊断非空的医案太少，评估不成立');

    final step = pool.length ~/ _sampleSize;
    final picked = <MedicalCase>[
      for (var i = 0; i < _sampleSize; i++) pool[i * step],
    ];

    var a1 = 0, a2 = 0, a3 = 0;
    final misses = <String>[];

    for (final c in picked) {
      // ground truth = 该案针灸方案里的穴位名
      final gt = LlmService.retrieveAcupoints(c.acupuncture, max: 4)
          .map((p) => p.name)
          .toList();
      if (gt.isEmpty) continue;

      final q = '西医诊断我是${c.diagnosis}，针灸该怎么取穴？';
      final r = await LlmService.prepare(q);
      final ctx = LlmService.buildContext(
        r.classics,
        q,
        formulas: r.formulas,
        cases: r.cases,
        acupoints: r.acupoints,
        diseaseBrief: r.diseaseBrief,
        stats: r.stats,
      );

      // 医案原文写「三阴交」，穴位库写「三阴交穴」，两种形态都算命中。
      final inCtx =
          gt.any((n) => ctx.contains(n) || ctx.contains(n.replaceAll('穴', '')));
      final hasFact = r.acupoints.isNotEmpty;
      if (inCtx) a1++;
      if (hasFact) a2++;
      if (r.classics.any((h) => h.source == 'zhenjiu')) a3++;
      if (!inCtx) misses.add('#${c.seq} ${c.diagnosis} → ${gt.join("/")}');
    }

    final r1 = a1 * 100 ~/ _sampleSize;
    final r2 = a2 * 100 ~/ _sampleSize;
    final r3 = a3 * 100 ~/ _sampleSize;
    // ignore: avoid_print
    print('A1 配穴可达 $r1% ｜ A2 穴位事实 $r2% ｜ A3 针灸讲稿 $r3%');
    if (misses.isNotEmpty) {
      // ignore: avoid_print
      print('配穴未进上下文：\n  ${misses.join('\n  ')}');
    }

    expect(r1, greaterThanOrEqualTo(70),
        reason: '配穴可达率过低：医案针灸列又没进上下文');
    expect(r2, greaterThanOrEqualTo(60),
        reason: '穴位事实命中过低：医案配穴没能反查到穴位库');
    expect(r3, greaterThanOrEqualTo(80),
        reason: '针灸讲稿可达率过低：seed 机制失效');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
