import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// 中文城市经纬度（WGS-84）数据模型。
///
/// 数据源：PyGeoCN（地级市多边形质心，CGCS2000≈WGS-84）为主 +
/// liaorui/geo-city（BD-09 已转 WGS-84）补充。用于紫微排盘「真太阳时」地点选择。
class CityLocation {
  final String name; // 中文名（如 北京市）
  final String province; // 省份（如 北京市），可能为空
  final double lng; // 经度（东经，WGS-84）
  final double lat; // 纬度（北纬，WGS-84）

  const CityLocation({
    required this.name,
    required this.province,
    required this.lng,
    required this.lat,
  });

  /// 展示名：带省份括号，便于在列表区分同名。
  String get displayName =>
      province.isNotEmpty ? '$name（$province）' : name;

  @override
  String toString() => displayName;
}

/// 中文城市经纬度检索服务（单例缓存）。
class CityLocationService {
  CityLocationService._();

  static List<CityLocation>? _cache;
  static bool _loaded = false;

  /// 从内置 JSON 资源加载并缓存（幂等，可重复调用）。
  static Future<List<CityLocation>> load() async {
    if (_loaded && _cache != null) return _cache!;
    final raw = await rootBundle
        .loadString('assets/data/china_cities.json');
    _cache = parseJson(raw);
    _loaded = true;
    return _cache!;
  }

  /// 纯解析（不依赖资源系统，便于测试注入）。
  static List<CityLocation> parseJson(String raw) {
    final list = jsonDecode(raw) as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return CityLocation(
        name: m['name'] as String,
        province: (m['province'] as String?) ?? '',
        lng: (m['lng'] as num).toDouble(),
        lat: (m['lat'] as num).toDouble(),
      );
    }).toList();
  }

  /// 在已加载列表内按中文名/省份模糊搜索。
  /// [query] 为空返回前 [limit] 条（便于浏览全部）。
  static List<CityLocation> searchIn(
    List<CityLocation> all,
    String query, [
    int limit = 80,
  ]) {
    final q = query.trim();
    if (q.isEmpty) return all.take(limit).toList();
    return all
        .where((c) => c.name.contains(q) || c.province.contains(q))
        .take(limit)
        .toList();
  }

  /// 便捷封装：基于已加载缓存搜索（未加载时返回空）。
  static List<CityLocation> search(String query, [int limit = 80]) =>
      searchIn(_cache ?? const [], query, limit);
}
