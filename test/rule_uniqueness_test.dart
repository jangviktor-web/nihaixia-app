// 规则表完整性：方名唯一。
//
// 背景：同一首方写两遍会让它自己跟自己平局（tiedTop 返回两条同名），
// coRecommended 推出「某汤、某汤」，且 kD 追问永远不触发（members 是 Set，
// 同名只算 1 个）。已经踩过两次：葛根芩连汤、百合地黄汤。
//
// 运行：flutter test test/rule_uniqueness_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/acupoint_repository.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/engine/formula_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await FormulaRepository.load();
    await AcupointRepository.load();
  });

  test('规则表里不应有重名方剂', () {
    final seen = <String, int>{};
    for (final r in allFormulaRules) {
      seen[r.name] = (seen[r.name] ?? 0) + 1;
    }
    final dup = seen.entries.where((e) => e.value > 1).toList();
    // ignore: avoid_print
    print('[规则表] ${allFormulaRules.length} 条 / ${seen.length} 个方名 | '
        '重名 ${dup.length} 个${dup.isEmpty ? "" : "：${dup.map((e) => "${e.key}x${e.value}").join("、")}"}');
    expect(dup, isEmpty,
        reason: '同名方会自己跟自己平局、coRecommended 出重复项、kD 追问永远不触发');
  });

  test('鉴别表的每个成员都能在规则表里找到', () {
    final names = allFormulaRules.map((r) => r.name).toSet();
    final missing = <String>[];
    for (final d in kDisambiguators) {
      for (final n in d.members.keys) {
        if (!names.contains(n)) missing.add('${d.key}:$n');
      }
    }
    expect(missing, isEmpty, reason: '鉴别表引用了不存在的方：${missing.join("、")}');
  });
}
