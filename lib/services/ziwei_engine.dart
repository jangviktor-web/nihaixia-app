import 'package:ziwei_core/ziwei_core.dart';

/// 紫微斗数排盘引擎封装层。
///
/// 把 [ziwei_core] 的底层对象（[ZiWeiPlate] / [Palace] / [Star]）抽取成与 UI 无关、
/// 纯中文标注的 app 数据模型，供排盘界面直接使用。
///
/// 引擎说明：纯 Dart、离线、无 GetX 依赖（与本项目 MaterialApp 架构兼容）。
/// 排盘结果属“民俗文化参考”，非医疗诊断。

// ---------------------------------------------------------------------------
// 星曜 key → 中文名 映射表（ziwei_core 仅以英文 key 标识星曜，不提供中文标签）
// 覆盖默认规则集内的全部主星 / 辅星 / 煞星 / 杂曜 / 长生十二神。
// ---------------------------------------------------------------------------
const Map<String, String> _starLabelMap = {
  // 十四主星
  'ziwei': '紫微',
  'tianji': '天机',
  'taiyang': '太阳',
  'wuqu': '武曲',
  'tiantong': '天同',
  'lianzhen': '廉贞',
  'tianfu': '天府',
  'taiyin': '太阴',
  'tanlang': '贪狼',
  'jumen': '巨门',
  'tianxiang': '天相',
  'tianliang': '天梁',
  'qisha': '七杀',
  'pojun': '破军',
  // 六吉星
  'zuofu': '左辅',
  'youbi': '右弼',
  'wenchang': '文昌',
  'wenqu': '文曲',
  'tiankui': '天魁',
  'tianyue': '天钺',
  // 六煞星
  'qingyang': '擎羊',
  'tuoluo': '陀罗',
  'huoxing': '火星',
  'lingxing': '铃星',
  'dikong': '地空',
  'dijie': '地劫',
  // 其他辅曜 / 杂曜
  'lucun': '禄存',
  'tianma': '天马',
  'hongluan': '红鸾',
  'tianxi': '天喜',
  'tianyao': '天姚',
  'tianxing': '天刑',
  'xianchi': '咸池',
  'santai': '三台',
  'bazuo': '八座',
  'enguang': '恩光',
  'tiangui': '天贵',
  'taifu': '台辅',
  'fenggao': '封诰',
  'tiancai': '天才',
  'tianshou': '天寿',
  'longchi': '龙池',
  'fengge': '凤阁',
  'guchen': '孤辰',
  'guasu': '寡宿',
  'xunkong': '旬空',
  'fuxun': '副旬',
  'jiekong': '劫空',
  'fujie': '副劫',
  'tiankong': '天空',
  'tianshang': '天伤',
  'tianshi': '天使',
  'tianku': '天哭',
  'tianxu': '天虚',
  'tianguan': '天官',
  'tianfu_minor': '天福',
  'yinsha': '阴煞',
  'tianwu': '天巫',
  'tianyue_minor': '天月',
  'posui': '破碎',
  'feilian': '蜚廉',
  'tianchu': '天厨',
  'jieshen': '解神',
  'nianjie': '年解',
  'tiande': '天德',
  'yuede': '月德',
  'dahao': '大耗',
  // 长生十二神
  'changsheng': '长生',
  'muyu': '沐浴',
  'guandai': '冠带',
  'linguan': '临官',
  'diwang': '帝旺',
  'shuai': '衰',
  'bing': '病',
  'si': '死',
  'mu': '墓',
  'jue': '绝',
  'tai': '胎',
  'yang': '养',
  // 流曜（动态盘使用，原局不出现）
  'flow_lucun': '流禄存',
  'flow_tiankui': '流天魁',
  'flow_tianyue': '流天钺',
  'flow_wenchang': '流文昌',
  'flow_wenqu': '流文曲',
  'flow_qingyang': '流擎羊',
  'flow_tuoluo': '流陀罗',
  'flow_tianma': '流天马',
  // 博士十二神（随禄存，顺时针）
  'boshi_boshi12': '博士',
  'lishi_boshi12': '力士',
  'qinglong_boshi12': '青龙',
  'xiaohao_boshi12': '小耗',
  'jiangjun_boshi12': '将军',
  'zoushu_boshi12': '奏书',
  'feilian_boshi12': '飞廉',
  'xishen_boshi12': '喜神',
  'bingfu_boshi12': '病符',
  'dahao_boshi12': '大耗',
  'fubing_boshi12': '伏兵',
  'guanfu_boshi12': '官府',
  // 岁建十二神（随太岁）
  'suijian_suijian12': '岁建',
  'huiqi_suijian12': '晦气',
  'sangmen_suijian12': '丧门',
  'guansuo_suijian12': '贯索',
  'guanfu_suijian12': '官符',
  'xiaohao_suijian12': '小耗',
  'suipo_suijian12': '岁破',
  'dahao_suijian12': '大耗',
  'longde_suijian12': '龙德',
  'baihu_suijian12': '白虎',
  'tiande_suijian12': '天德',
  'diaoke_suijian12': '吊客',
  'bingfu_suijian12': '病符',
  // 将前十二神（随年支三合）
  'jiangxing_jiangqian12': '将星',
  'panan_jiangqian12': '攀鞍',
  'suiyi_jiangqian12': '岁驿',
  'wangshen_jiangqian12': '亡神',
  'huagai_jiangqian12': '华盖',
  'jiesha_jiangqian12': '劫煞',
  'zaisha_jiangqian12': '灾煞',
  'tiansha_jiangqian12': '天煞',
  'zhibei_jiangqian12': '指背',
  'xianchi_jiangqian12': '咸池',
  'yuesha_jiangqian12': '月煞',
  'xishen_jiangqian12': '息神',
};

