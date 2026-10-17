// 「耳穴」tab 最小验证：结构化库可解析 + UI 能筛 + 处方 chip 深链可用。
// 运行：flutter test test/ear_points_tab_test.dart
//
// ⚠️ 三个坑（都踩过）：
// 1) rootBundle 是真实 IO，在 testWidgets 的假异步区里不会自己完成 → 必须
//    `await tester.runAsync(...)` 给它真实时间跑，再补一次 pump 触发 FutureBuilder 重建。
// 2) 切 tab 走的是 `animateTo`（带动画），`pump()` 默认推进 0ms，画面不会变 →
//    必须用 `pumpAndSettle()`。
// 3) 耳穴 tab 首帧是 CircularProgressIndicator（无限动画），在数据没到位前 pumpAndSettle
//    会死等 → 先 runAsync 排干，再 settle。
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/acupuncture_repository.dart';
import 'package:nihaisha_app/screens/acupuncture_screen.dart';
import 'package:nihaisha_app/theme/app_colors.dart';
import 'package:nihaisha_app/widgets/ear_points_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 仓库加载放 setUpAll：这里跑在真实 async 区，await 平台通道不会挂死。
  setUpAll(() async => AcupunctureRepository.load());

  test('ear_points.json 解析出 93 穴、10 分区，定位全非空', () async {
    final str = await rootBundle.loadString('assets/data/ear_points.json');
    final data = jsonDecode(str) as Map<String, dynamic>;
    final points = data['points'] as List<dynamic>;

    expect(points.length, 93, reason: 'GB/T 13734-2008 共 93 穴');
    expect(data['regions'].length, 10, reason: '10 个耳区');
    expect(
      points.where((p) => (p['location'] as String).isEmpty).length,
      0,
      reason: '每穴都应有定位',
    );
  });

  /// 自检：确认上面那条「X 分量取负」判据真的能抓到水平镜像，而不是恒为假。
  test('回归锚自检：diagonal3Values(-1,1,1) 的 X 分量确为负', () {
    expect(Matrix4.diagonal3Values(-1, 1, 1).storage[0], -1.0);
  });

  /// 耳穴 tab 的 asset 加载始于 initState，需在 runAsync 里给它真实时间跑完。
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
    // 搜索框自身也含这段文字，必须锚到 ExpansionTile 上再点
    await tester.tap(find.widgetWithText(ExpansionTile, symptom));
    await tester.pumpAndSettle();
    // widgetWithText 会把外层 Scrollable 的 GestureDetector 也算上 → 取最内层
    final chip = find.widgetWithText(GestureDetector, chipText).first;
    expect(chip, findsOneWidget, reason: '展开 $symptom 后应出现 $chipText chip');
    await tester.tap(chip, warnIfMissed: true);
    await tester.pumpAndSettle();
  }

  /// 耳穴 tab 搜索框当前文本。直接读 controller，避免裸 find.text 误中
  /// EditableText；切到耳穴 tab 时树上只有它一个 TextField，故 .last 即它。
  String earFieldText(WidgetTester tester) =>
      tester.widget<TextField>(find.byType(TextField).last).controller!.text;

  testWidgets('耳穴定位图：正/背两个 tab、出处标注可见', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light().copyWith(extensions: [AppColors.light]),
        home: const Scaffold(body: Center(child: EarPointsMap())),
      ),
    );
    await tester.pump();
    // 图片资产走真实 IO，runAsync 给解码留时间；文本断言不依赖图片渲染完成。
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    expect(find.text('正面 84 穴'), findsOneWidget);
    expect(find.text('背面 9 穴'), findsOneWidget);
    expect(find.textContaining('仅供学习参考'), findsOneWidget);

    // 回归锚：_flipX=false → 不应存在 X 轴取负的 Transform（水平镜像会让图内
    // 穴名文字反读）。不能裸判 find.byType(Transform) findsNothing：Material /
    // TabBar 内部本来就有 4 个 Transform（实测），只筛水平翻转那一个。
    final mirrors = tester
        .widgetList<Transform>(find.byType(Transform))
        .where((t) => t.transform.storage[0] < 0)
        .toList();
    expect(
      mirrors,
      isEmpty,
      reason: '按原始朝向展示（_flipX=false）时不应再有水平镜像 Transform',
    );
  });

  testWidgets('「耳穴」tab 默认 93 穴，搜「交感」后剩 1 穴', (tester) async {
    await pumpEarTabReady(tester);

    await tester.tap(find.text('耳穴'));
    await tester.pumpAndSettle();

    expect(find.text('共 93 穴'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, '交感');
    await tester.pump();

    expect(find.text('共 1 穴'), findsOneWidget);
    expect(find.text('交感'), findsWidgets);
  });

  testWidgets('点处方里的「耳穴:神门」chip → 跳到耳穴 tab 且只剩该穴', (tester) async {
    await pumpEarTabReady(tester);

    // 处方 chip 只在 ExpansionTile 展开后才建出来 → 先搜个小条目再展开它
    await tester.enterText(find.byType(TextField).first, '胃神经官能症');
    await tester.pumpAndSettle();
    // 注意：搜索框自身也含这段文字，必须锚到 ExpansionTile 上再点
    await tester.tap(find.widgetWithText(ExpansionTile, '胃神经官能症'));
    await tester.pumpAndSettle();

    // 注意：widgetWithText 会把 Scrollable 等外层 GestureDetector 也匹配上，取最内层那个
    final chip = find.widgetWithText(GestureDetector, '耳穴:神门').first;
    expect(chip, findsOneWidget, reason: '展开后应出现 耳穴:神门 chip');
    await tester.tap(chip, warnIfMissed: true);
    await tester.pumpAndSettle();

    expect(find.text('共 1 穴'), findsOneWidget);
    expect(find.text('神门'), findsWidgets);

    // 深链后该卡应默认展开：ExpansionTile 的 children 未展开时不会构建，
    // 「定位依据 …」只在展开态出现，用它锚定「已展开」（勿用裸 find.text
    // 找穴名，会误中搜索框里的 EditableText）。
    expect(
      find.text('定位依据 GB/T 13734-2008《耳穴名称与定位》'),
      findsOneWidget,
      reason: '点 耳穴:神门 chip 后该卡应默认展开，直接看到拼音/分区/主治',
    );

    // 搜索框必须同步显示归并后的穴名：否则「空搜索框 + 只剩 1 穴」像 bug，
    // 且用户不知道怎么恢复。
    expect(earFieldText(tester), '神门', reason: '深链后耳穴搜索框应显示「神门」');
  });

  testWidgets('深链后点「全部」分区 chip → 搜索框清空、回 93 穴', (tester) async {
    await pumpEarTabReady(tester);
    await deepLinkFromEntry(tester, '胃神经官能症', '耳穴:神门');
    expect(earFieldText(tester), '神门');

    // 恢复路径：点「全部」分区，搜索词与输入框一起清空。
    // 锚到 ChoiceChip 本体而非裸 Text，否则 tap 落在 Text 上会报 hit-test 警告。
    await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
    await tester.pumpAndSettle();

    expect(find.text('共 93 穴'), findsOneWidget);
    expect(earFieldText(tester), '', reason: '分区 chip 应同步清空输入框');
  });

  testWidgets('深链后切走再切回耳穴 tab：输入框内容与展开态都保持', (tester) async {
    await pumpEarTabReady(tester);
    await deepLinkFromEntry(tester, '胃神经官能症', '耳穴:神门');
    expect(earFieldText(tester), '神门');

    // 切 tab 会销毁耳穴页元素（PageView cacheExtent=0），controller 挂在父
    // State 上，文本不该丢；回来时卡重建，initiallyExpanded 再次生效。
    await tester.tap(find.text('穴位处方'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('耳穴'));
    await tester.pumpAndSettle();

    expect(earFieldText(tester), '神门', reason: '切走再切回输入框内容应保持');
    expect(find.text('共 1 穴'), findsOneWidget);
    expect(
      find.text('定位依据 GB/T 13734-2008《耳穴名称与定位》'),
      findsOneWidget,
      reason: '切回后深链那张卡仍应展开',
    );
  });
}
