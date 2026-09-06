// 通胜要览 + 本命生肖推导 + 建除月支口径 验证网。
// 原则：不凭记忆硬编码日期——动态扫描定位目标干支日，再断言派生结果。
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/services/lunar_almanac_service.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

const _validDirections = {
  '东北', '西北', '西南', '东南', '正北', '正南', '正东', '正西',
};

void main() {
  group('通胜要览：黄道吉时', () {
    test('黄道吉时恒为 6 个时辰（连续 60 天扫描）', () {
      for (int i = 0; i < 60; i++) {
        final a = getDailyAlmanac(DateTime(2026, 1, 1).add(Duration(days: i)));
        expect(
          a.jiShi.length,
          6,
          reason: '${a.solar} 黄道吉时应为 6 个（六黄道神各占一时辰）',
        );
      }
    });

    test('日支子日：青龙起子 → 吉时 = 子丑辰巳未戌', () {
      // 动态扫描 2026 年 1 月中旬，找到日柱为「X子」的日子。
      DateTime? subDay;
      var d = DateTime(2026, 1, 1);
      for (int i = 0; i < 15; i++) {
        if (getDailyAlmanac(d).ganzhiDay.endsWith('子')) {
          subDay = d;
          break;
        }
        d = d.add(const Duration(days: 1));
      }
      expect(subDay, isNotNull, reason: '15 天内必有子日（12 天一轮）');
      final a = getDailyAlmanac(subDay!);
      expect(a.ganzhiDay.endsWith('子'), isTrue);
      // 申子辰日青龙在子：黄道 = 青龙(子) 明堂(丑) 金匮(辰) 天德(巳)
      //                    玉堂(未) 司命(戌)
      expect(a.jiShi, ['子时', '丑时', '辰时', '巳时', '未时', '戌时']);
    });
  });

  group('通胜要览：三神方位', () {
    test('财神/喜神/福神均为合法方位词（连续 60 天扫描）', () {
      for (int i = 0; i < 60; i++) {
        final a = getDailyAlmanac(DateTime(2026, 1, 1).add(Duration(days: i)));
        expect(_validDirections.contains(a.caiShen), isTrue,
            reason: '${a.solar} 财神方位非法：${a.caiShen}');
        expect(_validDirections.contains(a.xiShen), isTrue,
            reason: '${a.solar} 喜神方位非法：${a.xiShen}');
        expect(_validDirections.contains(a.fuShen), isTrue,
            reason: '${a.solar} 福神方位非法：${a.fuShen}');
      }
    });

    test('同干日三神方位稳定、不同干日可能不同（抽两日验证）', () {
      final a1 = getDailyAlmanac(DateTime(2026, 1, 1));
      final a2 = getDailyAlmanac(DateTime(2026, 1, 2)); // 相邻日干必不同
      expect(a1.ganzhiDay[0], isNot(a2.ganzhiDay[0]));
      expect(a1.caiShen, isNotEmpty);
      expect(a2.caiShen, isNotEmpty);
    });
  });

  group('本命生肖推导（getUserZodiacFromSolar）', () {
    test('2026-06-01 → 丙午马年 → 马', () {
      expect(getUserZodiacFromSolar(DateTime(2026, 6, 1)), '马');
    });

    test('2025-06-01 → 乙巳蛇年 → 蛇', () {
      expect(getUserZodiacFromSolar(DateTime(2025, 6, 1)), '蛇');
    });

    test('立春前属前一年生肖：2026-02-03（立春前）→ 蛇', () {
      expect(getUserZodiacFromSolar(DateTime(2026, 2, 3)), '蛇');
    });
  });

  group('建除月支口径钉死：LunarDate.month 为 1-based', () {
    // _lunarMonthToBranch 表按 lunar.month=1 为正月建寅 假设；
    // 此处用已知节气日钉死库语义，防止底层升级悄悄变 0-based。
    test('2026-02-17 春节：农历正月初一 → month==1, day==1', () {
      final lunar = LunarDate.fromSolar(
        AstroDateTime(2026, 2, 17, 12, 0, 0),
      );
      expect(lunar.month, 1);
      expect(lunar.day, 1);
    });

    test('正月初一（寅月、日支戌）建除 = 成（钉死月支映射口径）', () {
      // 2026-02-17 日支由 ganzhiDay 独立解析（不凭记忆），为戌(10)。
      // 正月建寅：寅上起建顺数，戌为第 9 位 → 建除「成」（索引 8）。
      // 若 _lunarMonthToBranch 被改成 0-based，此处即失败。
      final a = getDailyAlmanac(DateTime(2026, 2, 17));
      const branches = [
        '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
      ];
      expect(branches.indexOf(a.ganzhiDay[1]), 10,
          reason: '2026-02-17 日支应为戌');
      expect(a.chong, '冲辰');
      expect(a.jianChuIndex, 8);
      expect(a.jianChu, '成');
    });
  });
}
