import 'package:flutter/material.dart';
import '../widgets/state_view.dart';
import 'package:nihaisha_app/services/solar_term_service.dart';

/// 节气养生独立板块。
///
/// 顶部展示当前节气卡（节气名 + 距下一节气倒计时 + 养生要点 + 倪师解析），
/// 下方为 24 节气竖向列表，每项卡片显示节气名、健康知识、倪师解析（可展开）。
/// 全部使用 Theme 语义 token，不硬编码颜色。
///
/// 内容来源：[assets/data/solar_term_knowledge.json]，倪师相关解析凡非逐字
/// 原文均已标注【推断】。
class SolarTermSectionScreen extends StatefulWidget {
  const SolarTermSectionScreen({super.key});

  @override
  State<SolarTermSectionScreen> createState() => _SolarTermSectionScreenState();
}

/// 24 节气名（日历顺序：立春 → 大寒），与 solar_term_knowledge.json 键一致。
const List<String> _termOrder = [
  '立春', '雨水', '惊蛰', '春分', '清明', '谷雨',
  '立夏', '小满', '芒种', '夏至', '小暑', '大暑',
  '立秋', '处暑', '白露', '秋分', '寒露', '霜降',
  '立冬', '小雪', '大雪', '冬至', '小寒', '大寒',
];

class _SolarTermSectionScreenState extends State<SolarTermSectionScreen> {
  SolarTermInfo? _current;
  List<SolarTermKnowledge> _all = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final current = getCurrentSolarTerm();
    final list = await Future.wait(
      _termOrder.map((t) => getSolarTermKnowledge(t)),
    );
    if (mounted) {
      setState(() {
        _current = current;
        _all = list.whereType<SolarTermKnowledge>().toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('节气养生')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: StateView.loading(),
              ),
            )
          else ...[
            if (_current != null) _currentCard(cs, _current!),
            const SizedBox(height: 16),
            Text(
              '二十四节气养生',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 8),
            ..._all.map((k) => _TermCard(k: k)),
            const SizedBox(height: 12),
            _disclaimer(cs),
          ],
        ],
      ),
    );
  }

  Widget _currentCard(ColorScheme cs, SolarTermInfo info) {
    final knowledge = _all.where((k) => k.term == info.currentTerm).firstOrNull;
    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: cs.primary, width: 4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.spa_outlined, color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    info.currentTerm.isEmpty
                        ? '当前节气'
                        : '当前节气 · ${info.currentTerm}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: cs.primary,
                    ),
                  ),
                ),
                if (info.daysLeft > 0)
                  Text(
                    '距${info.nextTerm} ${info.daysLeft} 天',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(info.healthTip, style: const TextStyle(fontSize: 13)),
            if (knowledge != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.menu_book_outlined,
                            size: 16, color: cs.onTertiaryContainer),
                        const SizedBox(width: 6),
                        Text(
                          '倪师解析',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: cs.onTertiaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      knowledge.niShi,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.6,
                        color: cs.onTertiaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _disclaimer(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '倪师原话请以《人纪》《天纪》等著作为准。以上节气养生内容属中医文化科普，'
        '不构成医疗诊断，如有不适请及时就医。',
        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant, height: 1.5),
      ),
    );
  }
}

/// 单个节气卡片：节气名 + 健康知识常驻，倪师解析可展开。
class _TermCard extends StatefulWidget {
  final SolarTermKnowledge k;
  const _TermCard({required this.k});

  @override
  State<_TermCard> createState() => _TermCardState();
}

class _TermCardState extends State<_TermCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.k.term,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      Icon(
                        _expanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: cs.onSurfaceVariant,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.k.health,
                    style: const TextStyle(fontSize: 13, height: 1.6),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.menu_book_outlined,
                          size: 14, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        _expanded ? '收起倪师解析' : '查看倪师解析',
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_expanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.k.niShi,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: cs.onTertiaryContainer,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
