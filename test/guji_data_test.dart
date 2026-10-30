// 古籍原文库回归：解析结果与书目元数据。
// 运行：flutter test test/guji_data_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/data/guji_data.dart';
import 'package:nihaisha_app/screens/guji_library_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('书目元数据：2 本、id 唯一、章数与实测一致', () {
    expect(kGujiBooks.length, 2);
    expect(kGujiBooks.map((b) => b.id).toSet().length, 2);
    final expected = {'lingshu': 82, 'zhenjiudacheng': 339};
    for (final book in kGujiBooks) {
      expect(book.chapterCount, expected[book.id], reason: '${book.id} 章数');
    }
  });

  test('解析分隔线结构：章节标题与正文都不为空', () {
    final raw = '''
《测试书》

========================================
第1章　序
========================================
第一段正文。
第二段正文。

========================================
第2章　正文
========================================
内容一。
''';
    final chapters = GujiRepository.parse(raw);
    expect(chapters.length, 2);
    expect(chapters[0].title, '第1章　序');
    expect(chapters[0].body.contains('第一段正文'), isTrue);
    expect(chapters[1].title, '第2章　正文');
    expect(chapters[1].index, 1);
  });

  test('真实资产解析：各本章数正确且首章标题非空', () async {
    GujiRepository.clearCache();
    for (final book in kGujiBooks) {
      final chapters = await GujiRepository.chaptersOf(book);
      expect(chapters.length, book.chapterCount, reason: book.id);
      expect(chapters.first.title.trim().isNotEmpty, isTrue, reason: book.id);
      expect(chapters.first.body.trim().isNotEmpty, isTrue, reason: book.id);
    }
  });

  testWidgets('书库页渲染全部书目', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: GujiLibraryScreen()));
    for (final book in kGujiBooks) {
      expect(find.text(book.title), findsOneWidget);
    }
  });
}
