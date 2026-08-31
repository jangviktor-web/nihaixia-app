import 'package:flutter_test/flutter_test.dart';
import 'package:ziwei_core/ziwei_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart';
import 'package:nihaisha_app/services/ziwei_interpretation.dart';

ZiweiChart _makeChart() {
  // 固定生辰（公历 2000-08-16 巳时，北京），保证可复现。
  final solar = DateTime(2000, 8, 16, 9, 0);
  return calculateZiweiChart(
    solar: solar,
    gender: Gender.male,
    location: Location(116.41, 39.90),
    useTrueSolarTime: true,
  );
}

void main() {
  group('流月/流日 引擎层', () {
    late ZiweiChart chart;
    setUp(() => chart = _makeChart());

    test('流月标记结构正确且命宫索引合法', () {
      final date = DateTime(2026, 8, 15);
      final fm = calculateFlowMonthMark(chart, date);
      expect(fm.mingIndex, inInclusiveRange(0, 11));
      expect(fm.illnessIndex, equals((fm.mingIndex + 5) % 12));
      expect(fm.ganzhi.length, equals(2));
      expect(fm.roleLabel, isNotEmpty);
      expect(fm.month, inInclusiveRange(1, 13));
    });

    test('流月命宫与引擎 FlowMonth.create 一致（oracle 校验）', () {
      final date = DateTime(2026, 8, 15);
      final fm = calculateFlowMonthMark(chart, date);
      final oracle = FlowMonth.create(
        fm.month,
        date.year,
        chart.basePlate,
        isLeap: fm.isLeap,
      );
      expect(fm.mingIndex, equals(oracle.index));
      expect(
        fm.ganzhi,
        equals('${oracle.ganzhi.gan.label}${oracle.ganzhi.zhi.label}'),
      );
    });

    test('流日标记结构正确且命宫索引合法', () {
      final date = DateTime(2026, 8, 15);
      final fd = calculateFlowDayMark(chart, date);
      expect(fd.mingIndex, inInclusiveRange(0, 11));
      expect(fd.illnessIndex, equals((fd.mingIndex + 5) % 12));
      expect(fd.ganzhi.length, equals(2));
      expect(fd.roleLabel, isNotEmpty);
    });

    test('同日期幂等（确定性）', () {
      final a = calculateFlowMonthMark(chart, DateTime(2026, 8, 15));
      final b = calculateFlowMonthMark(chart, DateTime(2026, 8, 15));
      expect(a.mingIndex, equals(b.mingIndex));
      expect(a.ganzhi, equals(b.ganzhi));
    });

    test('解读文案非空且含关键字', () {
      final date = DateTime(2026, 8, 15);
      final fm = calculateFlowMonthMark(chart, date);
      final fd = calculateFlowDayMark(chart, date);
      final sM = summarizeFlowMonth(chart, fm);
      final sD = summarizeFlowDay(chart, fd);
      expect(sM, contains('流月命宫'));
      expect(sD, contains('流日命宫'));
      expect(sM, contains('身体留意'));
      expect(sD, contains('身体留意'));
    });
  });
}
