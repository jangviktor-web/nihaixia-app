import 'package:flutter/material.dart';
import '../data/formula_repository.dart';
import '../data/herb_repository.dart';
import '../data/settings_repository.dart';
import '../engine/diagnostic_rules.dart';
import '../models/formula.dart';
import '../models/herb.dart';
import '../widgets/keep_alive_tab.dart';
import '../widgets/meridian_icons.dart';
import '../widgets/solar_term_card.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import 'acupuncture_screen.dart';
import 'bencao_library_screen.dart';
import 'llm_ask_screen.dart';
import 'formula_detail_screen.dart';
import 'herb_detail_screen.dart';
import 'meridian_detail_screen.dart';
import 'neijing_knowledge_screen.dart';
import 'search_tab.dart';
import 'shanghan_jingui_screen.dart';

class KnowledgeScreen extends StatefulWidget {
  const KnowledgeScreen({super.key});

  @override
  State<KnowledgeScreen> createState() => _KnowledgeScreenState();
}

class _KnowledgeScreenState extends State<KnowledgeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this)
      // 宽屏左侧 nav 在 TabBarView 之外，tab 下标变化不会触发本页 setState，
      // 硬监听一下才能让高亮跟着换。
      ..addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  static const _tabs = <_KnowledgeTab>[
    _KnowledgeTab('六经', Icons.public),
    _KnowledgeTab('方剂', Icons.medication),
    _KnowledgeTab('本草', Icons.eco),
    _KnowledgeTab('针灸', Icons.healing),
    _KnowledgeTab('内经', Icons.menu_book),
    _KnowledgeTab('伤寒金匮', Icons.auto_stories),
    _KnowledgeTab('搜索', Icons.search),
  ];

  Widget _aiAction() {
    return ListenableBuilder(
      listenable: SettingsRepository.instance,
      builder: (context, _) {
        final s = SettingsRepository.instance;
        if (!s.llmEnabled) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
            icon: const Icon(Icons.smart_toy_outlined, size: 18),
            label: const Text('问倪师AI'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LlmAskScreen()),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _tabViews() => [
        KeepAliveTab(child: _MeridianTab()),
        KeepAliveTab(child: _FormulaTab()),
        KeepAliveTab(child: _HerbTab()),
        const KeepAliveTab(child: AcupunctureScreen()),
        const KeepAliveTab(child: NeijingKnowledgeScreen()),
        const KeepAliveTab(child: ShangHanJinguiScreen()),
        const KeepAliveTab(child: SearchTab()),
      ];

  Widget _solarTermCard() {
    return ListenableBuilder(
      listenable: SettingsRepository.instance,
      builder: (context, _) => SettingsRepository.instance.hideSolarTermCard
          ? const SizedBox.shrink()
          : const SolarTermCard(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 7 个 tab 在手机宽度下要横向滑动才能翻完，电脑上则是一排 1200px 宽的按钮；
    // 宽屏统一改成左侧竖向 tab 列表，正文区回到可读宽度。
    if (context.isWideViewport) return _buildWide(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('知识库'),
        actions: [_aiAction()],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            for (final t in _tabs) Tab(text: t.label, icon: Icon(t.icon)),
          ],
        ),
      ),
      body: Column(
        children: [
          // 节气卡占一屏高度；设置里可关掉（issue #4 反馈占屏比大）
          _solarTermCard(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabViews(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWide(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('知识库'), actions: [_aiAction()]),
      body: Row(
        children: [
          Container(
            width: 176,
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              border: Border(right: BorderSide(color: cs.outlineVariant)),
            ),
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                ListenableBuilder(
                  listenable: _tabController,
                  builder: (context, _) => Column(
                    children: [
                      for (var i = 0; i < _tabs.length; i++)
                        _WideTabItem(
                          tab: _tabs[i],
                          selected: _tabController.index == i,
                          onTap: () => _tabController.animateTo(i),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: PageBody(
              maxWidth: 1100,
              child: Column(
                children: [
                  _solarTermCard(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: _tabViews(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowledgeTab {
  final String label;
  final IconData icon;
  const _KnowledgeTab(this.label, this.icon);
}

/// 宽屏知识库左侧的竖向 tab 项（与手机端 TabBar 同一份配置）。
class _WideTabItem extends StatelessWidget {
  final _KnowledgeTab tab;
  final bool selected;
  final VoidCallback onTap;

  const _WideTabItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fg = selected ? cs.onSecondaryContainer : cs.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: selected ? cs.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Icon(tab.icon, size: 18, color: fg),
                const SizedBox(width: 10),
                Text(
                  tab.label,
                  style: TextStyle(
                    fontSize: 13,
                    color: fg,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MeridianTab extends StatelessWidget {
  static const _meridianOrder = ['太阳', '阳明', '少阳', '太阴', '少阴', '厥阴'];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _meridianOrder.length,
      itemBuilder: (context, index) {
        final name = _meridianOrder[index];
        final details = DiagnosticRules.meridianDetails[name];
        if (details == null) return const SizedBox.shrink();

        final color = context.colors.meridianColor(name);
        final healingTime = DiagnosticRules.meridianHealingTime[name] ?? '';
        final formulas = details['formulas'] as List<String>;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MeridianDetailScreen(meridian: name),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: color, width: 4)),
              ),
              child: ExpansionTile(
                leading: Icon(meridianIcon(name), size: 28, color: color),
                title: Text(
                  '$name病',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      '${details['nature']} · ${details['organ']}',
                      style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '核心脉证：${details['keyPulse']}',
                      style: const TextStyle(fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 12, color: context.colors.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '欲解时：$healingTime',
                            style: TextStyle(fontSize: 10, color: context.colors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 核心症状
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: (details['coreSymptoms'] as List<String>)
                              .map((s) => Chip(
                                    label: Text(s, style: const TextStyle(fontSize: 12)),
                                    backgroundColor: context.colors.meridianContainer(name),
                                    side: BorderSide(color: context.colors.outlineVariant),
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        // 常用方剂
                        Text('常用方剂 (${formulas.length})',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14, color: color)),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: formulas
                              .map((f) => ActionChip(
                                    label: Text(f, style: const TextStyle(fontSize: 12)),
                                    onPressed: () {
                                      final formula = FormulaRepository.getByName(f);
                                      if (formula != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => FormulaDetailScreen(formula: formula),
                                          ),
                                        );
                                      }
                                    },
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        // 查看详情按钮
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MeridianDetailScreen(meridian: name),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward, size: 16),
                            label: const Text('查看详情', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FormulaTab extends StatefulWidget {
  @override
  State<_FormulaTab> createState() => _FormulaTabState();
}

class _FormulaTabState extends State<_FormulaTab> {
  String _selectedMeridian = '全部';
  String _selectedCategory = '全部';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  static const _meridians = [
    '全部', '太阳', '阳明', '少阳', '太阴', '少阴', '厥阴'
  ];

  static const _categories = [
    '全部', '金疮药', '倪海厦经验方',
    '解表剂', '和解剂', '清热剂', '泻下剂',
    '温里剂', '补益剂', '理气剂', '活血化瘀剂',
    '祛湿剂', '化痰剂', '寒热并用剂', '外用剂',
    '祛风剂', '安神剂', '止血剂', '驱虫剂',
  ];

  // 过滤结果缓存：build 会在主题切换、tab 重入、每次输入时被调用，
  // 257 首方剂 × 四个字段 toLowerCase 全表扫描没必要反复做。
  String? _cacheKey;
  List<Formula> _cachedList = const [];

  List<Formula> _getFormulas() {
    final key = '$_selectedMeridian|$_selectedCategory|$_searchQuery';
    if (key == _cacheKey) return _cachedList;

    var list = FormulaRepository.getAll();
    if (_selectedMeridian != '全部') {
      list = list.where((f) => f.meridian.contains(_selectedMeridian)).toList();
    }
    if (_selectedCategory != '全部') {
      list = list.where((f) => f.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((f) =>
          f.name.toLowerCase().contains(q) ||
          f.indication.toLowerCase().contains(q) ||
          f.components.any((c) => c.name.toLowerCase().contains(q)) ||
          f.keywords.any((k) => k.toLowerCase().contains(q))
      ).toList();
    }
    _cacheKey = key;
    _cachedList = list;
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final formulas = _getFormulas();

    return Column(
      children: [
        // 搜索框
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: '搜索方剂名、适应证、药物组成...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
          ),
        ),
        // 六经筛选
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _meridians.length,
            itemBuilder: (context, index) {
              final m = _meridians[index];
              final selected = m == _selectedMeridian;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(m, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedMeridian = m),
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
        ),
        // 分类筛选
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final c = _categories[index];
              final selected = c == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(c, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = c),
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '共 ${formulas.length} 首方剂',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(
          child: PageBody(
            maxWidth: 1000,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 宽屏改成两列卡片，一屏能看到更多方剂/药材。
                final wide = constraints.maxWidth >= 720;
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: formulas.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: wide ? 2 : 1,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    mainAxisExtent: 108,
                  ),
                  itemBuilder: (context, index) {
                    final f = formulas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Text(
                          f.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${f.meridian} · ${f.category}\n${f.indication.length > 40 ? '${f.indication.substring(0, 40)}...' : f.indication}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FormulaDetailScreen(formula: f),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _HerbTab extends StatefulWidget {
  @override
  State<_HerbTab> createState() => _HerbTabState();
}

class _HerbTabState extends State<_HerbTab> {
  String _selectedCategory = '全部';
  String _selectedNature = '全部';
  String _selectedMeridian = '全部';
  String _searchQuery = '';
  final TextEditingController _searchCtrl = TextEditingController();

  static const _meridians = [
    '全部', '肺', '心', '肝', '脾', '肾', '胃', '胆', '大肠', '小肠', '膀胱', '三焦'
  ];

  // 同 _FormulaTab：过滤结果缓存，避免每次 build 重跑全表匹配。
  String? _cacheKey;
  List<Herb> _cachedList = const [];

  List<Herb> _getHerbs() {
    final key =
        '$_selectedCategory|$_selectedNature|$_selectedMeridian|$_searchQuery';
    if (key == _cacheKey) return _cachedList;

    var herbs = HerbRepository.getAll();
    if (_selectedCategory != '全部') {
      herbs = herbs.where((h) => h.category == _selectedCategory).toList();
    }
    if (_selectedNature != '全部') {
      herbs = herbs.where((h) => h.natureCategory == _selectedNature).toList();
    }
    if (_selectedMeridian != '全部') {
      herbs = herbs.where((h) => h.meridians.contains(_selectedMeridian)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      // 走 HerbRepository.matchesQuery（含异名归一）。
      // 此前此处自行拼字符串匹配，漏了 canonicalOf，导致 103 个异名中 74 个在此页搜不到
      //（例：茈胡 → 应命中柴胡）。禁止改回本地匹配。
      herbs = herbs.where((h) => HerbRepository.matchesQuery(h, _searchQuery)).toList();
    }
    _cacheKey = key;
    _cachedList = herbs;
    return herbs;
  }

  @override
  Widget build(BuildContext context) {
    final herbs = _getHerbs();
    final categories = HerbRepository.getCategories();
    final natures = HerbRepository.getNatureCategories();

    return Column(
      children: [
        // 搜索框
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: '搜索药名、功效、性味、分类...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v.trim()),
          ),
        ),
        // Category filter
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final selected = cat == _selectedCategory;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(cat, style: const TextStyle(fontSize: 12)),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedCategory = cat),
                  visualDensity: VisualDensity.compact,
                ),
              );
            },
          ),
        ),
        // Nature + Meridian filter
        SizedBox(
          height: 36,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: natures.length + _meridians.length,
            itemBuilder: (context, index) {
              if (index < natures.length) {
                final n = natures[index];
                final selected = n == _selectedNature && _selectedMeridian == '全部';
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(n, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _selectedNature = n;
                      _selectedMeridian = '全部';
                    }),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              } else {
                final m = _meridians[index - natures.length];
                final selected = m == _selectedMeridian;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(m, style: const TextStyle(fontSize: 12)),
                    selected: selected,
                    onSelected: (_) => setState(() {
                      _selectedMeridian = m;
                      _selectedNature = '全部';
                    }),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }
            },
          ),
        ),
        // Count + 讲稿入口
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                '共 ${herbs.length} 味药',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // 本草讲稿（倪师人纪）：系统学习入口，与逐药速查互补。
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.menu_book_outlined, size: 16),
                label: const Text('讲稿', style: TextStyle(fontSize: 12)),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BenCaoLibraryScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Herb list
        Expanded(
          child: PageBody(
            maxWidth: 1000,
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 宽屏改成两列卡片，一屏能看到更多药材。
                final wide = constraints.maxWidth >= 720;
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: herbs.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: wide ? 2 : 1,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 8,
                    mainAxisExtent: 108,
                  ),
                  itemBuilder: (context, index) {
                    final h = herbs[index];
                    final action = h.action ?? '';
                    final actionShort =
                        action.length > 40 ? '${action.substring(0, 40)}...' : action;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              Theme.of(context).colorScheme.primaryContainer,
                          child: Text(
                            h.name.substring(0, 1),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Text(
                              h.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 6),
                            Icon(h.natureIcon, size: 14),
                          ],
                        ),
                        subtitle: Text(
                          '${h.flavor.isNotEmpty ? "味${h.flavor} " : ""}'
                          '${h.meridians.isNotEmpty ? "归${h.meridians.join(" ")} " : ""}'
                          '${h.category}\n$actionShort',
                          style: const TextStyle(fontSize: 12),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => HerbDetailScreen(herb: h),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
