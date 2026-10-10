// 五运六气 · 三张可视化图（运气五行图 / 五运图 / 六气图）
//
// 语义对齐参考站 <https://acuherb.xyz/ziwu/> 的同名三图，但**不追求像素级复刻**：
// 参考站是 SVG + 绝对坐标排版，本文件改为「按画布尺寸自适应」的三个
// CustomPainter，以便在小屏（360dp 宽）也能完整放下。
//
// ## 配色纪律
//
// 五行底色是**语义内容色**（木绿 / 火红 / 土黄 / 金白 / 水蓝），无法用
// `ColorScheme` token 表达，故本文件内建 [wxColorOf] 私有亮/暗两套映射——
// 这是全文件**唯一**的硬编码颜色来源。除此之外，所有颜色一律取自
// `colorScheme.*` 或已有颜色的 `withValues(alpha:)`，深色模式下文字对比度
// 由 [_textOn] 按背景亮度派生（浅底深字 / 深底浅字），不写死黑白。
//
// ## 绘制纪律
//
// * 所有 [TextPainter] 必须显式给 `textDirection: TextDirection.ltr`，
//   否则 Flutter 会抛断言。
// * 每个 painter 的 `shouldRepaint` 逐字段比较（选中日期 / 当前步变化要重绘）。
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/yunqi_engine.dart';

// ==================== 五行语义色（全文件唯一硬编码颜色来源） ====================

/// 浅色主题下的五行色。
const Map<String, Color> _wxColorsLight = <String, Color>{
  '木': Color(0xFF43A047), // 青绿
  '火': Color(0xFFE53935), // 赤
  '土': Color(0xFFFDD835), // 黄
  '金': Color(0xFFB0BEC5), // 白（灰白属金）
  '水': Color(0xFF1E88E5), // 蓝（玄）
};

/// 深色主题下的五行色（整体提亮，保证在深底上仍可辨）。
const Map<String, Color> _wxColorsDark = <String, Color>{
  '木': Color(0xFF66BB6A),
  '火': Color(0xFFEF5350),
  '土': Color(0xFFFFD54F),
  '金': Color(0xFFCFD8DC),
  '水': Color(0xFF42A5F5),
};

/// 五行兜底色（未知五行时）。
const Color _wxFallbackLight = Color(0xFF9E9E9E);
const Color _wxFallbackDark = Color(0xFFBDBDBD);

/// 取五行语义色。
///
/// [brightness] 通常来自 `Theme.of(context).colorScheme.brightness`。
Color wxColorOf(String wx, Brightness brightness) {
  final Map<String, Color> m =
      brightness == Brightness.dark ? _wxColorsDark : _wxColorsLight;
  return m[wx] ?? (brightness == Brightness.dark ? _wxFallbackDark : _wxFallbackLight);
}

/// 由背景色派生可读的前景色（浅底深字 / 深底浅字）。
///
/// 不写死黑白，而是沿原色相调整明度，保证与五行色同源、深色模式可读。
Color _textOn(Color bg) {
  final HSLColor hsl = HSLColor.fromColor(bg);
  final bool onDark = bg.computeLuminance() < 0.45;
  return hsl
      .withLightness(onDark ? 0.93 : 0.16)
      .withSaturation(math.min(hsl.saturation, 0.45))
      .toColor();
}

// ==================== 三图输入快照 ====================

/// 三张图共用的输入快照：一次算好，三图共享，避免重复求解节气。
///
/// 口径与 `yunqi_screen.dart` 完全一致——**年数据按日历年驱动**
/// （参考站口径，见 `YunQiEngine.calendarYearOf`），当前步按所选日期的
/// 毫秒时刻判定，因此「选生日 → 三图联动重绘」时高亮步会随之改变。
class YunQiChartData {
  /// 驱动年数据的公历年（= `YunQiEngine.calendarYearOf(selectedDate)`）。
  final int year;

  /// 该年的完整运气数据。
  final YunQiYearData yearData;

