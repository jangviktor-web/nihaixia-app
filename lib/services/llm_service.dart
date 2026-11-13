import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../data/acupoint_repository.dart';
import '../data/chinese_convert.dart' show toSimplified;
import '../data/classic_lecture_data.dart' show kJinguiLectures, kShangHanLectures;
import '../data/disease_alias_index.dart';
import '../data/formula_mention_index.dart';
import '../data/formula_repository.dart';
import '../data/medical_case_data.dart';
import '../data/settings_repository.dart';
import '../models/acupoint_detail.dart';
import 'classic_search_service.dart';

class LlmException implements Exception {
  final String message;
  const LlmException(this.message);

  @override
  String toString() => message;
}

/// OpenAI 兼容端点的连接配置。应用不内置任何地址或密钥。
class LlmConfig {
  final String baseUrl;
  final String apiKey;
  final String model;

  const LlmConfig({
    required this.baseUrl,
    required this.apiKey,
    required this.model,
  });

  factory LlmConfig.fromSettings() {
    final s = SettingsRepository.instance;
    return LlmConfig(
      baseUrl: s.llmBaseUrl,
      apiKey: s.llmApiKey,
      model: s.llmModel,
    );
  }
}

/// 一次提问的全部本地素材。检索一次、多处复用（上下文拼装 + 来源卡片 + 医案卡片）。
class LlmRetrieval {
  /// 讲义命中片段（给模型的长摘要）。
  final List<ClassicHit> classics;

  /// 未截断的命中总条数（片段只保留前若干条）。
  final int matchedArticles;

  /// 命中片段中出现的方剂名（确定性抽取，用于「某病有哪些方剂」的完整列举）。
  final List<String> formulas;

  /// 相关问题医案（来自本地 1089 例医案库）。
  final List<MedicalCase> cases;

  /// 从命中医案反推出来的方剂（「二跳」检索用：医保案里的方 → 回讲稿找该方的条文）。
  final List<String> caseFormulas;

  /// 命中方剂的本地库摘要（禁忌 + 要点）。
  ///
  /// 检索天然只召回「这个方治什么」（正向适应证），而辨证的难点在**排除**——
  /// 「为什么不是那个方、什么情况会把它用错」。禁忌就是排除依据，缺了它模型
  /// 只能拿自己的记忆做鉴别，且无从审计。数据来自 formulas.json（结构化整理，
  /// 非讲稿原文，渲染时会明确标注）。
  final List<({String name, String caution, String gist})> formulaBriefs;

  /// 本条提问命中的穴位（问「足三里主治什么」「失眠扎什么穴」时给出定位/手法/禁忌）。
  final List<AcupointDetail> acupoints;

  /// 本条提问命中的古今 / 中西医病名对照。
  final List<DiseaseAlias> diseases;

  /// 计数类提问的本地统计，空串表示不注入。
  final String stats;

  const LlmRetrieval({
    required this.classics,
    this.matchedArticles = 0,
    this.formulas = const [],
    this.cases = const [],
    this.caseFormulas = const [],
    this.formulaBriefs = const [],
    this.acupoints = const [],
    this.diseases = const [],
    this.stats = '',
  });

  /// 病名对照块（空串表示本条提问没命中对照关系）。
  String get diseaseBrief => DiseaseAliasIndex.brief(diseases);
}

/// 倪师讲义问答：本地检索片段 + 人格规则 → 一次 POST。
///
/// ponytail: 非流式、无重试队列；历史只带最近 3 轮、由调用方传入，不持久化。
class LlmService {
  LlmService._();

  static const String personaAsset = 'assets/llm/persona.md';

  /// 片段条数。原先 5 条 × 70 字摘要，一个病只能看到一两首方，模型便「只答第一个」。
  static const int maxHits = 8;

  /// 问答专用摘要窗口半径：列表展示仍是 ±32 字，问答要成段原文才能数得清方剂。
  static const int contextSnippetSpan = 200;
  static const int maxSnippetChars = 520;
  static const int maxContextChars = 3600;

  /// 方剂清单 / 医案 / 统计等附加块的独立预算（不挤占讲义片段预算）。
  static const int maxExtraChars = 2400;
  static const int maxFormulaList = 12;
  static const int maxCases = 3;

  /// 医案召回条数：比注入条数多取几条，只用于二跳抽方，不写进 prompt。
  static const int maxCaseCandidates = 5;

  /// 二跳检索：从命中医案反推最多几首方，回讲稿找它们的原文。
  static const int maxCaseFormulas = 3;

  /// 针灸意图：命中时改走「针灸讲稿优先 + 穴位事实 + 医案针灸列」三路。
  static const int maxAcupoints = 3;

  /// 针灸讲稿（`zhenjiu` 源）在索引里只有 72 条，全源检索永远排不上，
  /// 所以针刺/艾灸类提问必须单独限定来源。
  static const int maxAcuHits = 3;

  static const Set<String> _acuKeywords = {
    '针灸', '针', '灸', '扎针', '下针', '取穴', '穴位', '艾灸', '艾条',
    '刺血', '放血', '耳针', '耳穴', '拔罐', '火罐', '经络', '埋线', '电针',
  };
  static const int maxHistoryTurns = 3;

  static String? _persona;

