import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ziwei_core/ziwei_core.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart';
import 'package:nihaisha_app/services/ziwei_interpretation.dart';
import 'package:nihaisha_app/screens/ziwei_chart_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';

/// ③ 中医深化：流年疾厄宫见煞星/化忌时追加非诊断性中医脏腑/经络上下文，
/// 且免责声明仍在渲染卡片中。
void main() {
  group('analyzeHealthWatch 中医上下文', () {
    late ZiweiChart chart;
    late List<HealthWatchItem> items;

    setUpAll(() {
      chart = calculateZiweiChart(
        solar: DateTime(1990, 6, 15, 0, 0),
        gender: Gender.male,
        useTrueSolarTime: false,
      );
      items = analyzeHealthWatch(
        chart,
        fromYear: 1990,
        toYear: 2090,
        birthYear: 1990,
      );
    });

    test('化忌命中条目携带中医脏腑/经络上下文（含「经」字）', () {
      final jiItems = items.where((e) => e.reason.contains('化忌')).toList();
      expect(jiItems, isNotEmpty, reason: '应存在流年化忌命中条目');
      final withTcm = jiItems.where((e) => e.tcmContext != null).toList();
      expect(withTcm, isNotEmpty, reason: '化忌条目应带 tcmContext');
      // 经络术语（如「肾经」「肺经」）必含「经」
      expect(withTcm.any((e) => e.tcmContext!.contains('经')), isTrue);
      for (final it in withTcm.take(3)) {
        print('[TCM 化忌] ${it.year} ${it.reason} | ${it.tcmContext}');
      }
    });

    test('煞星命中条目同样携带中医上下文', () {
      final badItems = items
          .where((e) => e.reason.contains('煞星') || e.reason.contains('煞曜'))
          .toList();
      expect(badItems, isNotEmpty);
      expect(
        badItems.any((e) => e.tcmContext != null && e.tcmContext!.contains('经')),
        isTrue,
      );
    });

    test('tcmContextFor 覆盖全部 12 地支', () {
      for (int i = 0; i < 12; i++) {
        expect(tcmContextFor(i), contains('经'));
      }
    });
  });

  group('免责声明仍在渲染卡片中', () {
    testWidgets('排盘后健康提醒卡片含「非医疗诊断」声明', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AppColors.light], useMaterial3: true),
          home: const ZiweiChartScreen(),
        ),
      );
      await tester.pumpAndSettle();
      // 直接点击「开始排盘」触发 _calculate（避免依赖资源加载的城市服务）
      final btn = find.text('开始排盘');
      await tester.ensureVisible(btn);
      await tester.pump();
      await tester.tap(btn);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 2));
      // 健康提醒卡片位于长列表底部，测试中 ListView 仅挂载可见子项，需滚动挂载
      final listView = find.byType(ListView);
      for (int i = 0; i < 10; i++) {
        await tester.drag(listView, const Offset(0, -600));
        await tester.pumpAndSettle();
      }
      // 免责声明字符串（来自 ziwei_chart_screen 健康卡片头部）仍在渲染卡片中
      expect(find.textContaining('非医疗诊断'), findsWidgets);
    });
  });
}
