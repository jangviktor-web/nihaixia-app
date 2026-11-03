import 'package:flutter/material.dart';

import '../data/jingui_lecture_data.dart';
import 'classic_library_screen.dart';

/// 《人纪·金匮要略》书面整理版讲稿阅读库（授课实录书面化，按金匮篇目通读）。
/// 与「金匮要略」条文卡阅读库并列：条文卡 = 逐条速查（「见于经典」依赖），
/// 这里 = 书面版系统学习。正文内方剂 / 药材名自动可点跳详情。
class JinguiBookLectureScreen extends StatelessWidget {
  const JinguiBookLectureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ClassicLibraryScreen(
      title: '金匮讲稿 · 倪师人纪（书面版）',
      infoText:
          '《人纪·金匮要略》授课实录书面整理版（${kJinGuiBookLectures.length} 篇）：'
          '从脏腑经络到妇人杂病逐篇通读，含条文卡未收录的课堂展开与医案。'
          '与「金匮要略」条文卡互补：条文卡是逐条速查，这里是系统学习。',
      footer: '出处：倪海厦《人纪·金匮要略》讲稿（书面整理）· 传统文化参考，非医疗建议',
      lectures:kJinGuiBookLectures,
      seqLabel: (s) => '${s + 1}',
    );
  }
}
