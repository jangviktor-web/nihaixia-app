import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/yijing_data.dart';
import 'package:nihaisha_app/engine/yijing_engine.dart';

void main() {
  group('卦符', () {
    test('King Wen 序与 Unicode 卦符一一对应', () {
      expect(YiJingEngine.symbol(1), '䷀');
      expect(YiJingEngine.symbol(2), '䷁');
      expect(YiJingEngine.symbol(64), '䷿');
    });
  });

  group('数据完整性', () {
    test('64 卦、序号唯一、上下卦合法、爻辞 6 条', () {
      expect(kHexagrams.length, 64);
      expect(kHexagrams.map((h) => h.seq).toSet().length, 64);
      for (final h in kHexagrams) {
        expect(h.upper, inInclusiveRange(0, 7), reason: h.name);
        expect(h.lower, inInclusiveRange(0, 7), reason: h.name);
        expect(h.lines.length, 6, reason: h.name);
        expect(h.judgement, isNotEmpty, reason: h.name);
        expect(h.renjian, isNotEmpty, reason: h.name);
        for (final l in h.lines) {
          expect(l, isNotEmpty, reason: h.name);
        }
      }
    });

    test('上下卦组合全部互不相同（64 种一一映射）', () {
      final keys = kHexagrams.map((h) => '${h.upper}:${h.lower}').toSet();
      expect(keys.length, 64);
    });
  });

  group('卦查找', () {
    test('byUpperLower 命中正确卦', () {
      expect(YiJingEngine.byUpperLower(0, 0)!.name, '乾为天');
      expect(YiJingEngine.byUpperLower(7, 7)!.name, '坤为地');
      expect(YiJingEngine.byUpperLower(5, 7)!.name, '水地比'); // 上坎下坤
      expect(YiJingEngine.byUpperLower(7, 5)!.name, '地水师'); // 上坤下坎
      expect(YiJingEngine.byUpperLower(0, 1)!.name, '天泽履'); // 上乾下兑
      expect(YiJingEngine.byUpperLower(1, 0)!.name, '泽天夬'); // 上兑下乾
    });

    test('bySeq 全部命中', () {
      for (var i = 1; i <= 64; i++) {
        expect(YiJingEngine.bySeq(i), isNotNull, reason: 'seq $i');
      }
    });
  });

  group('手动起卦', () {
    test('乾为天静卦', () {
      final r = YiJingEngine.castManual(1, 1, 0);
      expect(r.primary.name, '乾为天');
      expect(r.moving, 0);
      expect(r.changed, isNull);
      expect(r.movingTitle, '静卦（六爻皆静）');
      expect(r.movingText, r.primary.judgement);
    });

    test('乾卦三爻动 → 变卦天泽履', () {
      final r = YiJingEngine.castManual(1, 1, 3);
      expect(r.primary.name, '乾为天');
      expect(r.changed!.name, '天泽履');
      expect(r.movingTitle, '九三');
      expect(r.movingText, '君子终日乾乾，夕惕若厉，无咎。');
    });

    test('互卦：地天泰 → 雷泽归妹（二三四爻为兑，三四五爻为震）', () {
      final r = YiJingEngine.castManual(8, 1, 1); // 上坤下乾 = 地天泰
      expect(r.primary.name, '地天泰');
      expect(r.nuclear!.name, '雷泽归妹');
    });

    test('坤卦一爻动 → 变卦地雷复', () {
      final r = YiJingEngine.castManual(8, 8, 1); // 坤为地，初六动
      expect(r.primary.name, '坤为地');
      expect(r.changed!.name, '地雷复');
      expect(r.movingTitle, '初六');
      expect(r.movingText, '履霜，坚冰至。');
    });
  });

  group('数字起卦', () {
    test('(1,1) → 乾为天，2爻动', () {
      final r = YiJingEngine.castByNumbers(1, 1);
      expect(r.primary.name, '乾为天');
      expect(r.moving, 2);
      expect(r.movingTitle, '九二');
      expect(r.movingText, '见龙在田，利见大人。');
    });

    test('(6,6) → 坎为水，6爻动（余数为 0 取 6）', () {
      final r = YiJingEngine.castByNumbers(6, 6);
      expect(r.primary.name, '坎为水');
      expect(r.moving, 6);
      expect(r.movingTitle, '上六');
    });

    test('(2,1) → 泽天夬，3爻动', () {
      final r = YiJingEngine.castByNumbers(2, 1);
      expect(r.primary.name, '泽天夬');
      expect(r.moving, 3);
    });

    test('大数余数归一', () {
      final r = YiJingEngine.castByNumbers(17, 17); // 17%8=1, 34%6=4
      expect(r.primary.name, '乾为天');
      expect(r.moving, 4);
    });
  });

  group('时间起卦', () {
    test('任意时间结果合法（上下卦 0-7，动爻 1-6）', () {
      final r = YiJingEngine.castByTime(DateTime(2026, 8, 17, 9));
      expect(r.primary, isNotNull);
      expect(r.moving, inInclusiveRange(1, 6));
      expect(r.changed, isNotNull);
      expect(r.nuclear, isNotNull);
      expect(r.primarySymbol, isNotEmpty);
      expect(r.changedSymbol, isNotEmpty);
    });

    test('同一时间结果稳定', () {
      final a = YiJingEngine.castByTime(DateTime(2026, 1, 1, 0));
      final b = YiJingEngine.castByTime(DateTime(2026, 1, 1, 0));
      expect(a.primary.seq, b.primary.seq);
      expect(a.moving, b.moving);
    });
  });

  group('爻题', () {
    test('阳爻九、阴爻六', () {
      expect(YiJingEngine.lineTitle(1, true), '初九');
      expect(YiJingEngine.lineTitle(2, false), '六二');
      expect(YiJingEngine.lineTitle(5, true), '九五');
      expect(YiJingEngine.lineTitle(6, false), '上六');
    });
  });
}
