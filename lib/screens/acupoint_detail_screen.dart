import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/acupoint_detail.dart';
import '../models/bookmark.dart';
import '../data/acupoint_repository.dart';
import '../data/database_helper.dart';
import '../data/acupuncture_repository.dart';
import '../data/guji_data.dart';
import '../data/zhenjiu_lecture_index.dart';
import '../models/acupuncture.dart';
import '../theme/app_colors.dart';
import 'guji_library_screen.dart';
import 'markdown_doc_screen.dart';

/// 判断处方/透针中的某个穴名（可能含「透」「、」组合或「穴」后缀）是否命中目标穴。
bool _nameMatches(String container, String target) {
  final t = target.replaceAll('穴', '');
  final parts = container
      .split(RegExp(r'[透、]'))
      .map((e) => e.trim().replaceAll('穴', ''))
      .where((e) => e.isNotEmpty)
      .toList();
  return parts.contains(t);
}

class AcupointDetailScreen extends StatefulWidget {
  final AcupointDetail acupoint;

  const AcupointDetailScreen({super.key, required this.acupoint});

  @override
  State<AcupointDetailScreen> createState() => _AcupointDetailScreenState();
}

class _AcupointDetailScreenState extends State<AcupointDetailScreen> {
  /// 同经络穴位，顺序沿用 AcupointRepository 的经络内国标穴序
  /// （_sortByMeridianOrder 已排好），filter 后天然有序。
  /// ponytail: 只在进页/换穴时算一次；401 条规模不值得做索引缓存。
  late List<AcupointDetail> _siblings = _buildSiblings();
  late int _index = _indexOf(widget.acupoint.name);

  int _indexOf(String name) {
    final i = _siblings.indexWhere((a) => a.name == name);
    return i < 0 ? 0 : i;
  }

  @override
  void didUpdateWidget(AcupointDetailScreen old) {
    super.didUpdateWidget(old);
    // 同一位置换 acupoint（测试连续 pump、或将来原地替换）时 State 会被复用，
    // 必须重算，否则仍显示上一个穴的标题与正文。
    if (old.acupoint.name != widget.acupoint.name) {
      _siblings = _buildSiblings();
      _index = _indexOf(widget.acupoint.name);
    }
  }

  List<AcupointDetail> _buildSiblings() {
    final same = AcupointRepository.getAll()
        .where((a) => a.meridian == widget.acupoint.meridian)
        .toList();
    if (same.isEmpty) return [widget.acupoint];
    // 传入的实例可能未入库（如测试里手工构造），补进去才能定位到它。
    if (!same.any((a) => a.name == widget.acupoint.name)) {
      same.add(widget.acupoint);
    }
    return same;
  }

  AcupointDetail get acupoint => _siblings[_index];

