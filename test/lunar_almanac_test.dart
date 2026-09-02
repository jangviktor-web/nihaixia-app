import 'package:flutter_test/flutter_test.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:nihaisha_app/services/lunar_almanac_service.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart' show calcZiweiBaZi;

const List<String> _branchNames = [
  '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
];
const List<String> _shaByBranch = [
  '南', '东', '北', '西', '南', '东', '北', '西', '南', '东', '北', '西',
];
const List<String> _jianChuNames = [
  '建', '除', '满', '平', '定', '执', '破', '危', '成', '收', '开', '闭',
];

void main() {
  group('每日黄历', () {
    test('结构字段非空且格式正确', () {
      final a = getDailyAlmanac(DateTime(2026, 8, 15));
      expect(a.ganzhiDay.length, equals(2));
      expect(_jianChuNames.contains(a.jianChu), isTrue);
      expect(a.jianChuIndex, inInclusiveRange(0, 11));
      expect(a.pengZu.length, equals(2));
      expect(a.pengZu.first, contains('不'));
      expect(a.pengZu.last, contains('不'));
      expect(a.yi, isNotEmpty);
      expect(a.ji, isNotEmpty);
      expect(a.chong, startsWith('冲'));
      expect(a.sha, startsWith('煞'));
    });

    test('建除随日递增（今日+1 天 = 建除序号 +1 mod 12）', () {
      final d = DateTime(2026, 1, 5);
      final today = getDailyAlmanac(d);
      final tomorrow = getDailyAlmanac(d.add(const Duration(days: 1)));
      expect(tomorrow.jianChuIndex, equals((today.jianChuIndex + 1) % 12));
    });

    test('冲煞与日支六冲一致（独立校验）', () {
      final d = DateTime(2026, 8, 15);
      final a = getDailyAlmanac(d);
      // 独立重算日支
      final ad = AstroDateTime(d.year, d.month, d.day, 12, 0, 0);
      final dayBranch = dayGanZhi(ad).zhi.index;
      final chongIdx = (dayBranch + 6) % 12;
      expect(a.chong, contains(_branchNames[chongIdx]));
      expect(a.sha, contains(_shaByBranch[dayBranch]));
    });

    test('宜与忌不重叠', () {
      final a = getDailyAlmanac(DateTime(2026, 8, 15));
      final overlap = a.yi.where((x) => a.ji.contains(x)).toList();
      expect(overlap, isEmpty);
    });

    test('同日期幂等（确定性）', () {
      final a = getDailyAlmanac(DateTime(2026, 8, 15));
      final b = getDailyAlmanac(DateTime(2026, 8, 15));
      expect(a.jianChu, equals(b.jianChu));
      expect(a.ganzhiDay, equals(b.ganzhiDay));
      expect(a.yi, equals(b.yi));
    });

    test('跨日范围不抛异常且结构稳定', () {
      for (int i = 0; i < 30; i++) {
        final a = getDailyAlmanac(DateTime(2026, 8, 1).add(Duration(days: i)));
        expect(a.jianChuIndex, inInclusiveRange(0, 11));
        expect(a.yi, isNotEmpty);
      }
    });
  });

  group('年柱月柱日柱', () {
    test('三柱均为两字干支且日柱与 dayGanZhi 同源一致（连续 400 天）', () {
      final start = DateTime(2026, 1, 1);
      for (int i = 0; i < 400; i++) {
        final d = start.add(Duration(days: i));
        final a = getDailyAlmanac(d);
        expect(a.ganzhiYear.length, equals(2), reason: '$d 年柱');
        expect(a.ganzhiMonth.length, equals(2), reason: '$d 月柱');
        expect(a.ganzhiDay.length, equals(2), reason: '$d 日柱');
        // 旧来源（sxwnl dayGanZhi，正午基准）应与新来源完全一致
        final ad = AstroDateTime(d.year, d.month, d.day, 12, 0, 0);
        expect(a.ganzhiDay, equals(dayGanZhi(ad).toString()),
            reason: '$d 日柱两来源应一致');
      }
    });

    test('年柱按立春分界、月柱按节气分界（2026 边界日）', () {
      // 2026 立春为 2 月 4 日：立春前仍属乙巳年（丑/子月），立春后为丙午年（寅月）
      final beforeLiChun = getDailyAlmanac(DateTime(2026, 2, 3));
      final afterLiChun = getDailyAlmanac(DateTime(2026, 2, 4));
      expect(beforeLiChun.ganzhiYear, equals('乙巳'));
      expect(afterLiChun.ganzhiYear, equals('丙午'));
      expect(afterLiChun.ganzhiMonth, equals('庚寅')); // 丙年寅月
    });

    test('三柱与紫微引擎四柱接口逐字一致（同正午基准）', () {
      final d = DateTime(2026, 9, 1);
      final a = getDailyAlmanac(d);
      final bz = calcZiweiBaZi(DateTime(d.year, d.month, d.day, 12, 0),
          useTrueSolarTime: false);
      expect(a.ganzhiYear, equals(bz.year));
      expect(a.ganzhiMonth, equals(bz.month));
      expect(a.ganzhiDay, equals(bz.day));
    });
  });
}