  /// 用户所选日期（用于判定「当前步」）。
  final DateTime selectedDate;

  /// 所选日期所处的客气步序（0-5）。
  final int qiStep;

  /// 所选日期所处的五运步序（0-4）。
  final int yunStep;

  /// 五运五步的起点（长度为 5）。
  final List<DateTime> yunBounds;

  /// 客气六步的边界（长度为 6）。
  final List<DateTime> qiBounds;

  const YunQiChartData({
    required this.year,
    required this.yearData,
    required this.selectedDate,
    required this.qiStep,
    required this.yunStep,
    required this.yunBounds,
    required this.qiBounds,
  });

  /// 按 [date] 构造快照（与 `yunqi_screen.dart` 的口径一致）。
  factory YunQiChartData.of(DateTime date) {
    final int y = YunQiEngine.calendarYearOf(date);
    final double ms = date.millisecondsSinceEpoch.toDouble();
    return YunQiChartData(
      year: y,
      yearData: YunQiEngine.yearGanzhi(y),
      selectedDate: date,
      qiStep: YunQiEngine.currentQiStep(y, ms),
      yunStep: YunQiEngine.currentYunStep(y, ms),
      yunBounds: YunQiEngine.yunStepBounds(y),
      qiBounds: YunQiEngine.qiStepBounds(y),
    );
  }

  /// 当前客气步名（如「太阳寒水」）。
  String get currentKeQi => yearData.keQi[qiStep];

  /// 当前主气步名（如「阳明燥金」）。
  String get currentZhuQi => zhuQiSteps[qiStep].qi;

  /// 当前主运步（如「太角」）。
  YunStep get currentZhuYun => yearData.zhuYun[yunStep];

  /// 当前客运步（如「少徵」）。
  YunStep get currentKeYun => yearData.keYun[yunStep];
}

// ==================== 运气五行图 · 徽章 ====================

/// 徽章角色（决定徽章文案与绘制顺序）。
enum YunQiBadgeRole {
  /// 岁运（中运 / 大运）。
  suiYun,

  /// 司天。
  siTian,

  /// 在泉。
  zaiQuan,

  /// 主运当前步。
  zhuYun,

  /// 客运当前步。
  keYun,

  /// 客气当前步。
  keQi,
}

/// 一枚「角色徽章」：文案 + 落宫五行。
class WuxingBadge {
  /// 角色。
  final YunQiBadgeRole role;

  /// 徽章文案，如「岁运·太火」「客运·少土」「司天」。
  final String text;

  /// 落宫五行（木/火/土/金/水）。
  final String wx;

  const WuxingBadge({required this.role, required this.text, required this.wx});

  @override
  String toString() => 'WuxingBadge($text → $wx)';
}

/// 五宫的绘制顺序（木火土金水，与 [yunQiWuXing] 一致）。
const List<String> wuxingPalaces = <String>['木', '火', '土', '金', '水'];

