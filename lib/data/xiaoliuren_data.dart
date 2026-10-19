// 小六壬（六壬时课）数据与排课纯函数。
//
// 数据源：通行俗传小六壬掌诀 / 《多能鄙事》卷八「小六壬课时」。
//   作者、成书年代及「李淳风」署名暂无可靠版本学证据，故不署作者名。
//   两种起课口径（月初一落宫）在术内本身有分歧，此处双口径并列、由使用者自选，
//   不把其中一口径伪装成唯一传统正解。
// 属民俗文化参考，非吉凶指令。

/// 起课口径。
enum XiaoliurenRule {
  /// 通行俗传掌诀：正月从大安起，月上起初一，日上起子时。
  common('通行掌诀', '正月从大安起，月上起初一，日上起子时'),

  /// 《多能鄙事》卷八：正月初一落留连，即月宫下一宫起初一。
  duoneng('《多能鄙事》', '正月初一留连，二月初一速喜；日宫起子时，依六宫顺行');

  const XiaoliurenRule(this.label, this.source);

  /// 口径显示名。
  final String label;

  /// 口径出处说明。
  final String source;

  /// 日宫起算偏移：0 = 月宫起初一；1 = 月宫下一宫起初一。
  int get dayStartOffset => this == XiaoliurenRule.duoneng ? 1 : 0;
}

/// 小六壬六宫（顺序固定，不可重排）。
enum XiaoliurenPalace {
  /// 大安，青龙主事。
  daAn('大安', '青龙'),

  /// 留连，玄武主事。
  liuLian('留连', '玄武'),

  /// 速喜，朱雀主事。
  suXi('速喜', '朱雀'),

  /// 赤口，白虎主事。
  chiKou('赤口', '白虎'),

  /// 小吉，六合主事。
  xiaoJi('小吉', '六合'),

  /// 空亡，勾陈主事。
  kongWang('空亡', '勾陈');

  const XiaoliurenPalace(this.name, this.deity);

  /// 宫名。
  final String name;

  /// 主事六神。
  final String deity;
}

/// 六宫固定顺序（大安 → 留连 → 速喜 → 赤口 → 小吉 → 空亡）。
const List<XiaoliurenPalace> kXiaoliurenPalaceOrder = [
  XiaoliurenPalace.daAn,
  XiaoliurenPalace.liuLian,
  XiaoliurenPalace.suXi,
  XiaoliurenPalace.chiKou,
  XiaoliurenPalace.xiaoJi,
  XiaoliurenPalace.kongWang,
];

/// 通行掌诀歌诀，索引与 [kXiaoliurenPalaceOrder] 对应。
const List<String> kXiaoliurenCommonVerses = [
  '大安事事昌，求财在坤方，失物去不远，宅舍保安康，行人身未动，病者主无妨，将军回田野，仔细更推详。',
  '留连事难成，求谋日未明，官事凡宜缓，去者未回程，失物南方见，急讨方心称，更须防口舌，人口且平平。',
  '速喜喜来临，求财向南行，失物申午未，逢人路上寻，官事有福德，病者无祸侵，田宅六畜吉，行人有信音。',
  '赤口主口舌，官非切宜防，失物急去寻，行人有惊慌，六畜多作怪，病者出西方，更须防咀咒，恐怕染瘟皇。',
  '小吉最吉昌，路上好商量，阴人来报喜，失物在坤方，行人立便至，交关甚是强，凡事皆和合，病者叩穷苍。',
  '空亡事不祥，阴人多乖张，求财无利益，行人有灾殃，失物寻不见，官事有刑伤，病人逢暗鬼，祈解保安康。',
];

