// 症状自查结果页：结论必须「可核对」。
//
// 这三条是把「十问自查 vs 倪师 AI 谁更准」从口头争论变成可操作判定的前提：
// 1. 不再以「置信度 xx%」呈现——那个数字只是勾选条数的映射，不是准确率，
//    写成百分比会被读成「九成把握」；
// 2. 每条依据可点开，看到它在规则表里到底决定哪些方的取舍；
// 3. 结果页给出倪师同类医案，用户能拿真实验案对照。
//
// 直接构造 SymptomResultSheet 而不是走完十问勾选：结果页是独立 UI 件，
// 用它自己的输入测它自己的行为，改动一处不必连带重算勾选路径。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/data/medical_case_data.dart';
import 'package:nihaisha_app/models/diagnosis.dart';
import 'package:nihaisha_app/screens/symptom_result_sheet.dart';

void main() {
  setUpAll(() async {
    await FormulaRepository.load();
  });

  DiagnosisResult sample() => DiagnosisResult(
        meridian: '少阴',
        pattern: '四逆汤证',
        formula: '四逆汤',
        recommendedFormulas: const ['四逆汤'],
        explanation: '但欲寐、四肢厥冷、下利清谷，少阴阳衰，当温之。',
        // 用一个很高的值：即使内部算出 0.95，界面也不该显示成百分比。
        confidence: 0.95,
        matchedSymptoms: const ['手脚冰冷', '不渴', '便秘，好几天一次'],
      );

  test('依据反查：选项文本能定位到把它当必选信号的方', () {
    final (required, reference) = SymptomResultSheet.evidenceOf('手脚冰冷');
    // 「手脚冰冷」在规则表里是四逆汤一系的必选信号（kQ1=⑥）。
    expect(required, contains('四逆汤'),
        reason: '手脚冰冷应是四逆汤的必选(★)信号');
    expect(required, isNotEmpty);
    // 一条属性不成立时不该被算成必选。
    final (req2, _) = SymptomResultSheet.evidenceOf('睡觉出汗');
    expect(req2, isNot(contains('四逆汤')));
    // 参考信号与必选信号不重叠统计。
    for (final n in reference) {
      expect(required, isNot(contains(n)),
          reason: '$n 同时被判为必选与参考，归类有误');
    }
  });

  testWidgets('结果页显示依据条数、依据可点开、同类医案可见', (tester) async {
    final r = sample();
    // 医案检索要读 1.2MB asset，属于真 IO：在 testWidgets 的假时钟里直接
    // await 会一直停在 FutureBuilder 的 waiting 态。用 runAsync 真跑一次，
    // 再把已完成的 future 注入 UI——测的是渲染，不是 IO 调度。
    final cases = await tester.runAsync(
          () => SymptomResultSheet.loadRelated(r),
        ) ??
        const <MedicalCase>[];
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SymptomResultSheet(
          result: r,
          relatedCases: Future.value(cases),
          onAskAi: () {},
        ),
      ),
    ));
    await tester.pumpAndSettle();

    // ① 置信度百分比不再出现，改口径为「依据 N 项」并附说明。
    expect(find.textContaining('置信度'), findsNothing,
        reason: '置信度百分比会把「信息量」误读成「准确率」');
    expect(find.textContaining('依据 3 项'), findsOneWidget);
    expect(find.textContaining('不是准确率'), findsOneWidget);

    // ② 依据 chips 可点开，给出该项在规则里的角色。
    final chip = find.widgetWithText(ActionChip, '手脚冰冷');
    expect(chip, findsOneWidget, reason: '命中症状应以可点击 chip 呈现');
    await tester.tap(chip);
    await tester.pumpAndSettle();
    expect(find.textContaining('必选'), findsWidgets,
        reason: '「手脚冰冷」应显示为若干方的必选信号');
    await tester.tap(find.text('知道了'));
    await tester.pumpAndSettle();

    // ③ 同类医案区块：有则列案例，无则明确说明语料缺同类记录。
    expect(find.text('倪师同类医案'), findsOneWidget);
    final hasCase = find.textContaining('#').evaluate().isNotEmpty;
    final hasEmptyHint =
        find.textContaining('没找到症状相近的医案').evaluate().isNotEmpty;
    expect(hasCase || hasEmptyHint, isTrue,
        reason: '医案区块必须给出结果或明确说明没有，不允许空白');
  });
}
