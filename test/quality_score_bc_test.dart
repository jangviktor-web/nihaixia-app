import 'package:flutter_test/flutter_test.dart';
import 'quality_score_bc.dart';

// 质量评分门禁：
// - 综合分 < 90 视为质量不达标，测试失败（阻断低质量交付）。
// - 任一关键维度(oracle 类 B1/B2/C1/C2/C4) 得分 < 95 也判失败。
void main() {
  group('B/C 质量评分', () {
    test('功能 B（流月/流日）质量评分 ≥ 90', () {
      final r = scoreFeatureB();
      // ignore: avoid_print
      print('\n${r.report()}');
      expect(r.weightedScore, greaterThanOrEqualTo(90),
          reason: '功能 B 综合质量分需 ≥ 90');
      for (final d in r.dims.where((d) => ['B1', 'B2'].contains(d.id))) {
        expect(d.score, greaterThanOrEqualTo(95.0),
            reason: '关键 oracle 维度 ${d.id} 得分需 ≥ 95');
      }
    });

    test('功能 C（每日黄历）质量评分 ≥ 90', () {
      final r = scoreFeatureC();
      // ignore: avoid_print
      print('\n${r.report()}');
      expect(r.weightedScore, greaterThanOrEqualTo(90),
          reason: '功能 C 综合质量分需 ≥ 90');
      for (final d in r.dims.where((d) => ['C1', 'C2', 'C4'].contains(d.id))) {
        expect(d.score, greaterThanOrEqualTo(95.0),
            reason: '关键 oracle 维度 ${d.id} 得分需 ≥ 95');
      }
    });

    test('B 与 C 综合评分汇总', () {
      final b = scoreFeatureB();
      final c = scoreFeatureC();
      final overall = ((b.weightedScore + c.weightedScore) / 2).round();
      // ignore: avoid_print
      print('\n========== 质量评分汇总 ==========');
      // ignore: avoid_print
      print('功能 B（流月/流日）：${b.weightedScore}分(${b.grade})，样本=${b.samples}');
      // ignore: avoid_print
      print('功能 C（每日黄历）：${c.weightedScore}分(${c.grade})，样本=${c.samples}');
      // ignore: avoid_print
      print('综合平均分：$overall 分');
      // ignore: avoid_print
      print('=================================\n');
      expect(overall, greaterThanOrEqualTo(90));
    });
  });
}
