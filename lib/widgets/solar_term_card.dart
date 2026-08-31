import 'package:flutter/material.dart';
import 'package:nihaisha_app/screens/solar_term_section_screen.dart';
import 'package:nihaisha_app/services/solar_term_service.dart';

/// 知识库页顶部「节气养生」入口卡。
///
/// 展示当前节气与距下一节气倒计时作为引导，点击进入独立节气板块
/// [SolarTermSectionScreen]。已移除旧版「本草推荐」联动内容。
class SolarTermCard extends StatelessWidget {
  const SolarTermCard({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final info = getCurrentSolarTerm();
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SolarTermSectionScreen()),
        ),
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: cs.primary, width: 4)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(Icons.spa_outlined, color: cs.primary, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            info.currentTerm.isEmpty
                                ? '节气养生'
                                : '当前节气 · ${info.currentTerm}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: cs.primary,
                            ),
                          ),
                        ),
                        if (info.daysLeft > 0)
                          Text(
                            '距${info.nextTerm} ${info.daysLeft} 天',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '24 节气健康知识 · 倪师节气养生解析',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
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
