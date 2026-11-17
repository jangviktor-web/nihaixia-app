import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/screens/tianji_doc_list_screen.dart';
import 'package:nihaisha_app/services/classic_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('天纪讲义：列表里的每个资产都能加载，图片引用必须可达', () async {
    expect(TianjiDocListScreen.docs, isNotEmpty);
    for (final (_, title, _, asset) in TianjiDocListScreen.docs) {
      final text = await rootBundle.loadString(asset);
      expect(text.trim(), isNotEmpty, reason: '$title（$asset）内容为空');
      // 早年间讲义里的图片引用全是被剔除的死链（板书照片），所以曾断言
      // 「不允许出现 !['」。现在有真实盘面图（assets/tianji/images/），
      // 规则升级为：出现的每一条图片引用都必须指向打包进 App 的真实资产。
      for (final m
          in RegExp(r'!\[[^\]]*\]\(([^)]+)\)').allMatches(text)) {
        final src = Uri.decodeComponent(m.group(1)!);
        try {
          await rootBundle.load(src);
        } catch (_) {
          fail('$title（$asset）引用的图片不存在：$src');
        }
      }
    }
  });

  test('天纪索引：关键词可命中，来源标签正确，且不影响医疗索引', () async {
    final r = await ClassicSearchService.search(
      '紫微星',
      onlySources: const {'tianji'},
      path: ClassicSearchService.tianjiAssetPath,
    );
    expect(r.total, greaterThan(0), reason: '「紫微星」应命中午夜字幕');
    expect(r.hits.first.sourceLabel, '天纪讲义');
    // 天纪条目无可打开的资产（lecture/*.md 不打包）
    expect(r.hits.every((h) => h.asset == null), isTrue);

    // 医疗索引仍独立：加载后 isLoaded 只反映默认库
    await ClassicSearchService.ensureLoaded();
    expect(ClassicSearchService.isLoaded, isTrue);
    final medical = await ClassicSearchService.search('桂枝汤');
    expect(medical.hits.every((h) => h.source != 'tianji'), isTrue,
        reason: '医疗检索不得命中天纪源');
  });
}