/// 徽章落宫规则：按 [data] 生成全部徽章。
///
/// 落宫五行取自：
/// * 岁运 → `yearData.yun`；
/// * 司天 → `yearData.siTianWx`；
/// * 在泉 → `qiWuXing[yearData.zaiQuan]`；
/// * 主运 → 当前运步 `zhuYun[yunStep].wx`；
/// * 客运 → 当前运步 `keYun[yunStep].wx`；
/// * 客气 → 当前客气步 `qiWuXing[keQi[qiStep]]`。
///
/// 同一宫可叠放多个徽章（参考站 2018-03-10 例：火宫 = 岁运 + 客运）。
/// 非五行的落宫值会被丢弃，保证绘制时不会落到宫外。
List<WuxingBadge> buildWuxingBadges(YunQiChartData data) {
  final YunQiYearData d = data.yearData;
  String taiShao(bool tai) => tai ? '太' : '少';
  final List<WuxingBadge> out = <WuxingBadge>[];

  void add(YunQiBadgeRole role, String text, String? wx) {
    if (wx == null || !wuxingPalaces.contains(wx)) return;
    out.add(WuxingBadge(role: role, text: text, wx: wx));
  }

  add(YunQiBadgeRole.suiYun, '岁运·${taiShao(d.taiGuo)}${d.yun}', d.yun);
  add(YunQiBadgeRole.siTian, '司天', d.siTianWx);
  add(YunQiBadgeRole.zaiQuan, '在泉', qiWuXing[d.zaiQuan]);
  add(
    YunQiBadgeRole.zhuYun,
    '主运·${taiShao(data.currentZhuYun.tai)}${data.currentZhuYun.wx}',
    data.currentZhuYun.wx,
  );
  add(
    YunQiBadgeRole.keYun,
    '客运·${taiShao(data.currentKeYun.tai)}${data.currentKeYun.wx}',
    data.currentKeYun.wx,
  );
  add(
    YunQiBadgeRole.keQi,
    '客气·${data.currentKeQi}',
    qiWuXing[data.currentKeQi],
  );
  return out;
}

// ==================== 通用绘制工具 ====================

/// 构造一个已指定字号/颜色的 [TextPainter]（**必带 ltr**，避免断言崩溃）。
TextPainter _tp(
  String text,
  double fontSize,
  Color? color, {
  FontWeight weight = FontWeight.normal,
}) {
  return TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: weight,
        height: 1.15,
      ),
    ),
    textDirection: TextDirection.ltr,
    maxLines: 1,
    ellipsis: '…',
  );
}

/// 在不超过 [maxWidth] 的前提下，把字号从 [base] 逐步下调（最低 [min]）。
///
/// 用于窄屏（360dp）下保证圆环扇区内的中文标签不被截断。
double _fitFont(
  String text,
  double maxWidth,
  double base, {
  FontWeight weight = FontWeight.normal,
  double min = 7.0,
}) {
  double fs = base;
  while (fs > min) {
    // 量宽度与颜色无关，故不传 color（避免为量测引入任何字面颜色）。
    final TextPainter tp = _tp(text, fs, null, weight: weight)..layout();
    final double w = tp.width;
    tp.dispose();
    if (w <= maxWidth) return fs;
    fs -= 0.5;
  }
  return min;
}

/// 以 [center] 为中心绘制单行文本。
void _drawCentered(
  Canvas canvas,
  String text,
  Offset center,
  double fontSize,
  Color color, {
  FontWeight weight = FontWeight.normal,
}) {
  final TextPainter tp = _tp(text, fontSize, color, weight: weight)..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  tp.dispose();
}

/// 环形扇区（内半径 [rIn] → 外半径 [rOut]，角度 [start] 起顺时针扫 [sweep]）。
Path _annulusSector(
  Offset c,
  double rIn,
  double rOut,
  double start,
  double sweep,
) {
  final Path p = Path();
  final Rect outer = Rect.fromCircle(center: c, radius: rOut);
  final Rect inner = Rect.fromCircle(center: c, radius: rIn);
  p.moveTo(c.dx + rOut * math.cos(start), c.dy + rOut * math.sin(start));
  p.arcTo(outer, start, sweep, false);
  p.lineTo(
    c.dx + rIn * math.cos(start + sweep),
    c.dy + rIn * math.sin(start + sweep),
  );
  p.arcTo(inner, start + sweep, -sweep, false);
  p.close();
  return p;
}

/// 实心扇形（圆心 [c]，半径 [r]）。
Path _pieSector(Offset c, double r, double start, double sweep) {
  final Path p = Path();
  p.moveTo(c.dx, c.dy);
  p.arcTo(Rect.fromCircle(center: c, radius: r), start, sweep, false);
  p.close();
  return p;
}

/// MM/dd 格式化。
String _mmdd(DateTime d) =>
    '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

/// 从 12 点方向起、顺时针的第 [i] 个扇区的起始角（弧度）。
double _sectorStart(int i, int count) => -math.pi / 2 + (2 * math.pi * i) / count;

