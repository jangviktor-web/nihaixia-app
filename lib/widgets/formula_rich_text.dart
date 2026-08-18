import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../data/chinese_convert.dart';
import '../data/formula_repository.dart';
import '../data/herb_repository.dart';
import '../models/formula.dart';
import '../models/herb.dart';

/// 方剂组成字段富文本：把正文中的已知方剂名/药材名渲染为可点链接。
/// 先 toSimplified 归一匹配，命中目标用仓库正名解析，文本按原文渲染，
/// 实现医案↔方剂/药材交叉跳转（繁体原文照常可点）。
///
/// 跳转行为通过 [onFormulaTap] / [onHerbTap] 回调交由调用方注入，
/// 保持 widgets → data/models 单向依赖（不反向 import 页面）。
class FormulaRichText extends StatefulWidget {
  final String formula;
  final ValueChanged<Formula>? onFormulaTap;
  final ValueChanged<Herb>? onHerbTap;
  const FormulaRichText({
    super.key,
    required this.formula,
    this.onFormulaTap,
    this.onHerbTap,
  });

  @override
  State<FormulaRichText> createState() => _FormulaRichTextState();
}

class _FormulaRichTextState extends State<FormulaRichText> {
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
    final spans = _buildSpans(widget.formula, base, linkStyle);
    return RichText(
      text: TextSpan(
        style: base.copyWith(fontSize: 14, height: 1.6),
        children: spans,
      ),
    );
  }

  /// 合并候选（方剂 + 药材别名），长度降序、同长方剂优先，非重叠扫描原文。
  List<InlineSpan> _buildSpans(String text, TextStyle base, TextStyle link) {
    final candidates = <({String name, bool isFormula})>[
      for (final f in FormulaRepository.getAll())
        if (f.name.length >= 2) (name: f.name, isFormula: true),
      for (final h in HerbRepository.getAll())
        if (h.name.length >= 2) (name: h.name, isFormula: false),
      for (final a in HerbRepository.aliasNames)
        if (a.length >= 2) (name: a, isFormula: false),
    ]..sort((a, b) {
        final byLen = b.name.length.compareTo(a.name.length);
        if (byLen != 0) return byLen;
        return (a.isFormula ? 0 : 1).compareTo(b.isFormula ? 0 : 1);
      });

    final norm = toSimplified(text);
    final used = List<bool>.filled(text.length, false);
    final hits = <({int start, int end, String name, bool isFormula})>[];
    for (final cand in candidates) {
      final name = toSimplified(cand.name);
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
          // 药材须精确+别名命中（不做模糊兜底，避免柴胡错跳含柴胡的方剂）
          final ok = cand.isFormula ||
              HerbRepository.getExactByName(cand.name) != null;
          if (ok) {
            hits.add((
              start: start,
              end: end,
              name: cand.name,
              isFormula: cand.isFormula,
            ));
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
        spans.add(TextSpan(text: text.substring(i, hit.start)));
      }
      final label = text.substring(hit.start, hit.end);
      final recognizer = TapGestureRecognizer()
        ..onTap = () {
          if (hit.isFormula) {
            final f = FormulaRepository.getByName(hit.name);
            if (f != null) widget.onFormulaTap?.call(f);
          } else {
            final h = HerbRepository.getExactByName(hit.name);
            if (h != null) widget.onHerbTap?.call(h);
          }
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
      spans.add(TextSpan(text: text.substring(i)));
    }
    return spans;
  }
}
