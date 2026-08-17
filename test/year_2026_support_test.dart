import 'package:flutter_test/flutter_test.dart';
import 'package:ziwei_core/ziwei_core.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart';
import 'package:nihaisha_app/engine/minggua_engine.dart';
import 'package:nihaisha_app/engine/yijing_engine.dart';
import 'package:nihaisha_app/engine/bazi_analysis.dart';

/// ① 2026 年出生日期支持（用户反馈：下拉上限卡在 2025）
/// ② 紫微杂星完整性（115 颗星全部有中文名，盘格可展示）
/// ③ 四柱命卦新增 十神 + 六十甲子纳音
/// ④ 易经铜钱摇卦（六爻多动爻）
/// ⑤ 紫微流年盘（流曜落宫）
/// ⑥ 八字详批（神煞/格局/日主强弱/用神忌神）
void main() {
  group('2026 年出生日期支持', () {
    test('紫微斗数：2026-03-15 12:00 女 可排盘', () {
      final chart = calculateZiweiChart(
        solar: DateTime(2026, 3, 15, 12, 0),
        gender: Gender.female,
        useTrueSolarTime: false,
      );
      expect(chart.palaces.length, 12);
      expect(chart.baziFull, isNotEmpty);
      expect(chart.lunarText, contains('2026'));
      expect(chart.elementBureauLabel, isNotEmpty);
      expect(chart.decades.length, 12);
    });

    test('四柱命卦：2026-06-01 辰时 可计算', () {
      final date = ZiweiDate.fromSolar(
        DateTime(2026, 6, 1, 7, 30),
        gender: Gender.male,
        useTrueSolarTime: false,
      );
      final bz = date.bazi;
      final r = MingGuaEngine.compute(
        yearGan: bz.year.gan.label,
        yearZhi: bz.year.zhi.label,
        monthGan: bz.month.gan.label,
        monthZhi: bz.month.zhi.label,
        dayGan: bz.day.gan.label,
        dayZhi: bz.day.zhi.label,
        timeGan: bz.time.gan.label,
        timeZhi: bz.time.zhi.label,
        male: true,
      );
      expect(r, isNotNull);
      expect(r!.baziFull, isNotEmpty);
      expect(r.xianTian.name, isNotEmpty);
    });
  });

  group('紫微杂星完整性（115 星全中文）', () {
    late ZiweiChart chart;
    setUpAll(() {
      chart = calculateZiweiChart(
        solar: DateTime(2000, 8, 16, 6, 0),
        gender: Gender.male,
        useTrueSolarTime: false,
      );
    });

    test('12 宫星曜总数 = 115（主14+吉8+煞6+杂39+博士12+将前12+岁建12+长生12）', () {
      final total = chart.palaces.fold<int>(0, (s, p) => s + p.stars.length);
      expect(total, 115);
    });

    test('所有星曜 label 均为中文（无英文 key 回退）', () {
      for (final p in chart.palaces) {
        for (final s in p.stars) {
          expect(s.label == s.key, isFalse,
              reason: '${p.roleLabel} 出现未映射星曜 key: ${s.key}');
        }
      }
    });

    test('杂曜（乙级星）分布广泛，多数宫可展示', () {
      final minorPaloes = chart.palaces
          .where((p) => p.minors.isNotEmpty)
          .length;
      expect(minorPaloes, greaterThanOrEqualTo(8),
          reason: '仅 $minorPaloes 宫有乙级星（个别宫无乙级星属正常）');
    });

    test('十二神分组齐全（博士/岁建/将前/长生 各 12）', () {
      final byType = <String, int>{};
      for (final p in chart.palaces) {
        for (final s in p.stars) {
          byType[s.type.name] = (byType[s.type.name] ?? 0) + 1;
        }
      }
      expect(byType['boshi12'], 12);
      expect(byType['suijian12'], 12);
      expect(byType['jiangqian12'], 12);
      expect(byType['changsheng12'], 12);
    });
  });

  group('四柱命卦·十神与纳音', () {
    test('六十甲子纳音抽查', () {
      expect(nayinOf('甲', '子'), '海中金');
      expect(nayinOf('乙', '丑'), '海中金');
      expect(nayinOf('庚', '申'), '石榴木');
      expect(nayinOf('癸', '亥'), '大海水');
      expect(nayinOf('壬', '午'), '杨柳木');
      expect(nayinOf('X', '子'), '');
    });

    test('十神关系抽查（日主庚）', () {
      expect(shiShenOf('庚', '甲'), '偏财'); // 庚见甲：同性克我财
      expect(shiShenOf('庚', '丙'), '七杀'); // 庚见丙：同性克我
      expect(shiShenOf('庚', '壬'), '食神'); // 庚见壬：我生同性
      expect(shiShenOf('庚', '戊'), '偏印'); // 庚见戊：同性生我
      expect(shiShenOf('庚', '庚'), '比肩'); // 庚见庚：同
    });
  });

  group('易经·铜钱摇卦（六爻）', () {
    test('单动爻：乾卦初九动 → 变天风姤', () {
      final r = YiJingEngine.castByCoins([9, 7, 7, 7, 7, 7]);
      expect(r.primary.seq, 1);
      expect(r.moving, 1);
      expect(r.movingLines, [1]);
      expect(r.changed!.seq, 44); // 姤
      expect(r.movingTitles.single, '初九');
      expect(r.movingTexts.single, '潜龙勿用。');
    });

    test('多动爻：坤卦六爻皆动 → 变乾', () {
      final r = YiJingEngine.castByCoins([6, 6, 6, 6, 6, 6]);
      expect(r.primary.seq, 2);
      expect(r.movingLines.length, 6);
      expect(r.changed!.seq, 1);
      expect(r.movingTitles.join('、'),
          '初六、六二、六三、六四、六五、上六');
    });

    test('静卦：全少阳无变卦，取卦辞', () {
      final r = YiJingEngine.castByCoins([7, 7, 7, 7, 7, 7]);
      expect(r.moving, 0);
      expect(r.movingLines, isEmpty);
      expect(r.changed, isNull);
      expect(r.movingText, r.primary.judgement);
    });

    test('两动爻：初/四动有变卦，主断取首动爻', () {
      final r = YiJingEngine.castByCoins([6, 8, 8, 9, 8, 8]);
      expect(r.movingLines, [1, 4]);
      expect(r.moving, 1);
      expect(r.changed, isNotNull);
    });
  });

  group('紫微·流年盘（流曜落宫）', () {
    test('干支与命宫：2026 丙午、2000 庚辰', () {
      final y26 = calculateFlowYearMark(year: 2026);
      expect(y26.ganzhi, '丙午');
      expect(y26.mingIndex, 6); // 午
      final y00 = calculateFlowYearMark(year: 2000);
      expect(y00.ganzhi, '庚辰');
      expect(y00.mingIndex, 4); // 辰
    });

    test('流曜查表：庚年禄存申、丙年天马申', () {
      final y00 = calculateFlowYearMark(year: 2000);
      expect(y00.flowStars[8], contains('流禄存')); // 庚 → 申
      expect(y00.flowStars[2], contains('流天马')); // 辰 → 寅
      final y26 = calculateFlowYearMark(year: 2026);
      expect(y26.flowStars[5], contains('流禄存')); // 丙 → 巳
      expect(y26.flowStars[8], contains('流天马')); // 午 → 申
    });

    test('8 颗流曜全部落宫', () {
      final y = calculateFlowYearMark(year: 2026);
      final total = y.flowStars.values.fold<int>(0, (a, v) => a + v.length);
      expect(total, 8);
    });
  });

  group('八字详批（神煞/格局/用神）', () {
    test('丙午 辛卯 戊子 戊午：正官格 + 羊刃将星', () {
      final a = analyzeBaZi(
        gans: ['丙', '辛', '戊', '戊'],
        zhis: ['午', '卯', '子', '午'],
      );
      expect(a.dayMaster, '戊');
      expect(a.pattern, '正官格'); // 卯藏乙，戊见乙正官
      expect(a.shensha.any((s) => s.name == '羊刃'), isTrue);
      expect(a.shensha.where((s) => s.name == '将星').length, 2);
      expect(a.shensha.every((s) => s.pillar.isNotEmpty && s.pos.isNotEmpty),
          isTrue);
      expect(a.favorable, contains('木(官杀)'));
      expect(a.unfavorable, contains('火(印)'));
    });

    test('建禄格与羊刃格判定', () {
      final b = analyzeBaZi(
        gans: ['甲', '丙', '甲', '甲'],
        zhis: ['子', '寅', '辰', '子'],
      );
      expect(b.pattern, '建禄格'); // 甲禄在寅
      final c = analyzeBaZi(
        gans: ['庚', '戊', '庚', '庚'],
        zhis: ['辰', '酉', '辰', '辰'],
      );
      expect(c.pattern, '羊刃格'); // 庚羊刃在酉
    });

    test('神煞抽查：庚日天乙丑未、文昌亥、禄神申', () {
      final d = analyzeBaZi(
        gans: ['庚', '己', '庚', '丁'],
        zhis: ['子', '丑', '辰', '亥'],
      );
      expect(d.shensha.any((s) =>
          s.name == '天乙贵人' && s.pillar == '月' && s.pos == '丑'), isTrue);
      expect(d.shensha.any((s) =>
          s.name == '文昌贵人' && s.pillar == '时' && s.pos == '亥'), isTrue);
      final e = analyzeBaZi(
        gans: ['庚', '戊', '庚', '甲'],
        zhis: ['申', '寅', '申', '申'],
      );
      expect(e.shensha.where((s) => s.name == '禄神').length, 3);
    });
  });
}
