import 'package:flutter/material.dart';

import '../data/zhenjiu_lecture_data.dart';
import 'classic_library_screen.dart';

/// 《人纪·针灸》阅读库：按篇浏览倪师针灸讲稿（书面整理版）。
/// 点按进入 MarkdownDocScreen 渲染，正文内方剂 / 药材 / 穴位名自动可点跳详情。
class ZhenjiuLibraryScreen extends StatelessWidget {
  const ZhenjiuLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ClassicLibraryScreen(
      title: '针灸讲稿 · 倪师人纪',
      infoText:
          '《人纪·针灸》讲稿书面整理版（${kZhenJiuLectures.length} 篇）：从使用时机、'
          '经络穴位到从头到脚治症。与「穴位讲解」并列：讲解是逐穴速查，这里是系统学习。',
      footer: '出处：倪海厦《人纪·针灸》讲稿 · 传统文化参考，非医疗建议',
      lectures: kZhenJiuLectures,
      seqLabel: (s) => '${s + 1}',
    );
  }
}
