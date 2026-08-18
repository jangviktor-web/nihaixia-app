import 'package:flutter/material.dart';
import '../data/ziwei_case_data.dart';
import 'ziwei_doc_screen.dart';

/// 倪师《天纪》紫微斗数案例库 / 十二宫详解 浏览页。
class ZiweiCasesListScreen extends StatelessWidget {
  const ZiweiCasesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('倪师紫微案例与十二宫')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionHeader('十二宫总论'),
          _entryTile(context, kZiweiOverview),
          const SizedBox(height: 8),
          _SectionHeader('紫微十二宫详解（按紫微所在宫）'),
          for (final e in kZiweiPalaceChapters) _entryTile(context, e),
          const SizedBox(height: 8),
          _SectionHeader('案例库（按命宫地支分组）'),
          ..._groupedCases().entries.expand(
            (g) => [
              Padding(
                padding: const EdgeInsets.only(left: 4, top: 8, bottom: 2),
                child: Text(
                  '命宫在「${g.key}」',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ),
              ...g.value.map((e) => _entryTile(context, e)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '内容逐字摘自倪海厦《天纪》紫微斗数案例/十二宫详解原文，'
            '作为排盘结果补充；属民俗文化参考，非医疗建议。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10, color: cs.outline, height: 1.6),
          ),
        ],
      ),
    );
  }

  Map<String, List<ZiweiCaseEntry>> _groupedCases() {
    final map = <String, List<ZiweiCaseEntry>>{};
    for (final e in kZiweiCases) {
      map.putIfAbsent(e.mingBranch, () => []).add(e);
    }
    return map;
  }

  Widget _entryTile(BuildContext context, ZiweiCaseEntry e) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: ListTile(
        dense: true,
        leading: Text(
          e.kind == 'case'
              ? '案${e.id}'
              : e.kind == 'palace'
              ? '章${e.id}'
              : '总',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(e.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          e.asset.split('/').last,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ZiweiDocScreen(entry: e)),
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