/// 《多能鄙事》卷八歌诀，索引与 [kXiaoliurenPalaceOrder] 对应。
const List<String> kXiaoliurenDuonengVerses = [
  '大安时青龙主事，百事吉，失物在，行人未动。',
  '留连时玄武主事，凡事难成，求谋日未明，官事只可缓，去者未回程，失物巽上见，急讨方称情，更须防口舌，人口且平平。',
  '速喜时朱雀用事，有喜即至，行人来，公事了，失物离上可觅见。',
  '赤口时白虎用事，有口舌官灾，行人有惊，病者重，有咒咀，失物有争。',
  '小吉时六合主事，去行人至，失物坤方寻得，交关宜利。',
  '空亡时勾陈主事，求财无利，行人有灾，失物难觅，百事无成。',
];

/// 取某口径下某宫位的歌诀。
String xiaoliurenVerse(XiaoliurenPalace palace, XiaoliurenRule rule) =>
    (rule == XiaoliurenRule.duoneng
            ? kXiaoliurenDuonengVerses
            : kXiaoliurenCommonVerses)[
        kXiaoliurenPalaceOrder.indexOf(palace)];

/// 一宫落位结果。
class XiaoliurenHit {
  /// 该宫在六宫顺序中的下标（0-5）。
  final int index;

  /// 落位宫。
  final XiaoliurenPalace palace;

  /// 顺数步数（从月宫起算的总步数，用于展示推算过程）。
  final int steps;

  const XiaoliurenHit(this.index, this.palace, this.steps);
}

/// 小六壬排课结果。
class XiaoliurenChart {
  /// 农历月（1-12；闰月沿用同名月序）。
  final int lunarMonth;

  /// 农历日（1-30）。
  final int lunarDay;

  /// 时辰数（子=1 … 亥=12）。
  final int hourNumber;

  /// 所用户口。
  final XiaoliurenRule rule;

  /// 月宫落位。
  final XiaoliurenHit month;

  /// 日宫落位。
  final XiaoliurenHit day;

  /// 时宫落位（主断，称为「正时」）。
  final XiaoliurenHit hour;

  const XiaoliurenChart({
    required this.lunarMonth,
    required this.lunarDay,
    required this.hourNumber,
    required this.rule,
    required this.month,
    required this.day,
    required this.hour,
  });
}

XiaoliurenHit _hit(int steps, XiaoliurenRule rule) {
  final idx = ((steps % 6) + 6) % 6;
  return XiaoliurenHit(idx, kXiaoliurenPalaceOrder[idx], steps);
}

/// 小六壬时间排课（月/日/时三宫顺数）。
///
/// 顺数规则：以农历月定月宫，自月宫起初一顺数至农历日定日宫，
/// 自日宫起子时顺数至所问时辰定时宫。
///
/// [hourNumber] 时辰数，子=1 … 亥=12（不是 24 小时制钟点）。
XiaoliurenChart computeXiaoliuren({
  required int lunarMonth,
  required int lunarDay,
  required int hourNumber,
  XiaoliurenRule rule = XiaoliurenRule.common,
}) {
  if (lunarMonth < 1 || lunarMonth > 12) {
    throw ArgumentError.value(lunarMonth, 'lunarMonth', '农历月须在 1-12');
  }
  if (lunarDay < 1 || lunarDay > 30) {
    throw ArgumentError.value(lunarDay, 'lunarDay', '农历日须在 1-30');
  }
  if (hourNumber < 1 || hourNumber > 12) {
    throw ArgumentError.value(hourNumber, 'hourNumber', '时辰数须在 1-12（子=1）');
  }
  final off = rule.dayStartOffset;
  // 月宫：正月起大安（两口径相同）。
  final monthSteps = lunarMonth - 1;
  // 日宫：月宫起初一，顺数到农历日。
  final daySteps = lunarMonth + lunarDay - 2 + off;
  // 时宫：日宫起子时，顺数到所问时辰。
  final hourSteps = lunarMonth + lunarDay + hourNumber - 3 + off;
  return XiaoliurenChart(
    lunarMonth: lunarMonth,
    lunarDay: lunarDay,
    hourNumber: hourNumber,
    rule: rule,
    month: _hit(monthSteps, rule),
    day: _hit(daySteps, rule),
    hour: _hit(hourSteps, rule),
  );
}
