import 'package:flutter/material.dart';

import '../services/lunar_almanac_service.dart';
import '../theme/app_colors.dart';

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
        (almanac.festivals.isNotEmpty ? almanac.festivals.first : null) ??
        (almanac.deityFestivals.isNotEmpty ? almanac.deityFestivals.first : null);
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
              Flexible(
                child: _AlmanacTag(
                  text: tagText,
                  color:
                      almanac.solarTerm != null ? cs.primary : cs.secondary,
                ),
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

/// 生肖相冲卡片：当日地支生肖 vs 六冲生肖。
///
/// [userZodiac] 为当前用户本命生肖（由已存命盘推导，可为 null）。
/// 若 [userZodiac] 恰为当日相冲生肖，额外高亮警示「今日冲你本命」。
class AlmanacZodiacChongCard extends StatelessWidget {
  const AlmanacZodiacChongCard({
    super.key,
    required this.almanac,
    this.userZodiac,
  });

  final AlmanacDay almanac;
  final String? userZodiac;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final clashWithUser =
        userZodiac != null && userZodiac == almanac.chongZodiac;
    return Card(
      elevation: 2,
      color: clashWithUser ? cs.errorContainer : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (clashWithUser) ...[
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: 18, color: cs.onErrorContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '今日相冲你的本命生肖（${almanac.chongZodiac}），诸事谨慎',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: cs.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('当日生肖',
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(
                        almanac.dayZodiac,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.sync_alt, size: 22, color: cs.onSurfaceVariant),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('相冲生肖',
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Text(
                        almanac.chongZodiac,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: clashWithUser
                              ? cs.onErrorContainer
                              : cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 通胜要览卡片：黄道吉时 + 财神/喜神/福神方位（《玉匣记》通书通用口诀）。
class AlmanacTongShengCard extends StatelessWidget {
  const AlmanacTongShengCard({super.key, required this.almanac});

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
            Row(
              children: [
                Icon(Icons.auto_awesome_outlined, size: 18, color: cs.tertiary),
                const SizedBox(width: 8),
                const Text(
                  '通胜要览',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Text(
                  '玉匣记通书',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.schedule, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('黄道吉时', style: TextStyle(fontSize: 12)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: almanac.jiShi
                            .map(
                              (s) => Chip(
                                backgroundColor: cs.primaryContainer
                                    .withValues(alpha: 0.5),
                                label: Text(s,
                                    style:
                                        TextStyle(color: cs.onPrimaryContainer)),
                                visualDensity: VisualDensity.compact,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _TongShengRow(
              icon: Icons.account_balance_wallet_outlined,
              label: '财神',
              value: almanac.caiShen,
              color: cs.secondary,
            ),
            _TongShengRow(
              icon: Icons.favorite_outline,
              label: '喜神',
              value: almanac.xiShen,
              color: cs.tertiary,
            ),
            _TongShengRow(
              icon: Icons.stars_outlined,
              label: '福神',
              value: almanac.fuShen,
              color: cs.primary,
            ),
          ],
        ),
      ),
    );
  }
}

/// 通胜要览内的「方位」单行（图标 + 标签 + 值）。
class _TongShengRow extends StatelessWidget {
  const _TongShengRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(label, style: const TextStyle(fontSize: 13)),
          ),
          Text(
            '$value方',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
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

/// 宜 / 忌 合并卡片：左「宜」右「忌」双栏并排，减少纵向滚动（P1）。
class AlmanacYiJiPairCard extends StatelessWidget {
  const AlmanacYiJiPairCard({super.key, required this.yi, required this.ji});

  final List<String> yi;
  final List<String> ji;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _YiJiColumn(
                kind: '宜',
                icon: Icons.check_circle_outline,
                color: colors.success,
                chipColor: colors.successContainer.withValues(alpha: 0.5),
                items: yi,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _YiJiColumn(
                kind: '忌',
                icon: Icons.block,
                color: colors.danger,
                chipColor: colors.dangerContainer.withValues(alpha: 0.5),
                items: ji,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 宜/忌单栏：标题行 + 条目 chips。
class _YiJiColumn extends StatelessWidget {
  const _YiJiColumn({
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
    return Column(
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
          spacing: 6,
          runSpacing: 6,
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

/// 神仙节日卡片（《玉匣记》圣诞 / 降临 / 斋期等，固定农历日期）。
class AlmanacDeityFestivalCard extends StatelessWidget {
  const AlmanacDeityFestivalCard({super.key, required this.festivals});

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
                Icon(Icons.temple_buddhist_outlined,
                    size: 18, color: cs.tertiary),
                const SizedBox(width: 8),
                const Text(
                  '神仙节日',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Text(
                  '玉匣记',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
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
                      backgroundColor: cs.tertiaryContainer.withValues(alpha: 0.6),
                      label: Text(
                        f,
                        style: TextStyle(color: cs.onTertiaryContainer),
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

/// 潮汕节俗卡片（神诞/游神/固定拜神日，地方性日期带地域标注）。
class AlmanacChaoshanCard extends StatelessWidget {
  const AlmanacChaoshanCard({super.key, required this.festivals});

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
                Icon(Icons.festival_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                const Text(
                  '潮汕节俗',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 6),
                Text(
                  '潮汕神诞 · 初一十五拜伯公',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
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
                      backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
                      label: Text(
                        f,
                        style: TextStyle(color: cs.onPrimaryContainer),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
