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
    for (final good in [
      '白虎人参汤',
      '抵挡汤',
      '大黄蛰虫丸',
      '甘草干姜附子汤',
      // 2026-11-09 P0 批次（异体字/简称/方言）
      '桂附八味丸', '金匮肾气丸', '八味肾气丸', // 原「桂附八味丸/金匮肾气丸」含斜杠被整条丢弃
      '防己黄耆汤', '黄耆建中汤', '桂枝加黄耆汤', // 耆/芪
      '旋复花代赭石汤', '旋复花汤', // 复/覆
      '桔皮汤', // 桔/橘
      '麻仁丸', '百合鸡子汤', '麻仁丸',
      '麻黄杏仁甘草石膏汤', '麻黄杏子甘草石膏汤', // 麻杏甘石汤正名过简
      '桂枝龙骨牡蛎汤', '赤小豆当归散', '甘草干姜苓术汤',
      // 白名单：以正名开头的加减方名，须绕过前缀规则
      '木防己汤去石膏加茯苓芒硝汤',
      '白通汤加猪胆汁汤',
      '白通汤加猪胆汁', // 结尾非剂型字，靠白名单放行
      '桂枝汤去芍药方中加附子汤',
    ]) {
      expect(al, contains(good), reason: '$good 应可成链');
    }
    for (final bad in [
      '虫剂',
      '群方之魁',
      '回阳救逆第一方',
      '伤寒第一方',
      '苇茎汤加大承气汤', // 合方描述，以另一正名开头，仍须拦下
      '健脾四神汤（区别于温肾止泻四神丸）',
      // 治法名，不是方名：方是蜜煎方，「蜜煎导」是导法外治（伤寒 233 条）。
      // 让它成链等于把治法当方剂展示，与 formula_rules.dart 的导法口径冲突。
      '蜜煎导',
      '蜜煎导方',
    ]) {
      expect(al, isNot(contains(bad)), reason: '$bad 不应进入成链候选');
    }
    // 白名单不得连带放宽通用规则：合方描述仍被拦下
    expect(al, contains('木防己汤去石膏加茯苓芒硝汤'));
    expect(al, isNot(contains('苇茎汤加大承气汤')));
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

  // 白名单项必须以「整串」成链，不能被更短的正名（木防己汤）劫持前半截。
  testWidgets('加减方名按最长优先成链，不被短正名劫持', (tester) async {
    await FormulaRepository.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormulaRichText(formula: '虚者即愈，实者三日复发，复与不愈者，宜木防己汤去石膏加茯苓芒硝汤主之。'),
        ),
      ),
    );
    final rich = tester.widget<RichText>(find.byType(RichText));
    expect(_hasLink(rich.text, '木防己汤去石膏加茯苓芒硝汤'), isTrue,
        reason: '应整串成链');
    expect(_hasLink(rich.text, '木防己汤'), isFalse,
        reason: '不应退化成短正名的链接');
    expect(_linkTexts(rich.text), contains('木防己汤去石膏加茯苓芒硝汤'));
  });

  // 「蜜煎导」是导法（外治法）之名，不是方名，正文里不应链成方剂；
  // 同段的「白通汤加猪胆汁」（结尾非剂型字）则必须成链。
  testWidgets('治法名不成链、非剂型字结尾的方名成链', (tester) async {
    await FormulaRepository.load();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormulaRichText(
            formula: '此为津液内竭，虽硬不可攻之，当须自欲大便，宜蜜煎导而通之。',
          ),
        ),
      ),
    );
    final rich1 = tester.widget<RichText>(find.byType(RichText));
    expect(_hasLink(rich1.text, '蜜煎导'), isFalse,
        reason: '蜜煎导是导法之名，不应链成方剂');
    expect(_linkTexts(rich1.text), isEmpty, reason: '该句不应产生任何方剂链接');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FormulaRichText(formula: '所以张仲景当初，他研究这个白通汤加猪胆汁的时候。'),
        ),
      ),
    );
    final rich2 = tester.widget<RichText>(find.byType(RichText));
    expect(_hasLink(rich2.text, '白通汤加猪胆汁'), isTrue,
        reason: '白通汤加猪胆汁是方名异写，应成链');
  });
}

/// 收集所有带 recognizer 的 span 文本，便于断言「链成了什么」。
List<String> _linkTexts(InlineSpan span) {
  final out = <String>[];
  void walk(InlineSpan s) {
    if (s is TextSpan) {
      if (s.text != null && s.recognizer != null) out.add(s.text!);
      for (final c in s.children ?? const <InlineSpan>[]) {
        walk(c);
      }
    }
  }

  walk(span);
  return out;
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
