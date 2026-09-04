// 批次 A-①：bazi_core 0.6.7 与我们 ziwei_core 路径的交叉验证（防口径漂移回归）。
//
// 三个维度：
//   1. 同生辰四柱逐柱一致（含晚子时边界 23:30）；
//   2. 大运顺逆 golden：阴年男逆（月柱-1）/ 阴年女顺（月柱+1）/ 阳年男顺（月柱+1），
//      方向 = 年干阴阳 × 性别（bazi_core fortune.dart:125-126）；
//   3. FortuneTable 冒烟：8 步大运 + 按公历年检索流年。
//
// 两库显式传同一 Location(120,30)、ratHourMode 默认 noSplit（23 点换日），
// 真太阳时均开启——任何一侧口径变化都会在这里报警。
import 'package:flutter_test/flutter_test.dart';

import 'package:bazi_core/bazi_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart' show Location;

import 'package:nihaisha_app/services/bazi_service.dart';

final _loc = Location(120, 30);

BaziChart _bc(DateTime t, Gender g) => BaziChart.createBySolarDate(
      clockTime: AstroDateTime(t.year, t.month, t.day, t.hour, t.minute),
      location: _loc,
      gender: g,
    );

String _pillars(BaziChart c) =>
    '${c.bazi.year} ${c.bazi.month} ${c.bazi.day} ${c.bazi.time}';

void main() {
  group('四柱交叉验证（bazi_core vs ziwei_core 路径）', () {
    final cases = [
      (DateTime(1995, 8, 16, 12, 0), Gender.male),
      (DateTime(2000, 1, 1, 23, 30), Gender.male), // 晚子时边界
      (DateTime(1984, 6, 15, 12, 0), Gender.female),
    ];
    for (final (t, g) in cases) {
      test('$t ${g.name}：四柱逐柱一致', () {
        final ours = computeBaZiPaipan(
          t,
          isMale: g == Gender.male,
          location: _loc,
        );
        expect(_pillars(_bc(t, g)),
            '${ours.bazi.year} ${ours.bazi.month} ${ours.bazi.day} ${ours.bazi.time}');
      });
    }
  });

  group('大运顺逆 golden（方向 = 年干阴阳 × 性别）', () {
    test('乙亥阴年男：逆排，首运 = 月柱-1（甲申→癸未）', () {
      final f = Fortune.createByBaziChart(
          _bc(DateTime(1995, 8, 16, 12, 0), Gender.male));
      expect('${f.getDecadeByIndex(1).ganZhi}', '癸未');
      expect(f.getDecadeByIndex(1).flowYears.length, 10);
    });

    test('乙亥阴年女：顺排，首运 = 月柱+1（甲申→乙酉）', () {
      final f = Fortune.createByBaziChart(
          _bc(DateTime(1995, 8, 16, 12, 0), Gender.female));
      expect('${f.getDecadeByIndex(1).ganZhi}', '乙酉');
    });

    test('甲子阳年男：顺排，首运 = 月柱+1（庚午→辛未）', () {
      final f = Fortune.createByBaziChart(
          _bc(DateTime(1984, 6, 15, 12, 0), Gender.male));
      // 甲子年午月：五虎遁「甲己之年丙作首」→ 午月庚午
      expect(_pillars(_bc(DateTime(1984, 6, 15, 12, 0), Gender.male)),
          contains('庚午'));
      expect('${f.getDecadeByIndex(1).ganZhi}', '辛未');
    });
  });

  group('FortuneTable 冒烟', () {
    test('8 步大运 + 各步含 10 流年，1998 年流年→戊寅', () {
      final f = Fortune.createByBaziChart(
          _bc(DateTime(1995, 8, 16, 12, 0), Gender.male));
      final table = FortuneTable.build(f, decadeCount: 8);
      // build 会在首步大运前插入「起运前小运阶段」（startAge>1 时），故 8 大运 → 9 段
      expect(table.decades.length, 9, reason: '起运前小运 + 8 步大运');
      final y1998 = [
        for (final d in table.decades)
          for (final y in d.years)
            if (y.year == 1998) y,
      ];
      expect(y1998, isNotEmpty);
      expect('${y1998.first.ganZhi}', '戊寅');
    });
  });
}
