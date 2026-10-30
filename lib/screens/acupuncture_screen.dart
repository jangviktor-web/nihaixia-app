import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../data/acupuncture_repository.dart';
import '../data/acupoint_repository.dart';
import '../models/acupuncture.dart';
import '../models/acupoint_detail.dart';
import 'acupoint_detail_screen.dart';
import '../theme/app_colors.dart';
import '../widgets/ear_points_map.dart';
import '../widgets/keep_alive_tab.dart';
import '../widgets/meridian_map.dart';

class _NoteSection {
  final String tag;
  final List<String> body;
  _NoteSection({required this.tag, required this.body});
}

class AcupunctureScreen extends StatefulWidget {
  const AcupunctureScreen({super.key});

  @override
  State<AcupunctureScreen> createState() => _AcupunctureScreenState();
}

class _AcupunctureScreenState extends State<AcupunctureScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = '全部';
  String _searchQuery = '';
  String _penetrationSearch = '';
  String _selectedMeridian = '全部';
  String _acupointSearch = '';

  // ===== 「耳穴」tab：GB/T 13734-2008，93 穴结构化库 =====
  String _earRegion = '全部';
  String _earQuery = '';
  /// 深链定位后要默认展开的穴名（null = 无深链，所有卡保持折叠）。
  String? _earExpandedName;
  /// 耳穴 tab 搜索框的 controller：深链时要把归并后的穴名写回输入框，
  /// 否则「空搜索框 + 只剩 1 穴」看起来像 bug，且用户不知如何恢复。
  late final TextEditingController _earSearchCtrl;
  late final Future<List<_EarPoint>> _earFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _earSearchCtrl = TextEditingController();
    _earFuture = _loadEarPoints();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _earSearchCtrl.dispose();
    super.dispose();
  }

  // 过滤结果缓存：每次 setState（输入、切筛选项、展开卡片）都会重建整页，
  // 全表扫描没必要重复跑。
  String? _entriesKey;
  List<AcupointEntry> _entriesCache = const [];
  String? _penetrationKey;
  List<PenetrationEntry> _penetrationCache = const [];
  String? _acupointsKey;
  List<AcupointDetail> _acupointsCache = const [];

  List<AcupointEntry> _getEntries() {
    final key = '$_searchQuery|$_selectedCategory';
    if (key == _entriesKey) return _entriesCache;
    final List<AcupointEntry> all;
    if (_searchQuery.isNotEmpty) {
      all = AcupunctureRepository.search(_searchQuery);
    } else {
      all = AcupunctureRepository.getByCategory(_selectedCategory);
    }
    // 隐藏「有病症名但无穴位内容」的空条目（如尾椎骨痛、牙周病）
    final list = all.where((e) => e.acupoints.isNotEmpty).toList();
    _entriesKey = key;
    _entriesCache = list;
    return list;
  }

  List<PenetrationEntry> _getPenetrations() {
    if (_penetrationKey == _penetrationSearch) return _penetrationCache;
    final list = AcupunctureRepository.searchPenetrations(_penetrationSearch);
    _penetrationKey = _penetrationSearch;
    _penetrationCache = list;
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: '穴位处方', icon: Icon(Icons.healing)),
              Tab(text: '透针透穴', icon: Icon(Icons.timeline)),
              Tab(text: '穴位讲解', icon: Icon(Icons.explore)),
              Tab(text: '耳穴', icon: Icon(Icons.hearing)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              KeepAliveTab(child: _buildEntriesTab()),
              KeepAliveTab(child: _buildPenetrationTab()),
              KeepAliveTab(child: _buildAcupointBrowseTab()),
              KeepAliveTab(child: _buildEarPointsTab()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEntriesTab() {
    final categories = AcupunctureRepository.getCategories();
    final entries = _getEntries();

    return Column(
      children: [
        // 搜索框
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索症状或穴位...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                if (value.isNotEmpty) {
                  _selectedCategory = '全部';
                }
              });
            },
          ),
        ),

        // 分类过滤
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isSelected = _selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = cat;
                      _searchQuery = '';
                    });
                  },
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // 条目列表
        Expanded(
          child: entries.isEmpty
              ? const Center(child: Text('无匹配结果'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    return _buildEntryCard(entries[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEntryCard(AcupointEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.symptom,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: entry.source == 'nihaisha'
                    ? context.colors.warningContainer
                    : context.colors.infoContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                entry.sourceLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: entry.source == 'nihaisha'
                      ? context.colors.warning
                      : context.colors.info,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          entry.acupointsText,
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 12,
          ),
        ),
        trailing: entry.hasCase
            ? Icon(Icons.article, color: Theme.of(context).colorScheme.tertiary)
            : null,
        children: [
          if (entry.aliases.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text('别名: ', style: TextStyle(color: context.colors.onSurfaceVariant)),
                  Text(entry.aliases.join('、')),
                ],
              ),
            ),

          // 穴位详情
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: entry.acupoints.map((a) {
                return GestureDetector(
                  onTap: () {
                    if (a.name.startsWith('耳穴:')) {
                      // 跳到「耳穴」tab，预填搜索框并让该穴的卡默认展开
                      final canonical = _earCanonicalName(a.name);
                      setState(() {
                        _earQuery = canonical;
                        _earExpandedName = canonical;
                        _earRegion = '全部';
                        // 写回输入框，让「只剩 1 穴」与搜索框显示一致。
                        // 直接赋值 .text 不会触发 onChanged，不会重复 setState。
                        _earSearchCtrl.text = canonical;
                      });
                      _tabController.animateTo(3);
                      return;
                    }
                    final detail = AcupointRepository.findByName(
                        AcupointRepository.canonicalOf(a.name));
                    if (detail != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AcupointDetailScreen(acupoint: detail),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('暂无"${a.name}"的详细解释')),
                      );
                    }
                  },
                  child: Chip(
                    label: Text(a.name),
                    backgroundColor: a.method != null
                        ? context.colors.warningContainer
                        : context.colors.infoContainer,
                    labelStyle: const TextStyle(fontSize: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),

          if (entry.notes.isNotEmpty) _buildNotes(entry.notes),

          if (entry.hasCase)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  entry.medicalCase,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPenetrationTab() {
    final penetrations = _getPenetrations();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索透穴或适应症...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (value) {
              setState(() => _penetrationSearch = value);
            },
          ),
        ),
        Expanded(
          child: penetrations.isEmpty
              ? const Center(child: Text('无匹配结果'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: penetrations.length,
                  itemBuilder: (context, index) {
                    return _buildPenetrationCard(penetrations[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPenetrationCard(PenetrationEntry entry) {
    // 从名称中提取穴位（如"中府透云门"→["中府", "云门"]）
    final acupointNames = _extractAcupointsFromName(entry.name);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          entry.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 穴位 chips（可点击跳转详情）
            if (acupointNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: acupointNames.map((name) {
                    return GestureDetector(
                      onTap: () {
                        final detail = AcupointRepository.findByName(
                            AcupointRepository.canonicalOf(name));
                        if (detail != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AcupointDetailScreen(acupoint: detail),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('暂无"$name"的详细解释')),
                          );
                        }
                      },
                      child: Chip(
                        label: Text(name, style: const TextStyle(fontSize: 10)),
                        backgroundColor: context.colors.infoContainer,
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  }).toList(),
                ),
              ),
            // 适应症
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: entry.indications.map((ind) {
                return Chip(
                  label: Text(ind, style: const TextStyle(fontSize: 10)),
                  backgroundColor: context.colors.successContainer,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '来源',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(entry.source),
                if (entry.hasInsight) ...[
                  const SizedBox(height: 12),
                  Text(
                    '临证心悟',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(entry.clinicalInsight),
                ],
                if (entry.hasCase) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(entry.medicalCase),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<String> _extractAcupointsFromName(String name) {
    // 解析穴位名称，支持多种格式：
    // - "中府透云门" → ["中府", "云门"]
    // - "曲池透少海、三间透合谷" → ["曲池", "少海", "三间", "合谷"]
    final List<String> acupoints = [];
    final parts = name.split('、');
    for (final part in parts) {
      final subParts = part.split('透');
      for (final sub in subParts) {
        final trimmed = sub.trim();
        if (trimmed.isNotEmpty && trimmed.length <= 4) {
          acupoints.add(trimmed);
        }
      }
    }
    return acupoints;
  }

  List<AcupointDetail> _getAcupoints() {
    final key = '$_acupointSearch|$_selectedMeridian';
    if (key == _acupointsKey) return _acupointsCache;
    final list = _acupointSearch.isNotEmpty
        ? AcupointRepository.search(_acupointSearch)
        : AcupointRepository.getByMeridian(_selectedMeridian);
    _acupointsKey = key;
    _acupointsCache = list;
    return list;
  }

  Widget _buildAcupointBrowseTab() {
    final meridians = ['全部', ...AcupointRepository.getMeridians()];
    final acupoints = _getAcupoints();

    return Column(
      children: [
        // 搜索框
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: '搜索穴位名称或位置...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onChanged: (value) {
              setState(() {
                _acupointSearch = value;
                if (value.isNotEmpty) {
                  _selectedMeridian = '全部';
                }
              });
            },
          ),
        ),

        // 经络过滤
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: meridians.length,
            itemBuilder: (context, index) {
              final m = meridians[index];
              final isSelected = _selectedMeridian == m;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(m),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMeridian = m;
                      _acupointSearch = '';
                    });
                  },
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 12, right: 4),
          child: Row(
            children: <Widget>[
              Text(
                '共 ${acupoints.length} 个穴位',
                style:
                    TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
              ),
              const Spacer(),
              // 选中具体经络 → 直接开该经的循行图；「全部」→ 开图后在对话框内切换经络。
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.account_tree_outlined, size: 16),
                label: const Text('经络图', style: TextStyle(fontSize: 12)),
                onPressed: () => showMeridianMapDialog(
                  context,
                  initial:
                      _selectedMeridian == '全部' ? null : _selectedMeridian,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 4),

        // 穴位列表
        Expanded(
          child: acupoints.isEmpty
              ? const Center(child: Text('无匹配结果'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: acupoints.length,
                  itemBuilder: (context, index) {
                    return _buildAcupointCard(acupoints[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAcupointCard(AcupointDetail acupoint) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDetail = acupoint.description.isNotEmpty || acupoint.location.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        title: Row(
          children: [
            Text(
              acupoint.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 8),
            if (acupoint.meridian.isNotEmpty)
              Chip(
                label: Text(acupoint.meridian, style: const TextStyle(fontSize: 10)),
                backgroundColor: colorScheme.primaryContainer,
                labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
        subtitle: acupoint.location.isNotEmpty
            ? Text(
                acupoint.location,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12),
              )
            : null,
        trailing: hasDetail ? const Icon(Icons.chevron_right) : null,
        onTap: hasDetail
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AcupointDetailScreen(acupoint: acupoint),
                  ),
                );
              }
            : null,
      ),
    );
  }

  // ===== 备注优化：将 【xxx】 结构标签渲染为小标题 =====
  Widget _buildNotes(String notes) {
    final sections = _parseNotes(notes);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '备注',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          ...sections.map(_buildNoteSection),
        ],
      ),
    );
  }

  Widget _buildNoteSection(_NoteSection s) {
    final cs = Theme.of(context).colorScheme;
    if (s.tag.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: s.body
              .map((b) => Text(
                    b,
                    style: TextStyle(
                      color: context.colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ))
              .toList(),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '【${s.tag}】',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          ...s.body.map(
            (b) => Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text(
                b,
                style: TextStyle(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_NoteSection> _parseNotes(String notes) {
    final sections = <_NoteSection>[];
    _NoteSection? current;
    for (final raw in notes.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty) continue;
      final m = RegExp(r'^【(.+?)】(.*)$').firstMatch(line);
      if (m != null) {
        current = _NoteSection(tag: m.group(1)!, body: <String>[]);
        sections.add(current);
        final rest = m.group(2)!.trim();
        if (rest.isNotEmpty) current.body.add(rest);
      } else if (current == null) {
        current = _NoteSection(tag: '', body: <String>[line]);
        sections.add(current);
      } else {
        current.body.add(line);
      }
    }
    return sections;
  }

  // ===== 「耳穴」tab：GB/T 13734-2008 结构化库 =====

  static Future<List<_EarPoint>> _loadEarPoints() async {
    final str = await rootBundle.loadString('assets/data/ear_points.json');
    final data = jsonDecode(str) as Map<String, dynamic>;
    return (data['points'] as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      // record 字面量（typedef 的 record 类型没有构造函数）
      return (
        name: (m['name'] as String?) ?? '',
        pinyin: (m['pinyin'] as String?) ?? '',
        code: (m['code'] as String?) ?? '',
        region: (m['region'] as String?) ?? '',
        location: (m['location'] as String?) ?? '',
        indication: (m['indication'] as String?) ?? '',
      );
    }).toList();
  }

  /// 处方里的 `耳穴:XXX` → GB/T 标准名（app 内的旧称/俗称归并到国标名）。
  static String _earCanonicalName(String raw) {
    final n = raw.replaceFirst('耳穴:', '').trim();
    return _earAlias[n] ?? n;
  }

  List<_EarPoint> _filterEarPoints(List<_EarPoint> all) {
    final q = _earQuery.trim().toLowerCase();
    return all.where((p) {
      if (_earRegion != '全部' && p.region != _earRegion) return false;
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) ||
          p.pinyin.toLowerCase().contains(q) ||
          p.code.toLowerCase().contains(q);
    }).toList();
  }

  Widget _buildEarPointsTab() {
    return FutureBuilder<List<_EarPoint>>(
      future: _earFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('耳穴库加载失败：${snap.error}'));
        }
        final all = snap.data!;
        // 用 Set 保序去重，得到 JSON 中出现的 10 个耳区
        final regions = ['全部', ...{for (final p in all) p.region}];
        final shown = _filterEarPoints(all);

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _earSearchCtrl,
                decoration: InputDecoration(
                  hintText: '搜索穴名 / 拼音 / 代码...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: (v) => setState(() => _earQuery = v),
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: regions.length,
                itemBuilder: (context, index) {
                  final r = regions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(r),
                      selected: _earRegion == r,
                      onSelected: (_) => setState(() {
                        _earRegion = r;
                        _earQuery = '';
                        // 同步清空输入框，避免状态与显示脱节
                        _earSearchCtrl.clear();
                      }),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 4),
            // ponytail: 不再挂「讲解全文」——erxue_jiangjie.md 是 AI 未校对内容，
            // 且定位口径为 GB/T 13734-1992，与本 tab 的 2008 口径矛盾（见 ear_points.json）。
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(
                    '共 ${shown.length} 穴',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: '标准耳穴定位图',
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.map_outlined, size: 18),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => Dialog(
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            // ponytail: 静态标准图没法图上高亮单穴——
                            // 搜索剩 1 穴时用户自己对图找，不传 highlight。
                            child: EarPointsMap(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: shown.isEmpty
                  ? const Center(child: Text('无匹配结果'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: shown.length,
                      itemBuilder: (context, index) =>
                          _buildEarPointCard(shown[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEarPointCard(_EarPoint p) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ExpansionTile(
        // 按穴名做 key：列表增删/换词后元素按名匹配，展开状态不会串到别的卡上。
        key: ValueKey(p.name),
        // 深链定位到的穴默认展开。initiallyExpanded 仅在元素首次创建时生效，
        // 配合上面的 key 才能保证深链后「神门」那张卡新建即展开。
        initiallyExpanded: p.name == _earExpandedName,
        title: Row(
          children: [
            Text(
              p.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(width: 6),
            Chip(
              label: Text(p.code, style: const TextStyle(fontSize: 10)),
              backgroundColor: cs.primaryContainer,
              labelStyle: TextStyle(color: cs.onPrimaryContainer),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        subtitle: Text(
          p.location,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.pinyin.isNotEmpty)
                  _earRow('拼音', p.pinyin, cs),
                _earRow('分区', '${p.region} · ${p.code}', cs),
                _earRow(
                  '主治',
                  p.indication.isNotEmpty ? p.indication : '暂无（app 未收录）',
                  cs,
                ),
                const SizedBox(height: 6),
                Text(
                  '定位依据 GB/T 13734-2008《耳穴名称与定位》',
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _earRow(String label, String value, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label：',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: cs.primary,
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

/// GB/T 13734-2008 单个耳穴。用 record 而非 class：纯数据，无行为。
typedef _EarPoint = ({
  String name,
  String pinyin,
  String code,
  String region,
  String location,
  String indication,
});

/// app 处方里的旧称/俗称 → GB/T 标准名。
const _earAlias = <String, String>{
  '下脚端': '交感',
  '降压沟': '耳背沟',
  '子宫': '内生殖器',
  '卵巢': '内生殖器',
  '精宫': '内生殖器',
  '精宫穴': '内生殖器',
  '睾丸': '内生殖器',
  '睾丸穴': '内生殖器',
  '肝阳': '结节',
  '平喘': '对屏尖',
  '脑点': '缘中',
  '屏间': '内分泌',
  '甲状腺': '内分泌',
  '支气管': '肺',
  '骶腰椎': '腰骶椎',
  '上颌': '颌',
  '下颌': '颌',
  '乳腺': '胸',
};
