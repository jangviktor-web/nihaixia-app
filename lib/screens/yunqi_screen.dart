import 'package:flutter/material.dart';

import '../services/yunqi_engine.dart';
import 'yunqi_charts.dart';

/// 「五运六气推算」界面。
///
/// 用户选择一个日期，本页展示该日期所属**运气年**（以立春为界）的完整运气信息：
/// 年干支、岁运（太过/不及）及病候、司天在泉、运气格局标记（天符/岁会/太一天符/
/// 同天符/同岁会/平气）、主运五步、客运五步、主气六步、客气六步、故主加临顺逆，
/// 以及**当前所处之气**（高亮）与当令之气病候。
///
/// 视觉语言沿用 `ziwuliuzhu_screen.dart`（`_InfoCard` / `_ResultCard` 同构），
/// 但本文件的私有小组件均为本文件自有，不跨文件引用其他模块的私有类。
///
/// 配色一律取 `Theme.of(context).colorScheme` 的 token，**不硬编码颜色**，
/// 以保证深色模式下对比度正常。
class YunQiScreen extends StatefulWidget {
  const YunQiScreen({super.key});

  @override
  State<YunQiScreen> createState() => _YunQiScreenState();
}

class _YunQiScreenState extends State<YunQiScreen> {
  /// 用户所选日期，默认今天。取日期部分即可（运气以日为单位）。
  DateTime _selectedDate = DateTime.now();

