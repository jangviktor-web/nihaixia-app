import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

import '../data/chaoshan_festival_data.dart';
import '../data/yuxiaji_deity_data.dart';

// 只引入四柱轻量接口：与紫微命盘 / 三盘合参共用 [ZiweiDate.bazi] 同一口径，
// 避免自行按底层历法重写导致与命盘页干支不一致。
// 用 show 限定作用域，避开与 sxwnl_spa_dart 的同名导出（如 BaZi）产生歧义。
import 'ziwei_engine.dart' show calcZiweiBaZi, ZiweiBaZi;

/// 每日黄历（老黄历）单日数据模型。
///
/// 数据基于 sxwnl_spa_dart 0.18.5 的农历 / 干支计算，叠加通用建除十二神、彭祖百忌、
/// 冲煞、宜忌规则（标准通胜口径，非某一家派别）。结果属「民俗文化参考」，非行事指令。
class AlmanacDay {
  final DateTime solar; // 公历日期
  final String weekdayName; // 周X
  final String lunarText; // 农历 2026年七月十五
  final String ganzhiYear; // 年干支，如「甲辰」
  final String ganzhiMonth; // 月干支，如「壬申」
  final String ganzhiDay; // 日干支，如「甲子」
  final String jianChu; // 建除十二神之一（建/除/满/平/定/执/破/危/成/收/开/闭）
  final int jianChuIndex; // 0=建 … 11=闭
  final List<String> pengZu; // 彭祖百忌（2 条：天干忌 + 地支忌）
  final String chong; // 日冲，如「冲午」
  final String sha; // 煞方，如「煞南」
  final String dayZodiac; // 日支生肖，如「鼠」
  final String chongZodiac; // 被冲生肖，如「马」（日支六冲）
  final List<String> yi; // 宜
  final List<String> ji; // 忌
  final String? solarTerm; // 当日节气（若有）
  final List<String> festivals; // 节日（含传统/法定/节气）
  final List<String> deityFestivals; // 神仙节日（《玉匣记》圣诞/斋期等）
  final List<String> chaoshanFestivals; // 潮汕神诞/节俗（地方性，带地域标注）

  /// 黄道吉时（十二黄道黑道神推算，当日吉时列表，如「子时」「卯时」）。
  final List<String> jiShi;
  /// 财神方位（《玉匣记》通书通用口诀，按日干）。
  final String caiShen;
  /// 喜神方位（同上）。
  final String xiShen;
  /// 福神方位（同上）。
  final String fuShen;

