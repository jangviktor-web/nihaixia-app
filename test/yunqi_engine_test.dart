// 五运六气引擎 · 黄金对拍 + 不变量守门测试
//
// 独立验证方（QA）撰写，不采信实现方自查。核心口径：
//   * 运气年以「立春」为界；客气六步以「大寒」为界（λ=300°）。
//   * 参考站外层用日历年、明细用立春年（刻意对齐夹具）。
//
// 夹具：D:\tools\yunqi_ref.json（62 年 × 24 字段 + 372 客气六步采样点）。
// 运行：flutter test test/yunqi_engine_test.dart

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/services/yunqi_engine.dart';

// ==================== 夹具加载 ====================

const String kFixturePath = r'D:\tools\yunqi_ref.json';

Map<String, dynamic>? _fixtureCache;

Map<String, dynamic> loadFixture() {
  if (_fixtureCache != null) return _fixtureCache!;
  final File f = File(kFixturePath);
  if (!f.existsSync()) {
    fail('夹具不存在: $kFixturePath');
  }
  _fixtureCache = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
  return _fixtureCache!;
}

Map<String, dynamic> years() =>
    loadFixture()['years'] as Map<String, dynamic>;

List<Map<String, dynamic>> qiSteps() => (loadFixture()['qi_steps'] as List)
    .cast<Map<String, dynamic>>();

/// 夹具 24 字段名（权威清单）。
List<String> fieldsOfYear() =>
    (loadFixture()['fields_of_yunqiYearData'] as List).cast<String>();

/// 把 sampleAt 字符串（'1900-01-21 12:00'）解析成本地墙钟 DateTime。
DateTime parseSampleAt(String s) =>
    DateTime.parse('${s.replaceFirst(' ', 'T')}:00');

String _wx(int i) => yunQiWuXing[i];
String _yin(int i) => yunQiYunYin[i];

