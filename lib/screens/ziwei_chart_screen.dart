import 'package:flutter/material.dart';
import 'package:ziwei_core/ziwei_core.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart';
import 'package:nihaisha_app/services/ziwei_interpretation.dart';
import 'ziwei_reference_screen.dart';
import 'ziwei_doc_screen.dart';
import 'ziwei_cases_list_screen.dart';
import '../data/ziwei_case_data.dart';
import '../theme/app_colors.dart';

/// 紫微斗数排盘界面。
///
/// 输入公历生辰 + 时辰 + 性别，调用 [calculateZiweiChart] 计算并可视化命盘。
/// 结果属「民俗文化参考」，非医疗诊断。
class ZiweiChartScreen extends StatefulWidget {
  const ZiweiChartScreen({super.key});

  @override
  State<ZiweiChartScreen> createState() => _ZiweiChartScreenState();
}

class _ZiweiChartScreenState extends State<ZiweiChartScreen> {
  // 时辰表（名称, 代表小时, 时段）
  static const _shiChen = [
    ('子时', 0, '23:00–01:00'),
    ('丑时', 2, '01:00–03:00'),
    ('寅时', 4, '03:00–05:00'),
    ('卯时', 6, '05:00–07:00'),
    ('辰时', 8, '07:00–09:00'),
    ('巳时', 10, '09:00–11:00'),
    ('午时', 12, '11:00–13:00'),
    ('未时', 14, '13:00–15:00'),
    ('申时', 16, '15:00–17:00'),
    ('酉时', 18, '17:00–19:00'),
    ('戌时', 20, '19:00–21:00'),
    ('亥时', 22, '21:00–23:00'),
  ];

  int _year = 2000;
  int _month = 8;
  int _day = 16;
  int _shiChenIndex = 5; // 巳时（默认 2000-08-16 06:00 约卯时，这里取常用值）
  bool _isMale = true;

  // ---- 流年盘状态 ----
  FlowYearMark? _flowMark; // 当前选中的流年（null = 不显示流年叠加）
  int? _flowYear; // 选中的流年年份
  bool _useTrueSolarTime = true; // 真太阳时校准（专业排盘默认开启）
  bool _showAllHealth = false; // 健康提醒：展开终身（出生→百岁）vs 默认未来30年
  final _longitudeCtrl = TextEditingController(); // 出生地经度（东经，留空用默认 120°）

  @override
  void dispose() {
    _longitudeCtrl.dispose();
    super.dispose();
  }

