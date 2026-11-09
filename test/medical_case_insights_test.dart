import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/data/medical_case_data.dart';
import 'package:nihaisha_app/screens/medical_case_insights_screen.dart';

/// 医案洞察页的统计跑在 isolate 里（全量提取 ~3.4s，不能占主线程），
/// 因此候选表由页面传入，isolate 内拿不到仓库、无法归一。
/// 回归点：传进去的必须是「候选 → 正名」映射，否则
/// ① 异写抽取不到（漏计）② 短正名截胡（白虎人参汤 → 人参汤，串方）
/// ③ 同方两种写法各占一行（频次被拆散）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, String> buildMap() => <String, String>{
        for (final f in FormulaRepository.getAll()) f.name: f.name,
        for (final a in FormulaRepository.aliasNames)
          a: FormulaRepository.getByName(a)?.name ?? a,
      };

  test('isolate 分支：异写与正名合并计数，且不串方', () async {
    await FormulaRepository.load();
    final stats = computeMedicalCaseInsights(
      [
        MedicalCase(seq: 1, formula: '黄耆建中汤'),
        MedicalCase(seq: 2, formula: '黄芪建中汤'),
        MedicalCase(seq: 3, formula: '白虎人参汤'),
        MedicalCase(seq: 4, formula: '桂枝龙骨牡蛎汤'),
      ],
      formulaCandidates: buildMap(),
      herbCandidates: const <String>[],
    );
    final m = {for (final f in stats.formulas) f.name: f.count};
    expect(m['黄芪建中汤'], 2, reason: '异写与正名应计到同一个方剂');
    expect(m['白虎加人参汤'], 1);
    expect(m['桂枝加龙骨牡蛎汤'], 1);
    expect(m.keys, isNot(contains('人参汤')), reason: '不应被短正名截胡');
    expect(m.keys, isNot(contains('牡蛎汤')), reason: '不应被短正名截胡');
    expect(stats.withFormula, 4, reason: '四条医案都应算作「有方剂」');
  });

  test('正名写法统计不变（无回归）', () async {
    await FormulaRepository.load();
    final stats = computeMedicalCaseInsights(
      [MedicalCase(seq: 1, formula: '桂枝汤')],
      formulaCandidates: buildMap(),
      herbCandidates: const <String>[],
    );
    expect({for (final f in stats.formulas) f.name: f.count}['桂枝汤'], 1);
  });
}
