import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nihaisha_app/screens/medical_case_library_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';

void main() {
  setUpAll(() {
    // flutter test 的桌面 runner 需要 ffi 版的 sqflite 工厂。
    databaseFactory = databaseFactoryFfi;
  });

  // 用一个共享的 pumpWidget 辅助：runAsync 内预激活 cases_table 资源，
  // 屏幕内部自愈 FormulaRepository/HerbRepository 加载（_load 已显式 await，
  // 不依赖 test 外部手动 load——模拟真机：main 已 await load，screen 二次保险）。
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.runAsync(() async {
      await rootBundle.loadString('assets/medical_cases/cases_table.md');
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: true, extensions: [AppColors.light]),
          home: const MedicalCaseLibraryScreen(),
        ),
      );
      // 冷启动 sqflite 首次 open database 真实 IO 较慢，先真实等几秒
      // 让所有 await (FormulaRepository/HerbRepository/rootBundle/sqflite) 完成。
      await Future<void>.delayed(const Duration(seconds: 4));
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
    });
  }

  group('MedicalCaseLibraryScreen filter bars', () {
    testWidgets('renders four rows and tap filters yield non-empty list',
        (tester) async {
      await pumpScreen(tester);

      // Render: four section labels.
      expect(find.text('年份'), findsOneWidget);
      expect(find.text('治法'), findsOneWidget);
      expect(find.text('疾病'), findsOneWidget);
      expect(find.text('视图'), findsOneWidget);

      // Top disease chips.
      expect(find.text('乳癌'), findsOneWidget);
      expect(find.text('肺癌'), findsOneWidget);
      expect(find.text('其他疾病'), findsOneWidget);

      // Baseline count.
      final baseline = tester
              .widget<Text>(find.textContaining('/ 1113 例'))
              .data ??
          '';
      expect(baseline.contains('1113 / 1113'), isTrue,
          reason: 'baseline should be 1113/1113, got: ' + baseline);

      // Tap formula chip → must reduce but stay > 0.
      await tester.tap(find.text('桂枝汤'));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final afterFormula = tester
              .widget<Text>(find.textContaining('/ 1113 例'))
              .data ??
          '';
      final mf =
          RegExp(r'共 (\d+) / 1113 例').firstMatch(afterFormula);
      expect(mf, isNotNull, reason: 'count line: ' + afterFormula);
      final nf = int.parse(mf!.group(1)!);
      expect(nf, greaterThan(0),
          reason: '桂枝汤 tap must yield >0, got $nf');
      expect(nf, lessThan(1113));

      // Reset to 全部 (治法), tap disease chip → also must reduce > 0.
      // Scroll filter bar left then tap 治法 row's 全部 chip.
      // Tap the second 全部 (治法 row) by finder of ancestor chip row labeled 治法.
      // Simpler: tap 桂枝汤 again to toggle off — but onSelected always emits o,
      // so re-tap keeps filter. Instead tap the 全部 in the 治法 row directly.
      // Find FilterChip with label 全部 in the same row as 治法 label.
      // Use a generic 全部 tap by tapping the first 全部 in the bar.
      // Reset by tapping 全部 in the first chip row of the bar (年份 row's 全部).
      // But that resets year, not formula. Need 治法 row 全部.
      // Easiest: tap 全部 next to 桂枝汤 — find ancestor Row containing 治法.
      // We do it by tapping the chip labeled 全部 whose ancestor contains 治法.
      // For simplicity, use a known approach: re-enter screen to reset state.
      // Actually simplest robust path: tap 糖尿病 (disease) — result is AND with
      // 桂枝汤 currently active, which may legitimately be 0. So reset formula first.
      // Reset: find the 治法 row's 全部 chip by lookup near the 治法 label.
      // Practical approach: tap the chip widget whose label is 全部 and which is
      // a sibling under the 治法 label.
      final otherAll = find.ancestor(
        of: find.text('治法'),
        matching: find.byType(Row),
      );
      // The 治法 row's 全部 chip is inside the SingleChildScrollView of that row.
      // Just tap the 全部 widget in the same overall filter bar — there are
      // four 全部 chips (one per row). Tap all to reset, then test disease.
      // For minimal flake: use the test approach of pumping a fresh screen.
      // Tap the first 全部 (年份 row) — doesn't reset formula. We need to
      // reset formula by tapping 治法 row's 全部. Find by Row ancestor of 治法.
      final formulaRowAll = find.descendant(
        of: otherAll,
        matching: find.widgetWithText(FilterChip, '全部'),
      );
      // Fallback: if multiple matches, just use the first one.
      if (formulaRowAll.evaluate().isNotEmpty) {
        await tester.tap(formulaRowAll.first);
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      // Now tap 糖尿病 (disease).
      await tester.tap(find.text('糖尿病'));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final afterDisease = tester
              .widget<Text>(find.textContaining('/ 1113 例'))
              .data ??
          '';
      final md =
          RegExp(r'共 (\d+) / 1113 例').firstMatch(afterDisease);
      expect(md, isNotNull, reason: 'count line: ' + afterDisease);
      final nd = int.parse(md!.group(1)!);
      expect(nd, greaterThan(0),
          reason: '糖尿病 tap must yield >0, got $nd');
    });
  });
}
