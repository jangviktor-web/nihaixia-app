/// 八字排盘聚合计算：四柱 + 十神 + 旬空 + 刑冲合害 + 长生十二神 + 八字详批。
///
/// 四柱（年/月/日/时干支）取自 [bazi_core] 的 [bazi.BaziChart.createBySolarDate]，
/// 与 [computeBaZiFortune] 大运同源，确保四柱与大运口径一致（年柱按立春、
/// 日柱用权威基准日、子时归属按 [ratHourMode]）。其余关系检测复用既有纯函数引擎，
/// 本文件只做编排，不重复实现历法 / 五行算法。
library;

import 'package:ziwei_core/ziwei_core.dart' show Gender, Location, RatHourMode;

import 'package:bazi_core/bazi_core.dart' as bazi;

import 'package:nihaisha_app/engine/bazi_analysis.dart'
    show analyzeBaZi, BaZiAnalysis;
import 'package:nihaisha_app/engine/bazi_relations.dart'
    show detectBaziRelations;
import 'package:nihaisha_app/engine/bazi_ten_gods.dart'
    show kongWang, tenGodsPerPillar;
import 'package:nihaisha_app/engine/bazi_twelve_stages.dart'
    show TwelveStageMode, twelveStagesForPillars;
import 'package:nihaisha_app/services/ziwei_engine.dart' show ZiweiBaZi;
import 'package:nihaisha_app/engine/bazi_extra.dart'
    show taiYuanOf, taiXiOf, kongWangPerPillar, selfTwelveStages, hiddenTenGods;

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
  final String taiYuan; // 胎元
  final String taiXi; // 胎息
  final List<String> kongWangPillars; // 各柱空亡（按各柱旬）
  final List<String> selfStages; // 自坐十二神
  final List<List<String>> hiddenTenGods; // 副星（各柱藏干十神）

  const BaZiPaipan({
    required this.bazi,
    required this.gans,
    required this.zhis,
    required this.tenGods,
    required this.kongWang,
    required this.relations,
    required this.twelveStages,
    required this.analysis,
    required this.taiYuan,
    required this.taiXi,
    required this.kongWangPillars,
    required this.selfStages,
    required this.hiddenTenGods,
  });
}

/// 构造 bazi_core 命盘，并按 [ratHourMode] 处理早晚子时。
///
/// 返回 [chart]（用于大运 / 一般四柱）与可选的 [timeOverride]：晚子时场景下，
/// 「日柱取当天 + 时柱取次日子时」属于混合口径，bazi_core 单一 [RatHourMode] 无法
/// 直接表达，故日柱取自 `todayGan` 盘、时柱取自 `noSplit` 盘并覆盖。
class _BaziChartBuild {
  final bazi.BaziChart chart;
  final String? timeOverride;
  _BaziChartBuild(this.chart, this.timeOverride);
}

_BaziChartBuild _buildBaziChart(
  DateTime solar,
  bool ratHourMode,
  Location? location,
  bool useTrueSolarTime,
  Gender gender,
) {
  final hour = solar.hour;
  final loc = location ?? Location(120, 30);
  final astro = bazi.AstroDateTime(
      solar.year, solar.month, solar.day, solar.hour, solar.minute);
  if (ratHourMode && hour >= 23) {
    // 晚子时：日柱用当天（todayGan），时柱用次日子时（noSplit）。
    final dayChart = bazi.BaziChart.createBySolarDate(
      clockTime: astro,
      location: loc,
      ratHourMode: RatHourMode.todayGan,
      useTrueSolarTime: useTrueSolarTime,
      gender: gender,
    );
    final timeChart = bazi.BaziChart.createBySolarDate(
      clockTime: astro,
      location: loc,
      ratHourMode: RatHourMode.noSplit,
      useTrueSolarTime: useTrueSolarTime,
      gender: gender,
    );
    return _BaziChartBuild(dayChart, '${timeChart.bazi.time}');
  }
  if (ratHourMode && hour < 1) {
    // 早子时：bazi_core 的 noSplit 仅处理 23–24 点；00–01 点需将出生日 +1 天
    // 再按 todayGan 排盘，方得「日柱次日、时柱子时」。
    final nextSolar = solar.add(const Duration(days: 1));
    final nextAstro = bazi.AstroDateTime(
        nextSolar.year, nextSolar.month, nextSolar.day, nextSolar.hour, nextSolar.minute);
    final chart = bazi.BaziChart.createBySolarDate(
      clockTime: nextAstro,
      location: loc,
      ratHourMode: RatHourMode.todayGan,
      useTrueSolarTime: useTrueSolarTime,
      gender: gender,
    );
    return _BaziChartBuild(chart, null);
  }
  // 关闭开关，或 01:00–23:00：子时归自然日（todayGan）。
  final chart = bazi.BaziChart.createBySolarDate(
    clockTime: astro,
    location: loc,
    ratHourMode: RatHourMode.todayGan,
    useTrueSolarTime: useTrueSolarTime,
    gender: gender,
  );
  return _BaziChartBuild(chart, null);
}

