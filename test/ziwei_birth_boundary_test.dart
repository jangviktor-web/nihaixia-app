import 'package:flutter_test/flutter_test.dart';
import 'package:ziwei_core/ziwei_core.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart';

/// ① 子时 / 闰月 边界正确性测试。
/// 验证：晚子时（23:00–23:59）滚动到次日子时；早子时（00:00–00:59）保持当日；
/// 闰月出生正确暴露「闰X月」。
void main() {
  group('晚子时 / 早子时 边界', () {
    test('resolveBirthSolar(enabled=true): 1990-05-20 23:30 → 次日 (5-21) 00:30', () {
      final solar = resolveBirthSolar(
        year: 1990,
        month: 5,
        day: 20,
        hour: 23,
        minute: 30,
        enabled: true,
      );
      expect(solar.year, 1990);
      expect(solar.month, 5);
      expect(solar.day, 21, reason: '晚子时应滚动到次日');
      expect(solar.hour, 0, reason: '次日早子时固化到 0 点');
      expect(solar.minute, 30);
    });

    test('resolveBirthSolar 默认关闭：1990-05-20 23:30 → 当日 (5-20) 00:30', () {
      final solar = resolveBirthSolar(
        year: 1990,
        month: 5,
        day: 20,
        hour: 23,
        minute: 30,
        // enabled 默认 false
      );
      expect(solar.year, 1990);
      expect(solar.month, 5);
      expect(solar.day, 20, reason: '默认关闭：晚子时按当日早子时，日柱不顺延');
      expect(solar.hour, 0, reason: '当日早子时固化到 0 点');
      expect(solar.minute, 30);
    });

    test('默认关闭时 23:30 与 00:30 同日（均当日早子时，日柱一致）', () {
      final lateZi = resolveBirthSolar(
        year: 1990, month: 5, day: 20, hour: 23, minute: 30,
      );
      final earlyZi = resolveBirthSolar(
        year: 1990, month: 5, day: 20, hour: 0, minute: 30,
      );
      expect(lateZi.day, earlyZi.day, reason: '默认口径下日柱一致');
      expect(lateZi.hour, 0);
    });

    test('resolveBirthSolar: 1990-05-20 00:30 → 当日 (5-20) 00:30', () {
      final solar = resolveBirthSolar(
        year: 1990,
        month: 5,
        day: 20,
        hour: 0,
        minute: 30,
      );
      expect(solar.year, 1990);
      expect(solar.month, 5);
      expect(solar.day, 20, reason: '早子时保持当日');
      expect(solar.hour, 0);
    });

    test('engine 收到 23:30(enabled=true) → 次日子时（日柱归入次日，与当日子时不同）', () {
      final lateZi = calculateZiweiChart(
        solar: resolveBirthSolar(
          year: 1990,
          month: 5,
          day: 20,
          hour: 23,
          minute: 30,
          enabled: true,
        ),
        gender: Gender.male,
        useTrueSolarTime: false,
      );
      final earlyZi = calculateZiweiChart(
        solar: resolveBirthSolar(
          year: 1990,
          month: 5,
          day: 20,
          hour: 0,
          minute: 30,
        ),
        gender: Gender.male,
        useTrueSolarTime: false,
      );
      // 时辰均应为「子」
      expect(lateZi.baziTime.endsWith('子'), isTrue);
      expect(earlyZi.baziTime.endsWith('子'), isTrue);
      // 晚子时的日柱应顺延到次日，与当日早子时不同
      expect(lateZi.baziDay, isNot(equals(earlyZi.baziDay)));
      print('[晚子时] bazi=${lateZi.baziFull}');
      print('[早子时] bazi=${earlyZi.baziFull}');
    });
  });

  group('闰月出生显示', () {
    test('2001-05-25（闰四月）暴露 lunarIsLeap=true 且显示「闰4月」', () {
      final chart = calculateZiweiChart(
        solar: DateTime(2001, 5, 25, 12, 0),
        gender: Gender.male,
        useTrueSolarTime: false,
      );
      print('[闰月] lunarText=${chart.lunarText} '
          'lunarMonth=${chart.lunarMonth} isLeap=${chart.lunarIsLeap} '
          'display=${chart.lunarMonthDisplay}');
      expect(chart.lunarIsLeap, isTrue);
      expect(chart.lunarMonthDisplay, '闰4月');
    });
  });
}
