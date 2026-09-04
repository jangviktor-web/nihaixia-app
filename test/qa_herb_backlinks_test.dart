// 独立功能验证 —— 药物详情页「相关内容」三级结构：
//   一级：药物详情页 3 个入口按钮（关联医案 / 关联闭门课 / 含此药方剂，带计数徽标）
//   二级：herb_related_screens.dart 的三个仅标题简洁列表页（数据各自独立加载）
//   三级：MedicalCaseDetailScreen / MarkdownDocScreen / FormulaDetailScreen
//
// 关键坑（沿用既往实测结论）：
//   - AppColors 是 ThemeExtension，必须 ThemeData(extensions:[AppColors.light]) 包裹。
//   - HerbDetailScreen / 列表页会调 DatabaseHelper（收藏态），需 sqflite FFI 初始化。
//   - rootBundle 大文件加载与 sqflite-ffi IO 须在 runAsync 真实 zone 解析；全量套件
//     高负载下 DB 可能短暂锁住（"database locked" 警告），所有 settle 统一包 runAsync
//     以消除负载相关的 flaky（单文件跑全绿、全量跑偶挂的根因即在此）。
//
// 运行：
//   TEMP="C:/Users/jangviktor/AppData/Local/Temp" TMP="C:/Users/jangviktor/AppData/Local/Temp" \
//     /d/flutter/bin/flutter test test/qa_herb_backlinks_test.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nihaisha_app/data/critical_illness_data.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/data/herb_repository.dart';
import 'package:nihaisha_app/data/medical_case_data.dart';
import 'package:nihaisha_app/models/herb.dart';
import 'package:nihaisha_app/screens/formula_detail_screen.dart';
import 'package:nihaisha_app/screens/herb_detail_screen.dart';
import 'package:nihaisha_app/screens/herb_related_screens.dart';
import 'package:nihaisha_app/screens/markdown_doc_screen.dart';
import 'package:nihaisha_app/screens/medical_case_detail_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';

