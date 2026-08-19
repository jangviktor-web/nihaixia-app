import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/screens/medical_case_library_screen.dart';

void main() {
  setUpAll(() {
    // flutter test 的桌面 runner 需要 ffi 版的 sqflite 工厂。
    databaseFactory = databaseFactoryFfi;
  });

  group('MedicalCaseLibraryScreen filter bars', () {
    testWidgets('renders 年份/治法/疾病/视图 after load', (tester) async {
      await tester.runAsync(() async {
        // Prime test-binding IO for rootBundle-backed repositories.
        await rootBundle.loadString('assets/medical_cases/cases_table.md');
        await FormulaRepository.load();
        await tester.pumpWidget(
          const MaterialApp(home: MedicalCaseLibraryScreen()),
        );
        // Drive async load + synchronous category computation to completion.
        for (var i = 0; i < 50; i++) {
          await tester.pump(const Duration(milliseconds: 200));
        }
      });

      // All four section labels must appear.
      expect(find.text('年份'), findsOneWidget);
      expect(find.text('治法'), findsOneWidget);
      expect(find.text('疾病'), findsOneWidget);
      expect(find.text('视图'), findsOneWidget);

      // Top formula chips (方剂名) must appear once FormulaRepository is loaded.
      expect(find.text('四逆汤'), findsOneWidget);
      expect(find.text('桂枝汤'), findsOneWidget);
      expect(find.text('其他治法'), findsOneWidget);

      // Top disease chips (西医病名) must appear.
      expect(find.text('乳癌'), findsOneWidget);
      expect(find.text('肺癌'), findsOneWidget);
      expect(find.text('其他疾病'), findsOneWidget);
    });
  });
}
