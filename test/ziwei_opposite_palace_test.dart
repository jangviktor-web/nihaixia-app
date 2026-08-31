import 'package:flutter_test/flutter_test.dart';
import 'package:ziwei_core/ziwei_core.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart';
import 'package:nihaisha_app/services/ziwei_interpretation.dart';

/// 验证「大运无主星 → 附对宫解析」：当某大限宫无主星时，[summarizeDecades]
/// 输出应含「对宫」字样，且对宫主星名出现在该行文案中。
void main() {
  group('大运无主星·对宫解析', () {
    /// 在若干真实生辰中找出一个大限宫（空宫）命盘，用于稳定断言。
    ZiweiChart _findEmptyPalaceChart() {
      for (int y = 1955; y <= 2005; y += 5) {
        for (final m in const [1, 4, 7, 10]) {
          final chart = calculateZiweiChart(
            solar: DateTime(y, m, 15, 12, 0),
            gender: Gender.male,
            useTrueSolarTime: false,
          );
          if (summarizeDecades(chart).any((s) => s.contains('对宫'))) {
            return chart;
          }
        }
      }
      // 兜底：再遍历若干时辰/性别组合
      for (int y = 1962; y <= 1998; y += 3) {
        for (final g in const [Gender.male, Gender.female]) {
          final chart = calculateZiweiChart(
            solar: DateTime(y, 6, 8, 6, 0),
            gender: g,
            useTrueSolarTime: false,
          );
          if (summarizeDecades(chart).any((s) => s.contains('对宫'))) {
            return chart;
          }
        }
      }
      throw StateError('测试样本未命中大限无主星命盘，请扩充候选生辰');
    }

    test('空宫大限的逐限评语含「对宫」且对宫主星名出现', () {
      final chart = _findEmptyPalaceChart();
      final lines = summarizeDecades(chart);
      final idx = lines.indexWhere((s) => s.contains('对宫'));
      expect(idx, greaterThanOrEqualTo(0),
          reason: '应能找到含「对宫」的逐限评语');

      // 找到该大限对应的空宫，核对其对宫主星名确实出现在本行
      final decade = chart.decades[idx];
      final palace =
          chart.palaces.firstWhere((p) => p.roleLabel == decade.roleLabel);
      expect(palace.majors.isEmpty, isTrue,
          reason: '含「对宫」的大限宫应为空宫');

      final opp = chart.palaces[(palace.index + 6) % 12];
      expect(opp.majors.isNotEmpty, isTrue,
          reason: '对宫解析仅在「对宫有主星」时列出星名');
      for (final s in opp.majors) {
        expect(lines[idx], contains(s.label),
            reason: '对宫主星「${s.label}」应出现在评语中');
      }
    });

    test('有主星的大限不会误加对宫提示', () {
      final chart = calculateZiweiChart(
        solar: DateTime(1990, 6, 15, 0, 0),
        gender: Gender.male,
        useTrueSolarTime: false,
      );
      // 仅校验：含主星的大限行不应以对宫总结尾（除非它恰为空宫）
      for (var i = 0; i < chart.decades.length; i++) {
        final palace = chart.palaces
            .firstWhere((p) => p.roleLabel == chart.decades[i].roleLabel);
        final line = summarizeDecades(chart)[i];
        if (palace.majors.isNotEmpty) {
          expect(line, isNot(contains('（对宫')),
              reason: '有主星大限不应追加对宫提示');
        }
      }
    });
  });
}
