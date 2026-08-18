import 'package:flutter/material.dart';

class ZiWuLiuZhuScreen extends StatefulWidget {
  const ZiWuLiuZhuScreen({super.key});

  @override
  State<ZiWuLiuZhuScreen> createState() => _ZiWuLiuZhuScreenState();
}

class _ZiWuLiuZhuScreenState extends State<ZiWuLiuZhuScreen> {
  DateTime _selectedDate = DateTime.now();

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

  // 日干推算：已知2000-01-01为庚辰日（日干序6=庚）
  static const _baseGanIndex = 6; // 庚

  int _getDayGanIndex(DateTime date) {
    final base = DateTime(2000, 1, 1);
    final diff = date.difference(base).inDays;
    return ((_baseGanIndex + diff) % 10 + 10) % 10;
  }

  // 时辰索引（根据当前小时+分钟）
  int _getShichenIndex(DateTime dt) {
    // 每个时辰2小时，子时从23:00开始
    final h = dt.hour;
    final m = dt.minute;
    final minutes = h * 60 + m;
    // 子时 23:00-01:00 = 1380-60
    if (minutes >= 1380 || minutes < 60) return 0; // 子
    // 丑时 01:00-03:00 = 60-180
    if (minutes < 180) return 1; // 丑
    // 寅时 03:00-05:00 = 180-300
    if (minutes < 300) return 2; // 寅
    // 卯时 05:00-07:00 = 300-420
    if (minutes < 420) return 3; // 卯
    // 辰时 07:00-09:00 = 420-540
    if (minutes < 540) return 4; // 辰
    // 巳时 09:00-11:00 = 540-660
    if (minutes < 660) return 5; // 巳
    // 午时 11:00-13:00 = 660-780
    if (minutes < 780) return 6; // 午
    // 未时 13:00-15:00 = 780-900
    if (minutes < 900) return 7; // 未
    // 申时 15:00-17:00 = 900-1020
    if (minutes < 1020) return 8; // 申
    // 酉时 17:00-19:00 = 1020-1140
    if (minutes < 1140) return 9; // 酉
    // 戌时 19:00-21:00 = 1140-1260
    if (minutes < 1260) return 10; // 戌
    // 亥时 21:00-23:00 = 1260-1380
    return 11; // 亥
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
    final colorScheme = Theme.of(context).colorScheme;

    // 计算结果
    final dayGanIndex = _getDayGanIndex(_selectedDate);
    final dayGan = _tianGan[dayGanIndex];
    final dayOrgan = _ganToOrgan[dayGan]!;

    final shichenIndex = _getShichenIndex(_selectedDate);
    final zhi = _diZhi[shichenIndex];
    final (meridian, timeRange) = _zhiToMeridian[zhi]!;
    final benXuePoint = _getBenXue(meridian);
    final wuMenInfo = _getWuMenInfo(dayGan);

    return Scaffold(
      appBar: AppBar(title: const Text('子午流注取穴计算器')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 时间输入
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
                          onPressed: _pickDate,
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: Text(
                            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time, size: 18),
                          label: Text(
                            '${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _selectedDate = DateTime.now()),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('当前时间'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // 时辰信息
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

          // 日天干→脏腑
          _ResultCard(
            icon: Icons.person,
            title: '日天干 → 脏腑',
            content: '$dayGan → $dayOrgan',
            subtitle: '天干歌：${_getTianGanSong()}',
            color: colorScheme,
          ),
          const SizedBox(height: 8),

          // 时辰→经络
          _ResultCard(
            icon: Icons.route,
            title: '时辰 → 经络',
            content: '$zhi时 → $meridian',
            subtitle: '地支歌：${_getDiZhiSong()}',
            color: colorScheme,
          ),
          const SizedBox(height: 8),

          // 本穴推荐
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

          // 五门十变
          _ResultCard(
            icon: Icons.swap_horiz,
            title: '五门十变',
            content: wuMenInfo,
            subtitle: '日干$dayGan的合化关系',
            color: colorScheme,
          ),
          const SizedBox(height: 16),

          // 参考表
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
                    children: _tianGan.map((g) {
                      final organ = _ganToOrgan[g]!;
                      final isCurrent = g == dayGan;
                      return Chip(
                        label: Text('$g→$organ',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
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
                    children: _diZhi.map((z) {
                      final (m, t) = _zhiToMeridian[z]!;
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
              title: const Text('本穴对照表'),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      ..._benXue.entries.map((e) {
                        final isCurrent = e.key == meridian;
                        return Chip(
                          label: Text('${e.key}→${e.value}',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                          backgroundColor: isCurrent ? colorScheme.tertiaryContainer : null,
                        );
                      }),
                      Chip(label: Text('心包经→阴谷（归癸·肾）', style: TextStyle(fontSize: 12, fontWeight: meridian == '心包经' ? FontWeight.bold : FontWeight.normal)),
                          backgroundColor: meridian == '心包经' ? colorScheme.tertiaryContainer : null),
                      Chip(label: Text('三焦经→通谷（寄壬·膀胱）', style: TextStyle(fontSize: 12, fontWeight: meridian == '三焦经' ? FontWeight.bold : FontWeight.normal)),
                          backgroundColor: meridian == '三焦经' ? colorScheme.tertiaryContainer : null),
                    ],
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
                    children: _wuMen.map((w) {
                      final (a, b, element, acupoints) = w;
                      final isActive = dayGan == a || dayGan == b;
                      return Container(
                        color: isActive ? colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('$a$b合化$element',
                                  style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                            ),
                            Text(acupoints, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTianGanSong() => '甲胆乙肝丙小肠，丁心戊胃己脾乡，庚属大肠辛属肺，壬属膀胱癸肾藏，三焦亦向壬中寄，包络同归入癸水';

  String _getDiZhiSong() => '寅肺卯大肠辰胃巳脾，午心未小肠申膀胱酉肾，戌心包亥三焦子胆丑肝';
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