void main() {
  // ==================== A. 引擎逐格对拍 ====================

  group('A1 · 单年 24 字段逐格对拍（62 年）', () {
    test('夹具字段清单恰为 24 个且与预期一致', () {
      expect(fieldsOfYear().length, 24);
      expect(
        fieldsOfYear().toSet(),
        <String>{
          'y', 'yG', 'gan', 'zhi', 'ganName', 'zhiName', 'yun', 'taiGuo',
          'siTian', 'zaiQuan', 'cat', 'isTianFu', 'isTaiYi', 'isSuiHui',
          'isTongTianFu', 'isTongSuiHui', 'isPingQi', 'zhuYun', 'keYun',
          'keQi', 'jiaLin', 'shengxiao', 'yunBing', 'siTianBing',
        },
      );
    });

    final Map<String, dynamic> ys = <String, dynamic>{};

    setUpAll(() {
      ys.addAll(years());
    });

    test('夹具含 62 年（1900/1949 + 1984-2043）', () {
      expect(ys.length, 62);
      expect(ys.containsKey('1900'), isTrue);
      expect(ys.containsKey('1949'), isTrue);
      for (int y = 1984; y <= 2043; y++) {
        expect(ys.containsKey('$y'), isTrue, reason: '缺年 $y');
      }
    });

    for (final String key in <String>['1900', '1949']) {
      test('整年逐格对拍 · $key', () {
        _assertWholeYear(int.parse(key), ys[key] as Map<String, dynamic>);
      });
    }

    test('整年逐格对拍 · 1984-2043（连续 60 年）', () {
      for (int y = 1984; y <= 2043; y++) {
        _assertWholeYear(y, ys['$y'] as Map<String, dynamic>);
      }
    });
  });

  group('A2 · 客气六步 372 采样点逐格对拍（双口径）', () {
    test('采样点总数 372 = 62 × 6', () {
      expect(qiSteps().length, 372);
    });

    test('日历年口径 step（372 点全量）', () {
      for (final Map<String, dynamic> s in qiSteps()) {
        final DateTime dt = parseSampleAt(s['sampleAt'] as String);
        final int got = YunQiEngine.currentQiStep(
          s['y'] as int,
          dt.millisecondsSinceEpoch.toDouble(),
        );
        expect(got, s['step'], reason: '${s['y']} ${s['term']} 日历年口径');
      }
    });

    test('运气年口径 stepByYunqiYear（372 点全量）', () {
      for (final Map<String, dynamic> s in qiSteps()) {
        final DateTime dt = parseSampleAt(s['sampleAt'] as String);
        final int got = YunQiEngine.currentQiStep(
          s['yunqiY'] as int,
          dt.millisecondsSinceEpoch.toDouble(),
        );
        expect(got, s['stepByYunqiYear'],
            reason: '${s['y']} ${s['term']} 运气年口径(yunqiY=${s['yunqiY']})');
      }
    });

    test('两口径关系：非大寒点相等；大寒点 step=0 且 byY=5 且 yunqiY=y-1', () {
      int diffCount = 0;
      for (final Map<String, dynamic> s in qiSteps()) {
        final int step = s['step'] as int;
        final int byY = s['stepByYunqiYear'] as int;
        final int lam = s['lam'] as int;
        if (step != byY) diffCount++;
        if (lam == 300) {
          expect(step, 0, reason: '${s['y']} 大寒 step');
          expect(byY, 5, reason: '${s['y']} 大寒 byY');
          expect(s['yunqiY'], (s['y'] as int) - 1,
              reason: '${s['y']} 大寒 yunqiY');
        } else {
          expect(step, byY, reason: '${s['y']} ${s['term']} 非大寒两口径应相等');
        }
      }
      // 差异集恰为 62 个大寒点。
      expect(diffCount, 62);
    });

    test('每个采样点所在节的节气名与 lam 映射一致', () {
      const Map<int, String> lamToTerm = <int, String>{
        300: '大寒', 0: '春分', 60: '小满',
        120: '大暑', 180: '秋分', 240: '小雪',
      };
      for (final Map<String, dynamic> s in qiSteps()) {
        expect(lamToTerm[s['lam'] as int], s['term']);
      }
    });
  });

  // ==================== B. 手工独立用例（防夹具共错） ====================

  group('B · 独立不变量（不依赖夹具数值）', () {
    test('B1 锚点干支', () {
      final Map<int, List<Object>> anchors = <int, List<Object>>{
        1984: <Object>['甲', '子', 0, 0, 0], // ganName,zhiName,gan,zhi,yG
        1900: <Object>['庚', '子', 6, 0, 36],
        1949: <Object>['己', '丑', 5, 1, 25],
        2000: <Object>['庚', '辰', 6, 4, 16],
        2026: <Object>['丙', '午', 2, 6, 42],
      };
      anchors.forEach((int y, List<Object> exp) {
        final YunQiYearData d = YunQiEngine.yearGanzhi(y);
        expect(d.ganName, exp[0], reason: '$y ganName');
        expect(d.zhiName, exp[1], reason: '$y zhiName');
        expect(d.gan, exp[2], reason: '$y gan');
        expect(d.zhi, exp[3], reason: '$y zhi');
        expect(d.ganzhiIndex, exp[4], reason: '$y yG');
      });
    });

    test('B2 1984-2043 干支 60 个互不相同，yG 覆盖 0..59', () {
      final Set<String> gz = <String>{};
      final Set<int> yg = <int>{};
      for (int y = 1984; y <= 2043; y++) {
        final YunQiYearData d = YunQiEngine.yearGanzhi(y);
        gz.add(d.ganZhi);
        yg.add(d.ganzhiIndex);
      }
      expect(gz.length, 60);
      expect(yg.length, 60);
      expect(yg.toList()..sort(), List<int>.generate(60, (int i) => i));
    });

    test('B3 司天固定落三之气（62 年，强不变量）', () {
      for (int y = 1900; y <= 2043; y++) {
        if (y == 1901) y = 1984; // 跳过非夹具年段
        final YunQiYearData d = YunQiEngine.yearGanzhi(y);
        expect(d.keQi[2], d.siTian, reason: '$y 客气三之气应等于司天');
      }
      for (int y = 1984; y <= 2043; y++) {
        final YunQiYearData d = YunQiEngine.yearGanzhi(y);
        expect(d.keQi[2], d.siTian, reason: '$y 客气三之气应等于司天');
      }
    });

    test('B4 主气六步恒定（与年份无关）', () {
      const List<String> expectQi = <String>[
        '厥阴风木', '少阴君火', '少阳相火', '太阴湿土', '阳明燥金', '太阳寒水',
      ];
      const List<String> expectName = <String>[
        '初之气', '二之气', '三之气', '四之气', '五之气', '终之气',
      ];
      const List<List<String>> expectFromTo = <List<String>>[
        <String>['大寒', '春分'], <String>['春分', '小满'],
        <String>['小满', '大暑'], <String>['大暑', '秋分'],
        <String>['秋分', '小雪'], <String>['小雪', '大寒'],
      ];
      for (int i = 0; i < 6; i++) {
        expect(zhuQiSteps[i].qi, expectQi[i], reason: 'zhuQiSteps[$i].qi');
        expect(zhuQiSteps[i].name, expectName[i]);
        expect(zhuQiSteps[i].from, expectFromTo[i][0]);
        expect(zhuQiSteps[i].to, expectFromTo[i][1]);
      }
      // 逐年 jiaLin 的主气也须同序
      for (int y = 1984; y <= 2043; y++) {
        final YunQiYearData d = YunQiEngine.yearGanzhi(y);
        for (int i = 0; i < 6; i++) {
          expect(d.jiaLin[i].zhu.qi, expectQi[i], reason: '$y jiaLin[$i]');
        }
      }
    });

    test('B5 司天↔在泉固定配对（从夹具推导的 6 组）', () {
      const Map<String, String> pairs = <String, String>{
        '少阴君火': '阳明燥金',
        '阳明燥金': '少阴君火',
        '太阴湿土': '太阳寒水',
        '太阳寒水': '太阴湿土',
        '少阳相火': '厥阴风木',
        '厥阴风木': '少阳相火',
      };
      for (int y = 1984; y <= 2043; y++) {
        final YunQiYearData d = YunQiEngine.yearGanzhi(y);
        expect(pairs[d.siTian], d.zaiQuan, reason: '$y ${d.siTian}↔${d.zaiQuan}');
      }
      expect(pairs.length, 6);
    });

    test('B6 主运五行/五音恒定；客运自岁运起循环移位', () {
      final Map<String, int> wxIdx = <String, int>{
        for (int i = 0; i < 5; i++) yunQiWuXing[i]: i,
      };
      for (int y = 1984; y <= 2043; y++) {
        final YunQiYearData d = YunQiEngine.yearGanzhi(y);
        // 主运
        for (int i = 0; i < 5; i++) {
          expect(d.zhuYun[i].wx, _wx(i), reason: '$y zhuYun[$i].wx');
          expect(d.zhuYun[i].yin, _yin(i), reason: '$y zhuYun[$i].yin');
        }
        // 客运：首步 == 岁运，整体循环移位
        expect(d.keYun[0].wx, d.yun, reason: '$y keYun[0]=岁运');
        for (int i = 0; i < 5; i++) {
          final int expectIdx = (wxIdx[d.yun]! + i) % 5;
          expect(d.keYun[i].wx, _wx(expectIdx), reason: '$y keYun[$i].wx');
          expect(d.keYun[i].yin, _yin(expectIdx), reason: '$y keYun[$i].yin');
        }
      }
    });

    test('B7 太过/不及交替 + 主客 tai 同步', () {
      for (int y = 1984; y <= 2043; y++) {
        final YunQiYearData d = YunQiEngine.yearGanzhi(y);
        expect(d.taiGuo, d.gan % 2 == 0, reason: '$y taiGuo');
        expect(d.zhuYun[0].tai, d.taiGuo, reason: '$y zhuYun[0].tai');
        expect(d.keYun[0].tai, d.taiGuo, reason: '$y keYun[0].tai');
        for (int i = 0; i < 4; i++) {
          expect(d.zhuYun[i].tai, isNot(d.zhuYun[i + 1].tai),
              reason: '$y zhuYun[$i..${i + 1}] 未交替');
          expect(d.keYun[i].tai, isNot(d.keYun[i + 1].tai),
              reason: '$y keYun[$i..${i + 1}] 未交替');
        }
        // 主客同步（实测 310/310 全同）
        for (int i = 0; i < 5; i++) {
          expect(d.zhuYun[i].tai, d.keYun[i].tai,
              reason: '$y zhuYun[$i]/keYun[$i] tai 不同步');
        }
      }
    });

    test('B8 flag/cat 规则独立重建（62 年，0 反例预期）', () {
      const Map<String, String> keMe = <String, String>{
        '木': '金', '火': '水', '土': '木', '金': '火', '水': '土',
      };
      const Map<String, String> qiWx = <String, String>{
        '厥阴风木': '木', '少阴君火': '火', '太阴湿土': '土',
        '少阳相火': '火', '阳明燥金': '金', '太阳寒水': '水',
      };
      const List<String> zhiWx = <String>[
        '水', '土', '木', '木', '土', '火', '火', '土', '金', '金', '土', '水',
      ];
      for (int y = 1984; y <= 2043; y++) {
        final YunQiYearData d = YunQiEngine.yearGanzhi(y);
        final String stWx = d.siTianWx;
        final bool tg = d.gan % 2 == 0;
        final bool isTF = d.yun == stWx;
        final bool isSH =
            d.yun == zhiWx[d.zhi] && !<int>[2, 5, 8, 11].contains(d.zhi);
        final bool isTY = isTF && isSH && d.gan != 1;
        final String zqWx = qiWx[d.zaiQuan]!;
        final bool zqSame =
            (d.yun == zqWx) && !(d.yun == '火' && d.zaiQuan == '少阴君火');
        final bool isTTF = tg && zqSame;
        final bool isTSH = !tg && zqSame;
        final bool isPQ =
            (tg && keMe[d.yun] == stWx) || (!tg && d.yun == stWx);

        expect(d.taiGuo, tg, reason: '$y taiGuo');
        expect(d.isTianFu, isTF, reason: '$y isTianFu');
        expect(d.isSuiHui, isSH, reason: '$y isSuiHui');
        expect(d.isTaiYi, isTY, reason: '$y isTaiYi');
        expect(d.isTongTianFu, isTTF, reason: '$y isTongTianFu');
        expect(d.isTongSuiHui, isTSH, reason: '$y isTongSuiHui');
        expect(d.isPingQi, isPQ, reason: '$y isPingQi');

        final List<String> tags = <String>[];
        if (isTY) tags.add('太一天符');
        if (isTF) tags.add('天符');
        if (isSH) tags.add('岁会');
        if (isTTF) tags.add('同天符');
        if (isTSH) tags.add('同岁会');
        if (isPQ) tags.add('平气');
        final String cat =
            tags.isNotEmpty ? tags.join('·') : (tg ? '岁运太过' : '岁运不及');
        expect(d.cat, cat, reason: '$y cat');
      }
    });
  });

  // ==================== C. 边界用例 ====================

  group('C · 边界（节气时刻 / 动静分支 / 跨世纪）', () {
    test('C1-a 1900-2043 每年 6 节气均可解出、落在预期年、且互不相同', () {
      const List<String> terms = <String>['大寒', '春分', '小满', '大暑', '秋分', '小雪'];
      for (int y = 1900; y <= 2043; y++) {
        final List<double> msList = <double>[];
        for (final String t in terms) {
          final double ms = jieQiTimeMs(y, t);
          final DateTime dt =
              DateTime.fromMillisecondsSinceEpoch(ms.toInt());
          // 未触发兜底（兜底 = 当年 1/1 00:00）
          final bool isFallback = dt.year == y &&
              dt.month == 1 &&
              dt.day == 1 &&
              dt.hour == 0 &&
              dt.minute == 0;
          expect(isFallback, isFalse,
              reason: '$y $t 疑似触发兜底（返回 Jan1 00:00）');
          expect(dt.year, y, reason: '$y $t 落在错误年份 ${dt.year}');
          msList.add(ms);
        }
        // 六值互不相同
        expect(msList.toSet().length, 6, reason: '$y 六节气时刻出现重复');
        // 单调递增：大寒<春分<小满<大暑<秋分<小雪
        for (int i = 0; i < 5; i++) {
          expect(msList[i] < msList[i + 1], isTrue,
              reason: '$y ${terms[i]} 应早于 ${terms[i + 1]}');
        }
      }
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('C1-b 节气时刻与夹具 termAt 同分钟（容差 ±1 分钟）', () {
      for (final Map<String, dynamic> s in qiSteps()) {
        final double ms = jieQiTimeMs(s['y'] as int, s['term'] as String);
        final DateTime got = DateTime.fromMillisecondsSinceEpoch(ms.toInt());
        final DateTime ref =
            DateTime.parse('${(s['termAt'] as String).replaceFirst(' ', 'T')}:00');
        final int diffMin = got.difference(ref).inMinutes;
        expect(diffMin.abs() <= 1, isTrue,
            reason: '${s['y']} ${s['term']}: got=$got ref=$ref diff=${diffMin}min');
      }
    });

    test('C2 立春当天前/中/后归年（运气年口径）', () {
      for (final int y in <int>[1900, 2000, 2024, 2026]) {
        final double lc = jieQiTimeMs(y, '立春');
        final DateTime at =
            DateTime.fromMillisecondsSinceEpoch(lc.toInt());
        final DateTime before = at.subtract(const Duration(seconds: 1));
        expect(YunQiEngine.yunqiYearOf(before), y - 1, reason: '$y 立春前1s');
        expect(YunQiEngine.yunqiYearOf(at), y, reason: '$y 立春时刻');
        expect(YunQiEngine.yunqiYearOf(at.add(const Duration(seconds: 1))), y,
            reason: '$y 立春后1s');
      }
    });

    test('C3 闰年/跨世纪：1900 非闰、2000 是闰，节气均可解', () {
      // 1900 不是闰年
      expect(DateTime(1900, 2, 29).month, 3); // 溢出到 3/1 = 非闰
      // 2000 是闰年
      expect(DateTime(2000, 2, 29).day, 29);
      // 两者节气均可解且落在当年
      for (final int y in <int>[1900, 2000]) {
        for (final String t in <String>['大寒', '春分', '小满', '大暑', '秋分', '小雪']) {
          final DateTime dt = DateTime.fromMillisecondsSinceEpoch(
              jieQiTimeMs(y, t).toInt());
          expect(dt.year, y, reason: '$y $t');
        }
      }
    });

    test('C4 六节气半开区间边界（大寒前后 1 分钟）', () {
      for (final int y in <int>[1900, 1984, 2000, 2026, 2043]) {
        final double dahan = jieQiTimeMs(y, '大寒');
        final double before1min = dahan - 60000;
        final double after1min = dahan + 60000;
        // 大寒前 1 分钟 → step 5
        expect(YunQiEngine.currentQiStep(y, before1min), 5,
            reason: '$y 大寒前1min 应 step=5');
        // 大寒后 1 分钟 → step 0
        expect(YunQiEngine.currentQiStep(y, after1min), 0,
            reason: '$y 大寒后1min 应 step=0');
        // 各节气边界：t-1min 归上一步，t 归本步
        const List<String> terms = <String>['春分', '小满', '大暑', '秋分', '小雪'];
        for (int i = 0; i < terms.length; i++) {
          final double b = jieQiTimeMs(y, terms[i]);
          expect(YunQiEngine.currentQiStep(y, b - 60000), i,
              reason: '$y ${terms[i]} 前1min 应 step=$i');
          expect(YunQiEngine.currentQiStep(y, b), i + 1,
              reason: '$y ${terms[i]} 时刻 应 step=${i + 1}');
        }
      }
    });

    test('C5 节气时刻秒级精度：t-1s / t / t+1s 归属正确', () {
      for (final int y in <int>[1984, 2026]) {
        for (final MapEntry<String, int> e in <String, int>{
          '大寒': 0, '春分': 1, '小满': 2, '大暑': 3, '秋分': 4, '小雪': 5,
        }.entries) {
          final double b = jieQiTimeMs(y, e.key);
          final int atStep = e.value;
          final int beforeStep = (e.value - 1 + 6) % 6;
          expect(YunQiEngine.currentQiStep(y, b - 1000), beforeStep,
              reason: '$y ${e.key} 前1s');
          expect(YunQiEngine.currentQiStep(y, b), atStep,
              reason: '$y ${e.key} 时刻');
          expect(YunQiEngine.currentQiStep(y, b + 1000), atStep,
              reason: '$y ${e.key} 后1s');
        }
      }
    });

    test('C6 jieQiTimeMs 幂等（缓存不污染）', () {
      final double a1 = jieQiTimeMs(2026, '大寒');
      final double b1 = jieQiTimeMs(2026, '春分');
      final double a2 = jieQiTimeMs(2026, '大寒');
      final double b2 = jieQiTimeMs(2026, '春分');
      expect(a1, a2, reason: '大寒缓存幂等');
      expect(b1, b2, reason: '春分缓存幂等');
      expect(a1 == b1, isFalse, reason: '不同节气不应缓存串味');
    });

    test('C7 getPrevJieQi 闭区间陷阱回归：恰好等于节气时刻不返回自身', () {
      // 用引擎现用的 getNextJieQi（开区间）验证：以节气时刻本身为游标，
      // 下一次必推进到「再下一个」节气，绝不原地打转。
      // 若此处卡死，说明退化回了 getPrevJieQi 闭区间实现。
      for (final int y in <int>[1900, 2000, 2026]) {
        // 若 jieQiTimeMs 内部原地打转，会 40 次后兜底成 Jan1；
        // C1 已断言非兜底，这里额外确认「连续两年同名节气严格递增」。
        final double t0 = jieQiTimeMs(y, '大寒');
        final double t1 = jieQiTimeMs(y + 1, '大寒');
        expect(t1 > t0, isTrue, reason: '$y vs ${y + 1} 大寒应递增');
        final double tExact = jieQiTimeMs(y, '春分');
        final int sAtExact = YunQiEngine.currentQiStep(y, tExact);
        expect(sAtExact, 1, reason: '$y 春分时刻应归二之气(step=1)');
      }
    });
  });

  // ==================== E. currentQiStepOf 门面守门 ====================

  // 背景：本项目两次翻车都源于「public API 零覆盖」（屏幕层 static const 私有
  // 数据逃逸）。currentQiStepOf(DateTime) 是服务层公开门面，此前 test/ 下零引用。
  // 本组把它焊死，防止后人改动门面语义（尤其误改成「立春年」口径）。
  group('E · currentQiStepOf(DateTime) 门面守门', () {
    test('E1 等价性：currentQiStepOf(dt) == currentQiStep(dt.year, ms)'
        '（口径 = 日历年 dt.year，非立春年）', () {
      final List<DateTime> samples = <DateTime>[
        DateTime(1900, 1, 21, 12, 0),
        DateTime(1984, 6, 1, 8, 0),
        DateTime(2000, 2, 4, 0, 0),
        DateTime(2026, 5, 21, 12, 0),
        DateTime(2026, 12, 1, 0, 0),
      ];
      for (final DateTime dt in samples) {
        final int viaFacade = YunQiEngine.currentQiStepOf(dt);
        final int viaCore = YunQiEngine.currentQiStep(
          dt.year, // ⚠️ 门面内部用的就是日历年 dt.year（用户拍板口径）
          dt.millisecondsSinceEpoch.toDouble(),
        );
        expect(viaFacade, viaCore,
            reason: '$dt 门面与 core(日历年) 应等价');
      }
    });

    test('E2 跨节气边界：大寒前 1s→5，大寒后 1s→0（时刻正确透传）', () {
      for (final int y in <int>[1900, 1984, 2026, 2043]) {
        final double dahan = jieQiTimeMs(y, '大寒');
        final DateTime before = DateTime.fromMillisecondsSinceEpoch(
            (dahan - 1000).round());
        final DateTime after = DateTime.fromMillisecondsSinceEpoch(
            (dahan + 1000).round());
        expect(YunQiEngine.currentQiStepOf(before), 5,
            reason: '$y 大寒前1s 应 step=5');
        expect(YunQiEngine.currentQiStepOf(after), 0,
            reason: '$y 大寒后1s 应 step=0');
      }
    });

    test('E3 口径一致性：大寒~立春之间门面走「日历年」=0（非运气年 5）', () {
      // 取大寒当日中午（必在大寒之后、立春之前），锁定门面用日历年口径。
      for (final int y in <int>[1900, 1984, 2026, 2043]) {
        final double dahan = jieQiTimeMs(y, '大寒');
        final double liChun = jieQiTimeMs(y, '立春');
        expect(dahan < liChun, isTrue, reason: '$y 大寒应早于立春');
        // 大寒与立春之间的中点
        final DateTime mid = DateTime.fromMillisecondsSinceEpoch(
            ((dahan + liChun) / 2).round());
        expect(mid.year, y);

        // 门面 = 日历年口径 → step 0（初之气起于大寒）
        expect(YunQiEngine.currentQiStepOf(mid), 0,
            reason: '$y 大寒~立春之间 门面应为日历年口径 step=0');
        // 对照：运气年口径（yunqiY=y-1）在同一点应为 5（上一年终之气）
        final int yunqiYearStep = YunQiEngine.currentQiStep(
            y - 1, mid.millisecondsSinceEpoch.toDouble());
        expect(yunqiYearStep, 5,
            reason: '$y 大寒~立春之间 运气年口径应为 step=5');
        // ⚠️ 两者不同，正是用户拍板「照搬参考站」的结果
        expect(YunQiEngine.currentQiStepOf(mid), isNot(yunqiYearStep));
      }
    });

    test('E4 与夹具一致：372 采样点用门面重算，日历年口径全对', () {
      for (final Map<String, dynamic> s in qiSteps()) {
        final DateTime dt = parseSampleAt(s['sampleAt'] as String);
        expect(YunQiEngine.currentQiStepOf(dt), s['step'],
            reason: '${s['y']} ${s['term']} 门面应为日历年口径 step=${s['step']}');
      }
    });
  });

  // ==================== 夹具内部自洽（防夹具共错） ====================

  group('D · 夹具与引擎交叉自洽', () {
    test('夹具 keQi[2]==siTian 全 62 年成立（夹具侧）', () {
      final Map<String, dynamic> ys = years();
      ys.forEach((String k, dynamic v) {
        final Map<String, dynamic> r = v as Map<String, dynamic>;
        final String st = (r['siTian'] as List)[0] as String;
        final List<dynamic> kq = r['keQi'] as List;
        expect(kq[2], st, reason: '夹具 $k keQi[2]!=siTian');
      });
    });

    test('夹具 zhuYun 五行恒为 木火土金水、tai 交替', () {
      years().forEach((String k, dynamic v) {
        final Map<String, dynamic> r = v as Map<String, dynamic>;
        final List<dynamic> zy = r['zhuYun'] as List;
        for (int i = 0; i < 5; i++) {
          expect((zy[i] as Map<String, dynamic>)['wx'], _wx(i),
              reason: '夹具 $k zhuYun[$i].wx');
        }
        for (int i = 0; i < 4; i++) {
          final bool a = (zy[i] as Map<String, dynamic>)['tai'] as bool;
          final bool b = (zy[i + 1] as Map<String, dynamic>)['tai'] as bool;
          expect(a, isNot(b), reason: '夹具 $k zhuYun tai 未交替');
        }
      });
    });

    test('夹具 jiaLin 文案逐格完整存在', () {
      years().forEach((String k, dynamic v) {
        final Map<String, dynamic> r = v as Map<String, dynamic>;
        final List<dynamic> jl = r['jiaLin'] as List;
        expect(jl.length, 6);
        for (final dynamic e in jl) {
          final Map<String, dynamic> m = e as Map<String, dynamic>;
          expect((m['judge'] as String).isNotEmpty, isTrue, reason: '$k judge 空');
          expect((m['kq'] as String).isNotEmpty, isTrue, reason: '$k kq 空');
        }
      });
    });
  });
}

/// 对某年做 24 字段整年深比对。
void _assertWholeYear(int y, Map<String, dynamic> r) {
  final YunQiYearData d = YunQiEngine.yearGanzhi(y);

  expect(d.year, r['y'], reason: '$y year');
  expect(d.ganzhiIndex, r['yG'], reason: '$y yG');
  expect(d.gan, r['gan'], reason: '$y gan');
  expect(d.zhi, r['zhi'], reason: '$y zhi');
  expect(d.ganName, r['ganName'], reason: '$y ganName');
  expect(d.zhiName, r['zhiName'], reason: '$y zhiName');
  expect(d.yun, r['yun'], reason: '$y yun');
  expect(d.taiGuo, r['taiGuo'], reason: '$y taiGuo');

  final List<dynamic> st = r['siTian'] as List;
  expect(d.siTian, st[0], reason: '$y siTian');
  expect(d.siTianWx, st[1], reason: '$y siTianWx');
  expect(d.zaiQuan, r['zaiQuan'], reason: '$y zaiQuan');
  expect(d.cat, r['cat'], reason: '$y cat');

  expect(d.isTianFu, r['isTianFu'], reason: '$y isTianFu');
  expect(d.isTaiYi, r['isTaiYi'], reason: '$y isTaiYi');
  expect(d.isSuiHui, r['isSuiHui'], reason: '$y isSuiHui');
  expect(d.isTongTianFu, r['isTongTianFu'], reason: '$y isTongTianFu');
  expect(d.isTongSuiHui, r['isTongSuiHui'], reason: '$y isTongSuiHui');
  expect(d.isPingQi, r['isPingQi'], reason: '$y isPingQi');

  // zhuYun[5]
  final List<dynamic> zy = r['zhuYun'] as List;
  expect(d.zhuYun.length, 5);
  for (int i = 0; i < 5; i++) {
    final Map<String, dynamic> e = zy[i] as Map<String, dynamic>;
    expect(d.zhuYun[i].wx, e['wx'], reason: '$y zhuYun[$i].wx');
    expect(d.zhuYun[i].yin, e['yin'], reason: '$y zhuYun[$i].yin');
    expect(d.zhuYun[i].tai, e['tai'], reason: '$y zhuYun[$i].tai');
  }

  // keYun[5]
  final List<dynamic> ky = r['keYun'] as List;
  expect(d.keYun.length, 5);
  for (int i = 0; i < 5; i++) {
    final Map<String, dynamic> e = ky[i] as Map<String, dynamic>;
    expect(d.keYun[i].wx, e['wx'], reason: '$y keYun[$i].wx');
    expect(d.keYun[i].yin, e['yin'], reason: '$y keYun[$i].yin');
    expect(d.keYun[i].tai, e['tai'], reason: '$y keYun[$i].tai');
  }

  // keQi[6]
  final List<dynamic> kq = r['keQi'] as List;
  expect(d.keQi.length, 6);
  for (int i = 0; i < 6; i++) {
    expect(d.keQi[i], kq[i], reason: '$y keQi[$i]');
  }

  // jiaLin[6] — 逐格比 judge 字符串（坑 1：不能只数失败数）
  final List<dynamic> jl = r['jiaLin'] as List;
  expect(d.jiaLin.length, 6);
  for (int i = 0; i < 6; i++) {
    final Map<String, dynamic> e = jl[i] as Map<String, dynamic>;
    final Map<String, dynamic> zq = e['zq'] as Map<String, dynamic>;
    expect(d.jiaLin[i].zhu.name, zq['name'], reason: '$y jiaLin[$i].zq.name');
    expect(d.jiaLin[i].zhu.qi, zq['qi'], reason: '$y jiaLin[$i].zq.qi');
    expect(d.jiaLin[i].zhu.from, zq['from'], reason: '$y jiaLin[$i].zq.from');
    expect(d.jiaLin[i].zhu.to, zq['to'], reason: '$y jiaLin[$i].zq.to');
    expect(d.jiaLin[i].ke, e['kq'], reason: '$y jiaLin[$i].kq');
    expect(d.jiaLin[i].judge, e['judge'],
        reason: '$y jiaLin[$i].judge（客主加临文案）');
  }

  expect(d.shengXiao, r['shengxiao'], reason: '$y shengxiao');
  expect(d.yunBingText, r['yunBing'], reason: '$y yunBing');
  expect(d.siTianBingText, r['siTianBing'], reason: '$y siTianBing');
}
