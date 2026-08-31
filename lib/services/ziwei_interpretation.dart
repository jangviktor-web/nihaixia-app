import 'package:nihaisha_app/services/ziwei_engine.dart';

import '../data/ziwei_rules_repository.dart';

/// 紫微斗数解读层（纯逻辑、UI 无关、可测）。
///
/// 综合命盘 [ZiweiChart] 与生年四化、十二大限、流年盘，产出：
/// - 整体运势叙述 [summarizeOverall]
/// - 十年大运逐限评语 [summarizeDecades]
/// - 单流年运势 [summarizeFlowYear]
/// - 健康提醒清单 [analyzeHealthWatch]
///
/// 全部为规则模板，离线计算，不调网络 / LLM。结果属「民俗文化参考」，
/// 非医疗诊断（健康提醒卡 UI 中会再次标注免责声明）。
///
/// 倪师《天纪·天机道》十四主星 / 十二宫口径取自 `ziwei_reference_screen.dart`
/// 的 [`ZiweiReferenceScreen.palaceMeanings`] 与十四主星表；此处以相同数据
/// 本地化为纯逻辑可用的映射，避免逻辑层反向依赖 UI 层。其余健康宫位→身体
/// 部位基线为通用紫微口径，未引入任何编造的倪师原话。

// ---------------------------------------------------------------------------
// 宫位名 → 人生领域（与 ZiweiReferenceScreen.palaceMeanings 保持一致）
// ---------------------------------------------------------------------------
const Map<String, String> _palaceMeanings = {
  '命宫': '性格格局',
  '兄弟宫': '兄弟姐妹',
  '夫妻宫': '婚姻感情',
  '子女宫': '子女缘分',
  '财帛宫': '财运理财',
  '疾厄宫': '健康疾病',
  '迁移宫': '外出际遇',
  '交友宫': '人际交友',
  '官禄宫': '事业功名',
  '田宅宫': '不动产',
  '福德宫': '精神生活',
  '父母宫': '父母长辈',
};

/// 星曜显示文本（UI 与解读层统一入口）：带亮度与四化，如「武曲(庙·禄)」。
///
/// 亮度/四化任一为空则省略对应括号内容，绝不输出空括号。
/// 宫位星曜渲染与解读文案统一走此函数，确保「庙旺利陷 + 四化」标注一致。
String starDisplayText(ZiweiStar s) {
  final parts = <String>[];
  if (s.brightness != null && s.brightness!.isNotEmpty) parts.add(s.brightness!);
  if (s.sihua != null) parts.add(s.sihuaText);
  final suffix = parts.isEmpty ? '' : '(${parts.join('·')})';
  return '${s.label}$suffix';
}

/// 亮度（庙旺利陷平）中文形容词，用于把星曜亮度写进运势/健康句式。
/// null 或未知 → 空串（调用方据此跳过，保持句子通顺）。
/// 7 档：庙=得地有力 / 旺=乘旺 / 得=得地 / 利=平顺 / 平=中和 / 不=势弱 / 陷=偏弱。
String dignityAdjective(String? brightness) {
  switch (brightness) {
    case '庙':
      return '得地有力';
    case '旺':
      return '乘旺';
    case '得':
      return '得地';
    case '利':
      return '平顺';
    case '平':
      return '中和';
    case '不':
      return '势弱';
    case '陷':
      return '偏弱';
    default:
      return '';
  }
}

/// 星曜 + 亮度形容词组合，如「武曲(庙)·得地有力」，供运势句式嵌入。
String starDignityPhrase(ZiweiStar s) {
  final adj = dignityAdjective(s.brightness);
  final base = starDisplayText(s);
  return adj.isEmpty ? base : '$base·$adj';
}

String _areaOf(ZiweiChart chart, int palaceIndex) {
  final role = chart.palaces[palaceIndex].roleLabel;
  return _palaceMeanings[role] ?? role;
}

/// 大限宫无主星时，拼出对宫（相隔六宫）的星情参看提示。
///
/// 紫微斗数「借星安宫」惯例：本宫空宫则取对宫同度主星参看。对宫索引恒为
/// `(palaceIndex + 6) % 12`（十二宫两两相对）。对宫有主星则列出其主星与煞星，
/// 否则说明对宫亦空。
String _oppositePalaceNote(ZiweiChart chart, int palaceIndex) {
  final opp = (palaceIndex + 6) % 12;
  final oppPalace = chart.palaces[opp];
  if (oppPalace.majors.isEmpty) {
    return '（对宫${oppPalace.roleLabel}亦无主星）';
  }
  final stars = oppPalace.majors.map(starDisplayText).join('、');
  final sb = StringBuffer('（对宫${oppPalace.roleLabel}：$stars坐守');
  if (oppPalace.bads.isNotEmpty) {
    sb.write('、需注意${oppPalace.bads.map(starDisplayText).join('、')}扰动');
  }
  sb.write('）');
  return sb.toString();
}

