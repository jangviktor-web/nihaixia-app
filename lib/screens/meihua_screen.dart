import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart' show LunarDate, AstroDateTime;

import '../data/meihua_data.dart';
import '../data/yijing_data.dart';
import '../services/bazi_service.dart' show computeBaZiPaipan;
import '../utils/chart_export.dart';
import '../utils/shake_detector.dart';

const _kZhiNames = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

int _zhiIndex(String zhi) => _kZhiNames.indexOf(zhi) + 1;

int _shiChenIndexOfHour(int hour) => ((hour.clamp(0, 23) + 1) ~/ 2) % 12;

/// 梅花易数 —— 时间 / 数字 / 随机三种起卦，主互变三卦与体用生克推演。
///
/// 属民俗文化参考，非吉凶指令。
class MeihuaScreen extends StatefulWidget {
  const MeihuaScreen({
    super.key,
    Stream<AccelerometerEvent> Function({Duration samplingPeriod})?
        accelSource,
  }) : _accelSource = accelSource ?? accelerometerEventStream;

  /// 加速度流来源。测试注入假流即可驱动「摇一摇」，不必真的摇手机。
  final Stream<AccelerometerEvent> Function({Duration samplingPeriod})
      _accelSource;

  @override
  State<MeihuaScreen> createState() => _MeihuaScreenState();
}

class _MeihuaScreenState extends State<MeihuaScreen> {
  MeihuaMethod _method = MeihuaMethod.time;
  DateTime _date = DateTime.now();
  int _shiChen = _shiChenIndexOfHour(DateTime.now().hour);
  final _firstC = TextEditingController(text: '3');
  final _secondC = TextEditingController(text: '7');
  MeihuaChart? _chart;
  String? _error;
  bool _shakeEnabled = true;
  late final ShakeDetector _shake;

  @override
  void initState() {
    super.initState();
    _shake = ShakeDetector(onShake: _onShake);
    _compute();
    if (_shakeEnabled) _startShake();
  }

  @override
  void dispose() {
    _shake.stop();
    _firstC.dispose();
    _secondC.dispose();
    super.dispose();
  }

  void _startShake() {
    // gameInterval(20ms)：摇动是百毫秒级脉冲，normal(200ms) 会漏采。
    _shake.start(
        widget._accelSource(samplingPeriod: SensorInterval.gameInterval)
            .map(_accMag));
  }

  void _toggleShake(bool v) {
    setState(() => _shakeEnabled = v);
    if (v) {
      _startShake();
    } else {
      _shake.stop();
    }
  }

