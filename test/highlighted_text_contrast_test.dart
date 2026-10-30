// 搜索高亮文字在浅色 / 深色下的可读性回归。
//
// 背景：RichText 不继承 DefaultTextStyle，HighlightedText 早前没给未命中片段
// 显式颜色，浅色模式下回退成接近白色 → 搜索页方剂/本草标题「看不见」
// （issue #4 用户截图实锤）。本测试锁死：基础色与高亮色都必须与卡片底色
// 达到 WCAG AA（≥ 4.5:1）。
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/widgets/highlighted_text.dart';

double _lin(double v) =>
    v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b);

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  Future<({TextSpan root, ColorScheme scheme})> pumpAndRead(
      WidgetTester tester, Brightness brightness) async {
    late ColorScheme scheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B4513),
            brightness: brightness,
          ),
        ),
        home: Builder(
          builder: (context) {
            scheme = Theme.of(context).colorScheme;
            return Scaffold(
              body: Card(
                child: ListTile(
                  title: const HighlightedText(
                    text: '枳实薤白桂枝汤',
                    query: '桂枝汤',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    final rich = tester.widget<RichText>(
      find.descendant(of: find.byType(Card), matching: find.byType(RichText)),
    );
    return (root: rich.text as TextSpan, scheme: scheme);
  }

  testWidgets('浅色模式：未命中片段与命中片段都对卡片底色 ≥ 4.5:1', (tester) async {
    final r = await pumpAndRead(tester, Brightness.light);
    final bg = r.scheme.surfaceContainerLow;

    final base = r.root.style?.color;
    expect(base, isNotNull, reason: '基础色必须显式给出，否则回退成近白色');
    expect(_contrast(base!, bg), greaterThanOrEqualTo(4.5),
        reason: '未命中片段的文字对比度不足');

    final highlight = r.root.children!
        .cast<TextSpan>()
        .firstWhere((s) => s.text == '桂枝汤')
        .style!
        .color!;
    expect(_contrast(highlight, bg), greaterThanOrEqualTo(4.5),
        reason: '高亮片段（关键词）对比度不足');
  });

  testWidgets('深色模式：基础色不能是深色（避免黑底黑字）', (tester) async {
    final r = await pumpAndRead(tester, Brightness.dark);
    final bg = r.scheme.surfaceContainerLow;
    final base = r.root.style?.color;
    expect(base, isNotNull);
    expect(_contrast(base!, bg), greaterThanOrEqualTo(4.5),
        reason: '深色模式下基础文字对比度不足');
  });

  testWidgets('无关键词时走 Text 分支，颜色同样可读', (tester) async {
    late ColorScheme scheme;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF8B4513),
            brightness: Brightness.light,
          ),
        ),
        home: Builder(
          builder: (context) {
            scheme = Theme.of(context).colorScheme;
            return const Scaffold(
              body: HighlightedText(
                text: '桂枝汤',
                query: '',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          },
        ),
      ),
    );
    final text = tester.widget<Text>(find.text('桂枝汤'));
    final color = text.style?.color;
    expect(color, isNotNull);
    expect(_contrast(color!, scheme.surface), greaterThanOrEqualTo(4.5));
  });
}
