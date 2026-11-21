// 兼症信号覆盖：规则表要的每个 ext 必选 key，自测页必须有勾选入口。
//
// 背景：规则表达标 ≠ 自测页可达。`jaundice`/`cough_wheeze`/`neck_stiff`/`edema`
// 这 4 个 key 原本只由聊天页的跟进问诊派生，自测页的兼症清单里没有入口，
// 于是 13 条规则在 App 里永远出不来（引擎测试直接 toggleExtSymptom，绕过了界面）。
//
// 运行：flutter test test/ext_signal_coverage_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/acupoint_repository.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/engine/formula_rules.dart';
import 'package:nihaisha_app/screens/symptom_check_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await FormulaRepository.load();
    await AcupointRepository.load();
  });

  test('规则表用到的 ext 必选 key，自测页都要有勾选入口', () {
    final uiKeys = <String>{
      for (final g in kSymptomExtGroups.values)
        for (final (k, _) in g) k,
    };
    expect(uiKeys.length, uiKeys.toSet().length, reason: '兼症 key 不应重复');

    final missing = <String>{};
    final affected = <String>[];
    for (final r in allFormulaRules) {
      final gaps = r.extRequired.where((k) => !uiKeys.contains(k)).toList();
      if (gaps.isEmpty) continue;
      missing.addAll(gaps);
      affected.add('${r.name}(${gaps.join(",")})');
    }

    // ignore: avoid_print
    print('[兼症入口] 自测页可勾 ${uiKeys.length} 项 | 规则要而界面缺 '
        '${missing.length} 个 key | 受影响规则 ${affected.length} 条');
    if (missing.isNotEmpty) {
      // ignore: avoid_print
      print('  缺: ${missing.join("、")}');
      // ignore: avoid_print
      print('  受影响: ${affected.join("、")}');
    }
    expect(missing, isEmpty,
        reason: '这些 key 界面上勾不到，对应规则在 App 里永远不可达');
  });

  test('兼症 key 必须都在 extSymptoms 里有中文名（结果页要显示）', () {
    final uiKeys = <String>{
      for (final g in kSymptomExtGroups.values)
        for (final (k, _) in g) k,
    };
    final noLabel = uiKeys.where((k) => !extSymptoms.containsKey(k)).toList();
    expect(noLabel, isEmpty, reason: '缺中文名: ${noLabel.join("、")}');
  });
}