  const AlmanacDay({
    required this.solar,
    required this.weekdayName,
    required this.lunarText,
    required this.ganzhiYear,
    required this.ganzhiMonth,
    required this.ganzhiDay,
    required this.jianChu,
    required this.jianChuIndex,
    required this.pengZu,
    required this.chong,
    required this.sha,
    required this.dayZodiac,
    required this.chongZodiac,
    required this.yi,
    required this.ji,
    required this.solarTerm,
    required this.festivals,
    required this.deityFestivals,
    required this.chaoshanFestivals,
    required this.jiShi,
    required this.caiShen,
    required this.xiShen,
    required this.fuShen,
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
// 生肖相冲（日支六冲 → 被冲地支的生肖；地支 → 生肖）
// ---------------------------------------------------------------------------
const List<String> _zodiacByBranch = [
  '鼠', '牛', '虎', '兔', '龙', '蛇', '马', '羊', '猴', '鸡', '狗', '猪',
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

// ---------------------------------------------------------------------------
// 通胜要览：黄道吉时 + 财神/喜神/福神方位（《玉匣记》通书通用口诀）。
// 注：方位口诀各流派略有出入，此处取通用版，集中于此便于按需校正。
// ---------------------------------------------------------------------------

// 十二时辰名（地支顺序，与 yuxiaji_omen 共用口径）。
const List<String> _shiChenNames = [
  '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
];

// 十二黄道黑道神（青龙起例，index 0=青龙 … 11=勾陈）。
// 黄道（吉）= 青龙/明堂/金匮/天德/玉堂/司命；黑道（凶）= 其余。
const List<bool> _isHuangDao = [
  true,  // 0 青龙
  true,  // 1 明堂
  false, // 2 天刑
  false, // 3 朱雀
  true,  // 4 金匮
  true,  // 5 天德
  false, // 6 白虎
  true,  // 7 玉堂
  false, // 8 天牢
  false, // 9 玄武
  true,  // 10 司命
  false, // 11 勾陈
];

// 青龙起例：按日支所属三合局，定青龙所在时辰（地支索引）。
// 申子辰→子(0) 寅午戌→午(6) 亥卯未→卯(3) 巳酉丑→寅(2)。
int _qingLongStart(int dayBranch) {
  if (dayBranch == 0 || dayBranch == 4 || dayBranch == 8) return 0;
  if (dayBranch == 2 || dayBranch == 6 || dayBranch == 10) return 6;
  if (dayBranch == 3 || dayBranch == 7 || dayBranch == 11) return 3;
  return 2; // 巳(5)/酉(9)/丑(1)
}

// 财神方位（按日干 甲乙丙丁戊己庚辛壬癸，通书通用版）。
const List<String> _caiShenByGan = [
  '东北', '西南', '正西', '正西', '正北', '正北', '正东', '正东', '正南', '正南',
];

// 喜神方位（按日干，五合分组：甲己/乙庚/丙辛/丁壬/戊癸）。
const List<String> _xiShenByGan = [
  '东北', '西北', '西南', '正南', '东南', '东北', '西北', '西南', '正南', '东南',
];

// 福神方位（按日干，五合分组，通书通用版）。
const List<String> _fuShenByGan = [
  '西南', '正西', '正南', '正北', '正东', '西南', '正西', '正南', '正北', '正东',
];

/// 由出生公历推导本命生肖（年柱地支 → 生肖），与命盘页同口径（含立春）。
/// 用于「今日相冲 vs 本命生肖」个性化预警；无有效数据返回 null。
String? getUserZodiacFromSolar(DateTime solar) {
  final bz = calcZiweiBaZi(solar, useTrueSolarTime: false);
  if (bz.year.length < 2) return null;
  final branchChar = bz.year[1];
  final idx = _branchNames.indexOf(branchChar);
  return idx >= 0 ? _zodiacByBranch[idx] : null;
}

/// 计算指定公历日期的每日黄历。
///
/// [solar] 公历日期（时分用于真太阳时无关的日柱判定，内部取正午基准）。
AlmanacDay getDailyAlmanac(DateTime solar) {
  final ad = AstroDateTime(solar.year, solar.month, solar.day, 12, 0, 0);
  final gz = dayGanZhi(ad);
  final lunar = LunarDate.fromSolar(ad);

  // 年柱 / 月柱 / 日柱：取自紫微引擎的四柱（正午基准、平太阳时），
  // 与命盘页、三盘合参同口径。日柱与 dayGanZhi 结果一致（见单测校验），
  // 三柱统一由本来源提供以保证同源。
  final ZiweiBaZi bz = calcZiweiBaZi(
    DateTime(solar.year, solar.month, solar.day, 12, 0),
    useTrueSolarTime: false,
  );

  // 建除：月支 → 日支 偏移
  final monthBranch = _lunarMonthToBranch[lunar.month];
  final dayBranch = gz.zhi.index;
  final jcIdx = ((dayBranch - monthBranch) % 12 + 12) % 12;

  // 冲煞 + 生肖相冲（日支六冲：冲支 = 日支 + 6，被冲生肖随之）
  final chongIdx = (dayBranch + 6) % 12;
  final chong = '冲${_branchNames[chongIdx]}';
  final sha = '煞${_shaByBranch[dayBranch]}';
  final dayZodiac = _zodiacByBranch[dayBranch];
  final chongZodiac = _zodiacByBranch[chongIdx];

  // 节气（当日若是交节则为该节气名）
  String? term;
  final jq = getJieQiInfo(ad);
  if (jq != null && jq.daysSincePrevJieQi == 0) term = jq.prevJieQi.name;

  // 节日
  final fests = FestivalEngine.getFestivals(ad, lunar, gz)
      .map((f) => f.name)
      .where((n) => n.isNotEmpty)
      .toList();

  // 神仙节日（《玉匣记》）：与 FestivalEngine 同口径——闰月不过节，
  // 键为农历月日各两位。独立成表，与既有节日各自成卡、互不覆盖。
  final deityKey =
      '${lunar.month.toString().padLeft(2, '0')}'
      '${lunar.day.toString().padLeft(2, '0')}';
  final deityFests = lunar.isLeap
      ? const <String>[]
      : kYuxiajiDeityFestivals[deityKey] ?? const <String>[];

  // 潮汕节俗：与引擎节日双向子串去重（春节/元宵/端午/除夕等已由
  // 节日卡展示，避免同屏重复），与玉匣记源互不干预、各自成卡。
  final chaoshanAll = lunar.isLeap
      ? const <String>[]
      : kChaoshanFestivals[deityKey] ?? const <String>[];
  final chaoshanFests = chaoshanAll
      .where(
        (c) => !fests.any(
          (f) => f == c || c.contains(f) || f.contains(c),
        ),
      )
      .toList();

  // 通胜要览：黄道吉时（十二黄道黑道神，青龙起例按日支三合局）+ 三神方位（按日干）。
  final ql = _qingLongStart(dayBranch);
  final jiShi = <String>[
    for (int i = 0; i < 12; i++)
      if (_isHuangDao[(i - ql + 12) % 12]) '${_shiChenNames[i]}时',
  ];
  final ganIdx = gz.gan.index;
  final caiShen = _caiShenByGan[ganIdx];
  final xiShen = _xiShenByGan[ganIdx];
  final fuShen = _fuShenByGan[ganIdx];

  return AlmanacDay(
    solar: solar,
    weekdayName: ['一', '二', '三', '四', '五', '六', '日'][solar.weekday - 1],
    lunarText: '农历 $lunar',
    ganzhiYear: bz.year,
    ganzhiMonth: bz.month,
    ganzhiDay: bz.day,
    jianChu: _jianChuNames[jcIdx],
    jianChuIndex: jcIdx,
    pengZu: [_pengZuGan[gz.gan.index], _pengZuZhi[gz.zhi.index]],
    chong: chong,
    sha: sha,
    dayZodiac: dayZodiac,
    chongZodiac: chongZodiac,
    yi: _yiByJianChu[jcIdx] ?? const [],
    ji: _jiByJianChu[jcIdx] ?? const [],
    solarTerm: term,
    festivals: fests,
    deityFestivals: deityFests,
    chaoshanFestivals: chaoshanFests,
    jiShi: jiShi,
    caiShen: caiShen,
    xiShen: xiShen,
    fuShen: fuShen,
  );
}
