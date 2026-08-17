import 'dart:async';
import 'package:flutter/material.dart';
import '../data/acupuncture_repository.dart';
import '../data/acupoint_repository.dart';
import '../data/formula_repository.dart';
import '../data/herb_repository.dart';
import '../data/search_history_repository.dart';
import '../models/acupuncture.dart';
import '../models/acupoint_detail.dart';
import '../models/formula.dart';
import '../models/herb.dart';
import '../widgets/highlighted_text.dart';
import 'acupoint_detail_screen.dart';
import 'formula_detail_screen.dart';
import 'herb_detail_screen.dart';

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _formulaIndicationController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounceTimer;

  // 搜索状态
  String _currentQuery = '';
  _AggregatedResults _results = _AggregatedResults.empty();
  bool _isFocused = false;

  // 搜索历史
  List<String> _searchHistory = [];

  // 联想
  List<String> _suggestions = [];

  // 展开状态
  final Map<String, bool> _expandedSections = {};

  // 筛选面板
  bool _showFilters = false;
  String _filterSection = 'herb'; // 'herb' or 'formula'

  // 本草筛选
  String _selectedHerbNature = '全部';
  String _selectedHerbFlavor = '全部';
  String _selectedHerbMeridian = '全部';
  String _selectedHerbCategory = '全部';

  // 方剂筛选
  String _selectedFormulaMeridian = '全部';
  String _selectedFormulaCategory = '全部';
  String _formulaIndicationQuery = '';

  // 筛选选项
  static const _natures = ['全部', '寒', '凉', '平', '温', '热'];
  static const _flavors = ['全部', '酸', '苦', '甘', '辛', '咸'];
  static const _meridians = ['全部', '肺', '心', '肝', '脾', '肾', '胃', '胆', '大肠', '小肠', '膀胱', '三焦'];
  static const _formulaMeridians = ['全部', '太阳', '阳明', '少阳', '太阴', '少阴', '厥阴'];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _loadHistory();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _formulaIndicationController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _isFocused = _focusNode.hasFocus);
    if (_focusNode.hasFocus && _currentQuery.isEmpty) {
      _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    final history = await SearchHistoryRepository.getRecentSearches();
    if (mounted) setState(() => _searchHistory = history);
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _executeSearch(query);
    });
    // 实时更新联想
    _updateSuggestions(query);
  }

  void _updateSuggestions(String query) {
    if (query.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    final herbNames = HerbRepository.getAll()
        .where((h) => h.name.contains(query))
        .map((h) => h.name)
        .take(4);
    final formulaNames = FormulaRepository.getAll()
        .where((f) => f.name.contains(query))
        .map((f) => f.name)
        .take(4);
    setState(() => _suggestions = [...herbNames, ...formulaNames].take(8).toList());
  }

  void _executeSearch(String query) {
    setState(() {
      _currentQuery = query;
      _suggestions = [];
      _results = _performSearch(query);
      _expandedSections.clear();
    });
  }

  void _onSubmitted(String query) {
    if (query.trim().isNotEmpty) {
      SearchHistoryRepository.addSearch(query);
      _loadHistory();
    }
  }

  _AggregatedResults _performSearch(String query) {
    if (query.isEmpty) return _AggregatedResults.empty();

    var formulas = FormulaRepository.search(query);
    var herbs = HerbRepository.search(query);
    var acupunctureEntries = AcupunctureRepository.search(query);
    var penetrations = AcupunctureRepository.searchPenetrations(query);
    var acupointDetails = AcupointRepository.search(query);

    // 本草筛选（AND逻辑）
    if (_selectedHerbNature != '全部') {
      herbs = herbs.where((h) => h.natureCategory == _selectedHerbNature).toList();
    }
    if (_selectedHerbFlavor != '全部') {
      herbs = herbs.where((h) => h.flavor.contains(_selectedHerbFlavor)).toList();
    }
    if (_selectedHerbMeridian != '全部') {
      herbs = herbs.where((h) => h.meridians.contains(_selectedHerbMeridian)).toList();
    }
    if (_selectedHerbCategory != '全部') {
      herbs = herbs.where((h) => h.category == _selectedHerbCategory).toList();
    }

    // 方剂筛选（AND逻辑）
    if (_selectedFormulaMeridian != '全部') {
      formulas = formulas.where((f) => f.meridian.contains(_selectedFormulaMeridian)).toList();
    }
    if (_selectedFormulaCategory != '全部') {
      formulas = formulas.where((f) => f.category == _selectedFormulaCategory).toList();
    }
    if (_formulaIndicationQuery.isNotEmpty) {
      final iq = _formulaIndicationQuery.toLowerCase();
      formulas = formulas.where((f) => f.indication.toLowerCase().contains(iq)).toList();
    }

    return _AggregatedResults(formulas, herbs, acupunctureEntries, penetrations, acupointDetails);
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedHerbNature != '全部') count++;
    if (_selectedHerbFlavor != '全部') count++;
    if (_selectedHerbMeridian != '全部') count++;
    if (_selectedHerbCategory != '全部') count++;
    if (_selectedFormulaMeridian != '全部') count++;
    if (_selectedFormulaCategory != '全部') count++;
    if (_formulaIndicationQuery.isNotEmpty) count++;
    return count;
  }

  void _clearFilters() {
    setState(() {
      _selectedHerbNature = '全部';
      _selectedHerbFlavor = '全部';
      _selectedHerbMeridian = '全部';
      _selectedHerbCategory = '全部';
      _selectedFormulaMeridian = '全部';
      _selectedFormulaCategory = '全部';
      _formulaIndicationQuery = '';
      _formulaIndicationController.clear();
      if (_currentQuery.isNotEmpty) {
        _results = _performSearch(_currentQuery);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        // 搜索框
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: '搜索方剂、药物、穴位、处方...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _executeSearch('');
                        _updateSuggestions('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (v) {
              _onSearchChanged(v);
            },
            onSubmitted: _onSubmitted,
          ),
        ),

        // 高级筛选开关
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              FilterChip(
                label: Text('高级筛选${_activeFilterCount > 0 ? ' ($_activeFilterCount)' : ''}'),
                selected: _showFilters,
                onSelected: (v) => setState(() => _showFilters = v),
                avatar: _activeFilterCount > 0
                    ? Badge(
                        label: Text('$_activeFilterCount',
                            style: const TextStyle(fontSize: 10)),
                        child: const Icon(Icons.tune, size: 18),
                      )
                    : null,
              ),
              if (_activeFilterCount > 0) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('清除筛选'),
                ),
              ],
            ],
          ),
        ),

        // 筛选面板
        if (_showFilters) _buildFilterPanel(cs),

        // 结果计数
        if (_currentQuery.isNotEmpty && _results.totalCount > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              '共 ${_results.totalCount} 条结果'
                  '${_results.formulas.isNotEmpty ? " · 方剂 ${_results.formulas.length}" : ""}'
                  '${_results.herbs.isNotEmpty ? " · 本草 ${_results.herbs.length}" : ""}'
                  '${_results.acupunctureEntries.isNotEmpty ? " · 穴位处方 ${_results.acupunctureEntries.length}" : ""}'
                  '${_results.penetrationEntries.isNotEmpty ? " · 透穴 ${_results.penetrationEntries.length}" : ""}'
                  '${_results.acupointDetails.isNotEmpty ? " · 穴位 ${_results.acupointDetails.length}" : ""}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),

        // 联想建议
        if (_suggestions.isNotEmpty && _currentQuery.isNotEmpty)
          _buildSuggestions(),

        // 主内容区域
        Expanded(child: _buildBody()),
      ],
    );
  }

  // ── 筛选面板 ──
  Widget _buildFilterPanel(ColorScheme cs) {
    final herbCategories = ['全部', ...HerbRepository.getCategories().where((c) => c != '全部')];
    final formulaCategories = ['全部', ...FormulaRepository.getCategories()];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.3),
        border: Border(bottom: BorderSide(color: cs.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 切换本草/方剂筛选
          Row(
            children: [
              ChoiceChip(
                label: const Text('本草筛选', style: TextStyle(fontSize: 12)),
                selected: _filterSection == 'herb',
                onSelected: (v) => setState(() => _filterSection = 'herb'),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('方剂筛选', style: TextStyle(fontSize: 12)),
                selected: _filterSection == 'formula',
                onSelected: (v) => setState(() => _filterSection = 'formula'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_filterSection == 'herb') ...[
            _buildChipRow('四气', _natures, _selectedHerbNature,
                (v) => setState(() {
                      _selectedHerbNature = v;
                      if (_currentQuery.isNotEmpty) _results = _performSearch(_currentQuery);
                    })),
            const SizedBox(height: 4),
            _buildChipRow('五味', _flavors, _selectedHerbFlavor,
                (v) => setState(() {
                      _selectedHerbFlavor = v;
                      if (_currentQuery.isNotEmpty) _results = _performSearch(_currentQuery);
                    })),
            const SizedBox(height: 4),
            _buildChipRow('归经', _meridians, _selectedHerbMeridian,
                (v) => setState(() {
                      _selectedHerbMeridian = v;
                      if (_currentQuery.isNotEmpty) _results = _performSearch(_currentQuery);
                    })),
            const SizedBox(height: 4),
            _buildChipRow('分类', herbCategories, _selectedHerbCategory,
                (v) => setState(() {
                      _selectedHerbCategory = v;
                      if (_currentQuery.isNotEmpty) _results = _performSearch(_currentQuery);
                    }), scrollable: true),
          ] else ...[
            _buildChipRow('六经', _formulaMeridians, _selectedFormulaMeridian,
                (v) => setState(() {
                      _selectedFormulaMeridian = v;
                      if (_currentQuery.isNotEmpty) _results = _performSearch(_currentQuery);
                    })),
            const SizedBox(height: 4),
            _buildChipRow('分类', formulaCategories, _selectedFormulaCategory,
                (v) => setState(() {
                      _selectedFormulaCategory = v;
                      if (_currentQuery.isNotEmpty) _results = _performSearch(_currentQuery);
                    }), scrollable: true),
            const SizedBox(height: 4),
            SizedBox(
              height: 40,
              child: TextField(
                controller: _formulaIndicationController,
                decoration: InputDecoration(
                  hintText: '主治症状关键词...',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  prefixIcon: const Icon(Icons.search, size: 18),
                ),
                onChanged: (v) {
                  _formulaIndicationQuery = v;
                  if (_currentQuery.isNotEmpty) {
                    setState(() => _results = _performSearch(_currentQuery));
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChipRow(String label, List<String> options, String selected,
      ValueChanged<String> onSelected, {bool scrollable = false}) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Text('$label:', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(width: 4),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final opt = options[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ChoiceChip(
                    label: Text(opt, style: const TextStyle(fontSize: 11)),
                    selected: selected == opt,
                    onSelected: (_) => onSelected(opt),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── 联想建议 ──
  Widget _buildSuggestions() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final s = _suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ActionChip(
              label: Text(s, style: const TextStyle(fontSize: 12)),
              onPressed: () {
                _searchController.text = s;
                _searchController.selection = TextSelection.fromPosition(
                  TextPosition(offset: s.length),
                );
                _executeSearch(s);
                _onSubmitted(s);
              },
            ),
          );
        },
      ),
    );
  }

  // ── 主内容 ──
  Widget _buildBody() {
    if (_currentQuery.isEmpty) {
      if (_isFocused && _searchHistory.isNotEmpty) {
        return _buildHistoryList();
      }
      return Center(
        child: Text(
          '输入关键词搜索方剂、药物、穴位、处方',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    if (_results.totalCount == 0) {
      return Center(
        child: Text(
          '未找到匹配结果',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      children: [
        if (_results.formulas.isNotEmpty)
          _buildFormulaSection(),
        if (_results.herbs.isNotEmpty)
          _buildHerbSection(),
        if (_results.acupunctureEntries.isNotEmpty)
          _buildAcupunctureSection(),
        if (_results.penetrationEntries.isNotEmpty)
          _buildPenetrationSection(),
        if (_results.acupointDetails.isNotEmpty)
          _buildAcupointDetailSection(),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── 搜索历史 ──
  Widget _buildHistoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('最近搜索', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () async {
                  await SearchHistoryRepository.clearAll();
                  setState(() => _searchHistory = []);
                },
                child: const Text('清空'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final q = _searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history, size: 20),
                title: Text(q),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () async {
                    await SearchHistoryRepository.deleteSearch(q);
                    setState(() => _searchHistory.remove(q));
                  },
                ),
                onTap: () {
                  _searchController.text = q;
                  _executeSearch(q);
                  _onSubmitted(q);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Section Header ──
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 6),
          Text(title, style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          )),
        ],
      ),
    );
  }

  // ── 方剂结果 ──
  Widget _buildFormulaSection() {
    final items = _results.formulas;
    final isExpanded = _expandedSections['formula'] ?? false;
    final showItems = isExpanded ? items : items.take(15).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('方剂 (${items.length})', Icons.medication),
        ...showItems.map((f) => Card(
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: ListTile(
            title: HighlightedText(
              text: f.name,
              query: _currentQuery,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${f.meridian} · ${f.indication}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => FormulaDetailScreen(formula: f))),
          ),
        )),
        if (!isExpanded && items.length > 15)
          _buildExpandButton('formula', items.length),
      ],
    );
  }

  // ── 本草结果 ──
  Widget _buildHerbSection() {
    final items = _results.herbs;
    final isExpanded = _expandedSections['herb'] ?? false;
    final showItems = isExpanded ? items : items.take(15).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('本草 (${items.length})', Icons.eco),
        ...showItems.map((h) => Card(
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(h.name.substring(0, 1),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                )),
            ),
            title: Row(
              children: [
                HighlightedText(
                  text: h.name,
                  query: _currentQuery,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Icon(h.natureIcon, size: 14),
              ],
            ),
            subtitle: Text(
              '${h.flavor.isNotEmpty ? "味${h.flavor} " : ""}'
              '${h.meridians.isNotEmpty ? "归${h.meridians.join(" ")} " : ""}'
              '${h.category}',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: h.hasDetailedInfo ? const Icon(Icons.chevron_right, size: 20) : null,
            onTap: h.hasDetailedInfo
                ? () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => HerbDetailScreen(herb: h)))
                : null,
          ),
        )),
        if (!isExpanded && items.length > 15)
          _buildExpandButton('herb', items.length),
      ],
    );
  }

  // ── 穴位处方结果 ──
  Widget _buildAcupunctureSection() {
    final items = _results.acupunctureEntries;
    final isExpanded = _expandedSections['acuEntry'] ?? false;
    final showItems = isExpanded ? items : items.take(15).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('穴位处方 (${items.length})', Icons.healing),
        ...showItems.map((e) => Card(
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
              child: Icon(Icons.healing, size: 18,
                color: Theme.of(context).colorScheme.tertiary),
            ),
            title: Row(
              children: [
                Expanded(child: HighlightedText(
                  text: e.symptom,
                  query: _currentQuery,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: e.source == 'nihaisha'
                        ? Colors.orange.shade100
                        : Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(e.sourceLabel,
                    style: TextStyle(fontSize: 10,
                      color: e.source == 'nihaisha'
                          ? Colors.orange.shade800
                          : Colors.blue.shade800)),
                ),
              ],
            ),
            subtitle: Text(e.acupointsText,
              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13)),
            trailing: e.hasCase
                ? Icon(Icons.article, color: Theme.of(context).colorScheme.tertiary)
                : null,
            children: [
              if (e.aliases.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(children: [
                    Text('别名: ', style: TextStyle(color: Colors.grey[600])),
                    Text(e.aliases.join('、')),
                  ]),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: e.acupoints.map((a) {
                    return GestureDetector(
                      onTap: () {
                        final detail = AcupointRepository.findByName(a.name);
                        if (detail != null) {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => AcupointDetailScreen(acupoint: detail)));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('暂无"${a.name}"的详细解释')));
                        }
                      },
                      child: Chip(
                        label: Text(a.name),
                        backgroundColor: a.method != null
                            ? Colors.orange.shade100
                            : Colors.blue.shade50,
                        labelStyle: const TextStyle(fontSize: 12),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (e.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Text('备注: ${e.notes}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ),
              if (e.hasCase)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(e.medicalCase, style: const TextStyle(fontSize: 13)),
                  ),
                ),
            ],
          ),
        )),
        if (!isExpanded && items.length > 15)
          _buildExpandButton('acuEntry', items.length),
      ],
    );
  }

  // ── 透针透穴结果 ──
  Widget _buildPenetrationSection() {
    final items = _results.penetrationEntries;
    final isExpanded = _expandedSections['penetration'] ?? false;
    final showItems = isExpanded ? items : items.take(15).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('透针透穴 (${items.length})', Icons.timeline),
        ...showItems.map((p) => Card(
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: ExpansionTile(
            title: HighlightedText(
              text: p.name,
              query: _currentQuery,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: p.indications.map((ind) => Chip(
                label: Text(ind, style: const TextStyle(fontSize: 11)),
                backgroundColor: Colors.green.shade50,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('来源', style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 4),
                    Text(p.source),
                    if (p.hasInsight) ...[
                      const SizedBox(height: 12),
                      Text('临证心悟', style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary)),
                      const SizedBox(height: 4),
                      Text(p.clinicalInsight),
                    ],
                    if (p.hasCase) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(p.medicalCase),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        )),
        if (!isExpanded && items.length > 15)
          _buildExpandButton('penetration', items.length),
      ],
    );
  }

  // ── 穴位详解结果 ──
  Widget _buildAcupointDetailSection() {
    final items = _results.acupointDetails;
    final isExpanded = _expandedSections['acupoint'] ?? false;
    final showItems = isExpanded ? items : items.take(15).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('穴位详解 (${items.length})', Icons.place),
        ...showItems.map((a) => Card(
          margin: const EdgeInsets.symmetric(vertical: 3),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
              child: Icon(Icons.place, size: 18,
                color: Theme.of(context).colorScheme.tertiary),
            ),
            title: HighlightedText(
              text: a.name,
              query: _currentQuery,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${a.meridian.isNotEmpty ? "${a.meridian} · " : ""}'
              '${a.description.isNotEmpty ? a.description : a.clinicalNotes}',
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => AcupointDetailScreen(acupoint: a))),
          ),
        )),
        if (!isExpanded && items.length > 15)
          _buildExpandButton('acupoint', items.length),
      ],
    );
  }

  Widget _buildExpandButton(String key, int total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextButton(
        onPressed: () => setState(() => _expandedSections[key] = true),
        child: Text('展开查看全部 $total 条'),
      ),
    );
  }
}

// ── 聚合搜索结果 ──
class _AggregatedResults {
  final List<Formula> formulas;
  final List<Herb> herbs;
  final List<AcupointEntry> acupunctureEntries;
  final List<PenetrationEntry> penetrationEntries;
  final List<AcupointDetail> acupointDetails;

  _AggregatedResults(
    this.formulas,
    this.herbs,
    this.acupunctureEntries,
    this.penetrationEntries,
    this.acupointDetails,
  );

  factory _AggregatedResults.empty() =>
      _AggregatedResults([], [], [], [], []);

  int get totalCount =>
      formulas.length +
      herbs.length +
      acupunctureEntries.length +
      penetrationEntries.length +
      acupointDetails.length;
}
