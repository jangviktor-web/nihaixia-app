// 最小验证测试：S17 删伪处方 + 耳穴条目计数
// 运行：flutter test test/acupuncture_erxue_test.dart
//
// ponytail: 原「erxue_jiangjie.md 可加载」用例已删——该 md 是 AI 未校对内容，
// 定位口径为 GB/T 13734-1992，与 assets/data/ear_points.json 的 2008 口径矛盾，
// 已从 app 与仓库中移除（2026-10-12）。
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('acupuncture.json 合法、总数=383、已删伪处方、耳穴条目=124', () async {
    final str = await rootBundle.loadString('assets/data/acupuncture.json');
    final data = jsonDecode(str) as Map<String, dynamic>;
    final cats = data['acupuncture']['categories'] as List<dynamic>;

    var total = 0;
    var erEntryCount = 0;
    var hasFake = false;
    for (final c in cats) {
      final entries = (c as Map<String, dynamic>)['entries'] as List<dynamic>;
      total += entries.length;
      for (final e in entries) {
        final sym = ((e as Map<String, dynamic>)['symptom'] as String?) ?? '';
        if (sym.contains('三焦逼毒法')) hasFake = true;
        final acu = (e['acupoints'] as List<dynamic>?) ?? <dynamic>[];
        if (acu.any((a) =>
            ((a as Map<String, dynamic>)['name'] as String).startsWith('耳穴:'))) {
          erEntryCount += 1;
        }
      }
    }

    expect(total, 383, reason: '删除 id=17 后总条目应为 383');
    expect(hasFake, isFalse, reason: '不应再存在 三焦逼毒法 伪处方');
    expect(erEntryCount, 124, reason: '含耳穴: 穴位的条目应为 124');
  });
}
