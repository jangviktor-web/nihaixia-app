import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/screens/daily_almanac_screen.dart';

/// 纯函数 [resolveSwipe] 单测：上/下/左/右判定 + 微小抖动返回 null。
void main() {
  group('resolveSwipe', () {
    test('左滑 → 下个月 (monthNext)', () {
      // 横向占优且 dx<0
      expect(resolveSwipe(-800, 50), SwipeDir.monthNext);
    });

    test('右滑 → 上个月 (monthPrev)', () {
      expect(resolveSwipe(800, 50), SwipeDir.monthPrev);
    });

    test('上滑（纵向向上，dy<0 超阈值）→ 下一天 (dayNext)', () {
      // 纵向占优且 dy 绝对值 > 40
      expect(resolveSwipe(30, -900), SwipeDir.dayNext);
    });

    test('下滑（纵向向下，dy>0 超阈值）→ 上一天 (dayPrev)', () {
      expect(resolveSwipe(30, 900), SwipeDir.dayPrev);
    });

    test('纵向未超阈值（轻微抖动）→ null', () {
      expect(resolveSwipe(5, 20), isNull);
    });

    test('横向极弱、纵向极弱 → null', () {
      expect(resolveSwipe(10, 10), isNull);
    });

    test('横向略占优但位移很小 → 仍判定切月（横向优先）', () {
      // dx.abs() > dy.abs() 走切月分支，不要求阈值
      expect(resolveSwipe(-60, 40), SwipeDir.monthNext);
      expect(resolveSwipe(60, 40), SwipeDir.monthPrev);
    });
  });
}
