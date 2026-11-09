import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/formula.dart';
import '../models/diagnosis.dart';
import 'chinese_convert.dart';

class FormulaRepository {
  static List<Formula>? _formulas;

  static Future<void> load() async {
    if (_formulas != null) return; // 幂等：重复调用跳过，避免重解析 + 防止与首次 late final 缓存竞争
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/formulas.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final list = data['formulas'] as List<dynamic>? ?? const [];
      _formulas = list.map((f) => Formula.fromJson(f)).toList();
    } catch (e, st) {
      debugPrint('[FormulaRepository] 加载 formulas.json 失败，降级为空：$e\n$st');
      _formulas = const [];
    }
  }

  static List<Formula> getAll() {
    return _formulas ?? [];
  }

  /// 可作为正文自动成链候选的方剂别名（异名、旧名、简称）。
  ///
  /// alias 字段混装了不止一类内容：
  /// 1. 真正的方名异写（白虎人参汤、抵挡汤、大黄蛰虫丸）；
  /// 2. 称号/合方描述（虫剂、群方之魁、回阳救逆第一方、苇茎汤加大承气汤）；
  /// 3. 治法/手法名（蜜煎导——「导法」外治之名，方是蜜煎方）；
  /// 4. 多写法串在一个字段里（桂附八味丸/金匮肾气丸）。
  /// 2、3、4 一旦进入候选词表，正文会被误链成方剂，故按下列规则过滤：
  /// ≥3 字、以剂型字（汤丸散膏丹煎）结尾、无括注/斜杠、不以其它正名开头、
  /// 不与任何正名重复（重复者已由正名候选覆盖）。
  ///
  /// 例外由 [_linkWhitelist] 手工维护。
  static List<String> get aliasNames {
    final all = _formulas;
    if (all == null) return const [];
    final names = {for (final f in all) f.name};
    final suffix = RegExp(r'[汤丸散膏丹煎]$');
    final out = <String>{};
    for (final f in all) {
      if (f.alias.isEmpty) continue;
      for (final raw in f.alias.split(',')) {
        final a = raw.trim();
        if (a.isEmpty) continue;
        final forced = _linkWhitelist.contains(a);
        // 长度、剂型字、括注三条规则可被白名单绕过；重复与前缀规则另判。
        if (!forced && a.length < 3) continue;
        if (!forced && !suffix.hasMatch(a)) continue;
        if (!forced && (a.contains('（') || a.contains('(') || a.contains('/'))) {
          continue;
        }
        if (names.contains(a)) continue;
        if (!forced && names.any(a.startsWith)) continue;
        out.add(a);
      }
    }
    return out.toList();
  }

  /// 必须成链的例外别名，可绕过「长度 ≥3」「剂型字结尾」「不以正名开头」三条规则。
  ///
  /// ① 加减方名（以正名开头，但仍是同一方）：
  ///    「木防己汤去石膏加茯苓芒硝汤」内含正名「木防己汤」，不放行则讲稿
  ///    clause_208 的 2 处会被错误链到「木防己汤」；
  ///    「桂枝汤去芍药方中加附子汤」同类（条文写法，见 clause_022）。
  /// ② 以「汤」以外的字收尾的方名写法：
  ///    「白通汤加猪胆汁」——clause_315:9、clause_315:15、clause_346:8 等处
  ///    不接「汤」字，不放行则这 3 处点不开（「白通汤加猪胆汁汤」已由正名
  ///    覆盖，长串优先，不会互相截断）。
  /// ③ 2 字简称：「白散」= 三物小白散（伤寒 141「白散亦可服」「白散方」）。
  ///    长度门槛 3 字本来是为了拦称号（如乌梅丸的「虫剂」），把这条真方名一起
  ///    挡了。已知代价：jingui/clause_084「张氏白散」是调侃侯氏黑散的戏称，
  ///    会误链到三物小白散 —— 1 处误链换 3 处正文可点，认了。
  ///    「鸡矢白散」「三物小白散」等更长写法由最长优先保证不被截断。
  ///
  /// ⛔ 不要把「蜜煎导」加进来：它是「导法」外治之名，不是方名
  ///    （方是蜜煎方，见伤寒 233 条「宜蜜煎导而通之」）。让它在正文里点开
  ///    方剂卡，等于把治法当方剂展示，与引擎侧 formula_rules.dart 的
  ///    「导法外治，不可攻下」口径冲突。它留在 alias 里只服务搜索命中。
  /// ⛔ 「苇茎汤加大承气汤」属合方描述，也不是例外。
  static const Set<String> _linkWhitelist = {
    '木防己汤去石膏加茯苓芒硝汤',
    '白通汤加猪胆汁汤',
    '白通汤加猪胆汁',
    '桂枝汤去芍药方中加附子汤',
    '白散',
  };

  static Formula? getById(String id) {
    try {
      return _formulas!.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  static Formula? getByName(String name) {
    if (_formulas == null) return null;
    // 1. 精确优先：避免长名被短名截胡（如点「茯苓四逆汤」误跳「四逆汤」页）
    for (final f in _formulas!) {
      if (f.name == name) return f;
    }
    // 2. 别名精确匹配：异体字/旧名（如「大黄蛰虫丸」）登记在 alias 字段，
    //    resolveFormula 早已支持，此处补齐 getByName 的 12 个调用方
    //    （chat / 书签 / 讲义详情 / LLM 服务 / 症状自查…），避免点开落空。
    for (final f in _formulas!) {
      if (f.alias.isEmpty) continue;
      for (final a in f.alias.split(',').map((e) => e.trim())) {
        if (a.isNotEmpty && a == name) return f;
      }
    }
    // 3. 模糊包含兜底
    for (final f in _formulas!) {
      if (name.contains(f.name) || f.name.contains(name)) {
        return f;
      }
    }
    return null;
  }

  static List<Formula> search(String query) {
    if (_formulas == null) return [];
    // 繁简归一：繁体输入（如「麻黃湯」）亦命中简体方名。
    final q = toSimplified(query).toLowerCase();
    return _formulas!.where((f) {
      return f.name.toLowerCase().contains(q) ||
          f.alias.toLowerCase().contains(q) ||
          f.indication.toLowerCase().contains(q) ||
          f.keywords.any((k) => k.toLowerCase().contains(q)) ||
          f.components.any((c) => c.name.toLowerCase().contains(q));
    }).toList();
  }

  static List<Formula> getByMeridian(String meridian) {
    if (_formulas == null) return [];
    return _formulas!.where((f) => f.meridian.contains(meridian)).toList();
  }

  static List<Formula> getByCategory(String category) {
    if (_formulas == null) return [];
    return _formulas!.where((f) => f.category == category).toList();
  }

  static List<String> getCategories() {
    if (_formulas == null) return [];
    final cats = _formulas!.map((f) => f.category).toSet().toList();
    cats.sort();
    return cats;
  }

  /// 4级匹配策略：精确 → 别名 → 斜杠分割 → 子串
  static Formula? resolveFormula(String engineName) {
    if (_formulas == null || engineName.isEmpty) return null;

    // 1. 精确匹配
    for (final f in _formulas!) {
      if (f.name == engineName) return f;
    }

    // 2. 别名匹配（别名以逗号分隔，逐一比对）
    for (final f in _formulas!) {
      if (f.alias.isEmpty) continue;
      final aliases = f.alias
          .split(',')
          .map((a) => a.trim())
          .where((a) => a.isNotEmpty);
      for (final a in aliases) {
        if (engineName == a ||
            engineName.contains(a) ||
            a.contains(engineName)) {
          return f;
        }
      }
    }

    // 3. 斜杠分割（取第一个匹配）
    if (engineName.contains('/')) {
      final first = engineName.split('/').first.trim();
      final found = resolveFormula(first);
      if (found != null) return found;
    }

    // 4. 子串匹配（长名包含短名）
    for (final f in _formulas!) {
      if (engineName.contains(f.name) && f.name.length >= 2) return f;
    }

    // 反向子串
    for (final f in _formulas!) {
      if (f.name.contains(engineName) && engineName.length >= 2) return f;
    }

    return null;
  }

  /// 构建完整处方
  static FormulaPrescription? buildPrescription(
    String formulaName, {
    List<FormulaModification>? modifications,
  }) {
    final formula = resolveFormula(formulaName);
    if (formula == null) return null;

    final components = formula.components
        .map((c) => PrescriptionComponent(
              name: c.name,
              dosage: c.dosage,
              role: c.role,
            ))
        .toList();

    // formulas.json 的 dosage 字段实际存储煎服法，每味药用量已在 components[].dosage
    // FIX: dosage 字段此前未填充（模型默认空串），导致 UI/测试处方剂量为空。
    return FormulaPrescription(
      formulaName: formula.name,
      components: components,
      dosage: formula.dosage,
      preparation: formula.dosage.isNotEmpty ? formula.dosage : formula.preparation,
      contraindication: formula.contraindication,
      modifications: modifications,
    );
  }
}
