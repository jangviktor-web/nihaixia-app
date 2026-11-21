import 'package:flutter/material.dart';

import '../data/settings_repository.dart';
import '../engine/diagnostic_engine.dart';
import '../engine/diagnostic_rules.dart';
import '../models/diagnosis.dart';
import 'llm_ask_screen.dart';
import 'symptom_result_sheet.dart';

/// 兼症（按诊）分组：胸口、心下、腹部、少腹的按压与自觉。
///
/// 这些信号在倪师讲义里往往是**决定性的**——「少腹急结」定桃核承气汤、
/// 「心下逆满」定苓桂术甘汤、「胸闷」定桂枝去芍药汤——但十问（问诊）问不到，
/// 规则表却有 37 首方把它们当必选(★)。自查页不给入口，这些方在自查路径上
/// 就是结构性不可达（37/172 = 21.5%），病人只能拿到按经套出来的方，
/// 一对照讲义自然显得「AI 更对」。
const Map<String, List<(String, String)>> _kExtGroups = {
  '胸部': [
    ('chest_oppression', '胸闷/气短'),
    ('chest_hard_full', '胸中痞硬（气上冲咽）'),
    ('chest_full_no_lie', '胸满不能卧'),
    ('chest_diaphragm_hard', '胸膈心下硬满（项强）'),
    ('chest_heart_great_cold', '心胸中大寒痛'),
    ('vexing_heat_pain', '心中懊憹热痛'),
    ('suspended_fluid', '悬饮（胸胁引痛）'),
  ],
  '心下（胃脘）': [
    ('epigastric_reverse_full', '心下逆满'),
    ('epigastric_palpitation', '心下悸'),
    ('epigastric_full_pain', '心下满微痛'),
    ('epigastric_press_pain', '心下按之痛（局限）'),
    ('epigastric_hard_full', '心下硬满（无热）'),
    ('epigastric_solid_full', '心下坚满（利反快）'),
    ('epigastric_hard_solid', '心下痞坚（面色黧黑）'),
    ('epigastric_to_abdomen_hard', '心下至少腹硬满剧痛'),
  ],
  '腹部': [
    ('periumbilical_pain', '绕脐痛'),
    ('abdomen_pain', '腹中痛（里急）'),
    ('abdomen_colic', '腹痛阵作时止'),
    ('abdomen_cold_thunder', '腹中寒气雷鸣切痛'),
    ('abdomen_full', '腹满'),
    ('heart_abdomen_acute', '心腹胀满卒痛'),
    ('hypochondriac_partial_pain', '胁下偏痛'),
    ('hypochondriac_qi_rise', '胁下气逆'),
  ],
  '少腹': [
    ('lesser_abdomen_acute', '少腹急结'),
    ('lesser_abdomen_hard', '少腹硬满'),
    ('lesser_abdomen_full', '少腹满'),
    ('lesser_abdomen_mass', '少腹癥块'),
  ],
  '其他': [
    ('nape_stiff', '项强如柔痉'),
    ('umbilical_palpitation', '脐下悸'),
    ('day_vex_night_calm', '昼日烦躁夜安静'),
    ('body_no_aversion_face_red', '身反不恶寒面赤'),
    ('jaundice_dark_forehead', '身黄额上黑'),
    ('jaundice_abdominal_full', '身黄腹满'),
  ],
};

/// 症状自查：把辨证引擎的「十问」做成一页式勾选表，一次出结果。
///
/// 与「辨证」Tab 的聊天式问诊共用同一套引擎与规则数据（DiagnosticEngine +
/// DiagnosticRules.tenQuestions），区别只在交互：聊天页一问一答翻十屏，
/// 自查页平铺一页、选完直接出结论，适合「我已经知道自己哪儿不舒服、
/// 只想快速对一下方证」的场景。
///
/// 数据全部来自本地规则引擎，不联网。
class SymptomCheckScreen extends StatefulWidget {
  const SymptomCheckScreen({super.key});

  @override
  State<SymptomCheckScreen> createState() => _SymptomCheckScreenState();
}

class _SymptomCheckScreenState extends State<SymptomCheckScreen> {
  final DiagnosticEngine _engine = DiagnosticEngine();
  List<FollowUpQuestion> _questions = const [];

  /// key → 选中的选项下标（每题单选，与聊天页的口径一致）。
  final Map<String, int> _selected = {};

