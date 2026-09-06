import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/engine/bazi_twelve_stages.dart';

void main() {
  group('长生十二神 · 火土同宫（现代子平主流）', () {
    test('阳干顺行：甲木长生在亥，丙火长生在寅', () {
      expect(twelveStageFor('甲', '亥', TwelveStageMode.fireEarthSame), '长生');
      expect(twelveStageFor('丙', '寅', TwelveStageMode.fireEarthSame), '长生');
    });

    test('阳土火土同宫：戊长生在寅', () {
      expect(twelveStageFor('戊', '寅', TwelveStageMode.fireEarthSame), '长生');
    });

    test('阴干逆行：乙木长生在午，病在子', () {
      expect(twelveStageFor('乙', '午', TwelveStageMode.fireEarthSame), '长生');
      expect(twelveStageFor('乙', '子', TwelveStageMode.fireEarthSame), '病');
    });

    test('阴土火土同宫：己长生在酉', () {
      expect(twelveStageFor('己', '酉', TwelveStageMode.fireEarthSame), '长生');
    });

    test('己卯：火土同宫为「病」', () {
      // 日主己（阴土），地支卯。火土同宫 己长生在酉，卯为逆行第 6 位 → 病。
      expect(twelveStageFor('己', '卯', TwelveStageMode.fireEarthSame), '病');
    });
  });

  group('长生十二神 · 水土同宫（部分古籍 / 纳音派）', () {
    test('阳土水土同宫：戊长生在申', () {
      expect(twelveStageFor('戊', '申', TwelveStageMode.waterEarthSame), '长生');
    });

    test('阴土水土同宫：己长生在卯', () {
      expect(twelveStageFor('己', '卯', TwelveStageMode.waterEarthSame), '长生');
    });

    test('己卯：水土同宫为「长生」', () {
      // 与火土同宫（病）恰好相反，验证口径互斥、无静默错算。
      expect(twelveStageFor('己', '卯', TwelveStageMode.waterEarthSame), '长生');
    });

    test('非土干两种口径结果一致（甲木长生在亥）', () {
      expect(twelveStageFor('甲', '亥', TwelveStageMode.fireEarthSame),
          equals(twelveStageFor('甲', '亥', TwelveStageMode.waterEarthSame)));
    });
  });

  group('长生十二神 · 四柱批量', () {
    test('twelveStagesForPillars 返回四柱顺序标签', () {
      final stages = twelveStagesForPillars(
        '己',
        ['子', '丑', '卯', '辰'],
        mode: TwelveStageMode.fireEarthSame,
      );
      expect(stages.length, 4);
      expect(stages[2], '病'); // 日柱地支卯 → 火土同宫为病
    });

    test('非法干支返回空串', () {
      expect(twelveStageFor('甲', 'X', TwelveStageMode.fireEarthSame), '');
      expect(twelveStageFor('Z', '子', TwelveStageMode.fireEarthSame), '');
    });
  });
}
