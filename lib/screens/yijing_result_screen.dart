import 'package:flutter/material.dart';
import '../engine/yijing_engine.dart';
import 'yijing_detail_screen.dart';

/// 解卦结果页：本卦 / 动爻 / 变卦 / 互卦
class YiJingResultScreen extends StatelessWidget {
  final CastResult cast;

  const YiJingResultScreen({super.key, required this.cast});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('解卦结果')),
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
                      Text(cast.movingTitle,
                          style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('「${cast.movingText}」',
                      style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: colorScheme.onPrimaryContainer)),
                ],
              ),
            ),
          ),
          if (cast.changed != null) ...[
            const SizedBox(height: 12),
            _ResultCard(
              label: '变卦（${cast.moving}爻动）',
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
                            fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(name,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
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
