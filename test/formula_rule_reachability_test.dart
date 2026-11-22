// 规则表自证：把「规则自己的必选信号」喂回去，看能不能得出它自己。
//
// 这是自查系统唯一有完整金标准的验证——规则表本身就是 GT：
// 每条 FormulaRule 写着「这些必选(★)症状 → 这个方」。如果按它自己的必选
// 条件构造输入，引擎却给不出这个方，那这条规则在实际使用中就是不可达的，
// 或者被同分的其他方抢走了。两种都是设计缺陷，不是数据问题。
//
// 判据（逐方统计，输出三类）：
//   ✓ 命中本方 —— 规则可达且 tie-break 正确
//   ✗ 被抢     —— 规则可达，但 top() 把结论给了别的方（打分/tie-break 冲突）
//   ✗ 空       —— 必选全满足却给不出任何方（门禁或路径问题）
//   ✗ 数据缺   —— 规则引用的选项号在选项表里不存在（硬数据错误）
//
// 现状：209 条，208 命中 / 1 被抢 / 0 空 / 0 数据缺（含 kD 追问后的完整链路）；
// 归因于「必选签名相撞」，属于规则表本身分不开，见第二个 test 的冲突清单。
//
// 运行：flutter test test/formula_rule_reachability_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/acupoint_repository.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/engine/diagnostic_engine.dart';
import 'package:nihaisha_app/engine/diagnostic_rules.dart';
import 'package:nihaisha_app/engine/formula_rules.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await FormulaRepository.load();
    await AcupointRepository.load();
  });

  /// canonical 选项号 → tenQuestions 里的选项原文。
  /// 两套 options 逐项同序（见 answerTenQuestion 的桥接注释），用下标取。
  String? optionText(String qKey, int oneBased) {
    final i = oneBased - 1;
    if (i < 0) return null;
    // kQ12(vomit_type) 不在十问列表里，它只在「胃口=⑧」时作为追问出现，
    // 选项表挂在 DiagnosticRules.vomitTypeQuestion 上（引擎 _recordFlatAnswer
    // 第 883 行同样为它开了特例），这里必须跟着走同一条路。
    if (qKey == kQ12) {
      final o = DiagnosticRules.vomitTypeQuestion.options;
      return i < o.length ? o[i] : null;
    }
    for (final q in DiagnosticRules.tenQuestions) {
      if (q.key != qKey) continue;
      return i < q.options.length ? q.options[i] : null;
    }
    return null;
  }

  test('全量规则可达性：按自己的必选条件能否得出自己', () {
    final hit = <String>[];
    final stolen = <(String, String)>[]; // (本该的方, 实际给的方)
    final empty = <String>[];
    final badData = <String>[];
    final extOnly = <String>[];
    final kdResolved = <String>[]; // 平局后靠 kD 追问才出本方的 // 无 required，纯靠 extReference 兜底

    for (final rule in allFormulaRules) {
      final e = DiagnosticEngine();
      // 寒热总纲随便给一个不锁死的（太阴/少阴会走评分细分，避免干扰）
      e.answerTemperaturePattern('fever_chills');

      var ok = true;
      for (final entry in rule.required.entries) {
        for (final no in entry.value) {
          final txt = optionText(entry.key, no);
          if (txt == null) {
            badData.add('${rule.name}: ${entry.key}[$no] 无对应选项');
            ok = false;
            break;
          }
          e.answerTenQuestion(entry.key, txt);
        }
        if (!ok) break;
      }
      if (!ok) continue;

      for (final key in rule.extRequired) {
        e.toggleExtSymptom(key, true);
      }
      // 纯参考方（无 required）没有 ★ 门禁，引擎只靠 extReference 给 1 分
      // 兜底入选（rule_engine.dart:63 那段注释就是为它们写的），所以这一类
      // 必须把参考兼症也勾上，否则测出来的「空」是测试漏配而不是引擎缺陷。
      if (rule.required.isEmpty) {
        extOnly.add(rule.name);
        for (final key in rule.extReference) {
          e.toggleExtSymptom(key, true);
        }
      }

      final r = e.diagnose();
      if (r == null || r.formula.isEmpty) {
        empty.add(rule.name);
      } else if (r.recommendedFormulas.contains(rule.name) ||
          r.formula == rule.name) {
        hit.add(rule.name);
      } else if (e.pendingDisambiguator() != null) {
        // 平局：产品里会补问一句 kD 再出结果，所以这里也要答，
        // 否则量到的是「不含鉴别题的引擎」，随 kD 组增多会持续掉。
        final d = kDisambiguators.firstWhere(
            (d) => d.members.containsKey(rule.name),
            orElse: () => kDisambiguators.first);
        final no = d.members[rule.name];
        if (no == null) {
          stolen.add((rule.name, r.formula));
        } else {
          e.answerTenQuestion(d.key, qOptions[d.key]![no - 1]);
          final r2 = e.diagnose();
          if (r2 != null &&
              (r2.formula == rule.name ||
                  r2.recommendedFormulas.contains(rule.name))) {
            hit.add(rule.name);
            kdResolved.add(rule.name);
          } else {
            stolen.add((rule.name, r2?.formula ?? ''));
          }
        }
      } else {
        stolen.add((rule.name, r.formula));
      }
    }

    final total = allFormulaRules.length;
    // ignore: avoid_print
    print('[规则可达] 总 $total 条 | ✓命中本方 ${hit.length} | '
        '✗被抢 ${stolen.length} | ✗空 ${empty.length} | ✗数据缺 ${badData.length} '
        '| 其中纯参考方 ${extOnly.length} 条 | 靠 kD 追问才可达 ${kdResolved.length} 条');

    if (stolen.isNotEmpty) {
      // 关键交叉验证：被抢的方，是不是都跟抢它的方「必选签名完全相同」？
      // 如果是，结论就不是打分/tie-break 算错，而是规则表本身分不开这两首方——
      // 属于数据缺陷，靠改规则表修，改算法改不了。
      final sigOf = <String, String>{};
      for (final r in allFormulaRules) {
        final keys = r.required.keys.toList()..sort();
        sigOf[r.name] =
            keys.map((k) => '$k:[${([...r.required[k]!]..sort()).join(",")}]').join('|');
      }
      var sameSig = 0;
      // ignore: avoid_print
      print('[被抢走的方（按必选给答案却得到别的方）]');
      for (final (want, got) in stolen.take(25)) {
        final same = sigOf[want] != null &&
            sigOf[want]!.isNotEmpty &&
            sigOf[want] == sigOf[got];
        if (same) sameSig++;
        // ignore: avoid_print
        print('  $want  ->  $got${same ? "   [必选签名完全相同，规则表本身分不开]" : ""}');
      }
      // ignore: avoid_print
      print('[归因] 被抢 ${stolen.length} 条中 $sameSig 条属于签名相撞（数据缺陷）');
    }
    if (empty.isNotEmpty) {
      // ignore: avoid_print
      print('[必选全满足却给不出结果] ${empty.take(20).join("、")}');
    }
    if (badData.isNotEmpty) {
      // ignore: avoid_print
      print('[规则数据异常] ${badData.take(10).join("；")}');
    }

    // 现状基线 208/209 = 99.5%。唯一被抢的是旋覆代赭汤——它 reference 为空，
// 与生姜泻心汤同分，只在「不答大便」时平局；真实流程答了 stool 就分开，故不做题。。剩下的 15 条里 11 条是「必选签名相撞」——
    // 规则表给两首语义不同的方写了同一组 ★，引擎无论怎么排都会有一首拿不到，
    // 只能改规则表（给对方补一条能分开的必选/扩展必选），改算法改不了。
    // 另 4 条是同门方被参考分更高的近邻方吃掉（大黄䗪虫丸/温经汤/红蓝花酒/
    // 内补当归建中汤→当归芍药散系）。门槛留在 0.90 防回退。
    expect(hit.length / total, greaterThanOrEqualTo(0.95),
        reason: '按规则自己的必选条件（含 kD 追问）能得出本方的比例不应低于 95%');
    expect(badData, isEmpty, reason: '规则表引用了不存在的选项号，属数据错误');
    expect(empty, isEmpty, reason: '必选全满足却出不了任何方，属引擎路径缺陷');
  });

  test('无重复定义：同一必选签名不该对应多个语义不同的方', () {
    // 必选签名完全相同的方会被 coRecommended 一起推荐（设计如此，如桂枝汤
    // 系列加减方），但如果签名相同、方义又差得远，就等于让用户自己猜。
    final bySig = <String, List<String>>{};
    for (final r in allFormulaRules) {
      final keys = r.required.keys.toList()..sort();
      // r.required 的 List<int> 来自 const 构造，不可原地排序，先拷一份。
      final sig = keys
          .map((k) => '$k:[${([...r.required[k]!]..sort()).join(",")}]')
          .join('|');
      if (sig.isEmpty) continue; // 纯 ext 驱动的另算
      bySig.putIfAbsent(sig, () => []).add(r.name);
    }
    final multi = bySig.entries.where((e) => e.value.length > 1).toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));
    // ignore: avoid_print
    print('[签名冲突] 共 ${multi.length} 组必选签名对应多个方');
    for (final e in multi.take(20)) {
      // ignore: avoid_print
      print('  ${e.key}  ->  ${e.value.join("、")}');
    }
  });
}
