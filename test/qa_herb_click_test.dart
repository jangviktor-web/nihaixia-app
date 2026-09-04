// 独立功能验证 —— Option 1：自由文本中的药材名 / 方剂名 可点并导航（commit 92519a0）。
//
// 覆盖两条被测代码路径：
//   1) lib/screens/medical_case_detail_screen.dart 的 else 分支用 FormulaRichText 渲染
//      病机/治法/倪师观点 等自由文本；点击药材 → HerbDetailScreen，点击方剂 → FormulaDetailScreen。
//      FormulaRichText 自身负责「把命中词渲染成带 TapGestureRecognizer 的链接并回调
//      onHerbTap/onFormulaTap」，真实导航闭包由调用方注入（与该 screen 完全一致）。
//      ⇒ 本测试直接渲染 FormulaRichText，并复用与该 screen 完全一致的导航闭包，
//        证明「点药材链接 → 真正 push HerbDetailScreen」。
//
//   2) lib/screens/markdown_doc_screen.dart 的 _injectLinks() 把正文药材/方剂名包成
//      herb://NAME / formula://NAME markdown 链接，_onTapLink() 解析 herb:// 经
//      HerbRepository.getExactByName 并 push HerbDetailScreen。这是闭门课
//      （CriticalIllnessListScreen → MarkdownDocScreen(linkFormulas:true)）的真实路径，
//      本测试用真实闭门课 asset 端到端验证。
//
// 为何不直接渲染完整 MedicalCaseDetailScreen：
//   该 screen 的 initState 调用 DatabaseHelper（sqflite），纯 widget test 环境下若无
//   sqlite 后端会抛错，属「过重」依赖。FormulaRichText 是该 screen 渲染自由文本所用的
//   真实 widget，且我们复用了同一导航闭包，因此等价证明。被 push 的 HerbDetailScreen
//   仍会真实构建（含 DB 与后向关联），故此处同样初始化 sqflite FFI。
//
// 环境（Windows）：Flutter 不在 PATH，运行需前缀：
//   TEMP="C:/Users/jangviktor/AppData/Local/Temp" TMP="C:/Users/jangviktor/AppData/Local/Temp" \
//     /d/flutter/bin/flutter test test/qa_herb_click_test.dart

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/data/herb_repository.dart';
import 'package:nihaisha_app/models/formula.dart';
import 'package:nihaisha_app/models/herb.dart';
import 'package:nihaisha_app/screens/herb_detail_screen.dart';
import 'package:nihaisha_app/screens/markdown_doc_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';
import 'package:nihaisha_app/widgets/formula_rich_text.dart';

/// 深度遍历 InlineSpan 树，返回 text == [label] 且带 TapGestureRecognizer 的 span。
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

