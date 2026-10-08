import 'package:flutter/material.dart';
import 'package:nihaisha_app/services/ziwuliuzhu_engine.dart' as eng;

class ZiWuLiuZhuScreen extends StatefulWidget {
  const ZiWuLiuZhuScreen({super.key});

  @override
  State<ZiWuLiuZhuScreen> createState() => _ZiWuLiuZhuScreenState();
}

class _ZiWuLiuZhuScreenState extends State<ZiWuLiuZhuScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  bool _lateZi = true; // 晚子时：23:00 后日干支按次日

  late final TabController _tabController;

  // 天干
  static const _tianGan = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];

  // 地支
  static const _diZhi = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

  // 天干→脏腑
  static const _ganToOrgan = {
    '甲': '胆', '乙': '肝', '丙': '小肠', '丁': '心', '戊': '胃',
    '己': '脾', '庚': '大肠', '辛': '肺', '壬': '膀胱', '癸': '肾',
  };

  // 地支→时辰→经络
  static const _zhiToMeridian = {
    '子': ('胆经', '23:00–01:00'),
    '丑': ('肝经', '01:00–03:00'),
    '寅': ('肺经', '03:00–05:00'),
    '卯': ('大肠经', '05:00–07:00'),
    '辰': ('胃经', '07:00–09:00'),
    '巳': ('脾经', '09:00–11:00'),
    '午': ('心经', '11:00–13:00'),
    '未': ('小肠经', '13:00–15:00'),
    '申': ('膀胱经', '15:00–17:00'),
    '酉': ('肾经', '17:00–19:00'),
    '戌': ('心包经', '19:00–21:00'),
    '亥': ('三焦经', '21:00–23:00'),
  };

  // 本穴表（经络→本穴）——数据来源：倪海厦人纪讲义·针灸教程 L4316
  // 心包经归癸（肾），三焦经寄壬（膀胱），不单独列本穴
  static const _benXue = {
    '胆经': '临泣', '肝经': '行间', '小肠经': '阳谷', '心经': '少府',
    '胃经': '足三里', '脾经': '太白', '大肠经': '二间', '肺经': '经渠',
    '膀胱经': '通谷', '肾经': '阴谷',
  };

  // 心包经→癸→肾经本穴，三焦经→壬→膀胱经本穴
  String _getBenXue(String meridian) {
    if (meridian == '心包经') return '阴谷（归癸·肾经）';
    if (meridian == '三焦经') return '通谷（寄壬·膀胱经）';
    return _benXue[meridian] ?? '';
  }

  // 五门十变——数据来源：倪海厦人纪讲义·针灸教程 L4316
  static const _wuMen = [
    ('甲', '己', '土', '临泣+太白'), ('乙', '庚', '金', '行间+二间'),
    ('丙', '辛', '水', '阳谷+经渠'), ('丁', '壬', '木', '少府+通谷'),
    ('戊', '癸', '火', '足三里+阴谷'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getShichenIndex(DateTime dt) {
    final minutes = dt.hour * 60 + dt.minute;
    if (minutes >= 1380 || minutes < 60) return 0; // 子
    if (minutes < 180) return 1;
    if (minutes < 300) return 2;
    if (minutes < 420) return 3;
    if (minutes < 540) return 4;
    if (minutes < 660) return 5;
    if (minutes < 780) return 6;
    if (minutes < 900) return 7;
    if (minutes < 1020) return 8;
    if (minutes < 1140) return 9;
    if (minutes < 1260) return 10;
    return 11;
  }

  String _getWuMenInfo(String gan) {
    for (final (a, b, element, acupoints) in _wuMen) {
      if (gan == a || gan == b) {
        return '$a$b合化$element（$acupoints）';
      }
    }
    return '';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day,
          picked.hour, picked.minute,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('子午流注取穴计算器'),
        bottom: const TabBar(
          isScrollable: true,
          tabs: [
            Tab(text: '纳子法'),
            Tab(text: '纳甲法'),
            Tab(text: '灵龟八法'),
            Tab(text: '飞腾八法'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NaZiTab(
            selectedDate: _selectedDate,
            lateZi: _lateZi,
            onLateZiChanged: (v) => setState(() => _lateZi = v),
            onPickDate: _pickDate,
            onPickTime: _pickTime,
            onResetNow: () => setState(() => _selectedDate = DateTime.now()),
            tianGan: _tianGan,
            diZhi: _diZhi,
            ganToOrgan: _ganToOrgan,
            zhiToMeridian: _zhiToMeridian,
            getBenXue: _getBenXue,
            getWuMenInfo: _getWuMenInfo,
            getTianGanSong: _getTianGanSong,
            getDiZhiSong: _getDiZhiSong,
            shichenIndex: _getShichenIndex(_selectedDate),
          ),
          _NajiaTab(selectedDate: _selectedDate, lateZi: _lateZi),
          _LingGuiTab(selectedDate: _selectedDate, lateZi: _lateZi),
          _FeiTengTab(selectedDate: _selectedDate, lateZi: _lateZi),
        ],
      ),
    );
  }

  String _getTianGanSong() => '甲胆乙肝丙小肠，丁心戊胃己脾乡，庚属大肠辛属肺，壬属膀胱癸肾藏，三焦亦向壬中寄，包络同归入癸水';

  String _getDiZhiSong() => '寅肺卯大肠辰胃巳脾，午心未小肠申膀胱酉肾，戌心包亥三焦子胆丑肝';
}

// ───────────────────────── 纳子法 Tab ─────────────────────────

class _NaZiTab extends StatelessWidget {
  final DateTime selectedDate;
  final bool lateZi;
  final ValueChanged<bool> onLateZiChanged;
  final Future<void> Function() onPickDate;
  final Future<void> Function() onPickTime;
  final VoidCallback onResetNow;
  final List<String> tianGan;
  final List<String> diZhi;
  final Map<String, String> ganToOrgan;
  final Map<String, (String, String)> zhiToMeridian;
  final String Function(String) getBenXue;
  final String Function(String) getWuMenInfo;
  final String Function() getTianGanSong;
  final String Function() getDiZhiSong;
  final int shichenIndex;

  const _NaZiTab({
    required this.selectedDate,
    required this.lateZi,
    required this.onLateZiChanged,
    required this.onPickDate,
    required this.onPickTime,
    required this.onResetNow,
    required this.tianGan,
    required this.diZhi,
    required this.ganToOrgan,
    required this.zhiToMeridian,
    required this.getBenXue,
    required this.getWuMenInfo,
    required this.getTianGanSong,
    required this.getDiZhiSong,
    required this.shichenIndex,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final gz = eng.calcDayGanZhi(selectedDate, lateZi: lateZi);
    final dayGan = tianGan[gz.dayGan];
    final dayOrgan = ganToOrgan[dayGan]!;
    final zhi = diZhi[shichenIndex];
    final (meridian, timeRange) = zhiToMeridian[zhi]!;
    final benXuePoint = getBenXue(meridian);
    final wuMenInfo = getWuMenInfo(dayGan);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('选择时间', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onPickDate,
                        icon: const Icon(Icons.calendar_today, size: 18),
                        label: Text(
                          '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onPickTime,
                        icon: const Icon(Icons.access_time, size: 18),
                        label: Text(
                          '${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => onLateZiChanged(!lateZi),
                      icon: Icon(lateZi ? Icons.check_box : Icons.check_box_outline_blank, size: 16),
                      label: const Text('晚子时（23:00后按次日干支）'),
                    ),
                    TextButton.icon(
                      onPressed: onResetNow,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('当前时间'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          color: colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(zhi, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('时辰：$zhi时', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
                      const SizedBox(height: 4),
                      Text('时间：$timeRange', style: TextStyle(fontSize: 14, color: colorScheme.onPrimaryContainer)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        _ResultCard(
          icon: Icons.person,
          title: '日天干 → 脏腑',
          content: '$dayGan → $dayOrgan',
          subtitle: '天干歌：${getTianGanSong()}',
          color: colorScheme,
        ),
        const SizedBox(height: 8),
        _ResultCard(
          icon: Icons.route,
          title: '时辰 → 经络',
          content: '$zhi时 → $meridian',
          subtitle: '地支歌：${getDiZhiSong()}',
          color: colorScheme,
        ),
        const SizedBox(height: 8),
        Card(
          color: colorScheme.tertiaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: colorScheme.onTertiaryContainer),
                    const SizedBox(width: 8),
                    Text('本穴推荐（纳子法）',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onTertiaryContainer)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(benXuePoint,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: colorScheme.onTertiaryContainer)),
                const SizedBox(height: 4),
                Text('$meridian 本穴',
                    style: TextStyle(fontSize: 14, color: colorScheme.onTertiaryContainer)),
                const SizedBox(height: 6),
                Text('当$zhi时，$meridian经气最旺，取其本穴 $benXuePoint',
                    style: TextStyle(fontSize: 12, color: colorScheme.onTertiaryContainer.withValues(alpha: 0.8))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        _ResultCard(
          icon: Icons.swap_horiz,
          title: '五门十变',
          content: wuMenInfo,
          subtitle: '日干$dayGan的合化关系',
          color: colorScheme,
        ),
        const SizedBox(height: 16),
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('天干→脏腑表'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: tianGan.map((g) {
                    final organ = ganToOrgan[g]!;
                    final isCurrent = g == dayGan;
                    return Chip(
                      label: Text('$g→$organ',
                          style: TextStyle(fontSize: 12, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                      backgroundColor: isCurrent ? colorScheme.primaryContainer : null,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('地支→时辰→经络表'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: diZhi.map((z) {
                    final (m, t) = zhiToMeridian[z]!;
                    final isCurrent = z == zhi;
                    return Container(
                      color: isCurrent ? colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 30, child: Text(z, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal))),
                          SizedBox(width: 100, child: Text(t, style: const TextStyle(fontSize: 12))),
                          Expanded(child: Text(m, style: TextStyle(fontSize: 12, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal))),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: ExpansionTile(
            leading: const Icon(Icons.table_chart),
            title: const Text('五门十变表'),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(children: [Expanded(child: Text('甲己合化土')), Text('临泣+太白')]),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(children: [Expanded(child: Text('乙庚合化金')), Text('行间+二间')]),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(children: [Expanded(child: Text('丙辛合化水')), Text('阳谷+经渠')]),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(children: [Expanded(child: Text('丁壬合化木')), Text('少府+通谷')]),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(children: [Expanded(child: Text('戊癸合化火')), Text('足三里+阴谷')]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ───────────────────────── 纳甲法 Tab ─────────────────────────

class _NajiaTab extends StatelessWidget {
  final DateTime selectedDate;
  final bool lateZi;
  const _NajiaTab({required this.selectedDate, required this.lateZi});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gz = eng.calcDayGanZhi(selectedDate, lateZi: lateZi);
    final hour = eng.calcHourGanZhi(gz.dayGan, selectedDate.hour, selectedDate.minute);

    final open = eng.najiaOpen(gz.dayGan, hour.hourGan, hour.hourZhi);
    final heRi = open == null
        ? eng.najiaHeRi(gz.dayGan, hour.hourGan, hour.hourZhi)
        : null;

    final result = open ?? heRi;
    final isHeRi = open == null && heRi != null;

    final typeLabel = const {
      '井': '井穴', '荥': '荥穴', '输': '输穴', '经': '经穴', '合': '合穴',
      '纳三焦': '纳三焦（原穴）', '纳包络': '纳包络（原穴）',
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TimeHeader(selectedDate: selectedDate, gz: gz, hour: hour),
        const SizedBox(height: 12),
        if (result == null)
          _InfoCard(
            icon: Icons.info_outline,
            title: '此时无开穴',
            content: '本日此时纳甲法无正开穴，亦无合日互用可借。',
            color: colorScheme,
          )
        else ...[
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(isHeRi ? '合日互用开穴' : '纳甲正开穴',
                      style: TextStyle(fontSize: 14, color: colorScheme.onPrimaryContainer)),
                  const SizedBox(height: 8),
                  Text(result['point']!,
                      style: TextStyle(fontSize: 44, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
                  const SizedBox(height: 6),
                  Text('${result['meridian']} · ${typeLabel[result['type']] ?? result['type']}',
                      style: TextStyle(fontSize: 16, color: colorScheme.onPrimaryContainer)),
                ],
              ),
            ),
          ),
          if (result['type'] == '输' && result['yuan'] != null)
            _InfoCard(
              icon: Icons.account_balance,
              title: '返本还原',
              content: '本穴为输穴，返本还原取原穴：${result['yuan']}',
              color: colorScheme,
            ),
          if (isHeRi)
            _InfoCard(
              icon: Icons.swap_horiz,
              title: '合日互用',
              content: '本日此时无正开穴，按日干合日（日干+5）互用取穴。',
              color: colorScheme,
            ),
          const SizedBox(height: 8),
          _InfoCard(
            icon: Icons.lightbulb_outline,
            title: '说明',
            content: '纳甲法按时干、时支取穴，阳日阳时开阳经、阴日阴时开阴经；输穴返本还原，本日无穴则合日互用。',
            color: colorScheme,
          ),
        ],
      ],
    );
  }
}

// ───────────────────────── 灵龟八法 Tab ─────────────────────────

class _LingGuiTab extends StatelessWidget {
  final DateTime selectedDate;
  final bool lateZi;
  const _LingGuiTab({required this.selectedDate, required this.lateZi});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gz = eng.calcDayGanZhi(selectedDate, lateZi: lateZi);
    final hour = eng.calcHourGanZhi(gz.dayGan, selectedDate.hour, selectedDate.minute);
    final r = eng.lingguiOpen(gz.dayGan, gz.dayZhi, hour.hourGan, hour.hourZhi);
    final gua = r['gua'] as List<String>;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TimeHeader(selectedDate: selectedDate, gz: gz, hour: hour),
        const SizedBox(height: 12),
        Card(
          color: colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(gua[0], style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('主穴：${gua[1]}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
                      const SizedBox(height: 4),
                      Text('所属：${gua[2]}', style: TextStyle(fontSize: 15, color: colorScheme.onPrimaryContainer)),
                      const SizedBox(height: 8),
                      Text('配穴：${r['peidui']}（${r['peiduiMai']}）', style: TextStyle(fontSize: 15, color: colorScheme.onPrimaryContainer)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if ((r['note'] as String).isNotEmpty)
          _InfoCard(icon: Icons.info_outline, title: '特殊处理', content: r['note'] as String, color: colorScheme),
        const SizedBox(height: 8),
        _InfoCard(
          icon: Icons.functions,
          title: '推算步骤',
          content: r['step'] as String,
          color: colorScheme,
        ),
        const SizedBox(height: 8),
        _InfoCard(
          icon: Icons.lightbulb_outline,
          title: '说明',
          content: '灵龟八法以日干支、时干支基数相加，阳日÷9、阴日÷6 取余数定卦穴；主穴与配穴相配，同调八脉交会。',
          color: colorScheme,
        ),
      ],
    );
  }
}

// ───────────────────────── 飞腾八法 Tab ─────────────────────────

class _FeiTengTab extends StatelessWidget {
  final DateTime selectedDate;
  final bool lateZi;
  const _FeiTengTab({required this.selectedDate, required this.lateZi});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final gz = eng.calcDayGanZhi(selectedDate, lateZi: lateZi);
    final hour = eng.calcHourGanZhi(gz.dayGan, selectedDate.hour, selectedDate.minute);
    final ft = eng.feitengOpen(hour.hourGan);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _TimeHeader(selectedDate: selectedDate, gz: gz, hour: hour),
        const SizedBox(height: 12),
        if (ft == null)
          _InfoCard(icon: Icons.info_outline, title: '无对应', content: '此时干无飞腾八法取穴。', color: colorScheme)
        else
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(ft[0], style: TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('开穴：${ft[1]}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colorScheme.onPrimaryContainer)),
                        const SizedBox(height: 4),
                        Text('时干：${eng.ganName(hour.hourGan)}', style: TextStyle(fontSize: 15, color: colorScheme.onPrimaryContainer)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        _InfoCard(
          icon: Icons.lightbulb_outline,
          title: '说明',
          content: '飞腾八法按时干直接查卦取单穴，较灵龟八法更简，二者同属八法流派，临床常参酌并用。',
          color: colorScheme,
        ),
      ],
    );
  }
}

// ───────────────────────── 共用小组件 ─────────────────────────

class _TimeHeader extends StatelessWidget {
  final DateTime selectedDate;
  final ({int dayGan, int dayZhi}) gz;
  final ({int hourGan, int hourZhi}) hour;
  const _TimeHeader({required this.selectedDate, required this.gz, required this.hour});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')} '
              '${selectedDate.hour.toString().padLeft(2, '0')}:${selectedDate.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              '日干支：${eng.ganName(gz.dayGan)}${eng.zhiName(gz.dayZhi)}　时干支：${eng.ganName(hour.hourGan)}${eng.zhiName(hour.hourZhi)}',
              style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final ColorScheme color;
  const _InfoCard({required this.icon, required this.title, required this.content, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color.primary),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 14, color: color.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final String subtitle;
  final ColorScheme color;

  const _ResultCard({
    required this.icon,
    required this.title,
    required this.content,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color.primary),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 14, color: color.onSurfaceVariant)),
              ],
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: color.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