/// 五运五步之名的序（初之运…终之运）。
const List<String> yunStepNames = <String>[
  '初之运', '二之运', '三之运', '四之运', '终之运',
];

// ==================== 图 1 · 运气五行图 ====================

/// 图 1「运气五行图」：十字五宫（土居中、火上、水下、木左、金右）。
///
/// 每宫内叠放角色徽章（岁运/司天/在泉/主运/客运/客气），徽章可溢出宫圆
/// 边界（参考站即如此），纯展示、不响应点击。
class WuxingChart extends StatelessWidget {
  /// 三图共用输入快照。
  final YunQiChartData data;

  const WuxingChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _WuxingPainter(data: data, colors: cs),
      child: const SizedBox.expand(),
    );
  }
}

/// [WuxingChart] 的绘制器。
class _WuxingPainter extends CustomPainter {
  final YunQiChartData data;
  final ColorScheme colors;

  const _WuxingPainter({required this.data, required this.colors});

  /// 五宫相对圆心的偏移（宫序同 [wuxingPalaces]：木火土金水）。
  static const List<Offset> _offsets = <Offset>[
    Offset(-1, 0), // 木 · 左
    Offset(0, -1), // 火 · 上
    Offset(0, 0), // 土 · 中
    Offset(1, 0), // 金 · 右
    Offset(0, 1), // 水 · 下
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double half = math.min(size.width, size.height) / 2;
    final double r = half * 0.32; // 宫圆半径
    if (r < 6) return;
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double d = half * 0.55; // 宫心到中心的距离
    final Brightness b = colors.brightness;

    // —— 先画十字连线（五宫关系骨架）——
    final Paint linkPaint = Paint()
      ..color = colors.outline.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(
      c + Offset(0, -d),
      c + Offset(0, d),
      linkPaint,
    );
    canvas.drawLine(c + Offset(-d, 0), c + Offset(d, 0), linkPaint);

    final List<WuxingBadge> badges = buildWuxingBadges(data);
    final double badgeFont = _fitFont('客运·太金', r * 2.0, r * 0.30, min: 8.0);
    final double badgeH = badgeFont + 6.0;

    for (int i = 0; i < wuxingPalaces.length; i++) {
      final String wx = wuxingPalaces[i];
      final Color wxColor = wxColorOf(wx, b);
      final Offset pc = c + Offset(_offsets[i].dx * d, _offsets[i].dy * d);

      // 宫圆
      canvas.drawCircle(
        pc,
        r,
        Paint()..color = wxColor.withValues(alpha: 0.90),
      );
      canvas.drawCircle(
        pc,
        r,
        Paint()
          ..color = wxColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );

      // 宫名（五行大字）
      _drawCentered(
        canvas,
        wx,
        pc - Offset(0, r * 0.22),
        r * 0.72,
        _textOn(wxColor),
        weight: FontWeight.bold,
      );

      // 该宫徽章（自宫心下方依次下叠，可溢出宫圆，参考站即如此）
      final List<WuxingBadge> mine = <WuxingBadge>[
        for (final WuxingBadge g in badges)
          if (g.wx == wx) g,
      ];
      double y = pc.dy + r * 0.30;
      for (final WuxingBadge g in mine) {
        final TextPainter tp = _tp(g.text, badgeFont, _textOn(wxColor),
            weight: FontWeight.w600)
          ..layout();
        final double w = tp.width + 10;
        final Rect rect = Rect.fromLTWH(pc.dx - w / 2, y, w, badgeH);
        final RRect rr = RRect.fromRectAndRadius(rect, const Radius.circular(4));
        canvas.drawRRect(rr, Paint()..color = wxColor.withValues(alpha: 0.96));
        canvas.drawRRect(
          rr,
          Paint()
            ..color = colors.outline.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
        tp.paint(canvas, Offset(rect.left + 5, y + (badgeH - tp.height) / 2));
        tp.dispose();
        y += badgeH + 3;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WuxingPainter old) =>
      old.colors != colors ||
      old.data.year != data.year ||
      old.data.qiStep != data.qiStep ||
      old.data.yunStep != data.yunStep ||
      old.data.selectedDate != data.selectedDate;
}

// ==================== 图 2 · 五运图 ====================

/// 图 2「五运图」：单层圆环十扇区（5 运期 × 主运/客运各半）。
///
/// 中心盘标注「初之运…终之运」，外圈标注 5 个步界日期（MM/dd）与基准节气名。
/// 当前运期扇区高亮加深并描边，环上加一个标记点（参考站为红点）。
class WuyunChart extends StatelessWidget {
  /// 三图共用输入快照。
  final YunQiChartData data;

  const WuyunChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _WuyunPainter(data: data, colors: cs),
      child: const SizedBox.expand(),
    );
  }
}

/// [WuyunChart] 的绘制器。
class _WuyunPainter extends CustomPainter {
  final YunQiChartData data;
  final ColorScheme colors;

