import 'package:flutter/material.dart';

import '../data/formula_repository.dart';
import '../data/settings_repository.dart';
import '../engine/diagnostic_engine.dart';
import '../engine/diagnostic_rules.dart';
import '../models/diagnosis.dart';
import 'formula_detail_screen.dart';

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

    // 与聊天页一致：倪师六条健康基线全过 → 直接给正面反馈，不进入异常辨证。
    // 少了这一步，全选「正常」的人会被判成某个方证（实测「当归散证」）。
    if (_engine.healthyBaselineOk) {
      _showHealthy();
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

  void _showResult(DiagnosisResult r) {
    final cs = Theme.of(context).colorScheme;
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
        builder: (_, scrollCtrl) => ListView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: [
            Text('自查结果',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _pill('${r.meridian}病', cs.primary),
                const SizedBox(width: 8),
                _pill('置信度 ${(r.confidence * 100).round()}%',
                    cs.surfaceContainerHighest),
              ],
            ),
            const SizedBox(height: 12),
            Text(r.pattern,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, height: 1.4)),
            if (r.patternDetail.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(r.patternDetail,
                  style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: cs.onSurfaceVariant)),
            ],
            const SizedBox(height: 16),
            Text('参考方剂',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: cs.primary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in r.recommendedFormulas.isEmpty
                    ? <String>[r.formula]
                    : r.recommendedFormulas)
                  ActionChip(
                    avatar: const Icon(Icons.medication_outlined, size: 16),
                    label: Text(name),
                    // 点进去看组成、剂量与「见于经典」原文
                    onPressed: () {
                      final f = FormulaRepository.getByName(name);
                      if (f == null) return;
                      Navigator.push(
                        sheetCtx,
                        MaterialPageRoute(
                            builder: (_) => FormulaDetailScreen(formula: f)),
                      );
                    },
                  ),
              ],
            ),
            if (r.matchedSymptoms.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('命中的症状',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: cs.primary)),
              const SizedBox(height: 6),
              Text(r.matchedSymptoms.join('、'),
                  style: const TextStyle(fontSize: 12, height: 1.6)),
            ],
            if (r.explanation.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('为什么这样辨',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: cs.primary)),
              const SizedBox(height: 6),
              Text(r.explanation,
                  style: const TextStyle(fontSize: 12, height: 1.7)),
            ],
            const SizedBox(height: 16),
            Text(
              '本结果由本地规则引擎按倪师讲义规则生成，仅供学习参考，不构成诊疗建议。'
              '结论偏倚可能来自勾选项不全或有相互矛盾的描述，症状复杂请用聊天式问诊逐项确认。',
              style: TextStyle(fontSize: 11, height: 1.6, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface)),
      );

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
              }),
              child: const Text('清空'),
            ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
        itemCount: _questions.length + 3,
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
