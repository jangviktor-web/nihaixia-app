/// 倪师医案合并蒸馏表格（1257 例）数据模型与解析。
///
/// 原始表格为 markdown（assets/medical_cases/cases_table.md，12 列）。
/// 不在编译期展开为常量（避免 685KB 膨胀），改为运行时按行解析。
/// 内容属传统文化参考，非医疗建议。
///
/// 索引增强（批1）：
/// - [toSimplified] 简繁归一：繁体原文可被简体搜索命中；
/// - [MedicalCase.formulaNames] / [MedicalCase.herbNames]：方剂/药材索引，
///   供详情页可点跳转与后续相关医案/数据洞察；
/// - [extractKnownNames]：箭头分段 + 噪声清洗 + 长度降序非重叠匹配 + 去重。
library;

import 'chinese_convert.dart';
import 'disease_repository.dart';
import 'formula_repository.dart';
import 'herb_repository.dart';

/// 全局提取缓存：按方剂字段原文 memo，同文本不重算（全量 1113 例提取约 3.4s，
/// memo 后重复打开详情/洞察/相关医案命中缓存，避免反复卡顿）。
final Map<String, List<String>> _formulaNameCache = {};
final Map<String, List<String>> _herbNameCache = {};
final Map<String, List<String>> _diseaseNameCache = {};

/// 从方剂字段提取已知方剂名（简繁归一 + 箭头分段 + 噪声清洗 + 长度降序 + 去重）。
/// 返回命中的方剂名（FormulaRepository 正名）。按原文 memo 缓存，返回不可变列表。
List<String> extractFormulaNames(String formula) {
  return _formulaNameCache.putIfAbsent(formula, () {
    final candidates = FormulaRepository.getAll().map((f) => f.name).toList();
    return List.unmodifiable(
      extractKnownNames(formula, candidates, resolve: (c) => c),
    );
  });
}

/// 从方剂字段提取已知药材正名（精确 + 别名归一，不做模糊兜底，避免柴胡错跳）。
/// 返回命中的药材正名（HerbRepository 正名，别名经 canonicalOf 归一）。
/// 按原文 memo 缓存，返回不可变列表。
List<String> extractHerbNames(String formula) {
  return _herbNameCache.putIfAbsent(formula, () {
    final candidates = <String>{
      ...HerbRepository.getAll().map((h) => h.name),
      ...HerbRepository.aliasNames,
    }.toList();
    return List.unmodifiable(
      extractKnownNames(
        formula,
        candidates,
        resolve: (c) => HerbRepository.getExactByName(c)?.name,
      ),
    );
  });
}

/// 从文本抽取西医病名（简繁归一 + 箭头分段 + 噪声清洗 + 长度降序 + 去重）。
/// 候选来自 [DiseaseRepository]（正名 + 别名），命中经 [DiseaseRepository.resolveDisease]
/// 归一为正名。供医案「疾病栏」分类（diagnosis / western 合并抽取）。
/// 按原文 memo 缓存，返回不可变列表。
List<String> extractDiseaseNames(String text) {
  return _diseaseNameCache.putIfAbsent(text, () {
    final candidates = DiseaseRepository.candidates;
    return List.unmodifiable(
      extractKnownNames(text, candidates, resolve: DiseaseRepository.resolveDisease),
    );
  });
}

