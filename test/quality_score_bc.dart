// 质量评分工具（B=流月/流日，C=每日黄历）
//
// 设计目标：用「独立 oracle 交叉校验 + 结构完整性 + 确定性」三维，对 B/C 两个
// 民俗文化功能的输出质量做量化打分（0-100，加权），并给出字母等级。
//
// 校验原则：
//  - 不信任被测模块自己的内部表，尽量用引擎/底层库（ziwei_core / sxwnl）独立
//    重算做 oracle 比对（B1/B2/C1/C2/C4）。
//  - 结构完整性（B3/B4/C3/C5/C6）确保产物可被 UI 正确消费、不出现语义矛盾。
//  - 确定性（B5/C6）确保同一输入永远同一输出（幂等）。
//
// 该文件仅被 test/quality_score_bc_test.dart 引用，不参与 App 运行期构建。

import 'package:ziwei_core/ziwei_core.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart';
import 'package:nihaisha_app/services/ziwei_interpretation.dart';
import 'package:nihaisha_app/services/lunar_almanac_service.dart';

// ---- 独立校验用的小型常量表（不直接引用被测模块的私有表） ----
const List<String> _branchNames = [
  '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
];
const List<String> _shaByBranch = [
  '南', '东', '北', '西', '南', '东', '北', '西', '南', '东', '北', '西',
];
// 农历月(1-12) -> 月支索引（正月建寅=2）。索引 0 占位。
const List<int> _lunarMonthToBranch = [0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 0, 1];

/// 单维度质量评分。
class QualityDimension {
  final String id;
  final String label;
  final int weight; // 1-5，权重越高越关键
  final int passed;
  final int total;
  final String note;
  const QualityDimension(this.id, this.label, this.weight, this.passed,
      this.total, this.note);

  /// 该维度得分（0-100）。
  double get score => total == 0 ? 100.0 : passed * 100 / total;
}

/// 功能级质量报告。
class QualityReport {
  final String feature; // 'B' / 'C'
  final int samples; // 样本量
  final List<QualityDimension> dims;
  const QualityReport(this.feature, this.samples, this.dims);

  /// 加权综合分（0-100）。
  int get weightedScore {
    final w = dims.fold(0, (s, d) => s + d.weight);
    if (w == 0) return 0;
    final acc = dims.fold(0.0, (s, d) => s + d.score * d.weight);
    return acc.round();
  }

  String get grade {
    final s = weightedScore;
    if (s >= 95) return 'A+';
    if (s >= 90) return 'A';
    if (s >= 80) return 'B';
    if (s >= 70) return 'C';
    if (s >= 60) return 'D';
    return 'F';
  }

  String report() {
    final buf = StringBuffer();
    buf.writeln('【功能 $feature 质量评分】 样本=$samples  综合=${weightedScore}分($grade)');
    for (final d in dims) {
      buf.writeln(
          '  ${d.id} ${d.label}: ${d.score.toStringAsFixed(1)}分 '
          '(${d.passed}/${d.total}) 权重${d.weight}  ${d.note}');
    }
    return buf.toString();
  }
}

// ===========================================================================
// 功能 B：流月 / 流日
// ===========================================================================

/// 固定生辰构造一张命盘，复用其底层命盘推演流运（与真实 UI 路径一致）。
ZiweiChart _makeBChart() {
  return calculateZiweiChart(
    solar: DateTime(2000, 8, 16, 9, 0),
    gender: Gender.male,
    location: Location(116.41, 39.90),
    useTrueSolarTime: true,
  );
}

List<DateTime> _bSamples() {
  final list = <DateTime>[];
  for (final y in [1965, 1985, 2000, 2010, 2026]) {
    for (int m = 1; m <= 12; m++) {
      list.add(DateTime(y, m, 15));
    }
  }
  list.add(DateTime(2024, 2, 29)); // 闰年边界
  list.add(DateTime(2026, 1, 1));
  list.add(DateTime(2026, 12, 31));
  return list;
}

