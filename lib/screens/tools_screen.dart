import 'package:flutter/material.dart';
import 'dosage_converter_screen.dart';
import 'ziwuliuzhu_screen.dart';
import 'yunqi_screen.dart';
import 'diagnosis_history_screen.dart';
import 'ziwei_chart_screen.dart';
import 'yijing_screen.dart';
import 'bazi_paipan_screen.dart';
import 'critical_illness_list_screen.dart';
import 'medical_case_library_screen.dart';
import 'guji_library_screen.dart';
import 'daily_almanac_screen.dart';
import 'yuxiaji_omen_screen.dart';
import 'dream_screen.dart';
import 'guansha_screen.dart';
import 'saved_charts_screen.dart';
import 'solar_term_section_screen.dart';
import 'settings_screen.dart';
import 'chenggu_bone_screen.dart';
import 'shousheng_debt_screen.dart';
import 'huangdi_siji_screen.dart';
import 'sanshan_lingqian_screen.dart';
import 'xiaoliuren_screen.dart';
import 'meihua_screen.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';
import '../widgets/zone_section.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('实用工具')),
      body: PageBody(
        maxWidth: 1280,
        child: LayoutBuilder(
          builder: (context, constraints) {
            // 手机单列；宽屏摊成 2~3 列，电脑上不再是一根细长的工具清单。
            final columns = computeColumns(
              constraints.maxWidth,
              candidates: const [3, 2, 1],
              minTileWidth: 340,
            );
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ZoneSection(
                  zone: Zone.tcm,
                  title: '中医区',
                  icon: Icons.local_hospital,
                  columns: columns,
                  children: [
                    _ToolCard(
                      icon: Icons.straighten,
                      title: '经方剂量换算器',
                      subtitle: '古代度量衡（两/升/铢）→ 现代克数',
                      color: colorScheme.primary,
                      builder: (_) => DosageConverterScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.trending_up,
                      title: '诊断历史趋势',
                      subtitle: '六经传变可视化、健康变化追踪',
                      color: colorScheme.error,
                      builder: (_) => DiagnosisHistoryScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.access_time,
                      title: '中医时辰开穴综合计算器',
                      subtitle: '纳子 / 纳甲 / 灵龟 / 飞腾四法开穴',
                      color: colorScheme.tertiary,
                      builder: (_) => ZiWuLiuZhuScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.grain,
                      title: '五运六气推算',
                      subtitle: '岁运 / 司天在泉 / 客气六步 / 客主加临',
                      color: colorScheme.secondary,
                      builder: (_) => YunQiScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.medical_information,
                      title: '闭门课 · 重症临床',
                      subtitle: '血癌/红斑狼疮/脑瘤/肾衰竭/乳癌/肝癌 · 倪师重症思路',
                      color: context.colors.danger,
                      builder: (_) => CriticalIllnessListScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.history_edu,
                      title: '倪师医案库（1113 例）',
                      subtitle: '全量结构化医案 · 按诊断/方剂/结果检索',
                      color: context.colors.info,
                      builder: (_) => MedicalCaseLibraryScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.auto_stories_outlined,
                      title: '古籍原文',
                      subtitle: '灵枢 / 针灸大成 · 原文全文阅读',
                      color: Theme.of(context).colorScheme.secondary,
                      builder: (_) => GujiLibraryScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.spa_outlined,
                      title: '节气养生',
                      subtitle: '24 节气健康知识 · 倪师节气解析',
                      color: Theme.of(context).colorScheme.tertiary,
                      builder: (_) => SolarTermSectionScreen(),
                    ),
                  ],
                ),
                ZoneSection(
                  zone: Zone.metaphysics,
                  title: '玄学区',
                  icon: Icons.auto_awesome,
                  columns: columns,
                  children: [
                    _ToolCard(
                      icon: Icons.auto_awesome,
                      title: '紫微斗数排盘',
                      subtitle: '民俗文化参考 · 十二宫 / 四化 / 大限',
                      color: colorScheme.secondary,
                      builder: (_) => ZiweiChartScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.view_column_outlined,
                      title: '八字排盘',
                      subtitle: '四柱 + 十神 + 旬空 + 刑冲合害 + 长生十二神 · 民俗参考',
                      color: colorScheme.tertiary,
                      builder: (_) => BaZiPaipanScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.change_history,
                      title: '易经六十四卦',
                      subtitle: '时间/数字/手动起卦 · 卦辞爻辞 · 倪师人间道',
                      color: context.colors.meridianJueyin,
                      builder: (_) => YiJingScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.calendar_month_outlined,
                      title: '每日黄历',
                      subtitle: '建除/彭祖百忌/冲煞/宜忌 · 民俗文化参考',
                      color: context.colors.success,
                      builder: (_) => DailyAlmanacScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.auto_awesome,
                      title: '玉匣灵兆',
                      subtitle: '面热/眼跳/耳鸣/心惊 · 十二时辰兆占 · 民俗文化参考',
                      color: Theme.of(context).colorScheme.tertiary,
                      builder: (_) => YuxiajiOmenScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.nightlight_round,
                      title: '周公解梦',
                      subtitle: '搜梦境查吉凶 · 民俗文化参考',
                      color: Theme.of(context).colorScheme.tertiary,
                      builder: (_) => DreamScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.child_care,
                      title: '小儿关煞',
                      subtitle: '生辰测关煞 · 民俗文化参考',
                      color: Theme.of(context).colorScheme.tertiary,
                      builder: (_) => GuanshaScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.auto_awesome_mosaic,
                      title: '三山国王灵签',
                      subtitle: '祖庙 92 签 · 求签/签谱 · 民俗文化参考',
                      color: Theme.of(context).colorScheme.tertiary,
                      builder: (_) => SanshanLingqianScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.timelapse,
                      title: '小六壬',
                      subtitle: '时间起课 · 六宫顺数 · 民俗文化参考',
                      color: Theme.of(context).colorScheme.tertiary,
                      builder: (_) => XiaoliurenScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.filter_vintage,
                      title: '梅花易数',
                      subtitle: '时间/数字/随机起卦 · 体用生克 · 民俗文化参考',
                      color: Theme.of(context).colorScheme.tertiary,
                      builder: (_) => MeihuaScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.scale_outlined,
                      title: '袁天罡称骨算命',
                      subtitle: '生辰骨重 · 称骨歌诀 · 民俗文化参考',
                      color: Theme.of(context).colorScheme.tertiary,
                      builder: (_) => ChengguBoneScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.account_balance_outlined,
                      title: '受生债查询',
                      subtitle: '禄库受生经 · 五斗金章受生经 · 民俗文化参考',
                      color: Theme.of(context).colorScheme.tertiary,
                      builder: (_) => ShoushengDebtScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.accessibility_new,
                      title: '轩辕黄帝四季歌',
                      subtitle: '出生季节·时辰定黄帝部位 · 民俗文化参考',
                      color: Theme.of(context).colorScheme.tertiary,
                      builder: (_) => HuangdiSijiScreen(),
                    ),
                    _ToolCard(
                      icon: Icons.bookmark_add_outlined,
                      title: '我的命盘库',
                      subtitle: '收藏生辰排盘 · 随时回看命盘',
                      color: context.colors.info,
                      builder: (_) => SavedChartsScreen(),
                    ),
                  ],
                ),
                ZoneSection(
                  zone: Zone.general,
                  title: '通用区',
                  icon: Icons.settings,
                  columns: columns,
                  children: [
                    _ToolCard(
                      icon: Icons.settings,
                      title: '设置',
                      subtitle: '外观/诊断/排盘口径（晚子时·长生十二神）· 数据管理',
                      color: colorScheme.primary,
                      builder: (_) => SettingsScreen(),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final WidgetBuilder builder;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: builder),
        ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: onSurfaceVariant)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
