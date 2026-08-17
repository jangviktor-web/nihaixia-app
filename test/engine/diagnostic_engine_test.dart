import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/engine/diagnostic_engine.dart';
import 'package:nihaisha_app/engine/formula_rules.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/models/diagnosis.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FormulaRepository.load();
  });

  group('DiagnosticEngine 初始化（主诉入口已移除 → 直接 Q1 寒热起步）', () {
    test('初始阶段为 temperaturePattern，扁平答案为空', () {
      final engine = DiagnosticEngine();
      expect(engine.stage, DiagnosticStage.temperaturePattern);
      expect(engine.selectedSymptoms, isEmpty);
      expect(engine.tenQuestionIndex, 0);
      expect(engine.qAnswers, isEmpty);
      expect(engine.extSymptoms, isEmpty);
    });

    test('getInitialGreeting 应包含 Q1 寒热问诊引导', () {
      final engine = DiagnosticEngine();
      final greeting = engine.getInitialGreeting();
      expect(greeting, contains('汉唐中医'));
      expect(greeting, contains('Q1'));
      expect(greeting, contains('寒热'));
    });

    test('getTemperatureQuestions 应返回 7 个寒热选项', () {
      final engine = DiagnosticEngine();
      expect(engine.getTemperatureQuestions().length, 7);
    });

    test('getTenQuestions 应返回非空且每问含 key/options', () {
      final engine = DiagnosticEngine();
      final questions = engine.getTenQuestions();
      expect(questions, isNotEmpty);
      for (final q in questions) {
        expect(q.key, isNotEmpty);
        expect(q.options, isNotEmpty);
      }
    });

    test('reset 应清空扁平答案与扩展症状', () {
      final engine = DiagnosticEngine();
      engine.answerFlatQuestion(kQ1, 0, qOptions[kQ1]![0]);
      engine.toggleExtSymptom('edema', true);
      expect(engine.qAnswers, isNotEmpty);
      engine.reset();
      expect(engine.stage, DiagnosticStage.temperaturePattern);
      expect(engine.qAnswers, isEmpty);
      expect(engine.extSymptoms, isEmpty);
    });
  });

  group('快照系统（扁平 Q1-Q12）', () {
    test('createSnapshot 应捕获 qAnswers 与 extSymptoms', () {
      final engine = DiagnosticEngine();
      engine.answerFlatQuestion(kQ1, 0, qOptions[kQ1]![0]);
      engine.toggleExtSymptom('edema', true);
      final snapshot = engine.createSnapshot();
      expect(snapshot.qAnswers[kQ1], 1);
      expect(snapshot.extSymptoms, contains('edema'));
    });

    test('restoreSnapshot 应恢复扁平状态', () {
      final engine = DiagnosticEngine();
      engine.answerFlatQuestion(kQ1, 0, qOptions[kQ1]![0]);
      final snapshot = engine.createSnapshot();
      engine.answerFlatQuestion(kQ1, 6, qOptions[kQ1]![6]);
      expect(engine.qAnswers[kQ1], 7);
      engine.restoreSnapshot(snapshot);
      expect(engine.qAnswers[kQ1], 1);
    });
  });

  group('扁平问诊 → 规则出方（主路径 diagnoseByRules）', () {
    test('桂枝汤：手脚温热+易汗+缓脉+不渴+不痛', () {
      final engine =
          _cast({kQ1: 1, kQ4: 2, kQ2: 12, kQ3: 1, kQ5: 1, kQ10: 2});
      final r = engine.diagnoseByRules();
      expect(r.formula, '桂枝汤');
      expect(r.recommendedFormulas, contains('桂枝汤'));
      expect(r.meridian, '太阳');
    });

    test('麻黄汤：全身怕冷+无汗+浮脉+不渴+头痛前额', () {
      final engine =
          _cast({kQ1: 7, kQ4: 1, kQ2: 1, kQ3: 1, kQ5: 2, kQ10: 2});
      final r = engine.diagnoseByRules();
      expect(r.formula, '麻黄汤');
    });

    test('小柴胡汤：往来寒热+胸胁胀痛+口苦口干', () {
      final engine = _cast(
          {kQ1: 3, kQ5: 5, kQ3: 5, kQ9: 2, kQ8: 2, kQ10: 4, kQ7: 2, kQ12: 3});
      final r = engine.diagnoseByRules();
      expect(r.formula, '小柴胡汤');
      expect(r.formula, contains('柴胡'));
    });

    test('五苓散：渴想喝冷水+小便不利+不渴分界', () {
      final engine = _cast({kQ3: 2, kQ7: 5, kQ2: 1, kQ1: 1, kQ6: 3});
      final r = engine.diagnoseByRules();
      expect(r.formula, '五苓散');
    });

    test('炙甘草汤：脉结代+心悸怔忡+容易疲倦', () {
      final engine = _cast({kQ2: 14, kQ5: 18, kQ10: 2, kQ1: 1, kQ3: 2, kQ9: 4});
      final r = engine.diagnoseByRules();
      expect(r.formula, '炙甘草汤');
    });

    test('白虎汤：手脚温热+大渴+大汗+数脉', () {
      final engine = _cast({kQ1: 1, kQ3: 7, kQ4: 7, kQ2: 4, kQ10: 4, kQ5: 1});
      final r = engine.diagnoseByRules();
      expect(r.formula, '白虎汤');
    });

    test('蜜煎导：汗出+便秘（津液内竭）', () {
      final engine = _cast({kQ6: 2, kQ4: 2});
      final r = engine.diagnoseByRules();
      expect(r.formula, '蜜煎导猪胆汁导');
    });

    test('纯便秘无汗 → 证据不足不出方', () {
      final engine = _cast({kQ6: 2});
      final r = engine.diagnoseByRules();
      expect(r.formula, isEmpty);
      expect(r.recommendConsult, isTrue);
    });

    test('四逆汤：手脚冰冷+微脉+但欲寐+下利清谷', () {
      final engine = _cast(
          {kQ1: 6, kQ2: 10, kQ10: 3, kQ3: 1, kQ6: 7, kQ7: 7, kQ5: 9, kQ8: 7});
      final r = engine.diagnoseByRules();
      expect(r.formula, '四逆汤');
    });

    test('防己黄芪汤：汗出+身重浮肿（扩展症状）', () {
      final engine = _cast({kQ4: 2, kQ1: 7, kQ7: 5, kQ2: 11, kQ5: 8},
          ext: {'edema'});
      final r = engine.diagnoseByRules();
      expect(r.formula, '防己黄芪汤');
    });

    test('大陷胸丸：★胸膈心下硬满+项背强（纯扩展症状）', () {
      final engine = _cast(const {}, ext: {'chest_diaphragm_hard', 'nape_stiff'});
      final r = engine.diagnoseByRules();
      expect(r.formula, '大陷胸丸');
    });

    test('大陷胸丸缺项背强（★缺失）→ 不出方', () {
      final engine = _cast(const {}, ext: {'chest_diaphragm_hard'});
      final r = engine.diagnoseByRules();
      expect(r.formula, isEmpty);
    });

    test('真武汤：手足温冷异常+小便不利+头晕目眩（去重唯一）', () {
      final engine = _cast({kQ1: 6, kQ7: 5, kQ5: 19});
      final r = engine.diagnoseByRules();
      expect(r.formula, '真武汤');
      expect(r.recommendedFormulas, ['真武汤']);
    });

    test('空输入 → 证据不足建议面诊', () {
      final engine = DiagnosticEngine();
      final r = engine.diagnoseByRules();
      expect(r.formula, isEmpty);
      expect(r.recommendConsult, isTrue);
    });
  });

  group('同症并列推荐（co-recommended）', () {
    test('{kQ1:7,kQ5:8} → 桂枝附子汤/桂枝芍药知母汤/乌头汤 三方并列', () {
      final engine = _cast({kQ1: 7, kQ5: 8});
      final r = engine.diagnoseByRules();
      expect(r.formula, '桂枝附子汤');
      expect(r.recommendedFormulas.toSet(),
          {'桂枝附子汤', '桂枝芍药知母汤', '乌头汤'});
    });

    test('带下三证 → 蛇床子散/狼牙汤/矾石散 三方并列', () {
      final engine =
          _cast(const {}, ext: {'leukorrhea', 'vulva_cold', 'vulva_ulcer'});
      final r = engine.diagnoseByRules();
      expect(r.recommendedFormulas.toSet(), {'蛇床子散', '狼牙汤', '矾石散'});
    });

    test('仅阴中寒 → 只推荐蛇床子散，不牵连其他', () {
      final engine = _cast(const {}, ext: {'vulva_cold'});
      final r = engine.diagnoseByRules();
      expect(r.recommendedFormulas, ['蛇床子散']);
    });
  });
}

/// 按 1-based 选项号扁平作答（与 chat_screen 的十问→规则桥接同源）。
DiagnosticEngine _cast(Map<String, int> q, {Set<String> ext = const {}}) {
  final engine = DiagnosticEngine();
  q.forEach((key, opt) {
    engine.answerFlatQuestion(key, opt - 1, qOptions[key]![opt - 1]);
  });
  for (final s in ext) {
    engine.toggleExtSymptom(s, true);
  }
  return engine;
}
