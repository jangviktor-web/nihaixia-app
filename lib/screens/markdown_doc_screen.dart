import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../data/formula_repository.dart';
import 'formula_detail_screen.dart';

/// 通用 Markdown 原文阅读页（加载 assets 资源渲染）。
/// 用于倪师《天纪》讲义/案例等原文展示，内容属传统文化参考。
///
/// [linkFormulas] 为真时，运行时将正文中出现的已知方剂名自动包成
/// `formula://方名` 链接，点击可跳转 [FormulaDetailScreen]（实现医案↔方剂联动）。
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
    try {
      final raw = await rootBundle.loadString(widget.asset);
      return widget.linkFormulas ? _injectFormulaLinks(raw) : raw;
    } catch (e) {
      return '（原文加载失败：$e）';
    }
  }

  /// 将正文中的已知方剂名包成 `formula://` 链接（单次最长匹配，避免嵌套）。
  String _injectFormulaLinks(String md) {
    final names = FormulaRepository.getAll()
        .map((f) => f.name)
        .where((n) => n.length >= 2)
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    if (names.isEmpty) return md;
    final pattern = names.map(RegExp.escape).join('|');
    final re = RegExp(pattern);
    return md.replaceAllMapped(
      re,
      (m) => '[${m.group(0)}](formula://${m.group(0)})',
    );
  }

  void _onTapLink(String? href) {
    if (href == null || !href.startsWith('formula://')) return;
    final name = href.substring('formula://'.length);
    final formula = FormulaRepository.getByName(name);
    if (formula != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => FormulaDetailScreen(formula: formula)),
      );
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
            return const Center(child: CircularProgressIndicator());
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
                        p: const TextStyle(fontSize: 15, height: 1.7),
                        h4: TextStyle(
                          fontSize: 18,
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
                    style: TextStyle(fontSize: 11, color: cs.outline),
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
