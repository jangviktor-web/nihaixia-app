import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nihaisha_app/screens/bookmarks_screen.dart';
import 'package:nihaisha_app/data/database_helper.dart';
import 'package:nihaisha_app/theme/app_colors.dart';

/// P2 返修复验：`_CreateFolderDialog`（controller 由弹窗 State 持有）。
///
/// 覆盖正常路径：打开 → 输入 → 创建 → 弹窗关闭、无异常。
/// 失败路径（DB 抛错仍关闭 + onCreated）见报告中的代码级确认
/// （`bookmarks_screen.dart:48-56` `try/finally`）。
void main() {
  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    DatabaseHelper.resetForTest();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true, extensions: [AppColors.light]),
        home: const BookmarksScreen(),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pumpAndSettle();
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新建文件夹'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  }

  testWidgets('新建文件夹：创建成功→弹窗关闭→无异常', (tester) async {
    await pumpScreen(tester);
    expect(tester.takeException(), isNull);

    await openDialog(tester);
    // 文件夹名带时间戳：测试库是真实文件，重复跑会不断累积记录
    final folderName = '复验文件夹${DateTime.now().microsecondsSinceEpoch}';
    await tester.enterText(
      find.descendant(
          of: find.byType(AlertDialog), matching: find.byType(TextField)),
      folderName,
    );
    // _submit 内 await insertFolder（真实 DB IO）后才 nav.pop()。
    // 首次建库 / 冷启动时固定等 800ms 不够（曾稳定失败），改为限时轮询等弹窗消失。
    await tester.runAsync(() async {
      await tester.tap(find.text('创建'));
      await tester.pump();
    });
    for (var i = 0; i < 50; i++) {
      if (find.byType(AlertDialog).evaluate().isEmpty) break;
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing, reason: '创建后弹窗应关闭');
    expect(tester.takeException(), isNull, reason: '创建流程不应抛异常');
  });

  testWidgets('新建文件夹：取消→弹窗关闭→无异常', (tester) async {
    await pumpScreen(tester);
    await openDialog(tester);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