  /// 显示「当前处于第几之气」时需要精确到时刻，故用完整 now。
  final DateTime _now = DateTime.now();

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      helpText: '选择日期（以该日所属运气年推演）',
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _resetToday() {
    setState(() => _selectedDate = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;

    // 口径：外层按参考站用「日历年」驱动 yunqiYearData（大寒~立春之间不回溯）。
    // 若需严格立春年，可改用 YunQiEngine.yunqiYearOf(_selectedDate)。
    final int calendarYear = YunQiEngine.calendarYearOf(_selectedDate);
    final YunQiYearData data = YunQiEngine.yearGanzhi(calendarYear);

    // 当前所处之气：按参考站口径，第一参数用日历年。
    final int nowCalYear = _now.year;
    final int currentStep = YunQiEngine.currentQiStep(
      nowCalYear,
      _now.millisecondsSinceEpoch.toDouble(),
    );

    // 选中的日期是否落在「今天所在的运气年」，决定是否高亮当前之气。
    final bool isCurrentYear = calendarYear == nowCalYear;

    return Scaffold(
      appBar: AppBar(title: const Text('五运六气推算')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          _DateHeader(
            selectedDate: _selectedDate,
            onPickDate: _pickDate,
            onResetToday: _resetToday,
          ),
          const SizedBox(height: 12),
          _YearSummaryCard(data: data, color: cs),
          const SizedBox(height: 12),
          _ChartsTabs(selectedDate: _selectedDate),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.wb_sunny_outlined,
            title: '岁运（中运）· 病候',
            content: data.yunBingText.isEmpty
                ? '${data.yun}运${data.taiGuo ? '太过' : '不及'}（病候文案缺失）'
                : data.yunBingText,
            highlight: '${data.yun}运${data.taiGuo ? '太过' : '不及'}',
            color: cs,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.cloud_outlined,
            title: '司天 · 病候',
            content: data.siTianBingText.isEmpty
                ? data.siTian
                : data.siTianBingText,
            highlight: data.siTian,
            color: cs,
          ),
          const SizedBox(height: 12),
          _KeyValueCard(
            title: '司天 / 在泉',
            icon: Icons.swap_horiz,
            rows: <({String label, String value})>[
              (label: '司天（主上半年）', value: '${data.siTian}（${data.siTianWx}）'),
              (label: '在泉（主下半年）', value: data.zaiQuan),
            ],
            color: cs,
          ),
          const SizedBox(height: 12),
          _InfoCard(
            icon: Icons.menu_book_outlined,
            title: '《内经》大论原文',
            content: (data.jz60['SAME'] ?? '').isEmpty
                ? '本年大论原文缺失'
                : data.jz60['SAME']!,
            highlight: '${data.ganName}${data.zhiName}年',
            color: cs,
          ),
          const SizedBox(height: 12),
          _KeyValueCard(
            title: '岁运三纪 · 胜复郁',
            icon: Icons.auto_graph,
            rows: <({String label, String value})>[
              (label: '三纪', value: data.yunBack['THREE'] ?? '—'),
              (label: '胜气', value: data.yunBack['OVER'] ?? '—'),
              (label: '复气', value: data.yunBack['BACK'] ?? '—'),
              (label: '郁发', value: data.yunBack['REBACK'] ?? '—'),
              (label: '年名', value: data.jz60['NAME'] ?? '—'),
              (label: '关系', value: data.jz60['IF'] ?? '—'),
            ],
            color: cs,
          ),
          const SizedBox(height: 12),
          _KeyValueCard(
            title: '司天在泉 · 治则病候',
            icon: Icons.medical_services_outlined,
            rows: <({String label, String value})>[
              (label: '司天治则', value: data.skySiTian['FIX'] ?? '—'),
              (label: '在泉治则', value: data.skyZaiQuan['FIX'] ?? '—'),
              (label: '在泉病候', value: data.skyZaiQuan['WIN'] ?? '—'),
              (label: '六气胜', value: data.qiBack['OVER'] ?? '—'),
              (label: '六气复', value: data.qiBack['BACK'] ?? '—'),
              (label: '胜治则', value: data.qiBack['OVER2'] ?? '—'),
              (label: '复治则', value: data.qiBack['BACK2'] ?? '—'),
            ],
            color: cs,
          ),
          const SizedBox(height: 12),
          _TagsCard(data: data, color: cs),
          const SizedBox(height: 12),
          _StepsCard<YunStep>(
            title: '主运五步',
            icon: Icons.filter_5,
            items: data.zhuYun,
            color: cs,
            leadingOf: (YunStep s, int i) => '第${_cnIndex(i)}运',
            valueOf: (YunStep s) => s.label,
            trailingOf: (YunStep s, int i) => s.wx,
          ),
          const SizedBox(height: 12),
          _StepsCard<YunStep>(
            title: '客运五步',
            icon: Icons.directions_bus_outlined,
            items: data.keYun,
            color: cs,
            leadingOf: (YunStep s, int i) => '第${_cnIndex(i)}运',
            valueOf: (YunStep s) => s.label,
            trailingOf: (YunStep s, int i) => s.wx,
          ),
          const SizedBox(height: 12),
          _StepsCard<String>(
            title: '主气六步（固定）',
            icon: Icons.grass,
            items: <String>[for (final ZhuQiStepDef z in zhuQiSteps) z.qi],
            color: cs,
            leadingOf: (String s, int i) => zhuQiSteps[i].name,
            valueOf: (String s) => s,
            trailingOf: (String s, int i) => '${zhuQiSteps[i].from}–${zhuQiSteps[i].to}',
            highlightIndex: isCurrentYear ? currentStep : null,
          ),
          const SizedBox(height: 12),
          _StepsCard<String>(
            title: '客气六步',
            icon: Icons.air,
            items: data.keQi,
            color: cs,
            leadingOf: (String s, int i) => qiStepNames[i],
            valueOf: (String s) => s,
            trailingOf: (String s, int i) => s == data.siTian ? '司天' : '',
            highlightIndex: isCurrentYear ? currentStep : null,
          ),
          const SizedBox(height: 12),
          if (isCurrentYear)
            _CurrentStepCard(
              step: currentStep,
              qi: data.keQi[currentStep],
              zhuQi: zhuQiSteps[currentStep].qi,
              stepName: qiStepNames[currentStep],
              color: cs,
            ),
          if (isCurrentYear) const SizedBox(height: 12),
          _JiaLinCard(data: data, color: cs, highlightIndex: isCurrentYear ? currentStep : null),
          const SizedBox(height: 12),
          const _DisclaimerCard(),
        ],
      ),
    );
  }

  /// 中文序数（一、二、三、四、五）。
  static String _cnIndex(int index) {
    const List<String> cn = <String>['一', '二', '三', '四', '五'];
    return (index >= 0 && index < cn.length) ? cn[index] : '${index + 1}';
  }
}

