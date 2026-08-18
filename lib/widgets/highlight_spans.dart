import 'package:flutter/material.dart';

import '../data/chinese_convert.dart';

/// 关键词高亮（简繁归一版）：先 toSimplified 归一对齐，逐字符找命中区间，
/// 高亮落回原文位置（繁体原文被简体关键词命中时，高亮落在原文对应字符上）。
/// 命中片段用 primary 色 + 加粗；无命中或空查询时返回原文单段。
List<InlineSpan> highlightSpans(
  BuildContext context,
  String text,
  String query,
  TextStyle base,
) {
  final cs = Theme.of(context).colorScheme;
  final hl = base.copyWith(color: cs.primary, fontWeight: FontWeight.bold);
  if (query.isEmpty || text.isEmpty) {
    return [TextSpan(text: text, style: base)];
  }
  final normText = toSimplified(text).toLowerCase();
  final normQuery = toSimplified(query).toLowerCase();
  if (normQuery.isEmpty) return [TextSpan(text: text, style: base)];
  final mask = List<bool>.filled(text.length, false);
  var idx = 0;
  while (true) {
    final start = normText.indexOf(normQuery, idx);
    if (start < 0) break;
    final end = start + normQuery.length;
    for (var k = start; k < end && k < mask.length; k++) {
      mask[k] = true;
    }
    idx = end;
  }
  final spans = <InlineSpan>[];
  var i = 0;
  while (i < text.length) {
    if (!mask[i]) {
      var j = i;
      while (j < text.length && !mask[j]) {
        j++;
      }
      spans.add(TextSpan(text: text.substring(i, j), style: base));
      i = j;
    } else {
      var j = i;
      while (j < text.length && mask[j]) {
        j++;
      }
      spans.add(TextSpan(text: text.substring(i, j), style: hl));
      i = j;
    }
  }
  return spans;
}