/// 已知名称提取引擎（供方剂/药材索引复用，亦便于断言脚本直接验证）：
/// 1. 按箭头（→ / ->）切分多段；
/// 2. 每段做噪声清洗（HT 成药号 /（科中）/ 步骤编号 / 剂付尾注）；
/// 3. 候选名按长度降序非重叠扫描（避免短名误吞长名，如「四逆汤」吞「茯苓四逆汤」）；
/// 4. [resolve] 返回 null 表示未收录（不记录）；返回非 null 为实际收录名（药材归一为正名）；
/// 5. 跨段结果去重（保持出现顺序）。
List<String> extractKnownNames(
  String rawText,
  List<String> candidates, {
  required String? Function(String candidate) resolve,
}) {
  final sorted = candidates
      .where((c) => c.length >= 2)
      .toSet()
      .toList()
    ..sort((a, b) => b.length.compareTo(a.length));
  if (sorted.isEmpty) return const [];

  final result = <String>[];
  final segments = rawText.split(RegExp(r'→|->'));
  for (final segRaw in segments) {
    final seg = _cleanFormulaSegment(toSimplified(segRaw));
    if (seg.isEmpty) continue;
    final used = List<bool>.filled(seg.length, false);
    for (final cand in sorted) {
      final norm = toSimplified(cand);
      if (norm.length > seg.length) continue;
      var idx = 0;
      while (true) {
        final start = seg.indexOf(norm, idx);
        if (start < 0) break;
        final end = start + norm.length;
        var overlapped = false;
        for (var k = start; k < end; k++) {
          if (used[k]) {
            overlapped = true;
            break;
          }
        }
        if (!overlapped) {
          final resolved = resolve(cand);
          if (resolved != null) {
            result.add(resolved);
            for (var k = start; k < end; k++) {
              used[k] = true;
            }
          }
        }
        idx = end;
      }
    }
  }

  final seen = <String>{};
  return result.where((r) => seen.add(r)).toList();
}

/// 方剂字段单段噪声清洗：HT 成药号、括号编号、（科中）尾注、步骤编号、剂付尾注。
String _cleanFormulaSegment(String seg) {
  var s = seg.trim();
  // HT 成药编号：HT-48 / HT48
  s = s.replaceAll(RegExp(r'HT[-－]?\d+'), '');
  // 括号编号：（1）（2）…（步骤标记）
  s = s.replaceAll(RegExp(r'[（(]\d+[）)]'), '');
  // （科中）尾注
  s = s.replaceAll(RegExp(r'[（(]\s*科中\s*[）)]'), '');
  // 步骤编号：仅段首 数字 + [.、．)）]（避免误删「6.5錢」中的小数「6.」）
  s = s.replaceAll(RegExp(r'^\d+[.、．)）]'), '');
  // 剂数/付数尾注：二剂/三付/貳付/5劑…
  s = s.replaceAll(RegExp(r'[一二三四五六七八九十百\d貳贰]+[剂劑付]'), '');
  return s.trim();
}

/// 相关医案：同方剂（共享 formulaNames）优先，按共享方剂数降序取最多 [max] 条；
/// 无方剂交集时回退同诊断（displayName 相同）。排除自身。
List<MedicalCase> findRelatedCases(
  MedicalCase c,
  List<MedicalCase> all, {
  int max = 6,
}) {
  if (all.isEmpty) return const [];
  final mine = c.formulaNames.toSet();
  if (mine.isNotEmpty) {
    final scored = <(MedicalCase, int)>[];
    for (final other in all) {
      if (other.seq == c.seq) continue;
      final shared = other.formulaNames.where(mine.contains).length;
      if (shared > 0) scored.add((other, shared));
    }
    scored.sort((a, b) {
      final byShared = b.$2.compareTo(a.$2);
      return byShared != 0 ? byShared : a.$1.seq.compareTo(b.$1.seq);
    });
    return scored.take(max).map((e) => e.$1).toList();
  }
  final name = c.displayName;
  if (name.isEmpty || name == '（未命名）') return const [];
  final same = all
      .where((o) => o.seq != c.seq && o.displayName == name)
      .toList()
    ..sort((a, b) => a.seq.compareTo(b.seq));
  return same.take(max).toList();
}

/// 医案「其他」哨兵：筛选栏中代表「无对应分类」的占位值（公开供筛选栏/列表页引用）。
/// - [kOtherMethod]：医案未出现任何经方方剂名（formulaNames 为空）→ 其他治法；
/// - [kOtherDisease]：医案未抽出任何西医病名（diagnosis/western 均未命中）→ 其他疾病。
const String kOtherMethod = '其他治法';
const String kOtherDisease = '其他疾病';

