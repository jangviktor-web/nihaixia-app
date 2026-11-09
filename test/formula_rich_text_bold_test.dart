import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
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

  // 讲稿口语常写异名（「白虎人参汤」「抵挡汤」），此前候选词表只放正名，
  // 这些正文不会成链、点不开方剂详情。2026-11-09 起方剂 aliasNames 一并入候选。
  test('aliasNames 只收方名异写，剔除称号与合方描述', () async {
    await FormulaRepository.load();
    final al = FormulaRepository.aliasNames;
    for (final good in ['白虎人参汤', '抵挡汤', '大黄蛰虫丸', '甘草干姜附子汤']) {
      expect(al, contains(good), reason: '$good 应可成链');
    }
    for (final bad in [
      '虫剂',
      '群方之魁',
      '回阳救逆第一方',
      '伤寒第一方',
      '苇茎汤加大承气汤', // 合方描述，以另一正名开头
      '桂附八味丸/金匮肾气丸', // 含斜杠的多写法
      '健脾四神汤（区别于温肾止泻四神丸）',
    ]) {
      expect(al, isNot(contains(bad)), reason: '$bad 不应进入成链候选');
    }
  });

  testWidgets('讲稿口语「白虎人参汤」可点击跳转方剂', (tester) async {
    await FormulaRepository.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormulaRichText(formula: '临床上我们中医的白虎人参汤证，就是脑膜炎引发的高热'),
        ),
      ),
    );
    final rich = tester.widget<RichText>(find.byType(RichText));
    expect(_hasLink(rich.text, '白虎人参汤'), isTrue,
        reason: '异名应成链并带点击回调');
  });
}

bool _hasLink(InlineSpan span, String text) {
  if (span is TextSpan) {
    if (span.text == text && span.recognizer != null) return true;
    for (final c in span.children ?? const <InlineSpan>[]) {
      if (_hasLink(c, text)) return true;
    }
  }
  return false;
}
