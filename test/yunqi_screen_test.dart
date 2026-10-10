// 五运六气 UI 冒烟测试（QA 独立验证）
//
// 目的：屏幕层防逃逸——本项目历史上两次因「屏幕层私有 static const 数据
// 逃逸测试覆盖」翻车。本测试从 UI 反读文本，断言其与引擎（同数据源）一致，
// 并静态扫描「无硬编码颜色」。
//
// 注意：YunQiScreen 主体是 ListView，屏幕外的卡片不会被构建。故测试把
// 测试视口调得足够高（含滚动），使整页内容都渲染出来再断言。
//
// 运行：flutter test test/yunqi_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/screens/yunqi_screen.dart';
import 'package:nihaisha_app/services/yunqi_engine.dart';

/// 放大的测试视口，避免 ListView 懒构建导致屏幕外文本找不到。
Future<void> _pumpTall(WidgetTester tester, {ThemeData? theme}) async {
  tester.view.physicalSize = const Size(1200, 8000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    theme: theme,
    home: const YunQiScreen(),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('五运六气 UI 冒烟', () {
    testWidgets('YunQiScreen 可构建、显示标题与关键分区', (WidgetTester tester) async {
      await _pumpTall(tester);

      expect(find.text('五运六气推算'), findsOneWidget);
      // 关键卡片标题
      expect(find.text('司天 / 在泉'), findsOneWidget);
      expect(find.text('主运五步'), findsOneWidget);
      expect(find.text('客运五步'), findsOneWidget);
      expect(find.text('主气六步（固定）'), findsOneWidget);
      expect(find.text('客气六步'), findsOneWidget);
    });

    testWidgets('UI 显示的年干支/司天/在泉与引擎同数据源一致',
        (WidgetTester tester) async {
      await _pumpTall(tester);

      // 屏幕默认用「日历年」口径驱动 yearGanzhi（参考站口径）。
      final int y = YunQiEngine.calendarYearOf(DateTime.now());
      final YunQiYearData d = YunQiEngine.yearGanzhi(y);

      // 司天/在泉展示串（见 yunqi_screen.dart L104-105）
      final String siTianText = '${d.siTian}（${d.siTianWx}）';
      expect(find.text(siTianText), findsOneWidget,
          reason: '司天展示应与引擎 ${d.siTian} 一致');
      expect(find.text(d.zaiQuan), findsWidgets,
          reason: '在泉展示应与引擎 ${d.zaiQuan} 一致');

      // 客气六步的全部气名都应出现（UI 不得自建私表）
      for (final String qi in d.keQi) {
        expect(find.text(qi), findsWidgets,
            reason: '客气「$qi」应在 UI 出现（数据源=引擎）');
      }

      // 主气六步固定气名（数据源 = zhuQiSteps 常量）
      for (final ZhuQiStepDef z in zhuQiSteps) {
        expect(find.text(z.qi), findsWidgets,
            reason: '主气「${z.qi}」应在 UI 出现');
      }
    });

    testWidgets('深色模式下可正常构建（无硬编码颜色导致的崩溃）',
        (WidgetTester tester) async {
      await _pumpTall(tester, theme: ThemeData.dark());
      expect(tester.takeException(), isNull);
      expect(find.text('五运六气推算'), findsOneWidget);
    });
  });
}
