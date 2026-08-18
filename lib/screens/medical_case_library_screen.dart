import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:share_plus/share_plus.dart';

import '../data/medical_case_data.dart';
import '../data/formula_repository.dart';
import '../data/herb_repository.dart';
import '../data/chinese_convert.dart';
import '../data/database_helper.dart';
import 'formula_detail_screen.dart';
import 'herb_detail_screen.dart';
import 'medical_case_insights_screen.dart';

/// 倪师医案库（1257 例）可搜索浏览。
/// 运行时解析 assets/medical_cases/cases_table.md，按诊断/方剂/结果/观点全文检索
/// （简繁归一：繁体原文可被简体关键词命中）。支持 300ms 防抖、关键词高亮、
/// 年份/治法/收藏/最近浏览筛选、方剂数/药数徽标、数据洞察入口。
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
  static const _recentLimit = 20;

  late Future<List<MedicalCase>> _future;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  List<MedicalCase> _all = [];
  List<String> _years = [];
  List<String> _methods = [];
  String? _year; // null = 全部
  String? _method; // null = 全部
  String? _view; // null=全部 | 'fav'=收藏 | 'recent'=最近浏览
  Set<int> _favSeqs = {};
  List<int> _recentSeqs = [];

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
    final md =
        await rootBundle.loadString('assets/medical_cases/cases_table.md');
    _all = parseMedicalCaseTable(md);
    _years = _computeYears(_all);
    _methods = _computeMethods(_all);
    // 异步刷新收藏/最近浏览（不阻塞列表渲染）
    _refreshFavRecent();
    return _all;
  }

  Future<void> _refreshFavRecent() async {
    final db = DatabaseHelper.instance;
    final favs = await db.getBookmarkedMedicalCaseSeqs();
    final recents = await db.getRecentMedicalCaseSeqs(limit: _recentLimit);
    if (!mounted) return;
    setState(() {
      _favSeqs = favs.toSet();
      _recentSeqs = recents;
    });
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

  /// 搜索 + 年份 + 治法 + 视图（收藏/最近浏览）AND 组合；最近浏览按时间倒序。
  List<MedicalCase> get _filtered {
    final q = _query;
    final year = _year;
    final method = _method;
    final view = _view;
    final list = _all.where((c) {
      if (q.isNotEmpty && !c.matches(q)) return false;
      if (year != null && _yearOf(c.date) != year) return false;
      if (method != null && c.method.trim() != method) return false;
      if (view == 'fav' && !_favSeqs.contains(c.seq)) return false;
      if (view == 'recent' && !_recentSeqs.contains(c.seq)) return false;
      return true;
    }).toList();
    if (view == 'recent') {
      final order = {
        for (var i = 0; i < _recentSeqs.length; i++) _recentSeqs[i]: i,
      };
      list.sort(
          (a, b) => (order[a.seq] ?? 0).compareTo(order[b.seq] ?? 0));
    }
    return list;
  }

  Future<void> _openInsights() async {
    if (_all.isEmpty) return;
    final diagnosis = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => MedicalCaseInsightsScreen(all: _all)),
    );
    if (diagnosis == null || diagnosis.isEmpty || !mounted) return;
    _debounce?.cancel();
    _searchCtrl.text = diagnosis;
    setState(() => _query = diagnosis);
  }

  Future<void> _clearRecent() async {
    await DatabaseHelper.instance.clearMedicalCaseRecent();
    await _refreshFavRecent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('倪师医案库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: '数据统计',
            onPressed: _openInsights,
          ),
        ],
      ),
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
                    _chipRow(
                      label: '视图',
                      options: const ['收藏', '最近浏览'],
                      selected: _view,
                      onChanged: (v) => setState(() => _view = v),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            '共 ${filtered.length} / ${_all.length} 例',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_view == 'recent')
                      TextButton(
                        onPressed: _clearRecent,
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        child: const Text('清空最近',
                            style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          _view == 'fav'
                              ? '暂无收藏医案\n在医案详情页点击书签收藏'
                              : _view == 'recent'
                                  ? '暂无最近浏览'
                                  : '无匹配医案',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.separated(
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
                                  style:
                                      const TextStyle(fontWeight: FontWeight.bold),
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
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
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MedicalCaseDetailScreen(
                                      c: c,
                                      allCases: _all,
                                    ),
                                  ),
                                );
                                // 返回后刷新收藏/最近浏览状态
                                if (mounted) await _refreshFavRecent();
                              },
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

/// 医案详情：12 字段逐条展示 + 收藏/复制/分享 + 相关医案。
class MedicalCaseDetailScreen extends StatefulWidget {
  final MedicalCase c;
  final List<MedicalCase>? allCases;
  const MedicalCaseDetailScreen({super.key, required this.c, this.allCases});

  @override
  State<MedicalCaseDetailScreen> createState() =>
      _MedicalCaseDetailScreenState();
}

class _MedicalCaseDetailScreenState extends State<MedicalCaseDetailScreen> {
  bool _isBookmarked = false;

  MedicalCase get c => widget.c;

  @override
  void initState() {
    super.initState();
    _recordRecent();
    _checkBookmark();
  }

  Future<void> _recordRecent() async {
    try {
      await DatabaseHelper.instance.upsertMedicalCaseRecent(c.seq);
    } catch (_) {
      // 记录失败不阻断阅读
    }
  }

  Future<void> _checkBookmark() async {
    final ok = await DatabaseHelper.instance.isMedicalCaseBookmarked(c.seq);
    if (mounted) setState(() => _isBookmarked = ok);
  }

  Future<void> _toggleBookmark() async {
    final next = !_isBookmarked;
    await DatabaseHelper.instance.setMedicalCaseBookmarked(c.seq, next);
    if (!mounted) return;
    setState(() => _isBookmarked = next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(next ? '已收藏医案 #${c.seq}' : '已取消收藏'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: c.toShareText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('医案文本已复制'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _shareText() async {
    await Share.share(c.toShareText());
  }

  /// 相关医案：委托 medical_case_data.findRelatedCases（同方剂优先，回退同诊断）。
  List<MedicalCase> get _related =>
      findRelatedCases(widget.c, widget.allCases ?? const [], max: 6);

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

    final children = <Widget>[];
    for (final (label, value) in rows) {
      if (value.isEmpty) continue;
      children.add(
        Padding(
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
        ),
      );
    }

    final related = _related;
    if (related.isNotEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '相关医案',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: cs.primary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 112,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: related.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) =>
                      _relatedCard(context, related[index]),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('#${c.seq}  ${c.displayName}'),
        actions: [
          IconButton(
            icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
            tooltip: _isBookmarked ? '取消收藏' : '收藏医案',
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '复制医案文本',
            onPressed: _copyText,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '分享医案',
            onPressed: _shareText,
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(14),
        itemCount: children.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) => children[index],
      ),
    );
  }

  Widget _relatedCard(BuildContext context, MedicalCase other) {
    final cs = Theme.of(context).colorScheme;
    final shared =
        c.formulaNames.where((n) => other.formulaNames.contains(n)).toList();
    return SizedBox(
      width: 210,
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MedicalCaseDetailScreen(
                  c: other,
                  allCases: widget.allCases,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#${other.seq}  ${other.displayName}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                if (shared.isNotEmpty)
                  Text(
                    '共方：${shared.join('、')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: cs.primary),
                  )
                else
                  Text(
                    '同诊断',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ),
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
