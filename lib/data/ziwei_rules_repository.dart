import 'dart:convert';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';

/// 紫微解读层可配置规则仓库（只读，进程内单例缓存）。
///
/// ## 设计底线：绝不因本仓库导致负优化
/// 解读层原本使用编译期常量，零 I/O。外置为 JSON 后引入了一个失败路径，
/// 因此本仓库保证：**JSON 缺失 / 未加载 / 字段异常 / 解析失败时，
/// 一律回退到与代码内建完全一致的默认值**，解读层输出与改动前逐字相同。
///
/// 由此带来两个直接好处：
/// 1. 单元测试无需加载资源即可运行（走默认值），现有测试零改动仍然通过；
/// 2. 线上即便资源打包遗漏，也只会退回既有行为，不会崩溃或输出空文案。
///
/// 幂等：`load()` 用 `_attempted` 标志守卫，重复调用直接返回，
/// 规避 `late final` 竞态（沿用 FormulaRepository / FormulaOralHintRepository 写法）。
class ZiweiRulesRepository {
  static List<String>? _huajiByStem;
  static Map<int, String>? _palaceBodyMap;
  static bool _attempted = false;

  // -------------------------------------------------------------------------
  // 内建默认值（与外置前 ziwei_interpretation.dart 中的常量逐字一致）
  // -------------------------------------------------------------------------

  /// 流年化忌表：索引 0-9 = 甲乙丙丁戊己庚辛壬癸。
  /// 已用 iztro-py 引擎独立校验 10/10 匹配（见 tools/ziwei_oracle/oracle.py）。
  static const List<String> defaultHuajiByStem = [
    '太阳', // 甲
    '太阴', // 乙
    '廉贞', // 丙
    '巨门', // 丁
    '天机', // 戊
    '文曲', // 己
    '天同', // 庚
    '文昌', // 辛
    '武曲', // 壬
    '贪狼', // 癸
  ];

  /// 身体映射：物理地支索引 0-11 → 脏腑系统。
  /// 口径为「地支/中医藏象」，非紫微「十二宫→脏腑」固定口径。
  static const Map<int, String> defaultPalaceBodyMap = {
    0: '膀胱、耳、生殖泌尿系统',
    1: '脾胃、腹部',
    2: '胆、手、肺',
    3: '肝、十指、神经系统',
    4: '胃、胸、消化系统',
    5: '心、咽喉',
    6: '心、眼、小肠',
    7: '脾胃、腹部',
    8: '肺、大肠、呼吸道',
    9: '肺、皮肤、呼吸道',
    10: '命门、腿足',
    11: '肾、头、膀胱',
  };

  /// 加载外置规则。失败时静默降级为默认值（仅 debug 日志提示）。
  static Future<void> load() async {
    if (_attempted) return; // 幂等：避免重复解析与竞态
    _attempted = true;
    try {
      final jsonStr =
          await rootBundle.loadString('assets/data/ziwei_rules.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;

      final huaji = data['huaji_by_stem'];
      if (huaji is List && huaji.length == defaultHuajiByStem.length) {
        _huajiByStem = huaji.map((e) => e.toString()).toList();
      } else {
        debugPrint('[ZiweiRules] huaji_by_stem 缺失或长度异常，使用内建默认值');
      }

      final bodyMap = data['palace_body_map'];
      if (bodyMap is Map) {
        final parsed = <int, String>{};
        bodyMap.forEach((key, value) {
          final idx = int.tryParse(key.toString());
          if (idx != null && value != null) parsed[idx] = value.toString();
        });
        if (parsed.isNotEmpty) {
          _palaceBodyMap = parsed;
        } else {
          debugPrint('[ZiweiRules] palace_body_map 为空，使用内建默认值');
        }
      } else {
        debugPrint('[ZiweiRules] palace_body_map 缺失，使用内建默认值');
      }
    } catch (e) {
      // 资源缺失或 JSON 解析失败：保持 null，全部走默认值。
      // 此处的静默降级是刻意的——解读层必须永远可用。
      debugPrint('[ZiweiRules] 加载失败，使用内建默认值: $e');
    }
  }

  /// 流年化忌表（未加载时返回内建默认值）。
  static List<String> get huajiByStem => _huajiByStem ?? defaultHuajiByStem;

  /// 取某物理地支索引对应的身体部位；未知索引或缺失时回退默认值。
  static String bodyPartFor(int palaceIndex) =>
      _palaceBodyMap?[palaceIndex] ??
      defaultPalaceBodyMap[palaceIndex] ??
      '相关身体部位';

  /// 是否成功加载了外置规则（false 表示正在使用内建默认值）。
  static bool get isLoaded => _huajiByStem != null || _palaceBodyMap != null;

  /// 供测试断言使用：重置为未加载状态。
  static void resetForTest() {
    _huajiByStem = null;
    _palaceBodyMap = null;
    _attempted = false;
  }
}
