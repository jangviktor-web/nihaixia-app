import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:share_plus/share_plus.dart';

import 'package:nihaisha_app/services/bazi_service.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart' show resolveBirthSolar;
import 'package:nihaisha_app/data/settings_repository.dart';
import 'package:nihaisha_app/data/saved_chart_repository.dart';
import 'package:nihaisha_app/engine/bazi_twelve_stages.dart' show TwelveStageMode;
import 'package:ziwei_core/ziwei_core.dart' show Location;

import 'package:nihaisha_app/widgets/bazi_location_picker.dart';
import 'package:nihaisha_app/widgets/bazi_fortune_card.dart';
import 'package:nihaisha_app/widgets/bazi_paipan_widgets.dart';

/// 八字排盘：生辰 → 四柱 + 十神 + 旬空 + 刑冲合害 + 长生十二神 + 八字详批。
///
/// 四柱取自项目内 [ZiweiDate.bazi]（与命盘 / 黄历同口径），其余关系检测复用既有
/// 纯函数引擎。长生十二神支持火土同宫 / 水土同宫两种口径（见 [TwelveStageMode]）。
/// 内容属传统命理文化参考，非医疗建议。
class BaZiPaipanScreen extends StatefulWidget {
  const BaZiPaipanScreen({super.key});

  @override
  State<BaZiPaipanScreen> createState() => _BaZiPaipanScreenState();
}

class _BaZiPaipanScreenState extends State<BaZiPaipanScreen> {
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
  bool _fireEarthSame = true; // 长生十二神口径：火土同宫(默认) / 水土同宫
  bool _earlyZiShi = false; // 早晚子时口径：晚子时(默认，23:00–24:00算次日) / 早子时(算当日)
  String? _locName; // 出生地点（真太阳时校正；null=未设置→引擎默认东经120°）
  double? _locLng;
  double? _locLat;

