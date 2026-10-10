/// 五运六气（运气学说）推算引擎。
///
/// 规则逐条移植自参考站 <https://acuherb.xyz/ziwu/> 核心脚本
/// （本地留存：`D:\tools\ziwu_page.html`，核心 IIFE 标记 `/*__CORE_START__*/`，
/// 相关函数位于 L511-634）。**本文件刻意与参考站逐格对齐**，以便与
/// `D:\tools\yunqi_ref.json`（62 年夹具）对拍；任何「看起来更合理但与参考站
/// 不一致」的改动都属于回归，请勿擅自修正。
///
/// ## 口径说明（重要，非笔误）
///
/// 1. **运气年以「立春」为界**：`yearGanzhi` 中 y - 1984 的 y 是「运气年」，
///    即从该公历年立春起算的干支年（见 [YunQiEngine.yunqiYearOf]）。
///    参考站外层用日历年、明细用立春年，大寒~立春之间会差一整个 step；
///    本引擎照搬该行为，以保证与夹具 372 个采样点逐格一致。
/// 2. **客气六步的「步」以「大寒」为界**（太阳黄经 λ=300° 起算），
///    与运气年的立春分界是两个不同的概念，切勿混用。
/// 3. 所有节气时刻均为**定气**（`sxwnl_spa_dart` 高精度算法），
///    每年公历日期在 1~2 天内浮动，**不得硬编码**「大寒 = 1 月 20 日」之类日期。
///
/// 依赖：`sxwnl_spa_dart ^0.18.5`（项目已有，零新增依赖）。
///
/// 对外入口：[YunQiEngine.yearGanzhi]（年运气数据）、
/// [YunQiEngine.currentQiStep]（某时刻所处客气步）、
/// [YunQiEngine.yunqiYearOf]（立春口径的运气年）。
library;

import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart'
    show AstroDateTime, JieQiResult, getNextJieQi;

import 'yunqi_literature.dart';

// ==================== 常量表（与参考站逐字对齐） ====================

