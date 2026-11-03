import 'package:flutter/material.dart';

import '../data/classic_lecture_data.dart';
import 'classic_library_screen.dart';
import 'guji_library_screen.dart';

/// 《人纪·伤寒论》《人纪·金匮要略》阅读库入口（知识库第 7 个 Tab 内容）。
/// 两本各一张入口卡 → [ClassicLibraryScreen]（全文阅读 + 方剂/药材自动链接）。
/// 内容出自倪师讲稿，属传统文化参考，非医疗建议。
class ShangHanJinguiScreen extends StatelessWidget {
  const ShangHanJinguiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('伤寒 · 金匮')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: cs.tertiaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.menu_book_outlined,
                    size: 18, color: cs.onTertiaryContainer),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '《人纪·伤寒论》《人纪·金匮要略》倪师讲稿全文：伤寒六经条文 + 金匮 23 篇杂病。'
                    '正文里的方剂名 / 药材名可直接点开详情。属传统文化参考，非医疗建议。',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onTertiaryContainer,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _BookCard(
            icon: Icons.account_tree_outlined,
            title: '伤寒论',
            subtitle: '六经辨证 · ${kShangHanLectures.length} 篇（条文级 + 五经概述）',
            onTap: () => _open(context, const ClassicLibraryScreen(
              title: '伤寒论 · 阅读库',
              lectures: kShangHanLectures,
              footer: '出处：《人纪·伤寒论》倪师讲稿 · 传统文化参考',
            )),
          ),
          _BookCard(
            icon: Icons.local_hospital_outlined,
            title: '金匮要略',
            subtitle: '杂病辨证 · ${kJinguiLectures.length} 篇',
            onTap: () => _open(context, const ClassicLibraryScreen(
              title: '金匮要略 · 阅读库',
              lectures: kJinguiLectures,
              footer: '出处：《人纪·金匮要略》倪师讲稿 · 传统文化参考',
            )),
          ),
          _BookCard(
            icon: Icons.auto_stories_outlined,
            title: '古籍原文',
            subtitle: '灵枢 · 针灸大成（原文，非讲稿）',
            onTap: () => _open(context, const GujiLibraryScreen()),
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

class _BookCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BookCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: cs.primaryContainer,
          child: Icon(icon, size: 20, color: cs.onPrimaryContainer),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
