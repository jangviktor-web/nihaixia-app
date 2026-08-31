import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ziwei_core/ziwei_core.dart';

import 'package:nihaisha_app/services/ziwei_engine.dart';
import 'package:nihaisha_app/services/ziwei_interpretation.dart';

/// 引擎交叉验证：本 App 的 ziwei_core 排盘 vs iztro-py 排盘基准。
///
/// 基准由 tools/ziwei_oracle/oracle.py 生成（iztro-py 0.5.0），覆盖 4 张生辰盘。
///
/// 本测试**收集全部分歧后一次性输出**（不遇错即停），便于看清整体吻合度。
/// 断言只针对紫微结构性字段（十二宫主星名 / 生年四化 / 大限区间）——
/// 这些两引擎必须一致；八字与亮度仅报告，因其涉及节气表与亮度表的流派差异。
void main() {
  final refFile = File('tools/ziwei_oracle/ziwei_reference.json');
  if (!refFile.existsSync()) {
    return; // 基准文件缺失不阻断常规测试
  }

  final data = json.decode(refFile.readAsStringSync()) as Map<String, dynamic>;
  final charts = data['charts'] as List<dynamic>;

  const hourOfIndex = <int, int>{
    0: 0, 1: 2, 2: 4, 3: 6, 4: 8, 5: 10, 6: 12,
    7: 14, 8: 16, 9: 18, 10: 20, 11: 22, 12: 23,
  };

  // 本引擎 roleLabel 只有「命宫」带宫字，其余不带；比对前统一去掉后缀。
  String norm(String s) => s.endsWith('宫') ? s.substring(0, s.length - 1) : s;

  // 顺序无关的 Map 签名：Map 迭代顺序不同会产生假分歧，必须先排序再比对。
  String _sig(Map<String, String> m) =>
      (m.keys.toList()..sort()).map((k) => '$k:${m[k]}').join('|');

  test('引擎交叉验证：与 iztro-py 基准逐项对齐', () {
    final baziDiffs = <String>[];
    final bureauDiffs = <String>[];
    final starDiffs = <String>[];
    final sihuaDiffs = <String>[];
    final decadalDiffs = <String>[];
    final brightDiffs = <String>[];
    var checkedPalaces = 0;

    for (final raw in charts) {
      final ref = raw as Map<String, dynamic>;
      final dp = (ref['solar_date'] as String).split('-');
      final solar = DateTime(int.parse(dp[0]), int.parse(dp[1]), int.parse(dp[2]),
          hourOfIndex[ref['time_index'] as int]!);
      final gender = ref['gender'] == '男' ? Gender.male : Gender.female;
      final chart = calculateZiweiChart(
        solar: solar, gender: gender, useTrueSolarTime: false,
      );
      final label = '${ref['solar_date']} 时辰${ref['time_index']} ${ref['gender']}';

      // 八字
      if (chart.baziFull != ref['chinese_date']) {
        baziDiffs.add('$label: 本引擎=${chart.baziFull} 基准=${ref['chinese_date']}');
      }
      // 五行局
      if (chart.elementBureauLabel != ref['five_elements_class']) {
        bureauDiffs.add('$label: 本引擎=${chart.elementBureauLabel} '
            '基准=${ref['five_elements_class']}');
      }

      // 十二宫主星 + 亮度 + 大限区间
      for (final rp in ref['palaces'] as List<dynamic>) {
        final p = rp as Map<String, dynamic>;
        final nameZh = p['name_zh'] as String;
        final match = chart.palaces
            .where((x) => norm(x.roleLabel) == norm(nameZh))
            .toList();
        if (match.isEmpty) {
          starDiffs.add('$label 找不到宫位 $nameZh');
          continue;
        }
        final ours = match.first;

        final refMajors = (p['major_stars'] as List<dynamic>)
            .map((s) => (s as Map<String, dynamic>)['name'] as String)
            .toList();
        final ourMajors = ours.majors.map((s) => s.label).toList();
        if (ourMajors.join(',') != refMajors.join(',')) {
          starDiffs.add('$label $nameZh: 本引擎=[${ourMajors.join(',')}] '
              '基准=[${refMajors.join(',')}]');
        }

        for (final rs in p['major_stars'] as List<dynamic>) {
          final m = rs as Map<String, dynamic>;
          final starName = m['name'] as String;
          final refBright = m['brightness'] as String?;
          final hit = ours.majors.where((s) => s.label == starName).toList();
          if (hit.isNotEmpty &&
              (hit.first.brightness ?? '-') != (refBright ?? '-')) {
            brightDiffs.add('$label $nameZh $starName: '
                '本引擎=${hit.first.brightness ?? '无'} 基准=${refBright ?? '无'}');
          }
        }
        checkedPalaces++;

        final refRange = p['decadal_range'] as List<dynamic>?;
        if (refRange != null) {
          final d = chart.decades
              .where((x) => norm(x.roleLabel) == norm(nameZh))
              .toList();
          if (d.isEmpty) {
            decadalDiffs.add('$label 找不到大限 $nameZh');
          } else if (d.first.startTime != refRange[0] ||
              d.first.endTime != refRange[1]) {
            decadalDiffs.add('$label $nameZh: '
                '本引擎=[${d.first.startTime},${d.first.endTime}] '
                '基准=[${refRange[0]},${refRange[1]}]');
          }
        }
      }

      // 生年四化
      final refSihua = <String, String>{
        for (final s in ref['sihua'] as List<dynamic>)
          (s as Map<String, dynamic>)['star'] as String:
              (s as Map<String, dynamic>)['mutagen'] as String,
      };
      final ourSihua = <String, String>{
        for (final s in chart.sihua) s.starLabelName: s.typeLabel,
      };
      // 必须做顺序无关比较：Map 迭代顺序不同会产生假分歧
      if (_sig(ourSihua) != _sig(refSihua)) {
        sihuaDiffs.add('$label: 本引擎=$ourSihua 基准=$refSihua');
      }
    }

    void report(String title, List<String> list) {
      // ignore: avoid_print
      print('  $title: ${list.isEmpty ? "全部一致" : "${list.length} 处分歧"}');
      for (final d in list) {
        // ignore: avoid_print
        print('    - $d');
      }
    }

    // ignore: avoid_print
    print('\n===== 引擎交叉验证（本 App ziwei_core vs iztro-py 基准）=====');
    // ignore: avoid_print
    print('  已比对宫位数: $checkedPalaces（4 张盘 × 12 宫）');
    report('十二宫主星', starDiffs);
    report('大限区间  ', decadalDiffs);
    report('生年四化  ', sihuaDiffs);
    report('八字      ', baziDiffs);
    report('五行局    ', bureauDiffs);
    report('星曜亮度  ', brightDiffs);
    // ignore: avoid_print
    print('==========================================================\n');

    // 硬断言：紫微结构性字段必须完全一致
    expect(starDiffs, isEmpty, reason: '十二宫主星与基准不一致');
    expect(decadalDiffs, isEmpty, reason: '大限区间与基准不一致');
    expect(sihuaDiffs, isEmpty, reason: '生年四化与基准不一致');

    // 化忌表（走外置 JSON 后的通路）不应为空
    for (var i = 0; i < 10; i++) {
      expect(huaJiStarByStem(i), isNotEmpty, reason: '化忌表第 $i 干为空');
    }
  });
}
