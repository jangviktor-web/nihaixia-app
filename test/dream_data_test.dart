import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/data/dream_data.dart';

const _auspiciousLevels = {'大吉', '吉', '平', '凶', '大凶'};

void main() {
  test('kDreamEntries 共 412 条', () {
    expect(kDreamEntries.length, 412);
  });

  test('每条字段非空且吉凶值合法', () {
    for (final e in kDreamEntries) {
      expect(e.id, isNotEmpty);
      expect(e.category, isNotEmpty);
      expect(e.subcategory, isNotEmpty);
      expect(e.keyword, isNotEmpty);
      expect(e.dream, isNotEmpty);
      expect(e.interpretation, isNotEmpty);
      expect(e.auspicious, isNotEmpty);
      expect(e.source, isNotEmpty);
      expect(_auspiciousLevels.contains(e.auspicious), isTrue,
          reason: '${e.id} 的吉凶值 ${e.auspicious} 不在合法集合内');
    }
  });

  test('kDreamCategories 共 10 条', () {
    expect(kDreamCategories.length, 10);
  });

  test('searchDreams(太阳) 包含 sky_001 且为大吉', () {
    final r = searchDreams('太阳');
    final hit = r.firstWhere((e) => e.id == 'sky_001', orElse: () => r.first);
    expect(r.any((e) => e.id == 'sky_001'), isTrue);
    expect(hit.auspicious, '大吉');
  });

  test('searchDreams(空, 动物) 全部 category 为动物', () {
    final r = searchDreams('', '动物');
    expect(r.isNotEmpty, isTrue);
    for (final e in r) {
      expect(e.category, '动物');
    }
  });

  test('searchDreams(不存在的词zzz) 返回空列表', () {
    final r = searchDreams('不存在的词zzz');
    expect(r, isEmpty);
  });

  test('searchDreams(竹子) 包含 plant_024 且为吉', () {
    final r = searchDreams('竹子');
    expect(r.any((e) => e.id == 'plant_024'), isTrue);
    final hit = r.firstWhere((e) => e.id == 'plant_024');
    expect(hit.auspicious, '吉');
  });
}
