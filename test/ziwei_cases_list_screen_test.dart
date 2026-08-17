import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/screens/ziwei_cases_list_screen.dart';

void main() {
  testWidgets('案例库页渲染总论/宫详解/案例分组', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ZiweiCasesListScreen()),
    );

    expect(find.text('倪师紫微案例与十二宫'), findsOneWidget);
    expect(find.text('十二宫总论'), findsOneWidget);
    expect(find.text('紫微十二宫详解（按紫微所在宫）'), findsOneWidget);

    // 顶部可见：总论 + 前言
    expect(find.text('总'), findsOneWidget);
    expect(find.text('紫微十二宫详解·前言'), findsOneWidget);

    // 滚动到案例分组
    await tester.scrollUntilVisible(find.text('案例库（按命宫地支分组）'), 400);
    expect(find.text('案例库（按命宫地支分组）'), findsOneWidget);
  });
}
