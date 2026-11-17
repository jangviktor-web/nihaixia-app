// 天纪三层导航：讲义 → 篇 → 节。验证点击链路与篇内短标题。
// 运行：flutter test test/tianji_navigation_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/screens/tianji_doc_list_screen.dart';
import 'package:nihaisha_app/screens/tianji_section_list_screen.dart';

/// 进入第二层并等真实 asset I/O 完成。
///
/// 不能用 pumpAndSettle：FutureBuilder 未完成时 CircularProgressIndicator 是
/// 无限动画，settle 永远等不到静止；而 asset 读取是真实 I/O，需要 runAsync
/// 让出事件循环才能真正完成。
Future<void> _openBook(WidgetTester tester, String book) async {
  await tester.tap(find.text(book));
  await tester.pump();
  // 轮询而不是定长等待：asset 读取是真实 I/O，何时完成取决于磁盘；
  // 只要有 CircularProgressIndicator 就继续让出事件循环。
  for (var i = 0; i < 30; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 50));
    final loading = find.byType(CircularProgressIndicator).evaluate().isNotEmpty;
    final tiles = find.byType(ListTile).evaluate().isNotEmpty;
    if (!loading && tiles) return;
  }
}

void main() {
  testWidgets('讲义入口按分组列出 10 篇（含地纪游记）', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TianjiDocListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('天纪讲义'), findsOneWidget); // AppBar
    // ListView 懒加载：首屏只有前两个分组
    expect(find.text('天纪总纲'), findsOneWidget);
    expect(find.text('紫微斗数'), findsOneWidget);
    for (final t in ['天机道', '十二宫详解', '星曜详解']) {
      expect(find.text(t), findsWidgets, reason: '篇「$t」应出现在首层');
    }
    // 滚到底验证末尾分组与末篇（地纪游记是最新加入的第 10 篇）
    await tester.scrollUntilVisible(find.text('地纪游记'), 400);
    expect(find.text('地纪 · 游记'), findsOneWidget);
    expect(find.text('八煞黄泉'), findsOneWidget);
  });

  testWidgets('点「天机道」进入篇内节目录，标题去篇名前缀', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TianjiDocListScreen()),
    );
    await tester.pumpAndSettle();

    await _openBook(tester, '天机道');

    expect(find.byType(TianjiSectionListScreen), findsOneWidget);
    // 篇内显示短标题：「天纪与真理」而非「天机道 · 天纪与真理」
    expect(find.text('天纪与真理'), findsOneWidget);
    expect(find.text('天机道 · 天纪与真理'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('篇内搜索能过滤节', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TianjiDocListScreen()),
    );
    await tester.pumpAndSettle();
    await _openBook(tester, '天机道');

    await tester.enterText(find.byType(TextField), '形与神');
    await tester.pump();

    // 限定在列表项内断言：搜索框自身也含「形与神」这段文本
    expect(find.widgetWithText(ListTile, '形与神'), findsOneWidget);
    expect(find.widgetWithText(ListTile, '天纪与真理'), findsNothing,
        reason: '不匹配的节应被过滤掉');
  });
}
