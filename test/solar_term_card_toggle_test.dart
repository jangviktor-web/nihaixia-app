// 知识库顶部节气卡可隐藏（issue #4：占屏比大）。
// 运行：flutter test test/solar_term_card_toggle_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nihaisha_app/data/acupoint_repository.dart';
import 'package:nihaisha_app/data/acupuncture_repository.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/data/herb_repository.dart';
import 'package:nihaisha_app/data/settings_repository.dart';
import 'package:nihaisha_app/screens/knowledge_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';
import 'package:nihaisha_app/widgets/solar_term_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    await FormulaRepository.load();
    await HerbRepository.load();
    await AcupunctureRepository.load();
    await AcupointRepository.load();
  });

  Future<void> pumpKnowledge(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true, extensions: [AppColors.light]),
      home: const KnowledgeScreen(),
    ));
    await tester.pump();
  }

  testWidgets('开关打开时显示节气卡，关闭后首屏不再占位', (tester) async {
    final settings = SettingsRepository.instance;

    // SettingsRepository 写库走 sqflite ffi（isolate 真异步），testWidgets 的
    // FakeAsync zone 收不到 isolate 回包会永久卡死 → 必须 runAsync 包裹。
    await tester.runAsync(() => settings.setHideSolarTermCard(false));
    await pumpKnowledge(tester);
    expect(find.byType(SolarTermCard), findsOneWidget);

    await tester.runAsync(() => settings.setHideSolarTermCard(true));
    await tester.pump();
    expect(find.byType(SolarTermCard), findsNothing,
        reason: '关闭后知识库顶部不应再渲染节气卡');

    // 复位，避免污染其它测试（SettingsRepository 是单例）
    await tester.runAsync(() => settings.setHideSolarTermCard(false));
    await tester.pump();
    expect(find.byType(SolarTermCard), findsOneWidget);
  });
}
