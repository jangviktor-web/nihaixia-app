// 医案表完整性体检（常驻护栏）。
//
// 背景：`tool/` 下已有四个只读审计脚本（audit_case_integrity / audit_duplicate_cases
// / case_verify_source / merge_duplicate_cases 的 dry-run），但全靠「记得手动跑」。
// 医案表 1.2 MB / 1445 行，比规则表更容易被改坏，而改坏的方式往往很安静：
//
//   · 某次编辑少了或多了竖线 → 整行 13 列变成 12/14 列，解析器直接跳过它
//   · 合并/补入时把同一源条目挂到两行 → 同一病例出现两次
//   · 批量清洗时把某列清空 → 门禁可用例数骤降，而界面只是「少了一些医案」
//
// 这里把三个审计脚本的核心断言固化成测试，CI 跑 `flutter test` 即生效。
// 允许的漂移：补数据会让空格减少（不拦）；新增病例会让行数上升（不拦）。
// 只有「结构破损」与「数据变少」会红。
//
// 运行：flutter test test/medical_case_integrity_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/medical_case_data.dart';

/// 当前基线（2026-11-23，合并 3 组重复行、补 119 行观点列之后）。改动数据后
/// 若这些数字只是变好（空格更少、行数更多），不必更新；只有变差时才该更新，
/// 并且要先确认是刻意为之。
const _baselineRows = 1444;
const _baselineUsable = 1278;
const _maxEmptyFormula = 133; // 方剂列空 127
const _maxEmptyFourDiag = 640; // 四诊列空 618

/// 与 `parseMedicalCaseTable` 的质量门禁同一判据。注意「未提及」是**精确等于**
/// 才算占位（写 `未提及方剂` 这种是有内容的），早先按 contains 统计会少算 1 例。
bool _usableRow(List<String> r) {
  final f = r[6].trim();
  if (f.isEmpty) return false;
  if (f.contains('未公开')) return false;
  if (f == '未提及') return false;
  // 「同上 / 同前」= 复诊占位，单行无方剂信息（2026-11-23 起与未提及同等对待）
  if (f == '同上' || f == '同前' || f == '同上。' || f == '同前。') return false;
  return true;
}

int _usableCount(List<List<String>> rows) => rows.where(_usableRow).length;

