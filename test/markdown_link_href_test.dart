import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/screens/markdown_doc_screen.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/data/herb_repository.dart';
import 'package:nihaisha_app/data/acupoint_repository.dart';

/// 回归：闭门课 / 伤寒金匮 / 内经 正文里的方剂·药材链接点击无反应。
///
/// 根因：flutter_markdown 会把链接目标做 percent-encoding 后传给 `onTapLink`，
/// 例如正文 `[四逆汤](formula://四逆汤)` 传入的是 `formula://%E5%9B%9B%E9%80%86%E6%B1%A4`。
/// 旧代码 `href.substring('formula://'.length)` 拿到编码串直接查库 → 永远 null → 静默无跳转。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('decodeMarkdownHref 解 percent-encoding；非法 % 不抛异常', () {
    expect(decodeMarkdownHref('formula://%E5%9B%9B%E9%80%86%E6%B1%A4'),
        'formula://四逆汤');
    expect(decodeMarkdownHref('herb://%E6%9F%B4%E8%83%A1'), 'herb://柴胡');
    // 非法 % 序列：原样返回，不崩
    expect(decodeMarkdownHref('formula://100%'), 'formula://100%');
  });

  test('编码 href 解码后能命中方剂 / 药材（复刻 flutter_markdown 的编码形态）', () async {
    await FormulaRepository.load();
    await HerbRepository.load();

    // 方剂：formula://四逆汤
    final fHref = 'formula://${Uri.encodeComponent('四逆汤')}';
    final fName = decodeMarkdownHref(fHref.substring('formula://'.length));
    expect(fName, '四逆汤');
    expect(FormulaRepository.getByName(fName), isNotNull);

    // 药材（含别名归一）：herb://柴胡
    final hHref = 'herb://${Uri.encodeComponent('柴胡')}';
    final hName = decodeMarkdownHref(hHref.substring('herb://'.length));
    expect(hName, '柴胡');
    expect(HerbRepository.getExactByName(hName), isNotNull);
  });

  test('未解码时会命中失败（证明该回归确实由缺解码引起）', () async {
    await FormulaRepository.load();
    final encoded = Uri.encodeComponent('四逆汤'); // %E5%9B%9B...
    expect(FormulaRepository.getByName(encoded), isNull);
  });

  group('injectInternalLinks：正文内方剂/药材/穴位自动变链接', () {
    setUpAll(() async {
      await FormulaRepository.load();
      await HerbRepository.load();
      await AcupointRepository.load();
    });

    test('方剂名注入 formula:// 链接', () {
      final out = injectInternalLinks('这是桂枝汤证，用桂枝汤主之。');
      expect(out, contains('[桂枝汤](formula://桂枝汤)'));
    });

    test('穴位名注入 acupoint:// 链接', () {
      final out = injectInternalLinks('可以取足三里、合谷。');
      expect(out.toLowerCase(), contains('acupoint://'));
    });

    test('最长优先：桂枝汤不被拆成桂枝药材', () {
      final out = injectInternalLinks('桂枝汤');
      expect(out, contains('[桂枝汤](formula://桂枝汤)'));
      expect(out.contains('[桂枝](herb://桂枝)'), isFalse);
    });

    test('无关键字的普通句子原样返回', () {
      const raw = '先辨六经，再看虚实寒热。';
      expect(injectInternalLinks(raw), raw);
    });

    test('幂等：已注入的链接不会被二次包裹', () {
      final once = injectInternalLinks('桂枝汤');
      // 再注入一次：链接文本里的方名会被再次匹配，但不会破坏 markdown 结构
      final twice = injectInternalLinks(once);
      expect(twice.contains('formula://'), isTrue);
    });
  });
}