/// 计算八字排盘。
///
/// [solar] 为公历生辰（含时辰）；[isMale] 性别（不影响四柱，仅为构造所需）；
/// [useTrueSolarTime] 真太阳时开关，与命盘页语义一致；
/// [location] 出生地经纬度：`null` 时按 bazi_core 默认 `Location(120, 30)`（东经 120°）。
/// 为保证时柱正确，调用方应显式传入真实出生地。
/// [twelveStageMode] 长生十二神口径（火土同宫 / 水土同宫）；
/// [ratHourMode] 区分早晚子时开关（含义同设置项「区分早晚子时」）：
///   - `false`（默认）：不区分，23:00–01:00 全部「子时归自然日」——日柱取当天、时柱取当日子时，不做偏移。
///   - `true`：区分早晚子时，由出生时刻自动判定：
///     · 晚子时（23:00 ≤ t < 24:00）：日柱维持**当天**（不变），时柱取**次日**子时干支；
///     · 早子时（00:00 ≤ t < 01:00）：日柱取**次日**（公历 +1 天），时柱取新一天子时干支；
///     · 01:00–23:00 不受影响，开关无作用。
/// 四柱由 [bazi.BaziChart.createBySolarDate] 算出（与大运同源），再包装为 [ZiweiBaZi]。
BaZiPaipan computeBaZiPaipan(
  DateTime solar, {
  bool isMale = true,
  bool useTrueSolarTime = true,
  TwelveStageMode twelveStageMode = TwelveStageMode.fireEarthSame,
  bool ratHourMode = false,
  Location? location,
}) {
  final built = _buildBaziChart(
    solar,
    ratHourMode,
    location,
    useTrueSolarTime,
    isMale ? Gender.male : Gender.female,
  );
  final four = built.chart.bazi;
  // 包装为 ZiweiBaZi（仍为 String 四柱），保持下游屏 / 组件读取方式不变。
  // 晚子时需要把「当日日柱」与「次日子时」混合，故时柱以 timeOverride 覆盖。
  final ziweiBazi = ZiweiBaZi(
    year: '${four.year}',
    month: '${four.month}',
    day: '${four.day}',
    time: built.timeOverride ?? '${four.time}',
  );
  final gans = <String>[
    _splitGanZhi(ziweiBazi.year).$1,
    _splitGanZhi(ziweiBazi.month).$1,
    _splitGanZhi(ziweiBazi.day).$1,
    _splitGanZhi(ziweiBazi.time).$1,
  ];
  final zhis = <String>[
    _splitGanZhi(ziweiBazi.year).$2,
    _splitGanZhi(ziweiBazi.month).$2,
    _splitGanZhi(ziweiBazi.day).$2,
    _splitGanZhi(ziweiBazi.time).$2,
  ];
  final dayGan = gans[2];
  final tenGods = tenGodsPerPillar(dayGan, gans);
  final kong = kongWang(dayGan, zhis[2]);
  final relations = detectBaziRelations(zhis);
  final stages = twelveStagesForPillars(dayGan, zhis, mode: twelveStageMode);
  final analysis = analyzeBaZi(gans: gans, zhis: zhis);
  return BaZiPaipan(
    bazi: ziweiBazi,
    gans: gans,
    zhis: zhis,
    tenGods: tenGods,
    kongWang: kong,
    relations: relations,
    twelveStages: stages,
    analysis: analysis,
    taiYuan: taiYuanOf(ziweiBazi.month),
    taiXi: taiXiOf(ziweiBazi.day),
    kongWangPillars:
        kongWangPerPillar([ziweiBazi.year, ziweiBazi.month, ziweiBazi.day, ziweiBazi.time]),
    selfStages: selfTwelveStages(gans, zhis),
    hiddenTenGods: hiddenTenGods(gans, zhis),
  );
}

