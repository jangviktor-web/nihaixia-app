import 'package:flutter_test/flutter_test.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:nihaisha_app/services/lunar_almanac_service.dart';

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
}
