import 'package:flutter/material.dart';

import 'package:nihaisha_app/services/bazi_service.dart';

/// 八字大运 / 流年卡：起运行 + 横向大运步骤条 + 选中步展开 10 流年。
class BaZiFortuneCard extends StatefulWidget {
  final BaZiFortune fortune;

  const BaZiFortuneCard({super.key, required this.fortune});

  @override
  State<BaZiFortuneCard> createState() => _BaZiFortuneCardState();
}

class _BaZiFortuneCardState extends State<BaZiFortuneCard> {
  int? _selected; // 当前展开流年列表的大运步（index）

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = widget.fortune;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  '大运 · 流年',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${f.startAge.toStringAsFixed(1)} 岁起运，交运于 '
              '${f.qiYunTime.year}-${f.qiYunTime.month.toString().padLeft(2, '0')}-'
              '${f.qiYunTime.day.toString().padLeft(2, '0')}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 86,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: f.decades.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final d = f.decades[i];
                  final selected = _selected == d.index;
                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () =>
                        setState(() => _selected = selected ? null : d.index),
                    child: Container(
                      width: 72,
                      decoration: BoxDecoration(
                        color: selected
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? cs.primary : Colors.transparent,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('第${d.index}运',
                              style: TextStyle(
                                  fontSize: 10, color: cs.onSurfaceVariant)),
                          const SizedBox(height: 2),
                          Text(d.ganZhi,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 2),
                          Text('${d.startAge}–${d.endAge}岁',
                              style: TextStyle(
                                  fontSize: 10, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_selected != null) ...[
              const SizedBox(height: 8),
              _buildFlowYears(cs),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFlowYears(ColorScheme cs) {
    final d = widget.fortune.decades.firstWhere((x) => x.index == _selected);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('第${d.index}运 ${d.ganZhi} · 流年',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              for (final y in d.years)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${y.year} ${y.ganZhi}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
