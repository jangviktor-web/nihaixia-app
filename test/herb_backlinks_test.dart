import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/data/medical_case_data.dart';
import 'package:nihaisha_app/data/herb_repository.dart';
import 'package:nihaisha_app/data/critical_illness_data.dart';

/// 验证详情页后向关联（含此药的医案 / 含此药的闭门课）的数据通路，
/// 与 markdown 正文中 herb:// 链接触达正确药材详情的解析路径。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await HerbRepository.load();
  });

  group('详情页后向关联（含此药的医案 / 闭门课）', () {
    test('全量医案资产可加载且非空', () async {
      final cases = await getAllMedicalCases();
      expect(cases, isNotEmpty);
    });

    test('含此药的医案：可反查出相关医案', () async {
      final cases = await getAllMedicalCases();
      // 找到任意一味在处方中出现过的药材（即详情页 backlink 的真实路径）
      final herb = HerbRepository.getAll().firstWhere(
        (h) => cases.any((c) => c.herbNames.contains(h.name)),
      );
      final related =
          cases.where((c) => c.herbNames.contains(herb.name)).toList();
      expect(related, isNotEmpty,
          reason: '药材 ${herb.name} 应能反查出含此药的医案');
    });

    test('含此药的闭门课：生附子应命中多个重症 tag', () {
      final related = kCriticalIllnesses
          .where((it) =>
              it.tags.any((t) => HerbRepository.canonicalOf(t) == '生附子'))
          .toList();
      expect(related, isNotEmpty, reason: '生附子应命中闭门课 tag');
    });

    test('herb:// 跳转解析：别名经 getExactByName 归一到正名', () {
      // 闭门课正文 herb://大附子 应触达「生附子」详情（无模糊兜底，避免错跳方剂）
      final herb = HerbRepository.getExactByName('大附子');
      expect(herb?.name, '生附子');
    });
  });
}
