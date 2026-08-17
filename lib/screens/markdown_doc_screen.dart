import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

/// 通用 Markdown 原文阅读页（加载 assets 资源渲染）。
/// 用于倪师《天纪》讲义/案例等原文展示，内容属传统文化参考。
class MarkdownDocScreen extends StatefulWidget {
  final String title;
  final String asset;
  final String? footer;

  const MarkdownDocScreen({
    super.key,
    required this.title,
    required this.asset,
    this.footer,
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
      return await rootBundle.loadString(widget.asset);
    } catch (e) {
      return '（原文加载失败：$e）';
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
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                      .copyWith(
                        p: const TextStyle(fontSize: 15, height: 1.7),
                        h4: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
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
