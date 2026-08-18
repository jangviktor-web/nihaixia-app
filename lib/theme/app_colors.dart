import 'package:flutter/material.dart';

/// 语义化设计 Token（Design Tokens）——App 内颜色唯一来源（P0-3 根治）。
///
/// 设计依据（设计师终稿）：品牌棕 seed #8B4513；中性系暖调去纯白纯黑；
/// 状态系含 container；六经专用色 light 深 shade / dark 亮 shade（对比度≥4.5:1）。
///
/// 使用方式：`Theme.of(context).extension<AppColors>()!`，或
/// `context.colors`（见 [AppColorsContext]）。不要在页面内写裸颜色字面量。
@immutable
class AppColors extends ThemeExtension<AppColors> {
  // ---- 主色系（品牌棕） ----
  final Color primary;
  final Color onPrimary;
  final Color primaryContainer;
  final Color onPrimaryContainer;

  // ---- 中性系（暖调） ----
  final Color background;
  final Color surface;
  final Color surfaceContainerHighest;
  final Color surfaceContainerLow;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;

  // ---- 状态系 ----
  final Color danger;
  final Color onDanger;
  final Color dangerContainer;
  final Color warning;
  final Color warningContainer;
  final Color success;
  final Color successContainer;
  final Color info;
  final Color infoContainer;

  // ---- 六经专用色（light 深 shade / dark 亮 shade） ----
  final Color meridianTaiyang;
  final Color meridianTaiyangContainer;
  final Color onMeridianTaiyang;
  final Color meridianYangming;
  final Color meridianYangmingContainer;
  final Color onMeridianYangming;
  final Color meridianShaoyang;
  final Color meridianShaoyangContainer;
  final Color onMeridianShaoyang;
  final Color meridianTaiyin;
  final Color meridianTaiyinContainer;
  final Color onMeridianTaiyin;
  final Color meridianShaoyin;
  final Color meridianShaoyinContainer;
  final Color onMeridianShaoyin;
  final Color meridianJueyin;
  final Color meridianJueyinContainer;
  final Color onMeridianJueyin;

  const AppColors({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.background,
    required this.surface,
    required this.surfaceContainerHighest,
    required this.surfaceContainerLow,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.danger,
    required this.onDanger,
    required this.dangerContainer,
    required this.warning,
    required this.warningContainer,
    required this.success,
    required this.successContainer,
    required this.info,
    required this.infoContainer,
    required this.meridianTaiyang,
    required this.meridianTaiyangContainer,
    required this.onMeridianTaiyang,
    required this.meridianYangming,
    required this.meridianYangmingContainer,
    required this.onMeridianYangming,
    required this.meridianShaoyang,
    required this.meridianShaoyangContainer,
    required this.onMeridianShaoyang,
    required this.meridianTaiyin,
    required this.meridianTaiyinContainer,
    required this.onMeridianTaiyin,
    required this.meridianShaoyin,
    required this.meridianShaoyinContainer,
    required this.onMeridianShaoyin,
    required this.meridianJueyin,
    required this.meridianJueyinContainer,
    required this.onMeridianJueyin,
  });

  /// 六经 container = 该色 12% alpha 叠加在底色上（light 白底 / dark 深底）。
  static Color _tint(Color c, {required bool dark}) {
    final bg = dark ? const Color(0xFF221D18) : const Color(0xFFFFFFFF);
    return Color.alphaBlend(c.withValues(alpha: 0.12), bg);
  }

