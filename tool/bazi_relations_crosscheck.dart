// 一次性对账脚本：bazi_core 的 15 种关系引擎 vs 项目内 detectBaziRelations。
//
// 运行（项目根目录）：
//   /d/flutter/bin/dart run tool/bazi_relations_crosscheck.dart
//
// 目的：批次 A 引入 bazi_core 后，对同一批命例并排输出两引擎的刑冲合害结果，
// 人工核对口径差异（覆盖范围：我们 8 类 vs bazi_core 15 类）。跑完归档结论，
// 不进 CI（不是回归测试，是迁移决策证据）。
import 'package:bazi_core/bazi_core.dart';

import 'package:nihaisha_app/engine/bazi_relations.dart';

final cases = [
  DateTime(1995, 8, 16, 12, 0), // 乙亥 甲申 己卯 庚午
  DateTime(2000, 1, 1, 23, 30), // 晚子时边界
  DateTime(1984, 6, 15, 12, 0), // 甲子 庚午 甲戌?（以引擎为准）
  DateTime(1990, 5, 20, 8, 0),
  DateTime(1976, 11, 3, 14, 0),
  DateTime(2001, 3, 8, 6, 30),
];

void main() {
  for (final t in cases) {
    final chart = BaziChart.createBySolarDate(
      clockTime: AstroDateTime(t.year, t.month, t.day, t.hour, t.minute),
    );
    final pillars =
        '${chart.bazi.year} ${chart.bazi.month} ${chart.bazi.day} ${chart.bazi.time}';
    final zhis = [
      chart.bazi.year.zhi.label,
      chart.bazi.month.zhi.label,
      chart.bazi.day.zhi.label,
      chart.bazi.time.zhi.label,
    ];

    print('=== $t  $pillars ===');
    print('  [项目内] ${detectBaziRelations(zhis)}');
    for (final res in chart.getAllInteractions()) {
      print('  [bazi_core] ${res.type}  参与柱: ${res.nodes}');
    }
  }
}
