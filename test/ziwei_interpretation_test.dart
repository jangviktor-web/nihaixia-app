import 'package:flutter_test/flutter_test.dart';
import 'package:ziwei_core/ziwei_core.dart';
import 'package:nihaisha_app/services/ziwei_engine.dart';
import 'package:nihaisha_app/services/ziwei_interpretation.dart';

/// 解读层冒烟测试 + 真实输出样例（用真实出生数据 男 1990-06-15 子时）。
void main() {
  group('ziwei interpretation (1990-06-15 子时 男)', () {
    late ZiweiChart chart;

    setUpAll(() {
      chart = calculateZiweiChart(
        solar: DateTime(1990, 6, 15, 0, 0), // 子时代表小时 0
        gender: Gender.male,
        useTrueSolarTime: false,
      );
    });

    test('a) summarizeOverall 非空', () {
      final out = summarizeOverall(chart);
      print('[summarizeOverall]\n$out\n');
      expect(out, isNotEmpty);
    });

    test('b) summarizeDecades 共12条且非空', () {
      final out = summarizeDecades(chart);
      expect(out.length, 12);
      for (final s in out) {
        expect(s, isNotEmpty);
      }
      print('[summarizeDecades]');
      for (final s in out) {
        print('  $s');
      }
      print('');
    });

    test('c) summarizeFlowYear 非空', () {
      final flow = calculateFlowYearMark(year: DateTime.now().year);
      final out = summarizeFlowYear(chart, flow);
      print('[summarizeFlowYear ${flow.year}(${flow.ganzhi})]\n$out\n');
      expect(out, isNotEmpty);
    });

    test('d) analyzeHealthWatch 不抛异常且有命中', () {
      final birthYear = 1990;
      final items = analyzeHealthWatch(
        chart,
        fromYear: birthYear,
        toYear: birthYear + 100,
        birthYear: birthYear,
      );
      expect(items, isNotEmpty);
      final niCount = items.where((e) => e.source == '倪师《天纪》').length;
      print('[analyzeHealthWatch] 总条数=${items.length}，倪师《天纪》来源=${niCount}');
      // 打印前 8 条样例
      for (final it in items.take(8)) {
        print('  ${it.year}年(${it.age}虚岁) ${it.bodyPart} | ${it.reason} | ${it.source}');
      }
      print('');

      // 默认未来30年视图也应可用
      final future = analyzeHealthWatch(
        chart,
        fromYear: DateTime.now().year,
        toYear: DateTime.now().year + 30,
        birthYear: birthYear,
      );
      expect(future, isNotEmpty);
      print('[默认未来30年] 条数=${future.length}');
    });

    test('d2) 化忌命中逻辑：已知年生年四化可推导', () {
      // 1990 庚午年 -> 生年四化 太阳禄/武曲权/太阴科/天同忌
      final jiStar = chart.sihua
          .firstWhere((s) => s.typeLabel == '忌')
          .starLabelName;
      print('[生年化忌星] $jiStar');
      expect(jiStar, isNotEmpty);
    });
  });
}
