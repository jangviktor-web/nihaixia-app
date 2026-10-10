import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/screens/ziwuliuzhu_screen.dart';

// ─────────────────────────────────────────────────────────────
// 纳子法「本穴表」独立性回归。
//
// 背景：本穴表曾经用错口径（肝经取「行间」、大肠经取「二间」、心包/三焦自行
// 推导成「阴谷/通谷」）。改为参考站 acuherb.xyz/ziwu 的教材通用口径后，
// `_getBenXue` 收敛成一行 `_benXue[meridian] ?? ''`。
//
// ⚠️ 为什么必须做「源码对账」而不是只跑业务测试：
// `_benXue` / `_getBenXue` / `_zhiToMeridian` 都是库私有成员（下划线前缀），
// 测试文件无法直接 import 调用；一旦 `_benXue` 的 key 与 `_zhiToMeridian`
// 的 value 出现哪怕一个字的拼写不一致（如「胆」vs「胆经」），map 取值会
// **静默返回空串**，编译不报错、引擎测试也全绿，只有 UI 上「本穴」一栏空白。
// 所以这里同时做两件事：
//   1) 静态对账：解析源文件，把两张表的 key/value 逐格比对（下方第 1~5 组）
//   2) 运行时冒烟：真实渲染纳子法 Tab，确认本穴文案非空且与表一致（第 6 组）
// ─────────────────────────────────────────────────────────────

/// 参考站 acuherb.xyz/ziwu 教材通用口径的十二经本穴期望值。
/// ⛔ 这是外部权威口径，改了源码却把这组期望值顺势改掉 = 直接算错。
const Map<String, String> kExpectedBenXue = {
  '胆经': '临泣',
  '肝经': '大敦',
  '小肠经': '阳谷',
  '心经': '少府',
  '胃经': '足三里',
  '脾经': '太白',
  '大肠经': '商阳',
  '肺经': '经渠',
  '膀胱经': '通谷',
  '肾经': '阴谷',
  '心包经': '劳宫',
  '三焦经': '支沟',
};

const List<String> kDiZhi = [
  '子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥',
];

String _sourcePath() {
  const rel = 'lib/screens/ziwuliuzhu_screen.dart';
  var dir = Directory.current;
  for (int i = 0; i < 5; i++) {
    final candidate = '${dir.path}/$rel';
    if (File(candidate).existsSync()) return candidate;
    dir = dir.parent;
  }
  throw StateError('找不到 $rel，cwd=${Directory.current.path}');
}

String _readSource() => File(_sourcePath()).readAsStringSync();

/// 去掉行注释，避免注释里出现的穴名干扰后续正则解析。
String _stripLineComments(String src) => src
    .split('\n')
    .map((line) {
      final i = line.indexOf('//');
      return i < 0 ? line : line.substring(0, i);
    })
    .join('\n');

/// 取出 `_benXue = { ... }` 这类声明的花括号块内容（按括号配平，不依赖缩进）。
String _blockOf(String src, String decl, String label) {
  final declAt = src.indexOf(decl);
  expect(declAt, greaterThanOrEqualTo(0), reason: '源码里找不到 $label 声明');
  final open = src.indexOf('{', declAt);
  expect(open, greaterThanOrEqualTo(0), reason: '$label 声明缺少左花括号');
  var depth = 0;
  for (var i = open; i < src.length; i++) {
    if (src[i] == '{') depth++;
    if (src[i] == '}') {
      depth--;
      if (depth == 0) return src.substring(open + 1, i);
    }
  }
  throw StateError('$label 花括号不闭合');
}

/// 解析 `_benXue`（经络→本穴）。
Map<String, String> _parseBenXueTable() {
  final block = _blockOf(_stripLineComments(_readSource()), '_benXue = ', '_benXue');
  final re = RegExp(r"'([^']+)'\s*:\s*'([^']+)'");
  final entries = re
      .allMatches(block)
      .map((m) => MapEntry(m.group(1)!, m.group(2)!))
      .toList();
  return Map<String, String>.fromEntries(entries);
}

/// 解析 `_zhiToMeridian`（地支→(经络, 时段)），返回地支→经络。
Map<String, String> _parseZhiToMeridian() {
  final block =
      _blockOf(_stripLineComments(_readSource()), '_zhiToMeridian = ', '_zhiToMeridian');
  final re = RegExp(r"'(.)'\s*:\s*\(\s*'([^']+)'");
  return Map<String, String>.fromEntries(
      re.allMatches(block).map((m) => MapEntry(m.group(1)!, m.group(2)!)));
}

/// 复制自 `_getShichenIndex`：把小时分钟映射到十二地支索引（子=0）。
int _shichenIndex(DateTime dt) {
  final minutes = dt.hour * 60 + dt.minute;
  if (minutes >= 1380 || minutes < 60) return 0;
  if (minutes < 180) return 1;
  if (minutes < 300) return 2;
  if (minutes < 420) return 3;
  if (minutes < 540) return 4;
  if (minutes < 660) return 5;
  if (minutes < 780) return 6;
  if (minutes < 900) return 7;
  if (minutes < 1020) return 8;
  if (minutes < 1140) return 9;
  if (minutes < 1260) return 10;
  return 11;
}

