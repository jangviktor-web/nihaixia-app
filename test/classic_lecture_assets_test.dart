import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/data/classic_lecture_data.dart';
import 'package:nihaisha_app/data/neijing_lecture_data.dart';

/// 阅读库索引 ↔ 资产一致性检查。
///
/// 最高风险点是「索引里的 asset 路径」与「实际打包的文件」对不上
/// （改名/漏加 pubspec 目录都会静默 404）。逐条 loadString 断言非空即覆盖。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> expectAllLoadable(List<LectureIndex> list, String label) async {
    expect(list, isNotEmpty, reason: '$label 索引为空');
    final seen = <String>{};
    for (final l in list) {
      expect(seen.add(l.asset), true, reason: '$label 资产重复: ${l.asset}');
      final s = await rootBundle.loadString(l.asset);
      expect(s.trim().isNotEmpty, true, reason: '$label 资产为空: ${l.asset}');
    }
  }

  test('伤寒论 阅读库资产全部可加载', () async {
    // 条文级拆分后：23 篇 → 380 条（+1 条 nhx 补缺：桂枝去芍药汤/加附子汤）
    expect(kShangHanLectures.length, 381);
    await expectAllLoadable(kShangHanLectures, '伤寒论');
  });

  test('金匮要略 阅读库资产全部可加载', () async {
    // 条文级拆分后：25 篇 → 453 条
    expect(kJinguiLectures.length, 453);
    await expectAllLoadable(kJinguiLectures, '金匮要略');
  });

  test('内经 阅读库资产仍可加载（回归）', () async {
    await expectAllLoadable(kNeiJingLectures, '内经');
  });
}
