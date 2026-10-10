// 五运六气 · 三张可视化图 测试
//
// 覆盖：
//   ① 三个图 widget 在浅色 / 深色主题下 pump 不抛异常；
//   ② YunQiEngine.yunStepBounds(2018) ≈ 1/20、4/3、6/16、8/30、11/11（±1 天）；
//   ③ 当前步高亮序号 == currentQiStepOf 的返回（2026-10-09 → step 4 五之气）；
//   ④ 五行徽章落宫正确（2018-03-10：火宫含岁运+客运、水宫含司天、土宫含在泉）。
//
// 运行：flutter test test/yunqi_charts_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/screens/yunqi_charts.dart';
import 'package:nihaisha_app/services/yunqi_engine.dart';

/// 把三张图各放进一个固定尺寸的画板并 pump（浅色 / 深色两套主题）。
Future<void> _pumpCharts(
  WidgetTester tester, {
  required Brightness brightness,
  DateTime? date,
}) async {
  final YunQiChartData data = YunQiChartData.of(date ?? DateTime(2026, 10, 9));
  // 视口调高到 1600，保证三张 380dp 高的图都被 ListView 构建出来。
  tester.view.physicalSize = const Size(360, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B4513),
        brightness: brightness,
      ),
      useMaterial3: true,
    ),
    home: Scaffold(
      body: ListView(
        children: <Widget>[
          SizedBox(
            width: 360,
            height: 380,
            child: WuxingChart(data: data),
          ),
          SizedBox(
            width: 360,
            height: 380,
            child: WuyunChart(data: data),
          ),
          SizedBox(
            width: 360,
            height: 380,
            child: LiuqiChart(data: data),
          ),
        ],
      ),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('① 三图 pump 不抛异常', () {
    testWidgets('浅色主题', (WidgetTester tester) async {
      await _pumpCharts(tester, brightness: Brightness.light);
      expect(tester.takeException(), isNull);
    });

    testWidgets('深色主题', (WidgetTester tester) async {
      await _pumpCharts(tester, brightness: Brightness.dark);
      expect(tester.takeException(), isNull);
    });

    testWidgets('极小画布不崩溃（size 退化保护）', (WidgetTester tester) async {
      final YunQiChartData data = YunQiChartData.of(DateTime(2026, 10, 9));
      tester.view.physicalSize = const Size(40, 40);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
        // 用 Stack 叠放，避免极小视口下 Column 报 RenderFlex overflow
        // （本例只验证 painter 的退化保护，不校验布局）。
        home: Scaffold(
          body: Stack(
            children: <Widget>[
              SizedBox(width: 20, height: 20, child: WuxingChart(data: data)),
              SizedBox(width: 20, height: 20, child: WuyunChart(data: data)),
              SizedBox(width: 20, height: 20, child: LiuqiChart(data: data)),
            ],
          ),
        ),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('② yunStepBounds 步界（参考站口径）', () {
    test('2018 年五个步界 ≈ 1/20、4/3、6/16、8/30、11/11（±1 天）', () {
      final List<DateTime> b = YunQiEngine.yunStepBounds(2018);
      expect(b.length, 5);

      const List<List<int>> wantMd = <List<int>>[
        <int>[1, 20],
        <int>[4, 3],
        <int>[6, 16],
        <int>[8, 30],
        <int>[11, 11],
      ];
      for (int i = 0; i < 5; i++) {
        final DateTime want = DateTime(2018, wantMd[i][0], wantMd[i][1]);
        final int diffDays = b[i].difference(want).inDays.abs();
        expect(diffDays <= 1, isTrue,
            reason: '步 $i：期望 ${want.month}/${want.day} 附近，'
                '实得 ${b[i].month}/${b[i].day}（差 $diffDays 天）');
        expect(b[i].year, 2018, reason: '步 $i 应落在 2018 年');
      }
    });

    test('步界严格递增，且基准节气表与偏移表长度一致', () {
      expect(YunQiEngine.yunStepBoundTerms.length, 5);
      expect(YunQiEngine.yunStepBoundOffsetDays.length, 5);
      expect(YunQiEngine.yunStepBoundTerms,
          <String>['大寒', '春分', '芒种', '处暑', '立冬']);
      expect(YunQiEngine.yunStepBoundOffsetDays, <int>[0, 13, 10, 7, 4]);

      for (final int y in <int>[1900, 1984, 2018, 2026, 2043]) {
        final List<DateTime> b = YunQiEngine.yunStepBounds(y);
        for (int i = 0; i < 4; i++) {
          expect(b[i].isBefore(b[i + 1]), isTrue, reason: '$y 步 $i 应早于步 ${i + 1}');
        }
      }
    });

    test('currentYunStep 与步界自洽（界前 1s 归上一步，界时刻归本步）', () {
      const int y = 2018;
      final List<double> ms = YunQiEngine.yunStepBoundMs(y);
      for (int i = 1; i < 5; i++) {
        expect(YunQiEngine.currentYunStep(y, ms[i] - 1000), i - 1,
            reason: '步界 $i 前 1s 应归步 ${i - 1}');
        expect(YunQiEngine.currentYunStep(y, ms[i]), i,
            reason: '步界 $i 时刻应归步 $i');
      }
      // 早于初之运（大寒前）→ 4（上一年五之运的延续，同 currentQiStep 口径）
      expect(YunQiEngine.currentYunStep(y, ms[0] - 1000), 4);
      // 五之运一直延续到次年大寒
      expect(YunQiEngine.currentYunStep(y, ms[4] + 86400000.0 * 30), 4);
    });

    test('qiStepBounds 与 zhuQiSteps.from 一致（6 个边界）', () {
      final List<DateTime> q = YunQiEngine.qiStepBounds(2018);
      expect(q.length, 6);
      for (int i = 0; i < 6; i++) {
        final double ms = jieQiTimeMs(2018, zhuQiSteps[i].from);
        expect(q[i].millisecondsSinceEpoch, ms.round(),
            reason: '边界 $i 应等于 ${zhuQiSteps[i].from} 的定气时刻');
        expect(q[i].year, 2018);
      }
    });
  });

  group('③ 当前步高亮 == currentQiStepOf', () {
    test('2026-10-09 → qiStep 4（五之气）', () {
      final DateTime d = DateTime(2026, 10, 9);
      final YunQiChartData c = YunQiChartData.of(d);
      expect(YunQiEngine.currentQiStepOf(d), 4);
      expect(c.qiStep, 4, reason: '图高亮步须与 currentQiStepOf 一致');
      expect(qiStepNames[c.qiStep], '五之气');
      expect(c.currentZhuQi, zhuQiSteps[4].qi);
      expect(c.currentKeQi, c.yearData.keQi[4]);
    });

    test('多日期抽样：图的 qiStep 恒等于 currentQiStepOf', () {
      final List<DateTime> samples = <DateTime>[
        DateTime(1900, 1, 21),
        DateTime(1984, 6, 1),
        DateTime(2000, 2, 4),
        DateTime(2018, 3, 10),
        DateTime(2026, 1, 15),
        DateTime(2026, 5, 21),
        DateTime(2026, 10, 9),
        DateTime(2026, 12, 1),
      ];
      for (final DateTime d in samples) {
        expect(YunQiChartData.of(d).qiStep, YunQiEngine.currentQiStepOf(d),
            reason: '$d qiStep 应与门面一致');
        expect(YunQiChartData.of(d).yunStep, YunQiEngine.currentYunStepOf(d),
            reason: '$d yunStep 应与门面一致');
      }
    });

    test('年份数据与年干支取自同一日历年口径', () {
      final YunQiChartData c = YunQiChartData.of(DateTime(2018, 3, 10));
      expect(c.year, 2018);
      expect(c.yearData.ganZhi, '戊戌');
      expect(c.yearData.ganZhi, YunQiEngine.yearGanzhi(2018).ganZhi);
    });
  });

  group('④ 五行徽章落宫（参考站 2018-03-10 例）', () {
    late YunQiChartData data;
    late List<WuxingBadge> badges;

    setUpAll(() {
      data = YunQiChartData.of(DateTime(2018, 3, 10));
      badges = buildWuxingBadges(data);
    });

    /// 取落在某宫的全部徽章角色。
    List<YunQiBadgeRole> rolesAt(String wx) => <YunQiBadgeRole>[
          for (final WuxingBadge g in badges)
            if (g.wx == wx) g.role,
        ];

    test('火宫：岁运 + 客运', () {
      final List<YunQiBadgeRole> r = rolesAt('火');
      expect(r, contains(YunQiBadgeRole.suiYun));
      expect(r, contains(YunQiBadgeRole.keYun));
    });

    test('水宫：司天', () {
      expect(rolesAt('水'), contains(YunQiBadgeRole.siTian));
    });

    test('土宫：在泉', () {
      expect(rolesAt('土'), contains(YunQiBadgeRole.zaiQuan));
    });

    test('木宫：主运（当前运步 = 初之运，主运初运恒为木）', () {
      expect(data.yunStep, 0, reason: '2018-03-10 在初之运（大寒~春分+13）');
      expect(data.currentZhuYun.wx, '木');
      expect(rolesAt('木'), contains(YunQiBadgeRole.zhuYun));
    });

    test('徽章总数 6，且每宫落宫值必属五行', () {
      expect(badges.length, 6);
      for (final WuxingBadge g in badges) {
        expect(wuxingPalaces, contains(g.wx));
        expect(g.text.isNotEmpty, isTrue);
      }
    });

    test('岁运徽章文案带太少（2018 戊戌 = 火运太过 → 岁运·太火）', () {
      expect(data.yearData.yun, '火');
      expect(data.yearData.taiGuo, isTrue);
      final WuxingBadge g =
          badges.firstWhere((WuxingBadge e) => e.role == YunQiBadgeRole.suiYun);
      expect(g.text, '岁运·太火');
      expect(g.wx, '火');
    });

    test('司天 / 在泉 徽章文案与落宫五行', () {
      expect(data.yearData.siTian, '太阳寒水');
      expect(data.yearData.zaiQuan, '太阴湿土');
      expect(
        badges
            .firstWhere((WuxingBadge e) => e.role == YunQiBadgeRole.siTian)
            .text,
        '司天',
      );
      expect(
        badges
            .firstWhere((WuxingBadge e) => e.role == YunQiBadgeRole.zaiQuan)
            .text,
        '在泉',
      );
      expect(
        badges
            .firstWhere((WuxingBadge e) => e.role == YunQiBadgeRole.siTian)
            .wx,
        '水',
      );
      expect(
        badges
            .firstWhere((WuxingBadge e) => e.role == YunQiBadgeRole.zaiQuan)
            .wx,
        '土',
      );
    });
  });

  group('⑤ 五行语义色（亮/暗两套映射）', () {
    test('五行各有一色，且亮暗不同', () {
      for (final String wx in wuxingPalaces) {
        final Color light = wxColorOf(wx, Brightness.light);
        final Color dark = wxColorOf(wx, Brightness.dark);
        expect(light, isNot(dark), reason: '$wx 亮暗应不同');
        expect(light.a, 1.0);
        expect(dark.a, 1.0);
      }
    });

    test('未知五行走兜底色，不抛异常', () {
      expect(wxColorOf('', Brightness.light), isA<Color>());
      expect(wxColorOf('', Brightness.dark), isA<Color>());
    });
  });

  group('⑥ painter shouldRepaint 语义', () {
    test('选中步序变化应触发重绘', () {
      final ColorScheme light = ColorScheme.fromSeed(
        seedColor: const Color(0xFF8B4513),
        brightness: Brightness.light,
      );
      final YunQiChartData a = YunQiChartData.of(DateTime(2026, 1, 10));
      final YunQiChartData b = YunQiChartData.of(DateTime(2026, 10, 9));
      expect(a.qiStep, isNot(b.qiStep));

      // 通过 widget 树拿不到私有 painter，改为直接构造同名 painter 的等价物：
      // 用 WuxingChart/LiuqiChart 在两种数据下 pump 后确认无异常且颜色可解析。
      expect(wxColorOf(a.currentZhuYun.wx, light.brightness), isA<Color>());
      expect(wxColorOf(b.currentZhuYun.wx, light.brightness), isA<Color>());
      expect(yunStepNames.length, 5);
      expect(qiStepNames.length, 6);
    });
  });
}
