import 'package:flutter/material.dart';
import '../data/yijing_data.dart';
import '../data/yijing_lecture_data.dart';
import '../data/minggua_data.dart';
import '../engine/yijing_engine.dart';
import 'markdown_doc_screen.dart';

/// 单卦详情页：卦符 / 卦辞 / 倪师人间道 / 六爻爻辞
class YiJingHexagramDetailScreen extends StatelessWidget {
  final Hexagram hex;
  final int highlightLine; // 0 = 不高亮

  const YiJingHexagramDetailScreen({
    super.key,
    required this.hex,
    this.highlightLine = 0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final upper = kTrigrams[hex.upper];
    final lower = kTrigrams[hex.lower];
    final lines = YiJingEngine.linesOf(hex);

    return Scaffold(
      appBar: AppBar(title: Text('第${hex.seq}卦 · ${hex.name}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 卦符 + 卦名
          Center(
            child: Column(
              children: [
                Text(
                  YiJingEngine.symbol(hex.seq),
                  style: const TextStyle(fontSize: 96),
                ),
                const SizedBox(height: 8),
                Text(
                  hex.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '上${upper.name}${upper.symbol}（${upper.nature}）· 下${lower.name}${lower.symbol}（${lower.nature}）',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 卦辞
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '卦辞',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '「${hex.judgement}」',
                    style: const TextStyle(fontSize: 16, height: 1.6),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 倪师人间道
          Card(
            color: colorScheme.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '倪师《天纪·人间道》',
                    style: TextStyle(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hex.renjian,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: colorScheme.onTertiaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 倪师《人间道》讲课文稿入口
          if (yijingLectureAsset(hex.seq) case final asset?) ...[
            Card(
              color: colorScheme.surfaceContainerHighest,
              child: ListTile(
                leading: Icon(
                  Icons.record_voice_over,
                  color: colorScheme.primary,
                ),
                title: const Text(
                  '倪师《天纪·人间道》讲课文稿',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('阅读倪师对本卦的完整讲义'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MarkdownDocScreen(
                      title: '第${hex.seq}卦 · ${hex.name} · 倪师《人间道》',
                      asset: asset,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 12),
          // 倪师《四柱命卦》讲义入口
          if (mingGuaLectureAsset(hex.seq) case final mgAsset?) ...[
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.calculate_outlined,
                  color: colorScheme.secondary,
                ),
                title: const Text(
                  '倪师《天纪·四柱命卦》讲义',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('此卦作为先天/后天/值年卦的批解'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MarkdownDocScreen(
                      title: '四柱命卦·${hex.name}',
                      asset: mgAsset,
                      footer: '倪师《天纪·四柱命卦》讲义 · 传统文化参考',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          // 六爻
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '六爻爻辞（自下而上）',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < 6; i++) ...[
                    _LineTile(
                      title: YiJingEngine.lineTitle(i + 1, lines[i] == 1),
                      text: hex.lines[i],
                      yang: lines[i] == 1,
                      highlight: highlightLine == i + 1,
                    ),
                    if (i < 5) const Divider(height: 12),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '卦辞/爻辞：通行本《周易》原文 · 人事应用：倪海厦《天纪·人间道》',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: colorScheme.outline),
          ),
        ],
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  final String title;
  final String text;
  final bool yang;
  final bool highlight;

  const _LineTile({
    required this.title,
    required this.text,
    required this.yang,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight ? colorScheme.primaryContainer : null,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: yang
                  ? colorScheme.primary.withValues(alpha: 0.15)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: yang ? colorScheme.primary : null,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(height: 1.5))),
          if (highlight) Icon(Icons.flag, size: 16, color: colorScheme.primary),
        ],
      ),
    );
  }
}
