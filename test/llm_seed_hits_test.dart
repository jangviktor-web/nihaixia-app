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
  const lecture = ClassicHit(
    source: 'tianji',
    sourceLabel: '天纪讲义',
    title: '第一节 天纪与真理',
    snippet: '天纪是自然法则',
  );

  test('withFacts 把盘面放进独立字段，不污染讲义片段', () {
    const base = LlmRetrieval(
      classics: [
        ClassicHit(source: 'shanghan', sourceLabel: '伤寒论讲稿', title: '桂枝汤', snippet: '太阳病'),
      ],
      matchedArticles: 7,
      formulas: ['桂枝汤'],
      stats: '方剂库 314 首',
    );

    final merged = base.withFacts([seed]);

    expect(merged.seedFacts.length, 1);
    expect(merged.seedFacts.first.asset, isNull); // 来源卡片不设跳转
    // 关键：讲义片段不被盘面污染，命中数也不虚增
    expect(merged.classics.length, 1);
    expect(merged.classics.first.sourceLabel, '伤寒论讲稿');
    expect(merged.matchedArticles, 7);
    expect(merged.formulas, ['桂枝汤']);
    expect(merged.stats, contains('314'));
  });

  test('withFacts 空列表原样返回', () {
    const base = LlmRetrieval(classics: [], matchedArticles: 0);
    expect(identical(base.withFacts(const []), base), isTrue);
  });

  test('盘面事实渲染为独立块，且排在讲义片段之前', () {
    final out = LlmService.buildContext(
      const [lecture],
      '解读命盘',
      seedFacts: const [seed],
    );
    expect(out, contains('【本地盘面事实】'));
    expect(out, contains('紫微命盘（本地排盘结果）·本盘十二宫与四化'));
    expect(out, contains('【讲义片段】'));
    expect(out, contains('天纪是自然法则'));
    expect(out.indexOf('【本地盘面事实】'), lessThan(out.indexOf('【讲义片段】')),
        reason: '盘面是确定性事实，必须排在可能无关的讲义摘录之前');
  });

  test('医疗场景不渲染盘面块', () {
    final out = LlmService.buildContext(const [], '桂枝汤治什么');
    expect(out, isNot(contains('【本地盘面事实】')));
  });

  test('命理铁律：认盘面、限尺度、禁医疗结论', () {
    final s = LlmService.buildSystem('测试人格', scene: LlmScene.divination);
    expect(s, contains('【本地盘面事实】'), reason: '要让模型知道盘面可直接引用');
    expect(s, contains('不要重新推算'));
    expect(s, contains('民俗'));
    expect(s, contains('不用「一定 / 必然 / 注定'));
    expect(s, contains('不诊断疾病'));
    expect(s, isNot(contains('方剂库摘要')), reason: '命理场景不应出现医疗素材块名');
  });

  test('默认场景仍是医疗铁律（不回归）', () {
    final s = LlmService.buildSystem('测试人格');
    expect(s, contains('方剂库摘要'));
    expect(s, contains('倪师医案'));
    expect(s, isNot(contains('【本地盘面事实】')));
  });
}