Widget _app(Widget home) => MaterialApp(
      theme: ThemeData(useMaterial3: true, extensions: [AppColors.light]),
      home: home,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Directory? _dbTempDir;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    // flutter test 默认多 isolate 并行跑测试文件，而各文件共享同一数据库文件，
    // 并行 isolate 之间会产生 SQLite 文件锁竞争（code 5 "database is locked"，
    // 详情页收藏态查询 open 时抛 SqfliteFfiException → 全量跑偶发挂）。
    // 给本文件一个专属临时库路径，彻底隔离锁竞争。
    _dbTempDir = await Directory.systemTemp.createTemp('qa_herb_backlinks_db');
    await databaseFactory.setDatabasesPath(_dbTempDir!.path);
    await HerbRepository.load();
    await FormulaRepository.load();
  });

  tearDownAll(() async {
    final dir = _dbTempDir;
    if (dir != null) {
      try {
        await dir.delete(recursive: true);
      } catch (_) {// 清理失败不影响测试结论
      }
    }
  });

  /// 处理路由 push 首帧 + 在真实 zone 中等待稳定（IO/动画与负载无关地完成）。
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.runAsync(() => tester.pumpAndSettle(const Duration(seconds: 30)));
  }

  /// 渲染药物详情页并等待异步计数就绪（医案计数需 getAllMedicalCases 完成）。
  Future<void> pumpHerbPage(WidgetTester tester, Herb herb) async {
    final view = tester.view;
    view.physicalSize = const Size(900, 6000);
    view.devicePixelRatio = 1;
    addTearDown(() => view.resetPhysicalSize());
    // 预热 getAllMedicalCases 缓存（rootBundle 必须在 runAsync 真实 zone 解析）。
    await tester.runAsync(() => getAllMedicalCases());
    await tester.pumpWidget(_app(HerbDetailScreen(herb: herb)));
    await settle(tester);
  }

  group('一级：药物详情页相关内容入口按钮', () {
    testWidgets('三个入口按钮齐备且计数正确（生附子）', (tester) async {
      final herb = HerbRepository.getExactByName('生附子')!;
      await pumpHerbPage(tester, herb);

      expect(find.text('关联医案'), findsOneWidget);
      expect(find.text('关联闭门课'), findsOneWidget);
      expect(find.text('含此药方剂'), findsOneWidget);

      // 与各列表页一致的预期计数。
      final caseCount = (await getAllMedicalCases())
          .where((c) => c.herbNames.contains(herb.name))
          .length;
      final critCount = kCriticalIllnesses
          .where((it) => it.tags
              .any((t) => HerbRepository.canonicalOf(t) == herb.name))
          .length;
      final formulaCount = FormulaRepository.getAll()
          .where((f) => f.components
              .any((c) => HerbRepository.canonicalOf(c.name) == herb.name))
          .length;
      expect(caseCount, greaterThan(0));
      expect(critCount, greaterThan(0));
      expect(formulaCount, greaterThan(0));

      expect(find.text('$caseCount 条'), findsOneWidget,
          reason: '关联医案入口应显示计数 $caseCount');
      expect(find.text('$critCount 条'), findsOneWidget,
          reason: '关联闭门课入口应显示计数 $critCount');
      expect(find.text('$formulaCount 条'), findsOneWidget,
          reason: '含此药方剂入口应显示计数 $formulaCount');
    });
  });

  group('二级：关联医案列表页', () {
    testWidgets('生附子：仅标题列表，点按条目跳 MedicalCaseDetailScreen', (tester) async {
      final herb = HerbRepository.getExactByName('生附子')!;
      await pumpHerbPage(tester, herb);

      await tester.tap(find.text('关联医案'));
      await settle(tester);

      expect(find.byType(HerbRelatedCasesScreen), findsOneWidget);
      expect(find.text('关联医案 · 生附子'), findsOneWidget);
      final tiles = find.byType(ListTile);
      expect(tiles, findsWidgets, reason: '列表页应展示医案标题条目');

      await tester.tap(tiles.first);
      await settle(tester);
      expect(find.byType(MedicalCaseDetailScreen), findsOneWidget,
          reason: '点按医案标题应跳转 MedicalCaseDetailScreen');
    });
  });

  group('二级：关联闭门课列表页', () {
    testWidgets('生附子：命中重症条目，点按跳 MarkdownDocScreen', (tester) async {
      final herb = HerbRepository.getExactByName('生附子')!;
      await pumpHerbPage(tester, herb);

      await tester.tap(find.text('关联闭门课'));
      await settle(tester);

      expect(find.byType(HerbRelatedCriticalScreen), findsOneWidget);
      expect(find.text('关联闭门课 · 生附子'), findsOneWidget);
      expect(find.text('肾衰竭尿毒症'), findsWidgets,
          reason: '生附子命中的重症条目（CriticalIllness.title）应出现在列表');

      await tester.tap(find.text('肾衰竭尿毒症'));
      await settle(tester);
      expect(find.byType(MarkdownDocScreen), findsOneWidget,
          reason: '点按闭门课题目应跳转 MarkdownDocScreen');
    });
  });

  group('二级：含此药方剂列表页', () {
    testWidgets('生附子：命中方剂条目，点按跳 FormulaDetailScreen', (tester) async {
      final herb = HerbRepository.getExactByName('生附子')!;
      await pumpHerbPage(tester, herb);

      await tester.tap(find.text('含此药方剂'));
      await settle(tester);

      expect(find.byType(HerbRelatedFormulasScreen), findsOneWidget);
      expect(find.text('含此药方剂 · 生附子'), findsOneWidget);
      expect(find.text('红斑性狼疮标准方'), findsWidgets,
          reason: '生附子命中的方剂应出现在列表');

      await tester.tap(find.text('红斑性狼疮标准方'));
      await settle(tester);
      expect(find.byType(FormulaDetailScreen), findsOneWidget,
          reason: '点按方剂名应跳转 FormulaDetailScreen');
    });
  });

  group('别名归一（大附子 → 生附子）', () {
    testWidgets('以别名渲染时入口计数与闭门课列表与正名一致', (tester) async {
      final aliased = HerbRepository.getExactByName('大附子')!;
      expect(aliased.name, '生附子',
          reason: 'getExactByName("大附子") 应归一到正名 生附子');
      await pumpHerbPage(tester, aliased);

      final critCount = kCriticalIllnesses
          .where((it) => it.tags
              .any((t) => HerbRepository.canonicalOf(t) == aliased.name))
          .length;
      expect(find.text('$critCount 条'), findsOneWidget,
          reason: '以别名渲染时闭门课入口计数应与正名一致（$critCount）');

      await tester.tap(find.text('关联闭门课'));
      await settle(tester);
      expect(find.text('肾衰竭尿毒症'), findsWidgets,
          reason: '以别名渲染时闭门课列表应与正名一致');
    });
  });
}
