import 'package:flutter/material.dart';

import '../services/lunar_almanac_service.dart';

/// 每日黄历页面的卡片组件集合。
///
/// 从 `daily_almanac_screen.dart` 拆出，使页面文件只保留手势判定与状态编排，
/// 单文件行数受控（P0）。颜色一律取自 [ColorScheme] 语义 token，
/// 图标一律使用 Material Icons，不使用 emoji。

/// 顶部手势提示条：说明左右滑可切换日期。
class AlmanacSwipeHint extends StatelessWidget {
  const AlmanacSwipeHint({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.swipe, size: 14, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '左/右滑切换前一天 / 后一天（亦可用右上角日期按钮）',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// 口径声明条：黄历内容属民俗文化参考，非行事指令。
class AlmanacDisclaimer extends StatelessWidget {
  const AlmanacDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
              '黄历内容属民俗文化参考，宜忌冲煞仅为传统通胜口径，非行事指令。',
              style: TextStyle(fontSize: 12, color: cs.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// 日期头卡片：公历日期 / 星期、农历、年柱月柱日柱，右侧挂节气或节日标签。
class AlmanacDateHeader extends StatelessWidget {
  const AlmanacDateHeader({super.key, required this.almanac});

  final AlmanacDay almanac;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tagText = almanac.solarTerm ??
        (almanac.festivals.isNotEmpty ? almanac.festivals.first : null);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${almanac.solar.year}年${almanac.solar.month}月'
                    '${almanac.solar.day}日 · 周${almanac.weekdayName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    almanac.lunarText,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '年柱 ${almanac.ganzhiYear} · 月柱 ${almanac.ganzhiMonth}'
                    ' · 日柱 ${almanac.ganzhiDay}',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (tagText != null)
              _AlmanacTag(
                text: tagText,
                color: almanac.solarTerm != null ? cs.primary : cs.secondary,
              ),
          ],
        ),
      ),
    );
  }
}

/// 建除十二神卡片（大字展示值神 + 冲煞）。
class AlmanacJianChuCard extends StatelessWidget {
  const AlmanacJianChuCard({super.key, required this.almanac});

  final AlmanacDay almanac;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                almanac.jianChu,
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '建除十二神',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${almanac.jianChu}日 · ${almanac.chong} · ${almanac.sha}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 彭祖百忌卡片（天干忌 + 地支忌两条）。
class AlmanacPengZuCard extends StatelessWidget {
  const AlmanacPengZuCard({super.key, required this.almanac});

  final AlmanacDay almanac;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '彭祖百忌',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...almanac.pengZu.map(
              (p) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Icon(Icons.format_quote, size: 16, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p, style: const TextStyle(fontSize: 13))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 宜 / 忌 通用卡片：[kind] 为「宜」或「忌」，[items] 为条目文案。
class AlmanacYiJiCard extends StatelessWidget {
  const AlmanacYiJiCard({
    super.key,
    required this.kind,
    required this.icon,
    required this.color,
    required this.chipColor,
    required this.items,
  });

  final String kind;
  final IconData icon;
  final Color color;
  final Color chipColor;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  kind,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items
                  .map(
                    (s) => Chip(
                      backgroundColor: chipColor,
                      label: Text(s, style: TextStyle(color: color)),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 节日卡片（含传统 / 法定 / 节气节日）。
class AlmanacFestivalCard extends StatelessWidget {
  const AlmanacFestivalCard({super.key, required this.festivals});

  final List<String> festivals;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.celebration_outlined, size: 18, color: cs.secondary),
                const SizedBox(width: 8),
                const Text(
                  '节日',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: festivals
                  .map(
                    (f) => Chip(
                      backgroundColor: cs.secondaryContainer,
                      label: Text(
                        f,
                        style: TextStyle(color: cs.onSecondaryContainer),
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// 日期头右侧的胶囊标签（节气 / 节日名）。
class _AlmanacTag extends StatelessWidget {
  const _AlmanacTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