// ---- 大运 / 流年（编排 bazi_core Fortune，UI 不直接依赖引擎类型）----

/// 单步大运（含其辖下 10 流年）的轻量视图。
class BaZiDecade {
  final int index; // 第几步大运（1 起）
  final String ganZhi; // 大运干支（如 癸未）
  final int startAge; // 起步虚岁
  final int endAge; // 结束虚岁
  final List<({int year, String ganZhi})> years; // 10 个流年

  const BaZiDecade({
    required this.index,
    required this.ganZhi,
    required this.startAge,
    required this.endAge,
    required this.years,
  });
}

/// 大运 / 流年汇总。
class BaZiFortune {
  final double startAge; // 起运虚岁（精确值，如 2.72）
  final DateTime qiYunTime; // 精确交运钟表时间
  final List<BaZiDecade> decades; // N 步大运

  const BaZiFortune({
    required this.startAge,
    required this.qiYunTime,
    required this.decades,
  });
}

/// 计算大运 / 流年。
///
/// 顺逆由 bazi_core 按传统规则内部判定：方向 = 年干阴阳 × 性别
/// （阳男阴女顺排、阴男阳女逆排，见 bazi_core fortune.dart）。
/// [location] 语义同 [computeBaZiPaipan]；`null` 时按默认东经 120°。
/// [ratHourMode] 区分早晚子时开关，与四柱排盘保持一致（含义见 [computeBaZiPaipan]）。
BaZiFortune computeBaZiFortune(
  DateTime solar, {
  required bool isMale,
  Location? location,
  bool ratHourMode = false,
  int decadeCount = 8,
}) {
  final chart = _buildBaziChart(
    solar,
    ratHourMode,
    location,
    true,
    isMale ? Gender.male : Gender.female,
  ).chart;
  final fortune = bazi.Fortune.createByBaziChart(chart);
  final decades = <BaZiDecade>[];
  for (var i = 1; i <= decadeCount; i++) {
    final d = fortune.getDecadeByIndex(i);
    decades.add(BaZiDecade(
      index: d.index,
      ganZhi: '${d.ganZhi}',
      startAge: d.startAge,
      endAge: d.endAge,
      years: [
        for (final y in d.flowYears) (year: y.year, ganZhi: '${y.ganZhi}'),
      ],
    ));
  }
  final qt = fortune.qiYunTime;
  return BaZiFortune(
    startAge: fortune.startAge,
    qiYunTime: DateTime(qt.year, qt.month, qt.day, qt.hour, qt.minute),
    decades: decades,
  );
}

/// 四柱纳音（如 甲子 → 海中金）。基于 sxwnl 权威纳音表，无需自维护。
String nayinOfPillar(String ganzhi) {
  assert(ganzhi.length == 2);
  final gz = bazi.GanZhi(
    bazi.TianGan.fromName(ganzhi.substring(0, 1)),
    bazi.DiZhi.fromName(ganzhi.substring(1, 2)),
  );
  return gz.naYin;
}
