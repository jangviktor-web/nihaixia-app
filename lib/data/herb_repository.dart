import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/herb.dart';

class HerbRepository {
  static List<Herb> _herbs = [];
  static bool _loaded = false;

  // 现代药名 → 神农本草经古名 映射（仅目标在本草库中存在的）
  static const _aliasMap = {
    '桂枝': '牡桂',
    '白芍': '芍药',
    '赤芍': '芍药',
    '杏仁': '杏核仁',
    '熟地': '熟地黄',
    '生地': '干地黄',
    '丹皮': '牡丹',
    '乌梅': '梅实',
    '川芎': '芎穷',
    '芒硝': '朴消',
    '香豉': '豆豉',
    '黄柏': '檗木',
    '黄芪': '黄耆',
    '桃仁': '桃核仁',
    '山药': '署豫',
    '柴胡': '茈胡',
    '麻仁': '麻子仁',
    '饴糖': '胶饴',
  };

  static Future<void> load() async {
    if (_loaded) return;
    final data = await rootBundle.loadString('assets/data/herbs.json');
    final map = json.decode(data) as Map<String, dynamic>;
    final list = map['herbs'] as List<dynamic>;
    _herbs = list.map((e) => Herb.fromJson(e as Map<String, dynamic>)).toList();
    _loaded = true;
  }

  static List<Herb> getAll() => List.unmodifiable(_herbs);

  static List<Herb> getByCategory(String category) {
    if (category == '全部') return getAll();
    return _herbs.where((h) => h.category == category).toList();
  }

  static List<Herb> search(String query) {
    if (query.isEmpty) return [];
    final q = query.toLowerCase();
    return _herbs.where((h) {
      return h.name.contains(q) ||
          (h.action?.contains(q) ?? false) ||
          (h.nature?.contains(q) ?? false) ||
          (h.original?.contains(q) ?? false) ||
          (h.flavor.contains(q)) ||
          h.category.contains(q) ||
          h.meridians.any((m) => m.contains(q));
    }).toList();
  }

  static Herb? getByName(String name) {
    // 先直接匹配
    try {
      return _herbs.firstWhere((h) => h.name == name);
    } catch (_) {}
    // 再用别名映射
    final mapped = _aliasMap[name];
    if (mapped != null) {
      try {
        return _herbs.firstWhere((h) => h.name == mapped);
      } catch (_) {}
    }
    // 模糊匹配
    for (final h in _herbs) {
      if (h.name.contains(name) || name.contains(h.name)) {
        return h;
      }
    }
    return null;
  }

  static List<String> getCategories() {
    final cats = _herbs.map((h) => h.category).toSet().toList();
    cats.sort();
    return ['全部', ...cats];
  }

  static List<String> getNatureCategories() {
    return ['全部', '寒', '凉', '平', '温', '热'];
  }

  static List<Herb> getByNature(String nature) {
    if (nature == '全部') return getAll();
    return _herbs.where((h) => h.natureCategory == nature).toList();
  }
}
