import 'package:flutter/material.dart';

import '../data/neijing_data.dart';
import 'neijing_library_screen.dart';
import 'neijing_search_screen.dart';
import '../theme/app_colors.dart';

/// 《人纪·黄帝内经》知识速查：五脏六腑脏象 / 五色望诊 / 常见脉象。
/// AppBar 右侧：阅读库（72 篇全文）+ 全文搜索入口。
/// 内容提炼自倪师内经讲稿（书面整理版），属传统文化参考，非医疗建议。
class NeijingKnowledgeScreen extends StatelessWidget {
  const NeijingKnowledgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('黄帝内经 · 速查'),
          actions: [
            IconButton(
              tooltip: '全文阅读库',
              icon: const Icon(Icons.menu_book_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NeijingLibraryScreen(),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: '全文搜索',
              icon: const Icon(Icons.search),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const NeijingSearchScreen(),
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '脏象', icon: Icon(Icons.account_tree_outlined)),
              Tab(text: '望诊', icon: Icon(Icons.remove_red_eye_outlined)),
              Tab(text: '脉诊', icon: Icon(Icons.monitor_heart_outlined)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _ZangFuTab(),
            _WangZhenTab(),
            _MaiZhenTab(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 脏象 Tab：十二脏腑卡
// ---------------------------------------------------------------------------
class _ZangFuTab extends StatelessWidget {
  const _ZangFuTab();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _InfoBanner(
          text: '《灵兰秘典论》以官职喻十二脏：主明则下安，以此养生则寿。',
        ),
        const SizedBox(height: 8),
        for (final card in kZangFuCards) _ZangFuCardTile(card: card),
        const SizedBox(height: 8),
        Text(
          '出处：《灵兰秘典论》《六节藏象论》《阴阳应象大论》· 倪师讲解 · 传统文化参考',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: cs.outline),
        ),
      ],
    );
  }
}

class _ZangFuCardTile extends StatelessWidget {
  final ZangFuCard card;

  const _ZangFuCardTile({required this.card});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: cs.primaryContainer,
          child: Text(
            card.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: cs.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(
          card.zhiGuan,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          card.func,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip(cs, '五行 ${card.wuXing}'),
              if (card.huaZai != '—') _chip(cs, '其华在 ${card.huaZai}'),
              if (card.chongZai != '—') _chip(cs, '其充在 ${card.chongZai}'),
              if (card.kaiQiao != '—' && !card.kaiQiao.contains('附'))
                _chip(cs, '开窍于 ${card.kaiQiao}'),
              if (card.qingZhi != '—') _chip(cs, '在志 ${card.qingZhi}'),
              if (card.shengKe != '—') _chip(cs, card.shengKe),
              if (card.tongYu != '—') _chip(cs, '通于${card.tongYu}'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            card.niShi,
            style: const TextStyle(fontSize: 12, height: 1.55),
          ),
          const SizedBox(height: 6),
          Text(
            '出处：${card.source}',
            style: TextStyle(fontSize: 10, color: cs.outline),
          ),
        ],
      ),
    );
  }

  Widget _chip(ColorScheme cs, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 望诊 Tab：五色 + 眼诊
// ---------------------------------------------------------------------------
class _WangZhenTab extends StatelessWidget {
  const _WangZhenTab();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _InfoBanner(
          text: '望诊要领：面之五色须有光泽（精微象），见病色则寿不久。'
              '「视精明、察五色」为诊法之首。',
        ),
        const SizedBox(height: 10),
        Text(
          '五色 · 正常与病色',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 6),
        for (final e in kWangZhenColors)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: _colorContainerOf(context, e.color),
                    child: Text(
                      e.color,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _colorOf(context, e.color),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e.zangFu}（${e.color}色）',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '正常：${e.normal}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.success,
                          ),
                        ),
                        Text(
                          '病色：${e.abnormal}',
                          style: TextStyle(
                            fontSize: 12,
                            color: context.colors.danger,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          e.note,
                          style: const TextStyle(fontSize: 12, height: 1.5),
                        ),
                        Text(
                          e.source,
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          '眼诊 · 观眼辨五脏（倪师）',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 6),
        for (final e in kEyeDiag)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 1,
            child: ListTile(
              leading: Icon(Icons.visibility_outlined,
                  color: cs.primary, size: 22),
              title: Text(
                '${e.zone} → ${e.zangFu}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  e.note,
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          '出处：《脉要精微论》《五脏生成》· 倪师讲解 · 传统文化参考',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: cs.outline),
        ),
      ],
    );
  }

  Color _colorOf(BuildContext context, String color) {
    switch (color) {
      case '赤':
        return context.colors.danger;
      case '白':
        return context.colors.onSurface;
      case '青':
        return context.colors.success;
      case '黄':
        return context.colors.warning;
      case '黑':
        return context.colors.onSurface;
      default:
        return context.colors.outline;
    }
  }

  Color _colorContainerOf(BuildContext context, String color) {
    switch (color) {
      case '赤':
        return context.colors.dangerContainer;
      case '白':
        return context.colors.surfaceContainerHighest;
      case '青':
        return context.colors.successContainer;
      case '黄':
        return context.colors.warningContainer;
      case '黑':
        return context.colors.surfaceContainerLow;
      default:
        return context.colors.surfaceContainerHighest;
    }
  }
}

// ---------------------------------------------------------------------------
// 脉诊 Tab：平人标准 + 常见脉 + 死脉
// ---------------------------------------------------------------------------
class _MaiZhenTab extends StatelessWidget {
  const _MaiZhenTab();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _InfoBanner(text: '诊脉以平旦为佳：阴气未动、阳气未散、饮食未进，气血未乱。'),
        const SizedBox(height: 10),
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '平人脉标准',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  kPingRenMai,
                  style: const TextStyle(fontSize: 12, height: 1.6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '脉之阴阳（寸尺定位）',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  kMaiYinYang,
                  style: const TextStyle(fontSize: 12, height: 1.6),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '常见脉象',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 6),
        for (final e in kMaiZhenCommon)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 1,
            child: ListTile(
              title: Text(
                e.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      e.diagnosis,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.detail,
                      style: const TextStyle(fontSize: 12, height: 1.5),
                    ),
                    Text(
                      e.source,
                      style: TextStyle(fontSize: 10, color: cs.outline),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        Text(
          '死脉警示（临证当慎）',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: cs.error,
          ),
        ),
        const SizedBox(height: 6),
        for (final e in kDeadPulses)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: 1,
            color: cs.errorContainer.withValues(alpha: 0.35),
            child: ListTile(
              leading: Icon(Icons.warning_amber_rounded,
                  color: cs.error, size: 22),
              title: Text(
                e.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.error,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  e.detail,
                  style: const TextStyle(fontSize: 12, height: 1.5),
                ),
              ),
              isThreeLine: true,
            ),
          ),
        const SizedBox(height: 8),
        Text(
          '出处：《脉要精微论》《平人气象论》《阴阳别论》· 倪师讲解 · 传统文化参考',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: cs.outline),
        ),
      ],
    );
  }
}

/// 顶部说明条。
class _InfoBanner extends StatelessWidget {
  final String text;

  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
              text,
              style: TextStyle(
                fontSize: 12,
                color: cs.onTertiaryContainer,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
