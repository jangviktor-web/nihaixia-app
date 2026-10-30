/// 设计 Token —— 间距 / 圆角 / 字号 单一来源。
///
/// 颜色 Token 已锁定于 [AppColors]（lib/theme/app_colors.dart，并在 main.dart
/// 以 ThemeExtension 注册，可由 `context.colors` 读取）。本文件补齐其余维度。
///
/// 整治目标（对应 UI 审计）：
///  - 间距无 token（P2）→ 统一走 [AppSpacing]
///  - 424 处硬编码 fontSize、0 处 textScaler（P0）→ 字号统一走 [AppType] 标准档位
///  - 圆角散落魔法值 → 统一走 [AppRadius]
///
/// Step 2+ 改造时，页面内禁止再写裸 `16.0` / `fontSize: 14` 等魔法值，必须引用此处。
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
}

/// 字号标准档位（dp）。替换硬编码 `fontSize` 时的目标映射：
///  - 大标题/页头 → [display] / [headline]
///  - 卡片标题 → [title]
///  - 正文 → [body]
///  - 辅助说明 → [caption] / [micro]
class AppType {
  static const double display = 24;
  static const double headline = 20;
  static const double subhead = 18;
  static const double title = 16;
  static const double body = 14;
  static const double caption = 12;
  static const double micro = 11;
}

/// 全局字号缩放档位（设置页 / 快捷外观弹窗 / 持久化校验的唯一来源）。
///
/// 上限 [max] = 200%：对应 issue #4「设置中字体大小调节调大至百分之二百以上」。
/// 每档 [step] = 5%，故 [divisions] = (max - min) / step = 24 档。
class AppTextScale {
  static const double min = 0.8;
  static const double max = 2.0;
  static const double defaultScale = 1.0;
  static const double step = 0.05;
  static const int divisions = 24;

  /// 把任意来源的缩放值收敛到合法区间（老版本 DB 遗留值、越界输入都经此兜底）。
  static double normalize(double value) =>
      value.clamp(min, max).toDouble();
}
