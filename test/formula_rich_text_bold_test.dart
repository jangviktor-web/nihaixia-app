import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/widgets/formula_rich_text.dart';

bool _hasBold(InlineSpan span) {
  if (span is TextSpan) {
    if (span.style?.fontWeight == FontWeight.bold &&
        (span.text?.contains('初诊') ?? false)) {
      return true;
    }
    for (final c in span.children ?? const <InlineSpan>[]) {
      if (_hasBold(c)) return true;
    }
  }
  return false;
}

bool _hasLiteralStars(InlineSpan span) {
  if (span is TextSpan) {
    if (span.text?.contains('**') ?? false) return true;
    for (final c in span.children ?? const <InlineSpan>[]) {
      if (_hasLiteralStars(c)) return true;
    }
  }
  return false;
}

void main() {
  testWidgets('方剂组成: **加粗** 渲染为加粗且不显示星号', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormulaRichText(formula: '**初诊** 患者服药两周'),
        ),
      ),
    );
    final rich = tester.widget<RichText>(find.byType(RichText));
    // 断言：「初诊」以加粗呈现
    expect(_hasBold(rich.text), isTrue);
    // 断言：不再有字面星号
    expect(_hasLiteralStars(rich.text), isFalse);
  });
}