  /// 摇一摇 = 切到随机起卦并重摇一卦（不动用户已输入的时间/数字）。
  void _onShake() {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _method = MeihuaMethod.random);
    _compute();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1920),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _date = picked);
      _compute();
    }
  }

  void _compute() {
    setState(() {
      _error = null;
      _chart = null;
    });
    try {
      final solar = DateTime(_date.year, _date.month, _date.day, 12, 0, 0);
      // 农历取当日正午，与八字/称骨口径一致（避免子时跨日争议）。
      final lunar = LunarDate.fromSolar(
          AstroDateTime(solar.year, solar.month, solar.day, 12, 0, 0));
      final c = switch (_method) {
        MeihuaMethod.time => _byTime(lunar.month, lunar.day),
        MeihuaMethod.number => _byNumber(lunar.month),
        MeihuaMethod.random => computeMeihuaByRandom(lunarMonth: lunar.month),
      };
      setState(() => _chart = c);
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  MeihuaChart _byTime(int lunarMonth, int lunarDay) {
    final p = computeBaZiPaipan(
      DateTime(_date.year, _date.month, _date.day, _shiChen * 2, 0),
      useTrueSolarTime: false,
      ratHourMode: false,
    );
    return computeMeihuaByTime(
      yearZhiIndex: _zhiIndex(p.zhis[0]),
      lunarMonth: lunarMonth,
      lunarDay: lunarDay,
      hourZhiIndex: _zhiIndex(p.zhis[3]),
    );
  }

  MeihuaChart _byNumber(int lunarMonth) {
    final a = int.tryParse(_firstC.text.trim());
    final b = int.tryParse(_secondC.text.trim());
    if (a == null || b == null || a < 1 || b < 1) {
      throw const FormatException('请输入两个正整数');
    }
    return computeMeihuaByNumber(
      first: a,
      second: b,
      lunarMonth: lunarMonth,
    );
  }

  /// 存图 / 分享长图：内容与结果区同源。
  void _exportImage() {
    final c = _chart;
    if (c == null) return;
    final stamp = '${_date.year}${_date.month.toString().padLeft(2, '0')}'
        '${_date.day.toString().padLeft(2, '0')}';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChartExportPage(
          title: '梅花易数',
          filename: 'meihua_$stamp.png',
          content: _buildExportContent(),
        ),
      ),
    );
  }

  Widget _buildExportContent() {
    final c = _chart!;
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('汉唐中医 · 梅花易数',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${c.methodLabel} · ${_date.year}-${_date.month.toString().padLeft(2, '0')}'
            '-${_date.day.toString().padLeft(2, '0')} ${_kZhiNames[_shiChen]}时',
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 12),
        _mainCard(cs, c),
        const SizedBox(height: 12),
        _tiYongCard(cs, c),
        const SizedBox(height: 12),
        _stagesCard(cs, c),
        const SizedBox(height: 12),
        _xiangCard(cs, c),
        const SizedBox(height: 12),
        _traceCard(cs, c),
        const SizedBox(height: 12),
        Text('仅供学习参考，非吉凶指令',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('梅花易数'),
        actions: [
          if (_chart != null)
            IconButton(
              icon: const Icon(Icons.image_outlined),
              tooltip: '存图 / 分享长图',
              onPressed: _exportImage,
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _disclaimer(cs),
          const SizedBox(height: 12),
          _inputCard(cs),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.errorContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('起卦失败：$_error',
                  style: TextStyle(fontSize: 12, color: cs.onErrorContainer)),
            ),
          ],
          if (_chart != null) ...[
            const SizedBox(height: 12),
            _mainCard(cs, _chart!),
            const SizedBox(height: 12),
            _tiYongCard(cs, _chart!),
            const SizedBox(height: 12),
            _stagesCard(cs, _chart!),
            const SizedBox(height: 12),
            _xiangCard(cs, _chart!),
            const SizedBox(height: 12),
            _traceCard(cs, _chart!),
          ],
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
              '宋·邵康节《梅花易数》。卦象/卦辞/爻辞取自本库易经数据。'
              '属民俗文化参考，非吉凶指令。',
              style: TextStyle(fontSize: 12, color: cs.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _inputCard(ColorScheme cs) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SegmentedButton<MeihuaMethod>(
              segments: const [
                ButtonSegment(value: MeihuaMethod.time, label: Text('时间')),
                ButtonSegment(value: MeihuaMethod.number, label: Text('数字')),
                ButtonSegment(value: MeihuaMethod.random, label: Text('随机')),
              ],
              selected: {_method},
              onSelectionChanged: (s) {
                setState(() => _method = s.first);
                _compute();
              },
            ),
            const SizedBox(height: 12),
            if (_method == MeihuaMethod.time) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(
                      '${_date.year}-${_date.month.toString().padLeft(2, '0')}'
                      '-${_date.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                  DropdownButton<int>(
                    value: _shiChen,
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i,
                        child: Text('${_kZhiNames[i]}时'),
                      ),
                    ),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _shiChen = v);
                      _compute();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '上卦=(年支序+月+日)%8；下卦=再+时支序%8；动爻=总和%6',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
            if (_method == MeihuaMethod.number) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _firstC,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: '第一数（上卦）',
                        isDense: true,
                      ),
                      onChanged: (_) => _compute(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _secondC,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: '第二数（下卦）',
                        isDense: true,
                      ),
                      onChanged: (_) => _compute(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '上卦=第一数%8；下卦=第二数%8；动爻=(两数之和)%6',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
            if (_method == MeihuaMethod.random)
              FilledButton.icon(
                onPressed: _compute,
                icon: const Icon(Icons.casino_outlined),
                label: const Text('随机起卦'),
              ),
            const Divider(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              dense: true,
              value: _shakeEnabled,
              onChanged: _toggleShake,
              secondary: const Icon(Icons.vibration, size: 20),
              title: const Text('摇一摇随机起卦', style: TextStyle(fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mainCard(ColorScheme cs, MeihuaChart c) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(c.methodLabel),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                Text('动爻：第${c.movingYao}爻',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 10),
            Text(c.main.name,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(
              '上${kTrigrams[c.main.upper].name}${kTrigrams[c.main.upper].symbol}'
              ' · 下${kTrigrams[c.main.lower].name}${kTrigrams[c.main.lower].symbol}',
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            _quoteBox(cs, '卦辞', c.main.judgement),
            const SizedBox(height: 8),
            _quoteBox(cs, '动爻爻辞（第${c.movingYao}爻）', c.movingYaoCi),
          ],
        ),
      ),
    );
  }

  Widget _tiYongCard(ColorScheme cs, MeihuaChart c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('体用生克',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: cs.primary)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _guaBox(cs, '体卦（我）', c.ti, c.tiWuxing,
                      c.tiWangShuai.label, cs.primaryContainer),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _guaBox(cs, '用卦（事）', c.yong, c.yongWuxing, '', null),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${c.tiWuxing} 体 · ${c.yongWuxing} 用 → ${c.mainRelation.label}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '月建${c.monthBranch}（${_zhiWuxing(c.monthBranch)}），体卦${c.tiWangShuai.label}。${c.verdict}',
                    style: const TextStyle(fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stagesCard(ColorScheme cs, MeihuaChart c) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('三阶段推演（主 → 互 → 变）',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: cs.primary)),
            const SizedBox(height: 8),
            ...c.stages.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 92,
                        child: Text('${s.name} · ${s.hexName}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        child: Text(s.detail,
                            style: const TextStyle(fontSize: 12, height: 1.4)),
                      ),
                    ],
                  ),
                )),
            const Divider(height: 20),
            Text('互卦 ${c.mutual.name} · 变卦 ${c.changed.name}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _xiangCard(ColorScheme cs, MeihuaChart c) {
    final tiX = xiangOf(c.ti);
    final yongX = xiangOf(c.yong);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('八卦取象',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: cs.primary)),
            const SizedBox(height: 8),
            _xiangRow('体', tiX),
            const SizedBox(height: 8),
            _xiangRow('用', yongX),
          ],
        ),
      ),
    );
  }

  Widget _xiangRow(String role, TrigramXiang x) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$role · ${x.name}（${x.wuxing} · ${x.direction}）',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text('家庭：${x.family}｜身体：${x.body}｜物象：${x.matters}',
            style: const TextStyle(fontSize: 12, height: 1.5)),
      ],
    );
  }

  Widget _traceCard(ColorScheme cs, MeihuaChart c) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('推算过程',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant)),
          const SizedBox(height: 4),
          ...c.trace.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(t, style: const TextStyle(fontSize: 12)),
              )),
        ],
      ),
    );
  }

  Widget _quoteBox(ColorScheme cs, String label, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.primary)),
          const SizedBox(height: 4),
          SelectableText(text, style: const TextStyle(fontSize: 14, height: 1.6)),
        ],
      ),
    );
  }

  Widget _guaBox(ColorScheme cs, String role, Trigram t, String wx,
      String extra, Color? bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg ?? cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role,
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          const SizedBox(height: 2),
          Text('${t.name}${t.symbol}',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          Text('$wx${extra.isEmpty ? '' : ' · $extra'}',
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

String _zhiWuxing(String zhi) => switch (zhi) {
      '子' || '亥' => '水',
      '丑' || '辰' || '未' || '戌' => '土',
      '寅' || '卯' => '木',
      '巳' || '午' => '火',
      _ => '金', // 申、酉
    };

/// 加速度模长：|a| 与朝向无关，缓慢倾斜时恒为重力，不会误判成摇动。
double _accMag(AccelerometerEvent e) => sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
