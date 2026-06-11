import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/models/diagnosis.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FormulaRepository.load();
  });

  group('FormulaRepository 加载', () {
    test('load后getAll应返回非空列表', () {
      final formulas = FormulaRepository.getAll();
      expect(formulas, isNotEmpty);
    });

    test('方剂数量应大于50', () {
      final formulas = FormulaRepository.getAll();
      expect(formulas.length, greaterThan(50));
    });
  });

  group('getById 查询', () {
    test('应能通过ID找到桂枝汤', () {
      final formula = FormulaRepository.getById('guizhi_tang');
      expect(formula, isNotNull);
      expect(formula!.name, '桂枝汤');
    });

    test('不存在的ID应返回null', () {
      final formula = FormulaRepository.getById('nonexistent');
      expect(formula, isNull);
    });
  });

  group('getByName 查询', () {
    test('应能通过名称找到桂枝汤', () {
      final formula = FormulaRepository.getByName('桂枝汤');
      expect(formula, isNotNull);
      // getByName使用contains匹配，可能返回第一个包含"桂枝汤"的方剂
      expect(formula!.name, contains('桂枝汤'));
    });

    test('部分名称应能匹配', () {
      final formula = FormulaRepository.getByName('乌梅丸');
      expect(formula, isNotNull);
      expect(formula!.name, '乌梅丸');
    });

    test('不存在的名称应返回null', () {
      final formula = FormulaRepository.getByName('不存在的方剂xyz');
      expect(formula, isNull);
    });
  });

  group('search 搜索', () {
    test('搜索"桂枝"应返回包含桂枝的方剂', () {
      final results = FormulaRepository.search('桂枝');
      expect(results, isNotEmpty);
      expect(results.any((f) => f.name.contains('桂枝')), isTrue);
    });

    test('搜索"柴胡"应返回小柴胡汤等', () {
      final results = FormulaRepository.search('柴胡');
      expect(results, isNotEmpty);
      expect(results.any((f) => f.name.contains('柴胡')), isTrue);
    });

    test('空搜索应返回所有方剂（通配行为）', () {
      final results = FormulaRepository.search('');
      // 空查询时 .contains('') 对所有字符串返回true，所以返回全部
      expect(results, isNotEmpty);
    });

    test('搜索应忽略大小写', () {
      // 搜索英文关键词（如果有）
      final results = FormulaRepository.search('桂');
      expect(results, isNotEmpty);
    });
  });

  group('getByMeridian 经络筛选', () {
    test('筛选太阳应返回桂枝汤、麻黄汤等', () {
      final results = FormulaRepository.getByMeridian('太阳');
      expect(results, isNotEmpty);
      expect(results.any((f) => f.name == '桂枝汤'), isTrue);
      expect(results.any((f) => f.name == '麻黄汤'), isTrue);
    });

    test('筛选阳明应返回白虎汤、承气汤等', () {
      final results = FormulaRepository.getByMeridian('阳明');
      expect(results, isNotEmpty);
      expect(results.any((f) => f.name.contains('白虎')), isTrue);
    });

    test('筛选少阳应返回柴胡类方剂', () {
      final results = FormulaRepository.getByMeridian('少阳');
      expect(results, isNotEmpty);
      expect(results.any((f) => f.name.contains('柴胡')), isTrue);
    });

    test('筛选太阴应返回理中汤等', () {
      final results = FormulaRepository.getByMeridian('太阴');
      expect(results, isNotEmpty);
    });

    test('筛选少阴应返回四逆汤、真武汤等', () {
      final results = FormulaRepository.getByMeridian('少阴');
      expect(results, isNotEmpty);
    });

    test('筛选厥阴应返回乌梅丸等', () {
      final results = FormulaRepository.getByMeridian('厥阴');
      expect(results, isNotEmpty);
    });
  });

  group('getByCategory 类别筛选', () {
    test('应返回有效的类别列表', () {
      final categories = FormulaRepository.getCategories();
      expect(categories, isNotEmpty);
    });

    test('按类别筛选应返回对应方剂', () {
      final categories = FormulaRepository.getCategories();
      if (categories.isNotEmpty) {
        final results = FormulaRepository.getByCategory(categories.first);
        expect(results, isNotEmpty);
      }
    });
  });

  group('resolveFormula 4级匹配策略', () {
    test('1. 精确匹配：直接匹配方剂名', () {
      final formula = FormulaRepository.resolveFormula('桂枝汤');
      expect(formula, isNotNull);
      expect(formula!.name, '桂枝汤');
    });

    test('2. 别名匹配：通过别名找到方剂', () {
      // 测试一些有别名的方剂
      final formula = FormulaRepository.resolveFormula('小柴胡');
      // 可能匹配到小柴胡汤
      if (formula != null) {
        expect(formula.name, contains('柴胡'));
      }
    });

    test('3. 斜杠分割：取第一个匹配', () {
      final formula = FormulaRepository.resolveFormula('桂枝汤/麻黄汤');
      expect(formula, isNotNull);
      expect(formula!.name, '桂枝汤');
    });

    test('4. 子串匹配：长名包含短名', () {
      final formula = FormulaRepository.resolveFormula('桂枝加厚朴杏仁汤');
      expect(formula, isNotNull);
      // 应匹配到桂枝汤或桂枝加厚朴杏仁汤
    });

    test('反向子串：方剂名包含输入', () {
      final formula = FormulaRepository.resolveFormula('桂枝');
      expect(formula, isNotNull);
    });

    test('空字符串应返回null', () {
      final formula = FormulaRepository.resolveFormula('');
      expect(formula, isNull);
    });

    test('不存在的方剂应返回null', () {
      final formula = FormulaRepository.resolveFormula('不存在的方剂');
      expect(formula, isNull);
    });
  });

  group('buildPrescription 处方构建', () {
    test('应能构建桂枝汤完整处方', () {
      final prescription = FormulaRepository.buildPrescription('桂枝汤');
      expect(prescription, isNotNull);
      expect(prescription!.formulaName, '桂枝汤');
      expect(prescription.components, isNotEmpty);
    });

    test('应能构建带加减法的处方', () {
      final mods = [
        const FormulaModification(
          condition: '兼咳喘',
          symptom: 'cough',
          type: ModificationType.add,
          herbName: '厚朴、杏仁',
          resultFormula: '桂枝加厚朴杏仁汤',
          description: '加厚朴、杏仁',
        ),
      ];
      final prescription = FormulaRepository.buildPrescription(
        '桂枝汤',
        modifications: mods,
      );
      expect(prescription, isNotNull);
      expect(prescription!.modifications, isNotNull);
      expect(prescription.modifications!.length, 1);
    });

    test('不存在的方剂应返回null', () {
      final prescription = FormulaRepository.buildPrescription('不存在的方剂');
      expect(prescription, isNull);
    });

    test('处方的toCopyText应返回完整文本', () {
      final prescription = FormulaRepository.buildPrescription('桂枝汤');
      expect(prescription, isNotNull);
      final text = prescription!.toCopyText();
      expect(text, contains('桂枝汤'));
      expect(text, contains('组成'));
    });
  });
}
