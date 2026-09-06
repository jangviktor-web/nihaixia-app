// 潮汕节俗 + 玉匣灵兆（身体兆占）测试。
//
// 农历日期对位沿用「引擎扫描」策略：用 sxwnl LunarDate.fromSolar 找出
// 目标农历日期对应的公历日，再断言 AlmanacDay 内容；不凭记忆硬编码日期。
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/yuxiaji_omen_data.dart';
import 'package:nihaisha_app/screens/yuxiaji_omen_screen.dart';
import 'package:nihaisha_app/services/lunar_almanac_service.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

AlmanacDay _dayOfLunar(int year, int month, int day) {
  var date = DateTime(year, 1, 1);
  final end = DateTime(year + 1, 2, 1);
  while (date.isBefore(end)) {
    final lunar = LunarDate.fromSolar(
      AstroDateTime(date.year, date.month, date.day, 12, 0, 0),
    );
    if (!lunar.isLeap && lunar.month == month && lunar.day == day) {
      return getDailyAlmanac(date);
    }
    date = date.add(const Duration(days: 1));
  }
  fail('农历 $year-$month-$day 未找到');
}

void main() {
  group('潮汕节俗（黄历模块）', () {
    test('正月初四：神落天（潮汕卡）', () {
      final d = _dayOfLunar(2026, 1, 4);
      expect(d.chaoshanFestivals, contains('神落天'));
    });

    test('正月初一：潮汕「春节」被引擎节日去重，不重复显示', () {
      final d = _dayOfLunar(2026, 1, 1);
      expect(d.festivals, contains('春节'));
      expect(
        d.chaoshanFestivals.every((c) => !c.contains('春节')),
        isTrue,
        reason: '春节已由节日卡展示，潮汕卡不应重复',
      );
    });

    test('每月固定拜神日：初一拜伯公、初二拜地主爷', () {
      final d1 = _dayOfLunar(2026, 6, 1);
      final d2 = _dayOfLunar(2026, 6, 2);
      expect(d1.chaoshanFestivals, contains('拜伯公（土地公）'));
      expect(d2.chaoshanFestivals, contains('拜地主爷（地基主）'));
    });

    test('地方性条目带地域标注：二月廿五 三山国王', () {
      final d = _dayOfLunar(2026, 2, 25);
      expect(
        d.chaoshanFestivals.any((c) => c.startsWith('三山国王生')),
        isTrue,
      );
    });

    test('全年潮汕节俗覆盖量合理（>=80 个农历日期）', () {
      var date = DateTime(2026, 1, 1);
      final end = DateTime(2027, 1, 1);
      var hit = 0;
      while (date.isBefore(end)) {
        final a = getDailyAlmanac(date);
        if (a.chaoshanFestivals.isNotEmpty) hit++;
        date = date.add(const Duration(days: 1));
      }
      expect(hit, greaterThanOrEqualTo(80));
    });
  });

  group('玉匣灵兆（身体兆占）', () {
    test('十二时辰占法 12 种，每种 12 条时辰占断', () {
      expect(kYuXiaJiShiChenOmens.length, 12);
      for (final o in kYuXiaJiShiChenOmens) {
        expect(o.duanByHour.length, 12, reason: o.name);
        expect(o.name, startsWith('占'), reason: o.name);
      }
    });

    test('特殊占法 2 种（鸦鸣鹊噪/占灯花），正文含关键结构', () {
      expect(kYuXiaJiSpecialOmens.length, 2);
      final deng = kYuXiaJiSpecialOmens.firstWhere(
        (s) => s.name == '占灯花法',
      );
      expect(deng.body, contains('【形态占断】'));
      final ya = kYuXiaJiSpecialOmens.firstWhere(
        (s) => s.name == '鸦鸣鹊噪方向',
      );
      expect(ya.body, contains('【占法步骤】'));
    });

    test('时辰换算纯函数：23 点与 0 点均为子时，12 点为午时', () {
      expect(shiChenIndexOf(DateTime(2026, 9, 5, 23, 0)), 0);
      expect(shiChenIndexOf(DateTime(2026, 9, 5, 0, 30)), 0);
      expect(shiChenIndexOf(DateTime(2026, 9, 5, 1, 0)), 1);
      expect(shiChenIndexOf(DateTime(2026, 9, 5, 12, 0)), 6);
      expect(shiChenIndexOf(DateTime(2026, 9, 5, 22, 59)), 11);
    });

    test('时辰标签：子时含 23:00 起点、区间连续', () {
      expect(shiChenLabel(0), contains('23:00'));
      expect(shiChenLabel(6), contains('11:00'));
      expect(shiChenLabel(6), contains('12:59'));
    });
  });
}