  const _WuyunPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double half = math.min(size.width, size.height) / 2;
    final double rOut = half - 28; // 外圈给步界标签留 28
    if (rOut < 24) return;
    final Offset c = Offset(size.width / 2, size.height / 2);
    final Brightness b = colors.brightness;
    const int n = 5;
    final double sweep = 2 * math.pi / n;

    final double band = math.min(rOut * 0.48, 58.0);
    final double rIn = rOut - band;
    final double rDisc = math.max(rIn - 3, 8);

    final Paint strokeBase = Paint()
      ..color = colors.outline.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < n; i++) {
      final double a0 = _sectorStart(i, n);
      final bool hi = data.yunStep == i;

      // —— 中心盘扇区（初之运…终之运）——
      canvas.drawPath(
        _pieSector(c, rDisc, a0, sweep),
        Paint()
          ..color = hi
              ? colors.primaryContainer
              : colors.surfaceContainerHighest.withValues(alpha: 0.55),
      );
      canvas.drawPath(_pieSector(c, rDisc, a0, sweep), strokeBase);
      final double discTextR = rDisc * 0.56;
      final double discMaxW = 2 * discTextR * math.sin(sweep / 2) * 0.92;
      final double discFont = _fitFont(yunStepNames[i], discMaxW, 11.0);
      _drawCentered(
        canvas,
        yunStepNames[i],
        c + Offset(
          discTextR * math.cos(a0 + sweep / 2),
          discTextR * math.sin(a0 + sweep / 2),
        ),
        discFont,
        hi ? colors.onPrimaryContainer : colors.onSurface,
        weight: hi ? FontWeight.bold : FontWeight.w500,
      );

      // —— 主运 / 客运两个半扇区 ——
      for (int k = 0; k < 2; k++) {
        final double s0 = a0 + k * sweep / 2;
        final YunStep step = k == 0 ? data.yearData.zhuYun[i] : data.yearData.keYun[i];
        final String label = '${k == 0 ? '主' : '客'} ${step.label}';
        final Color wx = wxColorOf(step.wx, b);

        canvas.drawPath(
          _annulusSector(c, rIn, rOut, s0, sweep / 2),
          Paint()..color = hi ? colors.primaryContainer : wx.withValues(alpha: 0.28),
        );
        canvas.drawPath(_annulusSector(c, rIn, rOut, s0, sweep / 2), strokeBase);

        final double midR = (rIn + rOut) / 2;
        final double mid = s0 + sweep / 4;
        final double maxW = 2 * midR * math.sin(sweep / 4) * 0.92;
        final double font = _fitFont(label, maxW, 11.0);
        _drawCentered(
          canvas,
          label,
          c + Offset(midR * math.cos(mid), midR * math.sin(mid)),
          font,
          hi ? colors.onPrimaryContainer : _textOn(wx),
          weight: hi ? FontWeight.bold : FontWeight.w600,
        );
      }

      // 高亮描边
      if (hi) {
        canvas.drawPath(
          _annulusSector(c, rIn, rOut, a0, sweep),
          Paint()
            ..color = colors.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
      }
    }

    // —— 外圈步界：MM/dd + 基准节气名 ——
    for (int i = 0; i < n; i++) {
      final double a = _sectorStart(i, n);
      final Offset p0 = c + Offset(rOut * math.cos(a), rOut * math.sin(a));
      final Offset p1 = c + Offset((rOut + 6) * math.cos(a), (rOut + 6) * math.sin(a));
      canvas.drawLine(p0, p1, strokeBase);
      final Offset lp =
          c + Offset((rOut + 15) * math.cos(a), (rOut + 15) * math.sin(a));
      _drawCentered(canvas, _mmdd(data.yunBounds[i]), lp, 9.0, colors.onSurfaceVariant);
      _drawCentered(
        canvas,
        YunQiEngine.yunStepBoundTerms[i],
        lp + const Offset(0, 11),
        9.0,
        colors.onSurfaceVariant,
      );
    }

    // —— 当前步标记点（参考站为红点）——
    final double markA = _sectorStart(data.yunStep, n) + sweep / 2;
    canvas.drawCircle(
      c + Offset((rOut + 3) * math.cos(markA), (rOut + 3) * math.sin(markA)),
      3.6,
      Paint()..color = colors.error,
    );
  }

