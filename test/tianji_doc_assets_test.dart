import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/screens/tianji_doc_list_screen.dart';
import 'package:nihaisha_app/services/classic_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('天纪讲义：列表里的每个资产都能加载，且无残留图片引用', () async {
    expect(TianjiDocListScreen.docs, isNotEmpty);
    for (final (_, title, _, asset) in TianjiDocListScreen.docs) {
      final text = await rootBundle.loadString(asset);
      expect(text.trim(), isNotEmpty, reason: '$title（$asset）内容为空');
      expect(text.contains('!['), isFalse, reason: '$title（$asset）残留图片引用');
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
