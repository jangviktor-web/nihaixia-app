import 'package:flutter/material.dart';
import '../models/formula_oral_hint.dart';

/// 「患者会怎么说」卡片：把方剂的患者口语描述、辨证指针与治法一并呈现，
/// 让辨证结果可解释——用户能直接对照「这话像不像我说的」，而不是只看到
/// 一条古文条文。
///
/// 语料中 [FormulaOralHint.oral] 为空时不渲染任何节点，避免出现空卡片
/// （语料只覆盖 170 首方，其余方剂不应显示空壳）。
class OralHintCard extends StatelessWidget {
  final FormulaOralHint hint;

  const OralHintCard({super.key, required this.hint});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (hint.oral.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Header(icon: Icons.record_voice_over, label: '患者会怎么说', cs: cs),
          const SizedBox(height: 6),
          Text(
            hint.oral,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: cs.onSurface,
            ),
          ),
          if (hint.indicatorPhrases.isNotEmpty) ...[
            const SizedBox(height: 10),
            _Header(icon: Icons.fact_check_outlined, label: '辨证指针', cs: cs),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final phrase in hint.indicatorPhrases)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      phrase,
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (hint.treatment.isNotEmpty) ...[
            const SizedBox(height: 10),
            _Header(icon: Icons.healing_outlined, label: '治法', cs: cs),
            const SizedBox(height: 6),
            Text(
              hint.treatment,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 卡片内的小节标题：统一描边图标 + 12px 说明文字，不使用 emoji。
class _Header extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme cs;

  const _Header({required this.icon, required this.label, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: cs.primary),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: cs.primary,
          ),
        ),
      ],
    );
  }
}
