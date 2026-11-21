// 问倪师AI 的入口契约：prefill 预填输入框；freshSession 不接续旧会话。
// 自查页「带着这个结果问倪师 AI」依赖这两点。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nihaisha_app/screens/llm_ask_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => databaseFactory = databaseFactoryFfi);

  Future<void> pumpScreen(WidgetTester tester, {required bool fresh}) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true, extensions: [AppColors.light]),
      home: LlmAskScreen(
        prefill: '【四诊·问诊】睡眠：半夜1-3点醒\n【寒热总纲】手脚冰冷（阴·阳虚）',
        freshSession: fresh,
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('prefill 文本进入输入框，且保留换行', (tester) async {
    await pumpScreen(tester, fresh: true);
    final field = tester.widget<TextField>(
      find.byType(TextField).first,
    );
    expect(field.controller?.text, contains('【四诊·问诊】'));
    expect(field.controller?.text, contains('半夜1-3点醒'));
    expect(field.controller?.text, contains('\n'));
  });

  testWidgets('freshSession 与默认构造都能打开，不抛异常', (tester) async {
    await pumpScreen(tester, fresh: true);
    expect(find.byType(LlmAskScreen), findsOneWidget);

    // 默认 false 是现有 5 个入口的行为，必须保持
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true, extensions: [AppColors.light]),
      home: const LlmAskScreen(),
    ));
    await tester.pump();
    expect(find.byType(LlmAskScreen), findsOneWidget);
  });
}
