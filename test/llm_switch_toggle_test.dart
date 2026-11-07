// 「问倪师AI」开关必须即时生效（回归：点了滑块不动，须退出设置页重进才刷新）。
// 运行：flutter test test/llm_switch_toggle_test.dart
//
// 根因备忘：LlmSettingsSection 在父级 ListView.children 里是 const 实例，
// 父级 ListenableBuilder 重建时新旧 widget identical → Flutter Element.updateChild
// 直接跳过该子树，内部 SwitchListTile 永不重建。断言用「不退出页面」来卡这个 bug。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nihaisha_app/data/settings_repository.dart';
import 'package:nihaisha_app/screens/settings_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true, extensions: [AppColors.light]),
      home: const SettingsScreen(),
    ));
    await tester.pump();
    // 「问倪师AI」在列表末尾，ListView 懒构建 → 先滚到底才会出现
    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pump();
  }

  bool switchValue(WidgetTester tester) => tester
      .widget<SwitchListTile>(
          find.widgetWithText(SwitchListTile, '启用「问倪师AI」'))
      .value;

  testWidgets('开关点击后当帧就翻转，不靠退出重进', (tester) async {
    final settings = SettingsRepository.instance;

    // 写库走 sqflite ffi（隔离线程真异步），FakeAsync zone 收不到回包会卡死，
    // 必须 runAsync 包裹；页面内的点击不 await 写库，所以 tap 本身安全。
    await tester.runAsync(() => settings.setLlmEnabled(false));
    await pumpSettings(tester);
    expect(switchValue(tester), isFalse);

    await tester.tap(find.widgetWithText(SwitchListTile, '启用「问倪师AI」'));
    await tester.pump();
    expect(switchValue(tester), isTrue,
        reason: '组件没订阅 SettingsRepository 时，父级重建会跳过 const 子树，开关停在旧值');

    // 开启后配置输入区应立刻出现（同一个「子树没重建」的连带症状）
    expect(find.widgetWithText(TextField, '接口地址（OpenAI 兼容）'), findsOneWidget);

    await tester.tap(find.widgetWithText(SwitchListTile, '启用「问倪师AI」'));
    await tester.pump();
    expect(switchValue(tester), isFalse);

    // 复位，避免污染其它测试（SettingsRepository 是单例）
    await tester.runAsync(() => settings.setLlmEnabled(false));
  });
}
