import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// 统一状态视图 —— Step 6「状态页统一」核心组件。
///
/// 提供三态：加载中 / 空状态 / 错误（含重试）。所有页面级 loading、empty、
/// error 不再各自手写 Center+Text，统一引用本组件，保证视觉与交互一致。
///
/// 决策约束（来自 Phase 1 用户拍板）：
///  - 加载中**不加文字**（决策④），保持与既有转圈一致。
///  - 空状态**保留各页面原始文案**（决策②），调用方透传 title/hint，本组件不改写措辞。
///  - 错误态提供「重试」按钮，颜色走 danger token（P0-3 根治，禁止裸色值）。
///  - 不覆盖 Dialog 内进度条（决策⑤）；不改动 main.dart 启动流程（决策③）。
enum ViewState { loading, empty, error }

class StateView extends StatelessWidget {
  final ViewState _state;
  final String? title;
  final String? hint;
  final IconData? icon;
  final String? message;
  final VoidCallback? onRetry;
  final bool fullScreen;

  const StateView._({
    Key? key,
    required ViewState state,
    this.title,
    this.hint,
    this.icon,
    this.message,
    this.onRetry,
    this.fullScreen = true,
  })  : _state = state,
        super(key: key);

  /// 加载中（无文字）。
  const StateView.loading({Key? key, bool fullScreen = true})
      : this._(key: key, state: ViewState.loading, fullScreen: fullScreen);

  /// 空状态。保留原始文案：调用方透传 [title]/[hint]。
  const StateView.empty({
    Key? key,
    String? title,
    String? hint,
    IconData? icon,
    bool fullScreen = true,
  }) : this._(
          key: key,
          state: ViewState.empty,
          title: title,
          hint: hint,
          icon: icon ?? Icons.inbox_outlined,
          fullScreen: fullScreen,
        );

  /// 错误态。仅 error 显示「重试」按钮（颜色走 danger）。
  const StateView.error({
    Key? key,
    String? title,
    String? message,
    required VoidCallback onRetry,
    bool fullScreen = true,
  }) : this._(
          key: key,
          state: ViewState.error,
          title: title,
          message: message,
          onRetry: onRetry,
          fullScreen: fullScreen,
        );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final Widget child;
    switch (_state) {
      case ViewState.loading:
        child = const CircularProgressIndicator();
        break;
      case ViewState.empty:
        child = _buildEmpty(colors);
        break;
      case ViewState.error:
        child = _buildError(colors);
        break;
    }
    if (fullScreen) {
      return Center(child: child);
    }
    return child;
  }

  Widget _buildEmpty(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? Icons.inbox_outlined, size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.lg),
          if (title != null)
            Text(
              title!,
              style: TextStyle(
                fontSize: AppType.title,
                fontWeight: FontWeight.w600,
                color: colors.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          if (hint != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              hint!,
              style: TextStyle(fontSize: AppType.caption, color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError(AppColors colors) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: colors.danger),
          const SizedBox(height: AppSpacing.lg),
          if (title != null)
            Text(
              title!,
              style: const TextStyle(
                fontSize: AppType.title,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          if (message != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              message!,
              style: TextStyle(fontSize: AppType.caption, color: colors.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(foregroundColor: colors.danger),
              child: const Text('重试'),
            ),
          ],
        ],
      ),
    );
  }
}
