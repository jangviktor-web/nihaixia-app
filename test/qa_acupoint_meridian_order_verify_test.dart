import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/data/acupoint_repository.dart';
import 'package:nihaisha_app/data/meridian_order.dart';

/// 独立 QA 复核测试（不复用实现者的测试常量，避免循环论证）。
///
/// 关键差异：**[approvedOrder] 是本文件内独立写死的用户批准顺序字面量**，
/// 不从 `lib/data/meridian_order.dart` 导入 `kMeridianOrder`。
/// 因此 `getMeridians() == approvedOrder` 这条断言**不是**自我循环，
/// 它真正把「实现表的内容」与「用户批准的真相」对撞。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// 用户批准的经络循行顺序（唯一真相，手写字面量，故意不 import 实现常量）。
  ///
  /// 含六奇经（冲脉 / 带脉 / 阴维脉 / 阳维脉 / 阴跷脉 / 阳跷脉）—— 用户已批准它们作为
  /// 交会穴筛选分组的依据，进入顺序表正式成员（位于任脉之后、经外奇穴之前）。
  const List<String> approvedOrder = <String>[
    '手太阴肺经',
    '手阳明大肠经',
    '足阳明胃经',
    '足太阴脾经',
    '手少阴心经',
    '手太阳小肠经',
    '足太阳膀胱经',
    '足少阴肾经',
    '手厥阴心包经',
    '手少阳三焦经',
    '足少阳胆经',
    '足厥阴肝经',
    '督脉',
    '任脉',
    '冲脉',
    '带脉',
    '阴维脉',
    '阳维脉',
    '阴跷脉',
    '阳跷脉',
    '经外奇穴',
  ];

  setUpAll(() async {
    await AcupointRepository.load();
  });

  /// 读原始 json，返回 (name -> 原始物理下标, 原始条目数, 原始 meridian 计数)
  Future<(Map<String, int>, int, Map<String, int>)> readRawJson() async {
    final jsonStr = await rootBundle.loadString('assets/data/acupoints.json');
    final decoded = json.decode(jsonStr) as Map<String, dynamic>;
    final raw = decoded['acupoints'] as List<dynamic>;
    final nameToIndex = <String, int>{};
    final meridianCount = <String, int>{};
    for (var i = 0; i < raw.length; i++) {
      final entry = raw[i] as Map<String, dynamic>;
      nameToIndex[entry['name'] as String] = i;
      final m = entry['meridian'] as String? ?? '';
      meridianCount[m] = (meridianCount[m] ?? 0) + 1;
    }
    return (nameToIndex, raw.length, meridianCount);
  }

  test('QA-1 getMeridians() 逐条等于用户批准顺序（非字典序、非自我循环）', () {
    final meridians = AcupointRepository.getMeridians();
    expect(meridians.length, approvedOrder.length);
    // 逐条比对，任何错字/多字/少字/顺序颠倒都会在这里被抓到
    for (var i = 0; i < approvedOrder.length; i++) {
      expect(meridians[i], approvedOrder[i], reason: '第 ${i + 1} 条经络应为 ${approvedOrder[i]}');
    }
    expect(meridians, equals(approvedOrder));
    // 反证：若退回字典序则必须失败
    expect(meridians, isNot(equals([...meridians]..sort())));
  });

  test('QA-2 getAll() 实际分组顺序 == 批准顺序（每经一个连续块，按主键 meridian 切分）', () async {
    final (_, rawCount, rawMeridians) = await readRawJson();
    // 数据的主键 meridian 仍恰好 15 个值（12 正经 + 督脉 + 任脉 + 经外奇穴），
    // 且全部在批准表内（无表外、无空串）。六奇经只出现在次键 meridians 里，不在此计数。
    expect(rawMeridians.length, 15);
    expect(rawMeridians.keys.toSet().difference(approvedOrder.toSet()), isEmpty);
    expect(rawMeridians.keys.every((m) => m.trim() == m && m.isNotEmpty), isTrue,
        reason: '数据含空串或带首尾空白的 meridian');

    final blocks = <String>[];
    String? prev;
    for (final a in AcupointRepository.getAll()) {
      if (a.meridian != prev) {
        blocks.add(a.meridian);
        prev = a.meridian;
      }
    }
    // 连续块数 == 15（主键 meridian 取值数）；
    // 主键块集 = 批准顺序去掉六奇经（经外奇穴仍属主键，六奇经只在次键 meridians 里）。
    const sixExtra = <String>{
      '冲脉', '带脉', '阴维脉', '阳维脉', '阴跷脉', '阳跷脉'
    };
    final primaryOrder =
        approvedOrder.where((m) => !sixExtra.contains(m)).toList();
    expect(blocks.length, 15);
    expect(blocks, equals(primaryOrder));
    expect(AcupointRepository.getAll().length, rawCount, reason: '排序丢条');
  });

  test('QA-3 排序稳定性：表外组（督脉/任脉/经外奇穴）内部原始下标严格递增（本测试独立实现）', () async {
    final (nameToIndex, rawCount, _) = await readRawJson();
    expect(AcupointRepository.getAll().length, rawCount);

    // 直接用 AcupointDetail，不依赖任何实现侧辅助
    final groups = <String, List<int>>{};
    for (final a in AcupointRepository.getAll()) {
      groups.putIfAbsent(a.meridian, () => <int>[]).add(nameToIndex[a.name]!);
    }
    // 主键 meridian 取值数 == 15（六奇经只在次键 meridians 里，不构成独立分组块）
    expect(groups.length, 15);
    // 十二正经的组内顺序已改为「国标穴序」（详见 acupoint_canon_order_test.dart），
    // 因此「原物理顺序递增」这条稳定性质只对表外组成立。
    final canonMeridians = kMeridianPointOrder.keys.toSet();
    groups.forEach((meridian, indexes) {
      expect(indexes.toSet().length, indexes.length, reason: '$meridian 组内穴位重复');
      if (canonMeridians.contains(meridian)) return;
      for (var i = 1; i < indexes.length; i++) {
        expect(indexes[i], greaterThan(indexes[i - 1]),
            reason: '$meridian 组内第 $i 项漂移：原下标 ${indexes[i]} <= 前项 ${indexes[i - 1]}');
      }
    });

    // 反向映射也必须是 408 个唯一 name（排序不产生副本/丢失）
    final names = AcupointRepository.getAll().map((a) => a.name).toSet();
    expect(names.length, rawCount);
  });

  test('QA-4 兜底：空串 / 纯空格 / 非标准名 都排末尾且一条不丢；六奇经为表内', () {
    // 复刻实现的比较器（与 meridian_order.dart 的 meridianOrderIndex 同一逻辑）
    int orderIndexOf(String m) {
      final i = approvedOrder.indexOf(m);
      return i >= 0 ? i : 1000000;
    }

    final lastKnown = approvedOrder.length - 1;
    // 六奇经已是批准表正式成员，不再视为表外
    for (final known in <String>['冲脉', '带脉', '阴维脉', '阳维脉', '阴跷脉', '阳跷脉', '经外奇穴']) {
      expect(orderIndexOf(known), lessThan(1000000), reason: '$known 应判为表内');
      expect(orderIndexOf(known), lessThanOrEqualTo(orderIndexOf(approvedOrder[lastKnown])),
          reason: '$known 不应排到表外之后');
    }
    // 真正的兜底只针对空串 / 纯空格 / 非标准写法（如手滑打的「肺经」）
    for (final odd in <String>['', '   ', '肺经']) {
      expect(orderIndexOf(odd), 1000000, reason: '$odd 应判为表外');
      expect(orderIndexOf(odd), greaterThan(orderIndexOf(approvedOrder[lastKnown])),
          reason: '$odd 未排到末尾');
    }
    // 排序后：表内条目在前、表外条目（同权重）聚末尾并保持原相对顺序，条目不丢
    final fake = <List<Object>>[
      ['冲脉A', '冲脉', 0],
      ['  ', '   ', 1],
      ['', '', 2],
      ['肺经X', '手太阴肺经', 3],
    ];
    fake.sort((a, b) {
      final byM = orderIndexOf(a[1] as String).compareTo(orderIndexOf(b[1] as String));
      return byM != 0 ? byM : (a[2] as int).compareTo(b[2] as int);
    });
    // 手太阴肺经(idx 0) < 冲脉(idx 14) << 表外(1e6)；纯空格(1) 与 空串(2) 兜底到末尾保持原序
    expect(fake.map((e) => e[0] as String).toList(),
        ['肺经X', '冲脉A', '  ', ''], reason: '表内条目在前、表外条目聚末尾且保持原相对顺序');
    expect(fake.length, 4, reason: '排序丢条');
  });

  test('QA-5 真实数据下表外条目为 0（兜底路径目前是死代码，不会影响用户）', () async {
    final (_, _, rawMeridians) = await readRawJson();
    final outOfTable = rawMeridians.keys
        .where((m) => !approvedOrder.contains(m))
        .toList();
    expect(outOfTable, isEmpty, reason: '数据出现表外经络，需复核 UI 是否漏 chip');
    // getAll() 里也不应出现空 meridian（否则该条在 chip 栏无法被筛到）
    expect(AcupointRepository.getAll().any((a) => a.meridian.trim().isEmpty), isFalse);
  });

  test('QA-6 返回值别名：getAll()/getByMeridian("全部") 返回内部可变列表', () {
    final a = AcupointRepository.getAll();
    final b = AcupointRepository.getAll();
    expect(identical(a, b), isTrue, reason: 'getAll() 每次返回同一对象');
    expect(identical(AcupointRepository.getByMeridian('全部'), a), isTrue,
        reason: 'getByMeridian("全部") 与 getAll() 是同一对象');
    // 当前调用方均未 mutate（已 grep 确认），故此处只做「暴露面」记录，不断言不可变
    // 若将来有人 sort/reverse/remove 这个列表，会直接污染全局缓存。
    expect(a.length, AcupointRepository.count);
  });

  test('QA-7 chip 顺序：主键经序 == 列表分组顺序；六奇经 chip 位于主键之后', () {
    final chips = ['全部', ...AcupointRepository.getMeridians()];
    expect(chips.first, '全部');
    final chipMeridians = chips.skip(1).toList();
    expect(chipMeridians, equals(approvedOrder));

    // 列表首次出现的经络顺序（按主键 meridian 切分，仅 15 块）
    final listOrder = <String>[];
    for (final a in AcupointRepository.getAll()) {
      if (a.name.isEmpty) continue;
      if (listOrder.isEmpty || listOrder.last != a.meridian) listOrder.add(a.meridian);
    }
    // 列表分组顺序 = 批准顺序的主键部分（12 正经 + 督任 + 经外奇穴）；
    // 六奇经只作 chip 过滤项，不构成独立主键块。
    const sixExtra = <String>{
      '冲脉', '带脉', '阴维脉', '阳维脉', '阴跷脉', '阳跷脉'
    };
    final primaryOrder =
        approvedOrder.where((m) => !sixExtra.contains(m)).toList();
    expect(listOrder, equals(primaryOrder),
        reason: '列表分组顺序应为批准顺序的主键部分');
    // chip 的主键部分（去掉六奇经）应与列表分组顺序一致；六奇经在 chip 里夹在任脉与经外奇穴之间
    expect(chipMeridians.where((m) => !sixExtra.contains(m)).toList(),
        equals(listOrder),
        reason: 'chip 主键部分顺序与列表分组顺序不一致');
    // 六奇经 chip 占据 approvedOrder 的 14..19（冲脉→阳跷脉），经外奇穴在 20
    expect(chipMeridians.sublist(14, 20),
        equals(['冲脉', '带脉', '阴维脉', '阳维脉', '阴跷脉', '阳跷脉']),
        reason: '六奇经 chip 应紧接主键经、位于经外奇穴之前');
  });

  test('QA-8 副作用：allNames 同长度组内顺序被重排（潜在回归，需产品确认）', () async {
    // 复刻 _buildAllNames（acupoint_repository.dart:82-90）
    List<String> buildNames(List<dynamic> source) {
      final set = <String>{};
      for (final a in source) {
        final n = (a as Map<String, dynamic>)['name'].toString().replaceAll('穴', '');
        // 与生产同一套形态口径：撞普通词的短名（子宫 → 子宫穴）用替换形态参与，
        // 否则「集合必须一致」这条会因**设计内**的形态修正而误报。
        set.add(AcupointRepository.kShortNameLinkForm[n] ?? n);
      }
      final list = set.toList();
      list.sort((x, y) => y.length.compareTo(x.length));
      return list;
    }

    final jsonStr = await rootBundle.loadString('assets/data/acupoints.json');
    final decoded = json.decode(jsonStr) as Map<String, dynamic>;
    final raw = decoded['acupoints'] as List<dynamic>;

    final beforeOrder = buildNames(raw); // 改造前：json 物理顺序播种
    final afterOrder = AcupointRepository.allNames; // 改造后：经络顺序播种

    // 集合内容必须完全一致（不能丢/多任何穴名）
    expect(afterOrder.toSet(), beforeOrder.toSet());
    expect(afterOrder.length, beforeOrder.length);

    // 记录：整体顺序是否被改动（改动本身不一定是 bug，但要让人知道）
    final sameOverall = beforeOrder.join('|') == afterOrder.join('|');
    // ignore: avoid_print
    print('[QA-8] allNames 整体顺序是否与改造前一致: $sameOverall');
    if (!sameOverall) {
      // 同长度桶内容相同，仅并列项次序可能漂移 -> 只提示，不失败
      final diffCount = <int>[];
      for (final n in afterOrder) {
        if (beforeOrder.indexOf(n) != afterOrder.indexOf(n)) diffCount.add(n.length);
      }
      // ignore: avoid_print
      print('[QA-8] 位置发生变化的穴名共 ${diffCount.length} 个，长度分布: '
          '${diffCount.toSet().toList()..sort()}');
    }
  });
}
