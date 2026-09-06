import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../widgets/state_view.dart';

import '../data/medical_case_data.dart';
import '../data/formula_repository.dart';
import '../data/herb_repository.dart';
import 'formula_detail_screen.dart';

/// 医案数据洞察：常用方剂 TOP / 高频诊断 TOP / 覆盖率摘要。
/// 统计基于批1的 formulaNames / herbNames。全量提取较慢（~3.4s），
/// 故在 [compute] isolate 中异步计算：进页先 loading，算完再渲染，不卡主线程。
/// 方剂条目点按跳方剂详情；诊断条目点按回医案库并带入搜索。
class MedicalCaseInsightsScreen extends StatefulWidget {
  final List<MedicalCase> all;
  const MedicalCaseInsightsScreen({super.key, required this.all});

  @override
  State<MedicalCaseInsightsScreen> createState() =>
      _MedicalCaseInsightsScreenState();
}

class _MedicalCaseInsightsScreenState extends State<MedicalCaseInsightsScreen> {
  static const _topN = 15;

  MedicalCaseInsightStats? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    // 候选名单在主 isolate 取出（仓库已加载），连同数据传给 isolate 纯函数，
    // isolate 内不依赖静态仓库。
    final all = widget.all;
    final fc = FormulaRepository.getAll().map((f) => f.name).toList();
    final hc = <String>{
      ...HerbRepository.getAll().map((h) => h.name),
      ...HerbRepository.aliasNames,
    }.toList();
    final stats = await compute(_computeInsightsJob, (all, fc, hc));
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  /// isolate 入口：compute 需要单位置参数的纯函数，这里把 record 解包后转调。
  static MedicalCaseInsightStats _computeInsightsJob(
    (List<MedicalCase>, List<String>, List<String>) job,
  ) {
    final (all, fc, hc) = job;
    return computeMedicalCaseInsights(
      all,
      formulaCandidates: fc,
      herbCandidates: hc,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stats = _stats;
    return Scaffold(
      appBar: AppBar(title: const Text('医案数据洞察')),
      body: _loading || stats == null
          ? const Center(child: StateView.loading())
          : ListView(
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
                  _empty()
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
                      title:
                          Text(f.name, style: const TextStyle(fontSize: 14)),
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
                              builder: (_) =>
                                  FormulaDetailScreen(formula: formula),
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
                  _empty()
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

  Widget _empty() => const StateView.empty(title: '暂无数据', fullScreen: false);
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

/// 全量统计纯函数（可测试）：方剂/药材覆盖 + 方剂频次 + 诊断频次
/// （按频次降序，同频按名称升序）。
///
/// 主 isolate 调用可不传候选（走 [MedicalCase.formulaNames]/[herbNames]，
/// 依赖已加载的仓库）；isolate 内调用必须传 [formulaCandidates]/[herbCandidates]，
/// 以纯提取替代静态仓库访问。
MedicalCaseInsightStats computeMedicalCaseInsights(
  List<MedicalCase> all, {
  List<String>? formulaCandidates,
  List<String>? herbCandidates,
}) {
  final useRepo = formulaCandidates == null || herbCandidates == null;
  final formulaFreq = <String, int>{};
  final diagFreq = <String, int>{};
  var withFormula = 0;
  var withHerb = 0;
  for (final c in all) {
    List<String> fn;
    bool hasHerb;
    if (useRepo) {
      fn = c.formulaNames;
      hasHerb = c.herbNames.isNotEmpty;
    } else {
      fn = extractKnownNames(c.formula, formulaCandidates, resolve: (c) => c);
      hasHerb = extractKnownNames(c.formula, herbCandidates, resolve: (c) => c)
          .isNotEmpty;
    }
    if (fn.isNotEmpty) withFormula++;
    if (hasHerb) withHerb++;
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
    formulas: top(formulaFreq, _MedicalCaseInsightsScreenState._topN),
    diagnoses: top(diagFreq, _MedicalCaseInsightsScreenState._topN),
  );
}
