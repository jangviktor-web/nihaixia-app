// 批次 C：传统扩展字段 golden 测试（golden 来源 = liujixue 排盘实测，
// 案例 1995-08-16 12:00 男：乙亥 甲申 己卯 庚午）。
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/engine/bazi_extra.dart';

void main() {
  const gans = ['乙', '甲', '己', '庚'];
  const zhis = ['亥', '申', '卯', '午'];
  const pillars = ['乙亥', '甲申', '己卯', '庚午'];

  group('胎元 / 胎息', () {
    test('月柱 甲申 → 胎元 乙亥', () {
      expect(taiYuanOf('甲申'), '乙亥');
    });
    test('日柱 己卯 → 胎息 甲戌（甲己合、卯戌合）', () {
      expect(taiXiOf('己卯'), '甲戌');
    });
    test('胎元公式抽查（月柱 庚午 → 辛酉）', () {
      expect(taiYuanOf('庚午'), '辛酉');
    });
  });

  group('各柱空亡', () {
    test('案例四柱 → 申酉 / 午未 / 申酉 / 戌亥（与 liujixue 一致）', () {
      expect(kongWangPerPillar(pillars), ['申酉', '午未', '申酉', '戌亥']);
    });
    test('甲子旬首自身 → 戌亥', () {
      expect(kongWangPerPillar(['甲子']), ['戌亥']);
    });
  });

  group('自坐十二神（火土同宫）', () {
    test('案例四柱 → 死 / 绝 / 病 / 沐浴（与 liujixue 一致）', () {
      expect(selfTwelveStages(gans, zhis), ['死', '绝', '病', '沐浴']);
    });
  });

  group('副星（藏干十神）', () {
    test('案例 → 与 liujixue 副星行逐柱一致', () {
      final gods = hiddenTenGods(gans, zhis);
      expect(gods[0], ['正财', '正官'], reason: '年柱亥藏壬甲');
      expect(gods[1], ['伤官', '正财', '劫财'], reason: '月柱申藏庚壬戊');
      expect(gods[2], ['七杀'], reason: '日柱卯藏乙');
      expect(gods[3], ['偏印', '比肩'], reason: '时柱午藏丁己');
    });
  });

  group('显性五行（8 字不折算藏干）', () {
    test('案例 → 木3 火1 土1 金2 水1（liujixue：金2 水1 等一致）', () {
      expect(visibleElementCounts(gans, zhis), [3, 1, 1, 2, 1]);
    });
  });
}
