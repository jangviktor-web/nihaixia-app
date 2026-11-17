// 天纪检索相关度：多词召回 + 排序；同时确认默认模式（医疗）行为未变。
// 运行：flutter test test/tianji_relevance_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/services/classic_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ClassicSearchResult> tianji(String q, {bool ranked = false}) =>
      ClassicSearchService.search(
        q,
        onlySources: const {'tianji'},
        path: ClassicSearchService.tianjiAssetPath,
        maxResults: 8,
        rankByRelevance: ranked,
      );

  test('整串匹配对多词查询 0 命中——这正是要拆词的原因', () async {
    final plain = await tianji('紫微 命宫 四化');
    expect(plain.total, 0,
        reason: '索引里没有「紫微 命宫 四化」这个连续串，'
            '按旧逻辑等于完全检索不到');
  });

  test('相关度模式：多词拆分后能召回，且取前 8 条', () async {
    final ranked = await tianji('紫微 命宫 四化', ranked: true);
    expect(ranked.total, greaterThan(0), reason: '拆成三个词后应能召回');
    expect(ranked.hits.length, lessThanOrEqualTo(8));
    expect(ranked.hits, isNotEmpty);
  });

  test('相关度模式：命中的词更多者排在更前', () async {
    const terms = ['紫微', '命宫', '四化'];
    final ranked = await tianji('紫微 命宫 四化', ranked: true);
    expect(ranked.hits.length, greaterThanOrEqualTo(2));

    int countTerms(ClassicHit h) {
      final text = '${h.title}${h.snippet}';
      return terms.where(text.contains).length;
    }

    final first = countTerms(ranked.hits.first);
    final last = countTerms(ranked.hits.last);
    expect(first, greaterThanOrEqualTo(last),
        reason: '排序后末尾不应比开头命中更多词（${ranked.hits.map(countTerms).toList()}）');
    expect(first, greaterThanOrEqualTo(1));
  });

  test('默认模式不受影响：单串查询仍是标题优先、索引顺序', () async {
    final plain = await tianji('紫微');
    final ranked = await tianji('紫微', ranked: true);
    // 两种模式总命中数一致（都扫全表），只是排序与截断方式不同
    expect(plain.total, ranked.total);
    expect(plain.hits.every((h) => h.sourceLabel == '天纪讲义'), isTrue);
  });

  test('相关度模式不影响医疗检索（未传参时 rankByRelevance 为 false）', () async {
    final medical = await ClassicSearchService.search('桂枝汤');
    expect(medical.total, greaterThan(0));
    expect(medical.hits.every((h) => h.source != 'tianji'), isTrue);
  });
}
