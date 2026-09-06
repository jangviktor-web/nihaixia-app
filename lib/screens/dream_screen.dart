import 'package:flutter/material.dart';

import '../data/dream_data.dart';

/// 周公解梦 —— 《周公解梦大全》结构化数据集民俗占梦查询。
///
/// 支持关键词搜索（关键词/梦境/解读）与分类筛选，逐条渲染梦境卡片，
/// 含吉凶色标。属民俗文化参考，解读为潜意识映射，非吉凶指令。
class DreamScreen extends StatefulWidget {
  const DreamScreen({super.key});

  @override
  State<DreamScreen> createState() => _DreamScreenState();
}

class _DreamScreenState extends State<DreamScreen> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';
  String? _category; // null = 全部

  /// 吉凶等级 → 基准色（绿系吉、蓝灰系平、橙红系凶）。
  Color _auspiciousColor(String level) {
    switch (level) {
      case '大吉':
        return Colors.green;
      case '吉':
        return Colors.teal;
      case '平':
        return Colors.blueGrey;
      case '凶':
        return Colors.orange;
      case '大凶':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final results = searchDreams(_query, _category);

    return Scaffold(
      appBar: AppBar(title: const Text('周公解梦')),
      body: Column(
        children: [
          _buildDisclaimer(cs),
          _buildSearchBar(cs),
          _buildCategoryChips(cs),
          Expanded(
            child: results.isEmpty
                ? const Center(
                    child: Text(
                      '未找到相关梦境',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: results.map(_buildDreamCard).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: cs.tertiaryContainer,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: cs.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              kDreamDisclaimer,
              style: TextStyle(fontSize: 12, color: cs.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _queryController,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: '搜关键词/梦境/解读，如 太阳、竹子、医院',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _queryController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ColorScheme cs) {
    final chips = <Widget>[
      _buildFilterChip(cs, '全部', _category == null),
    ];
    for (final c in kDreamCategories) {
      chips.add(_buildFilterChip(cs, c.name, _category == c.name));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: chips),
    );
  }

  Widget _buildFilterChip(ColorScheme cs, String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) =>
            setState(() => _category = (selected ? null : label == '全部' ? null : label)),
        selectedColor: cs.tertiaryContainer,
        checkmarkColor: cs.onTertiaryContainer,
        labelStyle: TextStyle(
          fontSize: 13,
          color: selected ? cs.onTertiaryContainer : cs.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildDreamCard(DreamEntry e) {
    final cs = Theme.of(context).colorScheme;
    final accent = _auspiciousColor(e.auspicious);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    e.keyword,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    e.auspicious,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  backgroundColor: accent.withValues(alpha: 0.18),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(e.dream, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 6),
            Text(
              e.interpretation,
              style: TextStyle(fontSize: 15, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              '出处：${e.source}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