String starLabel(String key) => _starLabelMap[key] ?? key;

/// 亮度数值 → 中文（6 庙 / 5 旺 / 4 得 / 3 利 / 2 平 / 1 不 / 0 陷 / -1 无）。
String? brightnessLabel(int index) {
  switch (index) {
    case 6:
      return '庙';
    case 5:
      return '旺';
    case 4:
      return '得';
    case 3:
      return '利';
    case 2:
      return '平';
    case 1:
      return '不';
    case 0:
      return '陷';
    default:
      return null;
  }
}

/// 四化类型 → 中文后缀。
String sihuaLabel(SiHuaType type) {
  switch (type) {
    case SiHuaType.lu:
      return '禄';
    case SiHuaType.quan:
      return '权';
    case SiHuaType.ke:
      return '科';
    case SiHuaType.ji:
      return '忌';
  }
}

/// 单颗星曜的展示模型。
class ZiweiStar {
  final String key;
  final String label;
  final StarType type;
  final String? brightness;
  final SiHuaType? sihua;

  ZiweiStar({
    required this.key,
    required this.label,
    required this.type,
    this.brightness,
    this.sihua,
  });

  bool get isMajor => type == StarType.major;
  bool get isLucky => type == StarType.lucky;
  bool get isBad => type == StarType.bad;
  bool get isMinor =>
      type == StarType.minor || type == StarType.other;

  String get sihuaText => sihua != null ? sihuaLabel(sihua!) : '';
}

/// 单宫的展示模型。
class ZiweiPalace {
  final int index; // 0-11，固定地支物理索引（0=子 … 11=亥）
  final PalaceRole role;
  final DiZhi branch;
  final TianGan? stem;
  final String ganzhiLabel;
  final List<ZiweiStar> stars;
  final bool isLife; // 命宫
  final bool isBody; // 身宫

  ZiweiPalace({
    required this.index,
    required this.role,
    required this.branch,
    required this.stem,
    required this.ganzhiLabel,
    required this.stars,
    required this.isLife,
    required this.isBody,
  });

  String get roleLabel => role.debugLabel;
  String get branchLabel => branch.label;
  String get stemLabel => stem?.label ?? '';

  List<ZiweiStar> get majors => stars.where((s) => s.isMajor).toList();
  List<ZiweiStar> get luckies => stars.where((s) => s.isLucky).toList();
  List<ZiweiStar> get bads => stars.where((s) => s.isBad).toList();
  List<ZiweiStar> get minors => stars.where((s) => s.isMinor).toList();
}

/// 生年四化条目。
class ZiweiSihua {
  final SiHuaType type;
  final String starLabelName;
  final String starKey;

  ZiweiSihua({
    required this.type,
    required this.starLabelName,
    required this.starKey,
  });

  String get typeLabel => sihuaLabel(type);
}

/// 大限（十年运）条目。
class ZiweiDecade {
  final int index; // 1-based：第几大限
  final int startTime; // 起始虚岁
  final int endTime; // 结束虚岁
  final String roleLabel; // 大限所在宫位名
  final String ganzhiLabel; // 大限宫位干支

  ZiweiDecade({
    required this.index,
    required this.startTime,
    required this.endTime,
    required this.roleLabel,
    required this.ganzhiLabel,
  });

  String get rangeLabel => '$startTime–$endTime 岁';
}

/// 完整命盘展示模型。
class ZiweiChart {
  final String baziYear;
  final String baziMonth;
  final String baziDay;
  final String baziTime;
  final String lunarText;
  final String genderLabel;
  final String elementBureauLabel;
  final String? mingZhuLabel;
  final String? shenZhuLabel;
  final int originMingIndex;
  final int bodyPalaceIndex;
  final List<ZiweiPalace> palaces; // 12 宫，按物理地支索引 0-11 排序
  final List<ZiweiSihua> sihua; // 生年四化（禄/权/科/忌 各一）
  final List<ZiweiDecade> decades; // 十二大限

