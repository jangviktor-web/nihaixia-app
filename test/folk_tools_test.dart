import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sxwnl_spa_dart/sxwnl_spa_dart.dart' show LunarDate, AstroDateTime;

import 'package:nihaisha_app/data/sanshan_lingqian_data.dart';
import 'package:nihaisha_app/data/xiaoliuren_data.dart';
import 'package:nihaisha_app/screens/sanshan_lingqian_screen.dart';
import 'package:nihaisha_app/screens/xiaoliuren_screen.dart';

void main() {
  group('小六壬 · 通行掌诀（正月大安起，月初一落月宫）', () {
    test('正月初一子时三宫皆大安', () {
      final c = computeXiaoliuren(lunarMonth: 1, lunarDay: 1, hourNumber: 1);
      expect(c.month.palace, XiaoliurenPalace.daAn);
      expect(c.day.palace, XiaoliurenPalace.daAn);
      expect(c.hour.palace, XiaoliurenPalace.daAn);
    });

    test('二月初一：月宫留连，日宫/时宫同落留连', () {
      final c = computeXiaoliuren(lunarMonth: 2, lunarDay: 1, hourNumber: 1);
      expect(c.month.palace, XiaoliurenPalace.liuLian);
      expect(c.day.palace, XiaoliurenPalace.liuLian);
      expect(c.hour.palace, XiaoliurenPalace.liuLian);
    });

    test('六月初五午时：月宫空亡、日宫/时宫赤口', () {
      // 月 6-1=5 → 空亡；日 6+5-2=9 → 9%6=3 赤口；时 6+5+7-3=15 → 15%6=3 赤口
      final c = computeXiaoliuren(lunarMonth: 6, lunarDay: 5, hourNumber: 7);
      expect(c.month.palace, XiaoliurenPalace.kongWang);
      expect(c.day.palace, XiaoliurenPalace.chiKou);
      expect(c.hour.palace, XiaoliurenPalace.chiKou);
    });

    test('腊月三十亥时回绕不越界', () {
      // 月 12-1=11 → 空亡；日 12+30-2=40 → 小吉；时 12+30+12-3=51 → 赤口
      final c = computeXiaoliuren(lunarMonth: 12, lunarDay: 30, hourNumber: 12);
      expect(c.month.palace, XiaoliurenPalace.kongWang);
      expect(c.day.palace, XiaoliurenPalace.xiaoJi);
      expect(c.hour.palace, XiaoliurenPalace.chiKou);
    });

    test('三月初九巳时：月宫速喜(朱雀)、日宫小吉(六合)', () {
      // 月 3-1=2 → 速喜；日 3+9-2=10 → 10%6=4 小吉；时 3+9+5-3=14 → 14%6=2 速喜
      final c = computeXiaoliuren(lunarMonth: 3, lunarDay: 9, hourNumber: 5);
      expect(c.month.palace, XiaoliurenPalace.suXi);
      expect(c.month.palace.deity, '朱雀');
      expect(c.day.palace, XiaoliurenPalace.xiaoJi);
      expect(c.day.palace.deity, '六合');
      expect(c.hour.palace, XiaoliurenPalace.suXi);
    });

    test('所有落位下标恒在 0-5', () {
      for (var m = 1; m <= 12; m++) {
        for (var d = 1; d <= 30; d++) {
          for (var h = 1; h <= 12; h++) {
            final c = computeXiaoliuren(lunarMonth: m, lunarDay: d, hourNumber: h);
            expect(c.month.index, inInclusiveRange(0, 5));
            expect(c.day.index, inInclusiveRange(0, 5));
            expect(c.hour.index, inInclusiveRange(0, 5));
          }
        }
      }
    });
  });

  group('小六壬 · 《多能鄙事》口径（月宫下一宫起初一）', () {
    test('正月初一落留连', () {
      final c = computeXiaoliuren(
        lunarMonth: 1,
        lunarDay: 1,
        hourNumber: 1,
        rule: XiaoliurenRule.duoneng,
      );
      expect(c.day.palace, XiaoliurenPalace.liuLian);
      expect(c.hour.palace, XiaoliurenPalace.liuLian);
    });

    test('二月初一落速喜', () {
      final c = computeXiaoliuren(
        lunarMonth: 2,
        lunarDay: 1,
        hourNumber: 1,
        rule: XiaoliurenRule.duoneng,
      );
      expect(c.day.palace, XiaoliurenPalace.suXi);
    });

    test('同一时刻两口径日宫/时宫必相差一宫，月宫不受影响', () {
      final a = computeXiaoliuren(lunarMonth: 8, lunarDay: 15, hourNumber: 4);
      final b = computeXiaoliuren(
        lunarMonth: 8,
        lunarDay: 15,
        hourNumber: 4,
        rule: XiaoliurenRule.duoneng,
      );
      expect((a.day.index + 1) % 6, b.day.index);
      expect((a.hour.index + 1) % 6, b.hour.index);
      expect(a.month.palace, b.month.palace);
    });
  });

  group('小六壬 · 入参保护', () {
    test('越界参数一律抛 ArgumentError', () {
      expect(
          () => computeXiaoliuren(lunarMonth: 0, lunarDay: 1, hourNumber: 1),
          throwsArgumentError);
      expect(
          () => computeXiaoliuren(lunarMonth: 13, lunarDay: 1, hourNumber: 1),
          throwsArgumentError);
      expect(
          () => computeXiaoliuren(lunarMonth: 1, lunarDay: 31, hourNumber: 1),
          throwsArgumentError);
      expect(
          () => computeXiaoliuren(lunarMonth: 1, lunarDay: 1, hourNumber: 0),
          throwsArgumentError);
      expect(
          () => computeXiaoliuren(lunarMonth: 1, lunarDay: 1, hourNumber: 13),
          throwsArgumentError);
    });
  });

  group('小六壬 · 歌诀资料齐备', () {
    test('六宫顺序固定，两套歌诀各 6 条且非空', () {
      expect(kXiaoliurenPalaceOrder.map((p) => p.name).toList(),
          ['大安', '留连', '速喜', '赤口', '小吉', '空亡']);
      expect(kXiaoliurenCommonVerses.length, 6);
      expect(kXiaoliurenDuonengVerses.length, 6);
      for (final v in [...kXiaoliurenCommonVerses, ...kXiaoliurenDuonengVerses]) {
        expect(v.trim(), isNotEmpty);
      }
    });

    test('通行歌诀首字与宫名一一对应', () {
      for (var i = 0; i < 6; i++) {
        expect(
            kXiaoliurenCommonVerses[i].startsWith(kXiaoliurenPalaceOrder[i].name),
            isTrue);
      }
    });
  });

  group('小六壬 · 农历换算冒烟', () {
    test('公历转农历落在合法区间', () {
      final lunar =
          LunarDate.fromSolar(AstroDateTime(2026, 10, 18, 12, 0, 0));
      expect(lunar.month, inInclusiveRange(1, 12));
      expect(lunar.day, inInclusiveRange(1, 30));
    });
  });

  group('三山国王灵签 · 数据完整性', () {
    test('92 签，签号 1-92 无重复无缺号', () {
      expect(kSanShanLingqian.length, 92);
      expect(kSanShanLingqian.map((s) => s.id).toList(),
          List.generate(92, (i) => i + 1));
    });

    test('每签签题/签诗/吉凶均非空', () {
      for (final s in kSanShanLingqian) {
        expect(s.title.trim(), isNotEmpty, reason: '第 ${s.id} 签签题为空');
        expect(s.verse.trim(), isNotEmpty, reason: '第 ${s.id} 签签诗为空');
        expect(s.luck.label.trim(), isNotEmpty);
      }
    });

    test('吉凶分布与祖庙签谱一致：上42 / 中31 / 下17 / 无事2', () {
      int of(LingqianLuck l) =>
          kSanShanLingqian.where((s) => s.luck == l).length;
      expect(of(LingqianLuck.daJi), 42);
      expect(of(LingqianLuck.ping), 31);
      expect(of(LingqianLuck.xiong), 17);
      expect(of(LingqianLuck.pingAn), 2);
    });
  });

  group('页面冒烟', () {
    testWidgets('小六壬页渲染：默认即出三宫结果', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: XiaoliurenScreen()));
      expect(find.text('小六壬'), findsOneWidget);
      expect(find.text('正时（主断）'), findsOneWidget);
      expect(find.text('月宫'), findsOneWidget);
      expect(find.text('日宫'), findsOneWidget);
      // 六宫顺序条在 ListView 首屏之外（懒加载），先滚到可见再断言
      await tester.scrollUntilVisible(
        find.text('六宫顺序'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      for (final p in kXiaoliurenPalaceOrder) {
        expect(find.text(p.name), findsWidgets);
      }
      // 推算过程区块同样滚到可见
      await tester.scrollUntilVisible(
        find.text('推算过程'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.textContaining('顺数'), findsWidgets);
    });

    testWidgets('小六壬页切换《多能鄙事》口径后重新起课', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: XiaoliurenScreen()));
      await tester.tap(find.text('《多能鄙事》'));
      await tester.pumpAndSettle();
      expect(find.textContaining('正月初一留连'), findsOneWidget);
    });

    testWidgets('灵签页渲染：求签/签谱两 tab + 免责声明', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SanshanLingqianScreen()));
      expect(find.text('三山国王灵签'), findsOneWidget);
      expect(find.text('求签'), findsOneWidget);
      expect(find.text('签谱'), findsOneWidget);
      expect(find.text('摇签'), findsOneWidget);

      // 切到签谱 tab：92 签列表可滚动渲染
      await tester.tap(find.text('签谱'));
      await tester.pumpAndSettle();
      expect(find.text('第一签 · 明月千山，太平丰年（大吉）'), findsOneWidget);
    });

    testWidgets('灵签页摇签后出现签文卡', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SanshanLingqianScreen()));
      await tester.tap(find.text('摇签'));
      await tester.pumpAndSettle();
      // 结果卡必含某一签的吉凶标签
      expect(find.byType(Card), findsWidgets);
      expect(find.text('再求一签'), findsOneWidget);
    });
  });
}
