import 'package:flutter/material.dart';

import '../data/chinese_convert.dart';
import '../data/formula_repository.dart';
import '../data/medical_case_data.dart';
import '../engine/formula_rules.dart';
import '../models/diagnosis.dart';
import 'formula_detail_screen.dart';
import 'medical_case_detail_screen.dart';

/// 症状自查结果弹层的内容部分。
///
/// 从 [SymptomCheckScreen] 抽出的原因：一是能被 widget 测试直接构造
/// （不必先走完十问勾选），二是「结论怎么来的」这块展示会持续迭代，
/// 独立成件才好逐条回归。
///
/// 这一页要回答的只有一件事：**凭什么得出这个结论、能不能核对**。
/// 所以三块内容缺一不可——依据条数与口径说明、逐条依据在规则里的角色、
/// 倪师同类医案（唯一带金标准的一步）。
class SymptomResultSheet extends StatelessWidget {
  final DiagnosisResult result;

  /// 同类医案检索的 future。必须由调用方在 build 外创建：
  /// FutureBuilder 每次 rebuild 都会用新 future 重订阅，写在 build 里
  /// 会让滚动时反复重扫 1200+ 条医案。
  final Future<List<MedicalCase>> relatedCases;

  final ScrollController? scrollController;

  /// 「带着这个结果问倪师 AI」。导航由调用方负责（它要处理先关弹层再 push）。
  final VoidCallback onAskAi;

  const SymptomResultSheet({
    super.key,
    required this.result,
    required this.relatedCases,
    required this.onAskAi,
    this.scrollController,
  });

  /// 从全部医案里找与本结果最接近的几例：命中的症状词越多越靠前。
  ///
  /// 这是判定「这个结论对不对」唯一有金标准的一步——医案里记的是倪师
  /// 亲自开的方。用症状词而不是病名检索，是因为用户此刻手里只有症状。
  static Future<List<MedicalCase>> loadRelated(DiagnosisResult r,
      {int max = 3}) async {
    final terms = <String>{
      ...r.matchedSymptoms.map((s) => s.replaceAll(RegExp(r'（[^）]*）'), '')),
      r.pattern,
    }..removeWhere((s) => s.trim().length < 2);
    if (terms.isEmpty) return const [];

    final all = await getAllMedicalCases();
    final scored = <(MedicalCase, int)>[];
    for (final c in all) {
      var hits = 0;
      for (final t in terms) {
        if (c.matchesNormalized(toSimplified(t).toLowerCase())) hits++;
      }
      // 至少两项对得上才算「同类」：只中一项时基本是「提到过这个词」，
      // 全库 1200+ 例里能捞出几十上百条，对判定没有价值。
      if (hits >= 2) scored.add((c, hits));
    }
    scored.sort((a, b) {
      final byHits = b.$2.compareTo(a.$2);
      // 同分时优先有方剂记录的：那才是可以直接对照的处方。
      if (byHits != 0) return byHits;
      return b.$1.formula.length.compareTo(a.$1.formula.length);
    });
    return scored.take(max).map((e) => e.$1).toList();
  }

  /// 反查一条「命中项」在规则表里的身份：哪些方把它当必选(★)、哪些当参考(Q)。
  ///
  /// [label] 是结果页显示的文本（选项原文，如「手脚冰冷」；扩展症状的中文名，
  /// 如「嗜睡」）。规则表内部用 `qKey + 选项号` 与 `extKey` 标识，故先把文本
  /// 反解回标识——两条映射分别来自 [qOptions] 与 [extSymptoms]。
  ///
  /// 两个列表都为空 = 这条命中项只是「信息」，没有决定任何方剂取舍，
  /// 此时界面明确告知，避免用户误以为每一项都在起作用。
  static (List<String>, List<String>) evidenceOf(String label) {
    final required = <String>[];
    final reference = <String>[];

    String? qk;
    int? optionNo;
    for (final e in qOptions.entries) {
      final i = e.value.indexOf(label);
      if (i >= 0) {
        qk = e.key;
        optionNo = i + 1;
        break;
      }
    }
    String? extKey;
    for (final e in extSymptoms.entries) {
      if (e.value == label) {
        extKey = e.key;
        break;
      }
    }

    for (final rule in allFormulaRules) {
      var isRequired = false;
      var isReference = false;
      if (qk != null && optionNo != null) {
        if (rule.required[qk]?.contains(optionNo) ?? false) isRequired = true;
        if (rule.reference[qk]?.contains(optionNo) ?? false) isReference = true;
      }
      if (extKey != null) {
        if (rule.extRequired.contains(extKey)) isRequired = true;
        if (rule.extReference.contains(extKey)) isReference = true;
      }
      if (isRequired) {
        required.add(rule.name);
      } else if (isReference) {
        reference.add(rule.name);
      }
    }
    return (required, reference);
  }

