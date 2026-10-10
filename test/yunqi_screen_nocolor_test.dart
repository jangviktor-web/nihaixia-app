// 五运六气屏幕层「无硬编码颜色」静态扫描（QA 独立验证）
//
// 背景：本项目铁律——屏幕层硬编码颜色会在深色模式下出问题，且难以被
// 运行时测试捕获。本测试直接扫描 yunqi_screen.dart 源码，禁止文字/
// 背景使用 Color(0x..) 或 Colors.<非 transparent> 字面量。
//
// 运行：flutter test test/yunqi_screen_nocolor_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final File f = File('lib/screens/yunqi_screen.dart');

  test('yunqi_screen.dart 存在', () {
    expect(f.existsSync(), isTrue, reason: '找不到 ${f.path}');
  });

  test('不得出现 Color(0x..) 硬编码颜色', () {
    final String src = f.readAsStringSync();
    final RegExp re = RegExp(r'Color\(0x[0-9a-fA-F]+\)');
    final Iterable<RegExpMatch> m = re.allMatches(src);
    expect(m.isEmpty, isTrue,
        reason: '发现硬编码 Color(0x..)：'
            '${m.map((RegExpMatch e) => e.group(0)).join(", ")} '
            '（应改用 Theme.colorScheme token）');
  });

  test('不得出现 Colors.<name>（Colors.transparent 除外）', () {
    final String src = f.readAsStringSync();
    final RegExp re = RegExp(r'Colors\.([a-zA-Z]+)');
    final List<String> banned = <String>[];
    for (final RegExpMatch e in re.allMatches(src)) {
      final String name = e.group(1)!;
      if (name != 'transparent') banned.add('Colors.$name');
    }
    expect(banned.isEmpty, isTrue,
        reason: '发现硬编码 Colors.*：${banned.join(", ")} '
            '（transparent 可豁免）');
  });
}
