import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../data/ziwei_case_data.dart';

/// 倪师《天纪》紫微斗数原文阅读页（Markdown 渲染）。
/// 内容为倪师口述讲解，作为排盘结果补充，属民俗文化参考。
class ZiweiDocScreen extends StatefulWidget {
  final ZiweiCaseEntry entry;

  const ZiweiDocScreen({super.key, required this.entry});

  @override
  State<ZiweiDocScreen> createState() => _ZiweiDocScreenState();
}

class _ZiweiDocScreenState extends State<ZiweiDocScreen> {
  late Future<String> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<String> _load() async {
    try {
      return await rootBundle.loadString(widget.entry.asset);
    } catch (e) {
      return '（原文加载失败：$e）';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(widget.entry.title)),
      body: FutureBuilder<String>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final text = snapshot.data ?? '';
          return Column(
            children: [
              Expanded(
                child: Markdown(
                  data: text,
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
                    '倪师《天纪·天机道》原文 · 民俗文化参考 · 非医疗建议',
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
