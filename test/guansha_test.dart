import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/services/bazi_service.dart' show BaZiPaipan, computeBaZiPaipan;
import 'package:nihaisha_app/data/guansha_data.dart'
    show GuanshaEntry, kGuanshaEntries, kExtShaEntries, searchGuansha;
import 'package:nihaisha_app/engine/guansha_engine.dart' show matchGuansha;

const _validSeverity = {'重关', '中关', '轻关'};

void main() {
  group('小儿关煞 · 金标准回归', () {
    late BaZiPaipan p;
    late Set<String> hitNames;
    late Set<String> guanshaHitNames;

    setUpAll(() {
      p = computeBaZiPaipan(
        DateTime(2022, 11, 15, 10, 30),
        isMale: true,
      );
      hitNames = matchGuansha(p, true).map((h) => h.entry.name).toSet();
      guanshaHitNames = hitNames
          .where((n) => kGuanshaEntries.any((e) => e.name == n))
          .toSet();
    });

    test('四柱口径符合核对版', () {
      // 壬寅 / 辛亥 / 壬申 / 乙巳
      expect(p.bazi.year, '壬寅');
      expect(p.bazi.month, '辛亥');
      expect(p.bazi.day, '壬申');
      expect(p.bazi.time, '乙巳');
      expect(p.zhis, ['寅', '亥', '申', '巳']);
      expect(p.gans[0], '壬'); // 年干
      expect(p.gans[2], '壬'); // 日干
    });

    test('恰好犯 {将军箭, 和尚关, 撞命关, 断肠关}', () {
      expect(guanshaHitNames, {
        '将军箭',
        '和尚关',
        '撞命关',
        '断肠关',
      });
    });

    test('下列均不犯', () {
      for (final name in [
        '天狗关',
        '白虎关',
        '铁蛇关',
        '童子关',
        '多厄关',
        '阎王关',
      ]) {
        expect(hitNames.contains(name), isFalse, reason: '$name 不应犯');
      }
    });

    test('扩展煞中隔离关、缠身官符煞犯（核对版示例）', () {
      expect(hitNames.contains('隔离关'), isTrue);
      expect(hitNames.contains('缠身官符煞'), isTrue);
    });
  });

  group('小儿关煞 · 数据完整性', () {
    test('条目数量与 isExt 标记', () {
      expect(kGuanshaEntries.length, 36);
      expect(kExtShaEntries.length, 18);
      expect(kGuanshaEntries.every((e) => !e.isExt), isTrue);
      expect(kExtShaEntries.every((e) => e.isExt), isTrue);
    });

    test('所有字段非空且 severity 合法', () {
      final all = [...kGuanshaEntries, ...kExtShaEntries];
      for (final GuanshaEntry e in all) {
        expect(e.name.isNotEmpty, isTrue, reason: 'name empty: ${e.name}');
        expect(e.category.isNotEmpty, isTrue, reason: 'category empty: ${e.name}');
        expect(_validSeverity.contains(e.severity), isTrue,
            reason: 'bad severity ${e.severity} for ${e.name}');
        expect(e.rule, isNotNull, reason: 'rule null: ${e.name}');
        expect(e.fanZheJi.isNotEmpty, isTrue, reason: 'fanZheJi empty: ${e.name}');
        expect(e.huaJie.isNotEmpty, isTrue, reason: 'huaJie empty: ${e.name}');
      }
    });

    test('无重名', () {
      final names = [...kGuanshaEntries, ...kExtShaEntries].map((e) => e.name);
      expect(names.toSet().length, names.length);
    });
  });

  group('小儿关煞 · 检索', () {
    test('按名称检索命中', () {
      final r = searchGuansha('将军箭');
      expect(r.any((e) => e.name == '将军箭'), isTrue);
    });

    test('按别名检索命中', () {
      final r = searchGuansha('阎罗关');
      expect(r.any((e) => e.name == '阎王关'), isTrue);
    });

    test('不存在关键词返回空', () {
      expect(searchGuansha('不存在zzz'), isEmpty);
    });

    test('空查询返回全部', () {
      expect(searchGuansha('').length, 54);
    });
  });

  group('小儿关煞 · 补充用例', () {
    test('卯月巳时犯四季关', () {
      // 2023-03-15 10:00：惊蛰后属卯月（春），巳时。
      final p = computeBaZiPaipan(DateTime(2023, 3, 15, 10, 0), isMale: true);
      final hits = matchGuansha(p, true).map((h) => h.entry.name).toSet();
      expect(hits.contains('四季关'), isTrue);
    });

    test('庚子年戌时犯天狗关', () {
      // 2020-06-15 20:00：庚子年（子），戌时。
      final p = computeBaZiPaipan(DateTime(2020, 6, 15, 20, 0), isMale: true);
      final hits = matchGuansha(p, true).map((h) => h.entry.name).toSet();
      expect(hits.contains('天狗关'), isTrue);
    });
  });
}
