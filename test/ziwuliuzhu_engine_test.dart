import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/services/ziwuliuzhu_engine.dart' as eng;

void main() {
  const validTypes = {'井', '荥', '输', '经', '合', '纳三焦', '纳包络'};

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
    test('2000-01-01 = 庚辰', () {
      final gz = eng.calcDayGanZhi(DateTime(2000, 1, 1, 12), lateZi: false);
      expect(gz.dayGan, 6);
      expect(gz.dayZhi, 4);
    });

    test('甲日子时 = 甲子', () {
      final h = eng.calcHourGanZhi(0, 0, 0);
      expect(h.hourZhi, 0);
      expect(h.hourGan, 0);
    });

    test('晚子时推移等于次日', () {
      final late = eng.calcDayGanZhi(DateTime(2000, 1, 1, 23, 30), lateZi: true);
      final next = eng.calcDayGanZhi(DateTime(2000, 1, 2, 12), lateZi: false);
      expect(late.dayGan, next.dayGan);
      expect(late.dayZhi, next.dayZhi);
    });
  });
}
