import 'dart:async';

import 'package:flutter/material.dart';
import '../widgets/state_view.dart';
import 'package:flutter/services.dart';

import '../data/database_helper.dart';
import '../data/formula_repository.dart';
import '../data/herb_repository.dart';
import '../data/medical_case_data.dart';
import '../widgets/medical_case_filter_bar.dart';
import '../widgets/medical_case_list_card.dart';
import 'medical_case_detail_screen.dart';
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
  static const _maxFormulaChips = 12;
  static const _maxDiseaseChips = 12;
  static const _recentLimit = 20;

  late Future<List<MedicalCase>> _future;
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  List<MedicalCase> _all = [];
  List<String> _years = [];
  List<String> _formulas = []; // 治法栏：经方方剂名分类（含「其他治法」哨兵）
  List<String> _diseases = []; // 疾病栏：西医病名分类（含「其他疾病」哨兵）
  String? _year; // null = 全部
  String? _formula; // null = 全部（具体经方方剂名 / 其他治法）
  String? _disease; // null = 全部（具体西医病名 / 其他疾病）
  String? _view; // null=全部 | 'fav'=收藏 | 'recent'=最近浏览
  List<int> _favSeqs = []; // 收藏 seq，按收藏时间倒序
  List<int> _recentSeqs = []; // 最近浏览 seq，按浏览时间倒序

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
    // 先保证方剂/药材库已加载（不依赖 main 启动时的 await 顺序，消除与
    // late final 缓存的 race——若 FormulaRepository 仍空时 formulaNames
    // 被首次访问并永久缓存为 []，将导致治法栏 freqF 错算、filter 0 结果）。
    await FormulaRepository.load();
    await HerbRepository.load();
    final md =
        await rootBundle.loadString('assets/medical_cases/cases_table.md');
    _all = parseMedicalCaseTable(md);
    _years = _computeYears(_all);
    // 同步累计治法(方剂名)/疾病(西医病名)分类频次：访问 c.formulaNames /
    // c.diseaseNames 同时填充全局 memo 缓存（保证详情秒开），并让
    // FutureBuilder 首帧即有完整筛选行数据，避免异步预热导致的两栏不显示。
    _computeCategories();
    // 异步刷新收藏/最近浏览（不阻塞列表渲染）
    _refreshFavRecent();
    return _all;
  }

  /// 同步累计治法(经方方剂名)/疾病(西医病名)分类频次，按频次降序取前若干，
  /// 末位追加「其他治法」「其他疾病」哨兵（对应无方剂名/无西医病名的医案）。
  /// 访问 c.formulaNames / c.diseaseNames 会同时填充全局 memo 缓存，保证详情秒开。
  void _computeCategories() {
    if (_all.isEmpty) return;
    final freqF = <String, int>{};
    final freqD = <String, int>{};
    var hasEmptyF = false;
    var hasEmptyD = false;
    for (final c in _all) {
      final fn = c.formulaNames; // 累计 + 预热 memo
      if (fn.isEmpty) {
        hasEmptyF = true;
      } else {
        for (final f in fn) {
          freqF[f] = (freqF[f] ?? 0) + 1;
        }
      }
      final dn = c.diseaseNames; // 累计 + 预热 memo
      if (dn.isEmpty) {
        hasEmptyD = true;
      } else {
        for (final d in dn) {
          freqD[d] = (freqD[d] ?? 0) + 1;
        }
      }
    }
    _formulas = _topChips(
      freqF,
      _maxFormulaChips,
      hasEmptyF ? const [kOtherMethod] : const [],
    );
    _diseases = _topChips(
      freqD,
      _maxDiseaseChips,
      hasEmptyD ? const [kOtherDisease] : const [],
    );
  }

  /// 频次降序取前 [max] 个分类，末位追加哨兵（[extra]，如有对应空桶）。
  List<String> _topChips(
    Map<String, int> freq,
    int max,
    List<String> extra,
  ) {
    final entries = freq.entries.toList()
      ..sort((a, b) {
        final byFreq = b.value.compareTo(a.value);
        return byFreq != 0 ? byFreq : a.key.compareTo(b.key);
      });
    return [...entries.take(max).map((e) => e.key), ...extra];
  }

  Future<void> _refreshFavRecent() async {
    final db = DatabaseHelper.instance;
    final favs = await db.getBookmarkedMedicalCaseSeqs();
    final recents = await db.getRecentMedicalCaseSeqs(limit: _recentLimit);
    if (!mounted) return;
    setState(() {
      _favSeqs = favs;
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

  String? _yearOf(String date) {
    final m = RegExp(r'(19|20)\d{2}').firstMatch(date);
    return m?.group(0);
  }

  /// 搜索 + 年份 + 治法(方剂名) + 疾病(西医病名) + 视图（收藏/最近浏览）AND 组合；
  /// 收藏按收藏时间倒序、最近浏览按浏览时间倒序（委托 filterMedicalCases）。
  List<MedicalCase> get _filtered => filterMedicalCases(
        _all,
        query: _query,
        year: _year,
        formula: _formula,
        disease: _disease,
        view: _view,
        favSeqs: _favSeqs,
        recentSeqs: _recentSeqs,
        yearOf: _yearOf,
      );

  Future<void> _openInsights() async {
    if (_all.isEmpty) return;
    final diagnosis = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => MedicalCaseInsightsScreen(all: _all)),
    );
    if (diagnosis == null || diagnosis.isEmpty || !mounted) return;
    // 回填搜索，并清空筛选避免回填后意外 0 结果
    _debounce?.cancel();
    _searchCtrl.text = diagnosis;
    setState(() {
      _query = diagnosis;
      _year = null;
      _formula = null;
      _disease = null;
      _view = null;
    });
  }

  Future<void> _clearRecent() async {
    await DatabaseHelper.instance.clearMedicalCaseRecent();
    await _refreshFavRecent();
  }

  Future<void> _openDetail(MedicalCase c) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicalCaseDetailScreen(c: c, allCases: _all),
      ),
    );
    // 返回后刷新收藏/最近浏览状态
    if (mounted) await _refreshFavRecent();
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
            return const Center(child: StateView.loading());
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
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _onQueryChanged,
                ),
              ),
              MedicalCaseFilterBar(
                years: _years,
                formulas: _formulas,
                diseases: _diseases,
                year: _year,
                formula: _formula,
                disease: _disease,
                view: _view,
                onYearChanged: (v) => setState(() => _year = v),
                onFormulaChanged: (v) => setState(() => _formula = v),
                onDiseaseChanged: (v) => setState(() => _disease = v),
                onViewChanged: (v) => setState(() => _view = v),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                child: Row(
                  children: [
                    Expanded(
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
                          return MedicalCaseListCard(
                            c: c,
                            query: _query,
                            onTap: () => _openDetail(c),
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
}
