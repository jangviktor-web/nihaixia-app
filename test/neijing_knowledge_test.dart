import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/neijing_data.dart';
import 'package:nihaisha_app/screens/neijing_knowledge_screen.dart';

/// 《人纪·黄帝内经》知识卡：数据完整性 + 页面冒烟。
void main() {
  group('脏象卡数据完整性', () {
    test('十二脏象齐全（五脏六腑 + 膻中）', () {
      expect(kZangFuCards.length, 12);
      final names = kZangFuCards.map((c) => c.name).toList();
      expect(names, containsAll(['心', '肺', '肝', '肾', '脾', '胃', '胆',
        '小肠', '大肠', '膀胱', '三焦', '膻中（心包）']));
      // 每个官职非空
      for (final c in kZangFuCards) {
        expect(c.zhiGuan, isNotEmpty, reason: c.name);
        expect(c.func, isNotEmpty, reason: c.name);
        expect(c.niShi, isNotEmpty, reason: c.name);
        expect(c.source, isNotEmpty, reason: c.name);
      }
      // 五脏（心肝脾肺肾）应含华充窍五行情志
      for (final c in kZangFuCards.take(5)) {
        expect(c.wuXing, isNotEmpty, reason: c.name);
        expect(c.qingZhi, isNotEmpty, reason: c.name);
        expect(c.shengKe, isNotEmpty, reason: c.name);
      }
    });

    test('五色望诊 5 条 + 眼诊 5 区 + 脉诊完整', () {
      expect(kWangZhenColors.length, 5);
      expect(kEyeDiag.length, 5);
      expect(kMaiZhenCommon.length, 8);
      expect(kDeadPulses.length, 5);
      expect(kPingRenMai, contains('脉五动'));
      expect(kMaiYinYang, contains('寸部为阳'));
    });
  });

  group('内经速查页冒烟', () {
    testWidgets('三 Tab 可切换且内容渲染', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: NeijingKnowledgeScreen()),
      );
      await tester.pumpAndSettle();

      // 脏象 Tab 默认可见
      expect(find.text('黄帝内经 · 速查'), findsOneWidget);
      expect(find.text('君主之官'), findsOneWidget);

      // 切到望诊
      await tester.tap(find.text('望诊'));
      await tester.pumpAndSettle();
      expect(find.text('五色 · 正常与病色'), findsOneWidget);
      // 眼诊区在 ListView 下方，滚动到可见
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(find.text('眼诊 · 观眼辨五脏（倪师）'), findsOneWidget);

      // 切到脉诊
      await tester.tap(find.text('脉诊'));
      await tester.pumpAndSettle();
      expect(find.text('平人脉标准'), findsOneWidget);
      // 脉诊内容较长，循环滚动至死脉区
      for (var i = 0; i < 8; i++) {
        if (tester.any(find.text('死脉警示（临证当慎）'))) break;
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(find.text('死脉警示（临证当慎）'), findsOneWidget);
    });
  });
}
