import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/acupoint_repository.dart';
import 'package:nihaisha_app/models/acupoint_detail.dart';
import 'package:nihaisha_app/widgets/acupoint_rich_text.dart';

TapGestureRecognizer? _findTapRecognizer(InlineSpan span, String label) {
  if (span is TextSpan) {
    if (span.text == label && span.recognizer is TapGestureRecognizer) {
      return span.recognizer as TapGestureRecognizer;
    }
    for (final c in span.children ?? const <InlineSpan>[]) {
      final r = _findTapRecognizer(c, label);
      if (r != null) return r;
    }
  }
  return null;
}

bool _hasLabel(InlineSpan span, String label) {
  if (span is TextSpan) {
    if (span.text == label) return true;
    for (final c in span.children ?? const <InlineSpan>[]) {
      if (_hasLabel(c, label)) return true;
    }
  }
  return false;
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AcupointRepository.load();
  });

  testWidgets('针灸方案: 已知穴位渲染为可点链接并触发跳转', (tester) async {
    AcupointDetail? tapped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AcupointRichText(
            text: '针刺足三里、合谷，留针二十分钟',
            onAcupointTap: (a) => tapped = a,
          ),
        ),
      ),
    );
    final rich = tester.widget<RichText>(find.byType(RichText));
    // 断言：足三里、合谷 均作为独立文字段渲染
    expect(_hasLabel(rich.text, '足三里'), isTrue);
    expect(_hasLabel(rich.text, '合谷'), isTrue);
    // 断言：足三里 段带 TapGestureRecognizer（即被识别为链接）
    final rec = _findTapRecognizer(rich.text, '足三里');
    expect(rec, isNotNull);
    // 触发点击，断言回调拿到正确的穴位（仓库正名带「穴」后缀）
    rec!.onTap!();
    expect(tapped, isNotNull);
    expect(tapped!.name, contains('足三里'));
  });

  testWidgets('针灸方案: 普通文本不误链', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AcupointRichText(
            text: '留针二十分钟，避风寒',
            onAcupointTap: (_) {},
          ),
        ),
      ),
    );
    final rich = tester.widget<RichText>(find.byType(RichText));
    // 没有足三里之类的链接
    expect(_findTapRecognizer(rich.text, '足三里'), isNull);
    expect(_hasLabel(rich.text, '留针二十分钟，避风寒'), isTrue);
  });
}
