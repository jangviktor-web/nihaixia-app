import 'package:flutter_test/flutter_test.dart';
import 'package:ziwei_core/ziwei_core.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart';
import 'package:nihaisha_app/services/ziwei_interpretation.dart';

/// ② 庙旺利陷（dignityAdjective）单测 + 句式冒烟测试。
void main() {
  group('dignityAdjective 映射', () {
    test('七档亮度映射齐全', () {
      expect(dignityAdjective('庙'), '得地有力');
      expect(dignityAdjective('旺'), '乘旺');
      expect(dignityAdjective('得'), '得地');
      expect(dignityAdjective('利'), '平顺');
      expect(dignityAdjective('平'), '中和');
      expect(dignityAdjective('不'), '势弱');
      expect(dignityAdjective('陷'), '偏弱');
    });
    test('null / 未知 → 空串（调用方可据此跳过）', () {
      expect(dignityAdjective(null), '');
      expect(dignityAdjective(''), '');
      expect(dignityAdjective('xyz'), '');
    });
  });

  group('starDisplayText / starDignityPhrase', () {
    final star = ZiweiStar(
      key: 'wuqu',
      label: '武曲',
      type: StarType.major,
      brightness: '庙',
      sihua: SiHuaType.lu,
    );
    test('starDisplayText 含亮度与四化', () {
      expect(starDisplayText(star), '武曲(庙·禄)');
    });
    test('starDisplayText 空亮度/空四化不画空括号', () {
      final s = ZiweiStar(
        key: 'k',
        label: '某星',
        type: StarType.other,
      );
      expect(starDisplayText(s), '某星');
    });
    test('starDignityPhrase 追加亮度形容词', () {
      expect(starDignityPhrase(star), '武曲(庙·禄)·得地有力');
    });
  });

  group('句式冒烟：运势总结含庙旺利陷措辞', () {
    late ZiweiChart chart;
    setUpAll(() {
      chart = calculateZiweiChart(
        solar: DateTime(1990, 6, 15, 0, 0),
        gender: Gender.male,
        useTrueSolarTime: false,
      );
    });

    test('summarizeDecades 至少一条大限含庙旺利陷形容词', () {
      final decades = summarizeDecades(chart).join(' ');
      final adjs = [
        '得地有力',
        '乘旺',
        '得地',
        '平顺',
        '中和',
        '势弱',
        '偏弱',
      ];
      final hit = adjs.where((a) => decades.contains(a)).toList();
      print('[decades dignity] 命中措辞=$hit');
      expect(hit, isNotEmpty);
    });

    test('summarizeOverall 不抛异常且非空', () {
      final out = summarizeOverall(chart);
      print('[overall] $out');
      expect(out, isNotEmpty);
    });
  });
}
