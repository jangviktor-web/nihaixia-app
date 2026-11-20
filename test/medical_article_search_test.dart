// 医案文章体全文检索：诊疗日志里的四诊细节能被搜到。
// 运行：flutter test test/medical_article_search_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/services/classic_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ClassicSearchResult> search(String q) => ClassicSearchService.search(
        q,
        onlySources: const {'yianwen'},
        path: ClassicSearchService.medicalArticleAssetPath,
        maxResults: 8,
      );

  test('文章体索引能命中四诊细节（镜面舌 / 一息三至）', () async {
    final r = await search('镜面舌');
    expect(r.total, greaterThan(0), reason: '中风案例段落应有「镜面舌」');
    expect(r.hits.first.sourceLabel, '医案文章');
    expect(r.hits.first.snippet, contains('舌'));

    final pulse = await search('一息三至');
    expect(pulse.total, greaterThan(0), reason: '同段应有脉象描述');
  });

  test('文章体索引不污染医疗讲稿库', () async {
    // 默认路径不含 yianwen 条目
    final r = await ClassicSearchService.search('镜面舌');
    expect(r.hits.where((h) => h.source == 'yianwen'), isEmpty);
  });
}
