import 'package:flutter_test/flutter_test.dart';
import 'package:ziwei_core/ziwei_core.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart';

/// 紫微斗数排盘回归测试。
///
/// 已知生辰 2000-08-16 06:00（男）的排盘结果已人工核对（庚年四化、金四局起运等），
/// 此处以具体断言锁定，防止引擎升级后无声回归。
void main() {
  group('ziwei chart (2000-08-16 06:00 男)', () {
    late ZiweiChart chart;

    setUpAll(() {
      chart = calculateZiweiChart(
        solar: DateTime(2000, 8, 16, 6, 0),
        gender: Gender.male,
        useTrueSolarTime: false,
      );
    });

    test('基本结构与八字', () {
      expect(chart.palaces.length, 12);
      expect(chart.baziFull, '庚辰 甲申 丙午 辛卯');
      expect(chart.lunarText, '农历 2000年七月十七');
      expect(chart.elementBureauLabel, '金四局');
      expect(chart.genderLabel, '男');
    });

    test('命主 / 身主', () {
      expect(chart.mingZhuLabel, '武曲');
      expect(chart.shenZhuLabel, '文昌');
    });

    test('命宫定位与主星', () {
      final life = chart.palaces[chart.originMingIndex];
      expect(life.isLife, isTrue);
      expect(life.roleLabel, '命宫');
      expect(life.ganzhiLabel, '辛巳');
      final majorNames = life.majors.map((s) => s.label).toList();
      expect(majorNames, contains('天相'));
    });

    test('身宫定位', () {
      final body = chart.palaces[chart.bodyPalaceIndex];
      expect(body.isBody, isTrue);
      expect(body.roleLabel, '迁移');
      final majorNames = body.majors.map((s) => s.label).toList();
      expect(majorNames, containsAll(['武曲', '破军']));
    });

    test('生年四化 (庚年: 太阳禄/武曲权/太阴科/天同忌)', () {
      expect(chart.sihua.length, 4);
      String starFor(SiHuaType t) =>
          chart.sihua.firstWhere((s) => s.type == t).starLabelName;
      expect(starFor(SiHuaType.lu), '太阳');
      expect(starFor(SiHuaType.quan), '武曲');
      expect(starFor(SiHuaType.ke), '太阴');
      expect(starFor(SiHuaType.ji), '天同');
    });

    test('十二大限 (金四局起运4岁, 阳男顺行)', () {
      expect(chart.decades.length, 12);
      final first = chart.decades.first;
      expect(first.rangeLabel, '4–13 岁');
      expect(first.roleLabel, '命宫');
      expect(first.ganzhiLabel, '辛巳');
      // 第2大限进入父母宫
      expect(chart.decades[1].roleLabel, '父母');
    });

    test('十二宫角色互不重复', () {
      final roles = chart.palaces.map((p) => p.role).toSet();
      expect(roles.length, 12);
    });
  });
}
