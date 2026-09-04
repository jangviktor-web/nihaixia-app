// P0-2：bazi_analysis.dart（详批引擎，402 行）的 golden 回归测试。
//
// 断言全部锚定「可查表的教科书事实」与代码内常量表，避免凭记忆猜命例：
//   - 天乙贵人：甲戊庚→丑未（乙己→子申、丙丁→亥酉、壬癸→卯巳、辛→午寅）
//   - 禄神：甲→寅、庚→申；羊刃（禄前一位）：甲→卯、庚→酉
//   - 格局：月支=禄→建禄格；月支=刃→羊刃格；月支藏干透干→十神格
//   - 强弱评分：得令(monthSupport) + 得地(藏干 0.5/0.3) + 得势(比劫1.0/印0.7)
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/engine/bazi_analysis.dart';

void main() {
  group('神煞', () {
    test('甲日主见丑：天乙贵人落在月支（甲戊庚牛羊）', () {
      final r = analyzeBaZi(
        gans: const ['甲', '丙', '甲', '甲'],
        zhis: const ['子', '丑', '子', '子'],
      );
      final hit = r.shensha
          .where((s) => s.name == '天乙贵人' && s.pillar == '月' && s.pos == '丑');
      expect(hit, isNotEmpty, reason: '甲日干查天乙贵人表→丑未，月支丑应命中');
    });

    test('庚日主四柱皆申：禄神四现', () {
      final r = analyzeBaZi(
        gans: const ['庚', '戊', '庚', '庚'],
        zhis: const ['申', '申', '申', '申'],
      );
      final lu = r.shensha.where((s) => s.name == '禄神').toList();
      expect(lu.length, 4, reason: '庚禄在申，四支皆申应四现');
    });

    test('甲日主日支见卯：羊刃（禄前一位，甲禄寅刃卯）', () {
      final r = analyzeBaZi(
        gans: const ['甲', '丙', '甲', '甲'],
        zhis: const ['子', '子', '卯', '子'],
      );
      final hit = r.shensha
          .where((s) => s.name == '羊刃' && s.pillar == '日' && s.pos == '卯');
      expect(hit, isNotEmpty, reason: '甲禄在寅、刃在卯，日支卯应命中羊刃');
    });
  });

  group('格局', () {
    test('庚日主月支申：建禄格', () {
      final r = analyzeBaZi(
        gans: const ['庚', '戊', '庚', '庚'],
        zhis: const ['申', '申', '子', '申'],
      );
      expect(r.pattern, '建禄格', reason: '月支为日主之禄（庚禄在申）→建禄格');
    });

    test('庚日主月支酉：羊刃格', () {
      final r = analyzeBaZi(
        gans: const ['庚', '乙', '庚', '庚'],
        zhis: const ['辰', '酉', '子', '丑'],
      );
      expect(r.pattern, '羊刃格', reason: '月支为日主之刃（庚刃在酉）→羊刃格');
    });

    test('甲日主月支丑、年干己透出：正财格（藏干透干优先）', () {
      final r = analyzeBaZi(
        gans: const ['己', '丙', '甲', '庚'],
        zhis: const ['丑', '丑', '子', '子'],
      );
      expect(r.pattern, '正财格',
          reason: '丑藏己癸辛，年干己透出（己为甲之正财）→正财格');
    });
  });

  group('日主强弱', () {
    test('庚金得令得地得势 → 身强，用神含官杀火', () {
      final r = analyzeBaZi(
        gans: const ['庚', '戊', '庚', '庚'],
        zhis: const ['申', '申', '辰', '申'],
      );
      // 得令申月金+3；得地三申(庚+0.5、戊生金+0.3)×2处+辰戊+0.3=1.9；得势庚+1.0、
      // 戊生金+0.7、庚+1.0=2.7 → 合计 7.6 ≥ 6 → 极旺
      expect(r.strengthLevel, '极旺');
      expect(r.favorable, contains('火(官杀)'),
          reason: '身强克泄耗：官杀（火克金）为用');
      expect(r.unfavorable, contains('金(比劫)'),
          reason: '身强忌比劫');
    });

    test('甲木失令无势 → 身弱，用神含印水', () {
      final r = analyzeBaZi(
        gans: const ['庚', '丙', '甲', '庚'],
        zhis: const ['申', '酉', '午', '申'],
      );
      // 得令酉月木-1；仅两处申藏壬水生木+0.3×2 → -0.4 → 身弱
      expect(r.strengthLevel, '身弱');
      expect(r.favorable, contains('水(印)'),
          reason: '身弱生扶：印（水生木）为用');
      expect(r.unfavorable, contains('金(官杀)'),
          reason: '身弱忌官杀');
    });
  });

  group('五行分布', () {
    test('五个元素齐全且金旺（庚金三透+三申藏庚）', () {
      final r = analyzeBaZi(
        gans: const ['庚', '戊', '庚', '庚'],
        zhis: const ['申', '申', '辰', '申'],
      );
      expect(r.fiveElements.length, 5);
      final metal =
          r.fiveElements.firstWhere((e) => e.element == '金');
      expect(metal.status, '旺', reason: '金占比过半（≥30% 阈值）');
    });
  });
}
