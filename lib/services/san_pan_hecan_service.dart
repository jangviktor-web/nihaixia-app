import 'package:ziwei_core/ziwei_core.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart';
import 'package:nihaisha_app/engine/minggua_engine.dart';
import 'package:nihaisha_app/engine/bazi_analysis.dart';
import 'package:nihaisha_app/engine/bazi_ten_gods.dart';

/// 三盘合参输入：统一锚定到同一出生时空，确保紫微 / 八字 / 命卦同源合参。
///
/// 三盘皆由同一 [year]/[month]/[day]/[hour]/[minute] 推导：
/// - 紫微、八字来自 [calculateZiweiChart]；
/// - 命卦（先天/后天）由八字四柱经 [MingGuaEngine] 推导。
/// [lateZiEnabled] 与 [useTrueSolarTime] 透传给排盘，保证与各自来源屏口径一致。
class HeCanInput {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final bool isMale;
  final bool lateZiEnabled;
  final bool useTrueSolarTime;
  final Location? location;

  const HeCanInput({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.isMale,
    this.lateZiEnabled = false,
    this.useTrueSolarTime = true,
    this.location,
  });
}

/// 三盘合参结果（Phase 1：三行同屏，不给合成结论）。
class SanPanHeCan {
  final String baziFull; // 八字四柱
  final String mingGongStars; // 紫微命宫主星
  final String dayMaster; // 八字日主
  final String favorable; // 八字用神
  final List<String> tenGods; // 八字四柱十神（顺序 年/月/日/时，日柱位为『日主』）
  final String kongWang; // 八字旬空（空亡）地支，如『戌、亥』
  final String xianTianName; // 易经先天卦名
  final String houTianName; // 易经后天卦名
  final bool mingGuaAvailable; // 命卦是否成功推算

  SanPanHeCan({
    required this.baziFull,
    required this.mingGongStars,
    required this.dayMaster,
    required this.favorable,
    required this.tenGods,
    required this.kongWang,
    required this.xianTianName,
    required this.houTianName,
    required this.mingGuaAvailable,
  });
}

/// 以同一出生时空推算紫微 / 八字 / 命卦三盘，返回同屏所需的顶层结论。
///
/// 不做任何"三重印证 / 冲突预警"合成（那是 Phase 2），仅如实呈现三盘各自结论，
/// 由用户在同屏对照。命卦不可用时降级为"—"（如卦数入中宫）。
SanPanHeCan computeSanPanHeCan(HeCanInput input) {
  final solar = resolveBirthSolar(
    year: input.year,
    month: input.month,
    day: input.day,
    hour: input.hour,
    minute: input.minute,
    enabled: input.lateZiEnabled,
  );
  final chart = calculateZiweiChart(
    solar: solar,
    gender: input.isMale ? Gender.male : Gender.female,
    location: input.location,
    useTrueSolarTime: input.useTrueSolarTime,
  );

  // 八字四柱（干支各取单字）
  String gan(String s) => s.length >= 2 ? s.substring(0, 1) : s;
  String zhi(String s) => s.length >= 2 ? s.substring(1, 2) : s;
  final gans = [
    gan(chart.baziYear),
    gan(chart.baziMonth),
    gan(chart.baziDay),
    gan(chart.baziTime),
  ];
  final zhis = [
    zhi(chart.baziYear),
    zhi(chart.baziMonth),
    zhi(chart.baziDay),
    zhi(chart.baziTime),
  ];

  final baZi = analyzeBaZi(gans: gans, zhis: zhis);

  // 八字十神（逐柱相对日主）与旬空（空亡）
  final tenGods = tenGodsPerPillar(gans[2], gans);
  final kw = kongWang(gans[2], zhis[2]);

  // 紫微命宫主星
  final ming = chart.palaces.firstWhere(
    (p) => p.isLife,
    orElse: () => chart.palaces.first,
  );
  final majorStars = ming.majors.map((s) => s.label).toList();
  final mingGongStars =
      majorStars.isEmpty ? '无主星（借对宫参看）' : majorStars.join('、');

  // 命卦（先天/后天）
  final mg = MingGuaEngine.compute(
    yearGan: gans[0],
    yearZhi: zhis[0],
    monthGan: gans[1],
    monthZhi: zhis[1],
    dayGan: gans[2],
    dayZhi: zhis[2],
    timeGan: gans[3],
    timeZhi: zhis[3],
    male: input.isMale,
  );

  return SanPanHeCan(
    baziFull:
        '${chart.baziYear} ${chart.baziMonth} ${chart.baziDay} ${chart.baziTime}',
    mingGongStars: mingGongStars,
    dayMaster: baZi.dayMaster,
    favorable: baZi.favorable.isEmpty ? '—' : baZi.favorable.join('、'),
    tenGods: tenGods,
    kongWang: kw.isEmpty ? '—' : '${kw[0]}、${kw[1]}',
    xianTianName: mg?.xianTian.name ?? '—',
    houTianName: mg?.houTian.name ?? '—',
    mingGuaAvailable: mg != null,
  );
}
