import 'package:flutter/material.dart';
import 'dosage_converter_screen.dart';
import 'ziwuliuzhu_screen.dart';
import 'diagnosis_history_screen.dart';
import 'ziwei_chart_screen.dart';
import 'yijing_screen.dart';
import 'critical_illness_list_screen.dart';
import 'medical_case_library_screen.dart';
import 'daily_almanac_screen.dart';
import 'saved_charts_screen.dart';
import 'solar_term_section_screen.dart';
import '../theme/app_colors.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('实用工具')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ToolCard(
            icon: Icons.straighten,
            title: '经方剂量换算器',
            subtitle: '古代度量衡（两/升/铢）→ 现代克数',
            color: colorScheme.primary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DosageConverterScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.trending_up,
            title: '诊断历史趋势',
            subtitle: '六经传变可视化、健康变化追踪',
            color: colorScheme.error,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DiagnosisHistoryScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.auto_awesome,
            title: '紫微斗数排盘',
            subtitle: '民俗文化参考 · 十二宫 / 四化 / 大限',
            color: colorScheme.secondary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ZiweiChartScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.access_time,
            title: '子午流注取穴计算器',
            subtitle: '输入时间自动推算开穴',
            color: colorScheme.tertiary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ZiWuLiuZhuScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.change_history,
            title: '易经六十四卦',
            subtitle: '时间/数字/手动起卦 · 卦辞爻辞 · 倪师人间道',
            color: context.colors.meridianJueyin,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const YiJingScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.medical_information,
            title: '闭门课 · 重症临床',
            subtitle: '血癌/红斑狼疮/脑瘤/肾衰竭/乳癌/肝癌 · 倪师重症思路',
            color: context.colors.danger,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CriticalIllnessListScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.history_edu,
            title: '倪师医案库（1113 例）',
            subtitle: '全量结构化医案 · 按诊断/方剂/结果检索',
            color: context.colors.info,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MedicalCaseLibraryScreen(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.calendar_month_outlined,
            title: '每日黄历',
            subtitle: '建除/彭祖百忌/冲煞/宜忌 · 民俗文化参考',
            color: context.colors.success,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DailyAlmanacScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.bookmark_add_outlined,
            title: '我的命盘库',
            subtitle: '收藏生辰排盘 · 随时回看命盘',
            color: context.colors.info,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedChartsScreen()),
            ),
          ),
          const SizedBox(height: 12),
          _ToolCard(
            icon: Icons.spa_outlined,
            title: '节气养生',
            subtitle: '24 节气健康知识 · 倪师节气解析',
            color: Theme.of(context).colorScheme.tertiary,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SolarTermSectionScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 28, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
