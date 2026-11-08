// 经典全文检索回归：讲稿 + 古籍原文统一索引。
// 运行：flutter test test/classic_search_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/services/classic_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('空查询返回空结果，不触发索引加载', () async {
    final r = await ClassicSearchService.search('   ');
    expect(r.total, 0);
    expect(r.hits, isEmpty);
  });

  test('索引可加载，条目数覆盖讲稿 906 + 古籍 421', () async {
    await ClassicSearchService.ensureLoaded();
    expect(ClassicSearchService.isLoaded, isTrue);

    // 用三个高覆盖词分别验证三类来源都能命中
    final guiZhi = await ClassicSearchService.search('桂枝汤');
    expect(guiZhi.total, greaterThan(0));
    expect(guiZhi.hits.any((h) => h.source == 'shanghan'), isTrue,
        reason: '伤寒讲稿应能搜到桂枝汤');

    final biaoYou = await ClassicSearchService.search('标幽赋');
    expect(biaoYou.total, greaterThan(0));
    expect(biaoYou.hits.any((h) => h.bookId == 'zhenjiudacheng'), isTrue,
        reason: '针灸大成卷二应有「标幽赋」');

    final lingshu = await ClassicSearchService.search('九针');
    expect(lingshu.total, greaterThan(0));
    expect(lingshu.hits.any((h) => h.bookId == 'lingshu'), isTrue,
        reason: '灵枢应能搜到九针相关章节');
  });

  test('回归：讲稿勘误后全文索引已重建（大黄蛰虫丸 → 金匮 clause_111）', () async {
    // 2026-11-08：clause_111.md 讲解句「大黄虫丸主之」勘误为「大黄蛰虫丸主之」。
    // classic_index.json.gz 是预生成索引，讲稿改动后忘了重跑 build_classic_search_index.py
    // 就会让 App 仍搜到旧文本。此断言把该流程约束钉死。
    final r = await ClassicSearchService.search('大黄蛰虫丸');
    expect(r.hits.any((h) => h.asset == 'assets/jingui/clause_111.md'), isTrue,
        reason: '勘误后的金匮条文应已写入预生成全文索引');
  });

  test('命中带来源标签与摘要，标题命中排在正文命中之前', () async {
    final r = await ClassicSearchService.search('上古天真论');
    expect(r.hits, isNotEmpty);
    expect(r.hits.first.title.contains('上古天真论'), isTrue);
    expect(r.hits.first.sourceLabel.isNotEmpty, isTrue);
    expect(r.hits.first.snippet.isNotEmpty, isTrue);
  });

  test('展示条数封顶 40，但总数照实统计', () async {
    final r = await ClassicSearchService.search('太阳');
    expect(r.hits.length, lessThanOrEqualTo(ClassicSearchService.maxHits));
    expect(r.total, greaterThanOrEqualTo(r.hits.length));
  });

  // ── 阅读库列表搜索回归（2026-11-05 建）──
  // 列表原先只匹配 ClassicLecture.name，而伤寒 395 条里仅 5 条 name 含
  // 「条文N」，于是搜不到；改为同时命中讲稿索引的标题+正文。
  // 切换 shanghan_unified 后编号统一为宋本条号，讲稿号体系整体废弃，
  // 不再为旧编号保留孤例对照注（YAGNI）。
  group('matchAssets（列表筛选用，不截断）', () {
    test('繁体输入可命中（繁简归一）', () async {
      final r = await ClassicSearchService.matchAssets('傷寒');
      expect(r, contains('assets/shanghan/clause_176.md'));
    });

    test('不套 40 条截断，否则列表会丢结果', () async {
      final r = await ClassicSearchService.matchAssets('太阳');
      expect(r.length, greaterThan(ClassicSearchService.maxHits));
    });

    test('空查询返回空集合', () async {
      final r = await ClassicSearchService.matchAssets('   ');
      expect(r, isEmpty);
    });
  });
}
