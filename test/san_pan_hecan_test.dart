import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/services/san_pan_hecan_service.dart';

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
  });
}

extension _HeCanCopy on HeCanInput {
  HeCanInput copyWith({bool? lateZiEnabled}) => HeCanInput(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        isMale: isMale,
        lateZiEnabled: lateZiEnabled ?? this.lateZiEnabled,
        useTrueSolarTime: useTrueSolarTime,
        location: location,
      );
}
