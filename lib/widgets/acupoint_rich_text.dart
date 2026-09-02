import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/chinese_convert.dart';
import '../data/acupoint_repository.dart';
import '../models/acupoint_detail.dart';

/// 针灸方案字段富文本：把正文中的已知穴位名渲染为可点链接。
/// 先 toSimplified 归一匹配，命中目标用仓库正名解析，文本按原文渲染，
/// 实现医案 ↔ 穴位详情交叉跳转（繁体原文照常可点）。
///
/// 跳转行为通过 [onAcupointTap] 回调交由调用方注入，
/// 保持 widgets → data/models 单向依赖（不反向 import 页面）。
class AcupointRichText extends StatefulWidget {
  final String text;
  final ValueChanged<AcupointDetail>? onAcupointTap;
  const AcupointRichText({
    super.key,
    required this.text,
    this.onAcupointTap,
  });

  @override
  State<AcupointRichText> createState() => _AcupointRichTextState();
}

class _AcupointRichTextState extends State<AcupointRichText> {
  /// 持有本次构建创建的 recognizer，dispose 时统一释放（避免每次 build 新建泄漏）。
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 清理上次构建的 recognizer（State 复用、父级刷新时避免累积泄漏）
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final base = DefaultTextStyle.of(context).style;
    final cs = Theme.of(context).colorScheme;
    final linkStyle = TextStyle(
      color: cs.primary,
      decoration: TextDecoration.underline,
      fontSize: 14,
      height: 1.6,
    );
    final spans = _buildSpans(widget.text, base, linkStyle);
    return RichText(
      text: TextSpan(
        // 显式设置 onSurface，避免 [RichText] 不继承 [DefaultTextStyle] 颜色时
        // 在某些环境回退为白色（浅色模式下不可读）。
        style: base.copyWith(
          fontSize: 14,
          height: 1.6,
          color: cs.onSurface,
        ),
        children: spans,
      ),
    );
  }

  /// 候选穴位名（含「穴」后缀与去后缀两种形态），长度降序、非重叠扫描原文。
  List<InlineSpan> _buildSpans(String text, TextStyle base, TextStyle link) {
    final candidates = <String>[
      for (final a in AcupointRepository.getAll()) a.name,
      for (final a in AcupointRepository.getAll()) a.name.replaceAll('穴', ''),
    ]..removeWhere((n) => n.length < 2)
     ..sort((a, b) => b.length.compareTo(a.length));

    final norm = toSimplified(text);
    final used = List<bool>.filled(text.length, false);
    final hits = <({int start, int end, String name})>[];
    for (final cand in candidates) {
      final name = toSimplified(cand);
      if (name.length > norm.length) continue;
      var idx = 0;
      while (true) {
        final start = norm.indexOf(name, idx);
        if (start < 0) break;
        final end = start + name.length;
        var overlapped = false;
        for (var k = start; k < end; k++) {
          if (used[k]) {
            overlapped = true;
            break;
          }
        }
        if (!overlapped) {
          // 仅当仓库确有该穴位时才链接（不做模糊兜底，避免普通词误跳）。
          final ok = AcupointRepository.findByName(cand) != null;
          if (ok) {
            hits.add((start: start, end: end, name: cand));
            for (var k = start; k < end; k++) {
              used[k] = true;
            }
          }
        }
        idx = end;
      }
    }
    hits.sort((a, b) => a.start.compareTo(b.start));

    final spans = <InlineSpan>[];
    var i = 0;
    for (final hit in hits) {
      if (hit.start > i) {
        spans.addAll(_spansWithBold(text.substring(i, hit.start), base));
      }
      final label = text.substring(hit.start, hit.end);
      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          final a = AcupointRepository.findByName(label);
          if (a != null) widget.onAcupointTap?.call(a);
        };
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: label,
          style: link,
          recognizer: recognizer,
        ),
      );
      i = hit.end;
    }
    if (i < text.length) {
      spans.addAll(_spansWithBold(text.substring(i), base));
    }
    return spans;
  }

  /// 把正文中的 `**加粗**` 解析为加粗 TextSpan（星号不再显示）。
  /// 仅作用于普通文本段；穴位链接段保持自身样式。
  List<InlineSpan> _spansWithBold(String text, TextStyle style) {
    final result = <InlineSpan>[];
    final re = RegExp(r'\*\*(.+?)\*\*');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) {
        result.add(TextSpan(text: text.substring(last, m.start)));
      }
      result.add(TextSpan(
        text: m.group(1),
        style: style.copyWith(fontWeight: FontWeight.bold),
      ));
      last = m.end;
    }
    if (last < text.length) {
      result.add(TextSpan(text: text.substring(last)));
    }
    if (result.isEmpty) result.add(TextSpan(text: text));
    return result;
  }
}
