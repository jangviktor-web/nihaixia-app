import 'package:flutter/material.dart';

import '../data/neijing_lecture_data.dart';
import 'markdown_doc_screen.dart';

/// 《人纪·黄帝内经》阅读库：按篇浏览 72 篇正文 + 前言。
/// 点按进入 MarkdownDocScreen 渲染原文（正文内已知方剂名自动可点跳方剂详情）。
class NeijingLibraryScreen extends StatelessWidget {
  const NeijingLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('黄帝内经 · 阅读库')),
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
                    '《素问》72 篇 + 前言（倪师讲稿书面整理版）。原文第 25、66-74 篇原稿未收录。',
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
          for (final l in kNeiJingLectures)
            Card(
              margin: const EdgeInsets.only(bottom: 6),
              elevation: 1,
              child: ListTile(
                dense: true,
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    l.seq == 0 ? '序' : '${l.seq}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                title: Text(
                  l.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  l.seq == 0 ? '全书导读' : '第${l.seq}篇',
                  style: TextStyle(fontSize: 11, color: cs.outline),
                ),
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => MarkdownDocScreen(
                        title: l.name,
                        asset: l.asset,
                        footer: '出处：《人纪·黄帝内经》倪师讲稿 · 传统文化参考',
                        linkFormulas: true,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
