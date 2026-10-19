import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'package:nihaisha_app/data/meihua_data.dart';
import 'package:nihaisha_app/data/yijing_data.dart';
import 'package:nihaisha_app/screens/meihua_screen.dart';

void main() {
  group('梅花易数 · 时间起卦（已知答案）', () {
    test('子年正月月子时 → 火雷噬嗑，动爻六四，体震用离', () {
      // 年支序1 + 月1 + 日1 = 3 → 上卦离(3)
      // + 时支序1 = 4 → 下卦震(4)；动爻 4%6=4
      final c = computeMeihuaByTime(
        yearZhiIndex: 1,
        lunarMonth: 1,
        lunarDay: 1,
        hourZhiIndex: 1,
      );
      expect(c.main.name, '火雷噬嗑');
      expect(c.main.upper, 2); // 离
      expect(c.main.lower, 3); // 震
      expect(c.movingYao, 4);
      expect(c.ti.name, '震');
      expect(c.yong.name, '离');
      expect(c.mainRelation, TiYongRelation.tiShengYong);
      expect(c.tiWuxing, '木');
      expect(c.yongWuxing, '火');
      expect(c.trace.length, 4);
    });

    test('主互变三卦：噬嗑 → 水山蹇 → 山雷颐', () {
      // 噬嗑六爻（下震上离）= [1,0,0,1,0,1]
      // 互卦取 2-4 爻 [0,0,1]=艮、3-5 爻 [0,1,0]=坎 → 上坎下艮 = 水山蹇
      // 变卦动爻4 阳变阴 → 上艮下震 = 山雷颐
      final c = computeMeihuaByTime(
        yearZhiIndex: 1,
        lunarMonth: 1,
        lunarDay: 1,
        hourZhiIndex: 1,
      );
      expect(c.mutual.name, '水山蹇');
      expect(c.changed.name, '山雷颐');
      // 动爻在下 → 体在下，故下互为体互（艮）、上互为用互（坎）
      expect(c.interTi.name, '艮');
      expect(c.interYong.name, '坎');
      // 变卦仍以动爻位定体用：动爻4 → 上卦为用、下卦为体
      expect(c.changedTi.name, '震');
      expect(c.changedYong.name, '艮');
    });

    test('月建寅木，体卦震木当令为旺', () {
      final c = computeMeihuaByTime(
        yearZhiIndex: 1,
        lunarMonth: 1,
        lunarDay: 1,
        hourZhiIndex: 1,
      );
      expect(c.monthBranch, '寅');
      expect(c.tiWangShuai, WangShuai.wang);
    });

    test('动爻在上卦（四五六爻）时上卦为用、下卦为体', () {
      // 年支序4(卯) + 月1 + 日1 = 6 → 上卦坎(6)；+时支序1 = 7 → 下卦艮(7)；动爻 7%6=1
      // 动爻1 在下卦 → 下卦为用、上卦为体
      final c = computeMeihuaByTime(
        yearZhiIndex: 4,
        lunarMonth: 1,
        lunarDay: 1,
        hourZhiIndex: 1,
      );
      expect(c.movingYao, 1);
      expect(c.ti.name, '坎');
      expect(c.yong.name, '艮');
    });

    test('穷举 12 年支 × 12 时支：互卦变卦恒可匹配', () {
      // 覆盖纯乾/纯坤主卦改取变卦中间四爻的特例分支
      for (var y = 1; y <= 12; y++) {
        for (var h = 1; h <= 12; h++) {
          final c = computeMeihuaByTime(
            yearZhiIndex: y,
            lunarMonth: 1,
            lunarDay: 1,
            hourZhiIndex: h,
          );
          expect(kHexagrams.any((x) => x.name == c.mutual.name), isTrue,
              reason: '年支$y 时支$h 互卦未匹配');
          expect(kHexagrams.any((x) => x.name == c.changed.name), isTrue,
              reason: '年支$y 时支$h 变卦未匹配');
          expect(c.ti.name, isNotEmpty);
          expect(c.movingYaoCi, isNotEmpty);
        }
      }
    });

    test('纯乾特例经数字起卦复现：上乾下乾动爻2 → 互卦天风姤', () {
      // first=1(乾) second=1(乾) → 动爻 (1+1)%6=2
      final c = computeMeihuaByNumber(first: 1, second: 1, lunarMonth: 6);
      expect(c.main.name, '乾为天');
      expect(c.movingYao, 2);
      // 主卦纯乾，改取变卦中间四爻。变卦六爻=[1,0,1,1,1,1]
      // 2-4 爻 [0,1,1]=巽、3-5 爻 [1,1,1]=乾 → 上乾下巽 = 天风姤
      expect(c.mutual.name, '天风姤');
    });
  });

  group('梅花易数 · 数字起卦', () {
    test('3 与 7 → 火山旅，动爻四，体艮用离（用生体）', () {
      final c = computeMeihuaByNumber(first: 3, second: 7, lunarMonth: 6);
      expect(c.main.name, '火山旅');
      expect(c.movingYao, 4);
      expect(c.ti.name, '艮');
      expect(c.yong.name, '离');
      expect(c.mainRelation, TiYongRelation.yongShengTi);
    });

    test('8 与 8 归正：上坤下坤，动爻取 4', () {
      final c = computeMeihuaByNumber(first: 8, second: 8, lunarMonth: 6);
      expect(c.main.name, '坤为地');
      expect(c.movingYao, 4); // (8+8)%6 = 4
    });

    test('非正整数一律抛 ArgumentError', () {
      expect(() => computeMeihuaByNumber(first: 0, second: 7, lunarMonth: 6),
          throwsArgumentError);
      expect(() => computeMeihuaByNumber(first: 3, second: -1, lunarMonth: 6),
          throwsArgumentError);
    });
  });

  group('梅花易数 · 随机起卦', () {
    test('固定种子可复现，且落位恒合法', () {
      final a = computeMeihuaByRandom(lunarMonth: 3, rng: Random(42));
      final b = computeMeihuaByRandom(lunarMonth: 3, rng: Random(42));
      expect(a.main.name, b.main.name);
      expect(a.movingYao, b.movingYao);
      expect(a.ti.name, b.ti.name);

      for (var seed = 0; seed < 50; seed++) {
        final c = computeMeihuaByRandom(lunarMonth: 5, rng: Random(seed));
        expect(c.movingYao, inInclusiveRange(1, 6));
        expect(c.main.upper, inInclusiveRange(0, 7));
        expect(c.main.lower, inInclusiveRange(0, 7));
        expect(c.movingYaoCi, isNotEmpty);
      }
    });
  });

  group('梅花易数 · 体用关系与旺衰', () {
    test('五关系判定正确', () {
      expect(tiYongRelation('木', '木'), TiYongRelation.biHe);
      expect(tiYongRelation('木', '土'), TiYongRelation.tiKeYong);
      expect(tiYongRelation('木', '金'), TiYongRelation.yongKeTi);
      expect(tiYongRelation('木', '火'), TiYongRelation.tiShengYong);
      expect(tiYongRelation('木', '水'), TiYongRelation.yongShengTi);
    });

    test('旺相休囚死五态判定正确', () {
      // 基准：月建寅（木）
      expect(wangShuaiOf('木', '木'), WangShuai.wang); // 当令
      expect(wangShuaiOf('火', '木'), WangShuai.xiang); // 木生火
      expect(wangShuaiOf('水', '木'), WangShuai.xiu); // 水生木
      expect(wangShuaiOf('金', '木'), WangShuai.qiu); // 金克木（我克月令）
      expect(wangShuaiOf('土', '木'), WangShuai.si); // 木克土（月令克我）
    });

    test('八卦五行按先天数正确', () {
      expect(wuxingOfXiantian(1), '金'); // 乾
      expect(wuxingOfXiantian(2), '金'); // 兑
      expect(wuxingOfXiantian(3), '火'); // 离
      expect(wuxingOfXiantian(4), '木'); // 震
      expect(wuxingOfXiantian(5), '木'); // 巽
      expect(wuxingOfXiantian(6), '水'); // 坎
      expect(wuxingOfXiantian(7), '土'); // 艮
      expect(wuxingOfXiantian(8), '土'); // 坤
    });

    test('月建地支序：正月寅 … 十一月子 十二月丑', () {
      expect(monthBranchIndexOfLunarMonth(1), 3); // 寅
      expect(monthBranchIndexOfLunarMonth(6), 8); // 未
      expect(monthBranchIndexOfLunarMonth(11), 1); // 子
      expect(monthBranchIndexOfLunarMonth(12), 2); // 丑
    });
  });

  group('梅花易数 · 数据复用完整性', () {
    test('八卦类象 8 条且与 kTrigrams 同名同序', () {
      expect(kTrigramXiang.length, 8);
      for (var i = 0; i < 8; i++) {
        expect(kTrigramXiang[i].name, kTrigrams[i].name);
        expect(kTrigramXiang[i].wuxing, wuxingOfXiantian(kTrigrams[i].xiantian));
      }
    });

    test('三阶段推演三段齐备且各带断语', () {
      final c = computeMeihuaByNumber(first: 3, second: 7, lunarMonth: 6);
      expect(c.stages.length, 3);
      expect(c.stages.map((s) => s.name).toList(), ['主卦', '互卦', '变卦']);
      for (final s in c.stages) {
        expect(s.hexName, isNotEmpty);
        expect(s.detail, contains('为体'));
        expect(s.detail, contains(s.relation.label));
      }
      // 断语含《体用总诀》原句
      expect(c.verdict, contains(c.mainRelation.verdict));
    });

    test('动爻爻辞取自主卦六爻且非空', () {
      final c = computeMeihuaByNumber(first: 3, second: 7, lunarMonth: 6);
      expect(c.movingYaoCi, c.main.lines[c.movingYao - 1]);
    });
  });

  group('梅花易数 · 页面冒烟', () {
    // ponytail: 视口设高让 ListView 一次全 build，免得跟 scrollUntilVisible 的多匹配较劲。
    void useTallSurface(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    testWidgets('默认时间起卦渲染：主卦/体用/三阶段/取象/推算', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(const MaterialApp(home: MeihuaScreen()));
      await tester.pumpAndSettle();
      expect(find.text('梅花易数'), findsOneWidget);
      expect(find.text('体用生克'), findsOneWidget);
      expect(find.text('三阶段推演（主 → 互 → 变）'), findsOneWidget);
      expect(find.text('八卦取象'), findsOneWidget);
      expect(find.text('推算过程'), findsOneWidget);
      expect(find.textContaining('卦辞'), findsWidgets);
      expect(find.textContaining('动爻爻辞（第'), findsOneWidget);
      // 默认已算出主卦名（非空）
      expect(find.byType(Card), findsWidgets);
    });

    testWidgets('切到数字起卦并改数，结果随之更新', (tester) async {
      useTallSurface(tester);
      await tester.pumpWidget(const MaterialApp(home: MeihuaScreen()));
      await tester.tap(find.text('数字'));
      await tester.pumpAndSettle();
      // 默认 3 / 7 → 火山旅
      expect(find.text('火山旅'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, '8');
      await tester.enterText(find.byType(TextField).last, '8');
      await tester.pumpAndSettle();
      // 8 / 8 → 上坤下坤，动爻 (8+8)%6=4 → 坤为地
      expect(find.text('坤为地'), findsOneWidget);
    });
  });

  group('梅花易数 · 摇一摇起卦', () {
    // ponytail: 同上部，视口设高让 ListView 一次全 build。
    void useTallSurface(WidgetTester tester) {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    // 假加速度源：注入 broadcast 流，测试里手动灌事件驱动摇一摇。
    Stream<AccelerometerEvent> fakeAccel(StreamController<AccelerometerEvent> c) =>
        c.stream;

    // 一次摇动脉冲：先静止，再两个连续高采样，最后回落静止。
    void shake(StreamController<AccelerometerEvent> c) {
      c.add(AccelerometerEvent(0, 9.8, 0, DateTime.now()));
      c.add(AccelerometerEvent(0, 14.0, 0, DateTime.now()));
      c.add(AccelerometerEvent(0, 14.2, 0, DateTime.now()));
      c.add(AccelerometerEvent(0, 9.8, 0, DateTime.now()));
    }

    testWidgets('摇一摇 → 自动切随机起卦并重摇一卦', (tester) async {
      useTallSurface(tester);
      final acc = StreamController<AccelerometerEvent>.broadcast(sync: true);
      addTearDown(acc.close);
      await tester.pumpWidget(MaterialApp(
        home: MeihuaScreen(
          accelSource: ({Duration samplingPeriod = const Duration(milliseconds: 20)}) =>
              fakeAccel(acc),
        ),
      ));
      await tester.pumpAndSettle();

      // 默认时间起卦：chip 是「时间起卦」，随机按钮不在树上
      expect(find.text('时间起卦'), findsOneWidget);
      expect(find.text('随机起卦'), findsNothing);

      shake(acc);
      await tester.pumpAndSettle();

      // 方法切到随机：chip + 随机按钮都在（两处同文案）
      expect(find.text('随机起卦'), findsNWidgets(2));
      expect(find.text('时间起卦'), findsNothing);
    });

    testWidgets('摇一摇开关默认开；关掉后摇动不再触发', (tester) async {
      useTallSurface(tester);
      final acc = StreamController<AccelerometerEvent>.broadcast(sync: true);
      addTearDown(acc.close);
      await tester.pumpWidget(MaterialApp(
        home: MeihuaScreen(
          accelSource: ({Duration samplingPeriod = const Duration(milliseconds: 20)}) =>
              fakeAccel(acc),
        ),
      ));
      await tester.pumpAndSettle();

      final sw = find.byType(SwitchListTile);
      expect(sw, findsOneWidget);
      expect(tester.widget<SwitchListTile>(sw).value, isTrue);

      await tester.tap(sw);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(sw).value, isFalse);

      shake(acc);
      await tester.pumpAndSettle();

      // 仍是时间起卦，没被摇动改写
      expect(find.text('时间起卦'), findsOneWidget);
      expect(find.text('随机起卦'), findsNothing);
    });

    testWidgets('连续两次摇动（中间有回落）→ 出两卦', (tester) async {
      useTallSurface(tester);
      final acc = StreamController<AccelerometerEvent>.broadcast(sync: true);
      addTearDown(acc.close);
      await tester.pumpWidget(MaterialApp(
        home: MeihuaScreen(
          accelSource: ({Duration samplingPeriod = const Duration(milliseconds: 20)}) =>
              fakeAccel(acc),
        ),
      ));
      await tester.pumpAndSettle();

      shake(acc);
      await tester.pumpAndSettle();
      expect(find.text('随机起卦'), findsNWidgets(2));

      // 第二次摇动：重新武装后再触发（防连发由 ShakeDetector 单测覆盖）
      shake(acc);
      await tester.pumpAndSettle();
      expect(find.text('随机起卦'), findsNWidgets(2));
      // 页面不崩、结果区仍在
      expect(find.text('体用生克'), findsOneWidget);
    });
  });
}
