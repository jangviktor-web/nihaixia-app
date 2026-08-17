import 'package:flutter_test/flutter_test.dart';
import 'package:ziwei_core/ziwei_core.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart';

void main() {
  group('2000-08-16 09:00 真太阳时/平太阳时对比', () {
    test('平太阳时（当前 false）=> 巳时', () {
      final chart = calculateZiweiChart(
        solar: DateTime(2000, 8, 16, 9, 0),
        gender: Gender.male,
        location: null,
        useTrueSolarTime: false,
      );
      print('平太阳时: ${chart.baziFull} | ${chart.elementBureauLabel} | '
          '命${chart.palaces[chart.originMingIndex].ganzhiLabel}');
      expect(chart.baziTime, '癸巳');
    });

    test('真太阳时 120E/30N（默认）=> 辰时', () {
      final chart = calculateZiweiChart(
        solar: DateTime(2000, 8, 16, 9, 0),
        gender: Gender.male,
        location: const Location(120, 30),
        useTrueSolarTime: true,
      );
      print('真太阳时: ${chart.baziFull} | ${chart.elementBureauLabel} | '
          '命${chart.palaces[chart.originMingIndex].ganzhiLabel}');
      expect(chart.baziTime, '壬辰');
    });
  });
}
