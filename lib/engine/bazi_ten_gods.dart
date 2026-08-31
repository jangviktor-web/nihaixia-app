/// 八字十神 / 旬空（空亡）纯算法。
///
/// 设计：独立于 [bazi_analysis]，作为可单测的纯函数集合。
/// - 十神仅依赖「日主阴阳 + 天干序列位移」，与五行无关，确定性查表（对齐主流排盘口径，
///   无流派歧义）。
/// - 旬空基于日柱干支定位旬首地支，返回该旬未出现的两个地支。
///
/// 数据正确性以经典旬空口诀校验：甲子旬戌亥空、甲戌旬申酉空、甲申旬午未空、
/// 甲午旬辰巳空、甲辰旬寅卯空、甲寅旬子丑空。

library;

const List<String> _ganChars = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
const List<String> _zhiChars = [
  '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
];

/// 日主为阳干时，目标干相对日主的位移(0-9)对应的十神。
/// 甲见甲→比肩、乙→劫财、丙→食神、丁→伤官、戊→偏财、己→正财、
/// 庚→七杀、辛→正官、壬→偏印、癸→正印。
const List<String> _shiShenYang = [
  '比肩', '劫财', '食神', '伤官', '偏财', '正财', '七杀', '正官', '偏印', '正印',
];

/// 日主为阴干时，目标干相对日主的位移(0-9)对应的十神。
/// 乙见乙→比肩、丙→伤官、丁→食神、戊→正财、己→偏财、庚→正官、
/// 辛→七杀、壬→正印、癸→偏印、甲→劫财。
const List<String> _shiShenYin = [
  '比肩', '伤官', '食神', '正财', '偏财', '正官', '七杀', '正印', '偏印', '劫财',
];

/// 单一天干相对日主的十神。
String tenGodForGan(String dayGan, String targetGan) {
  final di = _ganChars.indexOf(dayGan);
  final ti = _ganChars.indexOf(targetGan);
  if (di < 0 || ti < 0) return '';
  final d = (ti - di + 10) % 10;
  // 甲(0)丙(2)戊(4)庚(6)壬(8) 为阳干（偶索引），乙丁己辛癸为阴干（奇索引）。
  return (di.isEven ? _shiShenYang : _shiShenYin)[d];
}

/// 四柱天干各自相对日主的十神，顺序 [年, 月, 日, 时]。
/// 日柱位置固定返回『日主』标记（不重复十神）。
List<String> tenGodsPerPillar(String dayGan, List<String> pillarGans) {
  return pillarGans.asMap().entries.map((e) {
    if (e.key == 2) return '日主';
    return tenGodForGan(dayGan, e.value);
  }).toList();
}

/// 旬空（空亡）地支，基于日柱干支。
///
/// 算法：旬首地支 = (日支索引 - 日干索引 + 12) % 12；
/// 该旬未现的两地支为 [(旬首+10)%12, (旬首+11)%12]。
List<String> kongWang(String dayGan, String dayZhi) {
  final gi = _ganChars.indexOf(dayGan);
  final zi = _zhiChars.indexOf(dayZhi);
  if (gi < 0 || zi < 0) return const [];
  final startZhi = (zi - gi + 12) % 12;
  final e1 = (startZhi + 10) % 12;
  final e2 = (startZhi + 11) % 12;
  return [_zhiChars[e1], _zhiChars[e2]];
}
