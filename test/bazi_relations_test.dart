import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/engine/bazi_relations.dart';

void main() {
  group('八字地支关系检测', () {
    test('六冲：子午冲 / 寅申冲', () {
      final r = detectBaziRelations(['子', '午', '寅', '申']);
      expect(r, contains('子午冲'));
      expect(r, contains('寅申冲'));
    });

    test('六合：子丑合', () {
      expect(
        detectBaziRelations(['子', '丑', '寅', '卯']),
        contains('子丑合'),
      );
    });

    test('六害：子未害', () {
      expect(
        detectBaziRelations(['子', '未', '寅', '卯']),
        contains('子未害'),
      );
    });

    test('无礼之刑：子卯刑', () {
      expect(
        detectBaziRelations(['子', '卯', '寅', '申']),
        contains('子卯刑'),
      );
    });

    test('三合：申子辰三合水', () {
      expect(
        detectBaziRelations(['申', '子', '辰', '卯']),
        contains('申子辰三合水'),
      );
    });

    test('三会：亥子丑三会水', () {
      expect(
        detectBaziRelations(['亥', '子', '丑', '午']),
        contains('亥子丑三会水'),
      );
    });

    test('三刑：寅巳申三刑', () {
      expect(
        detectBaziRelations(['寅', '巳', '申', '子']),
        contains('寅巳申三刑'),
      );
    });

    test('自刑：辰辰自刑（同支重复出现）', () {
      final r = detectBaziRelations(['辰', '辰', '子', '午']);
      expect(r, contains('辰辰自刑'));
      expect(r, contains('子午冲')); // 同组里也含冲
    });

    test('空输入返回空', () {
      expect(detectBaziRelations([]), isEmpty);
      expect(detectBaziRelations(['', '', '', '']), isEmpty);
    });

    test('去重保序（同一关系不重复出现）', () {
      final r = detectBaziRelations(['子', '午', '子', '午']);
      expect(r.where((x) => x == '子午冲'), hasLength(1));
    });
  });
}
