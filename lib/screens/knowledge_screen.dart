import 'package:flutter/material.dart';
import '../data/formula_repository.dart';
import '../data/herb_repository.dart';
import '../engine/diagnostic_rules.dart';
import '../models/formula.dart';
import '../models/herb.dart';
import '../widgets/meridian_icons.dart';
import '../theme/app_colors.dart';
import 'acupuncture_screen.dart';
import 'formula_detail_screen.dart';
import 'herb_detail_screen.dart';
import 'meridian_detail_screen.dart';
import 'neijing_knowledge_screen.dart';
import 'search_tab.dart';

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
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('知识库'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '六经', icon: Icon(Icons.public)),
            Tab(text: '方剂', icon: Icon(Icons.medication)),
            Tab(text: '本草', icon: Icon(Icons.eco)),
            Tab(text: '针灸', icon: Icon(Icons.healing)),
            Tab(text: '内经', icon: Icon(Icons.menu_book)),
            Tab(text: '搜索', icon: Icon(Icons.search)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _MeridianTab(),
          _FormulaTab(),
          _HerbTab(),
          const AcupunctureScreen(),
          const NeijingKnowledgeScreen(),
          const SearchTab(),
        ],
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

  List<Formula> _getFormulas() {
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
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: formulas.length,
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

  List<Herb> _getHerbs() {
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
      final q = _searchQuery.toLowerCase();
      herbs = herbs.where((h) =>
          h.name.toLowerCase().contains(q) ||
          (h.action ?? '').toLowerCase().contains(q) ||
          h.flavor.toLowerCase().contains(q) ||
          h.category.toLowerCase().contains(q)
      ).toList();
    }
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
        // Count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '共 ${herbs.length} 味药',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        // Herb list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: herbs.length,
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
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        h.natureIcon,
                        size: 14,
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${h.flavor.isNotEmpty ? "味${h.flavor} " : ""}'
                    '${h.meridians.isNotEmpty ? "归${h.meridians.join(" ")} " : ""}'
                    '${h.category}\n$actionShort',
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: h.hasDetailedInfo
                      ? const Icon(Icons.chevron_right, size: 20)
                      : null,
                  onTap: h.hasDetailedInfo
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HerbDetailScreen(herb: h),
                            ),
                          )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
