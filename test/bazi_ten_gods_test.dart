import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/engine/bazi_ten_gods.dart';

void main() {
  group('十神（相对日主，阳/阴日主双表）', () {
    test('日主甲（阳）：十神位移表', () {
      const day = '甲';
      expect(tenGodForGan(day, '甲'), '比肩'); // +0
      expect(tenGodForGan(day, '乙'), '劫财'); // +1
      expect(tenGodForGan(day, '丙'), '食神'); // +2
      expect(tenGodForGan(day, '丁'), '伤官'); // +3
      expect(tenGodForGan(day, '戊'), '偏财'); // +4
      expect(tenGodForGan(day, '己'), '正财'); // +5
      expect(tenGodForGan(day, '庚'), '七杀'); // +6
      expect(tenGodForGan(day, '辛'), '正官'); // +7
      expect(tenGodForGan(day, '壬'), '偏印'); // +8
      expect(tenGodForGan(day, '癸'), '正印'); // +9
    });

    test('日主乙（阴）：十神位移表', () {
      const day = '乙';
      expect(tenGodForGan(day, '乙'), '比肩'); // +0
      expect(tenGodForGan(day, '丙'), '伤官'); // +1
      expect(tenGodForGan(day, '丁'), '食神'); // +2
      expect(tenGodForGan(day, '戊'), '正财'); // +3
      expect(tenGodForGan(day, '己'), '偏财'); // +4
      expect(tenGodForGan(day, '庚'), '正官'); // +5
      expect(tenGodForGan(day, '辛'), '七杀'); // +6
      expect(tenGodForGan(day, '壬'), '正印'); // +7
      expect(tenGodForGan(day, '癸'), '偏印'); // +8
      expect(tenGodForGan(day, '甲'), '劫财'); // +9
    });

    test('四柱逐柱十神：日柱位固定为「日主」', () {
      // 日主丙，四柱天干 乙/戊/丙/庚
      final r = tenGodsPerPillar('丙', const ['乙', '戊', '丙', '庚']);
      expect(r.length, 4);
      expect(r[0], '正印'); // 乙见丙(阴生阳)→正印
      expect(r[1], '食神'); // 戊见丙(阳生阳)→食神
      expect(r[2], '日主'); // 日柱
      expect(r[3], '偏财'); // 庚见丙(阳克阳)→偏财
    });

    test('unknown 天干返回空串', () {
      expect(tenGodForGan('甲', 'X'), '');
    });
  });

  group('旬空（空亡）', () {
    test('经典旬空口诀校验', () {
      expect(kongWang('甲', '子'), ['戌', '亥']); // 甲子旬戌亥空
      expect(kongWang('甲', '戌'), ['申', '酉']); // 甲戌旬申酉空
      expect(kongWang('戊', '申'), ['寅', '卯']); // 甲辰旬寅卯空
      expect(kongWang('丙', '寅'), ['戌', '亥']); // 甲子旬戌亥空
      expect(kongWang('甲', '寅'), ['子', '丑']); // 甲寅旬子丑空
      expect(kongWang('甲', '午'), ['辰', '巳']); // 甲午旬辰巳空
    });

    test('空亡需日干+日支联立（甲戌日非空戌亥）', () {
      // 单看日干甲会误判戌亥，联立日支戌后正确为申酉。
      expect(kongWang('甲', '戌'), ['申', '酉']);
    });

    test('unknown 返回空', () {
      expect(kongWang('X', '子'), isEmpty);
    });
  });
}
