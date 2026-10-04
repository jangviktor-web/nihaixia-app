import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/acupoint_repository.dart';

/// 回归：2 字穴位短名会嵌进普通词组造成误链。
///
/// 实测依据（2026-10-03 全库统计）：2 字候选「子宫」命中 19 处，其中
/// **17 处是解剖语**——「引起子宫收缩」「女人子宫卵巢有肿瘤」「灸百会治子宫下垂」，
/// 全被错误链到经外奇穴「子宫穴」。
/// 而正当引用（"倪师：子宫穴在中极旁开三寸"、"经外奇穴（子宫穴）"）写的是 **3 字**，
/// 会被更长的候选先捕获 → **只排 2 字形态是零代价的精准修法**。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async => AcupointRepository.load());

  test('形态表：只映射「子宫」，且不得收编本名即 2 字的常用穴位', () {
    // 本名就是 2 字的穴位在倪师讲义里有真实引用，改形态会砸掉真链接：
    //   肾关 ——「肾关在小腿内侧、阴陵泉下面两寸…它是董氏奇穴里面的要穴」
    //   肘尖 ——「灸肘尖百壮，瘰疬自消」
    for (final safe in const ['肾关', '肘尖', '三毛', '鱼腰', '安眠', '子宫穴']) {
      expect(AcupointRepository.kShortNameLinkForm.containsKey(safe), isFalse,
          reason: '「$safe」不该进形态表');
    }
    expect(AcupointRepository.kShortNameLinkForm['子宫'], '子宫穴');
  });

  test('allNames 不含 2 字「子宫」（解剖语不再误链）', () {
    expect(AcupointRepository.allNames.contains('子宫'), isFalse);
  });

  test('allNames 仍含 3 字「子宫穴」（正当引用不丢）', () {
    expect(AcupointRepository.allNames.contains('子宫穴'), isTrue,
        reason: '禁 2 字形态的同时必须保住 3 字原名，否则正当引用会失效');
  });

  test('真实用例：「子宫收缩」不再命中，「子宫穴」仍命中', () {
    final names = AcupointRepository.allNames;
    const anatomy = '它能引起子宫收缩，孕妇针了会流产';
    const legit = '子宫穴在中极旁开三寸，妇人病、痛经、不孕皆可用';
    expect(names.any((n) => anatomy.contains(n) && n == '子宫'), isFalse,
        reason: '「子宫收缩」里的 2 字子宫不应再被当穴位');
    expect(names.contains('子宫穴'), isTrue);
    expect(legit.contains('子宫穴'), isTrue);
  });

  test('回归防护：其它 2 字真穴位仍可自动链接', () {
    final names = AcupointRepository.allNames;
    for (final keep in const ['肾关', '肘尖', '三毛', '金津', '鱼腰', '安眠']) {
      expect(names.contains(keep), isTrue, reason: '「$keep」应仍可自动链接');
    }
  });
}
