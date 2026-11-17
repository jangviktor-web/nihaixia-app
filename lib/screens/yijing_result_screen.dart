import 'package:flutter/material.dart';
import '../engine/yijing_engine.dart';
import '../services/classic_search_service.dart';
import 'yijing_detail_screen.dart';
import 'llm_ask_screen.dart';

/// 解卦结果页：本卦 / 动爻 / 变卦 / 互卦
class YiJingResultScreen extends StatelessWidget {
  final CastResult cast;

  const YiJingResultScreen({super.key, required this.cast});

  /// 卦象摘要：本地引擎已排出本卦/动爻/变卦/互卦，
  /// 并附《天纪·人间道》原文，模型只解读、不重算。
  String _digest() {
    final b = StringBuffer()
      ..writeln('起卦法：${cast.method}')
      ..writeln('本卦：第${cast.primary.seq}卦 ${cast.primary.name}｜'
          '卦辞：${cast.primary.judgement}');
    if (cast.movingLines.isEmpty) {
      b.writeln('动爻：六爻皆静');
    } else {
      b.writeln('动爻：${cast.movingTitles.join('、')}');
      b.writeln('动爻爻辞：${cast.movingTexts.join('；')}');
    }
    final changed = cast.changed;
    if (changed != null) {
      b.writeln('变卦：第${changed.seq}卦 ${changed.name}｜卦辞：${changed.judgement}');
    }
    final nuclear = cast.nuclear;
    if (nuclear != null) {
      b.writeln('互卦：第${nuclear.seq}卦 ${nuclear.name}');
    }
    b.writeln('本卦《天纪·人间道》：${cast.primary.renjian}');
    return b.toString().trim();
  }

  void _askNishi(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LlmAskScreen(
          prefill: '请按倪师天纪的思路解这一卦：本卦与变卦的吉凶、'
              '动爻的提示，以及人间道上的应对。',
          seedHits: [
            ClassicHit(
              source: 'yijing',
              sourceLabel: '易经卦象（本地起卦结果）',
              title: '本卦动爻与变卦',
              snippet: _digest(),
            ),
          ],
          // 卦名定位到该卦，「卦」「爻」把讲义理的片段排前
          seedQuery: '${cast.primary.name} 卦 爻',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('解卦结果'),
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined),
            tooltip: '请倪师解此卦',
            onPressed: () => _askNishi(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Text(cast.method,
                textAlign: TextAlign.center,
                style: TextStyle(color: colorScheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 16),
          // 本卦
          _ResultCard(
            label: '本卦',
            symbol: cast.primarySymbol,
            name: '第${cast.primary.seq}卦 · ${cast.primary.name}',
            body: '「${cast.primary.judgement}」',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => YiJingHexagramDetailScreen(
                    hex: cast.primary, highlightLine: cast.moving),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 动爻
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.flag, size: 18, color: colorScheme.primary),
                      const SizedBox(width: 6),
                      Text(cast.movingTitles.join('、'),
                          style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (cast.movingLines.isEmpty)
                    Text('「${cast.movingText}」',
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: colorScheme.onPrimaryContainer))
                  else
                    for (var i = 0; i < cast.movingLines.length; i++) ...[
                      if (i > 0) const SizedBox(height: 6),
                      Text(
                        '${cast.movingTitles[i]}：「${cast.movingTexts[i]}」',
                        style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: colorScheme.onPrimaryContainer),
                      ),
                    ],
                ],
              ),
            ),
          ),
          if (cast.changed != null) ...[
            const SizedBox(height: 12),
            _ResultCard(
              label: '变卦（${cast.movingLines.isEmpty ? cast.moving : cast.movingLines.length}爻动）',
              symbol: cast.changedSymbol!,
              name: '第${cast.changed!.seq}卦 · ${cast.changed!.name}',
              body: '「${cast.changed!.judgement}」',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => YiJingHexagramDetailScreen(hex: cast.changed!),
                ),
              ),
            ),
          ],
          if (cast.nuclear != null) ...[
            const SizedBox(height: 12),
            _ResultCard(
              label: '互卦',
              symbol: cast.nuclearSymbol!,
              name: '第${cast.nuclear!.seq}卦 · ${cast.nuclear!.name}',
              body: '「${cast.nuclear!.judgement}」',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => YiJingHexagramDetailScreen(hex: cast.nuclear!),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            '解卦提示：静卦以卦辞为主断；有动爻以动爻之辞为主断，兼看本卦卦辞与变卦卦辞。'
            '卦辞/爻辞为通行本《周易》原文；人事应用出自倪海厦《天纪·人间道》。',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: colorScheme.outline, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label;
  final String symbol;
  final String name;
  final String body;
  final VoidCallback onTap;

  const _ResultCard({
    required this.label,
    required this.symbol,
    required this.name,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(symbol, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(body, style: const TextStyle(height: 1.5)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
