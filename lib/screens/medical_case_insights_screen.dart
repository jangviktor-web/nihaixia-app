import 'package:flutter/material.dart';

import '../data/medical_case_data.dart';
import '../data/formula_repository.dart';
import 'formula_detail_screen.dart';

/// 医案数据洞察：常用方剂 TOP / 高频诊断 TOP / 覆盖率摘要。
/// 统计基于批1的 formulaNames / herbNames（lazy 缓存，全量一次性计算）。
/// 方剂条目点按跳方剂详情；诊断条目点按回医案库并带入搜索。
class MedicalCaseInsightsScreen extends StatelessWidget {
  final List<MedicalCase> all;
  MedicalCaseInsightsScreen({super.key, required this.all});

  static const _topN = 15;

  late final MedicalCaseInsightStats _stats = computeMedicalCaseInsights(all);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(title: const Text('医案数据洞察')),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _summaryCard(context, stats),
          const SizedBox(height: 20),
          Text(
            '常用方剂 TOP ${stats.formulas.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 4),
          if (stats.formulas.isEmpty)
            _empty(context)
          else
            for (final (i, f) in stats.formulas.indexed) ...[
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: SizedBox(
                  width: 34,
                  child: Text(
                    '${i + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ),
                title: Text(f.name, style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  '${f.count} 例 · ${f.pct.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () {
                  final formula = FormulaRepository.getByName(f.name);
                  if (formula != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FormulaDetailScreen(formula: formula),
                      ),
                    );
                  }
                },
              ),
              const Divider(height: 1),
            ],
          const SizedBox(height: 20),
          Text(
            '高频诊断 TOP ${stats.diagnoses.length}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
          const SizedBox(height: 4),
          if (stats.diagnoses.isEmpty)
            _empty(context)
          else
            for (final (i, d) in stats.diagnoses.indexed) ...[
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: SizedBox(
                  width: 34,
                  child: Text(
                    '${i + 1}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ),
                title: Text(d.name, style: const TextStyle(fontSize: 14)),
                subtitle: Text(
                  '${d.count} 例 · ${d.pct.toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: const Icon(Icons.search, size: 18),
                onTap: () => Navigator.pop(context, d.name),
              ),
              const Divider(height: 1),
            ],
        ],
      ),
    );
  }

  Widget _summaryCard(BuildContext context, MedicalCaseInsightStats s) {
    final cs = Theme.of(context).colorScheme;
    Widget metric(String label, String value) => Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        );
    final coverage =
        s.total == 0 ? '0%' : '${(s.withFormula * 100 / s.total).round()}%';
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            metric('总例数', '${s.total}'),
            metric('有方剂', '${s.withFormula}'),
            metric('有药材', '${s.withHerb}'),
            metric('方剂覆盖率', coverage),
          ],
        ),
      ),
    );
  }

  Widget _empty(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          '暂无数据',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
}

/// 统计结果：摘要 + 两个 TOP 列表（count / pct 占全量比例）。
class MedicalCaseInsightStats {
  final int total;
  final int withFormula;
  final int withHerb;
  final List<({String name, int count, double pct})> formulas;
  final List<({String name, int count, double pct})> diagnoses;

  const MedicalCaseInsightStats({
    required this.total,
    required this.withFormula,
    required this.withHerb,
    required this.formulas,
    required this.diagnoses,
  });
}

/// 全量统计：方剂/药材覆盖 + 方剂频次 + 诊断频次（按频次降序，同频按名称升序）。
MedicalCaseInsightStats computeMedicalCaseInsights(List<MedicalCase> all) {
  final formulaFreq = <String, int>{};
  final diagFreq = <String, int>{};
  var withFormula = 0;
  var withHerb = 0;
  for (final c in all) {
    final fn = c.formulaNames;
    if (fn.isNotEmpty) withFormula++;
    if (c.herbNames.isNotEmpty) withHerb++;
    for (final n in fn) {
      formulaFreq[n] = (formulaFreq[n] ?? 0) + 1;
    }
    final d = c.displayName;
    if (d.isNotEmpty && d != '（未命名）') {
      diagFreq[d] = (diagFreq[d] ?? 0) + 1;
    }
  }
  final total = all.length;

  List<({String name, int count, double pct})> top(
      Map<String, int> freq, int n) {
    final entries = freq.entries.toList()
      ..sort((a, b) {
        final byCount = b.value.compareTo(a.value);
        return byCount != 0 ? byCount : a.key.compareTo(b.key);
      });
    return entries.take(n).map((e) => (
          name: e.key,
          count: e.value,
          pct: total == 0 ? 0.0 : e.value * 100 / total,
        )).toList();
  }

  return MedicalCaseInsightStats(
    total: total,
    withFormula: withFormula,
    withHerb: withHerb,
    formulas: top(formulaFreq, MedicalCaseInsightsScreen._topN),
    diagnoses: top(diagFreq, MedicalCaseInsightsScreen._topN),
  );
}
