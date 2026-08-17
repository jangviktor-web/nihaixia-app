import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/yijing_data.dart';
import 'package:nihaisha_app/screens/yijing_detail_screen.dart';

void main() {
  testWidgets('卦详情页展示倪师《人间道》讲义入口', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: YiJingHexagramDetailScreen(hex: kHexagrams[0])),
    );

    // 卦名 + 卦辞 + 倪师人间道 + 讲义入口
    expect(find.text('乾为天'), findsOneWidget);
    expect(find.text('倪师《天纪·人间道》'), findsOneWidget);
    expect(find.text('倪师《天纪·人间道》讲课文稿'), findsOneWidget);

    // 六爻
    await tester.scrollUntilVisible(find.text('六爻爻辞（自下而上）'), 300);
    expect(find.text('六爻爻辞（自下而上）'), findsOneWidget);
  });
}
