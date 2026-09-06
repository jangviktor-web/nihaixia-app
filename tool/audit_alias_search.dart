// 药材异名检索覆盖审计（防回归基线）
//
// 背景：提交 c67ad63 做了「同药异名合并」——把异名独立条目从 herbs.json 删除，
// 只保留正名条目，并在 herb_repository.dart 的 `_canonicalOf` 登记「异名 → 正名」。
// 后果：任何只按 herb.name 裸匹配、没走 canonicalOf 归一的代码，遇到异名查询必然返回空。
// 当时 knowledge_screen（药库列表）与 search_tab（联想框）各复制了一份匹配逻辑且都漏了归一，
// 导致 103 个异名中 74 / 87 个搜不到（典型：茈胡 搜不到 柴胡）。
//
// 本脚本把「全部异名 + 全部正名」逐条跑一遍统一匹配逻辑，失效数必须为 0。
// **改动 _canonicalOf 或 herbs.json 后必须重跑。**
//
// 运行（Windows，注意 TEMP 必须显式指定，%TEMP% 指向的 Y:\Temp 不可用）：
//   cd /d/AndroidProjects/nihaisha_app
//   TEMP="C:/Users/jangviktor/AppData/Local/Temp" TMP="C:/Users/jangviktor/AppData/Local/Temp" \
//     /d/flutter/bin/dart tool/audit_alias_search.dart
//
// 退出码：0 = 全部通过；1 = 存在失效项或有异常。

import 'dart:convert';
import 'dart:io';

const herbRepoPath = 'lib/data/herb_repository.dart';
const herbsJsonPath = 'assets/data/herbs.json';

/// 从 herb_repository.dart 源码解析 `_canonicalOf` 映射。
/// 不硬编码映射表 —— 必须随源码变化而变化，否则审计会与实现脱节。
Map<String, String> parseCanonicalOf(String src) {
  // 匹配 `_canonicalOf = { ... };`（常量以 `\n  };` 收尾）
  final block = RegExp(
    r'_canonicalOf\s*=\s*\{(.*?)\n  \};',
    dotAll: true,
  ).firstMatch(src);
  if (block == null) {
    stderr.writeln('[FATAL] 未在 $herbRepoPath 中定位到 _canonicalOf 常量。');
    exit(1);
  }
  final pairs = RegExp(r"'([^']+)'\s*:\s*'([^']+)'").allMatches(block.group(1)!);
  return {for (final m in pairs) m.group(1)!: m.group(2)!};
}

/// 与 HerbRepository.matchesQuery 保持一致的匹配逻辑。
/// ⚠️ 若修改了 herb_repository.dart 的 matchesQuery，本函数必须同步修改，
///    否则审计的就不是真实行为。
bool matchesQuery(Map<String, dynamic> h, String query, Map<String, String> canon) {
  if (query.isEmpty) return false;
  final q = query.toLowerCase();
  final cq = (canon[query] ?? query).toLowerCase();
  String s(Object? v) => (v ?? '').toString().toLowerCase();
  final meridians = (h['meridians'] as List<dynamic>? ?? <dynamic>[])
      .map((m) => m.toString().toLowerCase());
  return s(h['name']).contains(q) ||
      s(h['name']).contains(cq) ||
      s(h['action']).contains(q) ||
      s(h['nature']).contains(q) ||
      s(h['original']).contains(q) ||
      s(h['flavor']).contains(q) ||
      s(h['category']).contains(q) ||
      meridians.any((m) => m.contains(q));
}

void main() {
  final repoFile = File(herbRepoPath);
  final jsonFile = File(herbsJsonPath);
  if (!repoFile.existsSync() || !jsonFile.existsSync()) {
    stderr.writeln('[FATAL] 找不到 $herbRepoPath 或 $herbsJsonPath。'
        '请在项目根目录运行本脚本。');
    exit(1);
  }

  final canon = parseCanonicalOf(repoFile.readAsStringSync());
  final data = json.decode(jsonFile.readAsStringSync()) as Map<String, dynamic>;
  final herbs = (data['herbs'] as List<dynamic>).cast<Map<String, dynamic>>();
  final names = herbs.map((h) => h['name'].toString()).toList();

  stdout.writeln('药材条目数      : ${herbs.length}  (total 字段: ${data['total']})');
  stdout.writeln('_canonicalOf 映射: ${canon.length}');
  stdout.writeln('');

  // 自检 1：映射目标（正名）必须真实存在，否则是悬空死链
  final dangling = canon.entries.where((e) => !names.contains(e.value)).toList();
  // 自检 2：异名不应仍拥有独立条目，否则合并没做干净
  final unmerged = canon.keys.where((k) => names.contains(k)).toList();
  // 自检 3：herbs.json 内部不应有重名
  final dup = names.where((n) => names.where((x) => x == n).length > 1).toSet().toList();

  stdout.writeln('自检 1 悬空别名(映射目标不存在) : ${dangling.length}');
  for (final e in dangling) {
    stdout.writeln('    ${e.key} → ${e.value}  [正名缺失]');
  }
  stdout.writeln('自检 2 未合并(异名仍有独立条目) : ${unmerged.length}');
  for (final k in unmerged) {
    stdout.writeln('    $k → 应归入 ${canon[k]}，但自己仍占一页');
  }
  stdout.writeln('自检 3 herbs.json 内部重名     : ${dup.length}');
  for (final n in dup) {
    stdout.writeln('    $n');
  }
  stdout.writeln('');

  // 覆盖审计：每个异名 / 正名都必须至少命中一条
  List<String> hits(String q) =>
      herbs.where((h) => matchesQuery(h, q, canon)).map((h) => h['name'].toString()).toList();

  final aliasFail = canon.keys.where((a) => hits(a).isEmpty).toList();
  final nameFail = names.where((n) => hits(n).isEmpty).toList();

  stdout.writeln('=== 检索覆盖审计（统一 matchesQuery 路径）===');
  stdout.writeln('异名失效 : ${aliasFail.length} / ${canon.length}');
  for (final a in aliasFail) {
    stdout.writeln('    $a → 期望命中 [${canon[a]}]，实际为空');
  }
  stdout.writeln('正名失效 : ${nameFail.length} / ${names.length}');
  for (final n in nameFail) {
    stdout.writeln('    $n');
  }
  stdout.writeln('');

  // 用户直接报告的症状，单独确认
  stdout.writeln('=== 关键用例 ===');
  for (final probe in ['茈胡', '柴胡', '山药', '薯蓣', '橘皮', '红枣', '炙甘草', '牡桂']) {
    stdout.writeln('  $probe → ${hits(probe)}');
  }
  stdout.writeln('');

  final failed = dangling.length + unmerged.length + dup.length + aliasFail.length + nameFail.length;
  if (failed == 0) {
    stdout.writeln('PASS 全部通过：无悬空别名 / 无未合并 / 无重名 / 异名与正名均可检索。');
    exit(0);
  } else {
    stdout.writeln('FAIL 共 $failed 项不通过，详见上方清单。');
    exit(1);
  }
}
