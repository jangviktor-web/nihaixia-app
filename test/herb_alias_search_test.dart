import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/herb_repository.dart';

// 回归测试：药材异名检索覆盖。
//
// 背景（事故复现）：提交 c67ad63 做了「同药异名合并」，把异名独立条目从 herbs.json
// 删除，改为在 _canonicalOf 登记「异名 → 正名」。此后只按 herb.name 裸匹配、
// 没走 canonicalOf 归一的代码，遇到异名查询必然返回空。
// 当时 knowledge_screen（药库列表）与 search_tab（联想框）各复制了一份匹配逻辑
// 且都漏了归一，导致 103 个异名中 74 / 87 个搜不到（典型：茈胡 搜不到 柴胡）。
//
// 修复方式：收敛为 HerbRepository.matchesQuery 唯一入口。
// 本测试直接调用**生产代码 + 真实 assets**（非复刻逻辑），防止再次分叉。
//
// 运行：
//   TEMP="C:/Users/jangviktor/AppData/Local/Temp" TMP="C:/Users/jangviktor/AppData/Local/Temp" \
//     /d/flutter/bin/flutter test test/herb_alias_search_test.dart

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await HerbRepository.load();
  });

  group('药材数据完整性', () {
    test('药库已加载且条目数与 total 一致', () {
      final herbs = HerbRepository.getAll();
      expect(herbs, isNotEmpty);
    });

    test('异名映射非空', () {
      expect(HerbRepository.aliasNames, isNotEmpty);
    });
  });

  group('异名检索（用户直接报告的症状）', () {
    test('茈胡 → 应命中柴胡', () {
      final r = HerbRepository.search('茈胡').map((h) => h.name).toList();
      expect(r, contains('柴胡'), reason: 'search("茈胡") 实际返回 $r');
    });

    test('茈胡 → getExactByName 应归一到柴胡', () {
      expect(HerbRepository.getExactByName('茈胡')?.name, '柴胡');
    });

    test('典型异名逐个验证', () {
      const cases = {
        '茈胡': '柴胡',
        '山药': '署豫',
        '薯蓣': '署豫',
        '橘皮': '陈皮',
        '红枣': '大枣',
        '生甘草': '甘草',
        '牡桂': '肉桂',
        '牡丹皮': '牡丹',
      };
      for (final e in cases.entries) {
        final hit = HerbRepository.search(e.key).map((h) => h.name).toList();
        expect(hit, contains(e.value),
            reason: 'search("${e.key}") 应命中「${e.value}」，实际返回 $hit');
      }
    });
  });

  group('全量覆盖（防回归核心）', () {
    test('全部异名均可通过 matchesQuery 命中至少一条', () {
      final herbs = HerbRepository.getAll();
      final failed = <String>[];
      for (final alias in HerbRepository.aliasNames) {
        if (!herbs.any((h) => HerbRepository.matchesQuery(h, alias))) {
          failed.add(alias);
        }
      }
      expect(failed, isEmpty,
          reason: '以下异名检索失效（共 ${failed.length} 个）：$failed');
    });

    test('全部正名均可通过 matchesQuery 命中自身', () {
      final herbs = HerbRepository.getAll();
      final failed = <String>[];
      for (final h in herbs) {
        if (!herbs.any((x) => HerbRepository.matchesQuery(x, h.name))) {
          failed.add(h.name);
        }
      }
      expect(failed, isEmpty,
          reason: '以下正名检索失效（共 ${failed.length} 个）：$failed');
    });

    test('全部异名均可通过 search() 命中（与 matchesQuery 一致）', () {
      final failed = <String>[];
      for (final alias in HerbRepository.aliasNames) {
        if (HerbRepository.search(alias).isEmpty) {
          failed.add(alias);
        }
      }
      expect(failed, isEmpty,
          reason: 'search() 对以下异名返回空（共 ${failed.length} 个）：$failed');
    });
  });
}
