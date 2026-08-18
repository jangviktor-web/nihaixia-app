import 'package:flutter/material.dart';
import '../models/herb.dart';
import '../theme/app_colors.dart';
import '../models/bookmark.dart';
import '../data/formula_repository.dart';
import '../data/herb_repository.dart';
import '../data/database_helper.dart';
import 'formula_detail_screen.dart';

class HerbDetailScreen extends StatefulWidget {
  final Herb herb;

  const HerbDetailScreen({super.key, required this.herb});

  @override
  State<HerbDetailScreen> createState() => _HerbDetailScreenState();
}

class _HerbDetailScreenState extends State<HerbDetailScreen> {
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  void _checkBookmark() async {
    final db = DatabaseHelper.instance;
    final bookmarked = await db.isBookmarked(widget.herb.name);
    setState(() => _isBookmarked = bookmarked);
  }

  void _toggleBookmark() async {
    final db = DatabaseHelper.instance;
    if (_isBookmarked) {
      final bookmarks = await db.getAllBookmarks();
      final match = bookmarks.firstWhere(
        (b) => b.title == widget.herb.name,
        orElse: () => Bookmark(title: '', content: '', category: '', source: ''),
      );
      if (match.id != null) {
        await db.deleteBookmark(match.id!);
      }
    } else {
      await db.insertBookmark(Bookmark(
        title: widget.herb.name,
        content: _buildBookmarkContent(),
        category: '本草',
        source: 'herb_detail',
      ));
    }
    setState(() => _isBookmarked = !_isBookmarked);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isBookmarked ? '已收藏' : '已取消收藏'),
        ),
      );
    }
  }

  String _buildBookmarkContent() {
    final h = widget.herb;
    return '${h.name} (${h.category})\n'
        '${h.flavor.isNotEmpty ? "味${h.flavor} " : ""}'
        '${h.meridians.isNotEmpty ? "归${h.meridians.join(" ")}" : ""}\n\n'
        '${h.action ?? ""}';
  }

  @override
  Widget build(BuildContext context) {
    final herb = widget.herb;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(herb.name),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: _toggleBookmark,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(herb.natureIcon, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    herb.natureCategory,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header: name + category + flavor
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    herb.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Chip(
                        label: Text(herb.category),
                        backgroundColor: cs.primaryContainer,
                        labelStyle: TextStyle(color: cs.onPrimaryContainer),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      if (herb.flavor.isNotEmpty)
                        Chip(
                          label: Text('味${herb.flavor}'),
                          backgroundColor: cs.secondaryContainer,
                          labelStyle:
                              TextStyle(color: cs.onSecondaryContainer),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      if (herb.meridians.isNotEmpty)
                        Chip(
                          label: Text('归经: ${herb.meridians.join(" ")}'),
                          backgroundColor: cs.tertiaryContainer,
                          labelStyle:
                              TextStyle(color: cs.onTertiaryContainer),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // 性味
          if (herb.nature != null) _buildSection('性味', herb.nature!, cs),

          // 主治
          if (herb.action != null) _buildSection('主治', herb.action!, cs),

          // 本经原文
          if (herb.original != null)
            _buildSection('本经原文', herb.original!, cs),

          // 倪注
          if (herb.niNote != null) _buildSection('倪注', herb.niNote!, cs),

          // 容川注
          if (herb.rongchuan != null)
            _buildSection('容川注', herb.rongchuan!, cs),

          // 用量
          if (herb.dosage != null) _buildSection('用量', herb.dosage!, cs),

          // 禁忌
          if (herb.contraindication != null)
            Card(
              color: cs.errorContainer,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber,
                            color: cs.onErrorContainer),
                        const SizedBox(width: 8),
                        Text(
                          '禁忌',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      herb.contraindication!,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: cs.onErrorContainer),
                    ),
                  ],
                ),
              ),
            ),

          // 倪师临床口述
          if (herb.clinicalNotes != null)
            Card(
              color: cs.tertiaryContainer,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.record_voice_over,
                            color: cs.onTertiaryContainer),
                        const SizedBox(width: 8),
                        Text(
                          '倪师临床口述',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      herb.clinicalNotes!,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: cs.onTertiaryContainer),
                    ),
                  ],
                ),
              ),
            ),

          // 历代医家注释
          if (herb.historicalNotes != null && herb.historicalNotes!.isNotEmpty)
            Card(
              color: cs.surfaceContainerHighest,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.history_edu,
                            color: cs.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Text(
                          '历代医家注释',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      herb.historicalNotes!,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),

          // 药物比较
          if (herb.herbComparisons.isNotEmpty)
            Card(
              color: context.colors.primaryContainer,
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.compare_arrows,
                            color: cs.primary),
                        const SizedBox(width: 8),
                        Text(
                          '药物比较',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...herb.herbComparisons.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '· $c',
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: cs.onSurface),
                      ),
                    )),
                  ],
                ),
              ),
            ),

          // 含此药的方剂
          Builder(
            builder: (context) {
              final formulas = FormulaRepository.getAll()
                  .where((f) => f.components
                      .any((c) => HerbRepository.canonicalOf(c.name) == herb.name))
                  .toList();
              if (formulas.isEmpty) return const SizedBox.shrink();
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medication, color: cs.primary),
                          const SizedBox(width: 8),
                          Text(
                            '含此药的方剂 (${formulas.length})',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...formulas.map((f) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(f.name,
                                style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              '${f.meridian} · ${f.indication.length > 40 ? f.indication.substring(0, 40) + "..." : f.indication}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: const Icon(Icons.chevron_right, size: 20),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FormulaDetailScreen(formula: f),
                              ),
                            ),
                          )),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content, ColorScheme cs) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