// ───────────────────────── 顶部日期选择 ─────────────────────────

/// 顶部日期选择头：显示所选日期、所属运气年干支，并提供选日期 / 回到今天。
class _DateHeader extends StatelessWidget {
  final DateTime selectedDate;
  final Future<void> Function() onPickDate;
  final VoidCallback onResetToday;

  const _DateHeader({
    required this.selectedDate,
    required this.onPickDate,
    required this.onResetToday,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final int calendarYear = YunQiEngine.calendarYearOf(selectedDate);
    final YunQiYearData data = YunQiEngine.yearGanzhi(calendarYear);
    final String mm = selectedDate.month.toString().padLeft(2, '0');
    final String dd = selectedDate.day.toString().padLeft(2, '0');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.event, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                Text(
                  '所选日期',
                  style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onResetToday,
                  icon: const Icon(Icons.today, size: 18),
                  label: const Text('今天'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${selectedDate.year}-$mm-$dd',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '所属运气年：${data.ganZhi}年（${data.shengXiao}）· ${data.yun}运${data.taiGuo ? '太过' : '不及'}',
              style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPickDate,
                icon: const Icon(Icons.calendar_month, size: 18),
                label: const Text('选择日期'),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '点日期可查任意一天（如生日）的运气，下方三图会随之重绘。',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 年干支总览 ─────────────────────────

/// 年干支总览卡：干支、六甲子序、生肖、岁运、标记。
class _YearSummaryCard extends StatelessWidget {
  final YunQiYearData data;
  final ColorScheme color;

  const _YearSummaryCard({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.auto_awesome, size: 20, color: color.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  '运气年 ${data.year}',
                  style: TextStyle(fontSize: 14, color: color.onPrimaryContainer),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${data.ganZhi}年 · ${data.shengXiao}',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '六十甲子第 ${data.ganzhiOrdinal} 位　岁运：${data.yun}（${data.taiGuo ? '太过' : '不及'}）',
              style: TextStyle(fontSize: 14, color: color.onPrimaryContainer),
            ),
            const SizedBox(height: 8),
            Text(
              data.cat,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 三张可视化图 ─────────────────────────

/// 三张可视化图区块：运气五行图 / 五运图 / 六气图。
///
/// * 选中日期变化时三图联动重绘，并高亮「当前所处步」；
/// * 图区固定 380dp 高，图内排版按画布尺寸自适应（小屏 360dp 宽也能放下）；
/// * 具体绘制在 `yunqi_charts.dart`，本文件只负责 Tab 容器，改动最小化。
class _ChartsTabs extends StatefulWidget {
  /// 用户所选日期（决定三图的高亮步）。
  final DateTime selectedDate;

  const _ChartsTabs({required this.selectedDate});

  @override
  State<_ChartsTabs> createState() => _ChartsTabsState();
}

class _ChartsTabsState extends State<_ChartsTabs>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final YunQiChartData chart = YunQiChartData.of(widget.selectedDate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TabBar(
              controller: _tabController,
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              labelStyle:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12),
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurfaceVariant,
              tabs: const <Widget>[
                Tab(text: '运气五行图'),
                Tab(text: '五运图'),
                Tab(text: '六气图'),
              ],
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 380,
              child: TabBarView(
                controller: _tabController,
                children: <Widget>[
                  WuxingChart(data: chart),
                  WuyunChart(data: chart),
                  LiuqiChart(data: chart),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '当前：${qiStepNames[chart.qiStep]}·客气${chart.currentKeQi}'
              '　${yunStepNames[chart.yunStep]}·客运${chart.currentKeYun.label}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 格局标记 ─────────────────────────

/// 运气格局标记卡：逐条列出六个 flag 的成立与否。
class _TagsCard extends StatelessWidget {
  final YunQiYearData data;
  final ColorScheme color;

  const _TagsCard({required this.data, required this.color});

  @override
  Widget build(BuildContext context) {
    final List<({String label, bool on})> flags = <({String label, bool on})>[
      (label: '天符', on: data.isTianFu),
      (label: '岁会', on: data.isSuiHui),
      (label: '太一天符', on: data.isTaiYi),
      (label: '同天符', on: data.isTongTianFu),
      (label: '同岁会', on: data.isTongSuiHui),
      (label: '平气', on: data.isPingQi),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.sell_outlined, size: 20, color: color.primary),
                const SizedBox(width: 8),
                Text(
                  '运气格局',
                  style: TextStyle(fontSize: 14, color: color.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final ({String label, bool on}) f in flags)
                  Chip(
                    avatar: Icon(
                      f.on ? Icons.check_circle : Icons.remove_circle_outline,
                      size: 18,
                      color: f.on ? color.primary : color.onSurfaceVariant,
                    ),
                    label: Text(f.label),
                    labelStyle: TextStyle(
                      fontSize: 13,
                      color: f.on ? color.onSurface : color.onSurfaceVariant,
                    ),
                    backgroundColor:
                        f.on ? color.primaryContainer : color.surfaceContainerHighest,
                    side: BorderSide.none,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 通用卡：键值对 ─────────────────────────

/// 键值对卡。
class _KeyValueCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<({String label, String value})> rows;
  final ColorScheme color;

  const _KeyValueCard({
    required this.title,
    required this.icon,
    required this.rows,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 20, color: color.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: color.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (final ({String label, String value}) r in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: 132,
                      child: Text(
                        r.label,
                        style: TextStyle(fontSize: 13, color: color.onSurfaceVariant),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        r.value,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 通用卡：N 步列表 ─────────────────────────

/// 通用「若干步」列表卡，支持高亮某一步。
///
/// 用泛型是为了让主运/客运（[YunStep]）与主气/客气（[String]）复用同一套
/// 版式，避免三份几乎相同的 build 代码。
class _StepsCard<T> extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<T> items;
  final ColorScheme color;

  /// 左侧标签（步名）。
  final String Function(T item, int index) leadingOf;

  /// 主值。
  final String Function(T item) valueOf;

  /// 右侧次要文本（带步序，便于按步取固定表，如主气的起止节气）。
  final String Function(T item, int index) trailingOf;

  /// 需要高亮的下标（null 表示不高亮）。
  final int? highlightIndex;

  const _StepsCard({
    required this.title,
    required this.icon,
    required this.items,
    required this.color,
    required this.leadingOf,
    required this.valueOf,
    required this.trailingOf,
    this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 20, color: color.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: color.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (int i = 0; i < items.length; i++)
              _StepRow(
                leading: leadingOf(items[i], i),
                value: valueOf(items[i]),
                trailing: trailingOf(items[i], i),
                highlighted: highlightIndex == i,
                color: color,
              ),
          ],
        ),
      ),
    );
  }
}

/// 单步行。
class _StepRow extends StatelessWidget {
  final String leading;
  final String value;
  final String trailing;
  final bool highlighted;
  final ColorScheme color;

  const _StepRow({
    required this.leading,
    required this.value,
    required this.trailing,
    required this.highlighted,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? color.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 64,
            child: Text(
              leading,
              style: TextStyle(
                fontSize: 13,
                color: highlighted ? color.onPrimaryContainer : color.onSurfaceVariant,
                fontWeight: highlighted ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: highlighted ? FontWeight.bold : FontWeight.w500,
                color: highlighted ? color.onPrimaryContainer : color.onSurface,
              ),
            ),
          ),
          if (trailing.isNotEmpty)
            Text(
              trailing,
              style: TextStyle(
                fontSize: 12,
                color: highlighted ? color.onPrimaryContainer : color.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

// ───────────────────────── 当前之气 ─────────────────────────

/// 「当前处于第几之气」卡：客气 + 主气 + 当令之气病候。
class _CurrentStepCard extends StatelessWidget {
  final int step;
  final String qi;
  final String zhuQi;
  final String stepName;
  final ColorScheme color;

  const _CurrentStepCard({
    required this.step,
    required this.qi,
    required this.zhuQi,
    required this.stepName,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final String bing = qiBing[qi] ?? '';
    return Card(
      color: color.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.place, size: 20, color: color.onSecondaryContainer),
                const SizedBox(width: 8),
                Text(
                  '今日所处之气',
                  style: TextStyle(fontSize: 14, color: color.onSecondaryContainer),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '$stepName（第 ${step + 1} 步）',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '客气：$qi　主气：$zhuQi',
              style: TextStyle(fontSize: 14, color: color.onSecondaryContainer),
            ),
            if (bing.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                bing,
                style: TextStyle(fontSize: 14, color: color.onSecondaryContainer),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 客主加临 ─────────────────────────

/// 客主加临表卡：逐步列出主气、客气与顺逆判定。
class _JiaLinCard extends StatelessWidget {
  final YunQiYearData data;
  final ColorScheme color;
  final int? highlightIndex;

  const _JiaLinCard({
    required this.data,
    required this.color,
    this.highlightIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.compare_arrows, size: 20, color: color.primary),
                const SizedBox(width: 8),
                Text(
                  '客主加临（顺逆）',
                  style: TextStyle(fontSize: 14, color: color.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '主气为主，客气加之。客克主为顺，主克客为逆。',
              style: TextStyle(fontSize: 12, color: color.onSurfaceVariant),
            ),
            const SizedBox(height: 10),
            // 表头
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: <Widget>[
                  _headerCell('步', 52, color),
                  _headerCell('主气', 88, color),
                  _headerCell('客气', 88, color),
                  Expanded(child: _headerCell('判定', 0, color)),
                ],
              ),
            ),
            const Divider(height: 12),
            for (int i = 0; i < data.jiaLin.length; i++)
              _jiaLinRow(data.jiaLin[i], i),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text, double width, ColorScheme color) {
    final Widget t = Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: color.onSurfaceVariant,
      ),
    );
    return width > 0 ? SizedBox(width: width, child: t) : t;
  }

  Widget _jiaLinRow(JiaLinStep s, int index) {
    final bool hi = highlightIndex == index;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: hi ? color.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 52,
            child: Text(
              s.zhu.name.replaceAll('之气', ''),
              style: TextStyle(
                fontSize: 13,
                color: hi ? color.onPrimaryContainer : color.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(
            width: 88,
            child: Text(
              '${s.zhu.qi}\n(${s.zhuWx})',
              style: TextStyle(
                fontSize: 12,
                color: hi ? color.onPrimaryContainer : color.onSurface,
              ),
            ),
          ),
          SizedBox(
            width: 88,
            child: Text(
              '${s.ke}\n(${s.keWx})',
              style: TextStyle(
                fontSize: 12,
                color: hi ? color.onPrimaryContainer : color.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              s.judge,
              style: TextStyle(
                fontSize: 12,
                fontWeight: hi ? FontWeight.bold : FontWeight.w500,
                color: hi ? color.onPrimaryContainer : color.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── 通用卡：图标 + 标题 + 正文 ─────────────────────────

/// 图文信息卡（同构于 `ziwuliuzhu_screen.dart` 的 `_InfoCard`，本文件自有）。
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;

  /// 可选的高亮行（如「木运太过」），置于正文之前。
  final String? highlight;
  final ColorScheme color;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.color,
    this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(icon, size: 20, color: color.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 14, color: color.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (highlight != null && highlight!.isNotEmpty) ...<Widget>[
              Text(
                highlight!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
            ],
            Text(content, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── 免责声明 ─────────────────────────

/// 底部免责声明，与本项目其他命理模块口径一致。
class _DisclaimerCard extends StatelessWidget {
  const _DisclaimerCard();

  @override
  Widget build(BuildContext context) {
    final ColorScheme color = Theme.of(context).colorScheme;
    return Card(
      color: color.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(Icons.info_outline, size: 18, color: color.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '运气推算口径以《素问·天元纪大论》《六微旨大论》《气交变大论》等'
                '运气七篇为据，节气时刻由定气算法实时求解。'
                '本内容仅供中医理论学习与研究参考，不构成医疗建议。',
                style: TextStyle(fontSize: 12, color: color.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
