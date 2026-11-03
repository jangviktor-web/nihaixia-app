// 金匮书面版讲稿（kJinGuiBookLectures）：数据一致性最小验证。
// 运行：TEMP=... /d/flutter/bin/flutter test test/jingui_book_lecture_test.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/jingui_lecture_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('金匮书面版讲稿数据', () {
    test('篇数合理且 seq 连续', () {
      expect(kJinGuiBookLectures.length, inInclusiveRange(25, 40));
      for (var i = 0; i < kJinGuiBookLectures.length; i++) {
        expect(kJinGuiBookLectures[i].seq, i, reason: 'seq 必须从 0 连续');
      }
    });

    test('每个 asset 在磁盘存在且非空', () {
      for (final l in kJinGuiBookLectures) {
        final f = File(l.asset.replaceFirst('/', '\\'));
        expect(f.existsSync(), isTrue, reason: '缺文件: ${l.asset}');
        expect(f.lengthSync(), greaterThan(5000), reason: '过短: ${l.asset}');
      }
    });

    test('金匮 22 篇目齐全（第三/九/十五篇曾被源漏标，必须存在）', () {
      final names = kJinGuiBookLectures.map((l) => l.name).join('|');
      for (final key in ['百合狐惑', '胸痹', '黄疸', '妇人杂病', '水气']) {
        expect(names.contains(key), isTrue, reason: '缺篇: $key');
      }
    });

    test('篇内容干净：无 B 站链接 / URL / 时间戳残留', () {
      final bad = RegExp(r'(bilibili|http|www\.|\[\d{2}:\d{2})',
          caseSensitive: false);
      for (final l in kJinGuiBookLectures) {
        final text = File(l.asset.replaceFirst('/', '\\')).readAsStringSync();
        expect(bad.hasMatch(text), isFalse, reason: '脏内容: ${l.asset}');
      }
    });
  });
}
