import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nihaisha_app/data/settings_repository.dart';
import 'package:nihaisha_app/screens/llm_ask_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';

/// 「问倪师AI」页原先没有繁体开关（开关对该页无效，答文恒简体）。
/// 本回归锁两件事：① 开关在 AppBar 上存在 ② 点一下能翻转且不崩。
/// 繁简转换本身走 OpenCC 插件，单元测试环境不可用会退回简体，故不断言字形。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('问倪师AI 页有繁体开关且可翻转', (tester) async {
    await tester.runAsync(() async {
      await SettingsRepository.instance.setTraditionalDisplayEnabled(false);
    });

    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true, extensions: [AppColors.light]),
      home: const LlmAskScreen(),
    ));
    await tester.pump();

    expect(find.byTooltip('繁体显示'), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.byTooltip('繁体显示'));
      // 开关内部 await 了数据库写入，必须在真实事件循环里等它落地。
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byTooltip('关闭繁体显示'), findsOneWidget);
    expect(SettingsRepository.instance.traditionalDisplayEnabled, isTrue);

    // 复位：开关是全局单例，避免污染其他用例。
    await tester.runAsync(() async {
      await SettingsRepository.instance.setTraditionalDisplayEnabled(false);
    });
  });
}
