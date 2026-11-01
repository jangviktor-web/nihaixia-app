import 'package:flutter/material.dart';
import '../widgets/state_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../data/formula_repository.dart';
import '../data/herb_repository.dart';
import '../data/acupoint_repository.dart';
import '../data/zhenjiu_lecture_index.dart';
import 'formula_detail_screen.dart';
import 'herb_detail_screen.dart';
import 'acupoint_detail_screen.dart';

/// 解码 flutter_markdown 传给 `onTapLink` 的 href。
///
/// flutter_markdown 会对链接目标做 percent-encoding：正文里的
/// `[四逆汤](formula://四逆汤)` 传到 `onTapLink` 时变成
/// `formula://%E5%9B%9B%E9%80%86%E6%B1%A4`。不在此解码，查库用的就是编码串，
/// 永远命中不到 → 点击「无任何反应」。
String decodeMarkdownHref(String href) {
  try {
    return Uri.decodeComponent(href);
  } catch (_) {
    return href; // 非法 % 序列：原样返回，不因一个坏链接崩掉整页
  }
}

/// 通用 Markdown 原文阅读页（加载 assets 资源渲染）。
/// 用于倪师《天纪》讲义/案例等原文展示，内容属传统文化参考。
///
/// [linkFormulas] 为真时，运行时将正文中出现的已知方剂名包成 `formula://方名`、
/// 药材名（含别名）包成 `herb://药名` 链接，点击分别跳转 [FormulaDetailScreen] /
/// [HerbDetailScreen]（实现闭门课正文↔方剂/药材双向联动）。
class MarkdownDocScreen extends StatefulWidget {
  final String title;

  /// 资产路径（从 assets 读取正文）。
  final String asset;

  /// 直接传入的 Markdown 正文（古籍原文按章节解析后走这里，无需一章一个资产）。
  /// 与 [asset] 二选一，[content] 优先。
  final String? content;

  final String? footer;
  final bool linkFormulas;

  const MarkdownDocScreen({
    super.key,
    required this.title,
    this.asset = '',
    this.content,
    this.footer,
    this.linkFormulas = false,
  }) : assert(asset != '' || content != null, 'asset 与 content 至少要提供一个');

  @override
  State<MarkdownDocScreen> createState() => _MarkdownDocScreenState();

  /// 构建随主题（含深色模式）生效的 Markdown 样式表。
  ///
  /// 修复背景：`MarkdownStyleSheet.fromTheme()` 有两处**不随主题切换**的硬编码：
  /// - `blockquoteDecoration` 固定 `Colors.blue.shade100`（#BBDEFB 浅蓝底）。深色
  ///   模式下引用块文字取 `textTheme.bodyMedium`（即 `onSurface` 近白 #F0DFD7），
  ///   白字压浅蓝底实测对比度仅 **1.09:1**（WCAG AA 要求 ≥4.5:1）。闭门课正文
  ///   通篇使用 `>` 引用块，故整页正文在深色模式下几乎不可读 —— 这正是
  ///   「标题/正文后面那块蓝色背景」的来源。
  /// - `a` 固定 `Colors.blue`（#2196F3），与品牌色不一致。
  ///
  /// 现全部改为读取 `ColorScheme` 语义色：文字统一 `onSurface`（深色 14.29:1 /
  /// 浅色 16.30:1），引用块底色 `surfaceContainerHighest`（浅色 #F0DFD7 / 深色
  /// #3D332D），并用一条 `primary` 竖线保留引用语义，蓝色块整体移除。
  static MarkdownStyleSheet styleSheetFor(ThemeData theme) {
    final cs = theme.colorScheme;
    final body =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final bodySize = body.fontSize ?? 14;
    final tt = theme.textTheme;
    return MarkdownStyleSheet(
      a: TextStyle(color: cs.primary, decoration: TextDecoration.underline),
      p: body.copyWith(color: cs.onSurface, fontSize: 14, height: 1.7),
      pPadding: EdgeInsets.zero,
      code: body.copyWith(
        color: cs.onSurface,
        backgroundColor: cs.surfaceContainerHighest,
        fontFamily: 'monospace',
        fontSize: bodySize * 0.85,
      ),
      h1: (tt.headlineSmall ?? const TextStyle(fontSize: 24))
          .copyWith(color: cs.onSurface),
      h1Padding: EdgeInsets.zero,
      h2: (tt.titleLarge ?? const TextStyle(fontSize: 22))
          .copyWith(color: cs.onSurface),
      h2Padding: EdgeInsets.zero,
      h3: (tt.titleMedium ?? const TextStyle(fontSize: 16))
          .copyWith(color: cs.onSurface),
      h3Padding: EdgeInsets.zero,
      h4: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
          .copyWith(color: cs.primary),
      h4Padding: EdgeInsets.zero,
      h5: (tt.bodyLarge ?? const TextStyle(fontSize: 16))
          .copyWith(color: cs.onSurface),
      h5Padding: EdgeInsets.zero,
      h6: (tt.bodyLarge ?? const TextStyle(fontSize: 16))
          .copyWith(color: cs.onSurface),
      h6Padding: EdgeInsets.zero,
      em: const TextStyle(fontStyle: FontStyle.italic),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      del: const TextStyle(decoration: TextDecoration.lineThrough),
      blockquote:
          body.copyWith(color: cs.onSurface, fontSize: 14, height: 1.7),
      img: body.copyWith(color: cs.onSurface),
      checkbox: body.copyWith(color: cs.primary),
      blockSpacing: 8.0,
      listIndent: 24.0,
      listBullet: body.copyWith(color: cs.onSurface),
      listBulletPadding: const EdgeInsets.only(right: 4),
      tableHead: (tt.bodyMedium ?? body)
          .copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
      tableBody: body.copyWith(color: cs.onSurface),
      tableHeadAlign: TextAlign.center,
      tablePadding: const EdgeInsets.only(bottom: 4.0),
      tableBorder: TableBorder.all(color: cs.outlineVariant),
      tableColumnWidth: const FlexColumnWidth(),
      tableCellsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      tableCellsDecoration: const BoxDecoration(),
      blockquotePadding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      blockquoteDecoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius:
            const BorderRadius.horizontal(right: Radius.circular(4)),
        border: Border(left: BorderSide(color: cs.primary, width: 3)),
      ),
      codeblockPadding: const EdgeInsets.all(8.0),
      codeblockDecoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4.0),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(width: 1.0, color: cs.outlineVariant)),
      ),
    );
  }

  /// 便捷入口：从 [BuildContext] 取主题后构建样式表。
  static MarkdownStyleSheet buildStyleSheet(BuildContext context) =>
      styleSheetFor(Theme.of(context));
}

