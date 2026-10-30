import 'package:flutter/material.dart';
import 'package:ziwei_core/ziwei_core.dart' show Location;

import 'package:nihaisha_app/services/bazi_service.dart'
    show BaZiPaipan, computeBaZiPaipan;
import 'package:nihaisha_app/services/city_location_service.dart'
    show CityLocation;
import 'package:nihaisha_app/data/settings_repository.dart';
import 'package:nihaisha_app/widgets/bazi_location_picker.dart' show BaZiLocationRow;
import 'package:nihaisha_app/data/guansha_data.dart'
    show GuanshaEntry, searchGuansha;
import 'package:nihaisha_app/engine/guansha_engine.dart'
    show GuanshaHit, matchGuansha, describeRule;

/// 小儿关煞 —— 生辰测算 + 百科浏览。
///
/// 测算：输入儿童公历生辰（日期 + 时辰 + 性别 + 出生地）→ 复用八字引擎算四柱
/// → 自动判定犯哪些关煞（按 重关 > 中关 > 轻关 排序）。
/// 百科：36 关 + 18 扩展煞可搜索 / 浏览。
/// 属传统民俗文化参考，非医学或命理定论。
class GuanshaScreen extends StatefulWidget {
  const GuanshaScreen({super.key});

  @override
  State<GuanshaScreen> createState() => _GuanshaScreenState();
}

