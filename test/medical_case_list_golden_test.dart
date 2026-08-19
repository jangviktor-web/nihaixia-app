import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/data/medical_case_data.dart';
import 'package:nihaisha_app/widgets/medical_case_list_card.dart';

void main() {
  testWidgets('golden: medical case list cards (light)', (tester) async {
    final cases = [
      MedicalCase(
        seq: 1,
        date: '2006/09/03',
        patient: '女，六十岁',
        diagnosis: '乳癌',
        formula: '四逆汤',
        result: '服药后肿块缩小',
      ),
      MedicalCase(
        seq: 2,
        date: '2006/10/12',
        patient: '男，四十五岁',
        diagnosis: '偏头痛',
        formula: '吴茱萸汤',
        result: '痛止',
      ),
      MedicalCase(
        seq: 3,
        date: '2007/01/05',
        patient: '女，三十二岁',
        diagnosis: '不孕',
        formula: '温经汤',
        result: '三月后受孕',
      ),
    ];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B4513),
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final c in cases)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MedicalCaseListCard(c: c, query: '', onTap: () {}),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Scaffold),
      matchesGoldenFile('medical_case_list_light.png'),
    );
  });
}