  /// 左右滑动切换同经络上一穴／下一穴。
  /// 与黄历切换日期同一手法：只认 onHorizontalDragEnd，
  /// 纵向滚动仍归 ListView，不抢手势。
  void _swipe(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= _siblings.length) return;
    setState(() => _index = next);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final acupoint = this.acupoint;
    // 关联数据：反向关联穴位处方/透针
    final relatedEntries = AcupunctureRepository.getEntries()
        .where((e) => e.acupoints.any((a) => _nameMatches(a.name, acupoint.name)))
        .toList();
    final relatedPens = AcupunctureRepository.getPenetrations()
        .where((p) => _nameMatches(p.name, acupoint.name))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(acupoint.name),
        actions: [
          _AcupointBookmarkButton(key: ValueKey(acupoint.name), acupoint: acupoint),
          if (acupoint.meridian.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Chip(
                  label: Text(acupoint.meridian),
                  backgroundColor: colorScheme.primaryContainer,
                  labelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
      body: GestureDetector(
        // ponytail: 与黄历切换日期同一手法——只认横向拖拽结束，
        // 纵向滚动仍归 ListView，互不抢手势。
        onHorizontalDragEnd: (d) {
          final v = d.primaryVelocity ?? 0;
          if (v > 200) _swipe(-1); // 右滑 → 上一穴
          if (v < -200) _swipe(1); // 左滑 → 下一穴
        },
        child: ListView(
        // 换穴后回顶部：key 变化令 ListView 重建，滚动位置归零
        key: ValueKey(acupoint.name),
        padding: const EdgeInsets.all(16),
        children: [
          // 同经络序位提示（本经络只有一穴时不显示）
          if (_siblings.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '第 ${_index + 1}/${_siblings.length} 穴 · 左右滑动切换同经络穴位',
                style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
              ),
            ),
          // 属性标签：attribute 最长 54 字（内关/飞扬），Chip 内 Text 不换行、
          // 窄屏会被裁掉大半；改用可换行容器。
          // ponytail: 纯 Container + Text，不引新组件、不加样式参数。
          if (acupoint.attribute.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: context.colors.infoContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(acupoint.attribute),
              ),
            ),

          // 简介
          if (acupoint.description.isNotEmpty)
            _buildSection(context, '简介', acupoint.description, colorScheme, context.colors),

          // 讲义讲解：针灸讲稿中提及本穴的篇目（索引无命中则不显示）
          _buildLectureEntry(colorScheme),

          // 古籍原文：《针灸大成》《灵枢》中提及本穴的章节
          _buildGujiEntry(context, colorScheme),

          // 位置
          if (acupoint.location.isNotEmpty)
            _buildSection(context, '位置', acupoint.location, colorScheme, context.colors),

          // 针刺
          if (acupoint.needling.isNotEmpty)
            _buildSection(context, '针刺', acupoint.needling, colorScheme, context.colors),

          // 灸法
          if (acupoint.moxibustion.isNotEmpty)
            _buildSection(context, '灸法', acupoint.moxibustion, colorScheme, context.colors),

          // 禁忌
          if (acupoint.contraindication.isNotEmpty)
            _buildSection(context, '禁忌', acupoint.contraindication, colorScheme, context.colors,
                isWarning: true),

          // 倪海厦临床心悟
          if (acupoint.clinicalNotes.isNotEmpty)
            _buildSection(context, '倪海厦临床心悟', acupoint.clinicalNotes, colorScheme, context.colors,
                isHighlight: true),

          // 关联穴位处方（反向：哪些处方用到此穴）
          if (relatedEntries.isNotEmpty)
            _buildRelatedEntriesSection(context, relatedEntries, colorScheme),

          // 关联透针透穴
          if (relatedPens.isNotEmpty)
            _buildRelatedPenetrationSection(context, relatedPens, colorScheme),
        ],
        ),
      ),
    );
  }

  /// 古籍原文：《针灸大成》《灵枢》里提及本穴的章节入口。
  /// ponytail: 点击时才扫章节（GujiRepository 有缓存），不在 build 里预载 421 章。
  Widget _buildGujiEntry(BuildContext context, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(Icons.auto_stories_outlined, color: colorScheme.primary),
        title: const Text('古籍原文', style: TextStyle(fontSize: 15)),
        subtitle: const Text('《针灸大成》《灵枢》中提及本穴的章节',
            style: TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showGujiSheet(context),
      ),
    );
  }

  Future<List<MapEntry<GujiBook, GujiChapter>>> _gujiHits(
      List<String> keys) async {
    final out = <MapEntry<GujiBook, GujiChapter>>[];
    for (final b in kGujiBooks) {
      for (final c in await GujiRepository.chaptersOf(b)) {
        if (keys.any((k) => c.title.contains(k) || c.body.contains(k))) {
          out.add(MapEntry(b, c));
        }
      }
    }
    return out;
  }

  void _showGujiSheet(BuildContext context) {
    final key = acupoint.name.replaceAll('穴', '');
    // 古籍多写「太谿」「绝骨」，按正名查会漏，补上异写形态一起扫
    final keys = [key, ...?AcupointRepository.kAliasForms[key]];
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: FutureBuilder<List<MapEntry<GujiBook, GujiChapter>>>(
          future: _gujiHits(keys),
          builder: (context, snap) {
            final hits = snap.data ?? const <MapEntry<GujiBook, GujiChapter>>[];
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text('${acupoint.name} · 古籍提及',
                      style: Theme.of(sheetCtx)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                if (!snap.hasData && !snap.hasError)
                  const ListTile(title: Text('加载中…')),
                if (snap.hasError)
                  ListTile(title: Text('加载失败：${snap.error}')),
                if (snap.hasData && hits.isEmpty)
                  const ListTile(title: Text('暂无相关章节')),
                for (final e in hits)
                  ListTile(
                    dense: true,
                    title: Text(e.value.title,
                        style: const TextStyle(fontSize: 14)),
                    subtitle: Text('《${e.key.title}》',
                        style: const TextStyle(fontSize: 12)),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => GujiChapterScreen(
                              book: e.key, chapter: e.value),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 讲义讲解：针灸讲稿中提及本穴的篇目入口（索引无命中则不渲染任何内容）。
  Widget _buildLectureEntry(ColorScheme colorScheme) {
    return FutureBuilder<ZhenJiuLectureIndex>(
      future: ZhenJiuLectureIndex.load(),
      builder: (context, snap) {
        final hits = snap.data?.hitsFor(acupoint.name) ?? const [];
        if (hits.isEmpty) return const SizedBox.shrink();
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(Icons.menu_book_outlined, color: colorScheme.primary),
            title: const Text('讲义讲解', style: TextStyle(fontSize: 15)),
            subtitle: Text(
              '倪师针灸讲稿中 ${hits.length} 篇提及本穴',
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showLectureSheet(context, hits, colorScheme),
          ),
        );
      },
    );
  }

  void _showLectureSheet(
      BuildContext context, List<LectureHit> hits, ColorScheme colorScheme) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetCtx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                '${acupoint.name} · 讲义提及',
                style: Theme.of(sheetCtx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            for (final h in hits)
              ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    '${h.seq + 1}',
                    style: TextStyle(
                        fontSize: 11, color: colorScheme.onPrimaryContainer),
                  ),
                ),
                title: Text(
                  ZhenJiuLectureIndex.nameOf(h.seq),
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: Text(
                  '提及 ${h.count} 次',
                  style: TextStyle(
                      fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
                onTap: () {
                  final asset = ZhenJiuLectureIndex.assetOf(h.seq);
                  if (asset.isEmpty) return; // seq 越界：数据损坏时不跳转、不崩
                  Navigator.pop(sheetCtx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MarkdownDocScreen(
                        title: ZhenJiuLectureIndex.nameOf(h.seq),
                        asset: asset,
                        linkFormulas: true,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content,
      ColorScheme colorScheme,
      AppColors colors,
      {bool isWarning = false, bool isHighlight = false}) {
    final bgColor = isWarning
        ? colors.dangerContainer
        : isHighlight
            ? colors.infoContainer
            : colors.surfaceContainerHighest;
    final borderColor = isWarning
        ? colors.danger
        : isHighlight
            ? colors.info
            : colors.outlineVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isWarning
                  ? colors.danger
                  : isHighlight
                      ? colorScheme.primary
                      : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            // 2026-11-14：改用 MarkdownBody。原先用纯 Text() 渲染，导致
            // clinicalNotes 里的 **加粗** 在页面上原样显示为裸星号（全库 49 条受影响）。
            // softLineBreak: true 保留数据中用单 \n 分段的原有版式。
            child: MarkdownBody(
              data: content,
              softLineBreak: true,
              selectable: true,
              onTapLink: (_, href, _) => openInternalLink(context, href),
              styleSheet: MarkdownDocScreen.styleSheetFor(Theme.of(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedEntriesSection(BuildContext context,
      List<AcupointEntry> entries, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '关联穴位处方',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '以下穴位处方包含本穴',
            style: TextStyle(fontSize: 12, color: context.colors.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          ...entries.map((e) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.symptom,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: e.source == 'nihaisha'
                                  ? context.colors.warningContainer
                                  : context.colors.infoContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              e.sourceLabel,
                              style: TextStyle(
                                fontSize: 10,
                                color: e.source == 'nihaisha'
                                    ? context.colors.warning
                                    : context.colors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: e.acupoints
                            .expand((a) => a.name.split(RegExp(r'[透、]')))
                            .map((p) => p.trim())
                            .where((p) => p.isNotEmpty)
                            .map((p) => _buildPointChip(context, p))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildRelatedPenetrationSection(BuildContext context,
      List<PenetrationEntry> pens, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '关联透针透穴',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          ...pens.map((p) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (p.indications.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: p.indications
                              .map((ind) => Chip(
                                    label: Text(ind,
                                        style: const TextStyle(fontSize: 10)),
                                    backgroundColor: context.colors.successContainer,
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: p.name
                            .split(RegExp(r'[透、]'))
                            .map((s) => s.trim())
                            .where((s) => s.isNotEmpty && s.length <= 4)
                            .map((s) => _buildPointChip(context, s))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  /// 组成穴 chip：可点按跳转详情；未收录则灰显不可点。
  Widget _buildPointChip(BuildContext context, String name) {
    final detail =
        AcupointRepository.findByName(AcupointRepository.canonicalOf(name));
    if (detail == null) {
      return Chip(
        label: Text(name,
            style: TextStyle(fontSize: 12, color: context.colors.outline)),
        backgroundColor: context.colors.surfaceContainerHighest,
        visualDensity: VisualDensity.compact,
      );
    }
    final isSelf = detail.name == acupoint.name;
    return GestureDetector(
      onTap: isSelf
          ? null
          : () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AcupointDetailScreen(acupoint: detail),
                ),
              );
            },
      child: Chip(
        label: Text(name, style: const TextStyle(fontSize: 12)),
        backgroundColor: isSelf
            ? context.colors.warningContainer
            : context.colors.infoContainer,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// 穴位收藏按钮：复用本草/方剂页同一张 bookmarks 表，避免另起一套存储。
/// ponytail: 独立小 StatefulWidget，主页面保持 StatelessWidget 不动。
class _AcupointBookmarkButton extends StatefulWidget {
  final AcupointDetail acupoint;
  const _AcupointBookmarkButton({super.key, required this.acupoint});

  @override
  State<_AcupointBookmarkButton> createState() =>
      _AcupointBookmarkButtonState();
}

class _AcupointBookmarkButtonState extends State<_AcupointBookmarkButton> {
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    // ponytail: 数据库不可用时按钮保持未收藏态，绝不让详情页整体崩掉。
    () async {
      try {
        final v =
            await DatabaseHelper.instance.isBookmarked(widget.acupoint.name);
        if (mounted) setState(() => _saved = v);
      } catch (_) {}
    }();
  }

  Future<void> _toggle() async {
    final db = DatabaseHelper.instance;
    final a = widget.acupoint;
    try {
      if (_saved) {
        final all = await db.getAllBookmarks();
        for (final b in all) {
          if (b.title == a.name && b.id != null) {
            await db.deleteBookmark(b.id!);
            break;
          }
        }
      } else {
        await db.insertBookmark(Bookmark(
          title: a.name,
          content: a.description.isNotEmpty ? a.description : a.clinicalNotes,
          category: '穴位',
          source: 'acupoint_detail',
        ));
      }
    } catch (_) {
      return; // 数据库不可用：保持原状态，不弹成功提示
    }
    if (!mounted) return;
    setState(() => _saved = !_saved);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_saved ? '已收藏穴位' : '已取消收藏')),
    );
  }

  @override
  Widget build(BuildContext context) => IconButton(
        tooltip: _saved ? '取消收藏' : '收藏穴位',
        icon: Icon(_saved ? Icons.bookmark : Icons.bookmark_border),
        onPressed: _toggle,
      );
}