void main() {
  late String raw;
  late List<List<String>> rows;

  setUpAll(() {
    raw = File('assets/medical_cases/cases_table.md').readAsStringSync();
    rows = [];
    for (final line in raw.split('\n')) {
      final t = line.trim();
      if (!t.startsWith('|')) continue;
      final c = t.replaceAll(RegExp(r'^\||\|$'), '').split('|').map((e) => e.trim()).toList();
      if (c.length < 13) continue;
      if (c[0] == '序号' || RegExp(r'^[-: ]+$').hasMatch(c[0])) continue;
      rows.add(c);
    }
  });

  test('每行都是 13 列', () {
    final bad = <String>[];
    for (final line in raw.split('\n')) {
      final t = line.trim();
      if (!t.startsWith('|')) continue;
      final c = t.replaceAll(RegExp(r'^\||\|$'), '').split('|');
      final head = c[0].trim();
      // 只查数据行（首格为纯数字）；表头与分隔行不查。
      // 注意不能先用「列数不足就 continue」——短行会被直接跳过，
      // 断言就永远抓不到「少了竖线」这种最常见的破坏。
      if (!RegExp(r'^\d+$').hasMatch(head)) continue;
      if (c.length != 13) bad.add('$head 行有 ${c.length} 列');
    }
    // ignore: avoid_print
    print('[医案] 数据行 ${rows.length} | 列数异常 ${bad.length}');
    expect(bad, isEmpty, reason: '列数不是 13 的行会被解析器整行跳过：${bad.take(5).join("；")}');
  });

  test('序号唯一且严格升序', () {
    final seqs = <int>[];
    for (final r in rows) {
      final n = int.tryParse(r[0]);
      expect(n, isNotNull, reason: '非数字序号：${r[0]}');
      seqs.add(n!);
    }
    final dup = <int>{};
    final seen = <int>{};
    for (final n in seqs) {
      if (!seen.add(n)) dup.add(n);
    }
    expect(dup, isEmpty, reason: '序号重复：$dup');
    for (var i = 1; i < seqs.length; i++) {
      if (seqs[i] <= seqs[i - 1]) {
        fail('序号非升序：${seqs[i - 1]} → ${seqs[i]}');
      }
    }
  });

  test('日期格式合法或为空', () {
    final dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    final rangeRe = RegExp(r'^\d{4}-\d{2}-\d{2}\s*~\s*\d{4}-\d{2}-\d{2}$');
    final bad = rows
        .where((r) => r[1].isNotEmpty && !dateRe.hasMatch(r[1]) && !rangeRe.hasMatch(r[1]))
        .map((r) => '${r[0]}: ${r[1]}')
        .toList();
    expect(bad, isEmpty, reason: '日期写法不统一，同日比对会漏判：${bad.take(5).join("；")}');
  });

  // art 标记是「表行 → 诊疗日志全文」的唯一桥：classic_search_service 靠
  // `<art:文件名#段号>` 定位到 assets/medical_cases/article_index.json.gz 里的段落。
  // 合并重复行时若只搬 <md:N> 而漏搬 <art:…>，这条链接就静默断掉（2026-11-23 发生过）。
  test('诊疗日志链接标记 <art:…> 数量不得减少', () {
    final artRe = RegExp(r'<art:([^>]+)>');
    final arts = <String>[];
    for (final r in rows) {
      for (final cell in r) {
        for (final m in artRe.allMatches(cell)) {
          arts.add(m.group(1)!);
        }
      }
    }
    // ignore: avoid_print
    print('[医案] art 标记 ${arts.length} 个 | 重复 ${arts.length - arts.toSet().length} 个');
    expect(arts.length, greaterThanOrEqualTo(159),
        reason: 'art 标记数掉了，说明有医案与诊疗日志全文的链接被删断（合并/批处理常见）');
  });

  test('溯源标记 <md:N> 全局唯一', () {
    final tags = <String>[];
    final tagRe = RegExp(r'<md:([^>]+)>');
    for (final r in rows) {
      for (final cell in r) {
        for (final m in tagRe.allMatches(cell)) {
          tags.add(m.group(1)!);
        }
      }
    }
    final dup = <String, int>{};
    for (final t in tags) {
      dup[t] = (dup[t] ?? 0) + 1;
    }
    final repeated = dup.entries.where((e) => e.value > 1).map((e) => '<md:${e.key}>×${e.value}').toList();
    // ignore: avoid_print
    print('[医案] 溯源标记 ${tags.length} 个 | 重复 ${repeated.length} 个');
    expect(repeated, isEmpty,
        reason: '同一个源条目被两行引用＝同一病例出现两次（这正是 D1a/D1b 重复的指纹）：'
            '${repeated.take(5).join("、")}');
  });

  test('数据量不得低于基线（防批量丢失）', () {
    expect(rows.length, greaterThanOrEqualTo(_baselineRows),
        reason: '医案行数从 $_baselineRows 掉了，若非刻意删除请检查合并脚本');

    final usable = _usableCount(rows);
    // ignore: avoid_print
    print('[医案] 可用例数 $usable（方剂非空 / 非「未公开」/ 非纯「未提及·同上」）');
    expect(usable, greaterThanOrEqualTo(_baselineUsable),
        reason: '可用例数从 $_baselineUsable 掉了——门禁可用方骤降会让界面「少一些医案」而不报错');
  });

  test('关键列空格数不得增加', () {
    final emptyFormula = rows.where((r) => r[6].isEmpty).length;
    final emptyFourDiag = rows.where((r) => r[12].isEmpty).length;
    // ignore: avoid_print
    print('[医案] 方剂空 $emptyFormula | 四诊空 $emptyFourDiag');
    expect(emptyFormula, lessThanOrEqualTo(_maxEmptyFormula),
        reason: '方剂列空格增多会让门禁剔除更多医案');
    expect(emptyFourDiag, lessThanOrEqualTo(_maxEmptyFourDiag),
        reason: '四诊列空格增多会直接压低回考可考行数');
  });

  test('解析器与原始统计一致（列不错位）', () {
    final parsed = parseMedicalCaseTable(raw);
    final usable = _usableCount(rows);
    // ignore: avoid_print
    print('[医案] parseMedicalCaseTable -> ${parsed.length} 例');
    expect(parsed.length, usable,
        reason: '解析器给出的例数与「方剂列可用」的行数不一致，说明过滤条件或列下标错位');
    // 序号必须逐一对应，防整体串列
    final parsedSeq = parsed.map((c) => c.seq).toSet();
    final expectSeq = rows
        .where((r) => _usableRow(r))
        .map((r) => int.parse(r[0]))
        .toSet();
    expect(parsedSeq.difference(expectSeq), isEmpty, reason: '解析出的序号与预期不符');
  });
}
