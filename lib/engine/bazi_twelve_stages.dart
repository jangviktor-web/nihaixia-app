/// 八字长生十二神（十二运）纯算法。
///
/// 长生十二神依「日主天干」起长生，顺推（阳干）/逆推（阴干）至各柱地支。
/// 五行起长生位固定：木生亥、火生寅、金生巳、水生申。
/// 唯「戊己土」起长生位有流派分歧：
/// - 火土同宫（现代子平主流）：土寄生于火 → 戊长生在寅、己长生在酉；
/// - 水土同宫（部分古籍 / 纳音派）：土寄生于水 → 戊长生在申、己长生在卯。
/// 其余天干两种口径完全一致。本模块以 [TwelveStageMode] 显式区分，避免静默错算。

library;

/// 长生十二神起长生口径。
enum TwelveStageMode {
  /// 火土同宫：现代子平主流，戊己土寄生于火（戊长生在寅、己长生在酉）。
  fireEarthSame,

  /// 水土同宫：部分古籍 / 纳音派，戊己土寄生于水（戊长生在申、己长生在卯）。
  waterEarthSame,
}

const List<String> _stageNames = [
  '长生',
  '沐浴',
  '冠带',
  '临官',
  '帝旺',
  '衰',
  '病',
  '死',
  '墓',
  '绝',
  '胎',
  '养',
];

const List<String> _ganChars = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
const List<String> _zhiChars = [
  '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
];

/// 各天干「长生」地支索引（火土同宫口径）。顺序对应 [_ganChars]。
/// 木生亥(11)、火生寅(2)、金生巳(5)、水生申(8)；
/// 戊(4)/己(5) 取火位（寅2/酉9）。
const List<int> _changShengFireEarth = [11, 6, 2, 9, 2, 9, 5, 0, 8, 3];

/// 各天干「长生」地支索引（水土同宫口径）。顺序对应 [_ganChars]。
/// 仅戊(4)/己(5) 改为水位（申8/卯3），其余与火土同宫一致。
const List<int> _changShengWaterEarth = [11, 6, 2, 9, 8, 3, 5, 0, 8, 3];

/// 单一天干（日主）相对某地支的长生十二神标签。
///
/// 阳干（偶索引）顺行：offset = (target - 长生) % 12；
/// 阴干（奇索引）逆行：offset = (长生 - target) % 12。
String twelveStageFor(String dayGan, String targetZhi, TwelveStageMode mode) {
  final gi = _ganChars.indexOf(dayGan);
  final zi = _zhiChars.indexOf(targetZhi);
  if (gi < 0 || zi < 0) return '';
  final startList = mode == TwelveStageMode.fireEarthSame
      ? _changShengFireEarth
      : _changShengWaterEarth;
  final start = startList[gi];
  final offset = gi.isEven
      ? (zi - start + 12) % 12 // 阳干顺行
      : (start - zi + 12) % 12; // 阴干逆行
  return _stageNames[offset];
}

/// 四柱地支各自相对日主的长生十二神，顺序 [年, 月, 日, 时]。
List<String> twelveStagesForPillars(
  String dayGan,
  List<String> pillarZhis, {
  required TwelveStageMode mode,
}) {
  return pillarZhis.map((z) => twelveStageFor(dayGan, z, mode)).toList();
}