  static final AppColors light = AppColors(
    primary: const Color(0xFF8B4513),
    onPrimary: const Color(0xFFFFFFFF),
    primaryContainer: const Color(0xFFF5D7BC),
    onPrimaryContainer: const Color(0xFF2B1A00),
    background: const Color(0xFFFAF7F2),
    surface: const Color(0xFFFFFFFF),
    surfaceContainerHighest: const Color(0xFFEFE8DF),
    surfaceContainerLow: const Color(0xFFF4EFE8),
    onSurface: const Color(0xFF201B15),
    onSurfaceVariant: const Color(0xFF6F675C),
    outline: const Color(0xFF857C71),
    outlineVariant: const Color(0xFFD6CDC0),
    danger: const Color(0xFFC62828),
    onDanger: const Color(0xFFFFFFFF),
    dangerContainer: const Color(0xFFFFDAD6),
    warning: const Color(0xFF9A5B00),
    warningContainer: const Color(0xFFFFE0B5),
    success: const Color(0xFF2E7D32),
    successContainer: const Color(0xFFC8E6C9),
    info: const Color(0xFF1565C0),
    infoContainer: const Color(0xFFD6E9FF),
    meridianTaiyang: const Color(0xFFE65100),
    meridianTaiyangContainer: _tint(const Color(0xFFE65100), dark: false),
    onMeridianTaiyang: const Color(0xFF201B15),
    meridianYangming: const Color(0xFFC62828),
    meridianYangmingContainer: _tint(const Color(0xFFC62828), dark: false),
    onMeridianYangming: const Color(0xFF201B15),
    meridianShaoyang: const Color(0xFFD84315),
    meridianShaoyangContainer: _tint(const Color(0xFFD84315), dark: false),
    onMeridianShaoyang: const Color(0xFF201B15),
    meridianTaiyin: const Color(0xFF1565C0),
    meridianTaiyinContainer: _tint(const Color(0xFF1565C0), dark: false),
    onMeridianTaiyin: const Color(0xFF201B15),
    meridianShaoyin: const Color(0xFF6A1B9A),
    meridianShaoyinContainer: _tint(const Color(0xFF6A1B9A), dark: false),
    onMeridianShaoyin: const Color(0xFF201B15),
    meridianJueyin: const Color(0xFF37474F),
    meridianJueyinContainer: _tint(const Color(0xFF37474F), dark: false),
    onMeridianJueyin: const Color(0xFF201B15),
  );

  static final AppColors dark = AppColors(
    primary: const Color(0xFFE0A878),
    onPrimary: const Color(0xFF4A2A08),
    primaryContainer: const Color(0xFF5C3A10),
    onPrimaryContainer: const Color(0xFFF5D7BC),
    background: const Color(0xFF191512),
    surface: const Color(0xFF221D18),
    surfaceContainerHighest: const Color(0xFF2C2620),
    surfaceContainerLow: const Color(0xFF1E1A15),
    onSurface: const Color(0xFFEFE9E2),
    onSurfaceVariant: const Color(0xFFC4BBB0),
    outline: const Color(0xFF8F867A),
    outlineVariant: const Color(0xFF4F483E),
    danger: const Color(0xFFFFB4AB),
    onDanger: const Color(0xFF690005),
    dangerContainer: const Color(0xFF93000A),
    warning: const Color(0xFFFFB950),
    warningContainer: const Color(0xFF6B4100),
    success: const Color(0xFF81C784),
    successContainer: const Color(0xFF1B5E20),
    info: const Color(0xFF90CAF9),
    infoContainer: const Color(0xFF1E4E7A),
    meridianTaiyang: const Color(0xFFFFB74D),
    meridianTaiyangContainer: _tint(const Color(0xFFFFB74D), dark: true),
    onMeridianTaiyang: const Color(0xFFEFE9E2),
    meridianYangming: const Color(0xFFE57373),
    meridianYangmingContainer: _tint(const Color(0xFFE57373), dark: true),
    onMeridianYangming: const Color(0xFFEFE9E2),
    meridianShaoyang: const Color(0xFFFF8A65),
    meridianShaoyangContainer: _tint(const Color(0xFFFF8A65), dark: true),
    onMeridianShaoyang: const Color(0xFFEFE9E2),
    meridianTaiyin: const Color(0xFF64B5F6),
    meridianTaiyinContainer: _tint(const Color(0xFF64B5F6), dark: true),
    onMeridianTaiyin: const Color(0xFFEFE9E2),
    meridianShaoyin: const Color(0xFFBA68C8),
    meridianShaoyinContainer: _tint(const Color(0xFFBA68C8), dark: true),
    onMeridianShaoyin: const Color(0xFFEFE9E2),
    meridianJueyin: const Color(0xFF90A4AE),
    meridianJueyinContainer: _tint(const Color(0xFF90A4AE), dark: true),
    onMeridianJueyin: const Color(0xFFEFE9E2),
  );

