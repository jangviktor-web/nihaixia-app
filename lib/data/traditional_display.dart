import 'package:flutter_open_chinese_convert/flutter_open_chinese_convert.dart';

import 'chinese_convert.dart';
import 'settings_repository.dart';

/// 内容页「繁体显示」统一入口（阅读页 / 药材详情 / 方剂详情共用）。
///
/// 只转**内容文本**（正文、主治、原文、解释等），不转界面骨架文案——
/// 界面文案是硬编码简体，要转得走 i18n 层，成本远大于收益（简体界面繁体用户可读）。
///
/// ponytail: 单层 Map 缓存即可（内容文本只读、量小、进程内复用）；
/// 若将来要转整库长文再换 LRU 或落盘缓存。
final Map<String, String> _cache = {};

bool get traditionalDisplayOn =>
    SettingsRepository.instance.traditionalDisplayEnabled;

/// 单条文本转换（带缓存）。开关关闭 / 空串 / 转换异常 → 原样返回。
Future<String> trText(String text) async {
  if (!traditionalDisplayOn || text.isEmpty) return text;
  final hit = _cache[text];
  if (hit != null) return hit;
  try {
    final r = await ChineseConverter.convert(text, S2T(), inBackground: true);
    return _cache[text] = r;
  } catch (_) {
    return text;
  }
}

/// 批量转换：详情页初始化时一次转完，渲染期用返回值同步取（避免每帧 await）。
Future<Map<String, String>> trTexts(Iterable<String?> texts) async {
  final out = <String, String>{};
  for (final t in texts) {
    if (t == null || t.isEmpty) continue;
    out[t] = await trText(t);
  }
  return out;
}

final RegExp _mdLink = RegExp(r'\[([^\]]*)\]\(([^)]*)\)');

/// Markdown 全文转繁体，但**链接 href 原样保留**。
///
/// 旧做法是「整段转繁后，再把 href 用 [toSimplified] 还原」。问题在于：
/// 转繁用的是 OpenCC 全量字典，而还原只靠 497 条手工表 —— 两个方向覆盖不对等。
/// OpenCC 能转出的字体（蘭/宮/華/礬/歡/蓋/釐/鹽/燒/蝟…）大多不在表内，
/// 于是 `herb://泽兰` 变成 `herb://澤蘭` 后还原不了，点击落空、繁体搜索也搜不到。
///
/// 现改为：转换前把 href 换成纯 ASCII 占位符，转换后原样还原 ——
/// **完全不依赖繁简映射表**，表再缺字也不会断链。
Future<String> trMarkdown(String md) async {
  if (!traditionalDisplayOn || md.isEmpty) return md;
  try {
    final hrefs = <String>[];
    final shielded = md.replaceAllMapped(_mdLink, (m) {
      hrefs.add(m[2]!);
      return '[${m[1]}](__PH${hrefs.length - 1}__)';
    });
    final converted =
        await ChineseConverter.convert(shielded, S2T(), inBackground: true);
    var i = 0;
    return converted.replaceAllMapped(_mdLink, (m) {
      if (i >= hrefs.length) return m[0]!;
      return '[${m[1]}](${hrefs[i++]})';
    });
  } catch (_) {
    // 插件不可用/极端文本 → 退回简体，不阻断阅读。
    return md;
  }
}

/// 检索用查询词归一（繁体 → 简体）。
///
/// 优先走原生 OpenCC `T2S()`：覆盖全量繁体字，不受 497 条手工表限制，
/// 于是「澤蘭」「合歡」这类表外字也能命中简体索引。
/// 插件不可用（单元测试 / isolate 失败）时退回 [toSimplified]，
/// 保证「當歸」「麻黃湯」这类表内字仍可命中。
Future<String> normalizeQuery(String query) async {
  final q = query.trim();
  if (q.isEmpty) return q;
  try {
    return await ChineseConverter.convert(q, T2S(), inBackground: false);
  } catch (_) {
    return toSimplified(q);
  }
}
