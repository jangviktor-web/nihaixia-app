import 'package:flutter/material.dart';

import '../data/critical_illness_data.dart';
import '../data/formula_repository.dart';
import '../data/herb_repository.dart';
import 'formula_detail_screen.dart';
import 'herb_detail_screen.dart';
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
                              fontSize: 16,
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
                        fontSize: 12,
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
                                  // 标签既可能是方剂名（四逆汤），也可能是单味药
                                  // （生附子/生硫磺/柴胡/防己）。先用「本草精确命中」
                                  // 判定是否单味药——否则方剂库的模糊兜底会把
                                  // 「柴胡」错跳到含柴胡的方剂上。药材名与方剂名
                                  // 无精确同名冲突，此顺序安全。
                                  final herb =
                                      HerbRepository.getExactByName(t);
                                  if (herb != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            HerbDetailScreen(herb: herb),
                                      ),
                                    );
                                    return;
                                  }
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
