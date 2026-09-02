import 'package:flutter/material.dart';
import 'package:nihaisha_app/services/lunar_almanac_service.dart';
import '../theme/app_colors.dart';
import '../widgets/almanac_cards.dart';

/// 滑动手势方向（纯函数 [resolveSwipe] 的判定结果）。
enum SwipeDir { dayNext, dayPrev }

/// 纯函数：依据手势速度分量判定滑动方向，便于单测。
///
/// 规则：只认横向手势——左滑（dx<0）切前一天，右滑（dx>0）切后一天。
/// 以下情形返回 null（不触发切换）：
/// - 横向速度绝对值不超过 40px/s（抖动）；
/// - 纵向速度不小于横向（纵向手势留给内容滚动，不再用于切日）。
SwipeDir? resolveSwipe(double dx, double dy) {
  if (dx.abs() <= 40 || dx.abs() <= dy.abs()) return null;
  return dx < 0 ? SwipeDir.dayPrev : SwipeDir.dayNext;
}

/// 每日黄历（老黄历）页面。
///
/// 基于 sxwnl_spa_dart 的农历，叠加建除十二神、彭祖百忌、冲煞、宜忌，
/// 年柱月柱日柱取自紫微引擎同一套四柱口径（见 [AlmanacDay.ganzhiYear]）。
/// 结果属「民俗文化参考」，非行事指令。
///
/// 交互：左滑切前一天、右滑切后一天（[resolveSwipe] 判定），
/// 纵向手势交回列表用于滚动长内容（如「忌」条目较多时）。
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

  /// 按滑动方向切换日期：左滑 = 前一天 / 右滑 = 后一天。
  /// Dart 的 DateTime 自动处理跨月跨年（如 3 月 1 日往前一天为 2 月最后一日）。
  void _applySwipe(SwipeDir dir) {
    final delta = dir == SwipeDir.dayNext ? 1 : -1;
    _date = DateTime(_date.year, _date.month, _date.day + delta);
    _compute();
  }

  @override
  Widget build(BuildContext context) {
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
          final v = details.velocity.pixelsPerSecond;
          final dir = resolveSwipe(v.dx, v.dy);
          if (dir != null) _applySwipe(dir);
        },
        child: ListView(
          // 不禁用滚动：内容较长（如「忌」条目多）时可滚到底部完整查看。
          // 纵向手势归 ListView，横向手势由上层 GestureDetector 切日。
          padding: const EdgeInsets.all(16),
          children: [
            const AlmanacSwipeHint(),
            const AlmanacDisclaimer(),
            const SizedBox(height: 12),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_almanac != null)
              ..._buildContent(_almanac!),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent(AlmanacDay a) {
    return [
      AlmanacDateHeader(almanac: a),
      const SizedBox(height: 12),
      AlmanacJianChuCard(almanac: a),
      const SizedBox(height: 12),
      AlmanacPengZuCard(almanac: a),
      const SizedBox(height: 12),
      AlmanacYiJiCard(
        kind: '宜',
        icon: Icons.check_circle_outline,
        color: context.colors.success,
        chipColor: context.colors.successContainer.withValues(alpha: 0.5),
        items: a.yi,
      ),
      const SizedBox(height: 12),
      AlmanacYiJiCard(
        kind: '忌',
        icon: Icons.block,
        color: context.colors.danger,
        chipColor: context.colors.dangerContainer.withValues(alpha: 0.5),
        items: a.ji,
      ),
      if (a.festivals.isNotEmpty) ...[
        const SizedBox(height: 12),
        AlmanacFestivalCard(festivals: a.festivals),
      ],
    ];
  }
}