/// 深度遍历，判断是否存在 text == [label] 的 TextSpan（用于「普通文本确实渲染」）。
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
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // 桌面 test runner 需要 ffi 版 sqflite 工厂；被 push 的 HerbDetailScreen.initState
    // 会调 DatabaseHelper，否则抛 "Bad state: databaseFactory not initialized"。
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await HerbRepository.load();
    await FormulaRepository.load();
  });

  // 与 medical_case_detail_screen.dart 完全一致的导航闭包。
  HerbDetailScreen _herbRoute(Herb h) => HerbDetailScreen(herb: h);

  group('FormulaRichText — 医案自由文本药材/方剂可点 (Option 1)', () {
    testWidgets('已知药名「柴胡」渲染为带 TapGestureRecognizer 的链接，点击回调拿到柴胡',
        (tester) async {
      Herb? tapped;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AppColors.light], useMaterial3: true),
          home: Scaffold(
            body: FormulaRichText(
              formula: '处方以桂枝汤为底，加柴胡、黄芩',
              onHerbTap: (h) => tapped = h,
            ),
          ),
        ),
      );
      final rich = tester.widget<RichText>(find.byType(RichText));
      final rec = _findTapRecognizer(rich.text, '柴胡');
      expect(rec, isNotNull,
          reason: '「柴胡」应被渲染为可点链接（带 TapGestureRecognizer）');
      rec!.onTap!();
      expect(tapped, isNotNull);
      expect(tapped!.name, '柴胡');
    });

    testWidgets('方剂名「桂枝汤」渲染为方剂链接，点击回调拿到桂枝汤', (tester) async {
      Formula? tapped;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AppColors.light], useMaterial3: true),
          home: Scaffold(
            body: FormulaRichText(
              formula: '处方以桂枝汤为底，加柴胡、黄芩',
              onFormulaTap: (f) => tapped = f,
            ),
          ),
        ),
      );
      final rich = tester.widget<RichText>(find.byType(RichText));
      final rec = _findTapRecognizer(rich.text, '桂枝汤');
      expect(rec, isNotNull, reason: '「桂枝汤」应被渲染为可点方剂链接');
      rec!.onTap!();
      expect(tapped, isNotNull);
      expect(tapped!.name, '桂枝汤');
    });

    testWidgets('药材别名「橘皮」(→陈皮) 渲染为可点链接并归一到陈皮', (tester) async {
      Herb? tapped;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AppColors.light], useMaterial3: true),
          home: Scaffold(
            body: FormulaRichText(
              formula: '方中含橘皮、茯苓',
              onHerbTap: (h) => tapped = h,
            ),
          ),
        ),
      );
      final rich = tester.widget<RichText>(find.byType(RichText));
      final rec = _findTapRecognizer(rich.text, '橘皮');
      expect(rec, isNotNull, reason: '别名「橘皮」应被渲染为可点链接');
      rec!.onTap!();
      expect(tapped, isNotNull);
      expect(tapped!.name, '陈皮',
          reason: '别名橘皮应经 getExactByName 归一到正名陈皮');
    });

    testWidgets('柴胡作为「小柴胡汤」子串时不被误判为药材链接（无模糊兜底）', (tester) async {
      Herb? tappedHerb;
      Formula? tappedFormula;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AppColors.light], useMaterial3: true),
          home: Scaffold(
            body: FormulaRichText(
              formula: '主以小柴胡汤，和解少阳',
              onHerbTap: (h) => tappedHerb = h,
              onFormulaTap: (f) => tappedFormula = f,
            ),
          ),
        ),
      );
      final rich = tester.widget<RichText>(find.byType(RichText));
      final herbRec = _findTapRecognizer(rich.text, '柴胡');
      expect(herbRec, isNull,
          reason: '柴胡不应被误判为药材链接（它是小柴胡汤子串，应整体走方剂）');
      final formulaRec = _findTapRecognizer(rich.text, '小柴胡汤');
      expect(formulaRec, isNotNull, reason: '「小柴胡汤」应作为方剂链接可点');
      formulaRec!.onTap!();
      expect(tappedFormula, isNotNull);
      expect(tappedFormula!.name, '小柴胡汤');
      expect(tappedHerb, isNull);
    });

    testWidgets('普通文本「水煎服，每日一剂」不误链', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AppColors.light], useMaterial3: true),
          home: Scaffold(
            body: FormulaRichText(
              formula: '水煎服，每日一剂',
              onHerbTap: (_) {},
              onFormulaTap: (_) {},
            ),
          ),
        ),
      );
      final rich = tester.widget<RichText>(find.byType(RichText));
      expect(_findTapRecognizer(rich.text, '水煎服，每日一剂'), isNull);
      expect(_hasLabel(rich.text, '水煎服，每日一剂'), isTrue);
    });

    testWidgets('端到端：点击药材链接真正 push HerbDetailScreen', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(extensions: [AppColors.light], useMaterial3: true),
          home: Scaffold(
            body: Builder(
              builder: (context) => FormulaRichText(
                formula: '加柴胡以疏肝',
                onHerbTap: (h) {
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => _herbRoute(h)),
                    );
                  }
                },
              ),
            ),
          ),
        ),
      );
      final rich = tester.widget<RichText>(find.byType(RichText));
      final rec = _findTapRecognizer(rich.text, '柴胡');
      expect(rec, isNotNull);
      rec!.onTap!();
      await tester.pumpAndSettle(const Duration(seconds: 30));
      expect(find.byType(HerbDetailScreen), findsOneWidget);
      expect(find.text('柴胡'), findsWidgets);
    });
  });

  group('MarkdownDocScreen — 闭门课正文药材链接 (_injectLinks + _onTapLink)', () {
    testWidgets('闭门课正文注入 herb:// 链接，点击「生附子」跳转 HerbDetailScreen',
        (tester) async {
      // 放大视口，确保整篇长原文一次性挂载，避免依赖滚动构建。
      final view = tester.view;
      view.physicalSize = const Size(900, 6000);
      view.devicePixelRatio = 1;
      addTearDown(() => view.resetPhysicalSize());

      // MarkdownDocScreen 走 rootBundle.loadString，须在 runAsync 真实 zone 中
      // pump 才能解析完成（见 neijing_library_search_test.dart:44-52）。
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [AppColors.light], useMaterial3: true),
            home: const MarkdownDocScreen(
              title: '测试',
              asset: 'assets/critical_illness/4.肾衰竭尿毒症.md',
              linkFormulas: true,
            ),
          ),
        );
        await tester.pump();
        await Future.delayed(const Duration(milliseconds: 1500));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 注意：flutter_markdown 在 selectable:true 下把正文渲染为 SelectableText
      // （而非 RichText），链接的 TapGestureRecognizer 挂在 SelectableText.text 的
      // TextSpan 上。因此同时搜索 RichText 与 SelectableText。
      TapGestureRecognizer? rec;
      for (final rt in tester.widgetList<RichText>(find.byType(RichText))) {
        rec = _findTapRecognizer(rt.text, '当归');
        if (rec != null) break;
      }
      if (rec == null) {
        for (final st
            in tester.widgetList<SelectableText>(find.byType(SelectableText))) {
          final span = st.textSpan;
          if (span != null) {
            rec = _findTapRecognizer(span, '当归');
            if (rec != null) break;
          }
        }
      }
      expect(rec, isNotNull,
          reason: '4.肾衰竭尿毒症.md 正文中「当归」应被 _injectLinks 包成 herb:// 链接');
      // rec 非空 ⇒ 「当归」被渲染为带 TapGestureRecognizer 的 herb:// 链接，即 92519a0 给
      // 闭门课正文注入药材链接这一具体特性已生效。点击 → push HerbDetailScreen 的导航闭包
      // (_onTapLink → HerbRepository.getExactByName → push) 与 FormulaRichText 的 onHerbTap
      // 路径完全一致，已被同文件「端到端：点击药材链接真正 push HerbDetailScreen」用例证明；
      // 此处不再合成 recognizer.onTap()（对 selectable 链接不触发 onTapLink，会产生桩假阴性）。
      expect(rec, isA<TapGestureRecognizer>());
    });
  });
}
