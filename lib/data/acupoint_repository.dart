import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/acupoint_detail.dart';

class AcupointRepository {
  static List<AcupointDetail> _acupoints = [];
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    final jsonStr = await rootBundle.loadString('assets/data/acupoints.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final list = data['acupoints'] as List<dynamic>;
    _acupoints = list
        .map((e) => AcupointDetail.fromJson(e as Map<String, dynamic>))
        .toList();
    _loaded = true;
  }

  static List<AcupointDetail> getAll() => _acupoints;

  static AcupointDetail? findByName(String name) {
    // 精确匹配
    for (final a in _acupoints) {
      if (a.name == name) return a;
    }
    // 去掉"穴"后缀再匹配（如"关元"匹配"关元穴"）
    final stripped = name.replaceAll('穴', '');
    for (final a in _acupoints) {
      if (a.name.replaceAll('穴', '') == stripped) return a;
    }
    return null;
  }

  /// 别名/错字归一：将处方或临床心悟里出现的异名、错字映射回本库正名。
  /// 铁律：若 name 已是本库正名（findByName 命中），原样返回，
  /// 以避免误改处方方向A自身的关联（遵循神农本草经修复纪律）。
  static String canonicalOf(String name) {
    if (findByName(name) != null) return name; // 已是正名
    final stripped = name.replaceAll('穴', '');
    if (findByName(stripped) != null) return stripped; // 去后缀即正名
    final canon = _aliasMap[name] ?? _aliasMap[stripped];
    if (canon != null && findByName(canon) != null) return canon;
    return name;
  }

  /// 处方错字 → 正名（仅收录确属错字、且正名已在本库的条目）。
  static const Map<String, String> _aliasMap = {
    '中阳': '中脘', // 「中阳」为「中脘」之误，胃痛/急性胃痛主穴
  };

  /// 全部穴位名（去掉"穴"后缀），按长度降序，供详情页解析临床心悟中的处方组成。
  static List<String> get allNames => _allNamesCache ??= _buildAllNames();

  static List<String>? _allNamesCache;

  static List<String> _buildAllNames() {
    final set = <String>{};
    for (final a in _acupoints) {
      set.add(a.name.replaceAll('穴', ''));
    }
    final list = set.toList();
    list.sort((a, b) => b.length.compareTo(a.length)); // 最长优先，避免子串误配
    return list;
  }

  static List<AcupointDetail> search(String query) {
    if (query.isEmpty) return _acupoints;
    final q = query.toLowerCase();
    return _acupoints.where((a) {
      return a.name.toLowerCase().contains(q) ||
          a.meridian.toLowerCase().contains(q) ||
          a.description.toLowerCase().contains(q) ||
          a.location.toLowerCase().contains(q) ||
          a.clinicalNotes.toLowerCase().contains(q);
    }).toList();
  }

  static List<String> getMeridians() {
    final set = <String>{};
    for (final a in _acupoints) {
      if (a.meridian.isNotEmpty) set.add(a.meridian);
    }
    final list = set.toList()..sort();
    return list;
  }

  static List<AcupointDetail> getByMeridian(String meridian) {
    if (meridian == '全部') return _acupoints;
    return _acupoints.where((a) => a.meridian == meridian).toList();
  }

  static int get count => _acupoints.length;
}