class _MarkdownDocScreenState extends State<MarkdownDocScreen> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<String> _load() async {
    final raw = widget.content ?? await rootBundle.loadString(widget.asset);
    return widget.linkFormulas ? _injectLinks(raw) : raw;
  }

  void _reload() {
    setState(() => _future = _load());
  }

  /// 将正文中的已知方剂名、药材名（含别名）、穴位名（含排除名单）包成链接，
  /// 点击分别跳方剂 / 药材 / 穴位详情。
  /// 三类合并为单一候选集、长度降序、单次非重叠扫描，避免嵌套/二次包裹。
  String _injectLinks(String md) {
    final formulaNames = FormulaRepository.getAll()
        .map((f) => f.name)
        .where((n) => n.length >= 2)
        .toList();
    final herbCandidates = <String>{
      ...HerbRepository.getAll().map((h) => h.name),
      ...HerbRepository.aliasNames,
    }.where((n) => n.length >= 2).toList();

    // 穴位候选：仓库正名去「穴」后缀 + 短名映射（子宫→子宫穴），
    // 应用讲稿排除名单（太阳/光明——详见 zhenjiu_lecture_index）。
    final shortForm = AcupointRepository.kShortNameLinkForm;
    final excluded = ZhenJiuLectureIndex.cachedExcluded ??
        ZhenJiuLectureIndex.kFallbackExcluded.toSet();
    final acupointCandidates = AcupointRepository.allNames
        .map((n) => shortForm[n] ?? n)
        .where((n) => n.length >= 2 && !excluded.contains(n.replaceAll('穴', '')))
        .toList();

    // 名称 → 链接类型；方剂优先（同名时 formula 生效，herb/acupoint 的 putIfAbsent 不覆盖）。
    final targetOf = <String, String>{};
    for (final n in formulaNames) {
      targetOf.putIfAbsent(n, () => 'formula');
    }
    for (final n in herbCandidates) {
      targetOf.putIfAbsent(n, () => 'herb');
    }
    for (final n in acupointCandidates) {
      targetOf.putIfAbsent(n, () => 'acupoint');
    }
    if (targetOf.isEmpty) return md;

    final sorted = targetOf.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final re = RegExp(sorted.map(RegExp.escape).join('|'));
    return md.replaceAllMapped(re, (m) {
      final name = m.group(0)!;
      final type = targetOf[name]!;
      return '[$name]($type://$name)';
    });
  }

  void _onTapLink(String? href) {
    if (href == null) return;
    if (href.startsWith('formula://')) {
      final name = decodeMarkdownHref(href.substring('formula://'.length));
      final formula = FormulaRepository.getByName(name);
      if (formula != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => FormulaDetailScreen(formula: formula)),
        );
      }
    } else if (href.startsWith('acupoint://')) {
      final name = decodeMarkdownHref(href.substring('acupoint://'.length));
      final acupoint = AcupointRepository.findByName(name);
      if (acupoint != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AcupointDetailScreen(acupoint: acupoint)),
        );
      }
    } else if (href.startsWith('herb://')) {
      final name = decodeMarkdownHref(href.substring('herb://'.length));
      // 精确 + 别名归一（无模糊兜底），避免「柴胡」误跳到含柴胡的方剂。
      final herb = HerbRepository.getExactByName(name);
      if (herb != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HerbDetailScreen(herb: herb)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<String>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: StateView.loading());
          }
          if (snapshot.hasError) {
            return Center(
              child: StateView.error(
                title: '原文加载失败',
                message: snapshot.error.toString(),
                onRetry: _reload,
              ),
            );
          }
          return Column(
            children: [
              Expanded(
                child: Markdown(
                  data: snapshot.data ?? '',
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  selectable: true,
                  onTapLink: (text, href, title) => _onTapLink(href),
                  styleSheet: MarkdownDocScreen.buildStyleSheet(context),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Text(
                    widget.footer ?? '倪师《天纪》原文 · 传统文化参考 · 非医疗建议',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