  ZiweiChart({
    required this.baziYear,
    required this.baziMonth,
    required this.baziDay,
    required this.baziTime,
    required this.lunarText,
    required this.genderLabel,
    required this.elementBureauLabel,
    required this.mingZhuLabel,
    required this.shenZhuLabel,
    required this.originMingIndex,
    required this.bodyPalaceIndex,
    required this.palaces,
    required this.sihua,
    required this.decades,
  });

  String get baziFull =>
      '$baziYear $baziMonth $baziDay $baziTime';
}

/// 计算紫微斗数命盘。
///
/// - [solar] 公历出生时间（仅需年月日时，秒可忽略）
/// - [gender] 性别（影响大限顺逆）
/// - [location] 出生地经纬度；为 `null` 时引擎默认使用 `Location(120, 30)`。
/// - [useTrueSolarTime] 是否使用真太阳时（默认 `true`，与文墨天机等专业软件
///   一致）；设为 `false` 则使用平太阳时，与 iztro / MingLi-Bench 参考集一致。
///
/// 返回与 UI 解耦的中文标注命盘模型。
ZiweiChart calculateZiweiChart({
  required DateTime solar,
  required Gender gender,
  Location? location,
  bool useTrueSolarTime = true,
}) {
  final ruleset = ConfigLoader.getDefault();
  final date = ZiweiDate.fromSolar(
    AstroDateTime(solar.year, solar.month, solar.day, solar.hour, solar.minute),
    gender: gender,
    options: ruleset.calendarOptions,
    location: location,
    useTrueSolarTime: useTrueSolarTime,
  );
  final plate = ZiweiEngine.calculate(date, ruleset);

  // 十二宫（按物理地支索引 0-11）
  final List<ZiweiPalace> palaces = [];
  for (int i = 0; i < 12; i++) {
    final p = plate.palaces[i];
    final role = plate.getRole(ZiweiScope.origin, i);

    final List<ZiweiStar> stars = [];
    p.stars.forEach((type, list) {
      for (final s in list) {
        String? brightness;
        SiHuaType? sihua;
        if (s is StaticStar) {
          brightness = brightnessLabel(s.getBrightness(p.branch));
          sihua = s.siHuaBuff[ZiweiScope.origin];
        }
        stars.add(
          ZiweiStar(
            key: s.key,
            label: starLabel(s.key),
            type: type,
            brightness: brightness,
            sihua: sihua,
          ),
        );
      }
    });
    // 宫内排序：主星 → 吉 → 煞 → 杂
    stars.sort((a, b) => _starTypePriority(a.type)
        .compareTo(_starTypePriority(b.type)));

    palaces.add(
      ZiweiPalace(
        index: i,
        role: role,
        branch: p.branch,
        stem: p.stem,
        ganzhiLabel: p.stem != null
            ? '${p.stem!.label}${p.branch.label}'
            : p.branch.label,
        stars: stars,
        isLife: i == plate.originMingIndex,
        isBody: i == plate.bodyPalaceIndex,
      ),
    );
  }

  // 生年四化
  final List<ZiweiSihua> sihuaList = [];
  for (final palace in palaces) {
    for (final star in palace.stars) {
      if (star.sihua != null) {
        sihuaList.add(
          ZiweiSihua(
            type: star.sihua!,
            starLabelName: star.label,
            starKey: star.key,
          ),
        );
      }
    }
  }

  // 十二大限
  final List<ZiweiDecade> decades = [];
  for (int d = 1; d <= 12; d++) {
    final dec = Decade.fromIndex(d, plate);
    decades.add(
      ZiweiDecade(
        index: d,
        startTime: dec.startTime,
        endTime: dec.endTime,
        roleLabel: dec.role.debugLabel,
        ganzhiLabel: '${dec.ganzhi.gan.label}${dec.ganzhi.zhi.label}',
      ),
    );
  }

  // 八字
  final bz = date.bazi;
  final baziYear = '${bz.year.gan.label}${bz.year.zhi.label}';
  final baziMonth = '${bz.month.gan.label}${bz.month.zhi.label}';
  final baziDay = '${bz.day.gan.label}${bz.day.zhi.label}';
  final baziTime = '${bz.time.gan.label}${bz.time.zhi.label}';

  return ZiweiChart(
    baziYear: baziYear,
    baziMonth: baziMonth,
    baziDay: baziDay,
    baziTime: baziTime,
    lunarText: '农历 ${date.lunar}',
    genderLabel: gender == Gender.male ? '男' : '女',
    elementBureauLabel: plate.elementBureau.label,
    mingZhuLabel:
        plate.mingZhu != null ? starLabel(plate.mingZhu!) : null,
    shenZhuLabel:
        plate.shenZhu != null ? starLabel(plate.shenZhu!) : null,
    originMingIndex: plate.originMingIndex,
    bodyPalaceIndex: plate.bodyPalaceIndex,
    palaces: palaces,
    sihua: sihuaList,
    decades: decades,
  );
}

