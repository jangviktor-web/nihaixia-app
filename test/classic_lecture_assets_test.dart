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
    // 条文级拆分后：23 篇 → 380 条（+2 条 nhx 补缺：桂枝去芍药汤/加附子汤、桂苓甘草龙骨牡蛎汤）
    expect(kShangHanLectures.length, 384);
    await expectAllLoadable(kShangHanLectures, '伤寒论');
  });

  test('金匮要略 阅读库资产全部可加载', () async {
    // 条文级切分后：453 条（+2 nhx 补缺：诃黎勒散、桂辛附汤）；2026-11-04 合并 22 组「问曰+师曰」问答卡 → 433
    expect(kJinguiLectures.length, 433);
    await expectAllLoadable(kJinguiLectures, '金匮要略');
  });

  test('内经 阅读库资产仍可加载（回归）', () async {
    await expectAllLoadable(kNeiJingLectures, '内经');
  });

  test('每条讲稿首行都是标题行（否则搜索标题会退化成文件名）', () async {
    // 2026-11-03：18 个伤寒条文卡缺 `#### 标题`，搜索「clause」会命中一堆文件名。
    for (final l in [...kShangHanLectures, ...kJinguiLectures, ...kNeiJingLectures]) {
      final first = (await rootBundle.loadString(l.asset)).split('\n').first.trim();
      expect(first.startsWith('#'), true,
          reason: '缺标题行: ${l.asset} → $first');
    }
  });
}