QualityReport scoreFeatureB() {
  final chart = _makeBChart();
  final samples = _bSamples();

  int b1p = 0, b1t = 0; // 流月命宫 oracle 匹配
  int b2p = 0, b2t = 0; // 流日命宫 oracle 匹配
  int b3p = 0, b3t = 0; // 命宫-疾厄宫关系一致
  int b4p = 0, b4t = 0; // 解读文案完整
  int b5p = 0, b5t = 0; // 确定性（幂等）

  for (final date in samples) {
    b1t++;
    b2t++;
    b3t++;
    b4t++;

    final fm = calculateFlowMonthMark(chart, date);
    final fd = calculateFlowDayMark(chart, date);

    // 直接用引擎底层对象做 oracle（与 app 委托的 ZiweiLimitManager 同源）。
    final mgr = ZiweiLimitManager(chart.basePlate);
    mgr.setPhysicalDate(date);
    final engYear = mgr.limitContext.year!; // 立春为界的流年（非日历年份）
    final engMonth = mgr.limitContext.month!;
    final engDay = mgr.limitContext.day!;

    // B1：流月命宫 / 干支 与引擎 FlowMonth.create（标准工厂）一致
    // 关键：流月干支走五虎遁，依赖「流年天干」，须用立春为界的流年，而非日历 year。
    final om = FlowMonth.create(
      engMonth.month,
      engYear.year,
      chart.basePlate,
      sequence: engMonth.sequence,
      isLeap: engMonth.isLeap,
    );
    final okIdxM = fm.mingIndex == om.index && fm.mingIndex == engMonth.index;
    final okGzM =
        fm.ganzhi == '${om.ganzhi.gan.label}${om.ganzhi.zhi.label}';
    if (okIdxM && okGzM) b1p++;

    // B2：流日命宫 / 干支 与引擎 FlowDay.create（标准工厂）一致
    final ad = AstroDateTime(date.year, date.month, date.day, 12, 0, 0);
    final dayGz = dayGanZhi(ad);
    final od = FlowDay.create(engDay.day, dayGz, om, chart.basePlate);
    final okIdxD = fd.mingIndex == od.index && fd.mingIndex == engDay.index;
    final okGzD =
        fd.ganzhi == '${dayGz.gan.label}${_branchNames[fd.mingIndex]}';
    if (okIdxD && okGzD) b2p++;

    // B3：命宫 + 5 = 疾厄宫（mod 12）
    final okM = (fm.mingIndex + 5) % 12 == fm.illnessIndex;
    final okD = (fd.mingIndex + 5) % 12 == fd.illnessIndex;
    if (okM && okD) b3p++;

    // B4：解读文案非空且含关键字
    final sM = summarizeFlowMonth(chart, fm);
    final sD = summarizeFlowDay(chart, fd);
    final okM4 = sM.isNotEmpty &&
        sM.contains('流月命宫') &&
        sM.contains('身体留意');
    final okD4 = sD.isNotEmpty &&
        sD.contains('流日命宫') &&
        sD.contains('身体留意');
    if (okM4 && okD4) b4p++;
  }

  // B5：同日期幂等（取前 10 个样本）
  for (final date in samples.take(10)) {
    b5t++;
    final aM = calculateFlowMonthMark(chart, date);
    final bM = calculateFlowMonthMark(chart, date);
    final aD = calculateFlowDayMark(chart, date);
    final bD = calculateFlowDayMark(chart, date);
    if (aM.mingIndex == bM.mingIndex &&
        aM.ganzhi == bM.ganzhi &&
        aD.mingIndex == bD.mingIndex &&
        aD.ganzhi == bD.ganzhi) {
      b5p++;
    }
  }

  return QualityReport('B', samples.length, [
    const QualityDimension('B1', '流月命宫与引擎 oracle 一致', 5, 0, 0, 'FlowMonth.create 交叉校验'),
    const QualityDimension('B2', '流日命宫与引擎 oracle 一致', 5, 0, 0, 'FlowDay.create 交叉校验'),
    const QualityDimension('B3', '命宫-疾厄宫关系一致(命+5=疾厄)', 3, 0, 0, 'mod 12 关联'),
    const QualityDimension('B4', '解读文案完整(命宫/身体留意)', 3, 0, 0, '关键字 + 非空'),
    const QualityDimension('B5', '同日期幂等(确定性)', 2, 0, 0, '重复计算一致'),
  ].map((d) {
    // 用真实计数回填
    final p = d.id == 'B1'
        ? b1p
        : d.id == 'B2'
            ? b2p
            : d.id == 'B3'
                ? b3p
                : d.id == 'B4'
                    ? b4p
                    : b5p;
    final t = d.id == 'B1'
        ? b1t
        : d.id == 'B2'
            ? b2t
            : d.id == 'B3'
                ? b3t
                : d.id == 'B4'
                    ? b4t
                    : b5t;
    return QualityDimension(d.id, d.label, d.weight, p, t, d.note);
  }).toList());
}

// ===========================================================================
// 功能 C：每日黄历
// ===========================================================================

List<DateTime> _cSamples() {
  final list = <DateTime>[];
  for (final y in [1990, 2000, 2010, 2020, 2026]) {
    for (int m = 1; m <= 12; m++) {
      for (final d in [1, 10, 20, 28]) {
        list.add(DateTime(y, m, d));
      }
    }
  }
  return list;
}

