// 紫微大限 → AI 摘要：锁定「大限宫位名能与十二宫对上」与「年龄段不重叠」，
// 这是 _chartDigest 回查大限主星、按虚岁唯一定位的前提。
// 运行：flutter test test/ziwei_decade_digest_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart';
import 'package:ziwei_core/ziwei_core.dart';

void main() {
  late ZiweiChart chart;

  setUpAll(() {
    chart = calculateZiweiChart(
      solar: DateTime(2000, 8, 16, 6, 0),
      gender: Gender.male,
      useTrueSolarTime: false,
    );
  });

  test('十二大限齐全，且宫位名都能在十二宫里找到', () {
    expect(chart.decades.length, 12);
    final roles = chart.palaces.map((p) => p.roleLabel).toSet();
    for (final d in chart.decades) {
      expect(roles.contains(d.roleLabel), isTrue,
          reason: '大限「${d.roleLabel}」在十二宫里找不到同名宫位，'
              'AI 摘要回查该限主星会得到空值');
      expect(d.rangeLabel, isNotEmpty);
      expect(d.ganzhiLabel, isNotEmpty);
    }
  });

  test('大限年龄段递增且互不重叠——按虚岁能唯一定位', () {
    for (var i = 1; i < chart.decades.length; i++) {
      expect(chart.decades[i].startTime,
          greaterThan(chart.decades[i - 1].endTime),
          reason: '第 ${i + 1} 限起点应晚于上一限终点，否则同一虚岁会命中多限');
    }
  });

  test('首个大限从 1 岁或更大起算，跨度均为十年', () {
    final first = chart.decades.first;
    expect(first.startTime, greaterThanOrEqualTo(1));
    for (final d in chart.decades) {
      expect(d.endTime - d.startTime, 9, reason: '${d.rangeLabel} 不是十年跨度');
    }
  });
}
