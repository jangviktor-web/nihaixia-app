// 针灸讲稿阅读库：数据一致性 + 内容干净 + 穴位索引 + 搜索接入。
// 运行：flutter test test/zhenjiu_lecture_test.dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/data/zhenjiu_lecture_data.dart';
import 'package:nihaisha_app/data/zhenjiu_lecture_index.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('讲稿数据（kZhenJiuLectures 与磁盘资产一致）', () {
    test('篇数合理（70~100）且 seq 连续', () {
      expect(kZhenJiuLectures.length, inInclusiveRange(70, 100));
      for (var i = 0; i < kZhenJiuLectures.length; i++) {
        expect(kZhenJiuLectures[i].seq, i, reason: 'seq 必须连续');
      }
    });

    test('每个 asset 在磁盘存在且非空', () {
      for (final l in kZhenJiuLectures) {
        final f = File(l.asset.replaceFirst('assets/', 'assets/'));
        expect(f.existsSync(), isTrue, reason: '${l.asset} 不存在');
        expect(f.lengthSync(), greaterThan(60), reason: '${l.asset} 过小');
      }
    });

    test('篇内容干净：无 B 站链接 / URL / 时间戳残留', () async {
      final bad = RegExp(
          r'bilibili|http|www\.|\[（|\d+-\d{2}:\d{2}:\d{2}|BV1',
          caseSensitive: false);
      for (final l in kZhenJiuLectures) {
        final t = await rootBundle.loadString(l.asset);
        expect(bad.hasMatch(t), isFalse, reason: '${l.asset} 有链接残留');
      }
    });

    test('篇名带章前缀且无空 asset', () {
      for (final l in kZhenJiuLectures) {
        expect(l.name, contains('第'), reason: '篇名应带「第X章·」前缀');
        expect(l.asset, isNotEmpty);
      }
    });
  });

  group('穴位提及索引（acupoint_index.json）', () {
    late ZhenJiuLectureIndex idx;

    setUpAll(() async {
      idx = await ZhenJiuLectureIndex.load();
    });

    test('json 合法且排除名单生效', () {
      expect(idx.excludedNames, containsAll(['太阳', '光明', '子宫']));
      expect(idx.hitsFor('太阳'), isEmpty, reason: '排除词必须查无命中');
      expect(idx.hitsFor('光明穴'), isEmpty);
    });

    test('高频穴有命中且按次数降序', () {
      final hits = idx.hitsFor('合谷');
      expect(hits, isNotEmpty);
      for (var i = 1; i < hits.length; i++) {
        expect(hits[i - 1].count, greaterThanOrEqualTo(hits[i].count));
      }
    });

    test('带「穴」后缀查询自动归一', () {
      final bare = idx.hitsFor('涌泉');
      final suffixed = idx.hitsFor('涌泉穴');
      expect(bare, isNotEmpty);
      expect(suffixed.length, bare.length);
    });

    test('命中 seq 均在讲稿范围内且 nameOf/assetOf 可反查', () {
      for (final l in kZhenJiuLectures) {
        expect(ZhenJiuLectureIndex.nameOf(l.seq), l.name);
        expect(ZhenJiuLectureIndex.assetOf(l.seq), l.asset);
      }
    });

    test('索引正文里提过的篇, 其篇正文确实包含该穴名（抽 3 穴验证）', () async {
      final json = jsonDecode(
        await rootBundle
            .loadString('assets/zhenjiu_lecture/acupoint_index.json'),
      ) as Map<String, dynamic>;
      for (final name in ['涌泉', '合谷', '百会']) {
        final entries = (json[name] as List).cast<Map<String, dynamic>>();
        expect(entries, isNotEmpty);
        final hit = entries.first;
        final body =
            await rootBundle.loadString(kZhenJiuLectures[hit['s'] as int].asset);
        expect(body.contains(name as String), isTrue,
            reason: '$name 命中篇 ${hit['s']} 正文里应有该穴名');
      }
    });
  });
}
