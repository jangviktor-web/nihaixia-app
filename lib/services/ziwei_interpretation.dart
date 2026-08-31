import 'package:nihaisha_app/services/ziwei_engine.dart';

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

String _areaOf(ZiweiChart chart, int palaceIndex) {
  final role = chart.palaces[palaceIndex].roleLabel;
  return _palaceMeanings[role] ?? role;
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
// 与 ziwei_engine.dart 中 calculateFlowYearMark 的天干算法 (year+6)%10 一致，
// 星名与 _starLabelMap 中文 label 完全对齐（十四主星 / 文昌文曲均为引擎真实名）。
// ---------------------------------------------------------------------------
const List<String> _huaJiByStem = [
  '太阳', // 甲
  '太阴', // 乙
  '廉贞', // 丙
  '巨门', // 丁
  '天机', // 戊
  '文曲', // 己
  '天同', // 庚
  '文昌', // 辛
  '武曲', // 壬
  '贪狼', // 癸
];

/// 公开化忌星查表（供测试 / 外部校验锁定）。[stemIndex] 0-9 = 甲乙丙丁戊己庚辛壬癸。
/// 与《紫微斗数全书》十干四化表一致：甲太阳、乙太阴、丙廉贞、丁巨门、戊天机、
/// 己文曲、庚天同、辛文昌、壬武曲、癸贪狼。
String huaJiStarByStem(int stemIndex) => _huaJiByStem[stemIndex];

// ---------------------------------------------------------------------------
// 身体映射口径说明（重要）：
// 本表按「地支 / 中医藏象」对应，而非紫微「十二宫→脏腑」的固定口径。
// 即：流年疾厄宫落在某物理地支(0-11)，取该地支对应的脏腑系统。
// 这样设计让「健康提醒」能随流年疾厄宫位置逐年变化部位（紫微原生疾厄宫固定
// 对应大肠/心，不会逐年变部位）。此口径属「民俗文化参考」，非医疗诊断；
// 与倪师《天纪》内容不构成引用关系（仅十四主星性质表取自《天纪》）。
// 若日后切换为严格紫微口径，把本表换成「疾厄宫→大肠/心」固定映射即可。
// ---------------------------------------------------------------------------
const Map<int, String> palaceBodyMap = {
  0: '膀胱、耳、生殖泌尿系统',
  1: '脾胃、腹部',
  2: '胆、手、肺',
  3: '肝、十指、神经系统',
  4: '胃、胸、消化系统',
  5: '心、咽喉',
  6: '心、眼、小肠',
  7: '脾胃、腹部',
  8: '肺、大肠、呼吸道',
  9: '肺、皮肤、呼吸道',
  10: '命门、腿足',
  11: '肾、头、膀胱',
};

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
    final names = ming.majors.map((s) => s.label).join('、');
    sb.write('命宫$names坐守，格局清朗，先天心性已具主见。');
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
    } else {
      b.write('宫内${majors.map((s) => s.label).join('、')}坐守');
    }
    if (bads.isNotEmpty) {
      b.write('，需注意${bads.map((s) => s.label).join('、')}扰动');
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

  final mingMajors = mingPalace.majors.map((s) => s.label).join('、');
  sb.write('${flow.year}年（${flow.ganzhi}）流年命宫');
  sb.write(mingMajors.isNotEmpty ? '$mingMajors坐守' : '无主星、借对宫');

  final flowNames = flow.flowStars[flow.mingIndex];
  if (flowNames != null && flowNames.isNotEmpty) {
    sb.write('，见${flowNames.join('、')}');
  }

  final illMajors = illPalace.majors.map((s) => s.label).join('、');
  final bodyPart = palaceBodyMap[illnessIndex] ?? '相关身体部位';
  sb.write('；流年疾厄宫${illMajors.isNotEmpty ? '$illMajors坐守' : '空宫'}，身体留意$bodyPart。');

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

    final bodyBase = palaceBodyMap[illnessIndex] ?? '相关身体部位';
    final bodyPart = palace.roleLabel == '疾厄宫'
        ? '$bodyBase；后天体质、病邪易侵处'
        : bodyBase;

    // 1) 本局煞星落流年疾厄宫
    if (palace.bads.isNotEmpty) {
      final names = palace.bads.map((s) => s.label).join('、');
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
    final huaJi = _huaJiByStem[stemIdx];
    int? nativeIndex;
    for (final p in chart.palaces) {
      if (p.stars.any((s) => s.label == huaJi)) {
        nativeIndex = p.index;
        break;
      }
    }
    if (nativeIndex == illnessIndex) {
      final note = _niHaiXiaStarNote[huaJi];
      final reason = note != null
          ? '流年疾厄宫见流年化忌（$huaJi，$note）'
          : '流年疾厄宫见流年化忌（$huaJi）';
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
