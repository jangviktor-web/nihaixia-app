import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/screens/ziwuliuzhu_screen.dart';
import 'package:nihaisha_app/services/ziwuliuzhu_engine.dart' as eng;

typedef WuMenEntry = ({String a, String b, String element, String acupoints});

const Map<String, String> kExpectedByGan = {
  '甲': '甲己合化土（临泣+太白）',
  '己': '甲己合化土（临泣+太白）',
  '乙': '乙庚合化金（大敦+商阳）',
  '庚': '乙庚合化金（大敦+商阳）',
  '丙': '丙辛合化水（阳谷+经渠）',
  '辛': '丙辛合化水（阳谷+经渠）',
  '丁': '丁壬合化木（少府+通谷）',
  '壬': '丁壬合化木（少府+通谷）',
  '戊': '戊癸合化火（足三里+阴谷）',
  '癸': '戊癸合化火（足三里+阴谷）',
};

const Map<String, String> kGanToMeridian = {
  '甲': '胆经',
  '己': '脾经',
  '乙': '肝经',
  '庚': '大肠经',
  '丙': '小肠经',
  '辛': '肺经',
  '丁': '心经',
  '壬': '膀胱经',
  '戊': '胃经',
  '癸': '肾经',
};

String _sourcePath() {
  const relativePath = 'lib/screens/ziwuliuzhu_screen.dart';
  var directory = Directory.current;
  for (var i = 0; i < 5; i++) {
    final candidate = '${directory.path}/$relativePath';
    if (File(candidate).existsSync()) return candidate;
    directory = directory.parent;
  }
  throw StateError('找不到 $relativePath，cwd=${Directory.current.path}');
}

String _readSource() => File(_sourcePath()).readAsStringSync();

String _stripLineComments(String source) => source
    .split('\n')
    .map((line) {
      final commentStart = line.indexOf('//');
      return commentStart < 0 ? line : line.substring(0, commentStart);
    })
    .join('\n');

String _bracketBlockOf(
  String source,
  String declaration,
  String label,
  String opening,
  String closing,
) {
  final declarationStart = source.indexOf(declaration);
  expect(declarationStart, greaterThanOrEqualTo(0), reason: '源码里找不到 $label 声明');
  final blockStart = source.indexOf(opening, declarationStart);
  expect(blockStart, greaterThanOrEqualTo(0), reason: '$label 声明缺少 $opening');

  var depth = 0;
  for (var i = blockStart; i < source.length; i++) {
    if (source[i] == opening) depth++;
    if (source[i] == closing) {
      depth--;
      if (depth == 0) return source.substring(blockStart + 1, i);
    }
  }
  throw StateError('$label 的 $opening$closing 不闭合');
}

List<WuMenEntry> _parseWuMen() {
  final source = _stripLineComments(_readSource());
  final block = _bracketBlockOf(source, '_wuMen = ', '_wuMen', '[', ']');
  final entryPattern = RegExp(
    r"\(\s*'([^']+)'\s*,\s*'([^']+)'\s*,\s*'([^']+)'\s*,\s*'([^']+)'\s*\)",
  );
  return entryPattern
      .allMatches(block)
      .map(
        (match) => (
          a: match.group(1)!,
          b: match.group(2)!,
          element: match.group(3)!,
          acupoints: match.group(4)!,
        ),
      )
      .toList();
}

Map<String, String> _parseBenXue() {
  final source = _stripLineComments(_readSource());
  final block = _bracketBlockOf(source, '_benXue = ', '_benXue', '{', '}');
  final entryPattern = RegExp(r"'([^']+)'\s*:\s*'([^']+)'");
  return Map.fromEntries(
    entryPattern
        .allMatches(block)
        .map((match) => MapEntry(match.group(1)!, match.group(2)!)),
  );
}

Map<String, String> _parseUiWuMenTable() {
  final source = _stripLineComments(_readSource());
  final rowPattern = RegExp(
    r"Row\(children:\s*\[Expanded\(child:\s*Text\('([^']+合化[^']+)'\)\),\s*Text\('([^']+)'\)\]\)",
  );
  final rows = rowPattern.allMatches(source).toList();
  expect(rows, hasLength(5), reason: '五门十变 UI 表应恰有 5 行');
  return Map.fromEntries(
    rows.map((match) => MapEntry(match.group(1)!, match.group(2)!)),
  );
}

