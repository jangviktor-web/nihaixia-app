import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/services/ziwuliuzhu_engine.dart' as eng;

const List<String> zhi = ['子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥'];

void main() {
  const validTypes = {'井', '荥', '输', '经', '合', '纳三焦', '纳包络'};

  /// 纳甲开穴名（无正开穴则回落合日互用，仍无则 '-'）。
  String najiaPoint(int dayGan, int hourGan, int hourZhi) {
    final open = eng.najiaOpen(dayGan, hourGan, hourZhi);
    if (open != null) return open['point']!;
    final he = eng.najiaHeRi(dayGan, hourGan, hourZhi);
    if (he != null) return he['point']!;
    return '-';
  }

  group('纳甲法', () {
    test('查表完整且无键冲突（共 60 正开穴）', () {
      int nonNull = 0;
      for (int d = 0; d < 10; d++) {
        for (int hg = 0; hg < 10; hg++) {
          for (int hz = 0; hz < 12; hz++) {
            final r = eng.najiaOpen(d, hg, hz);
            if (r != null) {
              nonNull++;
              expect(r['point'], isNotNull);
              expect(r['meridian'], isNotNull);
              expect(validTypes.contains(r['type']), isTrue);
              expect((r['type'] == '输') == (r['yuan'] != null), isTrue);
            }
          }
        }
      }
      expect(nonNull, 60);
    });

    test('甲日戌时开胆经井穴 窍阴', () {
      final r = eng.najiaOpen(0, 0, 10);
      expect(r, isNotNull);
      expect(r!['point'], '窍阴');
      expect(r['meridian'], '胆经');
    });

    test('无正开穴时合日互用回退', () {
      bool triggered = false;
      for (int d = 0; d < 10 && !triggered; d++) {
        for (int hg = 0; hg < 10 && !triggered; hg++) {
          for (int hz = 0; hz < 12 && !triggered; hz++) {
            if (eng.najiaOpen(d, hg, hz) == null && eng.najiaHeRi(d, hg, hz) != null) {
              triggered = true;
            }
          }
        }
      }
      expect(triggered, isTrue);
      // 甲日亥时无正开穴，应可合日互用
      expect(eng.najiaHeRi(0, 1, 11), isNotNull);
    });
  });

  group('灵龟八法', () {
    test('甲日子时 → 艮/内关', () {
      final r = eng.lingguiOpen(0, 0, 0, 0);
      expect(r['rem'], 8);
      expect(r['gua'][0], '艮');
      expect(r['gua'][1], '内关');
      expect(r['peidui'], '公孙');
      expect(r['peiduiMai'], '冲脉');
    });

    test('余数5：中宫寄坤 → 照海', () {
      // dayGan=0,zhi=0,hourGan=0,zhi=3 → sum=35, 阳日÷9 余5
      final r = eng.lingguiOpen(0, 0, 0, 3);
      expect(r['rem'], 5);
      expect(r['effectiveRem'], 2);
      expect(r['gua'][1], '照海');
    });

    test('余数5：女寄艮 → 内关', () {
      final r = eng.lingguiOpen(0, 0, 0, 3, fiveMode: 'gender', sex: 'female');
      expect(r['effectiveRem'], 8);
      expect(r['gua'][1], '内关');
    });

    test('余数在合法范围', () {
      for (int d = 0; d < 10; d++) {
        for (int dz = 0; dz < 12; dz++) {
          for (int hg = 0; hg < 10; hg++) {
            for (int hz = 0; hz < 12; hz++) {
              final r = eng.lingguiOpen(d, dz, hg, hz);
              expect(r['rem'] >= 1 && r['rem'] <= r['div'], isTrue);
              expect(r['effectiveRem'] >= 1 && r['effectiveRem'] <= 9, isTrue);
              expect(r['gua'], hasLength(3));
              expect(r['peidui'], isNotNull);
            }
          }
        }
      }
    });
  });

  group('飞腾八法', () {
    test('十干均有所属', () {
      for (int hg = 0; hg < 10; hg++) {
        final ft = eng.feitengOpen(hg);
        expect(ft, isNotNull);
        expect(ft, hasLength(2));
      }
    });
  });

  group('干支推算', () {
    // ⛔ 硬编码锚点曾写「2000-01-01 = 庚辰」，真实为**戊午**（差 22 天）。
    //    该错误导致日干支系统性偏移 → 纳甲/灵龟/飞腾三法全部算错。
    //    现已改由 bazi_core 排盘（与八字/农历同口径），此用例防回归。
    test('2000-01-01 = 戊午（非庚辰）', () {
      final gz = eng.calcDayGanZhi(DateTime(2000, 1, 1, 12));
      expect(gz.dayGan, 4); // 戊
      expect(gz.dayZhi, 6); // 午
    });

    test('1949-10-01 = 甲子（参考站 acuherb.xyz/ziwu 锚点）', () {
      final gz = eng.calcDayGanZhi(DateTime(1949, 10, 1, 12));
      expect(gz.dayGan, 0);
      expect(gz.dayZhi, 0);
    });

    test('甲日子时 = 甲子', () {
      final h = eng.calcHourGanZhi(0, 0, 0);
      expect(h.hourZhi, 0);
      expect(h.hourGan, 0);
    });

    // 取穴模块固定「23:00 换日」（参考站 acuherb 口径，与八字排盘的晚子时不同）
    test('23:30 起按次日干支（子时换日）', () {
      final late = eng.calcDayGanZhi(DateTime(2000, 1, 1, 23, 30));
      final next = eng.calcDayGanZhi(DateTime(2000, 1, 2, 12));
      expect(late.dayGan, next.dayGan);
      expect(late.dayZhi, next.dayZhi);
    });

    test('22:30 仍属当日（23:00 才换日）', () {
      final before = eng.calcDayGanZhi(DateTime(2000, 1, 1, 22, 30));
      final today = eng.calcDayGanZhi(DateTime(2000, 1, 1, 12));
      expect(before.dayGan, today.dayGan);
      expect(before.dayZhi, today.dayZhi);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // 黄金回归夹具：acuherb.xyz/ziwu（中医时辰开穴 · 综合版）公开的
  // 乙卯日（2026-10-08）十二时辰三法总表 —— 36 个期望值。
  //
  // 每个时辰四列：[纳甲, 灵龟主穴, 灵龟配穴, 飞腾]
  // '-' 表示该时辰纳甲正开穴与合日互用皆无（巳、未时）。
  //
  // ⛔ 这些值是外部权威站硬算例，改动引擎却不过此组 = 直接算错，
  //    不要顺手把期望值改成引擎的输出。
  // ─────────────────────────────────────────────────────────────
  group('黄金回归 · acuherb 乙卯日三法总表', () {
    const Map<int, List<String>> expected = {
      0:  ['前谷', '外关', '临泣', '内关'],
      1:  ['少海', '申脉', '后溪', '照海'],
      2:  ['陷谷', '照海', '列缺', '临泣'],
      3:  ['间使', '照海', '列缺', '列缺'],
      4:  ['阳溪', '公孙', '内关', '外关'],
      5:  ['-',    '临泣', '外关', '后溪'],
      6:  ['委中', '照海', '列缺', '公孙'],
      7:  ['-',    '公孙', '内关', '申脉'],
      8:  ['液门', '外关', '临泣', '公孙'],
      9:  ['大敦', '申脉', '后溪', '申脉'],
      10: ['阳谷', '照海', '列缺', '内关'],
      11: ['少府', '外关', '临泣', '照海'],
    };

    test('2026-10-08 排盘 = 乙卯日', () {
      final gz = eng.calcDayGanZhi(DateTime(2026, 10, 8, 12));
      expect(gz.dayGan, 1); // 乙
      expect(gz.dayZhi, 3); // 卯
    });

    for (int hz = 0; hz < 12; hz++) {
      test('${zhi[hz]}时：纳甲 / 灵龟 / 飞腾 三法', () {
        const dayGan = 1, dayZhi = 3; // 乙卯
        // 时柱由五鼠遁推（顺带校验 calcHourGanZhi）
        final h = eng.calcHourGanZhi(dayGan, hz * 2, 0);
        expect(h.hourZhi, hz, reason: '${zhi[hz]}时 时辰索引');

        final exp = expected[hz]!;

        expect(najiaPoint(dayGan, h.hourGan, hz), exp[0],
            reason: '${zhi[hz]}时 纳甲法');

        final lg = eng.lingguiOpen(dayGan, dayZhi, h.hourGan, hz);
        expect((lg['gua'] as List<String>)[1], exp[1],
            reason: '${zhi[hz]}时 灵龟八法主穴');
        expect(lg['peidui'] as String, exp[2],
            reason: '${zhi[hz]}时 灵龟八法配穴');

        final ft = eng.feitengOpen(h.hourGan);
        expect(ft?[1] ?? '-', exp[3], reason: '${zhi[hz]}时 飞腾八法');
      });
    }
  });
}
