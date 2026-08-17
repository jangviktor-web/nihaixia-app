import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:ziwei_core/ziwei_core.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart';

bool _setEq<T>(Set<T> a, Set<T> b) =>
    a.containsAll(b) && b.containsAll(a);

String _diff<T>(Set<T> a, Set<T> b) {
  final onlyA = a.difference(b);
  final onlyB = b.difference(a);
  return '+$onlyA -$onlyB';
}

/// 跨引擎精度验证：把 MingLi-Bench（DestinyLinker/MingLi-Bench，MIT）的
/// `fortune_api_results.json`（32 道由 iztro 预排的八字+紫微命盘，源自
/// 全球算命师大赛 2022–2025 赛题）作为独立参考集，与本 app 的 ziwei_core
/// 引擎输出逐字段比对。比对按物理地支匹配宫位，绕过宫名一词之差。
///
/// 关键修复：本引擎原默认开启「真太阳时」(useTrueSolarTime=true)，会按默认
/// 120E/30N 强行修正，导致无地理位置输入的离线 app 时辰整体位移；已改为
/// 平太阳时（useTrueSolarTime=false），与 iztro / 主流排盘一致。
///
/// 已知流派约定差（非 bug，不计入失败）：
///   - case_31：年柱 立春(本引擎) vs 春节(iztro)
///   - case_7 ：身主 铃星(本引擎) vs 火星(iztro，火六局)
///   - 杂曜(aux)：空亡命名/取舍为门派浮动，预期内差异，不断言。
void main() {
  test('MingLi-Bench cross-engine comparison (ziwei_core vs iztro)', () async {
    final file = File('test/data/fortune_api_results.json');
    final content = await file.readAsString();
    final List<dynamic> cases = jsonDecode(content);

    int used = 0;
    int baziOk = 0,
        fiveOk = 0,
        lifeOk = 0,
        bodyOk = 0,
        mingOk = 0,
        shenOk = 0,
        majorOk = 0,
        auxOk = 0,
        sihuaOk = 0;
    int baziOkC = 0,
        baziOkF = 0,
        majorOkC = 0,
        majorOkF = 0,
        lifeOkC = 0,
        lifeOkF = 0;
    final List<String> lines = [];
    final List<String> vocabGaps = [];
    final List<String> baziDiffs = [];

    for (final c in cases) {
      final bi = c['birth_info'] as Map<String, dynamic>;
      final ad = c['api_response']?['data']?['data'] as Map<String, dynamic>?;
      if (ad == null || ad['palaces'] == null) continue;
      if (ad['success'] == false) continue;
      used++;

      final gender = bi['gender'] == '男' ? Gender.male : Gender.female;
      final country = bi['country'] as String? ?? '';
      final isChina = country == '中国';
      final dt = DateTime(
        bi['year'] as int,
        bi['month'] as int,
        bi['day'] as int,
        bi['hour'] as int,
        bi['minute'] as int,
      );

      // ---- benchmark expected ----
      final expBazi = ad['chineseDate'] as String;
      final expFive = ad['fiveElementsClass'] as String?;
      final expLife = ad['earthlyBranchOfSoulPalace'] as String?;
      final expBody = ad['earthlyBranchOfBodyPalace'] as String?;
      final expMing = ad['soul'] as String?;
      final expShen = ad['body'] as String?;

      final bench = <String, Map<String, Set<String>>>{};
      for (final p in ad['palaces'] as List) {
        final branch = p['earthlyBranch'] as String;
        final major = <String>{};
        final aux = <String>{};
        final sihua = <String>{};
        for (final s in p['majorStars'] as List) {
          major.add(s['name'] as String);
          final m = s['mutagen'] as String? ?? '';
          if (m.isNotEmpty) sihua.add('${s['name']}$m');
        }
        for (final s in p['minorStars'] as List) {
          aux.add(s['name'] as String);
          final m = s['mutagen'] as String? ?? '';
          if (m.isNotEmpty) sihua.add('${s['name']}$m');
        }
        for (final s in p['adjectiveStars'] as List) {
          aux.add(s['name'] as String);
          final m = s['mutagen'] as String? ?? '';
          if (m.isNotEmpty) sihua.add('${s['name']}$m');
        }
        bench[branch] = {'major': major, 'aux': aux, 'sihua': sihua};
      }

      // ---- my engine output ----
      // 本测试对齐 iztro/MingLi-Bench 参考集，使用平太阳时；UI 默认使用真太阳时。
      final chart = calculateZiweiChart(
        solar: dt,
        gender: gender,
        useTrueSolarTime: false,
      );
      String? myLife, myBody;
      for (final p in chart.palaces) {
        if (p.isLife) myLife = p.branchLabel;
        if (p.isBody) myBody = p.branchLabel;
      }
      final mine = <String, Map<String, Set<String>>>{};
      for (final p in chart.palaces) {
        final branch = p.branchLabel;
        final major = <String>{};
        final aux = <String>{};
        final sihua = <String>{};
        for (final s in p.stars) {
          if (s.type == StarType.major) {
            major.add(s.label);
            if (s.sihua != null) sihua.add('${s.label}${s.sihuaText}');
          } else if (s.type == StarType.lucky ||
              s.type == StarType.bad ||
              s.type == StarType.minor ||
              s.type == StarType.other) {
            aux.add(s.label);
            if (s.sihua != null) sihua.add('${s.label}${s.sihuaText}');
          }
        }
        mine[branch] = {'major': major, 'aux': aux, 'sihua': sihua};
      }

      // ---- compare ----
      final bBazi = chart.baziFull == expBazi;
      final bFive = chart.elementBureauLabel == expFive;
      final bLife = myLife == expLife;
      final bBody = myBody == expBody;
      final bMing = chart.mingZhuLabel == expMing;
      final bShen = chart.shenZhuLabel == expShen;

      bool cMajor = true, cAux = true, cSihua = true;
      final notes = <String>[];
      for (final branch in bench.keys) {
        final b = bench[branch]!;
        final m = mine[branch];
        if (m == null) {
          cMajor = cAux = cSihua = false;
          notes.add('$branch MISSING in mine');
          continue;
        }
        if (!_setEq(b['major']!, m['major']!)) {
          cMajor = false;
          notes.add('$branch major ${_diff(b['major']!, m['major']!)}');
        }
        if (!_setEq(b['aux']!, m['aux']!)) {
          cAux = false;
          notes.add('$branch aux ${_diff(b['aux']!, m['aux']!)}');
        }
        if (!_setEq(b['sihua']!, m['sihua']!)) {
          cSihua = false;
          notes.add('$branch sihua ${_diff(b['sihua']!, m['sihua']!)}');
        }
      }

      if (bBazi) {
        baziOk++;
        if (isChina) baziOkC++; else baziOkF++;
      } else {
        baziDiffs.add(
          '${c['case_id']} [$country] exp="$expBazi" got="${chart.baziFull}"',
        );
      }
      if (bFive) fiveOk++;
      if (bLife) {
        lifeOk++;
        if (isChina) lifeOkC++; else lifeOkF++;
      }
      if (bBody) bodyOk++;
      if (bMing) mingOk++;
      if (bShen) shenOk++;
      if (cMajor) {
        majorOk++;
        if (isChina) majorOkC++; else majorOkF++;
      }
      if (cAux) auxOk++;
      if (cSihua) sihuaOk++;

      final flags = <String>[];
      if (!bBazi) flags.add('BAZI');
      if (!bFive) flags.add('FIVE');
      if (!bLife) flags.add('LIFE');
      if (!bBody) flags.add('BODY');
      if (!bMing) flags.add('MING');
      if (!bShen) flags.add('SHEN');
      if (!cMajor) flags.add('MAJOR');
      if (!cAux) flags.add('AUX');
      if (!cSihua) flags.add('SIHUA');

      final status = flags.isEmpty ? 'OK ' : flags.join(',');
      lines.add(
        '${c['case_id']} ${bi['gender']} ${bi['year']}-${bi['month']}-${bi['day']} '
        '${bi['hour']}:${bi['minute']} ${bi['country']} | $status',
      );
      if (notes.isNotEmpty) {
        for (final n in notes) lines.add('    $n');
      }

      // vocab gap: my label equals a raw key (ascii) => missing map entry
      for (final p in chart.palaces) {
        for (final s in p.stars) {
          if (s.label == s.key && RegExp(r'^[a-z_]+$').hasMatch(s.key)) {
            vocabGaps.add('${c['case_id']}: ${s.key}');
          }
        }
      }
    }

    final buf = StringBuffer();
    buf.writeln('=== MingLi-Bench cross-engine (ziwei_core vs iztro) ===');
    buf.writeln('cases total: ${cases.length}, used: $used');
    buf.writeln();
    for (final l in lines) buf.writeln(l);
    buf.writeln();
    buf.writeln('--- AGGREGATE (used=$used) ---');
    buf.writeln('bazi        $baziOk/$used   (China $baziOkC / Foreign $baziOkF)');
    buf.writeln('five        $fiveOk/$used');
    buf.writeln('lifeBranch  $lifeOk/$used   (China $lifeOkC / Foreign $lifeOkF)');
    buf.writeln('bodyBranch  $bodyOk/$used');
    buf.writeln('mingZhu     $mingOk/$used');
    buf.writeln('shenZhu     $shenOk/$used');
    buf.writeln('major       $majorOk/$used   (China $majorOkC / Foreign $majorOkF)');
    buf.writeln('aux         $auxOk/$used   (convention-variable; informational)');
    buf.writeln('sihua       $sihuaOk/$used');
    if (baziDiffs.isNotEmpty) {
      buf.writeln();
      buf.writeln('--- BAZI DIFFS (China vs Foreign) ---');
      for (final d in baziDiffs) buf.writeln(d);
    }
    if (vocabGaps.isNotEmpty) {
      buf.writeln();
      buf.writeln('--- VOCAB GAPS (raw key used as label) ---');
      buf.writeln(vocabGaps.toSet().join('\n'));
    }
    // ignore: avoid_print
    print(buf.toString());

    // ===== 回归断言（达尔文实证：ziwei_core vs iztro 32-case 参考集）=====
    // 核心排盘字段应 32/32 全中；八字/身主各允许 1 例已知流派约定差。
    expect(fiveOk, 32, reason: '五行局应 32/32');
    expect(lifeOk, 32, reason: '命宫地支应 32/32');
    expect(bodyOk, 32, reason: '身宫地支应 32/32');
    expect(mingOk, 32, reason: '命主应 32/32');
    expect(majorOk, 32, reason: '十四主星应 32/32');
    expect(sihuaOk, 32, reason: '生年四化应 32/32');
    // 已知约定差（非 bug，文档化）：
    //  - case_31：年柱 立春(本引擎) vs 春节(iztro) → 八字 31/32
    //  - case_7 ：身主 铃星(本引擎) vs 火星(iztro，火六局) → 身主 31/32
    expect(baziOk, 31, reason: '八字仅允许 case_31 年柱立春/春节差');
    expect(shenOk, 31, reason: '身主仅允许 case_7 铃星/火星差');
    // 杂曜(aux)不断言：空亡命名/取舍为门派浮动，预期内差异。
    // 词汇完整性：星曜 key 必须都有中文映射，不得出现 raw key 当 label。
    expect(vocabGaps, isEmpty, reason: '星曜 key 缺失中文映射');
  });
}
