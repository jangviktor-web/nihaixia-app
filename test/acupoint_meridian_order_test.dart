import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/data/acupoint_repository.dart';
import 'package:nihaisha_app/data/meridian_order.dart';

/// 「穴位讲解」列表 / 经络筛选条按**十二经循行顺序**排序的回归测试。
///
/// 背景：`assets/data/acupoints.json` 的物理顺序是交错的（同一经络的穴位散成
/// 337 个连续块），且原实现 `load()` 零排序、`getMeridians()` 走字典序。
/// 本测试锁定改造后的四条关键性质：顺序正确、条数不变、分组正确、排序稳定。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AcupointRepository.load();
  });

  test('1. getMeridians() 严格等于 kMeridianOrder（21 条循行顺序，非字典序）', () {
    final meridians = AcupointRepository.getMeridians();
    expect(meridians.length, 21);
    expect(meridians, equals(kMeridianOrder));
    // 反向确认：若哪天退回字典序，这条断言会立刻失败，避免"恰好相等"的假绿。
    final byDictionary = [...meridians]..sort();
    expect(meridians, isNot(equals(byDictionary)));
  });

  test('2. getAll() 条目数 == 408（排序不丢条）', () {
    expect(AcupointRepository.getAll().length, 408);
  });

  test('3. getAll() 按 meridian 切连续块，块数 == 15 且块序 == 主键经序', () {
    final blocks = <String>[];
    String? previous;
    for (final a in AcupointRepository.getAll()) {
      if (a.meridian != previous) {
        blocks.add(a.meridian);
        previous = a.meridian;
      }
    }
    // 主键 meridian 取 15 个值（12 正经 + 督脉 + 任脉 + 经外奇穴）；
    // 六奇经只出现在交会穴的次键 meridians 里，不构成独立主键块，
    // 故主键块集 = 完整顺序表去掉六奇经（经外奇穴仍属主键）。
    const sixExtra = <String>{'冲脉', '带脉', '阴维脉', '阳维脉', '阴跷脉', '阳跷脉'};
    final expectedPrimary = kMeridianOrder.where((m) => !sixExtra.contains(m)).toList();
    expect(blocks.length, 15);
    expect(blocks, equals(expectedPrimary));
  });

  test('4. 所有 name 唯一（跨经重复穴位为 0）', () {
    final names = AcupointRepository.getAll().map((a) => a.name).toList();
    expect(names.toSet().length, names.length);
  });

  test('5. 排序稳定：表外组（督脉/任脉/经外奇穴）内条目顺序与原 json 物理顺序一致', () async {
    final jsonStr = await rootBundle.loadString('assets/data/acupoints.json');
    final decoded = json.decode(jsonStr) as Map<String, dynamic>;
    final raw = decoded['acupoints'] as List<dynamic>;

    // 穴位名 → 在原始 json 中的下标
    final originalIndex = <String, int>{};
    for (var i = 0; i < raw.length; i++) {
      final entry = raw[i] as Map<String, dynamic>;
      originalIndex[entry['name'] as String] = i;
    }

    // 按经络分组，收集组内条目在原 json 中的下标序列
    final byMeridian = <String, List<int>>{};
    for (final a in AcupointRepository.getAll()) {
      byMeridian.putIfAbsent(a.meridian, () => <int>[]).add(originalIndex[a.name]!);
    }
    expect(byMeridian.keys.toSet().length, 15);

    // 十二正经的组内顺序已改为「国标穴序」（见 acupoint_canon_order_test.dart），
    // 「原物理顺序严格递增」这条稳定性质现在只对表外组（督脉 / 任脉 / 经外奇穴）成立。
    final canonMeridians = kMeridianPointOrder.keys.toSet();
    byMeridian.forEach((meridian, indexes) {
      expect(indexes.toSet().length, indexes.length,
          reason: '$meridian 组内出现重复穴位');
      if (canonMeridians.contains(meridian)) return;
      for (var i = 1; i < indexes.length; i++) {
        expect(indexes[i], greaterThan(indexes[i - 1]),
            reason: '$meridian 组（表外组）应保留原物理顺序：第 $i 项原下标 ${indexes[i]} '
                '未大于前一项 ${indexes[i - 1]}（sort 不稳定）');
      }
    });
  });

  test('6. 六奇经已进入顺序表正式成员；空串/纯空格仍兜底排末尾且不丢', () {
    expect(meridianOrderIndex('手太阴肺经'), 0);
    expect(meridianOrderIndex('经外奇穴'), 20);
    // 六奇经现为顺序表一等公民（任脉之后、经外奇穴之前）。
    expect(meridianOrderIndex('冲脉'), 14);
    expect(meridianOrderIndex('带脉'), 15);
    expect(meridianOrderIndex('阴维脉'), 16);
    expect(meridianOrderIndex('阳维脉'), 17);
    expect(meridianOrderIndex('阴跷脉'), 18);
    expect(meridianOrderIndex('阳跷脉'), 19);
    // 真正的兜底只剩空串 / 纯空格：排到末尾且不丢。
    expect(meridianOrderIndex(''), kUnknownMeridianOrderIndex);
    expect(meridianOrderIndex('   '), kUnknownMeridianOrderIndex);
    // 简称表必须覆盖顺序表里的每一条经（21 条）。
    expect(kMeridianShortName.length, kMeridianOrder.length);
    for (final name in kMeridianOrder) {
      expect(kMeridianShortName.containsKey(name), true, reason: '缺少简称: $name');
      expect(kMeridianShortName[name], isNotEmpty, reason: '简称为空: $name');
    }
  });
}