  /// 点开一条命中项，看它牵动了哪些方。
  void _showEvidence(BuildContext context, String label, ColorScheme cs) {
    final (required, reference) = evidenceOf(label);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(label),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (required.isEmpty && reference.isEmpty)
                const Text('这一项在当前规则表里没有决定任何方剂的取舍，'
                    '它只作为背景信息出现。',
                    style: TextStyle(fontSize: 13, height: 1.7))
              else ...[
                if (required.isNotEmpty) ...[
                  Text('作为「必选」信号（缺此项该方直接出局）',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: cs.primary)),
                  const SizedBox(height: 4),
                  Text(required.join('、'),
                      style: const TextStyle(fontSize: 13, height: 1.7)),
                  const SizedBox(height: 12),
                ],
                if (reference.isNotEmpty) ...[
                  Text('作为「参考」信号（用于排序打分，缺失不影响入选）',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: cs.primary)),
                  const SizedBox(height: 4),
                  Text(reference.join('、'),
                      style: const TextStyle(fontSize: 13, height: 1.7)),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  Widget _pill(BuildContext context, String text, Color color) => Container(
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
    final r = result;
    return ListView(
      controller: scrollController,
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
            _pill(context, '${r.meridian}病', cs.primary),
            const SizedBox(width: 8),
            _pill(context, '依据 ${r.matchedSymptoms.length} 项',
                cs.surfaceContainerHighest),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '「依据 N 项」是本次勾选里落进规则加权表的症状条数，只说明信息够不够，'
          '不是准确率——多勾几项它就会变高，和辨证对错无关。',
          style:
              TextStyle(fontSize: 11, height: 1.6, color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Text(r.pattern,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, height: 1.4)),
        if (r.patternDetail.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(r.patternDetail,
              style:
                  TextStyle(fontSize: 13, height: 1.6, color: cs.onSurfaceVariant)),
        ],
        const SizedBox(height: 16),
        Text('参考方剂',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary)),
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
                    context,
                    MaterialPageRoute(
                        builder: (_) => FormulaDetailScreen(formula: f)),
                  );
                },
              ),
          ],
        ),
        if (r.matchedSymptoms.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('这次结论依据的症状',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary)),
          const SizedBox(height: 4),
          Text('点任一项，看它在规则里决定了哪些方的取舍',
              style:
                  TextStyle(fontSize: 11, height: 1.5, color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in r.matchedSymptoms)
                ActionChip(
                  label: Text(s, style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showEvidence(context, s, cs),
                ),
            ],
          ),
        ],
        if (r.explanation.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('为什么这样辨',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary)),
          const SizedBox(height: 6),
          Text(r.explanation, style: const TextStyle(fontSize: 12, height: 1.7)),
        ],
        const SizedBox(height: 16),
        Text('倪师同类医案',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.bold, color: cs.primary)),
        const SizedBox(height: 4),
        Text('症状对得上两项以上的案例，方剂栏就是倪师当时开的方',
            style:
                TextStyle(fontSize: 11, height: 1.5, color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        FutureBuilder<List<MedicalCase>>(
          future: relatedCases,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return Text('正在检索…',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant));
            }
            final list = snap.data ?? const <MedicalCase>[];
            if (list.isEmpty) {
              return Text(
                '没找到症状相近的医案。这本身也是信息：同类记录缺失，'
                '这个结论只能用伤寒金匮条文核对，没有现成验案可参照。',
                style: TextStyle(
                    fontSize: 12, height: 1.6, color: cs.onSurfaceVariant),
              );
            }
            return Column(
              children: [
                for (final c in list)
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.article_outlined, size: 18),
                    title: Text('#${c.seq} ${c.displayName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12)),
                    subtitle: Text(
                      c.formula.isEmpty
                          ? (c.fourDiagnoses.isEmpty
                              ? '（无方剂记录）'
                              : c.fourDiagnoses)
                          : c.formula,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 16),
                    onTap: () async {
                      final all = await getAllMedicalCases();
                      if (!ctx.mounted) return;
                      await Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) =>
                              MedicalCaseDetailScreen(c: c, allCases: all),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onAskAi,
            icon: const Icon(Icons.forum_outlined),
            label: const Text('带着这个结果问倪师 AI'),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '本结果由本地规则引擎按倪师讲义规则生成，仅供学习参考，不构成诊疗建议。'
          '结论偏倚可能来自勾选项不全或有相互矛盾的描述，症状复杂请用聊天式问诊逐项确认。',
          style: TextStyle(fontSize: 11, height: 1.6, color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
