import 'package:flutter/material.dart';
import 'package:ziwei_core/ziwei_core.dart';
import 'package:nihaisha_app/data/yijing_data.dart';
import 'package:nihaisha_app/engine/minggua_engine.dart';
import 'package:nihaisha_app/engine/bazi_analysis.dart';
import 'package:nihaisha_app/data/minggua_data.dart';
import 'package:nihaisha_app/engine/yijing_engine.dart';
import 'yijing_detail_screen.dart';
import 'markdown_doc_screen.dart';

/// 四柱命卦计算器：生辰 → 八字 → 先天卦（前半生）/ 后天卦（后半生）。
/// 算法依倪师《天纪·四柱命卦》讲义并经原文示例校准；值年卦需皇极经世查条表，暂不自动算。
class MingGuaCalculatorScreen extends StatefulWidget {
  const MingGuaCalculatorScreen({super.key});

  @override
  State<MingGuaCalculatorScreen> createState() =>
      _MingGuaCalculatorScreenState();
}

class _MingGuaCalculatorScreenState extends State<MingGuaCalculatorScreen> {
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

  int _year = 1995;
  int _month = 8;
  int _day = 16;
  int _shiChenIndex = 5;
  bool _isMale = true;

  MingGuaResult? _result;
  String? _baziNote;
  String _baziExtra = ''; // 四柱十神 + 纳音
  BaZiAnalysis? _baziAnalysis; // 八字详批（神煞/格局/用神）
  String? _error;

