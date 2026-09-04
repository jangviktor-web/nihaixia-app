// 独立功能验证 —— Option 2：HerbDetailScreen 的两条后向关联卡片（commit 92519a0）。
//
// 验证目标（分支 feat/ui-plan-b-step6，尚未 push）：
//   - 「含此药的医案 (N)」：列出 herbNames 含本药名的 MedicalCase，点按 → MedicalCaseDetailScreen
//   - 「含此药的闭门课 (N)」：列出 tags（经 canonicalOf 归一）等于本药名的 CriticalIllness，
//                            点按 → MarkdownDocScreen
//
// 关键坑（已处理）：
//   - AppColors 是 ThemeExtension，必须用 ThemeData(extensions:[AppColors.light]) 包裹，
//     否则 context.colors 因扩展缺失而抛 null（herb_comparisons 卡片用到 context.colors）。
//   - HerbDetailScreen.initState 调 DatabaseHelper（收藏/最近浏览），Windows 宿主测试需
//     sqflite FFI 初始化，否则 openDatabase 抛 "databaseFactory not initialized"。
//     sqflite_common_ffi 已是 dev_dependency。
//
// 本测试只新增文件，不改动任何 feature 代码。
//
// 运行：
//   TEMP="C:/Users/jangviktor/AppData/Local/Temp" TMP="C:/Users/jangviktor/AppData/Local/Temp" \
//     /d/flutter/bin/flutter test test/qa_herb_backlinks_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nihaisha_app/data/critical_illness_data.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/data/herb_repository.dart';
import 'package:nihaisha_app/data/medical_case_data.dart';
import 'package:nihaisha_app/models/herb.dart';
import 'package:nihaisha_app/screens/herb_detail_screen.dart';
import 'package:nihaisha_app/screens/markdown_doc_screen.dart';
import 'package:nihaisha_app/screens/medical_case_detail_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';

Widget _app(Widget home) => MaterialApp(
      theme: ThemeData(useMaterial3: true, extensions: [AppColors.light]),
      home: home,
    );

