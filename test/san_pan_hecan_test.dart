import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/services/san_pan_hecan_service.dart';
import 'package:nihaisha_app/engine/bazi_twelve_stages.dart';

void main() {
  group('computeSanPanHeCan 三盘同源合参', () {
    test('同一出生时空推三盘，结构完整且命卦降级路径正确', () {
      const input = HeCanInput(
        year: 1995,
        month: 8,
        day: 16,
        hour: 12, // 午时
        minute: 0,
        isMale: true,
        lateZiEnabled: false,
        useTrueSolarTime: true,
        location: null,
      );

      final hecan = computeSanPanHeCan(input);

      // 八字四柱：四组"干支"各取单字，形如 "乙 甲 丙 甲"
      final pillars = hecan.baziFull.split(' ');
      expect(pillars.length, 4);
      for (final p in pillars) {
        expect(p.length, 2, reason: '每柱应为两字干支');
      }

      // 紫微命宫主星非空
      expect(hecan.mingGongStars, isNotEmpty);

      // 八字日主非空
      expect(hecan.dayMaster, isNotEmpty);

      // 八字十神：四柱各一，日柱位为『日主』
      expect(hecan.tenGods.length, 4);
      expect(hecan.tenGods[2], '日主');
      for (var i = 0; i < 4; i++) {
        if (i != 2) expect(hecan.tenGods[i], isNotEmpty);
      }

      // 八字旬空非空（经典口诀情境下应为两字地支）
      expect(hecan.kongWang, isNotEmpty);

      // 八字刑冲合害/合会：标签列表，元素非空
      expect(hecan.relations, isA<List<String>>());
      for (final r in hecan.relations) {
        expect(r, isNotEmpty);
      }

      // 八字长生十二神：四柱各一标签（默认火土同宫口径）
      expect(hecan.twelveStages.length, 4);
      for (final s in hecan.twelveStages) {
        expect(s, isNotEmpty);
      }

      // 命卦降级一致性：可用则两卦名非空非占位，不可用则均为"—"
      if (hecan.mingGuaAvailable) {
        expect(hecan.xianTianName, isNot('—'));
        expect(hecan.houTianName, isNot('—'));
      } else {
        expect(hecan.xianTianName, '—');
        expect(hecan.houTianName, '—');
      }
    });

    test('晚子时开关改变命盘锚点（同源一致）', () {
      const base = HeCanInput(
        year: 1985,
        month: 3,
        day: 10,
        hour: 23,
        minute: 30,
        isMale: true,
      );
      final earlyZi = computeSanPanHeCan(base); // lateZiEnabled 默认 false
      final lateZi = computeSanPanHeCan(base.copyWith(lateZiEnabled: true));

      // 两开关下锚点不同，故八字四柱应不同（晚子时归次日 00:00）
      expect(earlyZi.baziFull, isNot(equals(lateZi.baziFull)));
    });

    test('长生十二神口径切换改变结果（火土同宫 vs 水土同宫）', () {
      const base = HeCanInput(
        year: 1995,
        month: 8,
        day: 16,
        hour: 12,
        minute: 0,
        isMale: true,
      );
      final fireEarth = computeSanPanHeCan(base); // twelveStageMode 默认 fireEarthSame
      final waterEarth =
          computeSanPanHeCan(base.copyWith(mode: TwelveStageMode.waterEarthSame));

      expect(fireEarth.twelveStages.length, 4);
      expect(waterEarth.twelveStages.length, 4);
      // 两口径仅戊/己土柱结果不同：日主或任一柱为戊/己则结果应不同，否则相同
      final gans = fireEarth.baziFull.split(' ').map((p) => p[0]).toList();
      final hasEarth = gans.contains('戊') || gans.contains('己');
      if (hasEarth) {
        expect(fireEarth.twelveStages.join(','),
            isNot(equals(waterEarth.twelveStages.join(','))));
      } else {
        expect(fireEarth.twelveStages.join(','),
            equals(waterEarth.twelveStages.join(',')));
      }
    });
  });
}

extension _HeCanCopy on HeCanInput {
  HeCanInput copyWith({
    bool? lateZiEnabled,
    TwelveStageMode? mode,
  }) =>
      HeCanInput(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        isMale: isMale,
        lateZiEnabled: lateZiEnabled ?? this.lateZiEnabled,
        useTrueSolarTime: useTrueSolarTime,
        twelveStageMode: mode ?? twelveStageMode,
        location: location,
      );
}
