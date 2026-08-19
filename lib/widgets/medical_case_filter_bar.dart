import 'package:flutter/material.dart';

/// 医案库筛选行：年份 / 治法(经方方剂名) / 疾病(西医病名) / 视图 四组横向 FilterChip。
/// 值与显示文案分离（[labels]），供收藏/最近浏览使用机器值 'fav'/'recent'。
class MedicalCaseFilterBar extends StatelessWidget {
  final List<String> years;
  final List<String> formulas; // 治法栏：经方方剂名分类（含「其他治法」哨兵）
  final List<String> diseases; // 疾病栏：西医病名分类（含「其他疾病」哨兵）
  final String? year; // null = 全部
  final String? formula; // null = 全部
  final String? disease; // null = 全部
  final String? view; // null=全部 | 'fav'=收藏 | 'recent'=最近浏览
  final ValueChanged<String?> onYearChanged;
  final ValueChanged<String?> onFormulaChanged;
  final ValueChanged<String?> onDiseaseChanged;
  final ValueChanged<String?> onViewChanged;

  const MedicalCaseFilterBar({
    super.key,
    required this.years,
    required this.formulas,
    required this.diseases,
    required this.year,
    required this.formula,
    required this.disease,
    required this.view,
    required this.onYearChanged,
    required this.onFormulaChanged,
    required this.onDiseaseChanged,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _chipRow(
            context,
            label: '年份',
            options: years,
            selected: year,
            onChanged: onYearChanged,
          ),
          if (formulas.isNotEmpty)
            _chipRow(
              context,
              label: '治法',
              options: formulas,
              selected: formula,
              onChanged: onFormulaChanged,
            ),
          if (diseases.isNotEmpty)
            _chipRow(
              context,
              label: '疾病',
              options: diseases,
              selected: disease,
              onChanged: onDiseaseChanged,
            ),
          _chipRow(
            context,
            label: '视图',
            options: const ['fav', 'recent'],
            labels: const {'fav': '收藏', 'recent': '最近浏览'},
            selected: view,
            onChanged: onViewChanged,
          ),
        ],
      ),
    );
  }

  /// 横向 FilterChip 行（含「全部」）。
  Widget _chipRow(
    BuildContext context, {
    required String label,
    required List<String> options,
    Map<String, String>? labels,
    required String? selected,
    required ValueChanged<String?> onChanged,
  }) {
    final labelColor = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 38,
            child: Text(
              label,
              style: TextStyle(fontSize: 11, color: labelColor),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _chip('全部', selected == null, () => onChanged(null)),
                  for (final o in options) ...[
                    const SizedBox(width: 6),
                    _chip(labels?[o] ?? o, selected == o, () => onChanged(o)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
