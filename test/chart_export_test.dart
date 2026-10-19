import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/screens/meihua_screen.dart';
import 'package:nihaisha_app/utils/chart_export.dart';

/// 与 ChartExportPage 底层截图副本同构的结构（Align + OverflowBox 无限高）。
Widget _fullLayoutHost(GlobalKey key, double width, Widget content) => Align(
      alignment: Alignment.topLeft,
      child: OverflowBox(
        maxHeight: double.infinity,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: RepaintBoundary(
            key: key,
            child: Material(color: Colors.white, child: content),
          ),
        ),
      ),
    );

Widget _tallContent() => Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        60,
        (i) => Container(
          height: 40,
          color: i.isEven ? Colors.blue.shade100 : Colors.white,
          child: Text('第 $i 行 · 排盘内容'),
        ),
      ),
    );

void main() {
  // ponytail: 视口设高让查看层一次布局完，免得跟滚动断言较劲（同 meihua_test）。
  void useTallSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('长图页：可滚动查看 + 两个导出出口', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(MaterialApp(
      home: ChartExportPage(
        title: '八字排盘',
        filename: 'bazi_test.png',
        content: _tallContent(),
      ),
    ));
    await tester.pump();
    expect(find.text('八字排盘'), findsOneWidget);
    expect(find.text('保存图片'), findsOneWidget);
    expect(find.text('分享长图'), findsOneWidget);
    // 内容在树里出现两份是设计如此：底层全量布局的截图副本 + 上层可滚动查看层。
    expect(find.text('第 0 行 · 排盘内容'), findsNWidgets(2));
    expect(find.text('第 59 行 · 排盘内容'), findsNWidgets(2));
  });

  testWidgets('截图副本按自然高度全量布局（长图完整的前提）', (tester) async {
    useTallSurface(tester);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: _fullLayoutHost(key, 1080, _tallContent())),
    ));
    await tester.pump();

    final ro = key.currentContext?.findRenderObject();
    expect(ro, isA<RenderRepaintBoundary>());
    final size = (ro as RenderRepaintBoundary).size;
    // 60 行 × 40px = 2400px，视口只有 2000px：若被视口约束住（=只截到可见区），
    // 高度会是 2000 而不是 2400。这里是 2400 才说明长图能截全。
    expect(size.width, 1080);
    expect(size.height, 2400,
        reason: '高度被视口约束住了，说明内容没全量布局，长图会被裁');
  });

  testWidgets('截图副本宽度取屏宽（不会塌成窄片）', (tester) async {
    useTallSurface(tester);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: _fullLayoutHost(key, 1080, _tallContent()),
      ),
    ));
    await tester.pump();
    final ro = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    // 若宽度约束丢失，Column 会收缩到最宽文本宽度（实测塌到 85px）
    expect(ro.size.width, greaterThan(1000));
  });

  test('capturePng：key 未挂载时安全返回 null（不崩）', () async {
    final bytes = await ChartExport.capturePng(GlobalKey());
    expect(bytes, isNull);
  });

  test('capturePng：挂的不是 RepaintBoundary 时返回 null', () async {
    final key = GlobalKey();
    // 故意挂一个非 boundary 的 key
    final notBoundary = GlobalKey();
    expect(await ChartExport.capturePng(notBoundary), isNull);
    expect(key.currentContext, isNull);
  });

  testWidgets('端到端：梅花页点「存图」能推进长图页并出两个出口', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(const MaterialApp(home: MeihuaScreen()));
    await tester.pump();

    // 梅花页默认就算出结果，AppBar 应有存图按钮
    final exportBtn = find.byIcon(Icons.image_outlined);
    expect(exportBtn, findsOneWidget);

    await tester.tap(exportBtn);
    await tester.pumpAndSettle();

    // 已推进到长图页：标题 + 两个出口 + 免责声明都在
    expect(find.text('梅花易数'), findsWidgets);
    expect(find.text('保存图片'), findsOneWidget);
    expect(find.text('分享长图'), findsOneWidget);
    expect(find.text('仅供学习参考，非吉凶指令'), findsWidgets);
  });

  // 回归守卫：2026-10-19 真机截图 bug——OverflowBox 放开高度的截图副本溢出视口，
  // 画到了底部按钮带上：「三阶段推演」标题从半透明的「保存图片」轮廓钮后面漏出来、
  // 被「分享长图」实心钮截断。三处断言分别盯住三个不变量。
  testWidgets('底栏不透明 + 截图副本溢出被裁 + 全量布局不丢', (tester) async {
    useTallSurface(tester);
    await tester.pumpWidget(MaterialApp(
      home: ChartExportPage(
        title: '回归',
        filename: 'regress.png',
        content: _tallContent(),
      ),
    ));
    await tester.pump();

    // 1) 底栏最外层 Material 必须不透明（按钮 Row 本身透明，就靠这道底兜住漏出内容）
    final barMat = tester.widget<Material>(find
        .ancestor(of: find.text('保存图片'), matching: find.byType(Material))
        .last);
    expect(barMat.color, isNotNull);
    expect(barMat.color!.a, 1.0, reason: '底栏背景透明，视口漏出的内容会穿帮');

    // 2) 截图副本必须被 ClipRect 包住（Stack 自身的硬裁剪没兜住这个溢出）
    final lastLine = find.text('第 59 行 · 排盘内容').first; // 树序在前=底层截图副本
    expect(
      find.ancestor(of: lastLine, matching: find.byType(ClipRect)),
      findsWidgets,
      reason: 'OverflowBox 的溢出部分没被裁住，会画到底部按钮带上',
    );

    // 3) 裁剪只能裁视觉、不能裁布局：boundary 仍按自然高度全量布局（视口仅 2000）
    final ro = tester.renderObject<RenderRepaintBoundary>(find
        .ancestor(of: lastLine, matching: find.byType(RepaintBoundary))
        .first);
    expect(ro.size.height, 2400,
        reason: '高度被视口约束住了，长图会只剩一屏——ClipRect 裁的是画不是布局');
  });
}
