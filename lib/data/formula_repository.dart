import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/formula.dart';
import '../models/diagnosis.dart';

class FormulaRepository {
  static List<Formula>? _formulas;

  static Future<void> load() async {
    final jsonStr =
        await rootBundle.loadString('assets/data/formulas.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final list = data['formulas'] as List;
    _formulas = list.map((f) => Formula.fromJson(f)).toList();
  }

  static List<Formula> getAll() {
    return _formulas ?? [];
  }

  static Formula? getById(String id) {
    try {
      return _formulas!.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  static Formula? getByName(String name) {
    if (_formulas == null) return null;
    for (final f in _formulas!) {
      if (name.contains(f.name) || f.name.contains(name)) {
        return f;
      }
    }
    return null;
  }

  static List<Formula> search(String query) {
    if (_formulas == null) return [];
    final q = query.toLowerCase();
    return _formulas!.where((f) {
      return f.name.toLowerCase().contains(q) ||
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

    // 2. 别名匹配
    for (final f in _formulas!) {
      if (f.alias.isNotEmpty && engineName.contains(f.alias)) return f;
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

    return FormulaPrescription(
      formulaName: formula.name,
      components: components,
      dosage: formula.dosage,
      preparation: formula.preparation,
      contraindication: formula.contraindication,
      modifications: modifications,
    );
  }
}
