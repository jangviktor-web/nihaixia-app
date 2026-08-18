import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';

import '../data/medical_case_data.dart';
import '../data/formula_repository.dart';
import '../data/herb_repository.dart';
import '../data/chinese_convert.dart';
import 'formula_detail_screen.dart';
import 'herb_detail_screen.dart';

/// 倪师医案库（1257 例）可搜索浏览。
/// 运行时解析 assets/medical_cases/cases_table.md，按诊断/方剂/结果/观点全文检索
/// （简繁归一：繁体原文可被简体关键词命中）。支持 300ms 防抖、关键词高亮、
/// 年份/治法筛选、方剂数/药数徽标。
class MedicalCaseLibraryScreen extends StatefulWidget {
  const MedicalCaseLibraryScreen({super.key});

  @override
  State<MedicalCaseLibraryScreen> createState() =>
      _MedicalCaseLibraryScreenState();
}

class _MedicalCaseLibraryScreenState extends State<MedicalCaseLibraryScreen> {
  static const _debounceDelay = Duration(milliseconds: 300);
  static const _maxYearChips = 8;
  static const _maxMethodChips = 8;

  late Future<List<MedicalCase>> _future;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  List<MedicalCase> _all = [];
  List<String> _years = [];
  List<String> _methods = [];
  String? _year; // null = 全部
  String? _method; // null = 全部

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<MedicalCase>> _load() async {
    final md = await rootBundle.loadString('assets/medical_cases/cases_table.md');
    _all = parseMedicalCaseTable(md);
    _years = _computeYears(_all);
    _methods = _computeMethods(_all);
    return _all;
  }

