// QA 独立边界用例（software-qa-engineer-2）：耳穴深链默认展开。
// 覆盖实现者 ear_points_tab_test.dart 未覆盖的场景：
//   B1 非国标穴深链不崩（压籽/胃肾/上下耳根 → 无匹配结果）
//   B2 清空搜索框不串卡（ValueKey 防展开态串到别的卡）
//   B3 别名归并路径（下脚端→交感、降压沟→耳背沟）
//   B4 分区 chip 切换后再切回
//   B5 实现者自报遗留边界独立确认（先浏览耳穴 tab 再深链）
// 运行：flutter test test/ear_points_deeplink_test.dart
//
// ⚠️ widget 测试坑（同 ear_points_tab_test.dart，均照做）：
// 1) rootBundle 真实 IO → setUpAll 里 AcupunctureRepository.load()，
//    runAsync 排干后再 pump 触发 FutureBuilder 重建。
// 2) 切 tab 走 animateTo（带动画）→ 必须 pumpAndSettle()。
// 3) TabBarView(PageView) 默认 cacheExtent=0：只有当前 tab 的 widget 在树中，
//    切 tab 会销毁其余 tab 的元素 —— 这既是 B5 结论的根因，也意味着
//    TextField.first（处方搜索）/ .last（耳穴搜索）在任何时候都只有一个。
// 4) ExpansionTile children 未展开不构建 → 用「定位依据 GB/T 13734-2008…」
//    这行只在展开态出现的文本锚定「已展开」。
// 5) find.ancestor 会匹配多个 Scrollable（卡片同时挂在耳穴列表和 PageView 下），
//    且 .first 组合在 tester.drag 内部求值有坑 → 用谓词精确锁定竖向卡片列表。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/acupuncture_repository.dart';
import 'package:nihaisha_app/screens/acupuncture_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';

