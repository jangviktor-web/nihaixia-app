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

/// Markdown 全文转繁体，但**链接 href 保持简体**。
///
/// `[当归](herb://当归)` 整体转换会变 `[當歸](herb://當歸)`，
/// 而查库用的是简体正名 → 点击失效。故转换后把 href 用 toSimplified 还原，
/// 锚文本仍为繁体。
Future<String> trMarkdown(String md) async {
  if (!traditionalDisplayOn || md.isEmpty) return md;
  try {
    final converted =
        await ChineseConverter.convert(md, S2T(), inBackground: true);
    return converted.replaceAllMapped(
        _mdLink, (m) => '[${m[1]}](${toSimplified(m[2]!)})');
  } catch (_) {
    // 插件不可用/极端文本 → 退回简体，不阻断阅读。
    return md;
  }
}
