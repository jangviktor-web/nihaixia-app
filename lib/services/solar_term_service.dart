import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart';

/// 当前节气信息（基于 sxwnl_spa_dart 0.18.5 的 [getJieQiInfo]，节气内部按 UTC+8 北京时间计算）。
class SolarTermInfo {
  /// 当前所处节气（最近的上一节气节点名称，如「处暑」）。
  final String currentTerm;

  /// 下一节气名称。
  final String nextTerm;

  /// 进入当前节气第几天。
  final int daysInto;

  /// 距下一节气还有几天。
  final int daysLeft;

  /// 当季养生要点（中医视角，简明）。
  final String healthTip;

  /// 当季本草药性（温/寒/凉/平/热），用于联动 [HerbRepository.getByNature]。
  final String seasonNature;

  const SolarTermInfo({
    required this.currentTerm,
    required this.nextTerm,
    required this.daysInto,
    required this.daysLeft,
    required this.healthTip,
    required this.seasonNature,
  });
}

/// 24 节气养生要点（中医视角，简明，无占卜断言）。
const Map<String, String> _healthTips = {
  '小寒': '敛藏精气，宜温补养肾，勿妄泄汗。',
  '大寒': '一年极寒，进补收尾，防风寒袭表。',
  '立春': '阳气初生，疏肝理气，夜卧早起。',
  '雨水': '湿气渐升，健脾祛湿，慎避风寒。',
  '惊蛰': '春雷乍动，护肝养阳，戒怒以安志。',
  '春分': '阴阳平分，调和肝脾，起居有常。',
  '清明': '清气上升，宜柔肝养血，防春瘟。',
  '谷雨': '雨生百谷，健脾益胃，祛湿通络。',
  '立夏': '心气始旺，养心安神，午休养阳。',
  '小满': '湿热渐盛，清热利湿，慎食生冷。',
  '芒种': '暑湿交蒸，清心除烦，防倦怠。',
  '夏至': '一阴初生，宁心静神，勿贪凉饮冷。',
  '小暑': '暑气上腾，养心健脾，及时补水。',
  '大暑': '暑湿鼎盛，化湿醒脾，谨防中暑。',
  '立秋': '凉风渐至，润肺养阴，早卧早起。',
  '处暑': '暑气将退，润燥安神，增减衣物。',
  '白露': '阴气渐重，润肺防燥，护足保暖。',
  '秋分': '燥金主令，滋阴润燥，平肝潜阳。',
  '寒露': '寒意袭人，温肺暖胃，防寒从足生。',
  '霜降': '秋燥末尾，补肺健脾，御寒固表。',
  '立冬': '阳气潜藏，温补肾阳，敛藏为本。',
  '小雪': '天寒地冻，温通血脉，避寒就温。',
  '大雪': '封藏极盛，滋补肾精，静养少泄。',
  '冬至': '一阳来复，养藏护阳，节欲少劳。',
};

/// 当季本草药性（春温升发 / 夏寒清热 / 秋平润燥 / 冬温养藏），用于联动本草库。
const Map<String, String> _seasonNature = {
  '立春': '温', '雨水': '温', '惊蛰': '温', '春分': '温', '清明': '温', '谷雨': '温',
  '立夏': '寒', '小满': '寒', '芒种': '寒', '夏至': '寒', '小暑': '寒', '大暑': '寒',
  '立秋': '平', '处暑': '平', '白露': '平', '秋分': '平', '寒露': '平', '霜降': '平',
  '立冬': '温', '小雪': '温', '大雪': '温', '冬至': '温', '小寒': '温', '大寒': '温',
};

/// 计算当前节气信息。
///
/// [now] 省略时取设备当前时间。返回 [SolarTermInfo]，调用方据此展示
/// 「当前节气 + 距下一节气倒计时 + 养生要点」。
SolarTermInfo getCurrentSolarTerm([DateTime? now]) {
  final dt = now ?? DateTime.now();
  final target = AstroDateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
  final info = getJieQiInfo(target);
  if (info == null) {
    return const SolarTermInfo(
      currentTerm: '',
      nextTerm: '',
      daysInto: 0,
      daysLeft: 0,
      healthTip: '节气信息暂不可用，请稍后重试。',
      seasonNature: '平',
    );
  }
  final current = info.prevJieQi.name;
  return SolarTermInfo(
    currentTerm: current,
    nextTerm: info.nextJieQi.name,
    daysInto: info.daysSincePrevJieQi.round(),
    daysLeft: info.daysUntilNextJieQi.round(),
    healthTip: _healthTips[current] ?? '顺时养生，起居有常。',
    seasonNature: _seasonNature[current] ?? '平',
  );
}
