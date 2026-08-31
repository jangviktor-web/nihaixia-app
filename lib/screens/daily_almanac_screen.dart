import 'package:flutter/material.dart';
import 'package:nihaisha_app/services/lunar_almanac_service.dart';
import '../theme/app_colors.dart';

/// 滑动手势方向（纯函数 [resolveSwipe] 的判定结果）。
enum SwipeDir { dayNext, dayPrev, monthNext, monthPrev }

/// 纯函数：依据手势速度分量判定滑动方向，便于单测。
///
/// 规则：横向位移占优（|dx| > |dy|）→ 切月（左滑 dx<0 为下月，右滑为上月）；
/// 纵向位移占优且超过阈值 40px/s → 切日（上滑 dy<0 为下一天，下滑为前一天）；
/// 位移过弱（抖动）返回 null，不触发任何切换。
SwipeDir? resolveSwipe(double dx, double dy) {
  if (dx.abs() > dy.abs()) {
    return dx < 0 ? SwipeDir.monthNext : SwipeDir.monthPrev;
  } else if (dy.abs() > 40) {
    return dy < 0 ? SwipeDir.dayNext : SwipeDir.dayPrev;
  }
  return null;
}

/// 每日黄历（老黄历）页面。
///
/// 基于 sxwnl_spa_dart 的农历/干支，叠加通用建除十二神、彭祖百忌、冲煞、宜忌。
/// 结果属「民俗文化参考」，非行事指令。
///
/// 交互：上/下滑切日，左/右滑切月（[resolveSwipe] 判定）。
class DailyAlmanacScreen extends StatefulWidget {
  const DailyAlmanacScreen({super.key});

  @override
  State<DailyAlmanacScreen> createState() => _DailyAlmanacScreenState();
}

class _DailyAlmanacScreenState extends State<DailyAlmanacScreen> {
  DateTime _date = DateTime.now();
  AlmanacDay? _almanac;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _compute();
  }

  void _compute() {
    setState(() => _loading = true);
    // 用 microtask 让 loading 先渲染，再算（农历/干支为纯本地计算，极快）。
    Future.microtask(() {
      final a = getDailyAlmanac(_date);
      if (mounted) {
        setState(() {
          _almanac = a;
          _loading = false;
        });
      }
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(2100, 12, 31),
    );
    if (picked != null && picked != _date) {
      setState(() => _date = picked);
      _compute();
    }
  }

  /// 月份偏移（delta 可正可负）。Dart 的 DateTime 自动处理跨年（如 13 月→次年 1 月）。
  /// 若目标月天数小于当前日，则钳制为该月最后一天。
  void _shiftMonth(int delta) {
    final y = _date.year;
    final m = _date.month + delta;
    final dim = DateTime(y, m + 1, 0).day;
    final day = _date.day > dim ? dim : _date.day;
    _date = DateTime(y, m, day);
  }

  /// 按滑动方向切换日期：上滑=下一天 / 下滑=上一天 / 左滑=下月 / 右滑=上月。
  void _applySwipe(SwipeDir dir) {
    switch (dir) {
      case SwipeDir.dayNext:
        _date = DateTime(_date.year, _date.month, _date.day + 1);
      case SwipeDir.dayPrev:
        _date = DateTime(_date.year, _date.month, _date.day - 1);
      case SwipeDir.monthNext:
        _shiftMonth(1);
      case SwipeDir.monthPrev:
        _shiftMonth(-1);
    }
    _compute();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('每日黄历'),
        actions: [
          IconButton(
            tooltip: '选择日期',
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: GestureDetector(
        onPanEnd: (details) {
          final dir = resolveSwipe(
            details.velocity.pixelsPerSecond.dx,
            details.velocity.pixelsPerSecond.dy,
          );
          if (dir != null) _applySwipe(dir);
        },
        child: ListView(
          // 纵向手势交由上层 GestureDetector 处理（切日/切月），内容较短不滚动。
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // 手势提示（无 emoji，语义色小字）
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Icon(Icons.swipe, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '上/下滑切日，左/右滑切月（亦可用右上角日期按钮）',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: cs.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '黄历内容属民俗文化参考，宜忌冲煞仅为传统通胜口径，非行事指令。',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_almanac != null)
            ..._buildContent(_almanac!, cs),
        ],
      ),
      ),
    );
  }

  List<Widget> _buildContent(AlmanacDay a, ColorScheme cs) {
    return [
      // 日期头
      Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: cs.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${a.solar.year}年${a.solar.month}月${a.solar.day}日 · 周${a.weekdayName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${a.lunarText} · 日柱 ${a.ganzhiDay}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (a.solarTerm != null)
                _tag(a.solarTerm!, cs.primary)
              else if (a.festivals.isNotEmpty)
                _tag(a.festivals.first, cs.secondary),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      // 建除十二神（大字）
      Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  a.jianChu,
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '建除十二神',
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${a.jianChu}日 · ${a.chong} · ${a.sha}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      // 彭祖百忌
      Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '彭祖百忌',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...a.pengZu.map(
                (p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.format_quote, size: 16, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(p, style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      // 宜
      Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 18, color: context.colors.success),
                  const SizedBox(width: 8),
                  const Text(
                    '宜',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: a.yi
                    .map(
                      (s) => Chip(
                        backgroundColor:
                            context.colors.successContainer.withValues(alpha: 0.5),
                        label: Text(s,
                            style: TextStyle(color: context.colors.success)),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      // 忌
      Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.block, size: 18, color: context.colors.danger),
                  const SizedBox(width: 8),
                  const Text(
                    '忌',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: a.ji
                    .map(
                      (s) => Chip(
                        backgroundColor:
                            context.colors.dangerContainer.withValues(alpha: 0.5),
                        label:
                            Text(s, style: TextStyle(color: context.colors.danger)),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
      if (a.festivals.isNotEmpty) ...[
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.celebration_outlined,
                        size: 18, color: cs.secondary),
                    const SizedBox(width: 8),
                    const Text(
                      '节日',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: a.festivals
                      .map(
                        (f) => Chip(
                          backgroundColor: cs.secondaryContainer,
                          label: Text(f,
                              style:
                                  TextStyle(color: cs.onSecondaryContainer)),
                          visualDensity: VisualDensity.compact,
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    ];
  }

  Widget _tag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
