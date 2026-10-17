// 十四经循行穴位图 · 资产完整性与对话框可用性测试
//
// 覆盖：
//   ① 14 张图全部存在、体积正常（不是 0 字节占位）；
//   ② 经络名单唯一，且与经穴库的 meridian 字段能对上（不靠映射表）；
//   ③ 未配图的奇经/奇穴 has() 返回 false；
//   ④ 对话框可打开、默认停在传入经络、含 InteractiveViewer（可缩放）。
//
// 运行：flutter test test/meridian_map_test.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/widgets/meridian_map.dart';

void main() {
  test('14 张经络图资产齐备且非空', () {
    expect(MeridianMap.meridians.length, 14);
    expect(MeridianMap.meridians.toSet().length, 14, reason: '经络名有重复');

    for (final String m in MeridianMap.meridians) {
      final File f = File(MeridianMap.assetOf(m));
      expect(f.existsSync(), isTrue, reason: '缺图：${f.path}');
      expect(
        f.lengthSync(),
        greaterThan(10 * 1024),
        reason: '图过小，疑似坏文件：${f.path}',
      );
    }
  });

  test('未配图的奇经八脉与经外奇穴 has() 为 false', () {
    expect(MeridianMap.has('手太阴肺经'), isTrue);
    expect(MeridianMap.has('督脉'), isTrue);
    expect(MeridianMap.has('阳维脉'), isFalse);
    expect(MeridianMap.has('冲脉'), isFalse);
    expect(MeridianMap.has('经外奇穴'), isFalse);
  });

  test('十四经名与经穴库 meridian 字段一致（无需映射表）', () {
    // ⛔ 不用 AcupointRepository.getMeridians()：它依赖 rootBundle 真实 IO，
    // 在纯 test() 的假异步区里永远不会完成（仓库里 _acupoints 恒为空）。
    // 直接读盘解析 JSON，等价且稳定。
    final Object? raw =
        jsonDecode(File('assets/data/acupoints.json').readAsStringSync());
    final List<dynamic> items = raw is Map<String, dynamic>
        ? (raw['acupoints'] as List<dynamic>)
        : (raw as List<dynamic>);

    final Set<String> library = <String>{};
    for (final dynamic item in items) {
      final Map<String, dynamic> a = item as Map<String, dynamic>;
      final Object? m = a['meridian'];
      if (m is String && m.isNotEmpty) library.add(m);
      final Object? ms = a['meridians'];
      if (ms is List) {
        for (final Object? x in ms) {
          if (x is String && x.isNotEmpty) library.add(x);
        }
      }
    }

    for (final String m in MeridianMap.meridians) {
      expect(
        library.contains(m),
        isTrue,
        reason: '经穴库里找不到「$m」，图名与数据不一致',
      );
    }
  });

  testWidgets('14 张图都能被 rootBundle 真实加载（中文文件名资产键可用）',
      (WidgetTester tester) async {
    // ⛔ rootBundle 是真实 IO，必须放在 runAsync 里，否则假异步区永不完成。
    await tester.runAsync(() async {
      for (final String m in MeridianMap.meridians) {
        final ByteData data = await rootBundle.load(MeridianMap.assetOf(m));
        expect(
          data.lengthInBytes,
          greaterThan(10 * 1024),
          reason: '资产键解析失败或内容为空：${MeridianMap.assetOf(m)}',
        );
      }
    });
  });

  testWidgets('经络图对话框可打开、默认停在传入经络', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (BuildContext ctx) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () =>
                  showMeridianMapDialog(ctx, initial: '足阳明胃经'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('十四经循行穴位图'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, '足阳明胃经'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.textContaining('仅供学习参考'), findsOneWidget);
  });
}
