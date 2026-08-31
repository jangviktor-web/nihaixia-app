import 'package:flutter/material.dart';
import 'package:nihaisha_app/services/san_pan_hecan_service.dart';

/// 三盘合参承接屏（Phase 1：同屏呈现，不做合成结论）。
///
/// 从紫微 / 八字命卦任一来源屏经 [input] 进入，统一以同一出生时空推算三盘并同屏对照。
class SanPanHeCanScreen extends StatelessWidget {
  final HeCanInput input;

  const SanPanHeCanScreen({super.key, required this.input});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hecan = computeSanPanHeCan(input);

    return Scaffold(
      appBar: AppBar(title: const Text('三盘合参')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    size: 18, color: cs.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '紫微 / 八字 / 易经 同源（同一出生时空）合参，供对照参考。',
                    style: TextStyle(
                        fontSize: 12, color: cs.onTertiaryContainer),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _row(cs, Icons.star_outline, '紫微 · 命宫主星', hecan.mingGongStars),
          _row(
            cs,
            Icons.water_outlined,
            '八字 · 日主 / 用神',
            '日主 ${hecan.dayMaster}　用神 ${hecan.favorable}',
          ),
          _row(
            cs,
            Icons.account_tree_outlined,
            '八字 · 十神',
            '年 ${hecan.tenGods[0]} · 月 ${hecan.tenGods[1]} · '
            '日 ${hecan.tenGods[2]} · 时 ${hecan.tenGods[3]}',
          ),
          _row(
            cs,
            Icons.auto_awesome_outlined,
            '易经 · 先天 / 后天卦',
            '${hecan.xianTianName} / ${hecan.houTianName}',
          ),
          _row(cs, Icons.calendar_today_outlined, '八字四柱',
              hecan.baziFull),
          _row(cs, Icons.filter_alt_outlined, '八字 · 旬空（空亡）',
              hecan.kongWang),
          if (!hecan.mingGuaAvailable)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text(
                '本命卦超出可校准范围暂不可用（可到讲义库阅读取数方法）。',
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            '属民俗文化参考，非科学诊断；具体用方请遵医嘱。',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _row(ColorScheme cs, IconData icon, String label, String text) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: cs.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(text,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
