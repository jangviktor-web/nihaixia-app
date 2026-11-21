// 医案金标准对照：用《cases_table.md》里倪师亲开的方名当 ground truth，
// 检验「倪师 AI」侧的检索能否把正确方证材料送进上下文。
//
// 判定口径（与 llm_symptom_accuracy_test.dart 一致）：
//   命中 = 方名出现在 r.formulas 列表，或出现在检索片段的 title/snippet 里。
// 这是「依据可达率」，不是「LLM 最终答对率」——LLM 的生成环节需要真实 API，
// 离线只能测到「材料有没有送到嘴边」这一层。
//
// 运行：flutter test test/llm_case_gt_recall_test.dart
import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/acupoint_repository.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/services/llm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await FormulaRepository.load();
    await AcupointRepository.load();
  });

  test('医案金标准方名可达率', () async {
    final raw = await rootBundle.loadString('assets/medical_cases/cases_table.md');
    final fj = jsonDecode(
        await rootBundle.loadString('assets/data/formulas.json')) as Map;
    final all = (fj['formulas'] as List)
        .map((e) => (e as Map)['name'] as String? ?? '')
        .where((s) => s.isNotEmpty)
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    final rows = <List<String>>[];
    for (final line in const LineSplitter().convert(raw)) {
      if (!line.startsWith('|')) continue;
      final c = line.trim().replaceAll(RegExp(r'^\||\|$'), '').split('|');
      final cells = c.map((e) => e.trim()).toList();
      if (cells.length != 13) continue;
      if (!RegExp(r'^\d+$').hasMatch(cells[0])) continue;
      rows.add(cells);
    }
    // ignore: avoid_print
    print('数据行 ${rows.length}');

    // 方名 GT：方剂列（下标 6）里出现的标准方名，最长优先避免「白虎汤」误配
    // 「白虎加人参汤」。四诊列（下标 12）须 >=25 字，否则输入太薄不具判别力。
    final cases = <(String, String, String)>[];
    for (final c in rows) {
      String? gt;
      for (final n in all) {
        if (c[6].contains(n)) {
          gt = n;
          break;
        }
      }
      if (gt == null) continue;
      if (c[12].length < 25) continue;
      cases.add((c[0], gt, c[12]));
    }
    // ignore: avoid_print
    print('金标准样本 ${cases.length} 条（方名 GT + 四诊>=25字）');

    // 每 8 条取 1 条，控制单次跑测在 ~1 分钟内
    final sample = <(String, String, String)>[];
    for (var i = 0; i < cases.length; i += 8) {
      sample.add(cases[i]);
    }
    // ignore: avoid_print
    print('本次抽样 ${sample.length} 条');

    var hit = 0;
    final miss = <String>[];
    for (final (no, gt, text) in sample) {
      final r = await LlmService.prepare(text);
      final classicText =
          r.classics.map((h) => '${h.title}${h.snippet}').join('\n');
      final ok = r.formulas.contains(gt) || classicText.contains(gt);
      if (ok) {
        hit++;
      } else {
        miss.add('#$no GT=$gt 片段=${r.classics.take(3).map((h) => h.sourceLabel).join("·")}');
      }
      // ignore: avoid_print
      print('${ok ? "✓" : "✗"} #$no GT=$gt 方=${r.formulas.take(3).join("/")} '
          '片段=${r.classics.take(2).map((h) => h.sourceLabel).join("·")}');
    }
    // ignore: avoid_print
    print('=== 医案金标准方名可达率：$hit/${sample.length} ===');
    if (miss.isNotEmpty) {
      // ignore: avoid_print
      print('未命中：\n${miss.join("\n")}');
    }
    // 2026-11-21 首测基线：20/34 = 58.8%（四诊全文直接当检索词的最差口径）。
    // 门槛设 55% 只用于防回退；真实链路走 symptom_check_screen 的
    // _buildRetrievalQuery（只取证型+症状短语），可达率高于此口径。
    expect(hit / sample.length, greaterThanOrEqualTo(0.55),
        reason: '医案金标准方名可达率跌破 55% 防回退线');
  }, timeout: const Timeout(Duration(minutes: 10)));
}
