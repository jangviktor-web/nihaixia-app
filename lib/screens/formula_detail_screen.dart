import 'package:flutter/material.dart';
import '../models/formula.dart';
import '../theme/app_colors.dart';
import '../models/bookmark.dart';
import '../data/database_helper.dart';
import '../data/herb_repository.dart';
import 'herb_detail_screen.dart';

class FormulaDetailScreen extends StatefulWidget {
  final Formula formula;

  const FormulaDetailScreen({super.key, required this.formula});

  @override
  State<FormulaDetailScreen> createState() => _FormulaDetailScreenState();
}

class _FormulaDetailScreenState extends State<FormulaDetailScreen> {
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _checkBookmark();
  }

  void _checkBookmark() async {
    final db = DatabaseHelper.instance;
    final bookmarked = await db.isBookmarked(widget.formula.name);
    setState(() => _isBookmarked = bookmarked);
  }

  void _toggleBookmark() async {
    final db = DatabaseHelper.instance;
    if (_isBookmarked) {
      final bookmarks = await db.getAllBookmarks();
      final match = bookmarks.firstWhere(
        (b) => b.title == widget.formula.name,
        orElse: () => Bookmark(title: '', content: '', category: '', source: ''),
      );
      if (match.id != null) {
        await db.deleteBookmark(match.id!);
      }
    } else {
      await db.insertBookmark(Bookmark(
        title: widget.formula.name,
        content: _buildBookmarkContent(),
        category: '方剂',
        source: 'formula_detail',
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
    final f = widget.formula;
    return '${f.name} (${f.meridian})\n'
        '${f.indication}\n\n'
        '组成: ${f.componentsText}\n'
        '${f.explanation}';
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.formula;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(f.name),
        actions: [
          IconButton(
            icon: Icon(
              _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            ),
            onPressed: _toggleBookmark,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                  if (f.alias.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      f.alias,
                      style: TextStyle(
                        fontSize: 14,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _Tag(label: f.meridian, color: cs.tertiary),
                      const SizedBox(width: 8),
                      _Tag(label: f.category, color: cs.secondary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 组成
            _SectionTitle(title: '组成'),
            const SizedBox(height: 8),
            ...f.components.map((c) {
              final herb = HerbRepository.getByName(c.name);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: herb != null
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HerbDetailScreen(herb: herb),
                            ),
                          )
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 14,
                                color: cs.onSurface,
                              ),
                              children: [
                                TextSpan(
                                  text: c.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: herb != null ? cs.primary : cs.onSurface,
                                    decoration: herb != null ? TextDecoration.underline : null,
                                  ),
                                ),
                                if (c.dosage.isNotEmpty)
                                  TextSpan(text: '  ${c.dosage}'),
                              ],
                            ),
                          ),
                        ),
                        if (c.role.isNotEmpty)
                          Expanded(
                            child: Text(
                              c.role,
                              style: TextStyle(
                                fontSize: 12,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),

            // 适应证
            _SectionTitle(title: '适应证'),
            const SizedBox(height: 8),
            Text(
              f.indication,
              style: const TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 20),

            // 禁忌
            if (f.contraindication.isNotEmpty) ...[
              _SectionTitle(title: '禁忌'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.dangerContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  f.contraindication,
                  style: TextStyle(
                    fontSize: 14,
                    color: cs.onErrorContainer,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 煎服法
            if (f.dosage.isNotEmpty) ...[
              _SectionTitle(title: '煎服法'),
              const SizedBox(height: 8),
              Text(
                f.dosage,
                style: const TextStyle(fontSize: 14, height: 1.6),
              ),
              const SizedBox(height: 20),
            ],

            // 倪海厦解读
            if (f.explanation.isNotEmpty) ...[
              _SectionTitle(title: '倪海厦解读'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  f.explanation,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: cs.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;
  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
