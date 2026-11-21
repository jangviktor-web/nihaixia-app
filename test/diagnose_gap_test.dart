// 自查路径的结构性缺口诊断（探针 + 回归）。
//
// 为什么 AI 拿到资料后经常推翻自查结论？这里把三个可疑点钉成可执行断言：
//   1. 只答 3 题（自查页允许的最低题数）时，定经会不会停在「太阴/少阴」
//      这个两经共用的占位名上，让 diagnose() 落 switch default 直接返回 null；
//   2. extRequired 依赖的兼症（胸闷/心下逆满/少腹急结）在自查路径上有没有入口；
//   3. 有入口之后，那些方是否真的能出得来。
// 运行：flutter test test/diagnose_gap_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/acupoint_repository.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/engine/diagnostic_engine.dart';
import 'package:nihaisha_app/engine/diagnostic_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await FormulaRepository.load();
    await AcupointRepository.load();
  });

  /// 取某道十问题目的选项原文（以 [prefix] 开头的那个）。
  /// 必须用 tenQuestions 的文本：_recordFlatAnswer 按下标映射，
  /// 传 qOptions 的裸文本会因后缀不同而匹配失败、静默不写 _qAnswers。
  String opt(String qKey, String prefix) {
    final q = DiagnosticRules.tenQuestions.firstWhere((e) => e.key == qKey);
    return q.options.firstWhere((o) => o.startsWith(prefix),
        orElse: () => throw StateError('$qKey 找不到以「$prefix」开头的选项'));
  }

  String? run(DiagnosticEngine e) {
    final r = e.diagnose();
    return r == null ? null : '${r.meridian}·${r.pattern}·方=${r.formula}';
  }

  test('只答 3 题不该白扔结果：定经必须细化到单一经名', () {
    final e = DiagnosticEngine();
    // 寒热总纲选「只怕冷不发热」，其 targetMeridian 是「太阴/少阴」两经共用。
    e.answerTemperaturePattern('chills_no_fever');
    e.answerTenQuestion('stool', opt('stool', '便秘'));
    e.answerTenQuestion('sweating', opt('sweating', '不容易出汗'));
    e.answerTenQuestion('thirst', opt('thirst', '不渴'));
    final got = run(e);
    // ignore: avoid_print
    print('[3题] -> $got');
    expect(got, isNotNull,
        reason: '定经停在「太阴/少阴」会让 switch 落 default 返回 null，'
            '用户只看到「信息不足」，白答一遍');
    expect(got, isNot(contains('太阴/少阴')));
  });

  test('兼症（按诊）通道：勾选后对应经方必须可达', () {
    // 这些方的 extRequired 是特异性最高的信号：不勾兼症时它们进不了候选，
    // 自查只能给按经套出来的方，一对照讲义自然显得「AI 更对」。
    final cases = <(String, void Function(DiagnosticEngine), String)>[
      ('桂枝去芍药汤', (e) {
        e.answerTemperaturePattern('fever_chills');
        e.answerTenQuestion('temperature', opt('temperature', '手脚温热'));
      }, 'chest_oppression'),
      ('苓桂术甘汤', (e) {
        e.answerTemperaturePattern('chills_no_fever');
        e.answerTenQuestion('pain', opt('pain', '头晕目眩'));
      }, 'epigastric_reverse_full'),
      ('抵当汤', (e) {
        e.answerTemperaturePattern('chills_no_fever');
        e.answerTenQuestion('stool', opt('stool', '大便色黑'));
      }, 'lesser_abdomen_hard'),
    ];

    for (final (name, seed, extKey) in cases) {
      final before = DiagnosticEngine();
      seed(before);
      final gotBefore = run(before);

      final after = DiagnosticEngine();
      seed(after);
      after.toggleExtSymptom(extKey, true);
      final gotAfter = run(after);

      // ignore: avoid_print
      print('$name | 不勾兼症 -> $gotBefore | 勾 $extKey -> $gotAfter');

      expect(gotAfter, isNotNull, reason: '$name：勾了必选兼症仍拿不到结果');
      expect(gotAfter, contains(name),
          reason: '$name 的必选兼症是 $extKey，勾上它就该出这个方');
    }
  });
}