  /// 寒热总纲。**必须选**：引擎靠它定六经方向（temperatureToMeridian），
  /// 不选则 diagnose() 只能拿症状权重瞎猜——实测全正常选项会被判成
  /// 「当归散证」、怕冷便溏会被判成「小青龙汤证」。
  String? _tempKey;

  /// 进阶线索（寒热真假八维，选填多选）：疑似寒热错杂时靠它纠正六经方向。
  /// 聊天页有这一步、原自查页漏了——实测「怕冷+便稀+尿清+嗜睡」会因此
  /// 被判成小青龙汤，勾上「小便清长」「大便稀溏」后才回到少阴/太阴。
  final Set<String> _clues = {};

  /// 已勾选的兼症（规则引擎 ext key）。十问问不到、但 37 首方以之为必选，
  /// 由 [ _kExtGroups ] 提供入口。
  final Set<String> _extSelected = {};

  /// 至少答这么多题才允许辨证：只勾一两项容易给出误导性结论。
  static const int _minAnswered = 3;

  @override
  void initState() {
    super.initState();
    final settings = SettingsRepository.instance;
    _questions = _engine.getTenQuestions(defaultGender: settings.defaultGender);
  }

  void _pick(FollowUpQuestion q, int index) {
    setState(() {
      if (_selected[q.key] == index) {
        _selected.remove(q.key); // 再点一次取消，避免选错后只能重开页面
      } else {
        _selected[q.key] = index;
      }
    });
  }

