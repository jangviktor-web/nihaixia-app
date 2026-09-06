import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/screens/daily_almanac_screen.dart';

/// 纯函数 [resolveSwipe] 单测：只认横向手势切日，纵向手势留给列表滚动。
void main() {
  group('resolveSwipe', () {
    test('左滑（dx<0）→ 前一天 (dayPrev)', () {
      expect(resolveSwipe(-800, 50), SwipeDir.dayPrev);
    });

    test('右滑（dx>0）→ 后一天 (dayNext)', () {
      expect(resolveSwipe(800, 50), SwipeDir.dayNext);
    });

    test('纯左滑 / 纯右滑（dy 为 0）同样生效', () {
      expect(resolveSwipe(-500, 0), SwipeDir.dayPrev);
      expect(resolveSwipe(500, 0), SwipeDir.dayNext);
    });

    test('横向位移过弱（抖动，|dx| 未超过 40）→ null', () {
      expect(resolveSwipe(5, 20), isNull);
      expect(resolveSwipe(-10, 0), isNull);
      expect(resolveSwipe(40, 0), isNull); // 阈值取严格大于 40
    });

    test('横向极弱、纵向极弱 → null', () {
      expect(resolveSwipe(10, 10), isNull);
    });

    test('纵向手势（上滑 / 下滑）一律不触发切日 → null', () {
      expect(resolveSwipe(30, -900), isNull);
      expect(resolveSwipe(-30, -900), isNull);
      expect(resolveSwipe(30, 900), isNull);
      expect(resolveSwipe(-30, 900), isNull);
    });

    test('斜向但纵向占优 → null（判给列表滚动，不误触切日）', () {
      expect(resolveSwipe(300, -900), isNull);
      expect(resolveSwipe(-300, 900), isNull);
      expect(resolveSwipe(500, 500), isNull); // 完全对角，纵向不小于横向
    });

    test('斜向但横向明显占优 → 仍可切日', () {
      expect(resolveSwipe(-800, 120), SwipeDir.dayPrev);
      expect(resolveSwipe(800, -120), SwipeDir.dayNext);
    });

    test('取值为 0 的速度（无手势）→ null', () {
      expect(resolveSwipe(0, 0), isNull);
    });
  });
}
