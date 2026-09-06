import 'package:flutter/material.dart';

import 'package:nihaisha_app/data/critical_illness_data.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/data/herb_repository.dart';
import 'package:nihaisha_app/data/medical_case_data.dart';
import 'package:nihaisha_app/models/herb.dart';
import 'package:nihaisha_app/screens/formula_detail_screen.dart';
import 'package:nihaisha_app/screens/markdown_doc_screen.dart';
import 'package:nihaisha_app/screens/medical_case_detail_screen.dart';

/// 药物详情页「相关内容」三级结构的中层列表页。
///
/// 第一级：药物详情页入口按钮（见 herb_detail_screen.dart）。
/// 第二级：本文件的三个列表页——仅标题的简洁列表，数据各自独立加载，不含正文。
/// 第三级：各自详情页（MedicalCaseDetailScreen / MarkdownDocScreen /
/// FormulaDetailScreen）。

/// 含此药的医案列表（医案 herbNames 命中本药正名）。
class HerbRelatedCasesScreen extends StatefulWidget {
  final Herb herb;
  const HerbRelatedCasesScreen({super.key, required this.herb});

  @override
  State<HerbRelatedCasesScreen> createState() =>
      _HerbRelatedCasesScreenState();
}

class _HerbRelatedCasesScreenState extends State<HerbRelatedCasesScreen> {
  List<MedicalCase> _cases = const [];
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final all = await getAllMedicalCases();
      if (!mounted) return;
      setState(() {
        _cases = all
            .where((c) => c.herbNames.contains(widget.herb.name))
            .toList();
        _ready = true;
      });
    } catch (_) {
      if (mounted) setState(() => _ready = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('关联医案 · ${widget.herb.name}')),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : _cases.isEmpty
              ? const Center(child: Text('未找到含此药的医案'))
              : ListView.builder(
                  itemCount: _cases.length,
                  itemBuilder: (context, i) {
                    final c = _cases[i];
                    return ListTile(
                      title: Text('#${c.seq}  ${c.displayName}'),
                      trailing: const Icon(Icons.chevron_right, size: 20),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MedicalCaseDetailScreen(c: c),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

/// 含此药的闭门课列表（tags 经 canonicalOf 归一后命中本药正名）。
class HerbRelatedCriticalScreen extends StatelessWidget {
  final Herb herb;
  const HerbRelatedCriticalScreen({super.key, required this.herb});

  @override
  Widget build(BuildContext context) {
    final items = kCriticalIllnesses
        .where((it) => it.tags
            .any((t) => HerbRepository.canonicalOf(t) == herb.name))
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text('关联闭门课 · ${herb.name}')),
      body: items.isEmpty
          ? const Center(child: Text('未找到含此药的闭门课'))
          : ListView(
              children: [
                for (final it in items)
                  ListTile(
                    title: Text(it.title),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MarkdownDocScreen(
                          title: it.title,
                          asset: it.asset,
                          linkFormulas: !it.isOverview,
                          footer: '倪师闭门课重症临床 · 传统文化参考 · 非医疗建议',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

/// 含此药的方剂列表（components 经 canonicalOf 归一后命中本药正名）。
class HerbRelatedFormulasScreen extends StatelessWidget {
  final Herb herb;
  const HerbRelatedFormulasScreen({super.key, required this.herb});

  @override
  Widget build(BuildContext context) {
    final formulas = FormulaRepository.getAll()
        .where((f) => f.components
            .any((c) => HerbRepository.canonicalOf(c.name) == herb.name))
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text('含此药方剂 · ${herb.name}')),
      body: formulas.isEmpty
          ? const Center(child: Text('未找到含此药的方剂'))
          : ListView(
              children: [
                for (final f in formulas)
                  ListTile(
                    title: Text(f.name),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FormulaDetailScreen(formula: f),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
