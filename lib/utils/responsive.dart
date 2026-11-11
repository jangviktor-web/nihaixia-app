import 'package:flutter/material.dart';

/// 断点：与 Material 的 compact / medium / expanded 三档对齐。
///
/// 手机竖屏 ≈ compact；平板竖屏、分屏 ≈ medium；平板横屏与桌面浏览器 ≈ expanded。
/// 列表页只在 ≥ [expanded]（840dp）时切大屏布局，中间档仍按手机布局渲染，
/// 只是把内容限制在可读宽度内。
abstract final class Breakpoints {
  static const double medium = 600;
  static const double expanded = 840;

  /// 超过此宽度视为「桌面级」视口：切侧边导航 + 多列网格。
  static const double sidebar = 1000;
}

/// 按**内容区**宽度（已扣掉侧边导航等占位）在若干候选列数中取一档。
///
/// 直接用视口宽度会在宽屏导航栏旁边再多算一列，卡片被挤成窄条，
/// 所以列数一律由 LayoutBuilder 拿到的实际宽度算。
int computeColumns(
  double contentWidth, {
  required List<int> candidates,
  double minTileWidth = 300,
}) {
  for (final c in candidates) {
    if (contentWidth / c >= minTileWidth) return c;
  }
  return candidates.last;
}

extension ResponsiveContext on BuildContext {
  /// 当前视口宽度（已含浏览器缩放与系统文字/显示缩放）。
  double get viewportWidth => MediaQuery.sizeOf(this).width;

  /// 是否使用宽屏布局（侧边 tab / 双列列表）。
  bool get isWideViewport => viewportWidth >= Breakpoints.expanded;

  /// 是否使用桌面式侧边导航栏。
  bool get useSideNav => viewportWidth >= Breakpoints.sidebar;
}

/// 外层页面内容限宽。
///
/// 手机端原样铺满（[maxWidth] 大于屏幕时自然无效）；
/// 宽屏端把正文收进 [maxWidth] 并水平居中，避免一行文字横跨 1920px。
class PageBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  const PageBody({
    super.key,
    required this.child,
    this.maxWidth = 1200,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );
  }
}