/// 在命盘中查找某星曜原生所在宫的物理地支索引（按中文 label 匹配）。
int _palaceIndexOfStar(ZiweiChart chart, String starLabel) {
  for (final p in chart.palaces) {
    if (p.stars.any((s) => s.label == starLabel)) return p.index;
  }
  return chart.originMingIndex;
}

// ---------------------------------------------------------------------------
// 倪师《天纪·天机道》十四主星口径（忠实自 ziwei_reference_screen.dart _majors）。
// 仅用于「流年化忌」命中时附原星性质说明，引用即标记 source='倪师《天纪》'。
// 不含十四主星之外的星（如文昌/文曲为吉星，不在此口径内）。
// ---------------------------------------------------------------------------
const Map<String, String> _niHaiXiaStarNote = {
  '紫微': '紫微为帝座，主尊贵权威（属土）',
  '天机': '天机为智慧星，主聪明善变（属木）',
  '太阳': '太阳为中天主星，主光明博爱（属火）',
  '武曲': '武曲为财星，主刚毅果断（属金）',
  '天同': '天同为福星，主温和享受（属水）',
  '廉贞': '廉贞为次桃花星，主多情是非（属火）',
  '天府': '天府为财库星，主稳重保守（属土）',
  '太阴': '太阴为田宅主，主阴柔内敛（属水）',
  '贪狼': '贪狼为桃花星，主欲望才艺（属木）',
  '巨门': '巨门为暗星，主口舌是非（属水）',
  '天相': '天相为印星，主辅佐公正（属水）',
  '天梁': '天梁为荫星，主化解逢凶化吉（属土）',
  '七杀': '七杀为将星，主冲劲变革（属金）',
  '破军': '破军为耗星，主破坏创新（属水）',
};

// ---------------------------------------------------------------------------
// 流年化忌四化表：天干索引 0-9 = 甲乙丙丁戊己庚辛壬癸 → 化忌星名。
// 与 ziwei_engine.dart 中 calculateFlowYearMark 的天干算法 (year+6)%10 一致。
//
// 规则已外置到 assets/data/ziwei_rules.json，经 [ZiweiRulesRepository] 读取；
// JSON 缺失或字段异常时自动回退内建默认值（见该仓库类注释）。
// ---------------------------------------------------------------------------

/// 公开化忌星查表（供测试 / 外部校验锁定）。[stemIndex] 0-9 = 甲乙丙丁戊己庚辛壬癸。
/// 与《紫微斗数全书》十干四化表一致：甲太阳、乙太阴、丙廉贞、丁巨门、戊天机、
/// 己文曲、庚天同、辛文昌、壬武曲、癸贪狼。
/// 已用 iztro-py 引擎独立校验 10/10 匹配（tools/ziwei_oracle/oracle.py）。
String huaJiStarByStem(int stemIndex) =>
    ZiweiRulesRepository.huajiByStem[stemIndex];

// ---------------------------------------------------------------------------
// 身体映射口径说明（重要）：
// 本表按「地支 / 中医藏象」对应，而非紫微「十二宫→脏腑」的固定口径。
// 即：流年疾厄宫落在某物理地支(0-11)，取该地支对应的脏腑系统。
// 这样设计让「健康提醒」能随流年疾厄宫位置逐年变化部位（紫微原生疾厄宫固定
// 对应大肠/心，不会逐年变部位）。此口径属「民俗文化参考」，非医疗诊断；
// 与倪师《天纪》内容不构成引用关系（仅十四主星性质表取自《天纪》）。
//
// 规则已外置到 assets/data/ziwei_rules.json（键为 "0".."11" 字符串），
// 经 [ZiweiRulesRepository.bodyPartFor] 读取；缺失时回退内建默认值。
// 若日后切换为严格紫微口径，只需改 JSON 的 palace_body_map，无需改代码。
// ---------------------------------------------------------------------------

/// 单条健康提醒条目。
class HealthWatchItem {
  final int year; // 流年公历年份
  final int age; // 虚岁（year - birthYear + 1）
  final String bodyPart; // 该年流年疾厄宫对应身体部位
  final String reason; // 命中信号描述
  final String source; // '倪师《天纪》' 或 '通用紫微'

  const HealthWatchItem({
    required this.year,
    required this.age,
    required this.bodyPart,
    required this.reason,
    required this.source,
  });
}

