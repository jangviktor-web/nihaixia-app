import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/yijing_lecture_data.dart';
import 'package:nihaisha_app/engine/yijing_engine.dart';

void main() {
  test('64 卦课稿全覆盖（seq 1-64 唯一）', () {
    expect(kYiJingLectures.length, 64);
    final seqs = kYiJingLectures.map((e) => e.seq).toList();
    expect(seqs.toSet(), {for (var i = 1; i <= 64; i++) i});
  });

  test('文件名卦符与引擎卦序一致', () {
    for (final e in kYiJingLectures) {
      // asset 形如 assets/yijing/1.乾为天䷀.md，.md 前一字符为卦符
      final symbol = e.asset.substring(e.asset.length - 4, e.asset.length - 3);
      expect(symbol, YiJingEngine.symbol(e.seq), reason: e.asset);
    }
  });

  test('资源文件全部存在', () {
    for (final e in kYiJingLectures) {
      expect(File(e.asset).existsSync(), isTrue, reason: e.asset);
    }
  });

  test('yijingLectureAsset 按卦序取路径', () {
    for (var i = 1; i <= 64; i++) {
      expect(yijingLectureAsset(i), isNotNull, reason: 'seq $i');
    }
    expect(yijingLectureAsset(0), isNull);
    expect(yijingLectureAsset(65), isNull);
  });
}
