import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/services/classic_search_service.dart';
import 'package:nihaisha_app/services/llm_service.dart';

void main() {
  const seed = ClassicHit(
    source: 'ziwei',
    sourceLabel: '紫微命盘（本地排盘结果）',
    title: '本盘十二宫与四化',
    snippet: '八字四柱：甲子 乙丑 丙寅 丁卯\n· 命宫（甲子）[命宫]紫微',
  );

  test('withHits 把命盘摘要前置到讲义片段，其余素材不丢', () {
    const base = LlmRetrieval(
      classics: [
        ClassicHit(source: 'shanghan', sourceLabel: '伤寒论讲稿', title: '桂枝汤', snippet: '太阳病'),
      ],
      matchedArticles: 7,
      formulas: ['桂枝汤'],
      stats: '方剂库 314 首',
    );

    final merged = base.withHits([seed]);

    expect(merged.classics.length, 2);
    expect(merged.classics.first.sourceLabel, '紫微命盘（本地排盘结果）');
    expect(merged.classics.first.asset, isNull); // 来源卡片不设跳转
    expect(merged.matchedArticles, 7); // 讲义命中数不因植入而虚增
    expect(merged.formulas, ['桂枝汤']);
    expect(merged.stats, contains('314'));
  });

  test('withHits 空列表原样返回', () {
    const base = LlmRetrieval(classics: [], matchedArticles: 0);
    expect(identical(base.withHits(const []), base), isTrue);
  });

  test('命盘摘要经 buildContext 渲染成可依据的片段', () {
    final out = LlmService.buildContext([seed], '解读命盘');
    expect(out, contains('紫微命盘（本地排盘结果）·本盘十二宫与四化'));
    expect(out, contains('命宫'));
  });
}
