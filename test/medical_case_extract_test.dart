import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/data/medical_case_data.dart';

/// 医案/LLM 抽取器 extractFormulaNames 的回归。
///
/// 它同时被 llm_service 用于检索关键词、引用核对（unverifiedFormulas）、
/// 相关医案，所以既不能漏抽异写，也不能让短正名截胡长异写。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('方名异写能抽出并归一到正名', () async {
    await FormulaRepository.load();
    const cases = <String, String>{
      '黄耆建中汤': '黄芪建中汤',
      '防己黄耆汤': '防己黄芪汤',
      '桂枝龙骨牡蛎汤': '桂枝加龙骨牡蛎汤',
      '麻仁丸': '麻子仁丸',
      '麻黄杏仁甘草石膏汤': '麻杏甘石汤',
      '耆芍桂酒汤': '黄芪芍药桂枝苦酒汤',
      '白虎人参汤': '白虎加人参汤',
      '八味肾气丸': '肾气丸',
    };
    final bad = <String>[];
    for (final e in cases.entries) {
      final got = extractFormulaNames(e.key);
      if (got.length != 1 || got.first != e.value) {
        bad.add('${e.key} → 期望 [${e.value}]，实际 $got');
      }
    }
    expect(bad, isEmpty, reason: '异写抽取异常：\n${bad.join('\n')}');
  });

  test('短正名不截胡长异写（白虎人参汤 ≠ 人参汤）', () async {
    await FormulaRepository.load();
    // 修正前实测返回 ['人参汤']、['牡蛎汤']——比漏抽更糟，会把医案归错方。
    expect(extractFormulaNames('白虎人参汤'), isNot(contains('人参汤')));
    expect(extractFormulaNames('桂枝龙骨牡蛎汤'), isNot(contains('牡蛎汤')));
  });

  test('正名与箭头分段不受影响', () async {
    await FormulaRepository.load();
    expect(extractFormulaNames('桂枝汤'), contains('桂枝汤'));
    expect(
      extractFormulaNames('小柴胡汤 → 大柴胡汤'),
      containsAll(<String>['小柴胡汤', '大柴胡汤']),
    );
  });
}