// ---------------------------------------------------------------------------
// a) 整体运势叙述（2–4 句，口语化、不浮夸）
// ---------------------------------------------------------------------------
String summarizeOverall(ZiweiChart chart) {
  final ming = chart.palaces[chart.originMingIndex];
  final sb = StringBuffer();

  if (ming.majors.isEmpty) {
    sb.write('命宫无主星，借对宫星情参看，格局平实，行事宜多方参考。');
  } else {
    final names = ming.majors.map(starDignityPhrase).join('、');
    final adjs = ming.majors
        .map((s) => dignityAdjective(s.brightness))
        .where((a) => a.isNotEmpty)
        .toList();
    if (adjs.contains('偏弱')) {
      sb.write('命宫$names坐守，其中偏弱之星宜多借力、勿独撑；格局仍具主见。');
    } else if (adjs.isNotEmpty) {
      sb.write('命宫$names坐守（${adjs.join('、')}），主星得地乘旺，格局更显其能。');
    } else {
      sb.write('命宫$names坐守，格局清朗，先天心性已具主见。');
    }
  }

  final luAreas = <String>[];
  final jiAreas = <String>[];
  final quanKe = <String>[];
  for (final h in chart.sihua) {
    final area = _areaOf(chart, _palaceIndexOfStar(chart, h.starLabelName));
    if (h.typeLabel == '禄') {
      luAreas.add(area);
    } else if (h.typeLabel == '忌') {
      jiAreas.add(area);
    } else {
      quanKe.add('${h.starLabelName}化${h.typeLabel}入$area');
    }
  }

  if (luAreas.isNotEmpty) {
    sb.write('生年${luAreas.join('、')}见化禄，相关领域多得助力、顺遂丰足。');
  }
  if (jiAreas.isNotEmpty) {
    sb.write('${jiAreas.join('、')}见化忌，宜守不宜攻，凡事多斟酌、忌冒进。');
  }
  if (quanKe.isNotEmpty) {
    sb.write('另${quanKe.join('、')}，主增掌控与名声文采。');
  }

  return sb.toString();
}

// ---------------------------------------------------------------------------
// b) 十年大运逐限评语
// ---------------------------------------------------------------------------
List<String> summarizeDecades(ZiweiChart chart) {
  final out = <String>[];
  for (final d in chart.decades) {
    final palace = chart.palaces.firstWhere((p) => p.roleLabel == d.roleLabel);
    final majors = palace.majors;
    final bads = palace.bads;
    final b = StringBuffer();
    b.write('第${d.index}大限 ${d.rangeLabel}，行${d.roleLabel}运：');
    if (majors.isEmpty) {
      b.write('本宫无主星，借对宫星情参看');
      b.write(_oppositePalaceNote(chart, palace.index));
    } else {
      b.write('宫内${majors.map(starDignityPhrase).join('、')}坐守');
      final adjs = majors
          .map((s) => dignityAdjective(s.brightness))
          .where((a) => a.isNotEmpty)
          .toList();
      if (adjs.contains('偏弱')) {
        b.write('（其中偏弱，宜守成、忌冒进）');
      } else if (adjs.isNotEmpty) {
        b.write('（${adjs.join('、')}）');
      }
    }
    if (bads.isNotEmpty) {
      b.write('，需注意${bads.map(starDisplayText).join('、')}扰动');
    } else if (majors.isNotEmpty) {
      b.write('，整体平顺');
    }
    out.add(b.toString());
  }
  return out;
}

// ---------------------------------------------------------------------------
// c) 单流年运势（1–2 句）
// ---------------------------------------------------------------------------
String summarizeFlowYear(ZiweiChart chart, FlowYearMark flow) {
  final mingPalace = chart.palaces[flow.mingIndex];
  final illnessIndex = (flow.mingIndex + 5) % 12;
  final illPalace = chart.palaces[illnessIndex];
  final sb = StringBuffer();

  final mingMajors = mingPalace.majors.map(starDisplayText).join('、');
  sb.write('${flow.year}年（${flow.ganzhi}）流年命宫');
  sb.write(mingMajors.isNotEmpty ? '$mingMajors坐守' : '无主星、借对宫');

  final flowNames = flow.flowStars[flow.mingIndex];
  if (flowNames != null && flowNames.isNotEmpty) {
    sb.write('，见${flowNames.join('、')}');
  }

  final illMajors = illPalace.majors.map(starDisplayText).join('、');
  final bodyPart = ZiweiRulesRepository.bodyPartFor(illnessIndex);
  sb.write('；流年疾厄宫${illMajors.isNotEmpty ? '$illMajors坐守' : '空宫'}，身体留意$bodyPart。');

  return sb.toString();
}

// ---------------------------------------------------------------------------
// c-2) 流月运势（1–2 句，结构与流年对齐）
// ---------------------------------------------------------------------------
/// 农历月份中文（数字，含闰月标识）。
String _lunarMonthLabel(int month, bool isLeap) => '${isLeap ? '闰' : ''}$month月';

