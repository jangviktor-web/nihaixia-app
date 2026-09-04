// MingLi-Bench（全球算命师大赛 2022-2025 真题，iztro 预计算排盘）交叉验证。
//
// 数据：test/fixtures/mingli/fortune_api_results.json（32 例，来源
// https://github.com/DestinyLinker/MingLi-Bench ，MIT）。
// 对比口径：钟表时间排盘（useTrueSolarTime:false），与 iztro 默认行为对齐；
// 四柱以 api_response.data.data.chineseDate（空格分隔四柱）为 ground truth。
//
// 断言策略：
//   - 非 23 点出生的案例：四柱必须 100% 一致（硬门禁，不一致即引擎 bug）；
//   - 已知例外：iztro（紫微系）年柱按农历正月初一换年，八字正统按立春。
//     位于「立春后~农历新年前」窗口（阳历 2月上中旬）的案例会出现年柱单柱差异
//     （如 1988-02-15 台湾例：iztro=丁卯，我们=戊辰，我们正确），归入报告不断言；
//   - 23:00-23:59 晚子时案例：流派差异区（日柱进位 vs 当日干），只报告不断言。
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/services/bazi_service.dart';

void main() {
  late List<dynamic> cases;

  setUpAll(() {
    final file = File('test/fixtures/mingli/fortune_api_results.json');
    expect(file.existsSync(), isTrue, reason: '请先下载 MingLi-Bench fixtures');
    cases = jsonDecode(file.readAsStringSync()) as List<dynamic>;
  });

  test('MingLi-Bench 32 例四柱交叉验证', () {
    var matched = 0;
    var skipped = 0;
    final normalMismatches = <String>[];
    final explained = <String>[];
    final lateZiRows = <String>[];

    for (final raw in cases) {
      final c = raw as Map<String, dynamic>;
      final info = c['birth_info'] as Map<String, dynamic>;
      final api = c['api_response'] as Map<String, dynamic>;
      if (api['success'] != true) {
        skipped++;
        continue;
      }
      final hour = info['hour'];
      final minute = info['minute'] ?? 0;
      if (hour == null) {
        skipped++;
        continue;
      }
      final solar = DateTime(
        info['year'] as int,
        info['month'] as int,
        info['day'] as int,
        hour as int,
        minute as int,
      );
      final isMale = (info['gender'] as String? ?? '男') == '男';
      final ours = computeBaZiPaipan(solar, isMale: isMale, useTrueSolarTime: false);
      final oursStr =
          '${ours.bazi.year} ${ours.bazi.month} ${ours.bazi.day} ${ours.bazi.time}';
      final data = api['data']['data'] as Map<String, dynamic>;
      final truth = data['chineseDate'] as String;
      // 归一空白后逐 token 比较
      final truthTokens = truth.trim().split(RegExp(r'\s+'));
      final ourTokens = oursStr.split(' ');
      final same = List.generate(4, (i) => truthTokens[i] == ourTokens[i]);
      if (same.every((x) => x)) {
        matched++;
      } else if (hour == 23) {
        lateZiRows.add(
          '${info['year']}-${info['month']}-${info['day']} $hour:$minute '
          'iztro=[$truth] ours=[$oursStr] 差异柱=${[for (var i = 0; i < 4; i++) if (!same[i]) i + 1]}',
        );
      } else if (same.take(1).every((x) => x == false) &&
          same.skip(1).every((x) => x) &&
          (info['month'] as int) == 2 &&
          (info['day'] as int) <= 17) {
        // 年柱单柱差异 + 2月上中旬 = iztro 紫微年界（农历新年） vs 八字立春，已解释。
        explained.add(
          '${info['year']}-${info['month']}-${info['day']} iztro=[$truth] ours=[$oursStr]（立春口径，我们正确）',
        );
      } else {
        normalMismatches.add(
          '${info['year']}-${info['month']}-${info['day']} $hour:$minute '
          'iztro=[$truth] ours=[$oursStr] 差异柱=${[for (var i = 0; i < 4; i++) if (!same[i]) i + 1]}',
        );
      }
    }

    // ignore: avoid_print
    print('MingLi-Bench 对账：matched=$matched skipped=$skipped '
        'normalMismatches=${normalMismatches.length} '
        '年界口径差异=${explained.length} lateZi=${lateZiRows.length}');
    for (final m in explained) {
      // ignore: avoid_print
      print('ℹ️ 年界口径（我们按立春，正确）：$m');
    }
    for (final m in lateZiRows) {
      // ignore: avoid_print
      print('ℹ️ 晚子时流派差异：$m');
    }
    for (final m in normalMismatches) {
      // ignore: avoid_print
      print('❌ $m');
    }

    expect(normalMismatches, isEmpty,
        reason: '排除已解释的年界/晚子时口径后，四柱必须与 iztro 完全一致');
    expect(matched + explained.length + lateZiRows.length + skipped, cases.length);
  });
}
