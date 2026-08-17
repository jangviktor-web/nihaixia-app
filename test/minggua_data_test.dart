import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/minggua_data.dart';

void main() {
  test('66 篇讲义：0 排法 + 1-64 卦 + 65 补充', () {
    expect(kMingGuaEntries.length, 66);
    final seqs = kMingGuaEntries.map((e) => e.seq).toList();
    expect(seqs.toSet(), {0, ...{for (var i = 1; i <= 64; i++) i}, 65});
    expect(kMingGuaEntries.where((e) => e.kind == 'overview').length, 1);
    expect(kMingGuaEntries.where((e) => e.kind == 'hex').length, 64);
    expect(kMingGuaEntries.where((e) => e.kind == 'supplement').length, 1);
  });

  test('资源文件全部存在', () {
    for (final e in kMingGuaEntries) {
      expect(File(e.asset).existsSync(), isTrue, reason: e.asset);
    }
  });

  test('mingGuaLectureAsset 按卦序取路径（非卦条目返回 null）', () {
    for (var i = 1; i <= 64; i++) {
      expect(mingGuaLectureAsset(i), isNotNull, reason: 'seq $i');
    }
    expect(mingGuaLectureAsset(0), isNull);
    expect(mingGuaLectureAsset(65), isNull);
    expect(mingGuaLectureAsset(66), isNull);
  });
}