String summarizeFlowMonth(ZiweiChart chart, FlowMonthMark flow) {
  final mingPalace = chart.palaces[flow.mingIndex];
  final illPalace = chart.palaces[flow.illnessIndex];
  final sb = StringBuffer();

  final mingMajors = mingPalace.majors.map(starDisplayText).join('、');
  final monthLabel = _lunarMonthLabel(flow.month, flow.isLeap);
  sb.write('${flow.year}年$monthLabel（${flow.ganzhi}）流月命宫');
  sb.write(mingMajors.isNotEmpty ? '$mingMajors坐守' : '无主星、借对宫');

  final illMajors = illPalace.majors.map(starDisplayText).join('、');
  final bodyPart = ZiweiRulesRepository.bodyPartFor(flow.illnessIndex);
  sb.write('；流月疾厄宫${illMajors.isNotEmpty ? '$illMajors坐守' : '空宫'}，身体留意$bodyPart。');

  return sb.toString();
}

// ---------------------------------------------------------------------------
// c-3) 流日运势（1–2 句，结构与流年对齐）
// ---------------------------------------------------------------------------
String summarizeFlowDay(ZiweiChart chart, FlowDayMark flow) {
  final mingPalace = chart.palaces[flow.mingIndex];
  final illPalace = chart.palaces[flow.illnessIndex];
  final sb = StringBuffer();

  final mingMajors = mingPalace.majors.map(starDisplayText).join('、');
  sb.write('${flow.date.year}-${flow.date.month}-${flow.date.day}（${flow.ganzhi}）流日命宫');
  sb.write(mingMajors.isNotEmpty ? '$mingMajors坐守' : '无主星、借对宫');

  final illMajors = illPalace.majors.map(starDisplayText).join('、');
  final bodyPart = ZiweiRulesRepository.bodyPartFor(flow.illnessIndex);
  sb.write('；流日疾厄宫${illMajors.isNotEmpty ? '$illMajors坐守' : '空宫'}，身体留意$bodyPart。');

  return sb.toString();
}

// ---------------------------------------------------------------------------
// d) 健康提醒：遍历 [fromYear, toYear]，逐年取流年疾厄宫命中信号
// ---------------------------------------------------------------------------
List<HealthWatchItem> analyzeHealthWatch(
  ZiweiChart chart, {
  required int fromYear,
  required int toYear,
  required int birthYear,
}) {
  final out = <HealthWatchItem>[];
  for (int year = fromYear; year <= toYear; year++) {
    final flow = calculateFlowYearMark(year: year);
    final illnessIndex = (flow.mingIndex + 5) % 12;
    final palace = chart.palaces[illnessIndex];

    final bodyBase = ZiweiRulesRepository.bodyPartFor(illnessIndex);
    final bodyPart = palace.roleLabel == '疾厄宫'
        ? '$bodyBase；后天体质、病邪易侵处'
        : bodyBase;

    // 1) 本局煞星落流年疾厄宫
    if (palace.bads.isNotEmpty) {
      final names = palace.bads.map(starDisplayText).join('、');
      out.add(HealthWatchItem(
        year: year,
        age: year - birthYear + 1,
        bodyPart: bodyPart,
        reason: '流年疾厄宫见$names（本局煞星）',
        source: '通用紫微',
      ));
    }

    // 2) 流年煞曜（流擎羊 / 流陀罗）
    final flowIll = flow.flowStars[illnessIndex];
    if (flowIll != null) {
      for (final sig in const ['流擎羊', '流陀罗']) {
        if (flowIll.contains(sig)) {
          out.add(HealthWatchItem(
            year: year,
            age: year - birthYear + 1,
            bodyPart: bodyPart,
            reason: '流年疾厄宫见$sig（流年煞曜）',
            source: '通用紫微',
          ));
        }
      }
    }

    // 3) 流年化忌星原生落入流年疾厄宫
    final stemIdx = ((year + 6) % 10 + 10) % 10;
    final huaJi = huaJiStarByStem(stemIdx);
    int? nativeIndex;
    ZiweiStar? jiStar;
    for (final p in chart.palaces) {
      final s = p.stars.where((s) => s.label == huaJi).firstOrNull;
      if (s != null) {
        nativeIndex = p.index;
        jiStar = s;
        break;
      }
    }
    if (nativeIndex == illnessIndex) {
      // 庙旺利陷语气：化忌星若落陷则加重提醒，得地则减轻
      final adj = dignityAdjective(jiStar?.brightness);
      final adjText = adj.isNotEmpty ? '，$adj' : '';
      final note = _niHaiXiaStarNote[huaJi];
      final reason = note != null
          ? '流年疾厄宫见流年化忌（$huaJi$adjText，$note）'
          : '流年疾厄宫见流年化忌（$huaJi$adjText）';
      out.add(HealthWatchItem(
        year: year,
        age: year - birthYear + 1,
        bodyPart: bodyPart,
        reason: reason,
        source: note != null ? '倪师《天纪》' : '通用紫微',
      ));
    }
  }
  return out;
}
