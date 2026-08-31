import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
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

  const SolarTermInfo({
    required this.currentTerm,
    required this.nextTerm,
    required this.daysInto,
    required this.daysLeft,
    required this.healthTip,
  });
}

/// 单节气养生知识（源自 [assets/data/solar_term_knowledge.json]）。
///
/// 内容分两层：[health] 为通用中医节气养生常识；[niShi] 为基于倪海厦先生
/// 公开讲座反复强调的原则（如「春夏养阳、秋冬养阴」「节气交替阴阳转换，
/// 慢性病易发作」）整理，凡非逐字原文均标注【推断】。
class SolarTermKnowledge {
  final String term;
  final String health;
  final String niShi;

  const SolarTermKnowledge({
    required this.term,
    required this.health,
    required this.niShi,
  });

  factory SolarTermKnowledge.fromJson(Map<String, dynamic> json) =>
      SolarTermKnowledge(
        term: json['term'] as String,
        health: json['health'] as String,
        niShi: json['niShi'] as String,
      );
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

/// 全量节气养生知识缓存（首次访问按需从资源加载，幂等）。
Map<String, SolarTermKnowledge>? _knowledgeCache;

/// 加载并缓存 24 节气养生知识（幂等，可重复调用）。
Future<Map<String, SolarTermKnowledge>> _loadKnowledge() async {
  if (_knowledgeCache != null) return _knowledgeCache!;
  final raw =
      await rootBundle.loadString('assets/data/solar_term_knowledge.json');
  final list = (jsonDecode(raw) as List<dynamic>)
      .map((e) => SolarTermKnowledge.fromJson(e as Map<String, dynamic>))
      .toList();
  _knowledgeCache = {for (final k in list) k.term: k};
  return _knowledgeCache!;
}

/// 获取指定节气的养生知识（[health] + [niShi]）。
///
/// [term] 须为 24 节气名之一（如「立春」）。找不到返回 null（调用方兜底）。
Future<SolarTermKnowledge?> getSolarTermKnowledge(String term) async {
  final map = await _loadKnowledge();
  return map[term];
}

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
    );
  }
  final current = info.prevJieQi.name;
  return SolarTermInfo(
    currentTerm: current,
    nextTerm: info.nextJieQi.name,
    daysInto: info.daysSincePrevJieQi.round(),
    daysLeft: info.daysUntilNextJieQi.round(),
    healthTip: _healthTips[current] ?? '顺时养生，起居有常。',
  );
}