  BaZiPaipan? _result;
  BaZiFortune? _fortune;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 同步共享排盘设置（与设置页双向一致）
    _fireEarthSame = SettingsRepository.instance.fireEarthSame;
    _earlyZiShi = !SettingsRepository.instance.lateZiShiEnabled; // 全局晚子时(true) -> 早子时取反
    _locName = SettingsRepository.instance.lastCityName;
    _locLng = SettingsRepository.instance.lastLng;
    _locLat = SettingsRepository.instance.lastLat;
  }

  void _compute() {
    setState(() {
      _result = null;
      _error = null;
    });
    try {
      final hour = _shiChen[_shiChenIndex].$2;
      final solar = DateTime(_year, _month, _day, hour, 0);
      final location =
          (_locLng != null) ? Location(_locLng!, _locLat ?? 30) : null;
      final r = computeBaZiPaipan(
        solar,
        isMale: _isMale,
        useTrueSolarTime: true,
        twelveStageMode: _fireEarthSame
            ? TwelveStageMode.fireEarthSame
            : TwelveStageMode.waterEarthSame,
        earlyZiShi: _earlyZiShi,
        location: location,
      );
      if (!mounted) return;
      setState(() {
        _result = r;
        _fortune = computeBaZiFortune(
          solar,
          isMale: _isMale,
          location: location,
          earlyZiShi: _earlyZiShi,
        );
      });
    } catch (e) {
      if (mounted) setState(() => _error = '计算失败：$e');
    }
  }

  /// 拼接纯文本排盘结果（复制 / 分享共用）。
  String _buildShareText() {
    final r = _result!;
    final pillars = [r.bazi.year, r.bazi.month, r.bazi.day, r.bazi.time];
    final b = StringBuffer()
      ..writeln('【八字排盘】')
      ..writeln('四柱：${pillars.join(' ')}')
      ..writeln('十神：${r.tenGods.join(' ')}')
      ..writeln(
          '纳音：${[for (final p in pillars) nayinOfPillar(p)].join(' ')}')
      ..writeln('旬空：${r.kongWang.isEmpty ? '无' : r.kongWang.join('、')}')
      ..writeln('关系：${r.relations.isEmpty ? '无' : r.relations.join('、')}');
    final f = _fortune;
    if (f != null) {
      b.writeln(
          '起运：${f.startAge.toStringAsFixed(1)} 岁（${f.qiYunTime.year} 年交运）');
      b.writeln('大运：${f.decades.map((d) => d.ganZhi).join(' → ')}');
    }
    b.writeln('—— 来自汉唐中医（民俗文化参考，非医疗建议）');
    return b.toString();
  }

  Future<void> _copyShareText() async {
    await Clipboard.setData(ClipboardData(text: _buildShareText()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制排盘文本')),
    );
  }

  Future<void> _shareResult() async {
    await Share.share(_buildShareText(), subject: '八字排盘');
  }

  /// 将当前八字排盘存入命盘库（与紫微排盘共用同一 [SavedChartRepository]）。
  /// 存入前按当前子时口径解析生辰（晚子时归次日，与紫微存盘同口径），
  /// 回看时由紫微排盘页统一重排。
  Future<void> _saveToLibrary() async {
    if (_result == null) return;
    final hour = _shiChen[_shiChenIndex].$2;
    final solar = resolveBirthSolar(
      year: _year,
      month: _month,
      day: _day,
      hour: hour,
      minute: 0,
      enabled: !_earlyZiShi, // 全局晚子时开关（true=晚子时，与设置页同源）
    );
    final genderLabel = _isMale ? '男' : '女';
    final defaultName =
        '命盘 $_year-${_month.toString().padLeft(2, '0')}-${_day.toString().padLeft(2, '0')} $genderLabel';
    final nameCtrl = TextEditingController(text: defaultName);

    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加到命盘库'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(
            labelText: '命盘名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textInputAction: TextInputAction.done,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final v = nameCtrl.text.trim();
              Navigator.pop(ctx, v.isEmpty ? defaultName : v);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    if (name == null) return;

    final saved = SavedChart(
      name: name,
      isMale: _isMale,
      solarIso: solar.toIso8601String(),
      lng: _locLng,
      lat: _locLat,
      cityName: _locName,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    try {
      await SavedChartRepository.insert(saved);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已存入命盘库')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('存入失败：$e')),
        );
      }
    }
  }

  int _daysInMonth(int year, int month) {
    if (month < 1 || month > 12) return 31;
    if (month == 2) {
      final isLeap =
          (year % 4 == 0 && year % 100 != 0) || year % 400 == 0;
      return isLeap ? 29 : 28;
    }
    return (month == 4 || month == 6 || month == 9 || month == 11)
        ? 30
        : 31;
  }

  void _clampDay() {
    final maxDay = _daysInMonth(_year, _month);
    if (_day > maxDay) _day = maxDay;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('八字排盘'), actions: [
    if (_result != null) ...[
      IconButton(
        icon: const Icon(Icons.copy_outlined),
        tooltip: '复制排盘文本',
        onPressed: _copyShareText,
      ),
      IconButton(
        icon: const Icon(Icons.share_outlined),
        tooltip: '分享',
        onPressed: _shareResult,
      ),
    ],
  ]),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _disclaimer(cs),
          const SizedBox(height: 12),
          _buildInputCard(cs),
          BaZiLocationRow(
            cityName: _locName,
            lng: _locLng,
            lat: _locLat,
            onSelected: (city) {
              setState(() {
                _locName = city.name;
                _locLng = city.lng;
                _locLat = city.lat;
              });
              SettingsRepository.instance
                  .setLastLocation(city.name, city.lng, city.lat);
              if (_result != null) _compute(); // 地点变更后重排
            },
          ),
          if (_result != null) ...[
            const SizedBox(height: 12),
            BaZiFourPillarsCard(result: _result!),
            const SizedBox(height: 12),
            // 添加到命盘库（与紫微排盘共用命盘库；Material 图标，无 emoji）
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _saveToLibrary,
                icon: const Icon(Icons.bookmark_add_outlined),
                label: const Text('添加到命盘库'),
              ),
            ),
            const SizedBox(height: 12),
            if (_fortune != null) ...[
              BaZiFortuneCard(fortune: _fortune!),
              const SizedBox(height: 12),
            ],
            BaZiRelationsCard(result: _result!),
            const SizedBox(height: 12),
            BaZiTwelveStagesCard(result: _result!),
            const SizedBox(height: 12),
            BaZiAnalysisCard(analysis: _result!.analysis),
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

  Widget _disclaimer(ColorScheme cs) {
    return Container(
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
              '八字排盘依传统子平法推算，属民俗文化参考，非医疗建议；'
              '长生十二神口径可在下方切换。',
              style: TextStyle(fontSize: 12, color: cs.onTertiaryContainer),
            ),
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
                          child: Text(
                            '${_shiChen[i].$1} (${_shiChen[i].$3})',
                          ),
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
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('火土同宫'),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('水土同宫'),
                ),
              ],
              selected: {_fireEarthSame},
              onSelectionChanged: (s) {
                setState(() => _fireEarthSame = s.first);
                SettingsRepository.instance.setFireEarthSame(s.first);
              },
            ),
            const SizedBox(height: 12),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: false,
                  label: Text('晚子时'),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('早子时'),
                ),
              ],
              selected: {_earlyZiShi},
              onSelectionChanged: (s) {
                setState(() => _earlyZiShi = s.first);
                // 全局共享「晚子时」口径：true=晚子时，故取反写入
                SettingsRepository.instance.setLateZiShiEnabled(!s.first);
              },
            ),
            const SizedBox(height: 4),
            Text(
              '子时口径：晚子时（23:00–次日01:00 算次日，与紫微命盘同口径，主流大宗）；'
              '早子时（23:00–24:00 算当日，日柱不变）。两者仅影响子时生人。',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              '长生十二神口径：火土同宫为现代子平主流；水土同宫见于部分古籍 / 纳音派。',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _compute,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('排八字'),
              ),
            ),
          ],
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