/// 医案列表组合过滤（搜索 + 年份 + 治法(方剂名) + 疾病(西医病名) + 视图），供列表页与断言复用。
/// [view]：null=全部 | 'fav'=收藏 | 'recent'=最近浏览；
/// [formula]：null=全部 | 具体经方方剂名 | [_kOtherMethod]=未出现方剂名；
/// [disease]：null=全部 | 具体西医病名 | [_kOtherDisease]=未抽出病名；
/// [favSeqs]/[recentSeqs] 需已按时间倒序传入，返回列表对 fav/recent 保持该顺序；
/// [yearOf] 缺省用内置年份提取（date 字段首个 19xx/20xx）。
List<MedicalCase> filterMedicalCases(
  List<MedicalCase> all, {
  String query = '',
  String? year,
  String? formula,
  String? disease,
  String? view,
  List<int> favSeqs = const [],
  List<int> recentSeqs = const [],
  String? Function(String date)? yearOf,
}) {
  final y = yearOf ?? _extractYear;
  final list = all.where((c) {
    if (query.isNotEmpty && !c.matches(query)) return false;
    if (year != null && y(c.date) != year) return false;
    if (formula != null) {
      if (formula == kOtherMethod) {
        if (c.formulaNames.isNotEmpty) return false;
      } else if (!c.formulaNames.contains(formula)) {
        return false;
      }
    }
    if (disease != null) {
      if (disease == kOtherDisease) {
        if (c.diseaseNames.isNotEmpty) return false;
      } else if (!c.diseaseNames.contains(disease)) {
        return false;
      }
    }
    if (view == 'fav' && !favSeqs.contains(c.seq)) return false;
    if (view == 'recent' && !recentSeqs.contains(c.seq)) return false;
    return true;
  }).toList();
  if (view == 'fav' || view == 'recent') {
    final seqs = view == 'fav' ? favSeqs : recentSeqs;
    final order = {for (var i = 0; i < seqs.length; i++) seqs[i]: i};
    list.sort((a, b) => (order[a.seq] ?? 0).compareTo(order[b.seq] ?? 0));
  }
  return list;
}

String? _extractYear(String date) {
  final m = RegExp(r'(19|20)\d{2}').firstMatch(date);
  return m?.group(0);
}

class MedicalCase {
  final int seq;
  final String date;
  final String patient;
  final String diagnosis; // 主要诊断（中医）
  final String mechanism; // 中医病因分析（关键病机）
  final String western; // 西医背景与观点
  final String formula; // 具体方剂剂量/治疗组成
  final String acupuncture; // 针灸方案
  final String method; // 中医治疗方法（原则）
  final String result; // 疗程/结果
  final String advice; // 生活医嘱
  final String view; // 倪海厦核心观点/评论

  MedicalCase({
    required this.seq,
    this.date = '',
    this.patient = '',
    this.diagnosis = '',
    this.mechanism = '',
    this.western = '',
    this.formula = '',
    this.acupuncture = '',
    this.method = '',
    this.result = '',
    this.advice = '',
    this.view = '',
  });

  /// 归一后的全文检索索引（简繁归一 + 小写），懒计算一次，供 [matches] 复用。
  late final String _searchNorm = toSimplified(
    '$diagnosis\n$formula\n$result\n$view\n$mechanism\n$patient',
  ).toLowerCase();

  /// 方剂索引：命中 FormulaRepository 的方剂名（简繁归一、去重、保持出现顺序）。
  late final List<String> formulaNames = extractFormulaNames(formula);

  /// 药材索引：命中 HerbRepository 的药材正名（精确+别名归一、去重、保持出现顺序）。
  late final List<String> herbNames = extractHerbNames(formula);

  /// 西医病名索引：合并抽取 [diagnosis] / [western] 中命中的西医病名
  /// （简繁归一、别名归一、去重、保持出现顺序）。空列表表示该医案未明确西医病名。
  late final List<String> diseaseNames = _mergeDiseaseNames(
    extractDiseaseNames(diagnosis),
    extractDiseaseNames(western),
  );