  void _compute() {
    setState(() {
      _result = null;
      _error = null;
      _baziNote = null;
    });
    try {
      final ruleset = ConfigLoader.getDefault();
      final date = ZiweiDate.fromSolar(
        AstroDateTime(_year, _month, _day, _shiChen[_shiChenIndex].$2, 0),
        gender: _isMale ? Gender.male : Gender.female,
        options: ruleset.calendarOptions,
        useTrueSolarTime: true,
      );
      final bz = date.bazi;
      final r = MingGuaEngine.compute(
        yearGan: bz.year.gan.label,
        yearZhi: bz.year.zhi.label,
        monthGan: bz.month.gan.label,
        monthZhi: bz.month.zhi.label,
        dayGan: bz.day.gan.label,
        dayZhi: bz.day.zhi.label,
        timeGan: bz.time.gan.label,
        timeZhi: bz.time.zhi.label,
        male: _isMale,
      );
      if (!mounted) return;
      setState(() {
        _baziNote = '农历 ${date.lunar}';
        _result = r;
        // 四柱十神（日柱为日主）+ 六十甲子纳音
        final gans = [
          bz.year.gan.label,
          bz.month.gan.label,
          bz.day.gan.label,
          bz.time.gan.label,
        ];
        final zhis = [
          bz.year.zhi.label,
          bz.month.zhi.label,
          bz.day.zhi.label,
          bz.time.zhi.label,
        ];
        final shen = [
          shiShenOf(bz.day.gan.label, gans[0]),
          shiShenOf(bz.day.gan.label, gans[1]),
          '日主',
          shiShenOf(bz.day.gan.label, gans[3]),
        ];
        final nayin = [
          nayinOf(gans[0], zhis[0]),
          nayinOf(gans[1], zhis[1]),
          nayinOf(gans[2], zhis[2]),
          nayinOf(gans[3], zhis[3]),
        ];
        const labels = ['年', '月', '日', '时'];
        _baziExtra =
            '十神  ${[for (var i = 0; i < 4; i++) '${labels[i]}${shen[i]}'].join(' · ')}\n'
            '纳音  ${[for (var i = 0; i < 4; i++) '${labels[i]}${nayin[i]}'].join(' · ')}';
        // 八字详批（神煞/格局/日主强弱/五行/用神忌神）
        _baziAnalysis = analyzeBaZi(gans: gans, zhis: zhis);
        if (r == null) {
          _error = '此八字超出可校准范围，无法成卦（卦数无效或入中宫）；可到讲义库阅读取数方法。';
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = '计算失败：$e');
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('四柱命卦')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
                    '依倪师《天纪·四柱命卦》讲义推算先天/后天卦；'
                    '属传统文化参考，非医疗建议。',
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
          if (_result != null) ...[
            const SizedBox(height: 12),
            _buildResult(cs, _result!),
          ],
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_error!, style: TextStyle(color: cs.error)),
            ),
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _compute,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('排四柱命卦'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(ColorScheme cs, MingGuaResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '八字（${_isMale ? '男' : '女'}命）',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  r.baziFull,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_baziNote != null)
                  Text(
                    _baziNote!,
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
                if (_baziExtra.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 10,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _baziExtra,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                if (_baziAnalysis != null) ...[
                  const SizedBox(height: 10),
                  _buildBaziAnalysisCard(cs, _baziAnalysis!),
                ],
                const SizedBox(height: 6),
                Text(
                  '阳数(天数)=${r.yangNumber}（−25→${r.upperNumber}）'
                  '· 阴数(地数)=${r.yinNumber}（−30→${r.lowerNumber}）',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _HexCard(
          label: '先天卦（前半生）',
          hex: r.xianTian,
          onTap: () => _open(r.xianTian),
        ),
        const SizedBox(height: 12),
        _HexCard(
          label: '后天卦（后半生·天旋地转）',
          hex: r.houTian,
          onTap: () => _open(r.houTian),
        ),
        const SizedBox(height: 16),
        Text(
          '先天卦主前半生、后天卦主后半生（倪师讲义「先天卦和后天卦是反的」）。'
          '值年卦（流年卦）依赖皇极经世查条表，本工具暂不自动计算，可于讲义库阅读。'
          '先天卦算法已按原文示例校准（甲子·丁卯·庚申·庚辰 阳男 → 天风姤）。',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: cs.outline, height: 1.6),
        ),
      ],
    );
  }

  void _open(Hexagram hex) {
    final asset = mingGuaLectureAsset(hex.seq);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${hex.name} ${YiJingEngine.symbol(hex.seq)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => YiJingHexagramDetailScreen(hex: hex),
                    ),
                  );
                },
                icon: const Icon(Icons.details),
                label: const Text('卦详情（卦辞/爻辞/人间道）'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: asset == null
                    ? null
                    : () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MarkdownDocScreen(
                              title: '四柱命卦·${hex.name}',
                              asset: asset,
                              footer: '倪师《天纪·四柱命卦》讲义 · 传统文化参考',
                            ),
                          ),
                        );
                      },
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('倪师四柱命卦讲义'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 八字详批卡：格局 / 日主强弱 / 神煞 / 五行 / 用神忌神。
  Widget _buildBaziAnalysisCard(ColorScheme cs, BaZiAnalysis a) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.secondaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined, size: 16, color: cs.primary),
              const SizedBox(width: 6),
              const Text('八字详批',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('格局 · ${a.pattern}',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: cs.primary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(a.patternDesc,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              _chip(cs, '日主 ${a.dayMaster}', cs.onSurface),
              _chip(cs, a.strengthLevel, _strengthColor(cs, a.strengthLevel)),
            ],
          ),
          if (a.shensha.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('神煞',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final s in a.shensha)
                  _chip(cs, '${s.name} · ${s.pillar}${s.pos}', cs.primary),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Text('五行',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          Row(
            children: [
              for (final e in a.fiveElements) ...[
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: e.status == '缺'
                          ? cs.surfaceContainerHighest
                          : cs.primaryContainer.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      children: [
                        Text(e.element,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(e.status,
                            style: TextStyle(
                                fontSize: 10, color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('用神',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.primary)),
              for (final x in a.favorable)
                _chip(cs, x, Colors.teal.shade700),
              Text('忌神',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cs.error)),
              for (final x in a.unfavorable) _chip(cs, x, cs.error),
            ],
          ),
          const SizedBox(height: 6),
          Text(a.suggestion,
              style: TextStyle(
                  fontSize: 12, height: 1.5, color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _chip(ColorScheme cs, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(text,
          style: TextStyle(fontSize: 11, color: color)),
    );
  }

  Color _strengthColor(ColorScheme cs, String level) {
    switch (level) {
      case '极旺':
      case '身强':
        return Colors.deepOrange.shade800;
      case '极弱':
      case '身弱':
        return Colors.blue.shade700;
      default:
        return cs.primary;
    }
  }
}

class _HexCard extends StatelessWidget {
  final String label;
  final Hexagram hex;
  final VoidCallback onTap;

  const _HexCard({required this.label, required this.hex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                YiJingEngine.symbol(hex.seq),
                style: const TextStyle(fontSize: 44),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: cs.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '第${hex.seq}卦 · ${hex.name}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '「${hex.judgement}」',
                      style: const TextStyle(height: 1.4),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
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