  /// 某年某月的天数（闰年 2 月 29 天）。
  int _daysInMonth(int year, int month) {
    if (month < 1 || month > 12) return 31;
    if (month == 2) {
      final isLeap = (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
      return isLeap ? 29 : 28;
    }
    return (month == 4 || month == 6 || month == 9 || month == 11) ? 30 : 31;
  }

  /// 年月变化后，把超出当月天数的日期钳制为当月最大日（避免非法日期静默错算）。
  void _clampDay() {
    final maxDay = _daysInMonth(_year, _month);
    if (_day > maxDay) _day = maxDay;
  }

  ZiweiChart? _chart;
  bool _calculating = false;
  String? _error;

  void _calculate() {
    // 校验经度输入（可选）
    double? lng;
    final lngText = _longitudeCtrl.text.trim();
    if (lngText.isNotEmpty) {
      final v = double.tryParse(lngText);
      if (v == null || v < -180 || v > 180) {
        setState(() {
          _error = '经度格式不正确（范围 -180 ~ 180，如 120 或 116.41）';
          _chart = null;
        });
        return;
      }
      lng = v;
    }
    setState(() {
      _calculating = true;
      _error = null;
    });
    // 用 microtask 让 loading 先渲染
    Future.microtask(() {
      try {
        final solar = DateTime(
          _year,
          _month,
          _day,
          _shiChen[_shiChenIndex].$2,
          0,
        );
        final chart = calculateZiweiChart(
          solar: solar,
          gender: _isMale ? Gender.male : Gender.female,
          location: lng != null ? Location(lng, 30) : null,
          useTrueSolarTime: _useTrueSolarTime,
        );
        if (mounted) {
          setState(() {
            _chart = chart;
            _calculating = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _error = '排盘失败：$e';
            _calculating = false;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('紫微斗数排盘'),
        actions: [
          IconButton(
            tooltip: '十四主星 / 十二宫位 / 倪师论命理',
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ZiweiReferenceScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 民俗参考声明
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: cs.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '紫微斗数属民俗文化参考，结果不构成任何医疗诊断或健康建议。',
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
          _buildInputCard(cs),
          const SizedBox(height: 12),
          if (_calculating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: TextStyle(color: cs.error)),
            ),
          if (_chart != null && !_calculating) ...[
            _buildSummaryCard(cs, _chart!),
            const SizedBox(height: 12),
            _buildCaseReferenceCard(cs, _chart!),
            const SizedBox(height: 12),
            _buildFlowYearBar(cs, _chart!),
            const SizedBox(height: 8),
            _buildPlate(cs, _chart!, _flowMark),
            const SizedBox(height: 12),
            _buildDecadeList(cs, _chart!),
            _buildInterpretationSection(cs, _chart!),
          ],
        ],
      ),
    );
  }

  Widget _buildInputCard(ColorScheme cs) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '生辰信息',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _Dropdown(
                    label: '年',
                    value: _year,
                    items: [
                      // 年份上限跟随当前年（2026 起自动扩展，无需再手改）
                      for (int y = 1920; y <= DateTime.now().year; y++)
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: (v) => setState(() {
                      _year = v!;
                      _clampDay();
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Dropdown(
                    label: '月',
                    value: _month,
                    items: [
                      for (int m = 1; m <= 12; m++)
                        DropdownMenuItem(value: m, child: Text('$m')),
                    ],
                    onChanged: (v) => setState(() {
                      _month = v!;
                      _clampDay();
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Dropdown(
                    label: '日',
                    value: _day,
                    items: [
                      for (int d = 1; d <= _daysInMonth(_year, _month); d++)
                        DropdownMenuItem(value: d, child: Text('$d')),
                    ],
                    onChanged: (v) => setState(() => _day = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _Dropdown(
                    label: '时辰',
                    value: _shiChenIndex,
                    items: [
                      for (int i = 0; i < _shiChen.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text('${_shiChen[i].$1} (${_shiChen[i].$3})'),
                        ),
                    ],
                    onChanged: (v) => setState(() => _shiChenIndex = v!),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(value: true, label: Text('男')),
                      ButtonSegment(value: false, label: Text('女')),
                    ],
                    selected: {_isMale},
                    onSelectionChanged: (s) =>
                        setState(() => _isMale = s.first),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                '真太阳时校准',
                style: TextStyle(fontSize: 12),
              ),
              subtitle: Text(
                '按出生地经度校正平太阳时时差，专业排盘默认开启',
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
              ),
              value: _useTrueSolarTime,
              onChanged: (v) => setState(() => _useTrueSolarTime = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _longitudeCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: '出生地经度（东经）',
                hintText: '留空按东经120°（UTC+8 标准线），如北京 116.41',
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('开始排盘'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ColorScheme cs, ZiweiChart chart) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '八字 ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  chart.baziFull,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              chart.lunarText,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _chip('五行局', chart.elementBureauLabel, cs.primary),
                _chip('命主', chart.mingZhuLabel ?? '—', cs.primary),
                _chip('身主', chart.shenZhuLabel ?? '—', cs.primary),
                _chip('性别', chart.genderLabel, cs.primary),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              '生年四化',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: chart.sihua.map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _sihuaColor(s.typeLabel).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${s.typeLabel}→${s.starLabelName}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _sihuaColor(s.typeLabel),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 倪师案例参考：按命宫地支 + 性别匹配《天纪》紫微案例。
  Widget _buildCaseReferenceCard(ColorScheme cs, ZiweiChart chart) {
    final ming = chart.palaces[chart.originMingIndex].branchLabel;
    final matched = ziweiCasesFor(ming, chart.genderLabel);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.menu_book_outlined, size: 20, color: cs.primary),
                const SizedBox(width: 8),
                const Text(
                  '倪师案例参考',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '命宫在「$ming」· ${chart.genderLabel}。'
              '${matched.isEmpty ? '暂未收录完全匹配案例' : '倪师《天纪》讲过 ${matched.length} 例相关案例：'}',
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            if (matched.isNotEmpty)
              ...matched.map(
                (e) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    '案${e.id}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                  title: Text(
                    e.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ZiweiDocScreen(entry: e)),
                  ),
                ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ZiweiCasesListScreen(),
                  ),
                ),
                icon: const Icon(Icons.library_books_outlined, size: 16),
                label: const Text('浏览全部案例与十二宫详解'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlowYearBar(ColorScheme cs, ZiweiChart chart) {
    final birthYear = _year;
    final maxYear = DateTime.now().year + 10;
    final selected = _flowYear;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            Icon(Icons.event_outlined, size: 18, color: cs.primary),
            const SizedBox(width: 8),
            const Text('流年',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButton<int>(
                value: selected,
                isExpanded: true,
                underline: const SizedBox.shrink(),
                hint: const Text('选流年看流曜落宫',
                    style: TextStyle(fontSize: 12)),
                items: [
                  for (var y = birthYear; y <= maxYear; y++)
                    DropdownMenuItem(
                      value: y,
                      child: Text('$y 年',
                          style: const TextStyle(fontSize: 12)),
                    ),
                ],
                onChanged: (v) {
                  if (v == null) return;
                  setState(() {
                    _flowYear = v;
                    _flowMark = calculateFlowYearMark(year: v);
                  });
                },
              ),
            ),
            if (selected != null) ...[
              if (_flowMark != null)
                Text(_flowMark!.ganzhi,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cs.primary)),
              const SizedBox(width: 4),
              IconButton(
                tooltip: '关闭流年',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() {
                  _flowYear = null;
                  _flowMark = null;
                }),
                icon: const Icon(Icons.close, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlate(ColorScheme cs, ZiweiChart chart, FlowYearMark? flow) {
    // 4×4 盘面：外围 12 宫按地支固定盘位，中心 2×2 为命盘核心。
    // slot(0..15) → 地支索引(0子..11亥) 或 -1(核心)
    const slotToBranch = [
      5, 6, 7, 8, // 巳 午 未 申
      4, -1, -1, 9, // 辰 [核][核] 酉
      3, -1, -1, 10, // 卯 [核][核] 戌
      2, 1, 0, 11, // 寅 丑 子 亥
    ];
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          childAspectRatio: 0.72,
          children: [
            for (int slot = 0; slot < 16; slot++)
              slotToBranch[slot] == -1
                  ? _buildCoreCell(cs, chart, slot)
                  : _buildPalaceCell(
                      cs,
                      chart,
                      chart.palaces[slotToBranch[slot]],
                      flow,
                    ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreCell(ColorScheme cs, ZiweiChart chart, int slot) {
    // 中心 2×2：五行局 / 命主 / 身主 / 性别
    final info = <int, String>{
      5: chart.elementBureauLabel,
      6: '命主 ${chart.mingZhuLabel ?? "—"}',
      9: '身主 ${chart.shenZhuLabel ?? "—"}',
      10: chart.genderLabel,
    }[slot]!;
    final title = <int, String>{5: '五行局', 6: '', 9: '', 10: ''}[slot];
    return Container(
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (title != null && title.isNotEmpty)
            Text(
              title,
              style: TextStyle(fontSize: 10, color: cs.onPrimaryContainer),
            ),
          Text(
            info,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: cs.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPalaceCell(
    ColorScheme cs,
    ZiweiChart chart,
    ZiweiPalace p,
    FlowYearMark? flow,
  ) {
    final isLife = p.isLife;
    final isBody = p.isBody;
    final isFlowMing = flow != null && flow.mingIndex == p.index;
    final flowStarsHere = flow?.flowStars[p.index] ?? const <String>[];
    final flowLabel = flowStarsHere.isEmpty
        ? null
        : '流 ${flowStarsHere.join(' ')}';
    return GestureDetector(
      onTap: () => _showPalaceDetail(p, flow),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isFlowMing
                ? cs.primary
                : isLife
                ? cs.error
                : isBody
                ? cs.tertiary
                : cs.outlineVariant,
            width: isFlowMing ? 2.2 : (isLife || isBody ? 1.8 : 0.6),
          ),
          borderRadius: BorderRadius.circular(8),
          color: isFlowMing
              ? cs.primaryContainer.withValues(alpha: 0.35)
              : isLife
              ? cs.errorContainer.withValues(alpha: 0.25)
              : isBody
              ? cs.tertiaryContainer.withValues(alpha: 0.25)
              : null,
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 宫名 + 命/身/流命标记
            Row(
              children: [
                Expanded(
                  child: Text(
                    p.roleLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isFlowMing)
                  _badge('流命', cs.primary)
                else if (isLife)
                  _badge('命', cs.error)
                else if (isBody)
                  _badge('身', cs.tertiary),
              ],
            ),
            Text(
              p.ganzhiLabel,
              style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 2),
            // 主星（含四化）
            ...p.majors.map(
              (s) => Text(
                s.sihua != null ? '${s.label}(${s.sihuaText})' : s.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: s.sihua != null
                      ? _sihuaColor(s.sihuaText)
                      : cs.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // 吉星
            if (p.luckies.isNotEmpty)
              Text(
                p.luckies.map((s) => s.label).join(' '),
                style: TextStyle(fontSize: 10, color: context.colors.success),
                overflow: TextOverflow.ellipsis,
              ),
            // 煞星
            if (p.bads.isNotEmpty)
              Text(
                p.bads.map((s) => s.label).join(' '),
                style: TextStyle(fontSize: 10, color: context.colors.danger),
                overflow: TextOverflow.ellipsis,
              ),
            // 杂曜（乙级星：红鸾/天喜/天刑/天姚/三台/八座等；
            // 博士/岁建/将前/长生十二神在点按宫格的详情中全量展示）
            if (p.minors.isNotEmpty)
              Text(
                p.minors.map((s) => s.label).join(' '),
                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            // 流曜（流年盘叠加）
            if (flowLabel != null)
              Text(
                flowLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
      ),
    );
  }

  /// 点按宫格：展示该宫主管（倪师天机道）与宫内星曜（含流年流曜）。
  void _showPalaceDetail(ZiweiPalace p, FlowYearMark? flow) {
    final cs = Theme.of(context).colorScheme;
    final meaning = ZiweiReferenceScreen.palaceMeanings[p.roleLabel];
    final flowStarsHere = flow?.flowStars[p.index] ?? const <String>[];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    p.roleLabel,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    p.ganzhiLabel,
                    style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 8),
                  if (p.isLife) _badge('命宫', cs.error),
                  if (p.isBody) _badge('身宫', cs.tertiary),
                  if (flow != null && flow.mingIndex == p.index)
                    _badge('流年命宫 ${flow.ganzhi}', cs.primary),
                ],
              ),
              const SizedBox(height: 6),
              if (meaning != null)
                Text(
                  '主管：$meaning',
                  style: const TextStyle(fontSize: 14, height: 1.5),
                ),
              const SizedBox(height: 12),
              if (p.stars.isEmpty)
                Text(
                  '本宫无星曜',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ...p.stars.map(
                (s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Text(
                        s.label,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: s.isMajor ? cs.onSurface : cs.onSurfaceVariant,
                        ),
                      ),
                      if (s.brightness != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          '${s.brightness}',
                          style: TextStyle(fontSize: 12, color: cs.primary),
                        ),
                      ],
                      if (s.sihua != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          s.sihuaText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _sihuaColor(s.sihuaText),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      Text(
                        _starKindLabel(s),
                        style: TextStyle(fontSize: 10, color: cs.outline),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (flowStarsHere.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(Icons.event, size: 14, color: cs.primary),
                      const SizedBox(width: 6),
                      Text(
                        '流曜：${flowStarsHere.join('、')}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                '宫位主管出自倪师《天纪·天机道》· 民俗文化参考',
                style: TextStyle(fontSize: 10, color: cs.outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _starKindLabel(ZiweiStar s) {
    if (s.isMajor) return '主星';
    if (s.isLucky) return '吉星';
    if (s.isBad) return '煞星';
    switch (s.type) {
      case StarType.boshi12:
        return '博士十二神';
      case StarType.suijian12:
        return '岁建十二神';
      case StarType.jiangqian12:
        return '将前十二神';
      case StarType.changsheng12:
        return '长生十二神';
      default:
        return '杂曜';
    }
  }

  Widget _buildDecadeList(ColorScheme cs, ZiweiChart chart) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '十二大限（十年运）',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ...chart.decades.map(
              (d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        '第${d.index}大限',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 84,
                      child: Text(
                        d.rangeLabel,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${d.roleLabel} ${d.ganzhiLabel}',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 「运势总结」区块：整体运势 / 十年大运 / 流年运势 / 健康提醒。
  /// 仅在既有排盘内容之下追加，不改动 _calculate / _buildPalaceGrid / _showPalaceDetail。
  Widget _buildInterpretationSection(ColorScheme cs, ZiweiChart chart) {
    final anchor = DateTime.now().year;
    final birthYear = _year; // 出生年 state（屏内无独立 _birth 字段）
    final healthItems = analyzeHealthWatch(
      chart,
      fromYear: _showAllHealth ? birthYear : anchor,
      toYear: _showAllHealth ? birthYear + 100 : anchor + 30,
      birthYear: birthYear,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        _interpretationCard(
          title: '整体运势',
          cs: cs,
          child: Text(
            summarizeOverall(chart),
            style: const TextStyle(fontSize: 13, height: 1.7),
          ),
        ),
        const SizedBox(height: 12),
        _interpretationCard(
          title: '十年大运',
          cs: cs,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: summarizeDecades(chart)
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Text(
                      '• $s',
                      style: const TextStyle(fontSize: 12, height: 1.6),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (_flowMark != null) ...[
          _interpretationCard(
            title: '流年运势（${_flowMark!.ganzhi}）',
            cs: cs,
            child: Text(
              summarizeFlowYear(chart, _flowMark!),
              style: const TextStyle(fontSize: 13, height: 1.7),
            ),
          ),
          const SizedBox(height: 12),
        ],
        _interpretationCard(
          title: '健康提醒',
          cs: cs,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, size: 14, color: context.colors.warning),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '民俗文化参考·非医疗诊断·如有不适请就医',
                      style: TextStyle(fontSize: 10, color: context.colors.warning),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (healthItems.isEmpty)
                Text(
                  '所选区间内流年疾厄宫未见明显煞忌信号。',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                )
              else
                ...healthItems.map((it) => _healthWatchRow(item: it, cs: cs)),
              if (healthItems.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(
                      () => _showAllHealth = !_showAllHealth,
                    ),
                    child: Text(
                      _showAllHealth ? '收起（仅看未来 30 年）' : '展开全部（终身）',
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// 健康提醒单条：年份/虚岁 + 醒目标签 + 信号原因 + 身体部位 + 来源。
  Widget _healthWatchRow({
    required HealthWatchItem item,
    required ColorScheme cs,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning, size: 14, color: context.colors.warning),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.year}年 · ${item.age}虚岁',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
                Text(item.reason, style: const TextStyle(fontSize: 12, height: 1.5)),
                Text(
                  '留意：${item.bodyPart}',
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                Text(
                  '来源：${item.source}',
                  style: TextStyle(fontSize: 10, color: cs.outline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 解读卡片外壳（统一 Card + 标题，沿用屏内配色约定）。
  Widget _interpretationCard({
    required String title,
    required ColorScheme cs,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.primary),
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 12),
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(color: context.colors.onSurfaceVariant),
            ),
            TextSpan(
              text: value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Color _sihuaColor(String t) {
    switch (t) {
      case '禄':
        return context.colors.danger;
      case '权':
        return context.colors.warning;
      case '科':
        return context.colors.info;
      case '忌':
        return context.colors.success;
      default:
        return context.colors.onSurface;
    }
  }
}

class _Dropdown extends StatelessWidget {
  final String label;
  final int value;
  final List<DropdownMenuItem<int>> items;
  final ValueChanged<int?> onChanged;

  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
