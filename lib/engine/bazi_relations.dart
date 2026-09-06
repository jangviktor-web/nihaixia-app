/// 八字地支刑冲合害 / 合会关系检测（纯函数）。
///
/// 数据表移植自 yw7915873/bazi-offline-web 的 detectRelations（其底层依赖
/// lunar-javascript，标准口径），以 Dart 纯函数重新实现，便于单测与三盘合参接入。
/// 覆盖：六冲、六合、六害、无礼之刑（子卯）、三合、三会、三刑、自刑。
///
/// 口径说明：六冲 / 六合 / 三合 / 三会 均为定论，无流派分歧，本模块直接采用主流
/// 子平标准表。注意：十二运（长生十二神）涉及火土 / 水土同宫争议，本模块刻意不含，
/// 如需另行上，应先确认口径。

library;

/// 两两地支关系：[(地支A, 地支B, 关系名)]
const List<(String, String, String)> _pairs = [
  // 六冲
  ('子', '午', '冲'), ('丑', '未', '冲'), ('寅', '申', '冲'),
  ('卯', '酉', '冲'), ('辰', '戌', '冲'), ('巳', '亥', '冲'),
  // 六合
  ('子', '丑', '合'), ('寅', '亥', '合'), ('卯', '戌', '合'),
  ('辰', '酉', '合'), ('巳', '申', '合'), ('午', '未', '合'),
  // 六害
  ('子', '未', '害'), ('丑', '午', '害'), ('寅', '巳', '害'),
  ('卯', '辰', '害'), ('申', '亥', '害'), ('酉', '戌', '害'),
  // 无礼之刑（子卯刑）
  ('子', '卯', '刑'),
];

/// 三合 / 三会 / 三刑：[(成员地支..., 关系名（含五行后缀）)]
const List<(List<String>, String)> _triples = [
  (['申', '子', '辰'], '三合水'),
  (['亥', '卯', '未'], '三合木'),
  (['寅', '午', '戌'], '三合火'),
  (['巳', '酉', '丑'], '三合金'),
  (['寅', '卯', '辰'], '三会木'),
  (['巳', '午', '未'], '三会火'),
  (['申', '酉', '戌'], '三会金'),
  (['亥', '子', '丑'], '三会水'),
  (['寅', '巳', '申'], '三刑'),
  (['丑', '戌', '未'], '三刑'),
];

/// 自刑地支：辰午酉亥 自刑（地支在四柱中重复出现即触发）
const List<String> _ziXingBranches = ['辰', '午', '酉', '亥'];

/// 检测传入地支集合（通常取八字四柱之地支）内的刑冲合害 / 合会关系。
///
/// 返回形如 `['子午冲', '申子辰三合水', '辰辰自刑']` 的标签列表（已去重、保序）。
/// [branches] 中允许空串（缺失柱），会被忽略。
List<String> detectBaziRelations(List<String> branches) {
  final valid = branches.where((b) => b.isNotEmpty).toList();
  final raw = <String>[];

  for (final (a, b, rel) in _pairs) {
    if (valid.contains(a) && valid.contains(b)) {
      raw.add('$a$b$rel');
    }
  }

  for (final (members, name) in _triples) {
    if (members.every((m) => valid.contains(m))) {
      raw.add('${members.join()}$name');
    }
  }

  for (final b in _ziXingBranches) {
    if (valid.where((x) => x == b).length > 1) {
      raw.add('$b$b自刑');
    }
  }

  // 去重且保序
  final seen = <String>{};
  final result = <String>[];
  for (final r in raw) {
    if (seen.add(r)) result.add(r);
  }
  return result;
}
