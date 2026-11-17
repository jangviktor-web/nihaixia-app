import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/tianji_section_repository.dart';
import 'package:nihaisha_app/screens/tianji_doc_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('天纪讲义按标题切节：每节标题与正文都不为空', () async {
    TianjiSectionRepository.clearCache();
    final sections =
        await TianjiSectionRepository.parseAll(TianjiDocListScreen.docs);

    expect(sections.length, greaterThan(100),
        reason: '9 篇讲义应切出上百节，而不是退化成几节');

    for (final s in sections) {
      expect(s.title.trim(), isNotEmpty, reason: '第 ${s.index} 节标题为空');
      expect(s.body.trim(), isNotEmpty, reason: '「${s.title}」正文为空');
      expect(s.book.trim(), isNotEmpty);
      // 标题格式：篇名 或 篇名 · 节名 [· 类目 · 节名]
      expect(s.title.split(' · ').first, s.book,
          reason: '「${s.title}」应以篇名开头');
      expect(s.title.contains('·  ·'), isFalse, reason: '「${s.title}」有重复分隔符');
    }

    // index 连续，供列表序号直接 +1 使用
    for (var i = 0; i < sections.length; i++) {
      expect(sections[i].index, i);
    }
  });

  test('天纪切节不丢内容：正文总量不超过原文总字数', () async {
    TianjiSectionRepository.clearCache();
    final sections =
        await TianjiSectionRepository.parseAll(TianjiDocListScreen.docs);
    final total = sections.fold<int>(0, (n, s) => n + s.body.length);
    // 原文 9 篇合计约 14.5 万字；切节只去标题行，不应大幅缩水
    expect(total, greaterThan(130000), reason: '切节后正文疑似被截断');
  });
}