void main() {
  group('纳子法本穴表 · 静态对账', () {
    test('_zhiToMeridian 覆盖十二地支且经络名互不相同', () {
      final m = _parseZhiToMeridian();
      expect(m.length, 12, reason: '地支应有 12 条');
      for (final zhi in kDiZhi) {
        expect(m.containsKey(zhi), isTrue, reason: '缺地支 $zhi');
      }
      expect(m.values.toSet().length, 12, reason: '存在重复经络名');
    });

    // ⛔ 本次修复最容易藏 bug 的一格：key/value 不一致会静默变空串。
    test('_benXue 的 key 与 _zhiToMeridian 的经络名完全一致', () {
      final zhiToMeridian = _parseZhiToMeridian();
      final benXue = _parseBenXueTable();

      expect(benXue.length, 12, reason: '本穴表应有 12 条（十二经各一穴）');
      final missing =
          zhiToMeridian.values.where((mer) => !benXue.containsKey(mer)).toList();
      final orphan =
          benXue.keys.where((mer) => !zhiToMeridian.values.contains(mer)).toList();
      expect(missing, isEmpty,
          reason: '以下经络已排入时辰但本穴表缺 key，UI 会显示空白：$missing');
      expect(orphan, isEmpty, reason: '本穴表存在无对应时辰的孤儿 key：$orphan');
    });

    test('十二经本穴均非空且互不重复', () {
      final benXue = _parseBenXueTable();
      for (final entry in benXue.entries) {
        expect(entry.value.trim(), isNotEmpty,
            reason: '${entry.key} 的本穴为空串');
      }
      expect(benXue.values.toSet().length, benXue.length,
          reason: '十二经本穴不应重复（每经各一穴）');
    });

    test('口径快照＝参考站 acuherb.xyz/ziwu（防回退到旧口径）', () {
      final benXue = _parseBenXueTable();
      expect(benXue.length, kExpectedBenXue.length);
      for (final entry in kExpectedBenXue.entries) {
        expect(benXue[entry.key], entry.value,
            reason: '${entry.key} 本穴口径不符');
      }
      // 旧口径的三处雷区显式点名，避免有人「改回推导」。
      expect(benXue['肝经'], isNot('行间'), reason: '肝经本穴误回退到荥穴（子穴）行间');
      expect(benXue['大肠经'], isNot('二间'), reason: '大肠经本穴误回退到荥穴（子穴）二间');
      expect(benXue['心包经'], isNot(contains('阴谷')), reason: '心包经误回退到「借阴谷」推导');
      expect(benXue['三焦经'], isNot(contains('通谷')), reason: '三焦经误回退到「借通谷」推导');
    });

    test('未知经络：查不到且有 ?? \'\' 兜底（返回空串而非崩溃/填空 UI）', () {
      final benXue = _parseBenXueTable();
      for (final unknown in ['任脉', '督脉', '带脉', '奇经', '']) {
        expect(benXue.containsKey(unknown), isFalse, reason: '$unknown 不应进本穴表');
        expect(benXue[unknown] ?? '', '', reason: '$unknown 应安全回落为空串');
      }

      final src = _stripLineComments(_readSource());
      final declAt = src.indexOf('_getBenXue(String meridian) {');
      expect(declAt, greaterThanOrEqualTo(0), reason: '找不到 _getBenXue 实现');
      final impl = src.substring(declAt, src.indexOf('}', declAt) + 1);
      expect(impl.contains('_benXue[meridian]'), isTrue,
          reason: '_getBenXue 不再是查表实现，请复核');
      expect(RegExp(r"\?\?\s*''").hasMatch(impl), isTrue,
          reason: '_getBenXue 缺少 ?? \'\' 兜底，未知经络会返回 null 并在 UI 抛错');
    });
  });

  group('纳子法 Tab · 运行时冒烟', () {
    testWidgets('渲染后「取其本穴 X」非空且与本穴表一致（当前时辰）', (tester) async {
      final benXue = _parseBenXueTable();
      final zhiToMeridian = _parseZhiToMeridian();

      // ListView 只构建可见 sliver：测试机默认视口放不下整条结果链，
      // 本穴卡片会被「跳过构建」。放大视口后再滚动，确保文案真的参与布局。
      final originSize = tester.view.physicalSize;
      final originDpr = tester.view.devicePixelRatio;
      addTearDown(() {
        tester.view.physicalSize = originSize;
        tester.view.devicePixelRatio = originDpr;
      });
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(const MaterialApp(home: ZiWuLiuZhuScreen()));
      await tester.pumpAndSettle();

      final idx = _shichenIndex(DateTime.now());
      final zhi = kDiZhi[idx];
      final meridian = zhiToMeridian[zhi]!;
      final expected = benXue[meridian]!;
      expect(expected, isNotEmpty, reason: '当前时辰 $zhi → $meridian 查不到本穴');

      final target = find.textContaining('取其本穴');
      if (target.evaluate().isEmpty) {
        await tester.scrollUntilVisible(
          target,
          -300,
          scrollable: find.byType(Scrollable),
          maxScrolls: 30,
        );
        await tester.pumpAndSettle();
      }

      final sentences = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .whereType<String>()
          .where((s) => s.startsWith('当$zhi时'))
          .toList();
      expect(sentences, hasLength(1), reason: '未找到唯一的长句文案');
      expect(sentences.single, endsWith('取其本穴 $expected'),
          reason: '$zhi时/$meridian 渲染出的本穴与本穴表不一致');
      expect(find.text('$meridian 本穴'), findsOneWidget);
    });
  });
}
