import 'package:flutter/material.dart';

import '../data/critical_illness_data.dart';
import '../data/formula_repository.dart';
import 'formula_detail_screen.dart';
import 'markdown_doc_screen.dart';

/// 倪师闭门课·七大重症临床 列表页。
/// 点按进入对应 markdown 原文（方剂名自动可点跳转）。
class CriticalIllnessListScreen extends StatelessWidget {
  const CriticalIllnessListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('闭门课 · 重症临床')),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: kCriticalIllnesses.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = kCriticalIllnesses[index];
          return Card(
            elevation: 2,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MarkdownDocScreen(
                    title: item.title,
                    asset: item.asset,
                    linkFormulas: !item.isOverview,
                    footer: '倪师闭门课重症临床 · 传统文化参考 · 非医疗建议',
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          item.isOverview
                              ? Icons.menu_book
                              : Icons.medical_information,
                          color: item.isOverview ? cs.outline : cs.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (item.tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: item.tags
                            .map(
                              (t) => ActionChip(
                                label: Text(t,
                                    style: const TextStyle(fontSize: 12)),
                                backgroundColor: cs.primaryContainer
                                    .withValues(alpha: 0.5),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                onPressed: () {
                                  final formula =
                                      FormulaRepository.getByName(t);
                                  if (formula != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => FormulaDetailScreen(
                                            formula: formula),
                                      ),
                                    );
                                  }
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