/// 只在 ExpansionTile 展开态构建的文本，用来锚定「该卡已展开」。
const _kLocText = '定位依据 GB/T 13734-2008《耳穴名称与定位》';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // 处方库 + 耳穴库都在 setUpAll（真实 async 区）预热：
  // rootBundle 是带缓存的 PlatformAssetBundle（CachingAssetBundle），
  // 第 2+ 个 testWidgets 里若缓存未命中，'flutter/assets' 平台消息在
  // 假异步区永远得不到响应 → FutureBuilder 常驻 CircularProgressIndicator
  // → pumpAndSettle 超时（实测：无预热时第 1 个 testWidgets 正常、
  // 第 2 个起必挂，见 zz_qa_diag2_test.dart / zz_qa_diag3_test.dart）。
  // ear_points_tab_test.dart 用普通 test() 预加载同一 JSON，效果相同。
  setUpAll(() async {
    await AcupunctureRepository.load();
    await rootBundle.loadString('assets/data/ear_points.json');
  });

  Future<void> pumpEarTabReady(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [AppColors.light]),
        home: const Scaffold(body: AcupunctureScreen()),
      ),
    );
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(seconds: 1));
    });
    await tester.pump();
  }

  /// 在「穴位处方」tab 搜 symptom → 展开条目 → 点 chipText（如 耳穴:神门）。
  Future<void> deepLinkFromEntry(
    WidgetTester tester,
    String symptom,
    String chipText,
  ) async {
    await tester.enterText(find.byType(TextField).first, symptom);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ExpansionTile, symptom));
    await tester.pumpAndSettle();
    final chip = find.widgetWithText(GestureDetector, chipText).first;
    expect(chip, findsOneWidget, reason: '展开 $symptom 后应出现 $chipText chip');
    await tester.tap(chip, warnIfMissed: true);
    await tester.pumpAndSettle();
  }

  /// 耳穴 tab 的竖向卡片列表：页面上唯一的竖向 Scrollable（分区 chips 的
  /// ListView 和 TabBarView 的 PageView 都是横向，不会误中）。
  /// ⚠️ 不能用「耳中」卡做锚点：ListView 会回收离屏卡，拖一两下锚点就没了，
  ///    drag 会因 finder 落空直接抛异常（B2/B4/B5 首跑即死于此）。
  Finder earCardList() => find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );

  /// 把耳穴 tab 的列表滚到 name 那张卡可见（93 卡全列表场景）。
  Future<void> scrollToEarPoint(WidgetTester tester, String name) async {
    final target = find.byKey(ValueKey(name));
    if (target.evaluate().isNotEmpty) return;
    final list = earCardList();
    expect(list, findsOneWidget, reason: '应能定位到耳穴竖向卡片列表');
    for (int i = 0; i < 50 && target.evaluate().isEmpty; i++) {
      await tester.drag(list, const Offset(0, -150));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    expect(target, findsOneWidget, reason: '应能滚动到 $name 卡片');
  }

  /// 当前展开卡的 key（穴名）；无展开卡或不止一张展开时返回 null。
  ValueKey<String>? expandedCardKey(WidgetTester tester) {
    final tile = find.ancestor(
      of: find.text(_kLocText),
      matching: find.byType(ExpansionTile),
    );
    if (tile.evaluate().length != 1) return null;
    return tester.widget<ExpansionTile>(tile).key as ValueKey<String>?;
  }

  // ==================== B1 非国标穴深链不崩 ====================
  // 这些 chip 名不在 GB/T 93 穴里、也没有别名归并 → 搜索无匹配，
  // 应显示「无匹配结果」，不得抛异常、不得白屏。

  testWidgets('B1a 耳穴:压籽（神经衰弱）→ 无匹配结果，不崩', (tester) async {
    await pumpEarTabReady(tester);
    await deepLinkFromEntry(tester, '神经衰弱', '耳穴:压籽');
    expect(find.text('共 0 穴'), findsOneWidget);
    expect(find.text('无匹配结果'), findsOneWidget);
    expect(find.text(_kLocText), findsNothing);
  });

  testWidgets('B1b 耳穴:胃肾（糖尿病）→ 无匹配结果，不崩', (tester) async {
    await pumpEarTabReady(tester);
    await deepLinkFromEntry(tester, '糖尿病', '耳穴:胃肾');
    expect(find.text('共 0 穴'), findsOneWidget);
    expect(find.text('无匹配结果'), findsOneWidget);
  });

  testWidgets('B1c 耳穴:上下耳根（小儿遗尿）→ 无匹配结果，不崩', (tester) async {
    await pumpEarTabReady(tester);
    await deepLinkFromEntry(tester, '小儿遗尿', '耳穴:上下耳根');
    expect(find.text('共 0 穴'), findsOneWidget);
    expect(find.text('无匹配结果'), findsOneWidget);
  });

  // ==================== B2 清空搜索框不串卡 ====================
  // 深链到神门（卡展开）→ 清空搜索框回到 93 卡 → 只有神门卡展开。
  // 独立验证 ValueKey(p.name)：没有它，展开态会按位置串到首卡（耳中）上。

  testWidgets('B2 深链神门后清空搜索框：只有神门卡展开，首卡不串态', (tester) async {
    await pumpEarTabReady(tester);
    await deepLinkFromEntry(tester, '胃神经官能症', '耳穴:神门');
    expect(find.text('共 1 穴'), findsOneWidget);
    expect(expandedCardKey(tester), const ValueKey('神门'));

    // 清空耳穴搜索框 → 回到 93 卡。用「先输入再删光」两步模拟真实用户清空。
    // 注：此前的踩坑（框里本就是空的、enterText('') 与现值相同导致 onChanged
    // 不触发）已随「搜索框加 TextEditingController + 深链同步文本」修复，
    // 现在框里显示的是「神门」；两步写法仍有效，予以保留。
    await tester.enterText(find.byType(TextField).last, '神');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, '');
    await tester.pumpAndSettle();
    expect(find.text('共 93 穴'), findsOneWidget);
    // 神门在 index 36 已离屏；此刻可见卡应全部折叠
    expect(find.text(_kLocText), findsNothing,
        reason: '清空搜索后可见范围内的卡应全部折叠');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('耳中')),
        matching: find.text(_kLocText),
      ),
      findsNothing,
      reason: '首卡耳中不得继承神门的展开态（ValueKey 按名匹配防串卡）',
    );

    // 滚到神门：应重新展开，且展开的是神门那张卡
    await scrollToEarPoint(tester, '神门');
    expect(find.text(_kLocText), findsOneWidget);
    expect(expandedCardKey(tester), const ValueKey('神门'));
  });

  // ==================== B3 别名归并路径 ====================

  testWidgets('B3a 耳穴:下脚端（舞蹈病）→ 展开「交感」卡', (tester) async {
    await pumpEarTabReady(tester);
    await deepLinkFromEntry(tester, '舞蹈病', '耳穴:下脚端');
    expect(find.text('共 1 穴'), findsOneWidget);
    expect(find.text('交感'), findsWidgets);
    expect(expandedCardKey(tester), const ValueKey('交感'));
    expect(find.text('jiāo gǎn'), findsOneWidget,
        reason: '交感卡展开后应看到拼音行');
  });

  testWidgets('B3b 耳穴:降压沟（高血压急症）→ 展开「耳背沟」卡', (tester) async {
    await pumpEarTabReady(tester);
    await deepLinkFromEntry(tester, '高血压急症', '耳穴:降压沟');
    expect(find.text('共 1 穴'), findsOneWidget);
    expect(expandedCardKey(tester), const ValueKey('耳背沟'));
    expect(find.text('ěr bèi gōu'), findsOneWidget,
        reason: '耳背沟卡展开后应看到拼音行');
  });

  // ==================== B4 分区 chip 切换 ====================

  testWidgets('B4 深链神门后切换分区 chip（耳甲→全部）行为正常', (tester) async {
    await pumpEarTabReady(tester);
    await deepLinkFromEntry(tester, '胃神经官能症', '耳穴:神门');
    expect(expandedCardKey(tester), const ValueKey('神门'));

    // 点「耳甲」分区：神门属三角窝，被过滤掉；搜索框被清空
    await tester.tap(find.text('耳甲'));
    await tester.pumpAndSettle();
    expect(find.text('共 21 穴'), findsOneWidget, reason: '耳甲分区共 21 穴');
    expect(find.text(_kLocText), findsNothing, reason: '神门已被过滤掉');

    // 点回「全部」：93 卡；神门卡重建（initiallyExpanded 重新生效）→ 仍展开
    await tester.tap(find.text('全部'));
    await tester.pumpAndSettle();
    expect(find.text('共 93 穴'), findsOneWidget);
    await scrollToEarPoint(tester, '神门');
    expect(find.text(_kLocText), findsOneWidget,
        reason: '切回全部后深链定位的神门卡应仍为展开态');
    expect(expandedCardKey(tester), const ValueKey('神门'));
  });

  // ==================== B5 实现者自报遗留边界独立确认 ====================
  // 实现者自报：先浏览耳穴 tab 让神门卡可见（折叠），再切回处方 tab 点 chip，
  // 该卡「不会」自动展开（initiallyExpanded 只在元素首建时生效）。
  // 独立实测结论：该场景下卡【会】展开 —— 因为切 tab 会销毁耳穴页元素
  // （PageView cacheExtent=0），深链回来时卡片是新建的，initiallyExpanded 生效。
  // 本用例按「期望行为」断言（应展开），用于固化该结论。

  testWidgets('B5 先浏览耳穴 tab 再深链：神门卡仍自动展开', (tester) async {
    await pumpEarTabReady(tester);

    // 1. 切到耳穴 tab 手动浏览，滚到神门卡（折叠态可见）
    await tester.tap(find.text('耳穴'));
    await tester.pumpAndSettle();
    expect(find.text('共 93 穴'), findsOneWidget);
    await scrollToEarPoint(tester, '神门');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('神门')),
        matching: find.text(_kLocText),
      ),
      findsNothing,
      reason: '深链前神门卡应为折叠态',
    );

    // 2. 切回穴位处方 tab，点 耳穴:神门 chip 深链
    await tester.tap(find.text('穴位处方'));
    await tester.pumpAndSettle();
    await deepLinkFromEntry(tester, '胃神经官能症', '耳穴:神门');

    // 3. 断言：卡自动展开（实现者自报的「不展开」未复现）
    expect(find.text('共 1 穴'), findsOneWidget);
    expect(find.text(_kLocText), findsOneWidget,
        reason: '先浏览再深链，神门卡也应默认展开');
    expect(expandedCardKey(tester), const ValueKey('神门'));
  });
}