  /// 合并两组病名（union，去重，保持出现顺序），返回不可变列表。
  static List<String> _mergeDiseaseNames(List<String> a, List<String> b) {
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    final seen = <String>{};
    final out = <String>[];
    for (final n in a.followedBy(b)) {
      if (seen.add(n)) out.add(n);
    }
    return List.unmodifiable(out);
  }

  /// 全文检索命中（诊断/方剂/结果/观点/病机/患者）。
  /// 查询与字段均先 [toSimplified] 归一，繁体原文可被简体搜索命中。
  bool matches(String q) {
    if (q.isEmpty) return true;
    final qn = toSimplified(q).toLowerCase();
    return qn.isEmpty || _searchNorm.contains(qn);
  }

  /// 医案展示名：优先「主要诊断」，缺失时回退「中医病机」，再缺失显「（未命名）」。
  String get displayName {
    if (diagnosis.isNotEmpty) return diagnosis;
    if (mechanism.isNotEmpty) return mechanism;
    return '（未命名）';
  }

  /// 复制/分享格式化文本（参照 diagnosis.toCopyText 风格；空字段跳过）。
  String toShareText() {
    final buf = StringBuffer();
    final title = displayName == '（未命名）' ? '#$seq' : '#$seq  $displayName';
    buf.writeln('倪师医案 $title');
    buf.writeln('─────────────────');
    void section(String label, String value) {
      if (value.trim().isEmpty) return;
      buf.writeln('\n$label:');
      buf.write(value.trim());
    }

    section('诊断', diagnosis);
    section('病机', mechanism);
    section('方剂', formula);
    section('治法', method);
    section('结果', result);
    section('观点', view);
    buf.writeln('\n─────────────────');
    buf.write('汉唐中医 · 倪海厦六经辨证（传统文化参考，非医疗建议）');
    return buf.toString();
  }
}

/// 解析 markdown 表格文本为病例列表。
/// 跳过表头（首格「序号」）与分隔行（含 `---`），仅收录首格为数字的行。
/// 质量门禁：方剂为空 / 含「未公开」/ 占位「未提及」的医案直接剔除（无可用方剂）。
List<MedicalCase> parseMedicalCaseTable(String md) {
  final lines = md.split('\n');
  final cases = <MedicalCase>[];

  for (final raw in lines) {
    final line = raw.trim();
    if (!line.startsWith('|')) continue;

    // 按 | 切分后，仅去除首尾由外框竖线产生的空串；
    // 【保留内部空单元格】以维持 12 列对齐（中间列为空不应导致后续列左移）。
    final rawCells = line.split('|').map((c) => c.trim()).toList();
    if (rawCells.isNotEmpty && rawCells.first.isEmpty) rawCells.removeAt(0);
    if (rawCells.isNotEmpty && rawCells.last.isEmpty) rawCells.removeLast();
    final cells = rawCells;
    if (cells.isEmpty) continue;

    // 表头 / 分隔行
    if (cells[0] == '序号' ||
        cells[0].contains('---') ||
        RegExp(r'^-+$').hasMatch(cells[0])) {
      continue;
    }

    final seq = int.tryParse(cells[0]);
    if (seq == null) continue;

    // 补齐至 12 列，防止短行越界
    final padded = List<String>.from(cells);
    while (padded.length < 12) {
      padded.add('');
    }
    // 源表以「---」作为空值占位，归一为空串以便详情页隐藏
    for (var i = 0; i < padded.length; i++) {
      if (padded[i] == '---') padded[i] = '';
    }

    // 质量门禁：无可用方剂的医案剔除（空 / 未公开 / 未提及）
    final formula = padded[6];
    if (formula.trim().isEmpty) continue;
    if (formula.contains('未公开')) continue;
    if (formula.trim() == '未提及') continue;

    cases.add(MedicalCase(
      seq: seq,
      date: padded[1],
      patient: padded[2],
      diagnosis: padded[3],
      mechanism: padded[4],
      western: padded[5],
      formula: padded[6],
      acupuncture: padded[7],
      method: padded[8],
      result: padded[9],
      advice: padded[10],
      view: padded[11],
    ));
  }

  return cases;
}
