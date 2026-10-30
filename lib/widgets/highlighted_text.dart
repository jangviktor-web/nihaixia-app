import 'package:flutter/material.dart';

class HighlightedText extends StatelessWidget {
  final String text;
  final String query;
  final TextStyle? style;
  final Color? highlightColor;
  final int? maxLines;

  const HighlightedText({
    super.key,
    required this.text,
    required this.query,
    this.style,
    this.highlightColor,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // RichText 不继承 DefaultTextStyle：未显式给色的片段会回退到引擎默认色
    // （浅色模式下接近白色），搜索页的方剂 / 本草标题因此几乎看不清。
    // 这里把父级 DefaultTextStyle 与调用方 style 合并，并强制一个明确的基础色。
    final baseStyle = DefaultTextStyle.of(context)
        .style
        .merge(style)
        .copyWith(color: style?.color ?? cs.onSurface);

    if (query.isEmpty || text.isEmpty) {
      return Text(text,
          style: baseStyle,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis);
    }

    final color = highlightColor ?? cs.error;
    final spans = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int start = 0;

    while (start < text.length) {
      final index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(text: text.substring(start)));
        break;
      }
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ));
      start = index + query.length;
    }

    return RichText(
      text: TextSpan(children: spans, style: baseStyle),
      maxLines: maxLines ?? 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