  void _runDiagnosis() {
    final temp = _tempKey;
    if (temp == null) return;
    // 定性六经方向，再灌十问——顺序与聊天页一致，跳过这步结论会跑偏。
    _engine.answerTemperaturePattern(temp);
    // 舌脉不做（自查页不要求用户摸脉），走「跳过」入口，与引擎既有分支一致。
    _engine.answerTonguePulse();
    // 逐题灌进引擎。用 answerTenQuestion 而非 answerFlatQuestion：
    // 后者会额外写 _qAnswers（v3.2 规则引擎的索引口径），与聊天页（本功能
    // 的已验证基线）不一致 —— 实测会用错口径、给出固定兜底结论。
    for (final q in _questions) {
      final idx = _selected[q.key];
      if (idx == null) continue;
      _engine.answerTenQuestion(q.key, q.options[idx]);
    }

    // 进阶线索：与聊天页一样在十问之后灌入，供寒热真假判定纠正方向。
    for (final key in _clues) {
      final label = DiagnosticRules.zhenJiaClueKeys.entries
          .firstWhere((e) => e.value == key,
              orElse: () => const MapEntry('', ''))
          .key;
      if (label.isNotEmpty) _engine.answerZhenJia(key, label);
    }

    // 兼症（按诊）：逐项写入引擎的 ext 集合，取消勾选的显式移除——
    // toggle 是幂等的，但只 add 不 remove 会让用户改主意后仍留着旧信号。
    for (final group in _kExtGroups.values) {
      for (final (key, _) in group) {
        _engine.toggleExtSymptom(key, _extSelected.contains(key));
      }
    }

    // 与聊天页一致：倪师六条健康基线全过 → 直接给正面反馈，不进入异常辨证。
    // 少了这一步，全选「正常」的人会被判成某个方证（实测「当归散证」）。
    if (_engine.healthyBaselineOk) {
      _showHealthy();
      return;
    }

    // 鉴别追问：规则表里有几组方「必选(★)信号完全相同」，引擎自己分不开。
    // 并列 ≥2 首时先补问一句（答案走 reference，+1 分即可破局），答完再出结论。
    final extra = _engine.pendingDisambiguator();
    if (extra != null && !_questions.any((q) => q.key == extra.key)) {
      setState(() => _questions = [..._questions, extra]);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('你的答案落到几首同证的方上，末尾多了一题，确认后再点一次')),
      );
      return;
    }

    final result = _engine.diagnose();
    if (!mounted) return;
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('信息不足，无法给出结论；请多选几项后再试')),
      );
      return;
    }
    _showResult(result);
  }

  /// 六条健康基线全过：直接给正面反馈，不硬凑一个方证。
  void _showHealthy() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.verified_outlined,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('倪师六条健康基线全部达标',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 12),
            const Text(
              '一觉到天亮、晨起排便成形、小便淡黄一天 5-7 次、手脚温热、'
              '有胃口食之有味、早起床精神好。\n\n'
              '继续保持：不熬夜、忌生冷、七分饱、顺应时辰。',
              style: TextStyle(fontSize: 13, height: 1.7),
            ),
          ],
        ),
      ),
    );
  }

  /// 把勾选结果写成结构化四诊文本，交给「问倪师 AI」。
  /// 用题目原文（含「（少阳）」括注）而非 key——那是模型的辨证线索。
  String _buildAiPrefill(DiagnosisResult r) {
    final buf = StringBuffer()
      ..writeln('我按倪师十问自查的结果如下，请结合讲义与医案帮我辨证：')
      ..writeln('【四诊·问诊】');
    for (final q in _questions) {
      final i = _selected[q.key];
      if (i == null || i < 0 || i >= q.options.length) continue;
      buf.writeln('${q.question}：${q.options[i]}');
    }
    final temp = DiagnosticRules.temperaturePatterns
        .where((t) => t.key == _tempKey)
        .map((t) => t.label)
        .toList();
    if (temp.isNotEmpty) buf.writeln('【寒热总纲】${temp.join('、')}');
    if (_clues.isNotEmpty) {
      final labels = DiagnosticRules.zhenJiaClueKeys.entries
          .where((e) => _clues.contains(e.value))
          .map((e) => e.key);
      buf.writeln('【寒热真假线索】${labels.join('、')}');
    }
    buf
      // 明确标注为「待验证假设」：这不是用户自述的结论，也不是讲义事实。
      // 模型若把它当既定事实，就会顺着复述；当它是错误断言，又会刻意反驳。
      // 也不写「置信度 95%」——那个数字只是勾选条数的映射，写进提示词会让
      // 模型拿它当可信度背书，反而降低纠错意愿。
      ..writeln('【本地规则初判·待验证假设，非讲义原文】${r.meridian}病 · ${r.pattern}'
          '（${r.matchedSymptoms.isEmpty ? "没有逐条症状依据，只是按经络方向给的参考方" : "依据 ${r.matchedSymptoms.length} 项症状，本地规则只反映信息量，不代表准确率"}）')
      ..writeln('【该假设给出的参考方剂】${r.recommendedFormulas.isEmpty ? r.formula : r.recommendedFormulas.join('、')}')
      ..writeln('请只依据讲义与医案核对这个假设：它成不成立、依据是哪几条、'
          '若不成立该是什么证；并指出我漏问了什么。不要直接复述假设，'
          '也不要照搬西医病名。');
    return buf.toString().trim();
  }

  /// 检索专用词：只用勾选项的裸症状（去括注），不带「请结合讲义」等套话。
  /// 组词顺序：诊断名 → 寒热 → 症状，让 keywordsFor 的前 32 个 4 字词
  /// 优先覆盖辨证关键线索，而不是被模板文字吃掉。
  String _buildRetrievalQuery(DiagnosisResult r) {
    final parts = <String>[r.pattern, ...r.matchedSymptoms];
    final temp = DiagnosticRules.temperaturePatterns
        .where((t) => t.key == _tempKey)
        .map((t) => t.label)
        .toList();
    parts.addAll(temp);
    for (final q in _questions) {
      final i = _selected[q.key];
      if (i == null || i < 0 || i >= q.options.length) continue;
      // 「手脚冰冷（阴·阳虚）」→「手脚冰冷」：括注是规则引擎的分类提示，
      // 不是患者主诉，进检索词只会稀释症状。
      parts.add(q.options[i].replaceAll(RegExp(r'（[^）]*）'), ''));
    }
    for (final e in DiagnosticRules.zhenJiaClueKeys.entries) {
      if (_clues.contains(e.value)) parts.add(e.key);
    }
    return parts.where((s) => s.trim().isNotEmpty).join(' ');
  }

  void _showResult(DiagnosisResult r) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.92,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => SymptomResultSheet(
          result: r,
          // future 在弹层外创建（见 SymptomResultSheet.relatedCases 注释）：
          // FutureBuilder 每次 rebuild 都会重订阅，写进内层会让滚动反复重扫医案库。
          relatedCases: SymptomResultSheet.loadRelated(r),
          scrollController: scrollCtrl,
          onAskAi: () {
            Navigator.pop(sheetCtx); // 先关结果弹层，避免叠三层
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LlmAskScreen(
                  prefill: _buildAiPrefill(r),
                  retrievalQuery: _buildRetrievalQuery(r),
                  freshSession: true,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enough = _tempKey != null && _selected.length >= _minAnswered;
    return Scaffold(
      appBar: AppBar(
        title: const Text('症状自查'),
        actions: [
          if (_selected.isNotEmpty)
            TextButton(
              onPressed: () => setState(() {
                _selected.clear();
                _tempKey = null;
                _clues.clear();
                _extSelected.clear();
              }),
              child: const Text('清空'),
            ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: _questions.length + 4,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
              child: Text(
                '把符合自己的描述选上（每题最多一项），选 $_minAnswered 题以上再辨证。',
                style: TextStyle(fontSize: 12, height: 1.6, color: cs.onSurfaceVariant),
              ),
            );
          }
          if (i == 1) {
            // 第一步：寒热总纲（决定六经方向，必选）
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('【第一步·寒热总纲】先分阴阳：你主要是怕冷还是发热？',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            height: 1.5)),
                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final t in DiagnosticRules.temperaturePatterns)
                              ChoiceChip(
                                label: Text('${t.label} → ${t.targetMeridian}',
                                    style: const TextStyle(fontSize: 12)),
                                selected: _tempKey == t.key,
                                onSelected: (_) =>
                                    setState(() => _tempKey = t.key),
                              ),
                          ],
                        ),
                        // 选中后补一句解释，避免只凭标签猜自己属于哪类
                        if (_tempKey != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DiagnosticRules.temperaturePatterns
                                  .firstWhere((t) => t.key == _tempKey)
                                  .description,
                              style: TextStyle(
                                  fontSize: 11,
                                  height: 1.5,
                                  color: cs.onSurfaceVariant),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
          if (i == 2) {
            // 第二步：进阶线索（选填）——多选，帮引擎判断寒热真假
            final cs2 = Theme.of(context).colorScheme;
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('【第二步·进阶线索】（选填，可多选）寒热错杂、真假难辨时勾这几条',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                            color: cs2.onSurface)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final e
                            in DiagnosticRules.zhenJiaClueKeys.entries)
                          FilterChip(
                            label: Text(e.key,
                                style: const TextStyle(fontSize: 12)),
                            selected: _clues.contains(e.value),
                            onSelected: (on) => setState(() {
                              if (on) {
                                _clues.add(e.value);
                              } else {
                                _clues.remove(e.value);
                              }
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }
          if (i == _questions.length + 3) {
            // 第三步：兼症（按诊）。十问问不到、但 37 首方以之为必选，
            // 不给入口这些方在自查路径上就永远出不来。
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                initiallyExpanded: _extSelected.isNotEmpty,
                title: const Text('【第三步·兼症按诊】（选填，可多选）',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        height: 1.5)),
                subtitle: Text(
                  '按压胸腹有什么感觉？这些兼症决定很多经方的取舍——'
                  '「少腹急结」定桃核承气汤、「心下逆满」定苓桂术甘汤，十问问不到。',
                  style: TextStyle(
                      fontSize: 11, height: 1.5, color: cs.onSurfaceVariant),
                ),
                children: [
                  for (final g in _kExtGroups.entries) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 6),
                        child: Text(g.key,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: cs.primary)),
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final (key, label) in g.value)
                          FilterChip(
                            label: Text(label,
                                style: const TextStyle(fontSize: 11)),
                            selected: _extSelected.contains(key),
                            visualDensity: VisualDensity.compact,
                            onSelected: (v) => setState(() {
                              if (v) {
                                _extSelected.add(key);
                              } else {
                                _extSelected.remove(key);
                              }
                            }),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }
          final q = _questions[i - 3];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.question,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          height: 1.5)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var oi = 0; oi < q.options.length; oi++)
                        ChoiceChip(
                          label: Text(q.options[oi],
                              style: const TextStyle(fontSize: 12)),
                          selected: _selected[q.key] == oi,
                          onSelected: (_) => _pick(q, oi),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            onPressed: enough ? _runDiagnosis : null,
            icon: const Icon(Icons.playlist_add_check, size: 18),
            label: Text(enough
                ? '开始辨证（十问已选 ${_selected.length} 项）'
                : _tempKey == null
                    ? '请先选寒热总纲'
                    : '十问至少选 $_minAnswered 项'),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46)),
          ),
        ),
      ),
    );
  }
}