  @override
  bool shouldRepaint(covariant _WuyunPainter old) =>
      old.colors != colors ||
      old.data.year != data.year ||
      old.data.yunStep != data.yunStep ||
      old.data.selectedDate != data.selectedDate;
}

// ==================== 图 3 · 六气图 ====================

/// 图 3「六气图」：双层圆环——内环主气六步、外环客气六步。
///
/// 外圈标注 6 个边界日期（MM/dd）与边界节气名（取自 `zhuQiSteps[i].from`）。
/// 当前步的内环（主气）与外环（客气）扇区同时高亮，环上加标记点。
class LiuqiChart extends StatelessWidget {
  /// 三图共用输入快照。
  final YunQiChartData data;

  const LiuqiChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return CustomPaint(
      painter: _LiuqiPainter(data: data, colors: cs),
      child: const SizedBox.expand(),
    );
  }
}

/// [LiuqiChart] 的绘制器。
class _LiuqiPainter extends CustomPainter {
  final YunQiChartData data;
  final ColorScheme colors;

  const _LiuqiPainter({required this.data, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double half = math.min(size.width, size.height) / 2;
    final double rOut = half - 28; // 外圈给边界标签留 28
    if (rOut < 30) return;
    final Offset c = Offset(size.width / 2, size.height / 2);
    final Brightness b = colors.brightness;
    const int n = 6;
    final double sweep = 2 * math.pi / n;

    final double outerBand = math.min(rOut * 0.30, 40.0);
    final double outerIn = rOut - outerBand;
    final double innerOut = outerIn - 2;
    final double innerBand = math.min(innerOut * 0.52, 46.0);
    final double innerIn = math.max(innerOut - innerBand, 12);
    final double hole = math.max(innerIn - 2, 0);

    final Paint strokeBase = Paint()
      ..color = colors.outline.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < n; i++) {
      final double a0 = _sectorStart(i, n);
      final double mid = a0 + sweep / 2;
      final bool hi = data.qiStep == i;

      // —— 外环：客气 ——
      final String ke = data.yearData.keQi[i];
      final Color keWx = wxColorOf(qiWuXing[ke] ?? '', b);
      canvas.drawPath(
        _annulusSector(c, outerIn, rOut, a0, sweep),
        Paint()..color = hi ? colors.primaryContainer : keWx.withValues(alpha: 0.28),
      );
      canvas.drawPath(_annulusSector(c, outerIn, rOut, a0, sweep), strokeBase);
      final double keR = (outerIn + rOut) / 2;
      final String keLabel = '客 $ke';
      final double keFont =
          _fitFont(keLabel, 2 * keR * math.sin(sweep / 2) * 0.92, 10.5);
      _drawCentered(
        canvas,
        keLabel,
        c + Offset(keR * math.cos(mid), keR * math.sin(mid)),
        keFont,
        hi ? colors.onPrimaryContainer : _textOn(keWx),
        weight: hi ? FontWeight.bold : FontWeight.w600,
      );

      // —— 内环：主气（两行：气名 + 步名小字）——
      final ZhuQiStepDef zq = zhuQiSteps[i];
      final Color zhuWx = wxColorOf(qiWuXing[zq.qi] ?? '', b);
      canvas.drawPath(
        _annulusSector(c, innerIn, innerOut, a0, sweep),
        Paint()..color = hi ? colors.primaryContainer : zhuWx.withValues(alpha: 0.22),
      );
      canvas.drawPath(_annulusSector(c, innerIn, innerOut, a0, sweep), strokeBase);

      final double line1R = innerIn + (innerOut - innerIn) * 0.68;
      final double line2R = innerIn + (innerOut - innerIn) * 0.28;
      final String zhuLabel = '主 ${zq.qi}';
      final double zhuFont =
          _fitFont(zhuLabel, 2 * line1R * math.sin(sweep / 2) * 0.92, 10.0);
      _drawCentered(
        canvas,
        zhuLabel,
        c + Offset(line1R * math.cos(mid), line1R * math.sin(mid)),
        zhuFont,
        hi ? colors.onPrimaryContainer : _textOn(zhuWx),
        weight: hi ? FontWeight.bold : FontWeight.w600,
      );
      _drawCentered(
        canvas,
        zq.name,
        c + Offset(line2R * math.cos(mid), line2R * math.sin(mid)),
        8.5,
        hi ? colors.onPrimaryContainer : colors.onSurfaceVariant,
      );

      if (hi) {
        canvas.drawPath(
          _annulusSector(c, innerIn, rOut, a0, sweep),
          Paint()
            ..color = colors.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2,
        );
      }
    }

    // —— 中心孔：年干支 ——
    if (hole >= 16) {
      canvas.drawCircle(c, hole, Paint()..color = colors.surfaceContainerHighest);
      _drawCentered(
        canvas,
        data.yearData.ganZhi,
        c,
        math.min(hole * 0.62, 18.0),
        colors.onSurface,
        weight: FontWeight.bold,
      );
    }

    // —— 外圈边界：MM/dd + 节气名 ——
    for (int i = 0; i < n; i++) {
      final double a = _sectorStart(i, n);
      canvas.drawLine(
        c + Offset(rOut * math.cos(a), rOut * math.sin(a)),
        c + Offset((rOut + 6) * math.cos(a), (rOut + 6) * math.sin(a)),
        strokeBase,
      );
      final Offset lp =
          c + Offset((rOut + 15) * math.cos(a), (rOut + 15) * math.sin(a));
      _drawCentered(canvas, _mmdd(data.qiBounds[i]), lp, 9.0, colors.onSurfaceVariant);
      _drawCentered(
        canvas,
        zhuQiSteps[i].from,
        lp + const Offset(0, 11),
        9.0,
        colors.onSurfaceVariant,
      );
    }

    // —— 当前步标记点（参考站为红点）——
    final double markA = _sectorStart(data.qiStep, n) + sweep / 2;
    canvas.drawCircle(
      c + Offset((rOut + 3) * math.cos(markA), (rOut + 3) * math.sin(markA)),
      3.6,
      Paint()..color = colors.error,
    );
  }

  @override
  bool shouldRepaint(covariant _LiuqiPainter old) =>
      old.colors != colors ||
      old.data.year != data.year ||
      old.data.qiStep != data.qiStep ||
      old.data.selectedDate != data.selectedDate;
}
