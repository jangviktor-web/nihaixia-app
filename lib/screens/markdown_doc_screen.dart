import 'package:flutter/material.dart';
import '../widgets/state_view.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../data/formula_repository.dart';
import '../data/herb_repository.dart';
import 'formula_detail_screen.dart';
import 'herb_detail_screen.dart';

/// 通用 Markdown 原文阅读页（加载 assets 资源渲染）。
/// 用于倪师《天纪》讲义/案例等原文展示，内容属传统文化参考。
///
/// [linkFormulas] 为真时，运行时将正文中出现的已知方剂名包成 `formula://方名`、
/// 药材名（含别名）包成 `herb://药名` 链接，点击分别跳转 [FormulaDetailScreen] /
/// [HerbDetailScreen]（实现闭门课正文↔方剂/药材双向联动）。
class MarkdownDocScreen extends StatefulWidget {
  final String title;
  final String asset;
  final String? footer;
  final bool linkFormulas;

  const MarkdownDocScreen({
    super.key,
    required this.title,
    required this.asset,
    this.footer,
    this.linkFormulas = false,
  });

  @override
  State<MarkdownDocScreen> createState() => _MarkdownDocScreenState();
}

class _MarkdownDocScreenState extends State<MarkdownDocScreen> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<String> _load() async {
    final raw = await rootBundle.loadString(widget.asset);
    return widget.linkFormulas ? _injectLinks(raw) : raw;
  }

  void _reload() {
    setState(() => _future = _load());
  }

  /// 将正文中的已知方剂名、药材名（含别名）包成链接，点击分别跳方剂/药材详情。
  /// 方剂 + 药材合并为单一候选集、长度降序、单次非重叠扫描，避免嵌套/二次包裹。
  String _injectLinks(String md) {
    final formulaNames = FormulaRepository.getAll()
        .map((f) => f.name)
        .where((n) => n.length >= 2)
        .toList();
    final herbCandidates = <String>{
      ...HerbRepository.getAll().map((h) => h.name),
      ...HerbRepository.aliasNames,
    }.where((n) => n.length >= 2).toList();

    // 名称 → 链接类型；方剂优先（同名时 formula 生效，herb 的 putIfAbsent 不覆盖）。
    final targetOf = <String, String>{};
    for (final n in formulaNames) {
      targetOf.putIfAbsent(n, () => 'formula');
    }
    for (final n in herbCandidates) {
      targetOf.putIfAbsent(n, () => 'herb');
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
      final name = href.substring('formula://'.length);
      final formula = FormulaRepository.getByName(name);
      if (formula != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => FormulaDetailScreen(formula: formula)),
        );
      }
    } else if (href.startsWith('herb://')) {
      final name = href.substring('herb://'.length);
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
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                        p: const TextStyle(fontSize: 14, height: 1.7),
                        h4: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                        a: TextStyle(
                          color: cs.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  child: Text(
                    widget.footer ?? '倪师《天纪》原文 · 传统文化参考 · 非医疗建议',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 10, color: cs.outline),
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