QualityReport scoreFeatureC() {
  final samples = _cSamples();

  int c1p = 0, c1t = 0; // 建除公式正确
  int c2p = 0, c2t = 0; // 冲煞独立校验
  int c3p = 0, c3t = 0; // 宜忌不重叠
  int c4p = 0, c4t = 0; // 节气 oracle 匹配
  int c5p = 0, c5t = 0; // 彭祖百忌完整且首字正确
  int c6p = 0, c6t = 0; // 确定性（幂等）

  for (final date in samples) {
    c1t++;
    c2t++;
    c3t++;
    c4t++;
    c5t++;
    c6t++;

    final ad = AstroDateTime(date.year, date.month, date.day, 12, 0, 0);
    final gz = dayGanZhi(ad);
    final lunar = LunarDate.fromSolar(ad);
    final a = getDailyAlmanac(date);

    // C1：建除 = (日支 - 月支) mod 12，独立重算
    final monthBranch = _lunarMonthToBranch[lunar.month];
    final dayBranch = gz.zhi.index;
    final jc = ((dayBranch - monthBranch) % 12 + 12) % 12;
    if (a.jianChuIndex == jc) c1p++;

    // C2：冲 = (日支+6) mod 12；煞 = 按日支查表
    final chongIdx = (dayBranch + 6) % 12;
    final okChong = a.chong.contains(_branchNames[chongIdx]);
    final okSha = a.sha.contains(_shaByBranch[dayBranch]);
    if (okChong && okSha) c2p++;

    // C3：宜 ∩ 忌 = ∅
    final overlap = a.yi.where((x) => a.ji.contains(x)).toList();
    if (overlap.isEmpty) c3p++;

    // C4：节气 oracle（与 sxwnl getJieQiInfo 一致）
    final jq = getJieQiInfo(ad);
    final expectedTerm = (jq != null && jq.daysSincePrevJieQi == 0);
    if ((a.solarTerm != null) == expectedTerm) c4p++;

    // C5：彭祖百忌 2 条，首字分别等于日干 / 日支（防索引错排）
    final okPz = a.pengZu.length == 2 &&
        a.pengZu.first.startsWith(gz.gan.label) &&
        a.pengZu.last.startsWith(gz.zhi.label);
    if (okPz) c5p++;

    // C6：确定性
    final b = getDailyAlmanac(date);
    if (a.jianChuIndex == b.jianChuIndex &&
        a.ganzhiDay == b.ganzhiDay &&
        a.yi == b.yi &&
        a.ji == b.ji) {
      c6p++;
    }
  }

  // C1 附加：2026 全年逐日以「独立 oracle」复核建除公式（高密度覆盖，非依赖增量假设）。
  // 每天用 dayGanZhi + LunarDate 独立重算 (日支-月支) mod 12，与 app 输出比对。
  {
    final start = DateTime(2026, 1, 1);
    for (int i = 0; i < 365; i++) {
      final d = start.add(Duration(days: i));
      final ad = AstroDateTime(d.year, d.month, d.day, 12, 0, 0);
      final gz = dayGanZhi(ad);
      final lunar = LunarDate.fromSolar(ad);
      final a = getDailyAlmanac(d);
      final monthBranch = _lunarMonthToBranch[lunar.month];
      final dayBranch = gz.zhi.index;
      final jc = ((dayBranch - monthBranch) % 12 + 12) % 12;
      c1t++;
      if (a.jianChuIndex == jc) c1p++;
    }
  }

  return QualityReport('C', samples.length, [
    const QualityDimension('C1', '建除十二神公式正确(含逐日递增)', 4, 0, 0, '日支-月支 独立重算'),
    const QualityDimension('C2', '冲煞与日支六冲一致', 4, 0, 0, '日支+6 / 煞方查表'),
    const QualityDimension('C3', '宜与忌不重叠', 4, 0, 0, '语义无矛盾'),
    const QualityDimension('C4', '节气与 sxwnl oracle 一致', 3, 0, 0, 'getJieQiInfo 交叉校验'),
    const QualityDimension('C5', '彭祖百忌完整且首字正确', 2, 0, 0, '天干/地支 首字校验'),
    const QualityDimension('C6', '同日期幂等(确定性)', 1, 0, 0, '重复计算一致'),
  ].map((d) {
    final p = d.id == 'C1'
        ? c1p
        : d.id == 'C2'
            ? c2p
            : d.id == 'C3'
                ? c3p
                : d.id == 'C4'
                    ? c4p
                    : d.id == 'C5'
                        ? c5p
                        : c6p;
    final t = d.id == 'C1'
        ? c1t
        : d.id == 'C2'
            ? c2t
            : d.id == 'C3'
                ? c3t
                : d.id == 'C4'
                    ? c4t
                    : d.id == 'C5'
                        ? c5t
                        : c6t;
    return QualityDimension(d.id, d.label, d.weight, p, t, d.note);
  }).toList());
}
