import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

/// 每日黄历（老黄历）单日数据模型。
///
/// 数据基于 sxwnl_spa_dart 0.18.5 的农历 / 干支计算，叠加通用建除十二神、彭祖百忌、
/// 冲煞、宜忌规则（标准通胜口径，非某一家派别）。结果属「民俗文化参考」，非行事指令。
class AlmanacDay {
  final DateTime solar; // 公历日期
  final String weekdayName; // 周X
  final String lunarText; // 农历 2026年七月十五
  final String ganzhiDay; // 日干支，如「甲子」
  final String jianChu; // 建除十二神之一（建/除/满/平/定/执/破/危/成/收/开/闭）
  final int jianChuIndex; // 0=建 … 11=闭
  final List<String> pengZu; // 彭祖百忌（2 条：天干忌 + 地支忌）
  final String chong; // 日冲，如「冲午」
  final String sha; // 煞方，如「煞南」
  final List<String> yi; // 宜
  final List<String> ji; // 忌
  final String? solarTerm; // 当日节气（若有）
  final List<String> festivals; // 节日（含传统/法定/节气）

  const AlmanacDay({
    required this.solar,
    required this.weekdayName,
    required this.lunarText,
    required this.ganzhiDay,
    required this.jianChu,
    required this.jianChuIndex,
    required this.pengZu,
    required this.chong,
    required this.sha,
    required this.yi,
    required this.ji,
    required this.solarTerm,
    required this.festivals,
  });
}

// ---------------------------------------------------------------------------
// 建除十二神（0=建 … 11=闭）
// ---------------------------------------------------------------------------
const List<String> _jianChuNames = [
  '建', '除', '满', '平', '定', '执', '破', '危', '成', '收', '开', '闭',
];

// 农历月（1-12）→ 月支索引。正月建寅(2)、二月建卯(3)… 腊月建丑(1)。
const List<int> _lunarMonthToBranch = [
  0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 1,
]; // index by lunar.month (0 占位)

// ---------------------------------------------------------------------------
// 彭祖百忌（天干忌 / 地支忌）
// ---------------------------------------------------------------------------
const List<String> _pengZuGan = [
  '甲不开仓财物耗散',
  '乙不栽植千株不长',
  '丙不修灶必见灾殃',
  '丁不剃头头必生疮',
  '戊不受田田主不祥',
  '己不破券二比并亡',
  '庚不经络织机虚张',
  '辛不合酱主人不尝',
  '壬不汲水更难提防',
  '癸不词讼理弱敌强',
];

const List<String> _pengZuZhi = [
  '子不问卜自惹祸殃',
  '丑不冠带主不还乡',
  '寅不祭祀神鬼不尝',
  '卯不穿井水泉不香',
  '辰不哭泣必主重丧',
  '巳不远行财物伏藏',
  '午不苫盖屋主更张',
  '未不服药毒气入肠',
  '申不安床鬼祟入房',
  '酉不会客醉坐颠狂',
  '戌不吃犬作怪上床',
  '亥不嫁娶不利新郎',
];

// ---------------------------------------------------------------------------
// 冲煞（按日支六冲 → 冲某支、煞某方）
// ---------------------------------------------------------------------------
const List<String> _branchNames = [
  '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
];

// 煞方查表（按日支索引 0-11）：子→南 丑→东 寅→北 卯→西 辰→南 巳→东
// 午→北 未→西 申→南 酉→东 戌→北 亥→西
const List<String> _shaByBranch = [
  '南', '东', '北', '西', '南', '东', '北', '西', '南', '东', '北', '西',
];

// ---------------------------------------------------------------------------
// 宜忌（按建除十二神，标准通胜口径）
// ---------------------------------------------------------------------------
const Map<int, List<String>> _yiByJianChu = {
  0: ['出行', '祈福', '动土', '订盟', '纳财', '开市', '交易', '立券', '栽种', '安床'],
  1: ['祭祀', '祈福', '出行', '解除', '移徙', '开市', '交易', '求医', '疗病'],
  2: ['祭祀', '祈福', '开市', '交易', '立券', '安床', '出行', '纳财'],
  3: ['修造', '动土', '平治', '道涂', '出行', '嫁娶', '安床'],
  4: ['祭祀', '祈福', '嫁娶', '造屋', '装修', '安葬'],
  5: ['造屋', '装修', '嫁娶', '捕捉', '收购', '修造'],
  6: ['破屋', '坏垣', '求医', '治病'],
  7: ['安床', '祭祀', '祈福', '捕捉'],
  8: ['嫁娶', '开市', '交易', '立券', '出行', '入学', '安床', '动土'],
  9: ['嫁娶', '纳财', '入仓', '捕捉', '纳畜', '收购'],
  10: ['祭祀', '祈福', '入学', '开市', '交易', '嫁娶', '动土', '出行'],
  11: ['安葬', '修造', '筑堤', '补垣', '塞穴'],
};

const Map<int, List<String>> _jiByJianChu = {
  0: ['嫁娶', '安葬', '掘井', '乘船'],
  1: ['嫁娶', '安葬', '入宅'],
  2: ['动土', '安葬', '破土', '修造', '嫁娶'],
  3: ['祈福', '求嗣', '词讼', '栽种'],
  4: ['词讼', '出行', '医疗', '交易'],
  5: ['开市', '交易', '移徙', '出行', '求医'],
  6: ['嫁娶', '出行', '签约', '开市', '动土', '安葬'],
  7: ['出行', '登高', '嫁娶', '移徙', '开市'],
  8: ['词讼', '安葬', '修造'],
  9: ['放债', '出行', '安葬', '开市'],
  10: ['安葬', '放债', '修造'],
  11: ['开市', '出行', '求医', '嫁娶', '动土'],
};

/// 计算指定公历日期的每日黄历。
///
/// [solar] 公历日期（时分用于真太阳时无关的日柱判定，内部取正午基准）。
AlmanacDay getDailyAlmanac(DateTime solar) {
  final ad = AstroDateTime(solar.year, solar.month, solar.day, 12, 0, 0);
  final gz = dayGanZhi(ad);
  final lunar = LunarDate.fromSolar(ad);

  // 建除：月支 → 日支 偏移
  final monthBranch = _lunarMonthToBranch[lunar.month];
  final dayBranch = gz.zhi.index;
  final jcIdx = ((dayBranch - monthBranch) % 12 + 12) % 12;

  // 冲煞
  final chongIdx = (dayBranch + 6) % 12;
  final chong = '冲${_branchNames[chongIdx]}';
  final sha = '煞${_shaByBranch[dayBranch]}';

  // 节气（当日若是交节则为该节气名）
  String? term;
  final jq = getJieQiInfo(ad);
  if (jq != null && jq.daysSincePrevJieQi == 0) term = jq.prevJieQi.name;

  // 节日
  final fests = FestivalEngine.getFestivals(ad, lunar, gz)
      .map((f) => f.name)
      .where((n) => n.isNotEmpty)
      .toList();

  return AlmanacDay(
    solar: solar,
    weekdayName: ['一', '二', '三', '四', '五', '六', '日'][solar.weekday - 1],
    lunarText: '农历 $lunar',
    ganzhiDay: gz.toString(),
    jianChu: _jianChuNames[jcIdx],
    jianChuIndex: jcIdx,
    pengZu: [_pengZuGan[gz.gan.index], _pengZuZhi[gz.zhi.index]],
    chong: chong,
    sha: sha,
    yi: _yiByJianChu[jcIdx] ?? const [],
    ji: _jiByJianChu[jcIdx] ?? const [],
    solarTerm: term,
    festivals: fests,
  );
}