  void _onQueryChanged(String v) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      if (!mounted) return;
      setState(() => _query = v.trim());
    });
  }

  void _clearQuery() {
    _debounce?.cancel();
    _searchCtrl.clear();
    setState(() => _query = '');
  }

  /// 年份候选：date 字段提取年份，去重降序，取最近若干年。
  List<String> _computeYears(List<MedicalCase> all) {
    final years = all
        .map((c) => _yearOf(c.date))
        .whereType<String>()
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return years.take(_maxYearChips).toList();
  }

  /// 治法候选：治法字段去重，按出现频次降序取前若干标签。
  List<String> _computeMethods(List<MedicalCase> all) {
    final freq = <String, int>{};
    for (final c in all) {
      final m = c.method.trim();
      if (m.isEmpty) continue;
      freq[m] = (freq[m] ?? 0) + 1;
    }
    final entries = freq.entries.toList()
      ..sort((a, b) {
        final byFreq = b.value.compareTo(a.value);
        return byFreq != 0 ? byFreq : a.key.compareTo(b.key);
      });
    return entries.take(_maxMethodChips).map((e) => e.key).toList();
  }

  String? _yearOf(String date) {
    final m = RegExp(r'(19|20)\d{2}').firstMatch(date);
    return m?.group(0);
  }

  /// 搜索与筛选 AND 组合。
  List<MedicalCase> get _filtered {
    final q = _query;
    final year = _year;
    final method = _method;
    return _all.where((c) {
      if (q.isNotEmpty && !c.matches(q)) return false;
      if (year != null && _yearOf(c.date) != year) return false;
      if (method != null && c.method.trim() != method) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('倪师医案库')),
      body: FutureBuilder<List<MedicalCase>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final filtered = _filtered;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: '搜索诊断 / 方剂 / 结果 / 倪师观点…',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: _clearQuery,
                          )
                        : null,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _onQueryChanged,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _chipRow(
                      label: '年份',
                      options: _years,
                      selected: _year,
                      onChanged: (v) => setState(() => _year = v),
                    ),
                    if (_methods.isNotEmpty)
                      _chipRow(
                        label: '治法',
                        options: _methods,
                        selected: _method,
                        onChanged: (v) => setState(() => _method = v),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '共 ${filtered.length} / ${_all.length} 例',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return Card(
                      margin: EdgeInsets.zero,
                      child: ListTile(
                        title: RichText(
                          text: TextSpan(
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            children: [
                              TextSpan(text: '#${c.seq}  '),
                              ..._highlighted(
                                c.displayName,
                                _query,
                                const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (c.patient.isNotEmpty)
                              RichText(
                                text: TextSpan(
                                  children: _highlighted(
                                    c.patient,
                                    _query,
                                    const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            if (c.formulaNames.isNotEmpty ||
                                c.herbNames.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '${c.formulaNames.length} 方 · ${c.herbNames.length} 药',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ),
                            if (c.formula.isNotEmpty)
                              RichText(
                                text: TextSpan(
                                  children: _highlighted(
                                    '方：${_clip(c.formula, 36)}',
                                    _query,
                                    const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                            if (c.result.isNotEmpty)
                              RichText(
                                text: TextSpan(
                                  children: _highlighted(
                                    '效：${_clip(c.result, 36)}',
                                    _query,
                                    const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MedicalCaseDetailScreen(c: c),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 横向 FilterChip 行（含「全部」）。
  Widget _chipRow({
    required String label,
    required List<String> options,
    required String? selected,
    required ValueChanged<String?> onChanged,
  }) {
    final labelColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('全部', selected == null, () => onChanged(null)),
                  for (final o in options) ...[
                    const SizedBox(width: 6),
                    _chip(o, selected == o, () => onChanged(o)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  /// 关键词高亮：先 toSimplified 归一对齐，逐字符找命中区间，高亮落回原文位置。
  List<InlineSpan> _highlighted(String text, String query, TextStyle base) {
    final cs = Theme.of(context).colorScheme;
    final hl = base.copyWith(color: cs.primary, fontWeight: FontWeight.bold);
    if (query.isEmpty || text.isEmpty) {
      return [TextSpan(text: text, style: base)];
    }
    final normText = toSimplified(text).toLowerCase();
    final normQuery = toSimplified(query).toLowerCase();
    if (normQuery.isEmpty) return [TextSpan(text: text, style: base)];
    final mask = List<bool>.filled(text.length, false);
    var idx = 0;
    while (true) {
      final start = normText.indexOf(normQuery, idx);
      if (start < 0) break;
      final end = start + normQuery.length;
      for (var k = start; k < end && k < mask.length; k++) {
        mask[k] = true;
      }
      idx = end;
    }
    final spans = <InlineSpan>[];
    var i = 0;
    while (i < text.length) {
      if (!mask[i]) {
        var j = i;
        while (j < text.length && !mask[j]) {
          j++;
        }
        spans.add(TextSpan(text: text.substring(i, j), style: base));
        i = j;
      } else {
        var j = i;
        while (j < text.length && mask[j]) {
          j++;
        }
        spans.add(TextSpan(text: text.substring(i, j), style: hl));
        i = j;
      }
    }
    return spans;
  }

  String _clip(String s, int n) => s.length > n ? '${s.substring(0, n)}…' : s;
}

/// 单例医案详情：12 字段逐条展示。
class MedicalCaseDetailScreen extends StatelessWidget {
  final MedicalCase c;
  const MedicalCaseDetailScreen({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rows = <(String, String)>[
      ('日期', c.date),
      ('患者', c.patient),
      ('主要诊断', c.diagnosis),
      ('中医病机', c.mechanism),
      ('西医背景', c.western),
      ('方剂组成', c.formula),
      ('针灸方案', c.acupuncture),
      ('治法原则', c.method),
      ('疗程结果', c.result),
      ('生活医嘱', c.advice),
      ('倪师观点', c.view),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('#${c.seq}  ${c.displayName}')),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final (label, value) = rows[index];
          if (value.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 4),
                label == '方剂组成'
                    ? _FormulaRichText(formula: value)
                    : Text(
                        value,
                        style: const TextStyle(fontSize: 14, height: 1.6),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 方剂组成字段富文本：把正文中的已知方剂名/药材名渲染为可点链接
/// （方剂 → FormulaDetailScreen；药材 → HerbDetailScreen）。
/// 先 toSimplified 归一匹配，点击目标用仓库正名解析，跳转不受繁体原文影响；
/// 文本按原文渲染，实现医案↔方剂/药材交叉跳转。
class _FormulaRichText extends StatelessWidget {
  final String formula;
  const _FormulaRichText({required this.formula});

  @override
  Widget build(BuildContext context) {
    final base = DefaultTextStyle.of(context).style;
    final cs = Theme.of(context).colorScheme;
    final linkStyle = TextStyle(
      color: cs.primary,
      decoration: TextDecoration.underline,
      fontSize: 14,
      height: 1.6,
    );
    final spans = _buildSpans(context, formula, base, linkStyle);
    return RichText(
      text: TextSpan(
        style: base.copyWith(fontSize: 14, height: 1.6),
        children: spans,
      ),
    );
  }

  /// 合并候选（方剂 + 药材别名），长度降序、同长方剂优先，非重叠扫描原文。
  List<InlineSpan> _buildSpans(
    BuildContext context,
    String text,
    TextStyle base,
    TextStyle link,
  ) {
    final candidates = <({String name, bool isFormula})>[
      for (final f in FormulaRepository.getAll())
        if (f.name.length >= 2) (name: f.name, isFormula: true),
      for (final h in HerbRepository.getAll())
        if (h.name.length >= 2) (name: h.name, isFormula: false),
      for (final a in HerbRepository.aliasNames)
        if (a.length >= 2) (name: a, isFormula: false),
    ]..sort((a, b) {
        final byLen = b.name.length.compareTo(a.name.length);
        if (byLen != 0) return byLen;
        return (a.isFormula ? 0 : 1).compareTo(b.isFormula ? 0 : 1);
      });

    final norm = toSimplified(text);
    final used = List<bool>.filled(text.length, false);
    final hits = <({int start, int end, String name, bool isFormula})>[];
    for (final cand in candidates) {
      final name = toSimplified(cand.name);
      if (name.length > norm.length) continue;
      var idx = 0;
      while (true) {
        final start = norm.indexOf(name, idx);
        if (start < 0) break;
        final end = start + name.length;
        var overlapped = false;
        for (var k = start; k < end; k++) {
          if (used[k]) {
            overlapped = true;
            break;
          }
        }
        if (!overlapped) {
          // 药材须精确+别名命中（不做模糊兜底，避免柴胡错跳含柴胡的方剂）
          final ok = cand.isFormula ||
              HerbRepository.getExactByName(cand.name) != null;
          if (ok) {
            hits.add((
              start: start,
              end: end,
              name: cand.name,
              isFormula: cand.isFormula,
            ));
            for (var k = start; k < end; k++) {
              used[k] = true;
            }
          }
        }
        idx = end;
      }
    }
    hits.sort((a, b) => a.start.compareTo(b.start));

    final spans = <InlineSpan>[];
    var i = 0;
    for (final hit in hits) {
      if (hit.start > i) {
        spans.add(TextSpan(text: text.substring(i, hit.start)));
      }
      final label = text.substring(hit.start, hit.end);
      spans.add(
        TextSpan(
          text: label,
          style: link,
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (hit.isFormula) {
                final f = FormulaRepository.getByName(hit.name);
                if (f != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FormulaDetailScreen(formula: f),
                    ),
                  );
                }
              } else {
                final h = HerbRepository.getExactByName(hit.name);
                if (h != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HerbDetailScreen(herb: h),
                    ),
                  );
                }
              }
            },
        ),
      );
      i = hit.end;
    }
    if (i < text.length) {
      spans.add(TextSpan(text: text.substring(i)));
    }
    return spans;
  }
}