/// 十干（甲…癸），下标即干序。
const List<String> yunQiGan = <String>['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];

/// 十二支（子…亥），下标即支序。
const List<String> yunQiZhi = <String>[
  '子', '丑', '寅', '卯', '辰', '巳',
  '午', '未', '申', '酉', '戌', '亥',
];

/// 十二生肖，下标同支序。
const List<String> yunQiShengXiao = <String>[
  '鼠', '牛', '虎', '兔', '龙', '蛇',
  '马', '羊', '猴', '鸡', '狗', '猪',
];

/// 五行，按「木火土金水」相生之序（亦是主运五步之序）。
const List<String> yunQiWuXing = <String>['木', '火', '土', '金', '水'];

/// 五音，与 [yunQiWuXing] 一一对应（角=木、徵=火、宫=土、商=金、羽=水）。
const List<String> yunQiYunYin = <String>['角', '徵', '宫', '商', '羽'];

/// 十干 → 岁运五行（甲己土、乙庚金、丙辛水、丁壬木、戊癸火）。
const Map<int, String> yunByGan = <int, String>{
  0: '土', 1: '金', 2: '水', 3: '木', 4: '火',
  5: '土', 6: '金', 7: '水', 8: '木', 9: '火',
};

/// 地支 → [司天之气名, 司天五行]（子午少阴君火、丑未太阴湿土…）。
const Map<int, List<String>> siTianByZhi = <int, List<String>>{
  0: <String>['少阴君火', '火'], 6: <String>['少阴君火', '火'],
  1: <String>['太阴湿土', '土'], 7: <String>['太阴湿土', '土'],
  2: <String>['少阳相火', '火'], 8: <String>['少阳相火', '火'],
  3: <String>['阳明燥金', '金'], 9: <String>['阳明燥金', '金'],
  4: <String>['太阳寒水', '水'], 10: <String>['太阳寒水', '水'],
  5: <String>['厥阴风木', '木'], 11: <String>['厥阴风木', '木'],
};

/// 地支 → 在泉之气（与司天相对，居三之气对面）。
const Map<int, String> zaiQuanByZhi = <int, String>{
  0: '阳明燥金', 1: '太阳寒水', 2: '厥阴风木',
  3: '少阴君火', 4: '太阴湿土', 5: '少阳相火',
  6: '阳明燥金', 7: '太阳寒水', 8: '厥阴风木',
  9: '少阴君火', 10: '太阴湿土', 11: '少阳相火',
};

/// 六气之序（客气轮转顺序）。
const List<String> qiSeq = <String>[
  '厥阴风木', '少阴君火', '太阴湿土', '少阳相火', '阳明燥金', '太阳寒水',
];

/// 六气 → 五行。
const Map<String, String> qiWuXing = <String, String>{
  '厥阴风木': '木',
  '少阴君火': '火',
  '太阴湿土': '土',
  '少阳相火': '火',
  '阳明燥金': '金',
  '太阳寒水': '水',
};

/// 地支 → 五行（子水、丑土、寅木…）。用于岁会判定。
const Map<int, String> zhiWuXing = <int, String>{
  0: '水', 1: '土', 2: '木', 3: '木', 4: '土', 5: '火',
  6: '火', 7: '土', 8: '金', 9: '金', 10: '土', 11: '水',
};

/// 五行相克表（我克者）：木克土、火克金、土克水、金克木、水克火。
///
/// 用于客主加临顺逆判定（`wuXingKe[客] == 主` → 客克主）。
/// 注意：**不可**用于平气判定，平气用的是 [wuXingKeMe]（见其注释）。
const Map<String, String> wuXingKe = <String, String>{
  '木': '土', '火': '金', '土': '水', '金': '木', '水': '火',
};

/// 五行相克表（克我者）：木受金克、火受水克、土受木克、金受火克、水受土克。
///
/// 对齐参考站 `yunqiYearData` 中的 `ke` 常量（原文写作
/// `{木:'金',火:'水',土:'木',金:'火',水:'土'}`，是「克我者」而非「我克者」）。
/// **仅用于平气判定**：太过年 `wuXingKeMe[岁运] == 司天五行` 即为平气。
/// 已用 62 年夹具逐格验证，请勿与 [wuXingKe] 混用。
const Map<String, String> wuXingKeMe = <String, String>{
  '木': '金', '火': '水', '土': '木', '金': '火', '水': '土',
};

/// 岁运病候文案（键 = 岁运五行 + 太过/不及）。
const Map<String, String> yunBing = <String, String>{
  '木太过': '风气流行，脾土受邪：易病飧泄、肠鸣、胁痛、善怒、眩晕',
  '火太过': '炎暑流行，肺金受邪：易病咳喘、血溢、咽干、心烦、身热',
  '土太过': '雨湿流行，肾水受邪：易病腹满、体重、足痿、饮病、濡泻',
  '金太过': '燥气流行，肝木受邪：易病胁痛、目赤、咳逆、少腹引痛',
  '水太过': '寒气流行，心火受邪：易病心痛、心悸、寒厥、烦躁、癫疾',
  '木不及': '燥乃大行，肝木受邪（金乘）：易病胁痛、目疾、筋脉拘急',
  '火不及': '寒乃大行，心火受邪（水乘）：易病心痛、胸痹、寒中、身重',
  '土不及': '风乃大行，脾土受邪（木乘）：易病飧泄、霍乱、腹满、体重',
  '金不及': '炎火乃行，肺金受邪（火乘）：易病咳喘、鼽嚏、血泄、肩背痛',
  '水不及': '湿乃大行，肾水受邪（土乘）：易病溏泄、腰痛、烦闷、足痿',
};

/// 司天病候文案（键 = 司天之气名）。
const Map<String, String> siTianBing = <String, String>{
  '少阴君火': '热气淫胜，肺金受病：易病咳喘、血溢、心痛、咽干、目赤',
  '太阴湿土': '湿气淫胜，肾水受病：易病腹满、水肿、濡泄、体重、足痿',
  '少阳相火': '火气淫胜，肺金受病：易病咳逆、衄血、疟疾、耳聋、目赤',
  '阳明燥金': '燥气淫胜，肝木受病：易病胁痛、目赤、疝痛、皮毛干燥',
  '太阳寒水': '寒气淫胜，心火受病：易病心痛、寒厥、心悸、呕逆、善忘',
  '厥阴风木': '风气淫胜，脾土受病：易病飧泄、腹痛、呕吐、胁痛、善怒',
};

/// 当令之气病候文案（键 = 六气名）。
const Map<String, String> qiBing = <String, String>{
  '厥阴风木': '风气当令：易病风证、肝胆、筋脉、目眩、胁痛',
  '少阴君火': '热气当令：易病心系、热证、咽干、心烦、失眠',
  '太阴湿土': '湿气当令：易病脾胃、湿证、腹胀、身重、泄泻',
  '少阳相火': '火气当令：易病暑热、心包三焦、口苦、目赤',
  '阳明燥金': '燥气当令：易病肺系、燥证、咳喘、便秘、皮肤干',
  '太阳寒水': '寒气当令：易病肾系、寒证、腰痛、畏寒、关节痛',
};

/// 主气六步定义（固定不变，与地支/年份无关）。
const List<ZhuQiStepDef> zhuQiSteps = <ZhuQiStepDef>[
  ZhuQiStepDef(name: '初之气', qi: '厥阴风木', from: '大寒', to: '春分'),
  ZhuQiStepDef(name: '二之气', qi: '少阴君火', from: '春分', to: '小满'),
  ZhuQiStepDef(name: '三之气', qi: '少阳相火', from: '小满', to: '大暑'),
  ZhuQiStepDef(name: '四之气', qi: '太阴湿土', from: '大暑', to: '秋分'),
  ZhuQiStepDef(name: '五之气', qi: '阳明燥金', from: '秋分', to: '小雪'),
  ZhuQiStepDef(name: '终之气', qi: '太阳寒水', from: '小雪', to: '大寒'),
];

/// 六步之名的序（下标即步序，对应 `currentQiStep` 返回值）。
const List<String> qiStepNames = <String>[
  '初之气', '二之气', '三之气', '四之气', '五之气', '终之气',
];

// ==================== 数据模型 ====================

/// 主气单步定义（名称 / 当令之气 / 起止节气）。
class ZhuQiStepDef {
  /// 步名（初之气…终之气）。
  final String name;

  /// 当令之气。
  final String qi;

  /// 起始节气名。
  final String from;

  /// 结束节气名（不含）。
  final String to;

  const ZhuQiStepDef({
    required this.name,
    required this.qi,
    required this.from,
    required this.to,
  });
}

/// 一步运（主运或客运）：五行 + 五音 + 太少。
class YunStep {
  /// 五行。
  final String wx;

  /// 五音（角徵宫商羽）。
  final String yin;

  /// 是否「太」（阳），否则为「少」（阴）。
  final bool tai;

  const YunStep({required this.wx, required this.yin, required this.tai});

  /// 完整名号，如「太角」「少徵」。
  String get label => '${tai ? '太' : '少'}$yin';

  @override
  String toString() => '$label（$wx）';
}

/// 客主加临单步：主气 + 客气 + 顺逆判定。
class JiaLinStep {
  /// 主气步定义。
  final ZhuQiStepDef zhu;

  /// 客气之名。
  final String ke;

  /// 顺逆判定文案。
  final String judge;

  const JiaLinStep({
    required this.zhu,
    required this.ke,
    required this.judge,
  });

  /// 主气所在五行。
  String get zhuWx => qiWuXing[zhu.qi] ?? '';

  /// 客气所在五行。
  String get keWx => qiWuXing[ke] ?? '';
}

/// 一年的完整运气数据（对应参考站 `yunqiYearData(y)` 返回值）。
class YunQiYearData {
  /// 运气年（以立春为界）。
  final int year;

  /// 运气年干支序（0-59，1984 甲子 = 0）。
  final int ganzhiIndex;

  /// 年干序（0-9）。
  final int gan;

  /// 年支序（0-11）。
  final int zhi;

  /// 年干名（甲乙丙…）。
  final String ganName;

  /// 年支名（子丑寅…）。
  final String zhiName;

  /// 岁运五行（即中运 / 大运）。
  final String yun;

  /// 岁运是否太过（阳干太过，阴干不及）。
  final bool taiGuo;

  /// 司天之气名。
  final String siTian;

  /// 司天之气五行。
  final String siTianWx;

  /// 在泉之气名。
  final String zaiQuan;

  /// 综合标记文本（天符·岁会·平气 等，或「岁运太过/不及」兜底）。
  final String cat;

  /// 天符：岁运五行 == 司天五行。
  final bool isTianFu;

  /// 太一天符：天符 + 岁会 + 年干非乙。
  final bool isTaiYi;

  /// 岁会：岁运五行 == 年支五行，且年支不属于四仲（卯酉子午）。
  final bool isSuiHui;

  /// 同天符：太过年 + 在泉与岁运同五行（相火在泉不计）。
  final bool isTongTianFu;

  /// 同岁会：不及年 + 在泉与岁运同五行（相火在泉不计）。
  final bool isTongSuiHui;

  /// 平气：太过年「我克者 == 司天」或不及年「岁运 == 司天」。
  final bool isPingQi;

  /// 主运五步（木火土金水，太少先阴后阳，固定）。
  final List<YunStep> zhuYun;

  /// 客运五步（以岁运五行起，逐年轮转）。
  final List<YunStep> keYun;

  /// 客气六步。
  final List<String> keQi;

  /// 客主加临六步。
  final List<JiaLinStep> jiaLin;

  /// 生肖（按年支序对照 [yunQiShengXiao] 取得，如「龙」）。
  ///
  /// ⚠️ 对拍说明：参考站 `yunqiYearData` 引用的 `SHENGXIAO` 全局**未定义**，
  /// 故其在 `D:\tools\yunqi_ref.json` 夹具中该字段**恒为 null**。
  /// 本引擎按地支序正常补齐，因此 **`shengXiao` 不参与 62 年夹具对拍**——
  /// 这是刻意为之，**不可**据此认为对拍存在遗漏（其余 23 个字段逐格全对）。
  final String shengXiao;

  /// 岁运病候。
  final String yunBingText;

  /// 司天病候。
  final String siTianBingText;

  /// 六十甲子《内经》大论原文等（key 为年干支，如「甲子」）。
  final Map<String, String> jz60;

  /// 岁运三纪·胜·复·郁（key 为「元素+太过/不及/平气」，如「金太过」）。
  final Map<String, String> yunBack;

  /// 六气胜复与治则（key 为六气名，如「阳明燥金」）。
  final Map<String, String> qiBack;

  /// 司天病候与治则（key 为「司天:气名」）。
  final Map<String, String> skySiTian;

  /// 在泉病候与治则（key 为「在泉:气名」）。
  final Map<String, String> skyZaiQuan;

  const YunQiYearData({
    required this.year,
    required this.ganzhiIndex,
    required this.gan,
    required this.zhi,
    required this.ganName,
    required this.zhiName,
    required this.yun,
    required this.taiGuo,
    required this.siTian,
    required this.siTianWx,
    required this.zaiQuan,
    required this.cat,
    required this.isTianFu,
    required this.isTaiYi,
    required this.isSuiHui,
    required this.isTongTianFu,
    required this.isTongSuiHui,
    required this.isPingQi,
    required this.zhuYun,
    required this.keYun,
    required this.keQi,
    required this.jiaLin,
    required this.shengXiao,
    required this.yunBingText,
    required this.siTianBingText,
    required this.jz60,
    required this.yunBack,
    required this.qiBack,
    required this.skySiTian,
    required this.skyZaiQuan,
  });

  /// 年干支，如「甲辰」。
  String get ganZhi => '$ganName$zhiName';

  /// 六十年甲子序（1-60，甲子 = 1），便于展示。
  int get ganzhiOrdinal => ganzhiIndex + 1;

  /// 所有成立的运气标记（按参考站 push 顺序）。
  List<String> get tags {
    final List<String> out = <String>[];
    if (isTaiYi) out.add('太一天符');
    if (isTianFu) out.add('天符');
    if (isSuiHui) out.add('岁会');
    if (isTongTianFu) out.add('同天符');
    if (isTongSuiHui) out.add('同岁会');
    if (isPingQi) out.add('平气');
    return out;
  }
}

// ==================== 引擎 ====================

/// 五运六气推算引擎。
///
/// 纯函数式实现，无状态；节气时刻通过 `sxwnl_spa_dart` 的定气算法实时求解。
class YunQiEngine {
  YunQiEngine._();

  /// 模运算，结果恒为非负（对齐 JS 的 `mod`）。
  static int _mod(int a, int b) => ((a % b) + b) % b;

  /// 取某个「运气年」（以立春为界）对应的公历年份。
  ///
  /// [date] 在立春之前 → 归上一年；立春（含）之后 → 归当年。
  static int yunqiYearOf(DateTime date) {
    final double ms = date.millisecondsSinceEpoch.toDouble();
    final double liChun = jieQiTimeMs(date.year, '立春');
    return ms < liChun ? date.year - 1 : date.year;
  }

  /// 按参考站口径取「运气年」：外层用日历年，大寒~立春之间不回溯。
  ///
  /// 参考站 UI 由日历年直接驱动 `yunqiYearData`，`currentQiStep` 亦以日历年
  /// 为第一参数，故两者在大寒~立春之间会相差一整个 step。本方法刻意保留
  /// 该行为以对齐夹具，**非笔误**。
  static int calendarYearOf(DateTime date) => date.year;

  /// 推算某运气年的完整运气数据（对应 `yunqiYearData(y)`）。
  static YunQiYearData yearGanzhi(int year) {
    final int yG = _mod(year - 1984, 60);
    final int gan = _mod(yG, 10);
    final int zhi = _mod(yG, 12);

    final String yun = yunByGan[gan]!;
    final bool taiGuo = gan % 2 == 0;

    final List<String> siTianPair = siTianByZhi[zhi]!;
    final String siTian = siTianPair[0];
    final String siTianWx = siTianPair[1];
    final String zaiQuan = zaiQuanByZhi[zhi]!;
    final String zaiQuanWx = qiWuXing[zaiQuan]!;

    // —— 标记判定 ——
    final bool isTianFu = yun == siTianWx;
    final bool isSuiHui =
        yun == zhiWuXing[zhi] && !<int>[2, 5, 8, 11].contains(zhi);
    final bool isTaiYi = isTianFu && isSuiHui && gan != 1;
    final bool zaiQuanSame =
        (yun == zaiQuanWx) && !(yun == '火' && zaiQuan == '少阴君火');
    final bool isTongTianFu = taiGuo && zaiQuanSame;
    final bool isTongSuiHui = !taiGuo && zaiQuanSame;
    // 平气：太过年用「克我者」表（参考站 ke 常量），不及年直接比五行。
    final bool isPingQi = (taiGuo && wuXingKeMe[yun] == siTianWx) ||
        (!taiGuo && yun == siTianWx);

    // tags 顺序：太一天符 / 天符 / 岁会 / 同天符 / 同岁会 / 平气
    final List<String> tags = <String>[];
    if (isTaiYi) tags.add('太一天符');
    if (isTianFu) tags.add('天符');
    if (isSuiHui) tags.add('岁会');
    if (isTongTianFu) tags.add('同天符');
    if (isTongSuiHui) tags.add('同岁会');
    if (isPingQi) tags.add('平气');
    final String cat = tags.isNotEmpty
        ? tags.join('·')
        : (taiGuo ? '岁运太过' : '岁运不及');

    // —— 主运五步：五行固定木火土金水，太少由初运太监决定后逐轮取反 ——
    final List<YunStep> zhuYun = <YunStep>[];
    bool shao = !taiGuo; // shao 初值 = !taiGuo，故第一步 tai = !shao = taiGuo
    for (int i = 0; i < 5; i++) {
      zhuYun.add(YunStep(wx: yunQiWuXing[i], yin: yunQiYunYin[i], tai: !shao));
      shao = !shao;
    }

    // —— 客运五步：以岁运五行为初运起，按五行序轮转，太少规则同主运 ——
    final List<YunStep> keYun = <YunStep>[];
    shao = !taiGuo;
    final int wxIdx = yunQiWuXing.indexOf(yun);
    for (int i = 0; i < 5; i++) {
      final int idx = _mod(wxIdx + i, 5);
      keYun.add(YunStep(wx: yunQiWuXing[idx], yin: yunQiYunYin[idx], tai: !shao));
      shao = !shao;
    }

    // —— 客气六步：司天固定落三之气（下标 2），故初始偏移 +4 ——
    // 校验：sIdx 为司天在 QI_SEQ 中的序号，keQi[2] 必等于司天。
    final int sIdx = qiSeq.indexOf(siTian);
    final List<String> keQi = <String>[];
    for (int i = 0; i < 6; i++) {
      keQi.add(qiSeq[_mod(sIdx + i + 4, 6)]);
    }

    // —— 客主加临：主客五行比较定顺逆 ——
    final List<JiaLinStep> jiaLin = <JiaLinStep>[];
    for (int i = 0; i < 6; i++) {
      final ZhuQiStepDef zq = zhuQiSteps[i];
      final String kq = keQi[i];
      jiaLin.add(JiaLinStep(zhu: zq, ke: kq, judge: _judgeJiaLin(kq, zq.qi)));
    }

    final String yunBingKey = '$yun${taiGuo ? '太过' : '不及'}';

    // —— 文献数据接入（算法未动，仅按现成字段查表）——
    final String ganZhiKey = '${yunQiGan[gan]}${yunQiZhi[zhi]}';
    final String yunBackKey =
        isPingQi ? '$yun平气' : '$yun${taiGuo ? '太过' : '不及'}';
    final Map<String, String> jz60Data =
        jz60Map[ganZhiKey] ?? const <String, String>{};
    final Map<String, String> yunBackData =
        yunBackMap[yunBackKey] ?? const <String, String>{};
    final Map<String, String> qiBackData =
        qiBackMap[siTian] ?? const <String, String>{};
    final Map<String, String> skySiTianData =
        skyWaterMap['司天:$siTian'] ?? const <String, String>{};
    final Map<String, String> skyZaiQuanData =
        skyWaterMap['在泉:$zaiQuan'] ?? const <String, String>{};

    return YunQiYearData(
      year: year,
      ganzhiIndex: yG,
      gan: gan,
      zhi: zhi,
      ganName: yunQiGan[gan],
      zhiName: yunQiZhi[zhi],
      yun: yun,
      taiGuo: taiGuo,
      siTian: siTian,
      siTianWx: siTianWx,
      zaiQuan: zaiQuan,
      cat: cat,
      isTianFu: isTianFu,
      isTaiYi: isTaiYi,
      isSuiHui: isSuiHui,
      isTongTianFu: isTongTianFu,
      isTongSuiHui: isTongSuiHui,
      isPingQi: isPingQi,
      zhuYun: zhuYun,
      keYun: keYun,
      keQi: keQi,
      jiaLin: jiaLin,
      shengXiao: yunQiShengXiao[zhi],
      yunBingText: yunBing[yunBingKey] ?? '',
      siTianBingText: siTianBing[siTian] ?? '',
      jz60: jz60Data,
      yunBack: yunBackData,
      qiBack: qiBackData,
      skySiTian: skySiTianData,
      skyZaiQuan: skyZaiQuanData,
    );
  }

  /// 客主加临顺逆判定（对齐参考站 `jiaLin` 映射逻辑）。
  ///
  /// 从夹具反推出的映射（客五行, 主五行）→ 判定：
  /// - `(木,土) (火,金) (土,水) (金,木) (水,火)` → **客克主·顺（相得）**
  /// - `(土,木) (金,火) (水,土) (木,金) (火,水)` → **主克客·逆（不相得）**
  /// - 同五行 → 同气相得；其余 → 相生·相得
  ///
  /// 注：第一组正是标准五行相克 `木克土 / 火克金 / 土克水 / 金克木 / 水克火`，
  /// 第二组即其反序（主克客）。
  static String _judgeJiaLin(String keQiName, String zhuQiName) {
    final String kw = qiWuXing[keQiName] ?? '';
    final String zw = qiWuXing[zhuQiName] ?? '';
    if (kw == zw) return '同气相得';
    if (wuXingKe[kw] == zw) return '客克主·顺（相得）';
    if (wuXingKe[zw] == kw) return '主克客·逆（不相得）';
    return '相生·相得';
  }

  /// 计算某时刻所处客气步序（对应 `currentQiStep(yunqiY, ms)`）。
  ///
  /// 客气六步的六个分界节气依次为
  /// **大寒 / 春分 / 小满 / 大暑 / 秋分 / 小雪**，
  /// 对应太阳黄经 **300° / 0° / 60° / 120° / 180° / 240°**。
  ///
  /// 六步依次为：
  /// 初之气[大寒,春分)、二之气[春分,小满)、三之气[小满,大暑)、
  /// 四之气[大暑,秋分)、五之气[秋分,小雪)、终之气[小雪,次年大寒)。
  ///
  /// ⚠️ 实现要点：本引擎**按节气名**经 `sxwnl_spa_dart` 定气算法求解时刻
  /// （见 [jieQiTimeMs]），**不查任何 λ→节气表**。上面标注的黄经数值仅作
  /// 注释参考，用于说明「为何起算边界是大寒而非小寒」（大寒 λ=300°，是
  /// 客气六步的唯一起点）。项目内节气黄经的权威来源是
  /// `lib/services/solar_term_service.dart` 的 `getTermSolarLongitude()`，
  /// 如需展示黄经请调用它，**不要**在本文件另建 λ 表。
  ///
  /// 之所以以「大寒」而非运气年的「立春」为界：客气六步属六气范畴，
  /// 以冬至后第一个中气大寒起算；而立春是运气年（岁运）的分界。
  /// 两者是两个不同概念，切勿混用。
  ///
  /// 返回值 0-5。若 [ms] 早于当年大寒，则视为上一年终之气（step=5）。
  static int currentQiStep(int yunqiYear, double ms) {
    final List<double> bounds = <double>[
      jieQiTimeMs(yunqiYear, '大寒'),
      jieQiTimeMs(yunqiYear, '春分'),
      jieQiTimeMs(yunqiYear, '小满'),
      jieQiTimeMs(yunqiYear, '大暑'),
      jieQiTimeMs(yunqiYear, '秋分'),
      jieQiTimeMs(yunqiYear, '小雪'),
    ];
    int step = 5;
    if (ms < bounds[0]) {
      step = 5;
    } else {
      for (int i = 0; i < 6; i++) {
        final double next =
            (i == 5) ? jieQiTimeMs(yunqiYear + 1, '大寒') : bounds[i + 1];
        if (ms >= bounds[i] && ms < next) {
          step = i;
          break;
        }
      }
    }
    return step;
  }

  /// 便捷方法：给定日期时间，直接返回其上下午所属的客气步序。
  static int currentQiStepOf(DateTime date) {
    return currentQiStep(date.year, date.millisecondsSinceEpoch.toDouble());
  }

  // ==================== 五运（主运/客运）五步 · 步界与当前步 ====================
  //
  // 与客气六步以「大寒/春分/小满/大暑/秋分/小雪」为界不同，**五运五步的步界
  // 是「基准节气 + 固定天数」**（参考站口径，已用 2018 年核实：
  // 01/20、04/03、06/16、08/30、11/11）。
  // 新增方法，不改动既有任何逻辑。

  /// 五运五步起点的基准节气（与参考站一致）。
  ///
  /// 实际起点 = 该节气定气时刻 + [yunStepBoundOffsetDays] 的同下标天数。
  static const List<String> yunStepBoundTerms = <String>[
    '大寒', '春分', '芒种', '处暑', '立冬',
  ];

  /// [yunStepBoundTerms] 各步起点相对基准节气的天数偏移。
  ///
  /// 初之运即大寒当日（偏移 0），二之运春分后 13 日，三之运芒种后 10 日，
  /// 四之运处暑后 7 日，五之运立冬后 4 日。
  static const List<int> yunStepBoundOffsetDays = <int>[0, 13, 10, 7, 4];

  /// 五运五步起点的精确时刻（毫秒时间戳），长度 5。
  ///
  /// 节气时刻由定气算法实时求解，逐年浮动 1~2 天，**不得硬编码日期**。
  static List<double> yunStepBoundMs(int yunqiYear) {
    return <double>[
      for (int i = 0; i < yunStepBoundTerms.length; i++)
        jieQiTimeMs(yunqiYear, yunStepBoundTerms[i]) +
            yunStepBoundOffsetDays[i] * 86400000.0,
    ];
  }

  /// 五运五步起点的墙钟时刻，长度 5（与 [yunStepBoundMs] 同源）。
  static List<DateTime> yunStepBounds(int yunqiYear) {
    return <DateTime>[
      for (final double ms in yunStepBoundMs(yunqiYear))
        DateTime.fromMillisecondsSinceEpoch(ms.round()),
    ];
  }

  /// 客气六步的边界时刻（大寒/春分/小满/大暑/秋分/小雪），长度 6。
  ///
  /// 边界节气名取自 [zhuQiSteps] 的 `from`（主气与客气共用同一组边界）。
  static List<DateTime> qiStepBounds(int yunqiYear) {
    return <DateTime>[
      for (final ZhuQiStepDef z in zhuQiSteps)
        DateTime.fromMillisecondsSinceEpoch(
            jieQiTimeMs(yunqiYear, z.from).round()),
    ];
  }

  /// 某时刻所处的五运步序（0-4，对应初之运…终之运）。
  ///
  /// 与 [currentQiStep] 同口径：
  /// - 早于当年大寒 → 归 4（视作上一年五之运的延续）；
  /// - 五之运自「立冬 + 4 天」起，一直延续到次年大寒。
  static int currentYunStep(int yunqiYear, double ms) {
    final List<double> b = yunStepBoundMs(yunqiYear);
    if (ms < b[0]) return 4;
    for (int i = 0; i < b.length - 1; i++) {
      if (ms < b[i + 1]) return i;
    }
    return 4;
  }

  /// 便捷方法：给定日期，返回其所属五运步序（0-4）。
  static int currentYunStepOf(DateTime date) {
    return currentYunStep(date.year, date.millisecondsSinceEpoch.toDouble());
  }
}

// ==================== 节气时刻（定气） ====================

/// 节气时刻缓存（键为 `'year|name'`），避免 UI 反复重建时重复求解。
final Map<String, double> _jieQiMsCache = <String, double>{};

/// 求某年某节气的精确时刻（毫秒时间戳，北京时间 UTC+8 墙钟）。
///
/// 实现要点：
/// 1. 用 `getNextJieQi` 从该年 1 月 1 日 0 时起**逐节气向前推进**，
///    直到取到的节气名与预期一致且落在预期公历年份内；
/// 2. 之所以用「下一个」而非「上一个」：`getPrevJieQi` 在「恰好等于交节时刻」
///    时会返回该节气本身（闭合区间），若照此推进游标容易原地打转；用
///    `getNextJieQi` 可从任意时刻单调向前，天然自增。
/// 3. 最多迭代 40 次防死循环（相邻节气约 15 天，跨年远小于该上限）。
/// 4. 若最终仍定位失败（理论上不可能），退化为「该年 1 月 1 日 0 时」，
///    保证调用方不会拿到 null 而崩溃。
///
/// 注意：**节气用定气算，公历日期逐年浮动 1~2 天**，故本函数必须动态求解，
/// 不允许硬编码日期。
double jieQiTimeMs(int year, String name) {
  final String key = '$year|$name';
  final double? cached = _jieQiMsCache[key];
  if (cached != null) return cached;

  // 起点：当年 1 月 1 日 0 时（北京时间）之前 1 秒，确保"下一个"能覆盖年初节气。
  AstroDateTime cursor =
      AstroDateTime(year, 1, 1, 0, 0, 0).subtract(const Duration(seconds: 1));
  double? found;

  for (int i = 0; i < 40; i++) {
    final JieQiCandidate? candidate = _nextJieQi(cursor);
    if (candidate == null) break;
    final DateTime? dt = candidate.dateTime.toDateTime();
    if (dt == null) break;

    // 游标推进到该节气时刻本身，下一轮 getNextJieQi 自然给出再下一个节气。
    cursor = candidate.dateTime;

    if (candidate.name == name && dt.year == year) {
      found = dt.millisecondsSinceEpoch.toDouble();
      break;
    }

    // 已越过目标年份过多，无需继续向后找（节气按时间单向递增）。
    if (dt.year > year + 1) break;
  }

  final double result =
      found ?? DateTime(year, 1, 1, 0, 0, 0).millisecondsSinceEpoch.toDouble();
  _jieQiMsCache[key] = result;
  return result;
}

/// `getPrevJieQi` 的轻量包装壳类型。
///
/// 直接使用包内的 `JieQiResult` 亦可，但包一层可让本文件的定位逻辑
/// 与具体依赖解耦（例如将来切换到 `getSpecificJieQi` 时只需改这一处）。
class JieQiCandidate {
  /// 节气名。
  final String name;

  /// 精确时刻（北京时间 UTC+8）。
  final AstroDateTime dateTime;

  const JieQiCandidate({required this.name, required this.dateTime});
}

/// 取 [target] 之后的第一个节气。
///
/// 直接调用 `getNextJieQi`（开区间语义：严格晚于 [target]），因此把游标设为
/// 某个节气时刻本身时，下一次调用必然给出再下一个节气，不会原地打转。
JieQiCandidate? _nextJieQi(AstroDateTime target) {
  final JieQiResult? result = getNextJieQi(target);
  if (result == null) return null;
  return JieQiCandidate(name: result.name, dateTime: result.dateTime);
}
