import 'package:flutter/material.dart';

import '../services/bazi_service.dart';
import '../engine/bazi_analysis.dart'
    show BaZiAnalysis, branchHiddenStems;
import '../theme/app_colors.dart';

/// 八字排盘结果卡片组件集合。
///
/// 颜色一律取自 [ColorScheme] 语义 token，图标一律使用 Material Icons，
/// 不使用 emoji；单文件行数受控（P0）。
const List<String> _pillarLabels = ['年', '月', '日', '时'];

/// 四柱卡：年 / 月 / 日 / 时 各列显示干支 + 十神，并单列旬空（空亡）。
class BaZiFourPillarsCard extends StatelessWidget {
  final BaZiPaipan result;
  const BaZiFourPillarsCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bz = result.bazi;
    final pillars = [bz.year, bz.month, bz.day, bz.time];
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '四柱',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (int i = 0; i < 4; i++)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _pillarLabels[i],
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pillars[i],
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          result.tenGods[i],
                          style: TextStyle(fontSize: 11, color: cs.primary),
                        ),
                        const SizedBox(height: 3),
                        // 藏干（如 卯→乙）：与详批引擎同源
                        Text(
                          branchHiddenStems(pillars[i].substring(1, 2)).join(' '),
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        // 纳音（如 甲子→海中金）：sxwnl 权威表
                        Text(
                          nayinOfPillar(pillars[i]),
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.block_outlined, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  '旬空（空亡）',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
                const SizedBox(width: 8),
                Text(
                  result.kongWang.isEmpty ? '无' : result.kongWang.join('、'),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

/// 地支刑冲合害卡：无显著关系时给出提示。
class BaZiRelationsCard extends StatelessWidget {
  final BaZiPaipan result;
  const BaZiRelationsCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rel = result.relations;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '地支刑冲合害',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 8),
            rel.isEmpty
                ? Text(
                    '四柱地支间无明显刑冲合害',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final r in rel)
                        Chip(
                          backgroundColor: cs.secondaryContainer,
                          label: Text(
                            r,
                            style: TextStyle(color: cs.onSecondaryContainer),
                          ),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}

/// 长生十二神卡：以日干起，展示年 / 月 / 日 / 时 四柱所临之运。
class BaZiTwelveStagesCard extends StatelessWidget {
  final BaZiPaipan result;
  const BaZiTwelveStagesCard({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final stages = result.twelveStages;
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '长生十二神（日干起）',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (int i = 0; i < 4; i++)
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          _pillarLabels[i],
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          stages[i],
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '火土同宫 / 水土同宫口径可在输入区切换',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// 八字详批卡：格局 / 日主强弱 / 神煞 / 五行 / 用神忌神。
class BaZiAnalysisCard extends StatelessWidget {
  final BaZiAnalysis analysis;
  const BaZiAnalysisCard({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final a = analysis;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              const Text(
                '八字详批',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '格局 · ${a.pattern}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            a.patternDesc,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _chip(cs, '日主 ${a.dayMaster}', cs.onSurface),
              _chip(cs, a.strengthLevel, _strengthColor(context, level: a.strengthLevel)),
            ],
          ),
          if (a.shensha.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '神煞',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final s in a.shensha)
                  _chip(cs, '${s.name} · ${s.pillar}${s.pos}', cs.primary),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text(
            '五行',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final e in a.fiveElements)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: e.status == '缺'
                          ? cs.surfaceContainerHighest
                          : cs.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Text(
                          e.element,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          e.status,
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '用神',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
              for (final x in a.favorable) _chip(cs, x, context.colors.success),
              Text(
                '忌神',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: cs.error,
                ),
              ),
              for (final x in a.unfavorable) _chip(cs, x, cs.error),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            a.suggestion,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(ColorScheme cs, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color)),
    );
  }

  Color _strengthColor(BuildContext context, {required String level}) {
    switch (level) {
      case '极旺':
      case '身强':
        return context.colors.warning;
      case '极弱':
      case '身弱':
        return context.colors.info;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}
