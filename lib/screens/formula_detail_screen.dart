import 'package:flutter/material.dart';
import '../models/formula.dart';
import '../theme/app_colors.dart';
import '../models/bookmark.dart';
import '../widgets/traditional_toggle_button.dart';
import '../data/traditional_display.dart';
import '../data/database_helper.dart';
import '../data/formula_mention_index.dart';
import '../data/herb_repository.dart';
import '../data/classic_lecture_data.dart';
import 'herb_detail_screen.dart';
import 'markdown_doc_screen.dart';

class FormulaDetailScreen extends StatefulWidget {
  final Formula formula;

  const FormulaDetailScreen({super.key, required this.formula});

  @override
  State<FormulaDetailScreen> createState() => _FormulaDetailScreenState();
}

class _FormulaDetailScreenState extends State<FormulaDetailScreen> {

  /// 繁体显示：内容字段进页时一次性转换并缓存（关开关则空表，渲染原样）。
  Map<String, String> _tc = {};
  bool _isBookmarked = false;
  bool _loadingMentions = true;
  List<ClassicLecture> _shanghanHits = [];
  List<ClassicLecture> _jinguiHits = [];
  List<MentionHit> _zhenjiuMentions = [];
  List<MentionHit> _bencaoMentions = [];

  Future<void> _loadTraditional() async {
    if (!traditionalDisplayOn) {
      if (_tc.isNotEmpty && mounted) setState(() => _tc = {});
      return;
    }
    final f = widget.formula;
    final m = await trTexts(<String?>[
      f.indication, f.contraindication, f.dosage, f.explanation,
      ...f.components.map((c) => c.role),
    ]);
    if (mounted && m.isNotEmpty) setState(() => _tc = m);
  }

  String _t(String? s) => s == null ? '' : (_tc[s] ?? s);

  @override
  void initState() {
    super.initState();
    _loadTraditional();
    _checkBookmark();
    _loadMentions();
  }

  void _checkBookmark() async {
    final db = DatabaseHelper.instance;
    final bookmarked = await db.isBookmarked(widget.formula.name);
    if (!mounted) return;
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
    if (mounted) setState(() => _isBookmarked = !_isBookmarked);
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

  /// 「见于经典」+ 讲稿提及：查预生成索引（tool/build_formula_index.py 生成，
  /// 判定与原运行时扫描逐位一致，见脚本 selfcheck）。
  /// 索引缺失/未命中 → 对应分组不渲染，不崩。
  Future<void> _loadMentions() async {
    final idx = await FormulaMentionIndex.load();
    final hits = idx.hitsFor(widget.formula.name);
    if (!mounted) return;
    setState(() {
      _shanghanHits = hits == null
          ? const []
          : hits.shanghan.map((i) => kShangHanLectures[i]).toList();
      _jinguiHits = hits == null
          ? const []
          : hits.jingui.map((i) => kJinguiLectures[i]).toList();
      _zhenjiuMentions = hits?.zhenjiu ?? const [];
      _bencaoMentions = hits?.bencao ?? const [];
      _loadingMentions = false;
    });
  }

  Widget _buildClauseCard(ClassicLecture lec) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(lec.name, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MarkdownDocScreen(
              title: lec.name,
              asset: lec.asset,
              linkFormulas: true,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildBookGroup(String bookName, List<ClassicLecture> hits) {
    final color = Theme.of(context).colorScheme.primary;
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Text(bookName,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ),
      ...hits.map(_buildClauseCard),
    ];
  }

  /// 讲稿提及分组（针灸/本草）：ListTile → MarkdownDocScreen，副标题带提及次数。
  List<Widget> _buildLectureGroup(
      String bookName, List<MentionHit> hits, String Function(int) nameOf,
      String Function(int) assetOf) {
    final color = Theme.of(context).colorScheme.primary;
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 2),
        child: Text(bookName,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
      ),
      ...hits.map((h) => Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              dense: true,
              title: Text(nameOf(h.seq), style: const TextStyle(fontSize: 13)),
              trailing: Text('提及 ${h.count} 次',
                  style: TextStyle(
                      fontSize: 12,
                      color: context.colors.onSurfaceVariant)),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MarkdownDocScreen(
                    title: nameOf(h.seq),
                    asset: assetOf(h.seq),
                    linkFormulas: true,
                  ),
                ),
              ),
            ),
          )),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final f = widget.formula;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(f.name),
        actions: [
          TraditionalToggleButton(
            onChanged: () {
              _loadTraditional();
              setState(() {});
            },
          ),
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
                                  TextSpan(text: '  ${_t(c.dosage)}'),
                              ],
                            ),
                          ),
                        ),
                        if (c.role.isNotEmpty)
                          Expanded(
                            child: Text(
                              _t(c.role),
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
              _t(f.indication),
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
                  _t(f.contraindication),
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
                _t(f.dosage),
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
                  _t(f.explanation),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: cs.onTertiaryContainer,
                  ),
                ),
              ),
            ],

            // 见于经典
            const SizedBox(height: 20),
            _SectionTitle(title: '见于经典'),
            const SizedBox(height: 8),
            if (_loadingMentions)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: CircularProgressIndicator(),
              )
            else if (_shanghanHits.isEmpty &&
                _jinguiHits.isEmpty &&
                _zhenjiuMentions.isEmpty &&
                _bencaoMentions.isEmpty)
              Text('暂未在该模块经典中找到出处',
                  style: TextStyle(fontSize: 13, color: context.colors.onSurfaceVariant))
            else ...[
              if (_shanghanHits.isNotEmpty) ..._buildBookGroup('伤寒论', _shanghanHits),
              if (_jinguiHits.isNotEmpty) ..._buildBookGroup('金匮要略', _jinguiHits),
              if (_zhenjiuMentions.isNotEmpty)
                ..._buildLectureGroup('针灸讲稿', _zhenjiuMentions,
                    FormulaMentionIndex.zhenjiuNameOf, FormulaMentionIndex.zhenjiuAssetOf),
              if (_bencaoMentions.isNotEmpty)
                ..._buildLectureGroup('本草讲稿', _bencaoMentions,
                    FormulaMentionIndex.bencaoNameOf, FormulaMentionIndex.bencaoAssetOf),
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
