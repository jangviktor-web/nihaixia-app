import 'package:flutter/material.dart';
import '../data/acupuncture_repository.dart';
import '../data/acupoint_repository.dart';
import '../models/acupuncture.dart';
import '../models/acupoint_detail.dart';
import 'acupoint_detail_screen.dart';
import '../theme/app_colors.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<AcupointEntry> _getEntries() {
    if (_searchQuery.isNotEmpty) {
      return AcupunctureRepository.search(_searchQuery);
    }
    return AcupunctureRepository.getByCategory(_selectedCategory);
  }

  List<PenetrationEntry> _getPenetrations() {
    return AcupunctureRepository.searchPenetrations(_penetrationSearch);
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
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildEntriesTab(),
              _buildPenetrationTab(),
              _buildAcupointBrowseTab(),
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

          if (entry.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '备注: ${entry.notes}',
                style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 12),
              ),
            ),

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
    if (_acupointSearch.isNotEmpty) {
      return AcupointRepository.search(_acupointSearch);
    }
    return AcupointRepository.getByMeridian(_selectedMeridian);
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '共 ${acupoints.length} 个穴位',
            style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
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
}
