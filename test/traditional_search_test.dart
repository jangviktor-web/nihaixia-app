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
}
