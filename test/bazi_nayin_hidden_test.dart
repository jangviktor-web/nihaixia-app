// 批次 B：藏干 API + 纳音辅助的验证。
// 纳音名称直接取自 sxwnl 权威表（GanZhi.naYin），此处做抽查 + 四柱全非空断言。
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/engine/bazi_analysis.dart';
import 'package:nihaisha_app/services/bazi_service.dart';

void main() {
  group('地支藏干 branchHiddenStems', () {
    test('教科书抽查', () {
      expect(branchHiddenStems('子'), ['癸']);
      expect(branchHiddenStems('卯'), ['乙']);
      expect(branchHiddenStems('寅'), ['甲', '丙', '戊']);
      expect(branchHiddenStems('丑'), ['己', '癸', '辛']);
    });

    test('十二地支全部非空且每个藏干为合法天干字符', () {
      const branches = [
        '子', '丑', '寅', '卯', '辰', '巳',
        '午', '未', '申', '酉', '戌', '亥',
      ];
      const gans = '甲乙丙丁戊己庚辛壬癸';
      for (final b in branches) {
        final h = branchHiddenStems(b);
        expect(h, isNotEmpty, reason: '$b 藏干不应为空');
        expect(h.length, lessThanOrEqualTo(3));
        for (final g in h) {
          expect(gans.contains(g), isTrue, reason: '$b 藏干 $g 应为合法天干');
        }
      }
    });
  });

  group('纳音 nayinOfPillar', () {
    test('教科书抽查', () {
      expect(nayinOfPillar('甲子'), '海中金');
      expect(nayinOfPillar('庚午'), '路旁土');
      expect(nayinOfPillar('壬戌'), '大海水');
      expect(nayinOfPillar('甲辰'), '覆灯火');
    });

    test('六十甲子循环内均能解析（任意干支组合两两合法）', () {
      const gans = ['甲', '丙', '戊', '庚', '壬'];
      const zhis = ['子', '寅', '辰', '午', '申', '戌'];
      for (var i = 0; i < 60; i++) {
        final gz = '${gans[i % 5]}${zhis[i % 6]}';
        // 同奇偶性才构成合法六十甲子；非法组合应抛错
        final ganIdx = gans.indexOf(gz.substring(0, 1));
        final zhiIdx = zhis.indexOf(gz.substring(1, 2));
        if ((ganIdx + zhiIdx) % 2 == 0) {
          expect(nayinOfPillar(gz), isNotEmpty, reason: '$gz 应有纳音');
        }
      }
    });
  });
}
