import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/data/medical_case_data.dart';
import 'package:nihaisha_app/services/classic_search_service.dart';
import 'package:nihaisha_app/services/llm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LlmService 上下文拼装', () {
    test('system 含不得编造铁律', () {
      final s = LlmService.buildSystem('测试人格');
      expect(s, contains('测试人格'));
      expect(s, contains('讲义里没有涉及这个话题'));
      expect(s.contains('modules/'), isFalse);
    });

    test('零命中时明确标注并带上提问', () {
      final c = LlmService.buildContext(<ClassicHit>[], '桂枝汤证');
      expect(c, contains('本次检索没有命中讲义内容'));
      expect(c, contains('【提问】\n桂枝汤证'));
      expect(c.length, lessThan(LlmService.maxContextChars + 200));
    });

    test('命中片段被截断且总长受限', () {
      final hits = List.generate(
        10,
        (i) => ClassicHit(
          source: 'shanghan',
          sourceLabel: '伤寒论讲稿',
          title: '宋本$i',
          snippet: '桂枝汤' * 500,
        ),
      );
      final c = LlmService.buildContext(hits, '问');
      expect(c.length, lessThan(LlmService.maxContextChars + 200));
      expect(c, contains('【伤寒论讲稿·宋本0】'));
    });

    test('接口地址归一化去掉尾部斜杠', () {
      expect(
        LlmService.normalizeBase(' https://api.example.com/v1/// '),
        'https://api.example.com/v1',
      );
    });

    test('方剂清单 / 医案 / 统计都进入上下文，且总长受限', () {
      final hits = [
        const ClassicHit(
          source: 'shanghan',
          sourceLabel: '伤寒论讲稿',
          title: '宋本176',
          snippet: '白虎汤主之',
        ),
      ];
      final c = LlmService.buildContext(
        hits,
        '咳嗽有哪些方剂',
        formulas: const ['白虎汤', '麻黄汤'],
        cases: [
          MedicalCase(
            seq: 8,
            diagnosis: '大肠癌',
            mechanism: '停在少阳与阳明之间',
            formula: '大柴胡汤',
            result: '〔愈〕恢复很好',
          ),
        ],
        stats: '【本地统计（口径＝本 App 收录量）】\n· 《金匮要略》讲稿 433 条',
      );
      expect(c, contains('【命中片段中出现的方剂】'));
      expect(c, contains('白虎汤、麻黄汤'));
      expect(c, contains('【倪师医案】'));
      expect(c, contains('#8｜诊断：大肠癌'));
      expect(c, contains('【本地统计'));
      expect(c.endsWith('【提问】\n咳嗽有哪些方剂'), isTrue,
          reason: '提问必须留在最后一块');
      expect(c.length, lessThan(LlmService.maxContextChars +
          LlmService.maxExtraChars + 400));
    });
  });

  test('关键词抽取含领域词且滤掉虚词', () {
    final kws = LlmService.keywordsFor('桂枝汤证的辨证要点是什么？');
    expect(kws, contains('桂枝汤'));
    expect(kws, contains('桂枝汤证'));
    expect(kws.contains('什么'), isFalse);
  });

  test('整句提问经关键词回退后能命中讲义（可达性，非仅存在性）', () async {
    final hits = await LlmService.retrieve('桂枝汤证的辨证要点是什么？');
    expect(hits, isNotEmpty, reason: '整句提问不能 0 命中，否则问答永远无讲义可用');
  });

  test('问答片段必须成段：一条命中里能看到多个方名，而非 70 字窗口', () async {
    final hits = await LlmService.retrieve('桂枝汤证的辨证要点是什么？');
    final longest =
        hits.map((h) => h.snippet.length).reduce((a, b) => a > b ? a : b);
    expect(longest, greaterThan(150),
        reason: '摘要窗口过短时，模型只能看到第一个方剂名');
    expect(hits.map((h) => '${h.source}|${h.title}').toSet().length, hits.length,
        reason: '同一篇讲稿只应贡献一条片段，否则上下文被一段占满');
  });

  test('疾病类提问能同时拿到方剂清单与多条不同来源片段', () async {
    await FormulaRepository.load();
    final r = await LlmService.prepare('咳嗽有哪些方剂？');
    expect(r.classics.length, greaterThan(1));
    expect(r.formulas, isNotEmpty,
        reason: '必须给出确定性方剂清单，否则模型只答第一个方剂');
  });

  test('计数类提问注入本地统计，普通提问不注入', () async {
    await FormulaRepository.load();
    final counting = await LlmService.prepare('金匮有多少方剂？');
    expect(counting.stats, contains('本地统计'));
    expect(counting.stats, contains('金匮要略'));

    final plain = await LlmService.prepare('桂枝汤证的辨证要点是什么？');
    expect(plain.stats, isEmpty, reason: '非计数提问不该被统计块干扰');
  });

  test('医案进上下文：说得出病名就能取到本地医案', () async {
    final cases = await LlmService.retrieveCases('大肠癌怎么治？');
    expect(cases, isNotEmpty, reason: '医案库必须参与检索，否则模型只能编病案');
    expect(cases.length, lessThanOrEqualTo(LlmService.maxCases));
  });

  test('多轮 messages：无历史时只有 system + 当前 user', () {
    final m = LlmService.buildMessages(
      system: 'S',
      currentContext: 'C',
      history: const [],
    );
    expect(m.length, 2);
    expect(m[0]['role'], 'system');
    expect(m[1]['role'], 'user');
    expect(m[1]['content'], 'C');
  });

  test('多轮 messages：只带最近 3 轮，历史轮不含讲义片段', () {
    final history = [
      for (var i = 1; i <= 5; i++) (question: 'Q$i', answer: 'A$i'),
    ];
    final m = LlmService.buildMessages(
      system: 'S',
      currentContext: '【讲义片段】C',
      history: history,
    );
    expect(m.length, 2 + LlmService.maxHistoryTurns * 2);
    final all = m.map((e) => e['content']).join('\n');
    expect(all.contains('Q1'), isFalse, reason: '最早的轮次应被裁掉');
    expect(all.contains('Q2'), isFalse);
    expect(all.contains('Q3'), isTrue);
    expect(all.contains('Q5'), isTrue);
    expect(all.contains('A5'), isTrue);
    expect(m.last['content'], '【讲义片段】C',
        reason: '讲义片段只出现在当前轮，历史轮是纯 Q/A');
    expect(m[1]['content'], 'Q3');
  });

  test('测试连接在配置不全时直接拒绝，不发网络请求', () async {
    await expectLater(
      LlmService.testConnection(
        const LlmConfig(baseUrl: '', apiKey: '', model: ''),
      ),
      throwsA(isA<LlmException>()),
    );
  });

  test('上下文溢出错误可识别，普通 400 不误判', () {
    expect(
      LlmService.isContextOverflow(
          '{"error":{"code":"context_length_exceeded"}}'),
      isTrue,
    );
    expect(
      LlmService.isContextOverflow('maximum context length is 4096 tokens'),
      isTrue,
    );
    expect(
      LlmService.isContextOverflow('{"error":{"message":"bad request"}}'),
      isFalse,
    );
    expect(LlmService.isContextOverflow(''), isFalse);
  });

  test('急症提问触发加强版免责框', () {
    expect(
      LlmService.isEmergencyQuery('我胸口剧痛大汗淋漓，该吃什么方子？'),
      isTrue,
    );
    expect(
      LlmService.isEmergencyQuery('桂枝汤证的辨证要点是什么？'),
      isFalse,
    );
  });

  test('persona 资产合规：不含 modules 引用、不超预算、含 App 约束', () {
    final f = File('assets/llm/persona.md');
    expect(f.existsSync(), isTrue, reason: 'persona.md 必须存在并注册进 pubspec');
    final s = f.readAsStringSync();
    expect(s.length, greaterThan(1000));
    expect(s.length, lessThan(14000));
    expect(s.contains('modules/'), isFalse);
    expect(s.contains('expression_style.md'), isFalse);
    expect(s.contains('App 运行约束'), isTrue);
  });

  group('出处审计（P2）：回答里超出讲义范围的方名', () {
    ClassicHit hit(String title, String snippet) => ClassicHit(
          source: 'shanghan',
          sourceLabel: '伤寒论讲稿',
          title: title,
          snippet: snippet,
          asset: 'assets/shanghan/clause_001.md',
        );

    test('讲义里有的方名不报，没有的报出来', () {
      final r = LlmRetrieval(
        classics: [hit('一二、「太阳中风」', '桂枝汤主之。')],
        formulas: ['桂枝汤'],
      );
      final out = LlmService.unverifiedFormulas(
        '这是桂枝汤证。若兼项强可用葛根汤，另有小续命汤可考虑。',
        r,
      );
      expect(out, contains('葛根汤'));
      expect(out, contains('小续命汤'));
      expect(out, isNot(contains('桂枝汤')), reason: '片段里有桂枝汤，属有据');
    });

    test('医案用方也算有据', () {
      final r = LlmRetrieval(
        classics: const [],
        formulas: const [],
        cases: [
          MedicalCase(
            seq: 8,
            diagnosis: '大肠癌',
            mechanism: '停在少阳与阳明之间',
            formula: '大柴胡汤',
            result: '愈',
          ),
        ],
      );
      expect(LlmService.unverifiedFormulas('用大柴胡汤。', r), isEmpty);
    });

    test('回答里没有方名时返回空，不误报', () {
      final r = LlmRetrieval(classics: const []);
      expect(LlmService.unverifiedFormulas('先辨六经，再看虚实。', r), isEmpty);
    });
  });

  group('方剂库摘要（P3）：给模型「什么情况不能用」的反证', () {
    setUpAll(() async {
      await FormulaRepository.load();
    });

    test('命中方剂带上禁忌与要点', () async {
      final r = await LlmService.prepare('桂枝汤证的辨证要点是什么？');
      final gui = r.formulaBriefs.where((b) => b.name == '桂枝汤').toList();
      expect(gui, isNotEmpty, reason: '命中桂枝汤却没取到库摘要');
      expect(gui.first.caution, isNotEmpty, reason: '禁忌是鉴别的核心，不能空');
    });

    test('上下文里有方剂摘要块，且明确标注非讲稿原文', () {
      final c = LlmService.buildContext(
        const [],
        '桂枝汤证',
        formulas: const ['桂枝汤'],
        formulaBriefs: const [
          (name: '桂枝汤', caution: '脉浮紧，发热，汗不出者不可与。', gist: '群方之魁'),
        ],
      );
      expect(c, contains('【方剂库摘要】'));
      expect(c, contains('非讲稿原文'), reason: '二手整理数据必须标注来源，否则会被当倪师原话');
      expect(c, contains('汗不出者不可与'), reason: '禁忌没渲染出来就等于没接');
    });

    test('易混方的鉴别点可达（麻黄汤 vs 桂枝汤）', () async {
      final r = await LlmService.prepare('麻黄汤证和桂枝汤证怎么区分？');
      final briefs = {for (final b in r.formulaBriefs) b.name: b};
      expect(briefs.keys, containsAll(<String>['麻黄汤', '桂枝汤']));
      final joined = briefs.values.map((b) => '${b.caution}${b.gist}').join();
      expect(joined.contains('无汗') || joined.contains('汗出'),
          isTrue, reason: '两方的鉴别眼目就是有汗/无汗，必须可达');
    });

    test('persona 规定方剂库不能冒充倪师原话', () {
      final s = File('assets/llm/persona.md').readAsStringSync();
      expect(s, contains('【方剂库摘要】'));
      expect(s, contains('不是倪师原话'));
    });

    test('方剂摘要不得挤掉医案块（同为附加素材，预算共享）', () {
      final c = LlmService.buildContext(
        const [],
        '桂枝汤证',
        formulas: const ['桂枝汤'],
        formulaBriefs: const [
          (name: '桂枝汤', caution: '汗不出者不可与。', gist: '群方之魁'),
        ],
        cases: [
          MedicalCase(seq: 8, diagnosis: '大肠癌', formula: '大柴胡汤'),
        ],
      );
      expect(c, contains('【方剂库摘要】'));
      expect(c, contains('【倪师医案】'), reason: '加素材块不能把医案挤没');
    });
  });
}