Future<void> _selectDate(
  WidgetTester tester,
  DateTime currentDate,
  DateTime targetDate,
) async {
  await tester.tap(find.widgetWithIcon(OutlinedButton, Icons.calendar_today));
  await tester.pumpAndSettle();

  if (targetDate.year != currentDate.year ||
      targetDate.month != currentDate.month) {
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
  }

  await tester.tap(find.text('${targetDate.day}').last);
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

void main() {
  group('五门十变 · 数据守门', () {
    test('五条合化关系符合参考站快照，十干均命中且夫妻干结果相同', () {
      final entries = _parseWuMen();
      expect(entries, hasLength(5), reason: '五门十变应恰有 5 条合化关系');

      final actualByGan = <String, String>{};
      for (final entry in entries) {
        final text =
            '${entry.a}${entry.b}合化${entry.element}（${entry.acupoints}）';
        actualByGan[entry.a] = text;
        actualByGan[entry.b] = text;
      }

      expect(actualByGan, kExpectedByGan);
      for (final entry in entries) {
        expect(
          actualByGan[entry.a],
          actualByGan[entry.b],
          reason: '${entry.a}${entry.b}夫妻干应返回同一条关系',
        );
      }
    });

    test('乙庚配穴显式防回退到讲义口误“行间、二间”', () {
      final entry = _parseWuMen().singleWhere(
        (item) => item.a == '乙' && item.b == '庚',
      );
      final text = '${entry.a}${entry.b}合化${entry.element}（${entry.acupoints}）';

      expect(text, kExpectedByGan['乙']);
      expect(text, isNot(contains('行间')));
      expect(text, isNot(contains('二间')));
    });

    test('每条夫妻经配穴均等于双方在 _benXue 中的本穴', () {
      final benXue = _parseBenXue();
      for (final entry in _parseWuMen()) {
        final firstMeridian = kGanToMeridian[entry.a]!;
        final secondMeridian = kGanToMeridian[entry.b]!;
        final expected = '${benXue[firstMeridian]}+${benXue[secondMeridian]}';
        expect(
          entry.acupoints,
          expected,
          reason: '${entry.a}${entry.b}配穴必须随两条夫妻经的本穴表保持一致',
        );
      }
    });

    test('_wuMen 常量与硬编码五门十变 UI 表逐行一致', () {
      final expectedUiRows = <String, String>{
        for (final entry in _parseWuMen())
          '${entry.a}${entry.b}合化${entry.element}': entry.acupoints,
      };
      expect(_parseUiWuMenTable(), expectedUiRows);
    });
  });

  group('五门十变 · 运行时 UI', () {
    testWidgets('_getWuMenInfo 经真实页面对连续十日覆盖全部十干', (tester) async {
      final originalSize = tester.view.physicalSize;
      final originalDpr = tester.view.devicePixelRatio;
      addTearDown(() {
        tester.view.physicalSize = originalSize;
        tester.view.devicePixelRatio = originalDpr;
      });
      tester.view.physicalSize = const Size(1200, 4000);
      tester.view.devicePixelRatio = 1;

      await tester.pumpWidget(const MaterialApp(home: ZiWuLiuZhuScreen()));
      await tester.pumpAndSettle();

      final firstDate = DateUtils.dateOnly(DateTime.now());
      var currentDate = firstDate;
      final seenGans = <String>{};
      for (var dayOffset = 0; dayOffset < 10; dayOffset++) {
        final targetDate = firstDate.add(Duration(days: dayOffset));
        await _selectDate(tester, currentDate, targetDate);
        currentDate = targetDate;

        final dayGan = eng.ganName(eng.calcDayGanZhi(targetDate).dayGan);
        seenGans.add(dayGan);
        expect(
          find.text(kExpectedByGan[dayGan]!),
          findsOneWidget,
          reason: '$targetDate 的日干 $dayGan 未渲染正确五门十变文案',
        );
      }
      expect(seenGans, kExpectedByGan.keys.toSet(), reason: '连续十日应覆盖十个天干');
    });
  });
}
