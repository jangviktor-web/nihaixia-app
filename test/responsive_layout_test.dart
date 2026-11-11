// Web/桌面端自适应布局（issue #7）：
// 手机构建保持底部导航 + 单列；宽屏切侧边导航 + 多列网格。
// 运行：flutter test test/responsive_layout_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nihaisha_app/data/acupoint_repository.dart';
import 'package:nihaisha_app/data/acupuncture_repository.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/data/herb_repository.dart';
import 'package:nihaisha_app/screens/home_screen.dart';
import 'package:nihaisha_app/screens/tools_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';
import 'package:nihaisha_app/utils/responsive.dart';
import 'package:nihaisha_app/widgets/zone_section.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    await FormulaRepository.load();
    await HerbRepository.load();
    await AcupunctureRepository.load();
    await AcupointRepository.load();
  });

  /// 把测试窗口设成指定逻辑宽度（默认测试窗口只有 800×600）。
  void setViewport(WidgetTester tester, Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget wrap(Widget child) => MaterialApp(
        theme: ThemeData(useMaterial3: true, extensions: [AppColors.light]),
        home: child,
      );

  testWidgets('手机宽度：底部导航；桌面宽度：侧边导航', (tester) async {
    setViewport(tester, const Size(420, 900));
    await tester.pumpWidget(wrap(const HomeScreen()));
    await tester.pump();
    expect(find.byType(NavigationBar), findsOneWidget);

    setViewport(tester, const Size(1440, 900));
    await tester.pumpWidget(wrap(const HomeScreen()));
    await tester.pump();
    expect(find.byType(NavigationBar), findsNothing,
        reason: '桌面宽度下底部导航应让位给左侧导航');
    // 侧边栏里四项导航文案都在
    expect(find.text('知识库'), findsWidgets);
    expect(find.text('辨证'), findsWidgets);

    // HomeScreen.initState 里有 800ms「更新了什么」与 3s 检查更新两个延迟任务，
    // 不推进时间会在用例结束时被判定为 pending timer。卸载后把定时器跑完即可。
    await tester.pumpWidget(wrap(const SizedBox.shrink()));
    await tester.pump(const Duration(seconds: 4));
  });

  testWidgets('工具页：手机单列，桌面多列网格', (tester) async {
    setViewport(tester, const Size(420, 900));
    await tester.pumpWidget(wrap(const ToolsScreen()));
    await tester.pump();
    expect(tester.widget<ZoneSection>(find.byType(ZoneSection).first).columns,
        1);

    setViewport(tester, const Size(1440, 900));
    await tester.pumpWidget(wrap(const ToolsScreen()));
    await tester.pump();
    expect(
      tester.widget<ZoneSection>(find.byType(ZoneSection).first).columns,
      greaterThan(1),
      reason: '桌面宽度下工具卡应摊成多列',
    );
  });

  testWidgets('PageBody 在宽屏下把内容收进 maxWidth', (tester) async {
    setViewport(tester, const Size(1600, 900));
    final key = GlobalKey();
    await tester.pumpWidget(wrap(
      Scaffold(
        body: PageBody(maxWidth: 860, child: SizedBox(key: key, height: 10)),
      ),
    ));
    // PageBody 自身是铺满视口的 Align，限宽生效在其子节点上，所以量 child。
    final width = tester.getSize(find.byKey(key)).width;
    expect(width, lessThanOrEqualTo(860));
  });

  test('computeColumns 按内容宽度取列数', () {
    expect(computeColumns(360, candidates: const [3, 2, 1], minTileWidth: 340), 1);
    expect(computeColumns(800, candidates: const [3, 2, 1], minTileWidth: 340), 2);
    expect(computeColumns(1200, candidates: const [3, 2, 1], minTileWidth: 340), 3);
  });
}
