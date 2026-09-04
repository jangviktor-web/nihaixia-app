/// 八字传统扩展字段：胎元 / 胎息 / 各柱空亡 / 自坐十二神 / 副星 / 显性五行。
///
/// 纯函数；口径为 mainstream 子平，golden 校验来源为 liujixue 排盘实测
/// （2026-09-05 网络对账，案例 1995-08-16 12:00 男）。
library;

import 'bazi_analysis.dart' show branchHiddenStems;
import 'minggua_engine.dart' show shiShenOf;
import 'bazi_twelve_stages.dart' show twelveStageFor, TwelveStageMode;

const String _gans = '甲乙丙丁戊己庚辛壬癸';
const String _zhis = '子丑寅卯辰巳午未申酉戌亥';

int _ganIdx(String g) => _gans.indexOf(g);
int _zhiIdx(String z) => _zhis.indexOf(z);

/// 六十甲子序（0=甲子）。非法组合（干支奇偶不同）返回 -1。
int ganzhiIndex(String ganzhi) {
  final g = _ganIdx(ganzhi.substring(0, 1));
  final z = _zhiIdx(ganzhi.substring(1, 2));
  if (g < 0 || z < 0) return -1;
  for (var i = 0; i < 60; i++) {
    if (i % 10 == g && i % 12 == z) return i;
  }
  return -1;
}

/// 胎元：月柱天干进一位、地支进三位（如 甲申 → 乙亥）。
String taiYuanOf(String monthPillar) {
  final g = (_ganIdx(monthPillar.substring(0, 1)) + 1) % 10;
  final z = (_zhiIdx(monthPillar.substring(1, 2)) + 3) % 12;
  return '${_gans[g]}${_zhis[z]}';
}

/// 天干五合对象（甲己、乙庚、丙辛、丁壬、戊癸）。
const List<String> _stemCombine = [
  '己', '庚', '辛', '壬', '癸', '甲', '乙', '丙', '丁', '戊',
];

/// 地支六合对象（子丑、寅亥、卯戌、辰酉、巳申、午未）。
const List<String> _branchCombine = [
  '丑', '子', '亥', '戌', '酉', '申', '未', '午', '巳', '辰', '卯', '寅',
];

/// 胎息：日柱天干五合、地支六合所得干支（如 己卯 → 甲戌）。
String taiXiOf(String dayPillar) {
  final g = _stemCombine[_ganIdx(dayPillar.substring(0, 1))];
  final z = _branchCombine[_zhiIdx(dayPillar.substring(1, 2))];
  return '$g$z';
}

/// 各柱空亡：按各柱干支所在旬取缺失的两地支（如 乙亥 → 申酉）。
List<String> kongWangPerPillar(List<String> pillars) {
  final result = <String>[];
  for (final p in pillars) {
    final idx = ganzhiIndex(p);
    if (idx < 0) {
      result.add('');
      continue;
    }
    final xunStart = idx - (idx % 10); // 旬首（甲X）
    final covered = {
      for (var k = 0; k < 10; k++) (xunStart % 12 + k) % 12,
    };
    final missing = [
      for (var z = 0; z < 12; z++)
        if (!covered.contains(z)) _zhis[z],
    ];
    result.add(missing.join());
  }
  return result;
}

/// 自坐十二神：各柱干支自身相对其天干的长生十二神（火土同宫口径）。
/// 如案例 乙亥/甲申/己卯/庚午 → 死/绝/病/沐浴。
List<String> selfTwelveStages(List<String> gans, List<String> zhis) => [
      for (var i = 0; i < gans.length; i++)
        twelveStageFor(gans[i], zhis[i], TwelveStageMode.fireEarthSame),
    ];

/// 副星：各柱藏干相对日主的十神（如 申柱藏庚壬戊 → [伤官, 正财, 劫财]）。
List<List<String>> hiddenTenGods(List<String> gans, List<String> zhis) {
  final dayGan = gans[2];
  return [
    for (var i = 0; i < 4; i++)
      [for (final h in branchHiddenStems(zhis[i])) shiShenOf(dayGan, h)],
  ];
}

/// 显性五行：只统计四柱天干 + 地支共 8 字，不折算藏干。
/// 返回 [木, 火, 土, 金, 水] 计数。
List<int> visibleElementCounts(List<String> gans, List<String> zhis) {
  const ganEl = [0, 0, 1, 1, 2, 2, 3, 3, 4, 4];
  const zhiEl = [4, 2, 0, 0, 2, 1, 1, 2, 3, 3, 2, 4];
  final counts = List<int>.filled(5, 0);
  for (final g in gans) {
    counts[ganEl[_ganIdx(g)]]++;
  }
  for (final z in zhis) {
    counts[zhiEl[_zhiIdx(z)]]++;
  }
  return counts;
}
