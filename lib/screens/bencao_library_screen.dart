import 'package:flutter/material.dart';

import '../data/bencao_lecture_data.dart';
import 'classic_library_screen.dart';

/// 《人纪·神农本草经》阅读库：按药目浏览倪师本草讲稿（书面整理版）。
/// 点按进入 MarkdownDocScreen 渲染，正文内方剂 / 药材 / 穴位名自动可点跳详情。
class BenCaoLibraryScreen extends StatelessWidget {
  const BenCaoLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ClassicLibraryScreen(
      title: '本草讲稿 · 倪师人纪',
      infoText:
          '《人纪·神农本草经》讲稿书面整理版（${kBenCaoLectures.length} 篇）：从总论药性到上中下三经每味药逐条讲解。'
          '与「本草」tab 逐药速查互补：这里是系统学习。',
      footer: '出处：倪海厦《人纪·神农本草经》讲稿 · 传统文化参考，非医疗建议',
      lectures: kBenCaoLectures,
      seqLabel: (s) => '${s + 1}',
    );
  }
}
