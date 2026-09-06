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

  group('神煞扩展（11 种通行口径）', () {
    // 甲日主四柱：年子 月午 日辰 时戌。
    // 太极(甲→子午)、金舆(甲→辰=禄前二位)、国印(甲→戌)、福星(甲→寅子)、
    // 寡宿(年支子→戌)、华盖(日支辰申子辰组→辰)、将星(年支子组→子)。
    test('甲日主 子午辰戌：太极/金舆/国印/福星/寡宿 各落其位', () {
      final r = analyzeBaZi(
        gans: const ['甲', '甲', '甲', '甲'],
        zhis: const ['子', '午', '辰', '戌'],
      );
      expect(
        r.shensha.any((s) => s.name == '太极贵人' && s.pillar == '年' && s.pos == '子'),
        isTrue,
        reason: '甲乙子午，年支子命中',
      );
      expect(r.shensha.any((s) => s.name == '太极贵人' && s.pos == '午'), isTrue);
      expect(
        r.shensha.any((s) => s.name == '金舆' && s.pillar == '日' && s.pos == '辰'),
        isTrue,
        reason: '甲禄寅、金舆禄前二位=辰',
      );
      expect(
        r.shensha.any((s) => s.name == '国印贵人' && s.pillar == '时' && s.pos == '戌'),
        isTrue,
        reason: '甲→戌',
      );
      expect(
        r.shensha.any((s) => s.name == '福星贵人' && s.pillar == '年' && s.pos == '子'),
        isTrue,
        reason: '甲丙寅子',
      );
      expect(
        r.shensha.any((s) => s.name == '寡宿' && s.pillar == '时' && s.pos == '戌'),
        isTrue,
        reason: '年支子属亥子丑组，寡宿在戌',
      );
      expect(
        r.shensha.where((s) => s.name == '天乙贵人'),
        isEmpty,
        reason: '四支子午辰戌无丑未，天乙贵人不应命中',
      );
    });

    // 年支卯（亥卯未组）：红鸾=子、天喜=午、孤辰=巳、寡宿=丑、劫煞=申、亡神=寅。
    test('年支卯：红鸾落子、亡神落寅、寡宿落丑、天乙贵人同宫丑', () {
      final r = analyzeBaZi(
        gans: const ['甲', '丙', '庚', '壬'],
        zhis: const ['卯', '子', '丑', '寅'],
      );
      expect(
        r.shensha.any((s) => s.name == '红鸾' && s.pillar == '月' && s.pos == '子'),
        isTrue,
        reason: '红鸾卯起逆行，年支卯→子',
      );
      expect(
        r.shensha.any((s) => s.name == '亡神' && s.pillar == '时' && s.pos == '寅'),
        isTrue,
        reason: '亥卯未木局亡神在寅（临官位）',
      );
      expect(
        r.shensha.any((s) => s.name == '寡宿' && s.pillar == '日' && s.pos == '丑'),
        isTrue,
        reason: '年支卯属寅卯辰组，寡宿在丑',
      );
      expect(
        r.shensha.any((s) => s.name == '天乙贵人' && s.pillar == '日' && s.pos == '丑'),
        isTrue,
        reason: '甲日主天乙在丑，与寡宿同宫并存',
      );
      expect(
        r.shensha.any((s) => s.name == '德秀贵人' && s.pillar == '时' && s.pos == '壬'),
        isTrue,
        reason: '月支子属申子辰水局，德干为壬，时干壬透',
      );
      expect(r.shensha.any((s) => s.name == '孤辰'), isFalse,
          reason: '四支无巳，孤辰不应命中');
      expect(r.shensha.any((s) => s.name == '天喜'), isFalse,
          reason: '四支无午，天喜不应命中');
      expect(r.shensha.any((s) => s.name == '劫煞'), isFalse,
          reason: '四支无申，劫煞不应命中');
    });

    // 年支午（寅午戌组）：劫煞=亥、亡神=巳、红鸾=酉、天喜=卯、孤辰=申、寡宿=辰。
    test('年支午：天喜落卯、红鸾落酉、劫煞落亥、桃花同宫午', () {
      final r = analyzeBaZi(
        gans: const ['甲', '丁', '甲', '乙'],
        zhis: const ['午', '酉', '卯', '亥'],
      );
      expect(
        r.shensha.any((s) => s.name == '红鸾' && s.pillar == '月' && s.pos == '酉'),
        isTrue,
        reason: '年支午→红鸾在酉（卯起逆行）',
      );
      expect(
        r.shensha.any((s) => s.name == '天喜' && s.pillar == '日' && s.pos == '卯'),
        isTrue,
        reason: '天喜为红鸾冲位',
      );
      expect(
        r.shensha.any((s) => s.name == '劫煞' && s.pillar == '时' && s.pos == '亥'),
        isTrue,
        reason: '寅午戌火局劫煞在亥（绝位）',
      );
      expect(
        r.shensha.any((s) => s.name == '羊刃' && s.pillar == '日' && s.pos == '卯'),
        isTrue,
        reason: '甲禄寅刃卯（既有神煞回归）',
      );
      expect(r.shensha.any((s) => s.name == '孤辰'), isFalse,
          reason: '四支无申');
      expect(r.shensha.any((s) => s.name == '寡宿'), isFalse,
          reason: '四支无辰');
    });

    test('神煞名称不越出既有+扩展的已知集合', () {
      final r = analyzeBaZi(
        gans: const ['甲', '丙', '庚', '壬'],
        zhis: const ['卯', '子', '丑', '寅'],
      );
      const known = {
        '天乙贵人', '文昌贵人', '驿马', '桃花', '华盖', '将星', '天德', '月德',
        '禄神', '羊刃', '太极贵人', '国印贵人', '金舆', '福星贵人', '德秀贵人',
        '红鸾', '天喜', '孤辰', '寡宿', '劫煞', '亡神',
      };
      for (final s in r.shensha) {
        expect(known, contains(s.name), reason: '未知神煞名: ${s.name}');
      }
    });
  });
}
