import 'package:flutter/material.dart';
import 'package:nihaisha_app/data/herb_repository.dart';
import 'package:nihaisha_app/models/herb.dart';
import 'package:nihaisha_app/screens/herb_detail_screen.dart';
import 'package:nihaisha_app/services/solar_term_service.dart';

/// 首页「当前节气」卡片：展示当前节气、距下一节气倒计时、养生要点，
/// 并按当季药性从本草库联动推荐 2 味参考药材（可点进详情）。
class SolarTermCard extends StatefulWidget {
  const SolarTermCard({super.key});

  @override
  State<SolarTermCard> createState() => _SolarTermCardState();
}

class _SolarTermCardState extends State<SolarTermCard> {
  late final SolarTermInfo _info;
  bool _herbsReady = false;

  @override
  void initState() {
    super.initState();
    _info = getCurrentSolarTerm();
    // 本草库可能尚未加载（首次进入首页时），确保加载后再显示联动药材。
    HerbRepository.load().then((_) {
      if (mounted) setState(() => _herbsReady = true);
    });
  }

  List<Herb> _seasonHerbs() {
    if (!_herbsReady) return const [];
    return HerbRepository.getByNature(_info.seasonNature).take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final herbs = _seasonHerbs();
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: cs.primary, width: 4)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.eco, color: cs.primary, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _info.currentTerm.isEmpty
                          ? '当前节气'
                          : '当前节气 · ${_info.currentTerm}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ),
                  if (_info.daysLeft > 0)
                    Text(
                      '距${_info.nextTerm} ${_info.daysLeft} 天',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(_info.healthTip, style: const TextStyle(fontSize: 13)),
              if (herbs.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(Icons.spa, size: 14, color: cs.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text(
                      '当季本草参考',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: herbs.map((h) {
                    return ActionChip(
                      avatar: Icon(h.natureIcon, size: 14),
                      label: Text('${h.name}（${h.natureCategory}）'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => HerbDetailScreen(herb: h)),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
