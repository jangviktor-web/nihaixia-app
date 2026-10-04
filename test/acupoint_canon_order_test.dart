import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/data/acupoint_repository.dart';
import 'package:nihaisha_app/data/meridian_order.dart';

/// 十二正经**经络内部**穴位顺序 = 国标循行顺序 的回归测试。
///
/// 背景：`kMeridianOrder` 只规定了「经与经谁先谁后」，同一经内部的穴位是跟着
/// `assets/data/acupoints.json` 的物理顺序走的，而那份物理顺序既不是循行序也不是
/// 字典序（手太阴肺经原本是 中府 → 云门 → 侠白 → 列缺 → 天府 …）。
/// 本测试锁定改造后的性质：每条正经内部必须严格按国标穴序排列。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await AcupointRepository.load();
  });

  test('0. kPointAlias 的每个值都能落到国标表里（防死表 / 拼错）', () {
    for (final entry in kPointAlias.entries) {
      final hit = kMeridianPointOrder.values.any(
        (canon) => canon.contains(entry.value) || canon.contains('${entry.value}穴'),
      );
      expect(hit, isTrue,
          reason: '别名 ${entry.key} -> ${entry.value} 在国标表里找不到落点，是死表');
    }
  });

  test('1. 每条正经内部：国标穴序单调不减，且 0..n-1 每个槽位都被填上', () {
    for (final entry in kMeridianPointOrder.entries) {
      final meridian = entry.key;
      final canonical = entry.value;
      final actual = AcupointRepository.getByMeridian(meridian);
      expect(actual, isNotEmpty, reason: '$meridian 是空经络');

      final indices = actual
          .map((a) => pointOrderIndex(meridian, a.name))
          .where((i) => i != kUnknownPointOrderIndex)
          .toList();

      // (a) 单调不减 —— 哪怕只把一个穴位插错位置，这里立刻红。
      for (var i = 1; i < indices.length; i++) {
        expect(
          indices[i],
          greaterThanOrEqualTo(indices[i - 1]),
          reason: '$meridian 第 $i 个穴位「${actual[i].name}」插错了位置'
              '（前一下标 ${indices[i - 1]}，本个 ${indices[i]}）',
        );
      }

      // (b) 每个国标槽位都被填上，不缺不重。
      final sorted = indices.toSet().toList()..sort();
      expect(
        sorted,
        equals(List<int>.generate(canonical.length, (i) => i)),
        reason: '$meridian 的国标穴序下标集合与国标表不一致（国标 ${canonical.length} 穴，'
            '实际覆盖 ${sorted.length} 个槽位）',
      );
    }
  });

  test('2. 手太阴肺经：完整等于 中府 → 云门 → 天府 → 侠白 → 尺泽 → … → 少商', () {
    final actual = AcupointRepository.getByMeridian('手太阴肺经').map((a) => a.name).toList();
    // 国标名统一补尾「穴」以对齐库内形态（气穴 这类本身带穴的保持原样）。
    final expected = kMeridianPointOrder['手太阴肺经']!
        .map((n) => n.endsWith('穴') ? n : '$n穴')
        .toList();
    expect(actual, equals(expected));
    // 反向确认：这绝不可能碰巧是字典序。
    expect(actual, isNot(equals([...actual]..sort())));
  });

  test('3. 足太阳膀胱经：至阴 之后只剩表外的「八髎穴」', () {
    const meridian = '足太阳膀胱经';
    final names = AcupointRepository.getByMeridian(meridian).map((a) => a.name).toList();
    final zi = names.indexOf('至阴穴');
    expect(zi, greaterThanOrEqualTo(0), reason: '膀胱经里找不到 至阴穴');

    // 至阴 是国标最后一穴，排在它后面的必定是表外穴。
    expect(names.sublist(zi + 1), equals(<String>['八髎穴']));

    // 「通谷穴」虽是异名，但经 kPointAlias 归一到 足通谷，因此落在国标槽位内，
    // 必须与 足通谷穴 紧邻（二者同一槽位，谁在先由原始物理顺序决定）。
    final zc = names.indexOf('足通谷穴');
    final alias = names.indexOf('通谷穴');
    expect(zc, greaterThanOrEqualTo(0));
    expect(alias, greaterThanOrEqualTo(0));
    expect((zc - alias).abs() <= 1, isTrue,
        reason: '异名 通谷穴 应与 足通谷穴 相邻');
    expect(pointOrderIndex(meridian, '通谷穴'),
        pointOrderIndex(meridian, '足通谷穴'));
  });

  test('4. 异名归一：「五里穴」被归到国标第 9 位（足五里 的槽位）', () {
    const meridian = '足厥阴肝经';
    final names = AcupointRepository.getByMeridian(meridian).map((a) => a.name).toList();
    final at = names.indexOf('五里穴');
    expect(at, greaterThanOrEqualTo(0), reason: '肝经里找不到 五里穴（异名）');

    // 库里没有标准的「足五里穴」记录，全靠 kPointAlias 把异名归位。
    final canonSlot = kMeridianPointOrder[meridian]!.indexOf('足五里');
    expect(canonSlot, greaterThanOrEqualTo(0));
    expect(pointOrderIndex(meridian, '五里穴'), canonSlot);
    // 归位后必须夹在 阴包 与 阴廉 之间。
    expect(names[at - 1], '阴包');
    expect(names[at + 1], '阴廉');
  });

  test('5. 排序只换顺序、不丢不重：总数仍为 408', () {
    expect(AcupointRepository.getAll().length, 408);
  });

  test('6. 经外奇穴 没有国标循行表，内部保持原物理顺序', () {
    final names = AcupointRepository.getByMeridian('经外奇穴').map((a) => a.name).toList();
    expect(names, isNotEmpty);
    expect(
      names.every((n) => pointOrderIndex('经外奇穴', n) == kUnknownPointOrderIndex),
      isTrue,
      reason: '经外奇穴 不该有穴位落进国标表',
    );
    // 端点仍保留原始物理顺序（首 三毛、末 颈夹脊）。
    expect(names.first, '三毛');
    expect(names.last, '颈夹脊');
  });

  test('8. 奇经八脉：督脉 / 任脉 现已按古籍循行顺序排列', () {
    // 督脉：从下往上，长强 打头、印堂 收尾（印堂按国标修订划入督脉本经穴 DU29）。
    final du = AcupointRepository.getByMeridian('督脉').map((a) => a.name).toList();
    expect(du.first, '长强穴');
    expect(du.last, '印堂穴');
    expect(pointOrderIndex('督脉', '长强穴'), lessThan(pointOrderIndex('督脉', '腰阳关')));
    expect(pointOrderIndex('督脉', '水沟'), lessThan(pointOrderIndex('督脉', '龈交')));
    // 异名归一：人中穴 = 水沟穴，应紧邻 水沟穴。
    final renIdx = du.indexOf('人中');
    final shuiIdx = du.indexOf('水沟');
    expect(renIdx, greaterThanOrEqualTo(0));
    expect(shuiIdx, greaterThanOrEqualTo(0));
    expect((renIdx - shuiIdx).abs(), 1, reason: '异名 人中穴 应与 水沟穴 紧邻');

    // 任脉：从下往上，会阴 打头、承浆 收尾。
    final rn = AcupointRepository.getByMeridian('任脉').map((a) => a.name).toList();
    expect(rn.first, '会阴');
    expect(rn.last, '承浆穴');
    expect(pointOrderIndex('任脉', '会阴'), lessThan(pointOrderIndex('任脉', '关元穴')));
    expect(pointOrderIndex('任脉', '天突穴'), lessThan(pointOrderIndex('任脉', '承浆穴')));
  });

  test('7. 国标错字回归：三焦经存在「瘈脉穴」，且「瘛脉」已绝迹', () {
    final names = AcupointRepository.getByMeridian('手少阳三焦经').map((a) => a.name).toList();
    expect(names, contains('瘈脉穴'));
    expect(names, isNot(contains('瘛脉穴')));
  });
}