int _starTypePriority(StarType type) {
  switch (type) {
    case StarType.major:
      return 0;
    case StarType.lucky:
      return 1;
    case StarType.bad:
      return 2;
    case StarType.minor:
    case StarType.other:
      return 3;
    default:
      return 4;
  }
}

// ---------------------------------------------------------------------------
// 流年盘（大限/流年/流月 基础 + 流曜落宫）
// 流曜定位表源自 ziwei_core 0.13.0 默认规则集（MIT），按流年干支查表。
// ---------------------------------------------------------------------------

/// 流年流曜落宫标记（叠加在原局盘上展示）。
class FlowYearMark {
  final int year;
  final String ganzhi; // 流年干支（如 丙午）
  final int mingIndex; // 流年命宫地支索引 0-11
  final int taiSuiIndex; // 流年太岁（流年地支）所在宫索引
  final Map<int, List<String>> flowStars; // 宫索引 -> 流曜中文名列表

  const FlowYearMark({
    required this.year,
    required this.ganzhi,
    required this.mingIndex,
    required this.taiSuiIndex,
    required this.flowStars,
  });
}

/// 流年天干（0=甲..9=癸）：`(year + 6) % 10`（与 FlowYear.createByYear 一致）。
int _flowYearStemIndex(int year) => ((year + 6) % 10 + 10) % 10;

/// 流年地支索引（0=子..11=亥）：`(year + 8) % 12`。
int _flowYearBranchIndex(int year) => ((year + 8) % 12 + 12) % 12;

/// 8 颗流曜按流年天干查表（地支索引 0=子..11=亥）。
/// 数据源自 ziwei_core 0.13.0 `default_jsons.dart` 流曜规则（lookup 表）。
const Map<String, List<int>> _flowStarStemTable = {
  '流禄存': [2, 3, 5, 6, 5, 6, 8, 9, 11, 0],
  '流天魁': [1, 0, 11, 11, 1, 0, 1, 6, 3, 3],
  '流天钺': [7, 8, 9, 9, 7, 8, 7, 2, 5, 5],
  '流文昌': [5, 6, 8, 9, 8, 9, 11, 0, 2, 3],
  '流文曲': [9, 8, 6, 5, 6, 5, 3, 2, 0, 11],
  '流擎羊': [3, 4, 6, 7, 6, 7, 9, 10, 0, 1],
  '流陀罗': [1, 2, 4, 5, 4, 5, 7, 8, 10, 11],
};

/// 流天马按流年地支三合局查表：{子辰申→寅, 寅午戌→申, 巳酉丑→亥, 亥卯未→巳}。
int _flowTianmaIndex(int branchIndex) {
  const sanHe = {
    // 子, 辰, 申 → 寅(2)
    0: 2, 4: 2, 8: 2,
    // 寅, 午, 戌 → 申(8)
    2: 8, 6: 8, 10: 8,
    // 巳, 酉, 丑 → 亥(11)
    5: 11, 9: 11, 1: 11,
    // 亥, 卯, 未 → 巳(5)
    11: 5, 3: 5, 7: 5,
  };
  return sanHe[branchIndex]!;
}

/// 计算指定流年的流曜落宫（用于原局盘叠加流年信息）。
///
/// - [year] 流年公历年份
/// 返回：流年干支、流年命宫/太岁宫位、8 颗流曜分布。
FlowYearMark calculateFlowYearMark({required int year}) {
  final stemIdx = _flowYearStemIndex(year);
  final branchIdx = _flowYearBranchIndex(year);

  const ganNames = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
  const zhiNames = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

  // 流年命宫：FlowYear.createByYear 的 placeIndex = (year + 8) % 12
  final mingIndex = branchIdx;
  final taiSuiIndex = branchIdx;

  final flowStars = <int, List<String>>{};
  void add(int idx, String name) {
    flowStars.putIfAbsent(idx, () => []).add(name);
  }

  _flowStarStemTable.forEach((name, table) {
    add(table[stemIdx], name);
  });
  add(_flowTianmaIndex(branchIdx), '流天马');

  return FlowYearMark(
    year: year,
    ganzhi: '${ganNames[stemIdx]}${zhiNames[branchIdx]}',
    mingIndex: mingIndex,
    taiSuiIndex: taiSuiIndex,
    flowStars: flowStars,
  );
}
