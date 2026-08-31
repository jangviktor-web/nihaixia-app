import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/services/solar_term_service.dart';

void main() {
  group('节气服务', () {
    test('2026-08-31 处于处暑、距白露为正', () {
      final info = getCurrentSolarTerm(DateTime(2026, 8, 31, 12, 0, 0));
      expect(info.currentTerm, '处暑');
      expect(info.nextTerm, '白露');
      expect(info.daysLeft, greaterThan(0));
      expect(info.daysLeft, lessThan(30));
      expect(info.daysInto, greaterThan(0));
      expect(info.healthTip, isNotEmpty);
      // 处暑属秋，映射药性应为「平」
      expect(info.seasonNature, '平');
    });

    test('冬至为冬，映射药性应为温', () {
      final info = getCurrentSolarTerm(DateTime(2026, 12, 22, 12, 0, 0));
      expect(info.currentTerm, '冬至');
      expect(info.seasonNature, '温');
    });

    test('立春为春，映射药性应为温', () {
      final info = getCurrentSolarTerm(DateTime(2026, 2, 5, 12, 0, 0));
      expect(info.currentTerm, '立春');
      expect(info.seasonNature, '温');
    });
  });
}