  static String normalizeBase(String url) {
    var u = url.trim();
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  /// 急症提问：正文的安全话术由 persona 禁止（避免逐题重复、跑偏），
  /// 因此应用侧必须识别并渲染加强版免责框，否则会出现「只说不能定方、不给急救指引」。
  static const Set<String> emergencyKeywords = {
    '胸口剧痛', '胸痛', '大汗淋漓', '心梗', '中风', '昏迷', '大出血',
    '呼吸困难', '窒息', '抽搐', '高热不退', '剧烈腹痛', '休克',
  };

  static bool isEmergencyQuery(String q) =>
      emergencyKeywords.any(q.contains);

  /// ClassicSearchService 是整串 contains：整句提问（「桂枝汤证的辨证要点是什么？」）
  /// 会 0 命中，只有短词（「桂枝汤」208 命中）才有结果。
  /// ponytail: 不引入分词器，只切 2–4 字连续片段并滤掉虚词，长词优先。
  static const Set<String> _stopWords = {
    '什么', '怎么', '如何', '为何', '为什', '是否', '可以', '应该', '请问',
    '一下', '这个', '那个', '有没有', '能不能', '关系', '要点', '区别',
    '哪些', '多少', '哪里', '帮我', '告诉', '说说', '介绍', '是不是',
    // 领域泛词：含它们必然命中上百条无关条文，会把真正的病名/方名挤掉。
    '方剂', '方子', '处方', '方名', '经方', '中药', '中医', '药材', '药物',
    '医师', '医生', '病人', '症状', '治疗', '治法', '办法', '方法', '情况',
    '问题', '内容', '意思', '作用', '功效', '效果', '用法', '用量', '剂量',
    '时候', '怎么用', '用什么', '有哪些',
    // 求诊话术里的泛词：不滤掉的话，「西医诊断我是里寒湿」会先命中「西医」「诊断」，
    // 把「寒湿」真正的医案挤到后面（实测命中的是肺癌/癫痫案，全不相干）。
    '西医', '诊断', '医院', '检查', '患者',
  };

  /// 疑问/语气/代词字符：任何包含它们的片段都不是领域词。
  ///
  /// 不做这层过滤时，「有哪些」命中 8 条、「有多」命中 74 条、「方剂」命中 88 条，
  /// 而真正的病名「咳嗽」命中 191 条却排在最后被截断 —— 检索结果全是无关条文。
  /// ⛔ 只放功能字，不要放「上下中里」这类会切碎「中焦 / 心下 / 上气」的字。
  static const String _functionChars =
      '的了吗呢吧啊么什怎哪那些这有多几是个用能可会要该应为请帮我你他她它们'
      '和与及或而也都还又但如若者之';

  static final Set<String> _functionCharSet =
      _functionChars.split('').toSet();

  static bool _isContentWord(String w) {
    // 子串判定而非整词判定：只停「西医」「诊断」拦不住 4-gram 拼出来的
    // 「西医诊断」「医诊断」，而这些词在讲稿里遍地都是，一命中就把上下文塞满
    // 无关条文（实测同一个问题的 8 条片段里有 7 条是伤寒通用条辨）。
    for (final s in _stopWords) {
      if (w.contains(s)) return false;
    }
    for (var i = 0; i < w.length; i++) {
      if (_functionCharSet.contains(w[i])) return false;
    }
    return true;
  }

  static List<String> keywordsFor(String q) {
    final clean = q.replaceAll(RegExp(r'[^\u4e00-\u9fffA-Za-z0-9]'), '');
    final words = <String>{};
    for (var len = 4; len >= 2; len--) {
      for (var i = 0; i + len <= clean.length; i++) {
        final w = clean.substring(i, i + len);
        if (_isContentWord(w)) words.add(w);
      }
    }
    return words.take(32).toList();
  }

  /// 整句直接检索；0 命中时按关键词逐词检索并合并（长词优先）。
  ///
  /// 回退路径按关键词**贪心填满**：最具体的词（长词）先把它能给的片段全拿走，
  /// 而不是每个词只取 2 条。否则一个病名有 191 条命中却只进 2 条，
  /// 上下文里就只剩一两首方，模型只能「只答第一个方剂」。
  /// 去重键是「来源+标题」，同一篇讲稿只贡献一条。
  ///
  /// [priority] 是**已知术语**（病名索引命中的古名、提问里的方剂名），先检索它们；
  /// [extra] 是病名对照的其余叫法（问「糖尿病」→ 补「消渴」），只在还有空位时用。
  /// 优先级顺序保证了「用户字面问到的东西」与「古今叫法对应的东西」都在上下文里，
  /// 又不会让扩展词把原词结果挤掉。
  static Future<ClassicSearchResult> _retrieveResult(
    String q, {
    List<String> priority = const [],
    List<String> extra = const [],
    List<ClassicHit> seed = const [],
    int cap = maxHits,
  }) async {
    final direct = await ClassicSearchService.search(
      q,
      snippetSpan: contextSnippetSpan,
      maxResults: cap,
    );
    if (direct.hits.isNotEmpty &&
        priority.isEmpty &&
        extra.isEmpty &&
        seed.isEmpty) {
      return direct;
    }

    final pool = <String, ClassicHit>{};
    // seed = 已经确定必须占位的高价值片段（如针灸讲稿）。先落位再填别的，
    // 否则它们会被同源噪声挤出上下文。
    for (final h in seed) {
      if (pool.length >= cap) break;
      pool.putIfAbsent('${h.source}|${h.title}', () => h);
    }
    for (final h in direct.hits) {
      if (pool.length >= cap) break;
      pool.putIfAbsent('${h.source}|${h.title}', () => h);
    }
    var bestTotal = direct.total;

    Future<void> sweep(String w, int cap, {int perWord = 0}) async {
      final r = await ClassicSearchService.search(
        w,
        snippetSpan: contextSnippetSpan,
        maxResults: perWord > 0 ? perWord : cap,
      );
      if (r.total == 0) return;
      if (r.total > bestTotal) bestTotal = r.total;
      var take = 0;
      for (final h in r.hits) {
        if (pool.length >= cap) break;
        if (perWord > 0 && take >= perWord) break;
        final before = pool.length;
        pool.putIfAbsent('${h.source}|${h.title}', () => h);
        if (pool.length > before) take++;
      }
    }

    // ① 已知术语（古病名 / 方名）优先，但留 2 条给用户原话里的其它词。
    if (priority.isNotEmpty) {
      final pcap = (cap - 2).clamp(1, cap);
      for (final w in priority) {
        if (pool.length >= pcap) break;
        await sweep(w, pcap);
      }
    }
    // ② 原关键词：**首个命中的词才允许填满**，其后每词最多 2 条。
    // 否则「大肠癌」这类题在长词只命中 1-2 条时，会由「大肠」把剩余槽位全部吃掉，
    // 塞进一堆大肠经/针灸条文（实测 8 条片段里 5 条与大肠癌无关）。
    var firstHit = true;
    for (final w in keywordsFor(q)) {
      if (pool.length >= cap) break;
      final before = pool.length;
      await sweep(w, cap, perWord: firstHit ? 0 : 2);
      if (pool.length > before) firstHit = false;
    }
    // ③ 病名对照的补充叫法（原词没喂饱才用），一律每词 2 条。
    for (final w in extra) {
      if (pool.length >= cap) break;
      await sweep(w, cap, perWord: 2);
    }
    return ClassicSearchResult(total: bestTotal, hits: pool.values.toList());
  }

  /// 只取讲义片段（保留旧接口：调用方只需要命中列表时用）。
  static Future<List<ClassicHit>> retrieve(String q) async =>
      (await _retrieveResult(q)).hits;

  /// 组装一次提问所需的全部本地素材：讲义片段 + 病名对照 + 方剂 + 相关医案 + 统计。
  static Future<LlmRetrieval> prepare(String q) async {
    // 穴位表幂等加载（402 条，首次几毫秒）：针灸意图要靠穴位名判定，
    // 「足三里主治什么」这类句子一个针/灸字都没有。
    await AcupointRepository.load();
    final acupoints = <AcupointDetail>[...retrieveAcupoints(q)];
    final isAcu = isAcupunctureQuery(q);
    final acuFuture =
        isAcu ? _retrieveAcuHits(q) : Future<List<ClassicHit>>.value(const []);

    // 医案解析较重（1089 例）但只解析一次（进程内缓存），
    // 因为它决定了要不要给「二跳」预留槽位，必须先拿到。
    var cases = await retrieveCases(q, max: maxCaseCandidates);
    // 第三跳先跑（症状 → 穴位最贴题），医案针灸列反查放后面补齐。
    // 顺序反了会被「随便哪条医案的配穴」占满 3 个名额（实测问带状疱疹给出的
    // 是下关/合谷/胆石点，因为前 3 个名额被医案反查占掉了）。
    if (isAcu) {
      final jump = await _jumpByAcupoints(q);
      for (final p in jump.points) {
        if (acupoints.length >= maxAcupoints) break;
        if (!acupoints.any((e) => e.name == p.name)) acupoints.add(p);
      }
      if (jump.cases.isNotEmpty) {
        final merged = <MedicalCase>[...jump.cases];
        for (final c in cases) {
          if (merged.length >= maxCaseCandidates) break;
          if (!merged.any((e) => e.seq == c.seq)) merged.add(c);
        }
        cases = merged;
      }
    }

    // 医案「针灸方案」列是倪师真实配穴记录：拿它反查穴位库，
    // 医案给穴位、穴位库给定位与手法，这条闭环才是「用针灸医案训练」的落点。
    for (final c in cases) {
      if (acupoints.length >= maxAcupoints) break;
      if (c.acupuncture.isEmpty) continue;
      for (final p in retrieveAcupoints(
        c.acupuncture,
        max: maxAcupoints - acupoints.length,
      )) {
        if (!acupoints.any((e) => e.name == p.name)) acupoints.add(p);
      }
    }
    final aliasIndex = await DiseaseAliasIndex.load();
    final aliases = aliasIndex.match(q);
    // 已知术语优先：病名索引里的古名（问「糖尿病」先检索「消渴」）+ 提问里的方名。
    final priority = <String>[
      // 只取 gujin（古篇名）条目的古名。zhongxi 条目的 ancient 往往是症状描述
      // （如「脓血 → 大肠癌」），拿它检索会把桃花汤类条文塞满上下文。
      for (final e in aliases)
        if (e.isGuiJin) e.ancient,
      ...extractFormulaNames(q),
    ];

    // 二跳：病名检索拿到的是「讲这个病」的条文，未必是「用这个方」的条文。
    // 医案里「诊断 → 方剂」是现成的映射，拿它回讲稿找该方的原文，
    // 才能把「大肠癌 → 大柴胡汤」这类答案真正送到模型面前。
    // ⚠️ 必须给二跳**预留**槽位，否则第一轮把 8 条填满，二跳永远轮不上（实测白改）。
    final caseFormulas = <String>[];
    for (final c in cases) {
      for (final f in c.formulaNames) {
        if (caseFormulas.length >= maxCaseFormulas) break;
        if (!caseFormulas.contains(f)) caseFormulas.add(f);
      }
    }
    final reserve = caseFormulas.isEmpty ? 0 : maxCaseFormulas;
    final acuHits = await acuFuture;
    var res = await _retrieveResult(
      q,
      priority: priority,
      extra: aliasIndex.expandTerms(aliases),
      // 针灸讲稿（72 条）seed 在前，保证「问针灸却全是伤寒条文」不再发生。
      seed: acuHits,
      cap: maxHits - reserve,
    );
    if (caseFormulas.isNotEmpty) {
      res = await _extendByFormulas(res, caseFormulas);
    }

    final formulas = <String>[];
    for (final h in res.hits) {
      for (final f in extractFormulaNames(h.snippet)) {
        if (formulas.length >= maxFormulaList) break;
        if (!formulas.contains(f)) formulas.add(f);
      }
    }

    // 方剂库摘要：把禁忌与要点带上，让模型能给出「有据的反证」。
    final briefs = <({String name, String caution, String gist})>[];
    for (final name in formulas) {
      if (briefs.length >= maxFormulaList) break;
      final d = FormulaRepository.getByName(name);
      if (d == null) continue;
      briefs.add((
        name: d.name,
        caution: d.contraindication.trim(),
        gist: d.explanation.trim(),
      ));
    }

    return LlmRetrieval(
      classics: res.hits,
      matchedArticles: res.total,
      formulas: formulas,
      formulaBriefs: briefs,
      cases: cases,
      caseFormulas: caseFormulas,
      acupoints: acupoints,
      diseases: aliases,
      stats: await _statsIfCounting(q, matched: res.total, cases: cases.length),
    );
  }

  /// 用医案反推的方剂补讲义片段：只在还有空位时补，且不重复已有条文。
  static Future<ClassicSearchResult> _extendByFormulas(
    ClassicSearchResult base,
    List<String> formulas,
  ) async {
    final pool = <String, ClassicHit>{
      for (final h in base.hits) '${h.source}|${h.title}': h,
    };
    // 轮流取：每首方先占 1 条。若让第一首把预留槽位吃满，
    // 排在后面的方（往往才是答案）永远进不来（实测「射干麻黄汤」被「麻黄附子细辛汤」挤掉）。
    for (var round = 0; round < maxHits; round++) {
      var added = false;
      for (final f in formulas) {
        if (pool.length >= maxHits) break;
        final r = await ClassicSearchService.search(
          f,
          snippetSpan: contextSnippetSpan,
          maxResults: round + 1,
        );
        if (r.hits.length <= round) continue;
        final h = r.hits[round];
        final key = '${h.source}|${h.title}';
        if (pool.containsKey(key)) continue;
        pool[key] = h;
        added = true;
      }
      if (!added) break;
    }
    return ClassicSearchResult(total: base.total, hits: pool.values.toList());
  }

  /// 医案检索：先按提问里的病名/方名命中，抽不到时退回关键词。
  /// 医案库此前完全没进问答上下文，模型只能凭印象编病案。
  static Future<List<MedicalCase>> retrieveCases(
    String q, {
    int max = maxCases,
  }) async {
    final all = await getAllMedicalCases();
    if (all.isEmpty) return const [];

    final needles = <String>{
      ...extractDiseaseNames(q),
      ...extractFormulaNames(q),
    };
    if (needles.isEmpty) {
      // 短词优先：4-gram 连续片段在医案里几乎不可能逐字出现，
      // 按「长词优先」取前 10 个等于全部落空（实测「里寒湿」0 命中）。
      final kws = keywordsFor(q).where((w) => w.length >= 2).toList()
        ..sort((a, b) => a.length.compareTo(b.length));
      needles.addAll(kws.take(10));
    }
    if (needles.isEmpty) return const [];

    final norm = <String>{
      for (final n in needles) toSimplified(n).toLowerCase(),
    }.where((n) => n.isNotEmpty);

    final scored = <({MedicalCase c, int score})>[];
    for (final c in all) {
      var score = 0;
      for (final n in norm) {
        // 按命中词**长度**加权：命中「带状疱疹」比命中「痛」值钱得多。
        // 只数个数时，一堆只沾了「痛」字的案例会把真正同病的案例挤掉
        // （实测「带状疱疹后遗神经痛」召回的 5 条里没有一条是带状疱疹）。
        if (c.matchesNormalized(n)) score += n.length;
        // 命中「主要诊断」再加一倍：诊断对上就是同病，比病机里顺带提到更靠谱。
        if (c.diagnosisNorm.contains(n)) score += n.length * 2;
      }
      if (score > 0) scored.add((c: c, score: score));
    }
    if (scored.isEmpty) return const [];
    scored.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      // 同分时短诊断优先（诊断越短越像「就是这个病」），再按 seq 保证稳定，
      // List.sort 不稳定，不给次键每次召回顺序都会漂。
      final byLen = a.c.diagnosis.length.compareTo(b.c.diagnosis.length);
      if (byLen != 0) return byLen;
      return a.c.seq.compareTo(b.c.seq);
    });
    return [for (final e in scored.take(max)) e.c];
  }

  /// 是否针灸类提问：含针刺/艾灸类词，**或**句子里出现了已知穴位名。
  ///
  /// 后一条是必需的：「足三里主治什么」「合谷能治什么」里一个针/灸字都没有，
  /// 但显然在问针灸。穴位表 402 个正名 + 短名归一，直接复用现有仓库。
  static bool isAcupunctureQuery(String q) {
    final text = toSimplified(q);
    for (final k in _acuKeywords) {
      if (text.contains(k)) return true;
    }
    return retrieveAcupoints(q).isNotEmpty;
  }

  /// 提问里点名的穴位（最长优先非重叠匹配，已归一别名）。
  static List<AcupointDetail> retrieveAcupoints(String q, {int max = maxAcupoints}) {
    final text = toSimplified(q);
    if (text.isEmpty) return const [];
    final out = <AcupointDetail>[];
    final used = List<bool>.filled(text.length, false);
    // AcupointRepository.allNames 已按长度降序排好，短名撞普通词的情形也处理过。
    for (final name in AcupointRepository.allNames) {
      if (out.length >= max) break;
      if (name.length < 2) continue;
      var idx = 0;
      while (true) {
        final at = text.indexOf(name, idx);
        if (at < 0) break;
        final end = at + name.length;
        var clash = false;
        for (var i = at; i < end; i++) {
          if (used[i]) {
            clash = true;
            break;
          }
        }
        if (!clash) {
          final p = AcupointRepository.findByName(name) ??
              AcupointRepository.findByName(AcupointRepository.canonicalOf(name));
          if (p != null) {
            out.add(p);
            for (var i = at; i < end; i++) {
              used[i] = true;
            }
          }
        }
        idx = end;
      }
    }
    return out;
  }

  /// 针灸讲稿检索：限定 `zhenjiu` 源，按提问关键词逐个试。
  static Future<List<ClassicHit>> _retrieveAcuHits(String q) async {
    final words = <String>[
      // 点名的穴位最具体，优先。
      ...retrieveAcupoints(q).map((p) => p.name),
      // 病证词次之；「针灸」「扎针」这类剔除 —— 它们在讲稿里遍地是，
      // 一命中就把经络总论抢到前面，问「失眠」反而拿不到治失眠的篇。
      ...keywordsFor(q).where((w) => !_acuKeywords.any(w.contains)),
      q,
    ];
    final out = <String, ClassicHit>{};
    for (final w in words) {
      if (w.trim().isEmpty) continue;
      if (out.length >= maxAcuHits) break;
      final r = await ClassicSearchService.search(
        w,
        snippetSpan: contextSnippetSpan,
        maxResults: maxAcuHits,
        onlySources: const {'zhenjiu'},
      );
      for (final h in r.hits) {
        if (out.length >= maxAcuHits) break;
        out.putIfAbsent('${h.source}|${h.title}', () => h);
      }
    }
    // 兜底：病名言在针灸讲稿里查不到时，至少给「什么时候不能下针」那一篇。
    // 针灸回答不给禁忌是危险的；这一篇也是倪师讲义里唯一按「时机」组织的。
    if (out.isEmpty) {
      final r = await ClassicSearchService.search(
        '不下针',
        snippetSpan: contextSnippetSpan,
        maxResults: 1,
        onlySources: const {'zhenjiu'},
      );
      for (final h in r.hits) {
        out.putIfAbsent('${h.source}|${h.title}', () => h);
      }
    }
    return out.values.toList();
  }

  /// 第三跳：症状 → 穴位 → 医案。
  ///
  /// 针灸讲稿是按经络腧穴组织的，不按病证，所以「失眠扎什么穴」在讲稿里
  /// 只能捞到零散提到失眠的篇，拿不到完整配穴。这一跳换条路：
  /// ① 用症状词反查穴位库的 `clinicalNotes`（主治）→ 得到候选穴位；
  /// ② 用这些穴位反查医案的「针灸方案」列 → 得到倪师真实用过该配穴的案例。
  /// 穴位库给定位手法，医案给配穴与病机，正好互补。
  static Future<({List<AcupointDetail> points, List<MedicalCase> cases})>
      _jumpByAcupoints(String q) async {
    const empty = (points: <AcupointDetail>[], cases: <MedicalCase>[]);
    final symptoms = keywordsFor(q)
        .where((w) => w.length >= 2 && !_acuKeywords.any(w.contains))
        .take(4)
        .toList();
    if (symptoms.isEmpty) return empty;

    // 按主治里的命中次数排序：穴位表是按经络排的，直接取前 3 个会混进
    // 只顺带提一句的穴位（「失眠」曾给出大陵 + 小海 + 太乙，后两个不对症）。
    final scoredPts = <({AcupointDetail p, int s})>[];
    for (final p in AcupointRepository.getAll()) {
      var score = 0;
      for (final w in symptoms) {
        if (p.clinicalNotes.isEmpty) continue;
        score += p.clinicalNotes.split(w).length - 1;
      }
      if (score > 0) scoredPts.add((p: p, s: score));
    }
    scoredPts.sort((a, b) => b.s.compareTo(a.s));
    final points = [for (final e in scoredPts.take(maxAcupoints)) e.p];
    if (points.isEmpty) return empty;

    final names = {for (final p in points) p.name};
    final all = await getAllMedicalCases();
    final scored = <({MedicalCase c, int s})>[];
    for (final c in all) {
      if (c.acupuncture.isEmpty) continue;
      final n = c.acupointNames.where(names.contains).length;
      if (n > 0) scored.add((c: c, s: n));
    }
    if (scored.isEmpty) return (points: points, cases: const <MedicalCase>[]);
    scored.sort((a, b) => b.s.compareTo(a.s));
    return (
      points: points,
      cases: [for (final e in scored.take(maxCases)) e.c],
    );
  }

  /// 计数类提问（多少 / 几个 / 一共 …）注入确定性统计。
  /// 不注入的话模型只能瞎猜「金匮有多少方剂」；注入后它照抄数字并说明口径即可。
  static const Set<String> _countWords = {
    '多少', '几个', '几首', '几种', '几条', '几例', '几篇', '几味',
    '一共', '总共', '总数', '数量', '统计',
  };

  static Future<String> _statsIfCounting(
    String q, {
    required int matched,
    required int cases,
  }) async {
    if (!_countWords.any(q.contains)) return '';
    var shanghanFormulas = 0;
    var jinguiFormulas = 0;
    try {
      final idx = await FormulaMentionIndex.load();
      shanghanFormulas = idx.countWith('s');
      jinguiFormulas = idx.countWith('j');
    } catch (_) {
      // 索引缺失：降级为只给条数，不影响提问。
    }
    final buf = StringBuffer()
      ..writeln('【本地统计（口径＝本 App 收录量）】')
      ..writeln('· 《伤寒论》讲稿 ${kShangHanLectures.length} 条'
          '${shanghanFormulas > 0 ? "，出现方剂 $shanghanFormulas 首" : ""}')
      ..writeln('· 《金匮要略》讲稿 ${kJinguiLectures.length} 条'
          '${jinguiFormulas > 0 ? "，出现方剂 $jinguiFormulas 首" : ""}')
      ..writeln('· 方剂库（含组成与主治）${FormulaRepository.getAll().length} 首')
      ..writeln('· 医案库 ${(await getAllMedicalCases()).length} 例')
      ..writeln('· 本次提问检索命中 $matched 条，医案相关 $cases 例');
    return buf.toString().trim();
  }

  static Future<String> loadPersona() async {
    if (_persona != null) return _persona!;
    // 构建期从 WorkBuddy nihaixia skill 抽取的静态规则；不读 850 KB 旧快照。
    return _persona = await rootBundle.loadString(personaAsset);
  }

  /// 纯函数，便于测试：system = 人格规则 + App 铁律。
  static String buildSystem(String persona) => '''
$persona

---
【本轮运行时铁律 · 优先级最高】
只依据下方【讲义片段】【古今·中西医病名对照】【命中片段中出现的方剂】【方剂库摘要】【倪师医案】【本地统计】作答。后五块也是应用从本地数据确定性抽取的事实，其中统计数字可直接引用并说明口径。
以上都未涉及就明确说「讲义里没有涉及这个话题，我不能替倪师乱讲」，绝不编造、不引用外部知识、不虚构条文号或方剂。
不要输出资产路径、行号或模块编号。不要写免责声明与安全话术——应用会在回答下方固定渲染免责框。
''';

  /// 纯函数，便于测试：把本地检索命中拼成有限长度的讲义片段 + 附加素材。
  ///
  /// [formulas] / [cases] / [stats] 是确定性的本地事实：方剂清单解决「某病只答
  /// 第一个方剂」，医案解决「说到病例不回链医案」，统计解决「不会数方剂数」。
  static String buildContext(
    List<ClassicHit> hits,
    String question, {
    List<String> formulas = const [],
    List<({String name, String caution, String gist})> formulaBriefs = const [],
    List<MedicalCase> cases = const [],
    List<AcupointDetail> acupoints = const [],
    String diseaseBrief = '',
    String stats = '',
  }) {
    final buf = StringBuffer();
    for (final hit in hits.take(maxHits)) {
      final s = hit.snippet;
      final body = s.length > maxSnippetChars
          ? s.substring(0, maxSnippetChars)
          : s;
      final line = '【${hit.sourceLabel}·${hit.title}】\n$body\n';
      if (buf.length + line.length > maxContextChars) break;
      buf.write(line);
    }
    final excerpts = buf.toString().trim();

    final parts = <String>[
      '【讲义片段】\n'
          '${excerpts.isEmpty ? "（本次检索没有命中讲义内容）" : excerpts}',
    ];

    final extra = StringBuffer();
    if (acupoints.isNotEmpty) {
      extra.writeln('【相关穴位（本地穴位库：定位 / 手法 / 禁忌）】');
      for (final p in acupoints) {
        final bits = <String>[
          if (p.location.isNotEmpty) '定位：${_clip(p.location, 46)}',
          if (p.needling.isNotEmpty) '针刺：${_clip(p.needling, 40)}',
          if (p.moxibustion.isNotEmpty) '灸法：${_clip(p.moxibustion, 36)}',
          if (p.clinicalNotes.isNotEmpty) '主治：${_clip(p.clinicalNotes, 46)}',
          if (p.contraindication.isNotEmpty) '禁忌：${_clip(p.contraindication, 32)}',
        ];
        extra.writeln('· ${p.name}（${p.meridian}）｜${bits.join("｜")}');
      }
      extra.writeln();
    }
    if (diseaseBrief.isNotEmpty) {
      extra.writeln(diseaseBrief);
      extra.writeln();
    }
    if (formulas.isNotEmpty) {
      extra.writeln('【命中片段中出现的方剂】（从上述原文确定性抽取，可全部列出）');
      extra.writeln(formulas.take(maxFormulaList).join('、'));
      extra.writeln();
    }
    if (formulaBriefs.isNotEmpty) {
      // 标题与括注必须保留「非讲稿原文」字样：这是二手整理数据，
      // 不标注就会被模型当成倪师原话讲出去。
      extra.writeln('【方剂库摘要】（本地结构化整理，非讲稿原文；'
          '用来讲「什么情况不能用」）');
      for (final b in formulaBriefs) {
        final parts = <String>[
          if (b.caution.isNotEmpty) '禁忌 ${_clip(b.caution, 46)}',
          if (b.gist.isNotEmpty) '要点 ${_clip(b.gist, 40)}',
        ];
        if (parts.isEmpty) continue;
        extra.writeln('· ${b.name}：${parts.join('｜')}');
      }
      extra.writeln();
    }
    if (cases.isNotEmpty) {
      extra.writeln('【倪师医案】（本地医案库，引用时写「医案 #序号」）');
      for (final c in cases.take(maxCases)) {
        extra.writeln('#${c.seq}｜诊断：${_clip(c.diagnosis, 40)}'
            '${c.mechanism.isEmpty ? "" : "｜病机：${_clip(c.mechanism, 40)}"}'
            '${c.formula.isEmpty ? "" : "｜方剂：${_clip(c.formula, 60)}"}'
            // 医案里的「针灸方案」是倪师真实的配穴记录，之前完全没进上下文，
            // 问针灸时等于把最强的材料扔了。
            '${c.acupuncture.isEmpty ? "" : "｜针灸：${_clip(c.acupuncture, 60)}"}'
            '${c.result.isEmpty ? "" : "｜结果：${_clip(c.result, 40)}"}');
      }
      extra.writeln();
    }
    if (stats.isNotEmpty) {
      extra.writeln(stats);
      extra.writeln();
    }
    final extraText = extra.toString().trim();
    if (extraText.isNotEmpty) {
      parts.add(
        extraText.length > maxExtraChars
            ? extraText.substring(0, maxExtraChars)
            : extraText,
      );
    }

    parts.add('【提问】\n$question');
    return parts.join('\n\n');
  }

  static String _clip(String s, int max) {
    final t = s.trim().replaceAll('\n', ' ');
    return t.length <= max ? t : '${t.substring(0, max)}…';
  }

  /// 拼装多轮 messages。讲义片段只给当前轮，历史轮只带纯 Q/A，避免上下文翻倍增长。
  /// 纯函数，便于测试窗口裁剪。
  static List<Map<String, String>> buildMessages({
    required String system,
    required String currentContext,
    required List<({String question, String answer})> history,
  }) {
    final msgs = <Map<String, String>>[
      {'role': 'system', 'content': system},
    ];
    final recent = history.length > maxHistoryTurns
        ? history.sublist(history.length - maxHistoryTurns)
        : history;
    for (final h in recent) {
      msgs.add({'role': 'user', 'content': h.question});
      msgs.add({'role': 'assistant', 'content': h.answer});
    }
    msgs.add({'role': 'user', 'content': currentContext});
    return msgs;
  }

  /// 从 OpenAI 兼容的 GET {base}/models 自动获取可用模型名。
  /// 端点不支持时抛 [LlmException]，设置页允许手动填写模型名兜底。
  static Future<List<String>> fetchModels(String baseUrl, String apiKey) async {
    final base = normalizeBase(baseUrl);
    final key = apiKey.trim();
    if (base.isEmpty || key.isEmpty) {
      throw const LlmException('请先填写接口地址与 API Key');
    }

    late final http.Response res;
    try {
      res = await http
          .get(
            Uri.parse('$base/models'),
            headers: {
              'Authorization': 'Bearer $key',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
    } on Exception {
      throw const LlmException('连接失败：请检查接口地址与网络');
    }

    if (res.statusCode != 200) {
      throw LlmException(_statusMessage(res.statusCode, forModels: true));
    }

    final decoded = jsonDecode(utf8.decode(res.bodyBytes));
    final data = decoded is Map ? decoded['data'] : null;
    if (data is! List) {
      throw const LlmException('该端点未返回模型列表，请手动填写模型名');
    }
    final ids = <String>{};
    for (final item in data) {
      if (item is String) {
        if (item.isNotEmpty) ids.add(item);
      } else if (item is Map && item['id'] is String) {
        final id = item['id'] as String;
        if (id.isNotEmpty) ids.add(id);
      }
    }
    if (ids.isEmpty) {
      throw const LlmException('模型列表为空，请手动填写模型名');
    }
    final list = ids.toList()..sort();
    return list;
  }

  /// 回答里提到、但本轮上下文没有任何支撑的方名（超出讲义范围的引用）。
  ///
  /// 用途：模型可能拿自己的中医知识补片段没有的方。答对了是运气，答错了就是
  /// 幻觉且无从发现 —— 这里把「无据方名」挑出来，交由 UI 标注为「未在讲义
  /// 片段中出现」，让用户自己判断可信度，不改写、不拦截回答。
  ///
  /// 支撑面 = 【讲义片段里出现的方】∪【命中片段的方剂清单】∪【医案用方】。
  /// ⛔ 已知天花板：只能识别 `formulas.json` 里有的方名（314 首）。模型自造
  /// 的、或库外冷门方的名字抽不出来 —— 漏报但不误报，升级方向是扩充方剂库。
  static List<String> unverifiedFormulas(String answer, LlmRetrieval r) {
    final cited = extractFormulaNames(answer);
    if (cited.isEmpty) return const [];
    final supported = <String>{
      ...r.formulas,
      for (final c in r.cases) ...c.formulaNames,
      for (final hit in r.classics) ...extractFormulaNames(hit.snippet),
    };
    return [
      for (final f in cited)
        if (!supported.contains(f)) f,
    ];
  }

  /// 提问。[retrieval] 为 null 时现场组装（[prepare]）。
  static Future<String> ask(
    String question,
    LlmConfig config, {
    LlmRetrieval? retrieval,
    List<({String question, String answer})> history = const [],
    // 推理型模型（reasoning）吐完思考再说答案，60s 常常不够，调用方可放宽。
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final q = question.trim();
    if (q.isEmpty) throw const LlmException('请输入问题');

    final r = retrieval ?? await prepare(q);
    final decoded = await _postChat(
      config,
      buildMessages(
        system: buildSystem(await loadPersona()),
        currentContext: buildContext(
          r.classics,
          q,
          formulas: r.formulas,
          formulaBriefs: r.formulaBriefs,
          cases: r.cases,
          acupoints: r.acupoints,
          diseaseBrief: r.diseaseBrief,
          stats: r.stats,
        ),
        history: history,
      ),
      timeout: timeout,
    );
    try {
      final content = decoded['choices'][0]['message']['content'];
      if (content is! String || content.trim().isEmpty) {
        throw const LlmException('模型返回了空内容');
      }
      return content.trim();
    } on LlmException {
      rethrow;
    } catch (_) {
      throw const LlmException('无法解析模型返回内容');
    }
  }

  /// chat/completions 公共 POST：ask 与 testConnection 共用同一套校验与错误处理。
  static Future<Map<String, dynamic>> _postChat(
    LlmConfig config,
    List<Map<String, String>> messages, {
    int? maxTokens,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final base = normalizeBase(config.baseUrl);
    if (base.isEmpty || config.apiKey.trim().isEmpty || config.model.isEmpty) {
      throw const LlmException('请先在「设置 → AI 讲义问答」完成配置');
    }
    final payload = <String, dynamic>{
      'model': config.model,
      'stream': false,
      'messages': messages,
    };
    if (maxTokens != null) payload['max_tokens'] = maxTokens;

    late final http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('$base/chat/completions'),
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': 'Bearer ${config.apiKey.trim()}',
            },
            body: jsonEncode(payload),
          )
          .timeout(timeout);
    } on Exception {
      throw const LlmException('请求失败或超时：请检查接口地址、网络与模型名');
    }

    if (res.statusCode != 200) {
      throw LlmException(_statusMessage(
        res.statusCode,
        body: utf8.decode(res.bodyBytes, allowMalformed: true),
      ));
    }
    try {
      final decoded = jsonDecode(utf8.decode(res.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const LlmException('无法解析模型返回内容');
      }
      return decoded;
    } on LlmException {
      rethrow;
    } catch (_) {
      throw const LlmException('无法解析模型返回内容');
    }
  }

  /// 用当前选中模型发一条极短消息，端到端验证地址 / 密钥 / 模型名 / chat 路径。
  /// 不带 persona、不走检索；成功返回耗时，失败抛 [LlmException]。
  static Future<Duration> testConnection(LlmConfig config) async {
    final sw = Stopwatch()..start();
    final decoded = await _postChat(
      config,
      [
        {'role': 'user', 'content': '请只回复两个字：正常'}
      ],
      maxTokens: 16,
      timeout: const Duration(seconds: 30),
    );
    final choices = decoded['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const LlmException('端点未返回有效回答');
    }
    sw.stop();
    return sw.elapsed;
  }

  /// 判定 400 是否为「超出模型上下文窗口」。只做关键字匹配，不回显响应体。
  static bool isContextOverflow(String body) {
    final b = body.toLowerCase();
    return b.contains('context_length') ||
        b.contains('maximum context') ||
        b.contains('context window') ||
        b.contains('too many tokens') ||
        b.contains('prompt is too long');
  }

  /// 只暴露状态码含义，不回显响应体（响应体可能含密钥或用户输入）。
  static String _statusMessage(
    int code, {
    bool forModels = false,
    String body = '',
  }) {
    switch (code) {
      case 400:
        if (isContextOverflow(body)) {
          return '输入超出该模型的上下文上限：请换用上下文更大的模型（HTTP 400）';
        }
        return '请求被拒绝（HTTP 400）';
      case 401:
      case 403:
        return 'API Key 无效或无权限（HTTP $code）';
      case 404:
        return forModels
            ? '该地址不提供 /models，请手动填写模型名（HTTP 404）'
            : '接口地址不正确，未找到 /chat/completions（HTTP 404）';
      case 429:
        return '请求过于频繁或额度不足（HTTP 429）';
      default:
        if (code >= 500) return '服务端错误（HTTP $code）';
        return '请求被拒绝（HTTP $code）';
    }
  }
}