class _GuanshaScreenState extends State<GuanshaScreen>
    with SingleTickerProviderStateMixin {
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

  late final TabController _tabController;

  DateTime _birthDate = DateTime(2022, 11, 15);
  int _birthHour = 10; // 出生小时（0-23），默认巳时约 10:00
  int _birthMinute = 0; // 出生分钟（0-59）
  bool _isMale = true;
  bool _useTrueSolarTime = true; // 真太阳时校准（默认开启）
  bool _distinguishZiShi = false; // 区分早晚子时（默认关）
  String? _locName;
  double? _locLng;
  double? _locLat;

  BaZiPaipan? _paipan;
  List<GuanshaHit>? _hits;
  String? _error;

  // 百科
  final TextEditingController _queryController = TextEditingController();
  String _query = '';
  String? _category;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // 同步共享排盘设置（与设置页 / 紫微排盘页双向一致）
    _useTrueSolarTime = SettingsRepository.instance.useTrueSolarTime;
    _distinguishZiShi =
        SettingsRepository.instance.distinguishZiShiEnabled;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  /// 由出生小时（0-23）推导时辰索引（子=0，丑=1，…；23 点归子时）。
  int _shiChenIndexOfHour(int hour) => ((hour.clamp(0, 23) + 1) ~/ 2) % 12;

  void _compute() {
    setState(() {
      _paipan = null;
      _hits = null;
      _error = null;
    });
    try {
      final solar = DateTime(_birthDate.year, _birthDate.month, _birthDate.day,
          _birthHour, _birthMinute);
      final location =
          (_locLng != null) ? Location(_locLng!, _locLat ?? 30) : null;
      final p = computeBaZiPaipan(
        solar,
        isMale: _isMale,
        useTrueSolarTime: _useTrueSolarTime,
        ratHourMode: _distinguishZiShi,
        location: location,
      );
      if (!mounted) return;
      setState(() {
        _paipan = p;
        _hits = matchGuansha(p, _isMale);
      });
    } catch (e) {
      if (mounted) setState(() => _error = '计算失败：$e');
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case '重关':
        return Colors.red.shade400;
      case '中关':
        return Colors.orange.shade400;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('小儿关煞'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '测算'),
            Tab(text: '百科'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildDisclaimer(cs),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCalcTab(cs),
                _buildWikiTab(cs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisclaimer(ColorScheme cs) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      color: cs.tertiaryContainer,
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: cs.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '小儿关煞为传统民俗说法，仅供文化参考，非医学或命理定论；儿童健康请务必咨询正规医疗机构。',
              style: TextStyle(fontSize: 12, color: cs.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcTab(ColorScheme cs) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('儿童生辰',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          '${_birthDate.year}-${_birthDate.month.toString().padLeft(2, '0')}-${_birthDate.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '时',
                          isDense: true,
                        ),
                        child: DropdownButton<int>(
                          value: _birthHour,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          items: [
                            for (int h = 0; h <= 23; h++)
                              DropdownMenuItem(
                                value: h,
                                child: Text(
                                  h == 23
                                      ? (_distinguishZiShi
                                          ? '23(晚子时)'
                                          : '23(子时)')
                                      : '$h',
                                ),
                              ),
                          ],
                          onChanged: (v) =>
                              setState(() => _birthHour = v ?? _birthHour),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: '分',
                          isDense: true,
                        ),
                        child: DropdownButton<int>(
                          value: _birthMinute,
                          isExpanded: true,
                          underline: const SizedBox.shrink(),
                          items: [
                            for (int m = 0; m <= 59; m++)
                              DropdownMenuItem(
                                value: m,
                                child: Text(m.toString().padLeft(2, '0')),
                              ),
                          ],
                          onChanged: (v) =>
                              setState(() => _birthMinute = v ?? _birthMinute),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _chip(
                      '时辰',
                      '${_shiChen[_shiChenIndexOfHour(_birthHour)].$1} '
                      '(${_shiChen[_shiChenIndexOfHour(_birthHour)].$3})',
                      cs.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('男')),
                    ButtonSegment(value: false, label: Text('女')),
                  ],
                  selected: {_isMale},
                  onSelectionChanged: (s) =>
                      setState(() => _isMale = s.first),
                ),
                const SizedBox(height: 4),
                // 真太阳时校准开关（与设置页 / 紫微排盘页同口径）
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
                  onChanged: (v) {
                    setState(() => _useTrueSolarTime = v);
                    SettingsRepository.instance.setUseTrueSolarTime(v);
                  },
                ),
                // 区分早晚子时开关（默认关闭；开启后由出生时刻自动判定早晚子时）
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    '区分早晚子时',
                    style: TextStyle(fontSize: 12),
                  ),
                  subtitle: Text(
                    '默认关闭：子时归自然日（日柱当天）。开启后 23:00-24:00 为晚子时'
                    '（日柱当天、时柱次日子时），00:00-01:00 为早子时（属当日子时、日柱当天）。',
                    style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                  ),
                  value: _distinguishZiShi,
                  onChanged: (v) {
                    setState(() => _distinguishZiShi = v);
                    SettingsRepository.instance.setDistinguishZiShiEnabled(v);
                  },
                ),
                const SizedBox(height: 8),
                BaZiLocationRow(
                  cityName: _locName,
                  lng: _locLng,
                  lat: _locLat,
                  onSelected: (CityLocation city) {
                    setState(() {
                      _locName = city.label;
                      _locLng = city.lng;
                      _locLat = city.lat;
                    });
                    // 地点变更后自动重排（与八字排盘页行为一致）
                    if (_paipan != null) _compute();
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _compute,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('测算关煞'),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(_error!, style: TextStyle(color: cs.error)),
          ),
        if (_paipan != null) ...[
          const SizedBox(height: 12),
          _buildPillarsCard(cs),
        ],
        if (_hits != null) ...[
          const SizedBox(height: 12),
          _buildResultList(cs),
        ],
      ],
    );
  }

  Widget _buildPillarsCard(ColorScheme cs) {
    final p = _paipan!;
    final pillars = [p.bazi.year, p.bazi.month, p.bazi.day, p.bazi.time];
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '出生农历：${p.lunarText}',
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _pillar(cs, '年', pillars[0]),
                _pillar(cs, '月', pillars[1]),
                _pillar(cs, '日', pillars[2]),
                _pillar(cs, '时', pillars[3]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pillar(ColorScheme cs, String label, String gz) {
    return Column(
      children: [
        Text(label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(gz, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildResultList(ColorScheme cs) {
    if (_hits!.isEmpty) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 40, color: cs.primary),
              const SizedBox(height: 8),
              const Text('未犯所列关煞', style: TextStyle(fontSize: 15)),
              const SizedBox(height: 4),
              Text('（仅依本库收录的 36 关 + 18 扩展煞判定，仅供参考）',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text('判定的关煞（按严重程度排序）',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: cs.onSurfaceVariant)),
        ),
        ..._hits!.map((h) => _buildHitCard(cs, h)),
      ],
    );
  }

  Widget _buildHitCard(ColorScheme cs, GuanshaHit h) {
    final e = h.entry;
    final accent = _severityColor(e.severity);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDetail(e),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(e.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Chip(
                    label: Text(e.severity,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
                    backgroundColor: accent.withValues(alpha: 0.18),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text('原因：${h.reason}', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              if (e.fanZheJi.isNotEmpty) ...[
                Text('犯者忌：${e.fanZheJi.join('；')}',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                const SizedBox(height: 4),
              ],
              if (e.huaJie.isNotEmpty)
                Text('化解：${e.huaJie.join('；')}',
                    style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('点击查看完整条目',
                  style: TextStyle(fontSize: 11, color: cs.primary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWikiTab(ColorScheme cs) {
    final results = searchGuansha(_query, _category);
    final categories = _allCategories();
    return Column(
      children: [
        _buildSearchBar(cs),
        _buildCategoryChips(cs, categories),
        Expanded(
          child: results.isEmpty
              ? Center(
                  child: Text('未找到相关条目',
                      style:
                          TextStyle(fontSize: 14, color: cs.onSurfaceVariant)),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  children: results.map((e) => _buildWikiCard(cs, e)).toList(),
                ),
        ),
      ],
    );
  }

  List<String> _allCategories() {
    final set = <String>{};
    for (final e in searchGuansha('')) {
      set.add(e.category);
    }
    return set.toList()..sort();
  }

  Widget _buildSearchBar(ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _queryController,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: '搜名称/别名/口诀，如 将军箭、童女关',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _queryController.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          filled: true,
          fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ColorScheme cs, List<String> categories) {
    final chips = <Widget>[
      _buildFilterChip(cs, '全部', _category == null),
    ];
    for (final c in categories) {
      chips.add(_buildFilterChip(cs, c, _category == c));
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: chips),
    );
  }

  Widget _buildFilterChip(ColorScheme cs, String label, bool selected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(
            () => _category = (selected ? null : (label == '全部' ? null : label))),
        selectedColor: cs.tertiaryContainer,
        checkmarkColor: cs.onTertiaryContainer,
        labelStyle: TextStyle(
          fontSize: 13,
          color: selected ? cs.onTertiaryContainer : cs.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildWikiCard(ColorScheme cs, GuanshaEntry e) {
    final accent = _severityColor(e.severity);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDetail(e),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.name,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(e.category,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    if (e.isExt)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text('扩展煞',
                            style: TextStyle(fontSize: 11, color: cs.primary)),
                      ),
                  ],
                ),
              ),
              Chip(
                label: Text(e.severity,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
                backgroundColor: accent.withValues(alpha: 0.18),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(GuanshaEntry e) {
    final cs = Theme.of(context).colorScheme;
    final accent = _severityColor(e.severity);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(e.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
                Chip(
                  label: Text(e.severity,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: accent)),
                  backgroundColor: accent.withValues(alpha: 0.18),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
              ],
            ),
            if (e.aliases.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('别名：${e.aliases.join('、')}',
                    style:
                        TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('类别：${e.category}${e.isExt ? '（扩展煞）' : ''}',
                  style: const TextStyle(fontSize: 13)),
            ),
            const Divider(height: 20),
            if (e.jue.isNotEmpty) ...[
              _detailSection('口诀', e.jue),
            ],
            _detailSection('查法', describeRule(e.rule)),
            if (e.fanZheJi.isNotEmpty)
              _detailSection('犯者忌', e.fanZheJi.join('；')),
            if (e.huaJie.isNotEmpty)
              _detailSection('化解方法', e.huaJie.join('；')),
            if (e.tuShi != null && e.tuShi!.isNotEmpty)
              _detailSection('图示说明', e.tuShi!),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.tertiaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '本条目为传统民俗文化参考，非医学或命理定论；儿童健康请务必咨询正规医疗机构。',
                style: TextStyle(fontSize: 12, color: cs.onTertiaryContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailSection(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(body, style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }

  /// 圆角小标签：用于展示由出生时刻推导的时辰名（与紫微排盘页同口径）。
  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          children: [
            TextSpan(
              text: '$label ',
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
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
}
