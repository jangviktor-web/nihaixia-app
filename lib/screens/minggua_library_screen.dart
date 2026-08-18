import 'package:flutter/material.dart';
import '../data/minggua_data.dart';
import 'markdown_doc_screen.dart';

/// 倪师《天纪·四柱命卦》讲义库浏览页。
class MingGuaLibraryScreen extends StatelessWidget {
  const MingGuaLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final overview = kMingGuaEntries
        .where((e) => e.kind == 'overview')
        .toList();
    final hexes = kMingGuaEntries.where((e) => e.kind == 'hex').toList();
    final supplements = kMingGuaEntries
        .where((e) => e.kind == 'supplement')
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('四柱命卦讲义')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('排法（算法源）'),
          for (final e in overview) _entryTile(context, e),
          const SizedBox(height: 8),
          _SectionHeader('批卦补充'),
          for (final e in supplements) _entryTile(context, e),
          const SizedBox(height: 8),
          _SectionHeader('64 卦 · 先天/后天/值年卦批解'),
          for (final e in hexes) _entryTile(context, e),
          const SizedBox(height: 16),
          Text(
            '内容逐字摘自倪海厦《天纪·四柱命卦》讲义；属传统文化参考，非医疗建议。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: cs.outline, height: 1.6),
          ),
        ],
      ),
    );
  }

  Widget _entryTile(BuildContext context, MingGuaEntry e) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: Text(
          e.seq == 0
              ? '法'
              : e.seq == 65
              ? '补'
              : '第${e.seq}卦',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MarkdownDocScreen(
              title: e.seq == 0 ? '八字的排列方法' : '四柱命卦·${e.title}',
              asset: e.asset,
              footer: '倪师《天纪·四柱命卦》讲义 · 传统文化参考',
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: cs.onSurface,
        ),
      ),
    );
  }
}
