import 'package:flutter/material.dart';

import '../data/medical_case_data.dart';
import 'highlight_spans.dart';

/// 医案列表卡片：标题（#序号+诊断，关键词高亮）+ 患者 / 方药徽标 / 方剂 / 结果
/// + 西医病名徽标（diseaseNames，让「疾病栏」筛出的医案命中关系可见）。
/// 所有文字均显式指定 [ColorScheme] 颜色，避免 [RichText] 因不继承
/// [DefaultTextStyle] 而回退为不可读颜色（如浅色模式下变成白色）。
class MedicalCaseListCard extends StatelessWidget {
  final MedicalCase c;
  final String query;
  final VoidCallback onTap;
  const MedicalCaseListCard({
    super.key,
    required this.c,
    required this.query,
    required this.onTap,
  });

  /// 卡片上最多展示的病名徽标数，超出折叠为 +N。
  static const _maxBadges = 3;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: cs.onSurface,
            ),
            children: [
              TextSpan(text: '#${c.seq}  '),
              ...highlightSpans(
                context,
                c.displayName,
                query,
                TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (c.patient.isNotEmpty)
              RichText(
                text: TextSpan(
                  children: highlightSpans(
                    context,
                    c.patient,
                    query,
                    TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            if (c.diseaseNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 3,
                  children: _diseaseBadges(cs),
                ),
              ),
            if (c.formulaNames.isNotEmpty || c.herbNames.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '${c.formulaNames.length} 方 · ${c.herbNames.length} 药',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              ),
            if (c.formula.isNotEmpty)
              RichText(
                text: TextSpan(
                  children: highlightSpans(
                    context,
                    '方：${_clip(c.formula, 36)}',
                    query,
                    TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
              ),
            if (c.result.isNotEmpty)
              RichText(
                text: TextSpan(
                  children: highlightSpans(
                    context,
                    '效：${_clip(c.result, 36)}',
                    query,
                    TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  /// 西医病名徽标（最多 [_maxBadges] 个，超出折叠为 +N），
  /// 让疾病栏筛出的医案在卡片上可见其病名命中关系。
  List<Widget> _diseaseBadges(ColorScheme cs) {
    final shown = c.diseaseNames.take(_maxBadges).toList();
    final extra = c.diseaseNames.length - shown.length;
    return [
      for (final d in shown)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: cs.secondaryContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            d,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: cs.onSecondaryContainer,
            ),
          ),
        ),
      if (extra > 0)
        Text(
          '+$extra',
          style: TextStyle(fontSize: 10.5, color: cs.onSurfaceVariant),
        ),
    ];
  }

  String _clip(String s, int n) => s.length > n ? '${s.substring(0, n)}…' : s;
}
