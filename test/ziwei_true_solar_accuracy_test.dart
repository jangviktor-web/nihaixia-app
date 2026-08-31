import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ziwei_core/ziwei_core.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart';
import 'package:nihaisha_app/services/city_location_service.dart';

/// 真太阳时 + 城市经纬度 准确性测试。
///
/// 沿用本会话既有方法论（见 test/quality_score_bc.dart、ziwei_flow_test.dart）：
/// 1) 用引擎自身底层 API（ZiweiDate）作独立 oracle 交叉校验 wrapper 暴露的时辰；
/// 2) 差分敏感性：近 120°E 城市 vs 远西城市、开/关真太阳时，断言时辰变化符合预期；
/// 3) 结构完整性 + 幂等。
void main() {
  final all = CityLocationService.parseJson(
    File('assets/data/china_cities.json').readAsStringSync(),
  );
  CityLocation find(String name) =>
      all.firstWhere((c) => c.name == name);

  final bj = find('北京市');
  final urumqi = find('乌鲁木齐市');

  ZiweiChart calc(CityLocation c, DateTime solar, bool tst) =>
      calculateZiweiChart(
        solar: solar,
        gender: Gender.male,
        location: Location(c.lng, c.lat),
        useTrueSolarTime: tst,
      );

  /// 独立 oracle：直接调 ziwei_core 的 ZiweiDate，取真太阳时调整后的时辰干支。
  String oracleBaziTime(DateTime solar, CityLocation c, bool tst) {
    final ruleset = ConfigLoader.getDefault();
    final date = ZiweiDate.fromSolar(
      AstroDateTime(solar.year, solar.month, solar.day, solar.hour, solar.minute),
      gender: Gender.male,
      options: ruleset.calendarOptions,
      location: Location(c.lng, c.lat),
      useTrueSolarTime: tst,
    );
    return '${date.bazi.time.gan.label}${date.bazi.time.zhi.label}';
  }

  final solar = DateTime(2000, 8, 16, 12, 0); // 正午，便于 ±16min 不跨时辰边界

  group('城市经纬度生效（location 真正流入引擎）', () {
    test('数据集含北京/乌鲁木齐且坐标正确', () {
      expect(bj.lng, closeTo(116.43585, 0.01));
      expect(bj.lat, closeTo(40.10859, 0.01));
      expect(urumqi.lng, closeTo(87.77529, 0.01));
      expect(urumqi.lat, closeTo(43.56514, 0.01));
    });

    test('北京 vs 乌鲁木齐（均开真太阳时）时辰不同 → 经度被使用', () {
      final bjT = calc(bj, solar, true).baziTime;
      final urT = calc(urumqi, solar, true).baziTime;
      // 经度差 ~28.6° → 时差 ~1h54m，必然跨时辰
      expect(bjT, isNot(equals(urT)),
          reason: '北京($bjT) 与 乌鲁木齐($urT) 经度不同，真太阳时校正应使其时辰不同');
    });
  });

  group('真太阳时确实生效（useTrueSolarTime 起作用）', () {
    test('北京（近120E）：开/关真太阳时时辰不变', () {
      final on = calc(bj, solar, true).baziTime;
      final off = calc(bj, solar, false).baziTime;
      expect(on, equals(off),
          reason: '近120°E 城市真太阳时校正仅 ±16min，正午不跨时辰边界');
    });

    test('乌鲁木齐（远西）：开/关真太阳时时辰变化 → 校正按城市经度生效', () {
      final on = calc(urumqi, solar, true).baziTime;
      final off = calc(urumqi, solar, false).baziTime;
      expect(on, isNot(equals(off)),
          reason: '远西城市真太阳时校正 ~2h，应跨时辰边界');
    });
  });

  group('包装层忠实暴露引擎真太阳时（底层 API 作 oracle）', () {
    test('北京 ON：wrapper.baziTime == ZiweiDate 直算', () {
      final w = calc(bj, solar, true).baziTime;
      final o = oracleBaziTime(solar, bj, true);
      expect(w, equals(o));
    });
    test('乌鲁木齐 ON：wrapper.baziTime == ZiweiDate 直算', () {
      final w = calc(urumqi, solar, true).baziTime;
      final o = oracleBaziTime(solar, urumqi, true);
      expect(w, equals(o));
    });
    test('乌鲁木齐 OFF（平太阳时路径）：wrapper == ZiweiDate 直算', () {
      final w = calc(urumqi, solar, false).baziTime;
      final o = oracleBaziTime(solar, urumqi, false);
      expect(w, equals(o));
    });
  });

  group('结构完整性（真太阳时开启下）', () {
    final chart = calc(bj, solar, true);
    test('12 宫、索引 0-11、唯一命宫/身宫', () {
      expect(chart.palaces.length, 12);
      for (int i = 0; i < 12; i++) {
        expect(chart.palaces[i].index, i);
      }
      final lifes = chart.palaces.where((p) => p.isLife).toList();
      final bodys = chart.palaces.where((p) => p.isBody).toList();
      expect(lifes.length, 1);
      expect(bodys.length, 1);
      expect(lifes.first.index, chart.originMingIndex);
      expect(bodys.first.index, chart.bodyPalaceIndex);
    });
    test('生年四化 恰好 禄/权/科/忌 各一', () {
      final types = chart.sihua.map((s) => s.typeLabel).toList();
      expect(types.toSet(), {'禄', '权', '科', '忌'});
      expect(types.length, 4);
    });
    test('十二大限 起点递增且区间合法', () {
      expect(chart.decades.length, 12);
      final starts = chart.decades.map((d) => d.startTime).toList();
      for (int i = 0; i < starts.length - 1; i++) {
        expect(starts[i + 1], greaterThan(starts[i]));
      }
      for (final d in chart.decades) {
        expect(d.startTime, lessThan(d.endTime));
        expect(d.startTime, greaterThanOrEqualTo(1));
      }
    });
  });

  group('幂等（同输入两次一致）', () {
    test('北京 ON 两次 baziTime/命宫/八字一致', () {
      final a = calc(bj, solar, true);
      final b = calc(bj, solar, true);
      expect(a.baziTime, equals(b.baziTime));
      expect(a.originMingIndex, equals(b.originMingIndex));
      expect(a.baziFull, equals(b.baziFull));
    });
  });
}
