import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/formula_oral_hint.dart';

/// 方剂口语语料仓库（只读，进程内单例缓存）。
///
/// 语料未加载时所有查询返回 null，匹配器据此退化为原有纯字面匹配，
/// 因此资源缺失不会导致辨证失败（向后兼容底线）。
class FormulaOralHintRepository {
  static Map<String, FormulaOralHint>? _hints;

  /// 幂等：重复调用跳过，避免重解析 + 防止与首次缓存竞争
  /// （沿用 FormulaRepository 的写法，规避 `late final` 竞态坑）。
  static Future<void> load() async {
    if (_hints != null) return;
    final jsonStr =
        await rootBundle.loadString('assets/data/formula_oral_hints.json');
    final data = json.decode(jsonStr) as Map<String, dynamic>;
    final raw = data['hints'] as Map<String, dynamic>? ?? {};
    _hints = raw.map(
      (id, value) =>
          MapEntry(id, FormulaOralHint.fromJson(id, value as Map<String, dynamic>)),
    );
  }

  /// 按方剂 id 取语料；未加载或无该方剂时返回 null。
  static FormulaOralHint? getById(String id) => _hints?[id];

  /// 已加载的语料条数（未加载为 0）。
  static int get count => _hints?.length ?? 0;

  /// 是否已加载完成。
  static bool get isLoaded => _hints != null;
}
