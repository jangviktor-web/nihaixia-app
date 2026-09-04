/// 八字排盘聚合计算：四柱 + 十神 + 旬空 + 刑冲合害 + 长生十二神 + 八字详批。
///
/// 四柱取自 [calcZiweiBaZi]（与命盘 / 黄历同口径，底层为项目内 [ZiweiDate.bazi]），
/// 其余关系检测复用既有纯函数引擎，本文件只做编排，不重复实现历法 / 五行算法。
library;

import 'package:ziwei_core/ziwei_core.dart' show Gender, Location, RatHourMode;

import 'package:nihaisha_app/engine/bazi_analysis.dart'
    show analyzeBaZi, BaZiAnalysis;
import 'package:nihaisha_app/engine/bazi_relations.dart'
    show detectBaziRelations;
import 'package:nihaisha_app/engine/bazi_ten_gods.dart'
    show kongWang, tenGodsPerPillar;
import 'package:nihaisha_app/engine/bazi_twelve_stages.dart'
    show TwelveStageMode, twelveStagesForPillars;
import 'package:nihaisha_app/services/ziwei_engine.dart'
    show ZiweiBaZi, calcZiweiBaZi;

/// 单柱干支（如「甲辰」）拆成 (干, 支)。
(String, String) _splitGanZhi(String gz) =>
    (gz.substring(0, 1), gz.substring(1, 2));

/// 八字排盘结果聚合。
class BaZiPaipan {
  final ZiweiBaZi bazi;
  final List<String> gans;
  final List<String> zhis;
  final List<String> tenGods; // 十神（日主位固定为『日主』）
  final List<String> kongWang; // 旬空（空亡）地支
  final List<String> relations; // 刑冲合害 / 合会标签
  final List<String> twelveStages; // 长生十二神（年/月/日/时）
  final BaZiAnalysis analysis; // 格局 / 日主强弱 / 神煞 / 五行 / 用神忌神

  const BaZiPaipan({
    required this.bazi,
    required this.gans,
    required this.zhis,
    required this.tenGods,
    required this.kongWang,
    required this.relations,
    required this.twelveStages,
    required this.analysis,
  });
}

/// 计算八字排盘。
///
/// [solar] 为公历生辰（含时辰）；[isMale] 性别（不影响四柱，仅为构造所需）；
/// [useTrueSolarTime] 真太阳时开关，与命盘页语义一致；
/// [location] 出生地经纬度：`null` 时引擎默认 `Location(120, 30)`（东经 120°）。
/// 为保证时柱正确，调用方应显式传入真实出生地（见 ziwei_engine.dart:523 说明）。
/// [twelveStageMode] 长生十二神口径（火土同宫 / 水土同宫）；
/// [earlyZiShi] 早晚子时口径：默认 `false`（晚子时，23:00–24:00 算次日，与紫微同口径）；
/// `true` 即“早子时”（23:00–24:00 算当日，日柱不变），供排盘页开关切换。
BaZiPaipan computeBaZiPaipan(
  DateTime solar, {
  bool isMale = true,
  bool useTrueSolarTime = true,
  TwelveStageMode twelveStageMode = TwelveStageMode.fireEarthSame,
  bool earlyZiShi = false,
  Location? location,
}) {
  final bazi = calcZiweiBaZi(
    solar,
    gender: isMale ? Gender.male : Gender.female,
    useTrueSolarTime: useTrueSolarTime,
    ratHourMode: earlyZiShi ? RatHourMode.todayGan : null,
    location: location,
  );
  final gans = <String>[
    _splitGanZhi(bazi.year).$1,
    _splitGanZhi(bazi.month).$1,
    _splitGanZhi(bazi.day).$1,
    _splitGanZhi(bazi.time).$1,
  ];
  final zhis = <String>[
    _splitGanZhi(bazi.year).$2,
    _splitGanZhi(bazi.month).$2,
    _splitGanZhi(bazi.day).$2,
    _splitGanZhi(bazi.time).$2,
  ];
  final dayGan = gans[2];
  final tenGods = tenGodsPerPillar(dayGan, gans);
  final kong = kongWang(dayGan, zhis[2]);
  final relations = detectBaziRelations(zhis);
  final stages = twelveStagesForPillars(dayGan, zhis, mode: twelveStageMode);
  final analysis = analyzeBaZi(gans: gans, zhis: zhis);
  return BaZiPaipan(
    bazi: bazi,
    gans: gans,
    zhis: zhis,
    tenGods: tenGods,
    kongWang: kong,
    relations: relations,
    twelveStages: stages,
    analysis: analysis,
  );
}
