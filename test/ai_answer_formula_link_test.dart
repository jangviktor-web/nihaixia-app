import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/screens/markdown_doc_screen.dart';

/// 「问倪师AI」回答走的是 injectInternalLinks（Markdown 注入），
/// 与正文 FormulaRichText 是两条独立链路。2026-11-09 P0 批次补的方剂异写
/// 必须两条链路都能成链、且链到**正确**的方剂（不能被短正名截胡）。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 异写 → 库内正名（2026-11-09 P0 批次，20 组）
  const pairs = <String, String>{
    '旋复花代赭石汤': '旋覆代赭石汤',
    '旋复花汤': '旋覆花汤',
    '木防己汤去石膏加茯苓芒硝汤': '木防己去石膏加茯苓芒硝汤',
    '桔皮汤': '橘皮汤',
    '白通汤加猪胆汁汤': '白通加猪胆汁汤',
    '白通汤加猪胆汁': '白通加猪胆汁汤',
    '防己黄耆汤': '防己黄芪汤',
    '黄耆建中汤': '黄芪建中汤',
    '黄耆桂枝五物汤': '黄芪桂枝五物汤',
    '桂枝加黄耆汤': '桂枝加黄芪汤',
    '桂枝龙骨牡蛎汤': '桂枝加龙骨牡蛎汤',
    '麻仁丸': '麻子仁丸',
    '百合鸡子汤': '百合鸡子黄汤',
    '赤小豆当归散': '赤豆当归散',
    '八味肾气丸': '肾气丸',
    '桂附八味丸': '肾气丸',
    '金匮肾气丸': '肾气丸',
    '耆芍桂酒汤': '黄芪芍药桂枝苦酒汤',
    '桂枝汤去芍药方中加附子汤': '桂枝去芍药加附子汤',
    '甘草干姜苓术汤': '甘草干姜茯苓白术汤',
    '桂枝加厚朴杏子汤': '桂枝加厚朴杏仁汤',
    '麻黄杏仁甘草石膏汤': '麻杏甘石汤',
    '麻黄杏子甘草石膏汤': '麻杏甘石汤',
  };

  /// 抽出 markdown 里所有 formula:// 链接名（已解码）。
  List<String> hrefNames(String md) => RegExp(r'\(formula://([^)]+)\)')
      .allMatches(md)
      .map((m) => decodeMarkdownHref(m.group(1)!))
      .toList();

  test('AI 回答中的方剂异写：成链且链到正确方剂', () async {
    await FormulaRepository.load();
    final noLink = <String>[];
    final wrong = <String>[];
    for (final e in pairs.entries) {
      final names = hrefNames(injectInternalLinks('倪师说，${e.key}主之。'));
      if (names.isEmpty) {
        noLink.add('${e.key} → ${e.value}');
        continue;
      }
      final resolved = names.map((n) => FormulaRepository.getByName(n)?.name).toList();
      if (!resolved.contains(e.value)) {
        wrong.add('${e.key} → 期望 ${e.value}，实际链到 $resolved');
      }
    }
    expect(noLink, isEmpty, reason: '未成链：\n${noLink.join('\n')}');
    expect(wrong, isEmpty, reason: '链错方剂：\n${wrong.join('\n')}');
  });

  test('AI 回答中的方剂异写：点击能解析到方剂（跳转不落空）', () async {
    await FormulaRepository.load();
    final bad = <String>[];
    for (final e in pairs.entries) {
      final got = FormulaRepository.getByName(e.key)?.name;
      if (got != e.value) bad.add('${e.key} → 期望 ${e.value}，实际 ${got ?? 'null'}');
    }
    expect(bad, isEmpty, reason: '跳转落空/错方：\n${bad.join('\n')}');
  });

  test('繁体输入仍能命中（搜索走 toSimplified 归一）', () async {
    await FormulaRepository.load();
    for (final q in const ['防己黃耆湯', '麻黃杏仁甘草石膏湯', '桂枝龍骨牡蠣湯']) {
      expect(FormulaRepository.search(q), isNotEmpty, reason: '$q 应有结果');
    }
  });

  // 模型可能用繁体作答（prompt 未约束语体）。候选集是简体，故 injectInternalLinks
  // 在「转简文本」上定位、用原文切片做锚文本：繁体也能成链，且字形不被改写。
  test('模型以繁体作答时同样成链，锚文本保留繁体', () async {
    await FormulaRepository.load();
    const cases = <String, String>{
      '黃耆建中湯': '黄芪建中汤',
      '防己黃耆湯': '防己黄芪汤',
      '桂枝龍骨牡蠣湯': '桂枝加龙骨牡蛎汤',
      '麻黃杏仁甘草石膏湯': '麻杏甘石汤',
      '赤小豆當歸散': '赤豆当归散',
      '旋復花代赭石湯': '旋覆代赭石汤',
    };
    for (final e in cases.entries) {
      final md = injectInternalLinks('倪師說，${e.key}主之。');
      expect(md, contains('[${e.key}](formula://'), reason: '${e.key} 应成链且锚文本保留繁体');
      final targets = RegExp(r'\(formula://([^)]+)\)')
          .allMatches(md)
          .map((m) => FormulaRepository.getByName(decodeMarkdownHref(m.group(1)!))?.name)
          .toList();
      expect(targets, contains(e.value), reason: '${e.key} 应链到 ${e.value}，实际 $targets');
    }
  });
}
