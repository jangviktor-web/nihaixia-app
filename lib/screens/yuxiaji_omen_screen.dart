import 'package:flutter/material.dart';

import '../data/yuxiaji_omen_data.dart';

/// 十二时辰 → 索引（0=子 … 11=亥）。
///
/// 时辰从 23:00 起每两小时一换：23-0 时为子、1-2 为丑……纯函数便于单测。
int shiChenIndexOf(DateTime t) => ((t.hour + 1) ~/ 2) % 12;

/// 时辰索引 → 显示标签（含钟表区间）。
String shiChenLabel(int index) {
  const names = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];
  final start = (index * 2 + 23) % 24;
  final startLabel = '$start:00'.padLeft(5, '0');
  final endHour = (start + 2) % 24;
  final endLabel = endHour == 1 ? '00:59' : '${endHour - 1}:59';
  return '${names[index]}时 $startLabel–$endLabel';
}

/// 玉匣灵兆 —— 《玉匣记》杂占篇·身体兆占。
///
/// 面热/眼跳/耳鸣/心惊等十二时辰占法 + 鸦鸣鹊噪/占灯花特殊占法。
/// 属民俗文化参考，非吉凶指令。
class YuxiajiOmenScreen extends StatefulWidget {
  const YuxiajiOmenScreen({super.key});

  @override
  State<YuxiajiOmenScreen> createState() => _YuxiajiOmenScreenState();
}

class _YuxiajiOmenScreenState extends State<YuxiajiOmenScreen> {
  final int _hourIndex = shiChenIndexOf(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('玉匣灵兆')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildDisclaimer(cs),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 18, color: cs.primary),
              const SizedBox(width: 8),
              const Text(
                '十二时辰身兆占',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '当前 ${shiChenLabel(_hourIndex)}',
                style: TextStyle(fontSize: 12, color: cs.primary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...kYuXiaJiShiChenOmens.map(_buildOmenCard),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.flare, size: 18, color: cs.tertiary),
              const SizedBox(width: 8),
              const Text(
                '特殊兆占',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...kYuXiaJiSpecialOmens.map(_buildSpecialCard),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.tertiaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: cs.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '《玉匣记》杂占篇 · 身体兆占。属民俗文化参考，非吉凶指令。',
              style: TextStyle(fontSize: 12, color: cs.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOmenCard(ShiChenOmen omen) {
    final cs = Theme.of(context).colorScheme;
    final current = omen.duanByHour[_hourIndex];
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    omen.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  omen.target,
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shiChenLabel(_hourIndex),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(current, style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                title: Text(
                  '十二时辰详表',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                children: [
                  ...List.generate(12, (i) {
                    final isNow = i == _hourIndex;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 118,
                            child: Text(
                              shiChenLabel(i),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    isNow ? FontWeight.bold : FontWeight.normal,
                                color: isNow ? cs.primary : cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              omen.duanByHour[i],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    isNow ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialCard(OmenSpecial s) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              s.target,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            SelectableText(
              s.body,
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