  /// 六经名 → 主色（UI 层共用，替代散落的硬编码色）。
  Color meridianColor(String name) {
    switch (name) {
      case '太阳':
        return meridianTaiyang;
      case '阳明':
        return meridianYangming;
      case '少阳':
        return meridianShaoyang;
      case '太阴':
        return meridianTaiyin;
      case '少阴':
        return meridianShaoyin;
      case '厥阴':
        return meridianJueyin;
      default:
        return warning;
    }
  }

  /// 六经名 → container 色。
  Color meridianContainer(String name) {
    switch (name) {
      case '太阳':
        return meridianTaiyangContainer;
      case '阳明':
        return meridianYangmingContainer;
      case '少阳':
        return meridianShaoyangContainer;
      case '太阴':
        return meridianTaiyinContainer;
      case '少阴':
        return meridianShaoyinContainer;
      case '厥阴':
        return meridianJueyinContainer;
      default:
        return surfaceContainerHighest;
    }
  }

  @override
  AppColors copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? background,
    Color? surface,
    Color? surfaceContainerHighest,
    Color? surfaceContainerLow,
    Color? onSurface,
    Color? onSurfaceVariant,
    Color? outline,
    Color? outlineVariant,
    Color? danger,
    Color? onDanger,
    Color? dangerContainer,
    Color? warning,
    Color? warningContainer,
    Color? success,
    Color? successContainer,
    Color? info,
    Color? infoContainer,
    Color? meridianTaiyang,
    Color? meridianTaiyangContainer,
    Color? onMeridianTaiyang,
    Color? meridianYangming,
    Color? meridianYangmingContainer,
    Color? onMeridianYangming,
    Color? meridianShaoyang,
    Color? meridianShaoyangContainer,
    Color? onMeridianShaoyang,
    Color? meridianTaiyin,
    Color? meridianTaiyinContainer,
    Color? onMeridianTaiyin,
    Color? meridianShaoyin,
    Color? meridianShaoyinContainer,
    Color? onMeridianShaoyin,
    Color? meridianJueyin,
    Color? meridianJueyinContainer,
    Color? onMeridianJueyin,
  }) {
    return AppColors(
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceContainerHighest:
          surfaceContainerHighest ?? this.surfaceContainerHighest,
      surfaceContainerLow: surfaceContainerLow ?? this.surfaceContainerLow,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
      outline: outline ?? this.outline,
      outlineVariant: outlineVariant ?? this.outlineVariant,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerContainer: dangerContainer ?? this.dangerContainer,
      warning: warning ?? this.warning,
      warningContainer: warningContainer ?? this.warningContainer,
      success: success ?? this.success,
      successContainer: successContainer ?? this.successContainer,
      info: info ?? this.info,
      infoContainer: infoContainer ?? this.infoContainer,
      meridianTaiyang: meridianTaiyang ?? this.meridianTaiyang,
      meridianTaiyangContainer:
          meridianTaiyangContainer ?? this.meridianTaiyangContainer,
      onMeridianTaiyang: onMeridianTaiyang ?? this.onMeridianTaiyang,
      meridianYangming: meridianYangming ?? this.meridianYangming,
      meridianYangmingContainer:
          meridianYangmingContainer ?? this.meridianYangmingContainer,
      onMeridianYangming: onMeridianYangming ?? this.onMeridianYangming,
      meridianShaoyang: meridianShaoyang ?? this.meridianShaoyang,
      meridianShaoyangContainer:
          meridianShaoyangContainer ?? this.meridianShaoyangContainer,
      onMeridianShaoyang: onMeridianShaoyang ?? this.onMeridianShaoyang,
      meridianTaiyin: meridianTaiyin ?? this.meridianTaiyin,
      meridianTaiyinContainer:
          meridianTaiyinContainer ?? this.meridianTaiyinContainer,
      onMeridianTaiyin: onMeridianTaiyin ?? this.onMeridianTaiyin,
      meridianShaoyin: meridianShaoyin ?? this.meridianShaoyin,
      meridianShaoyinContainer:
          meridianShaoyinContainer ?? this.meridianShaoyinContainer,
      onMeridianShaoyin: onMeridianShaoyin ?? this.onMeridianShaoyin,
      meridianJueyin: meridianJueyin ?? this.meridianJueyin,
      meridianJueyinContainer:
          meridianJueyinContainer ?? this.meridianJueyinContainer,
      onMeridianJueyin: onMeridianJueyin ?? this.onMeridianJueyin,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      primary: l(primary, other.primary),
      onPrimary: l(onPrimary, other.onPrimary),
      primaryContainer: l(primaryContainer, other.primaryContainer),
      onPrimaryContainer: l(onPrimaryContainer, other.onPrimaryContainer),
      background: l(background, other.background),
      surface: l(surface, other.surface),
      surfaceContainerHighest:
          l(surfaceContainerHighest, other.surfaceContainerHighest),
      surfaceContainerLow: l(surfaceContainerLow, other.surfaceContainerLow),
      onSurface: l(onSurface, other.onSurface),
      onSurfaceVariant: l(onSurfaceVariant, other.onSurfaceVariant),
      outline: l(outline, other.outline),
      outlineVariant: l(outlineVariant, other.outlineVariant),
      danger: l(danger, other.danger),
      onDanger: l(onDanger, other.onDanger),
      dangerContainer: l(dangerContainer, other.dangerContainer),
      warning: l(warning, other.warning),
      warningContainer: l(warningContainer, other.warningContainer),
      success: l(success, other.success),
      successContainer: l(successContainer, other.successContainer),
      info: l(info, other.info),
      infoContainer: l(infoContainer, other.infoContainer),
      meridianTaiyang: l(meridianTaiyang, other.meridianTaiyang),
      meridianTaiyangContainer:
          l(meridianTaiyangContainer, other.meridianTaiyangContainer),
      onMeridianTaiyang: l(onMeridianTaiyang, other.onMeridianTaiyang),
      meridianYangming: l(meridianYangming, other.meridianYangming),
      meridianYangmingContainer:
          l(meridianYangmingContainer, other.meridianYangmingContainer),
      onMeridianYangming: l(onMeridianYangming, other.onMeridianYangming),
      meridianShaoyang: l(meridianShaoyang, other.meridianShaoyang),
      meridianShaoyangContainer:
          l(meridianShaoyangContainer, other.meridianShaoyangContainer),
      onMeridianShaoyang: l(onMeridianShaoyang, other.onMeridianShaoyang),
      meridianTaiyin: l(meridianTaiyin, other.meridianTaiyin),
      meridianTaiyinContainer:
          l(meridianTaiyinContainer, other.meridianTaiyinContainer),
      onMeridianTaiyin: l(onMeridianTaiyin, other.onMeridianTaiyin),
      meridianShaoyin: l(meridianShaoyin, other.meridianShaoyin),
      meridianShaoyinContainer:
          l(meridianShaoyinContainer, other.meridianShaoyinContainer),
      onMeridianShaoyin: l(onMeridianShaoyin, other.onMeridianShaoyin),
      meridianJueyin: l(meridianJueyin, other.meridianJueyin),
      meridianJueyinContainer:
          l(meridianJueyinContainer, other.meridianJueyinContainer),
      onMeridianJueyin: l(onMeridianJueyin, other.onMeridianJueyin),
    );
  }
}

/// 便捷读取：`context.colors.primary` 等。
extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
