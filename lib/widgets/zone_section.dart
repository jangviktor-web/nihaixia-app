import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// 工具页分区枚举：通用 / 中医 / 玄学。
enum Zone { general, tcm, metaphysics }

/// 工具页（ToolsScreen）中一组功能卡片的可视化分区容器。
///
/// 每个分区带一个彩色标题（图标 + 文案）与一层轻微着色背景，
/// 使「通用区 / 中医区 / 玄学区」在视觉上彼此独立、层次清晰。
class ZoneSection extends StatelessWidget {
  final Zone zone;
  final String title;
  final IconData icon;
  final List<Widget> children;

  /// 卡片列数。1 表示沿用手机端竖排；>1 时按网格排布（桌面端）。
  final int columns;

  const ZoneSection({
    super.key,
    required this.zone,
    required this.title,
    required this.icon,
    required this.children,
    this.columns = 1,
  });

  /// 根据分区类型返回对应的主题色。
  Color _color(BuildContext context) {
    switch (zone) {
      case Zone.general:
        return Theme.of(context).colorScheme.primary;
      case Zone.tcm:
        return context.colors.tcmZone;
      case Zone.metaphysics:
        return context.colors.metaphysicsZone;
    }
  }

  Widget _layout(int columns) {
    if (columns <= 1) return Column(children: children);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        // 卡片自带 4 的 margin，这里用 4 让视觉间距仍是 12。
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        // 卡片高度约 96 + 内边距，2.9 的比例在 300~420dp 宽度内既不空也不挤。
        childAspectRatio: 2.9,
      ),
      itemCount: children.length,
      itemBuilder: (_, i) => children[i],
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.22)),
          ),
          padding: const EdgeInsets.all(8),
          // 网格列数依赖实际可用宽度（外层已有 PageBody 限宽），不能用整屏宽度算。
          child: LayoutBuilder(
            builder: (context, constraints) => _layout(
              constraints.maxWidth >= 640 ? columns : 1,
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
