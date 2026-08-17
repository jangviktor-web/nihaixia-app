import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/ziwei_case_data.dart';

void main() {
  const branches = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

  test('案例 28 篇 + 宫详解 13 篇（含前言）+ 总论 1 篇', () {
    expect(kZiweiCases.length, 28);
    expect(kZiweiPalaceChapters.length, 13);
    expect(kZiweiOverview.asset, 'assets/ziwei/overview.md');
    expect(kZiweiOverview.kind, 'overview');
  });

  test('地支字段全部合法（无「戍」异体，已归一为「戌」）', () {
    for (final e in [...kZiweiCases, ...kZiweiPalaceChapters]) {
      if (e.mingBranch.isEmpty && e.ziweiBranch.isEmpty) {
        continue; // 前言等无编码条目
      }
      expect(branches, contains(e.mingBranch), reason: e.title);
      expect(e.mingBranch, isNot('戍'));
      if (e.ziweiBranch.isNotEmpty) {
        expect(branches, contains(e.ziweiBranch), reason: e.title);
        expect(e.ziweiBranch, isNot('戍'));
      }
    }
  });

  test('案例 id 唯一且按序', () {
    final ids = kZiweiCases.map((e) => e.id).toList();
    expect(ids.toSet().length, ids.length, reason: '案例序号应唯一');
  });

  test('资源文件全部存在（assets/ziwei/ 下）', () {
    for (final e in [...kZiweiCases, ...kZiweiPalaceChapters, kZiweiOverview]) {
      expect(File(e.asset).existsSync(), isTrue, reason: e.asset);
    }
  });

  test('按命宫地支+性别匹配：命宫巳·女 → 案例9、案例25', () {
    final r = ziweiCasesFor('巳', '女');
    expect(r.map((e) => e.id), containsAll(['9', '25']));
  });

  test('匹配函数始终返回列表（无匹配为空）', () {
    expect(ziweiCasesFor('午', '男'), isA<List<ZiweiCaseEntry>>());
    expect(ziweiCasesFor('不存在', '男'), isEmpty);
  });
}
