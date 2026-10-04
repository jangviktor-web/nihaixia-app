import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/acupoint_repository.dart';

/// 回归：同长度穴名的并列次序必须**确定**，不能依赖 `getAll()` 的插入顺序。
///
/// 背景：`AcupointRepository.allNames` 与 `acupoint_rich_text._buildSpans` 的候选表
/// 原本都只按长度排序，而 Dart `List.sort` **不保证稳定** → 并列项先后退化成插入顺序。
/// 穴位列表一旦改成「按经络重排」，贪心扫描就会选错穴位：
/// 实测 3 字的督脉`腰阳关`被同为 3 字的胆经`阳关穴`抢先占位，链错了。
///
/// 修法：两个比较器都补「名称字典序」次键。下面的不变式就是这道防线的守卫。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => AcupointRepository.load());

  test('allNames：同长度分组内严格按名称升序（次键真的生效）', () {
    final names = AcupointRepository.allNames;
    expect(names.length, 408, reason: '排序不应丢条目');
    var checked = 0;
    for (var i = 1; i < names.length; i++) {
      final prev = names[i - 1], cur = names[i];
      if (prev.length != cur.length) continue; // 跨长度比较由主键决定，不归这条管
      checked++;
      expect(prev.compareTo(cur), lessThan(0),
          reason: '同为 ${prev.length} 字的「$prev」「$cur」未按名称升序 → 仍依赖插入顺序');
    }
    expect(checked, greaterThan(0), reason: '样本为空，断言没意义');
  });

  test('allNames：仍是长度降序（主键没被改坏）', () {
    final names = AcupointRepository.allNames;
    for (var i = 1; i < names.length; i++) {
      expect(names[i - 1].length, greaterThanOrEqualTo(names[i].length));
    }
  });

  test('同长度并列：督脉腰阳关 先于 胆经阳关穴（否则会误链到胆经阳关穴）', () {
    // 与 acupoint_rich_text._buildSpans 同构的候选表（含「穴」后缀与去后缀两种形态）
    final all = AcupointRepository.getAll();
    final cands = <String>[
      for (final a in all) a.name,
      for (final a in all) a.name.replaceAll('穴', ''),
    ]
      ..removeWhere((n) => n.length < 2)
      ..sort((a, b) {
        final byLen = b.length.compareTo(a.length);
        return byLen != 0 ? byLen : a.compareTo(b);
      });

    final iYao = cands.indexOf('腰阳关'); // 督脉
    final iYang = cands.indexOf('阳关穴'); // 足少阳胆经
    expect(iYao, isNonNegative, reason: '候选表应含督脉腰阳关');
    expect(iYang, isNonNegative, reason: '候选表应含胆经阳关穴');
    expect(iYao, lessThan(iYang),
        reason: '腰(U+8170) < 阳(U+9633)，腰阳关必须先占位');
  });

  test('穴位数据前提没被排序改动破坏：跨经同名 = 0', () {
    final byName = <String, String>{};
    for (final a in AcupointRepository.getAll()) {
      expect(byName.containsKey(a.name), isFalse, reason: '「${a.name}」跨经重复');
      byName[a.name] = a.meridian;
    }
    expect(byName.length, 408);
  });
}
