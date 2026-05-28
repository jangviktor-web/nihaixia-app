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
