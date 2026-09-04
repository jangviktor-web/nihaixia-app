import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/ziwei_case_data.dart';
import 'package:nihaisha_app/screens/ziwei_doc_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';

void main() {
  testWidgets('原文阅读页渲染 Markdown 内容（总论）', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, extensions: [AppColors.light]),
        home: ZiweiDocScreen(entry: kZiweiOverview),
      ),
    );
    // 等待 rootBundle 异步加载
    await tester.pumpAndSettle();

    expect(find.text('紫微斗数十二宫（总论）'), findsOneWidget); // AppBar 标题
    expect(find.textContaining('紫微斗数十二宫'), findsWidgets); // 正文标题
    expect(find.text('倪师《天纪·天机道》原文 · 民俗文化参考 · 非医疗建议'),
        findsOneWidget);
  });
}