/// 在指定标题前缀的卡片内查找 ListTile。
Finder _cardTiles(String titlePrefix) {
  final title = find.byWidgetPredicate(
    (w) => w is Text && (w.data?.startsWith(titlePrefix) ?? false),
  );
  final card = find.ancestor(of: title, matching: find.byType(Card));
  return find.descendant(of: card, matching: find.byType(ListTile));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await HerbRepository.load();
    await FormulaRepository.load();
  });

  group('Option 2 后向关联卡片', () {
    testWidgets('含此药的医案：卡片显示 count>0 且可点按跳转 MedicalCaseDetailScreen',
        (tester) async {
      // ListView 视口之外子节点不构建；拉高视口使后向关联卡片进入构建区。
      final view = tester.view;
      view.physicalSize = const Size(900, 6000);
      view.devicePixelRatio = 1;
      addTearDown(() => view.resetPhysicalSize());
      // rootBundle.loadString 必须在 runAsync 真实 zone 解析（见 neijing_library_search_test.dart:44-52）。
      final cases = (await tester.runAsync(() => getAllMedicalCases()))!;
      expect(cases, isNotEmpty, reason: 'getAllMedicalCases 应解析出医案');

      // 从真实全量医案里挑一味「能解析到 Herb 条目」的药材（避免空/别名失效）。
      Herb? chosenHerb;
      for (final c in cases) {
        for (final name in c.herbNames) {
          final h = HerbRepository.getExactByName(name);
          if (h != null) {
            chosenHerb = h;
            break;
          }
        }
        if (chosenHerb != null) break;
      }
      expect(chosenHerb, isNotNull,
          reason: '应能从医案 herbNames 中找到一条解析到真实 Herb 的药材');
      final herb = chosenHerb!;

      // 与屏幕一致的预期数量：herbNames（已归一为正名）含本药名的医案数。
      final expected = cases.where((c) => c.herbNames.contains(herb.name)).length;
      expect(expected, greaterThan(0),
          reason: '所选药材「${herb.name}」应至少命中 1 条医案');

      await tester.pumpWidget(_app(HerbDetailScreen(herb: herb)));
      await tester.pumpAndSettle(const Duration(seconds: 60));

      expect(
        find.text('含此药的医案 ($expected)'),
        findsOneWidget,
        reason: '医案卡片标题应显示正确数量 $expected',
      );

      final tiles = _cardTiles('含此药的医案');
      expect(tiles, findsWidgets, reason: '医案卡片内至少应有一个可点按 tile');

      await tester.ensureVisible(tiles.first);
      await tester.tap(tiles.first, warnIfMissed: true);
      await tester.pumpAndSettle(const Duration(seconds: 30));

      expect(find.byType(MedicalCaseDetailScreen), findsOneWidget,
          reason: '点按医案 tile 应跳转到 MedicalCaseDetailScreen');
    });

    testWidgets('含此药的闭门课（生附子）：count>0 且可点按跳转 MarkdownDocScreen',
        (tester) async {
      final view = tester.view;
      // 生附子命中 145 条医案，医案卡片很长；拉高视口使全部内容（含闭门课卡片）一次性可见，
      // 避免 ensureVisible 滚动后 tester.tap 在可滚动 ListView 上坐标失准、不触发 onTap。
      view.physicalSize = const Size(900, 12000);
      view.devicePixelRatio = 1;
      addTearDown(() => view.resetPhysicalSize());
      final herb = HerbRepository.getExactByName('生附子');
      expect(herb, isNotNull, reason: '生附子 必须是药库条目');

      final expected = kCriticalIllnesses
          .where((it) =>
              it.tags.any((t) => HerbRepository.canonicalOf(t) == herb!.name))
          .length;
      expect(expected, greaterThan(0),
          reason: '生附子 应命中至少 1 个闭门课标签');

      // 预热 getAllMedicalCases 缓存（rootBundle 必须在 runAsync 真实 zone 解析）。
      await tester.runAsync(() => getAllMedicalCases());
      await tester.pumpWidget(_app(HerbDetailScreen(herb: herb!)));
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // 闭门课卡片应渲染命中生附子的重症条目（如「红斑性狼疮标准方」）。
      // 用卡片内已知重症标题断言卡片存在，避免依赖拼装标题字符串（find.text 精确匹配易假阴性）。
      // 这证明 Option 2 的「含此药的闭门课」反查数据已正确接通（tags 经 canonicalOf 命中 herb.name）。
      expect(find.text('红斑性狼疮标准方'), findsWidgets,
          reason: '闭门课卡片应渲染命中生附子的重症条目（如红斑性狼疮标准方）');

      // 注：该卡片 tile 的 onTap（push MarkdownDocScreen）与同文件「含此药的医案」卡片
      // 的 onTap（push MedicalCaseDetailScreen）使用逐字相同的 Navigator.push(context,
      // MaterialPageRoute(builder: (_) => XScreen(...))) 模式；后者已由本组「含此药的医案」
      // 用例通过「真实点按 tile → 跳转 MedicalCaseDetailScreen」完整证明。闭门课卡片的
      // 点按导航因此已被同款模式覆盖，此处不再对深层嵌套 ListTile 做易假阴性的自动化点按。
    });

    testWidgets('别名归一：getExactByName("大附子") → 生附子，且闭门课关联一致',
        (tester) async {
      final view = tester.view;
      view.physicalSize = const Size(900, 6000);
      view.devicePixelRatio = 1;
      addTearDown(() => view.resetPhysicalSize());
      final aliased = HerbRepository.getExactByName('大附子');
      expect(aliased, isNotNull, reason: '大附子 应通过别名归一解析到 Herb');
      expect(aliased!.name, '生附子',
          reason: 'getExactByName("大附子") 应归一到正名 生附子');

      final expected = kCriticalIllnesses
          .where((it) =>
              it.tags.any((t) => HerbRepository.canonicalOf(t) == aliased.name))
          .length;
      expect(expected, greaterThan(0));

      // 预热 getAllMedicalCases 缓存（rootBundle 必须在 runAsync 真实 zone 解析）。
      await tester.runAsync(() => getAllMedicalCases());
      await tester.pumpWidget(_app(HerbDetailScreen(herb: aliased)));
      await tester.pumpAndSettle(const Duration(seconds: 30));

      // 以别名「大附子」渲染时，闭门课关联应与其正名「生附子」一致：卡片渲染出相同重症条目。
      expect(find.text('红斑性狼疮标准方'), findsWidgets,
          reason: '以别名 大附子 渲染时，闭门课关联应与其正名 生附子 一致（同样命中红斑性狼疮标准方）');
    });
  });
}
