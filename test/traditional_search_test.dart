// 繁体输入命中简体内容（2026-11-04 加）。
//
// 背景：内容库已统一为简体（医案整文件转简、条文卡异体字规范、其余本就简体），
// 但三处检索入口此前只用原样字符串匹配 → 繁体用户输入「當歸」「麻黃湯」返回空。
// 修法：三个入口的**查询词**过 chinese_convert.toSimplified（索引正文构建期已简化，
// 故不必逐条归一，O(query) 开销）。
//
// 运行：
//   TEMP="C:/Users/jangviktor/AppData/Local/Temp" TMP="C:/Users/jangviktor/AppData/Local/Temp" \
//     /d/flutter/bin/flutter test test/traditional_search_test.dart
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/data/chinese_convert.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/data/herb_repository.dart';
import 'package:nihaisha_app/services/classic_search_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('药材检索：繁体「當歸」命中 当归', () async {
    await HerbRepository.load();
    final names = HerbRepository.search('當歸').map((h) => h.name).toList();
    expect(names, contains('当归'), reason: '繁体查询应命中简体药名，实际：$names');
  });

  test('方剂检索：繁体「麻黃湯」命中 麻黄汤', () async {
    await FormulaRepository.load();
    final names = FormulaRepository.search('麻黃湯').map((f) => f.name).toList();
    expect(names, contains('麻黄汤'), reason: '繁体查询应命中简体方名，实际：$names');
  });

  test('经典全文检索：繁体「當歸」有结果', () async {
    final r = await ClassicSearchService.search('當歸');
    expect(r.total, greaterThan(0), reason: '繁体查询应在经典索引中命中');
  });

  // ── 表外字回归（2026-11-05 繁简审计）──
  // 下面这些字的繁体原本不在 497 条手工表内，导致繁体模式下搜索为空、
  // 条文卡内点击无反应。已补映射 + classic 检索改走原生 T2S。
  test('药材检索：表外字「澤蘭」命中 泽兰', () async {
    await HerbRepository.load();
    final names = HerbRepository.search('澤蘭').map((h) => h.name).toList();
    expect(names, contains('泽兰'), reason: '表外字繁体也应命中，实际：$names');
  });

  test('药材检索：表外字「合歡」命中 合欢', () async {
    await HerbRepository.load();
    final names = HerbRepository.search('合歡').map((h) => h.name).toList();
    expect(names, contains('合欢'), reason: '表外字繁体也应命中，实际：$names');
  });

  test('方剂检索：表外字「七釐散」命中 七厘散', () async {
    await FormulaRepository.load();
    final names = FormulaRepository.search('七釐散').map((f) => f.name).toList();
    expect(names, contains('七厘散'), reason: '表外字繁体也应命中，实际：$names');
  });

  test('经典全文检索：表外字「礬石」有结果', () async {
    final r = await ClassicSearchService.search('礬石');
    expect(r.total, greaterThan(0), reason: '表外字繁体应在经典索引中命中');
  });

  // 核心词回归：原手工表连「傷」都没收，toSimplified('傷寒') 原样返回，
  // 繁体用户搜「傷寒」永远搜不到。现映射表由 OpenCC 全量生成（3786 条）。
  test('逐字归一：核心词「傷寒」→「伤寒」', () {
    expect(toSimplified('傷寒'), '伤寒');
    expect(toSimplified('傷寒論'), '伤寒论');
    expect(toSimplified('太陽病'), '太阳病');
  });

  test('经典全文检索：繁体「傷寒」有结果', () async {
    final r = await ClassicSearchService.search('傷寒');
    expect(r.total, greaterThan(0), reason: '核心词繁体必须能命中');
  });
}
