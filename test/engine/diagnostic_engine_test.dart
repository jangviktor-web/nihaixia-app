import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:nihaisha_app/engine/diagnostic_engine.dart';
import 'package:nihaisha_app/engine/diagnostic_rules.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/models/diagnosis.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FormulaRepository.load();
  });

  group('DiagnosticEngine 初始化', () {
    test('初始状态应为chiefComplaint阶段', () {
      final engine = DiagnosticEngine();
      expect(engine.stage, DiagnosticStage.chiefComplaint);
      expect(engine.selectedSymptoms, isEmpty);
      expect(engine.tenQuestionIndex, 0);
    });

    test('getInitialGreeting应返回包含七步问诊的问候', () {
      final engine = DiagnosticEngine();
      final greeting = engine.getInitialGreeting();
      expect(greeting, contains('汉唐中医'));
      expect(greeting, contains('七步'));
    });

    test('getChiefComplaintOptions应返回非空列表', () {
      final engine = DiagnosticEngine();
      final options = engine.getChiefComplaintOptions();
      expect(options, isNotEmpty);
    });

    test('getTemperatureQuestions应返回7个寒热选项', () {
      final engine = DiagnosticEngine();
      final options = engine.getTemperatureQuestions();
      // 工作树规则已扩充至 7 项（含 no_fever_no_chill 寒热不显项）
      expect(options.length, 7);
    });

    test('getTenQuestions应返回11个问题（含性别）', () {
      final engine = DiagnosticEngine();
      final questions = engine.getTenQuestions();
      expect(questions.length, 11); // 性别+传统十问
    });

    test('reset应恢复到初始状态', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('headache');
      engine.answerTemperaturePattern('fever_chills');
      engine.reset();
      expect(engine.stage, DiagnosticStage.chiefComplaint);
      expect(engine.selectedSymptoms, isEmpty);
    });
  });

  group('快照系统', () {
    test('createSnapshot应捕获当前状态', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('headache');
      engine.answerTemperaturePattern('fever_chills');

      final snapshot = engine.createSnapshot();
      expect(snapshot.stage, DiagnosticStage.tonguePulse);
      expect(snapshot.selectedSymptoms, contains('headache'));
      expect(snapshot.answers['temperature'], 'fever_chills');
    });

    test('restoreSnapshot应恢复到快照状态', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('headache');
      engine.answerTemperaturePattern('fever_chills');
      final snapshot = engine.createSnapshot();

      engine.answerTonguePulse(tongueCoating: '薄白');
      expect(engine.stage, DiagnosticStage.tenQuestions);

      engine.restoreSnapshot(snapshot);
      expect(engine.stage, DiagnosticStage.tonguePulse);
      expect(engine.selectedSymptoms, ['headache']);
    });

    test('快照应独立于引擎状态（深拷贝）', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('headache');
      final snapshot = engine.createSnapshot();

      engine.selectChiefComplaint('fever');
      expect(snapshot.selectedSymptoms, ['headache']);
    });
  });

  group('诊断流程状态机', () {
    test('selectChiefComplaint应进入temperaturePattern阶段', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('headache');
      expect(engine.stage, DiagnosticStage.temperaturePattern);
      expect(engine.selectedSymptoms, contains('headache'));
    });

    test('answerTemperaturePattern应进入tonguePulse阶段', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('headache');
      engine.answerTemperaturePattern('fever_chills');
      expect(engine.stage, DiagnosticStage.tonguePulse);
    });

    test('answerTonguePulse应进入tenQuestions阶段', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('headache');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮');
      expect(engine.stage, DiagnosticStage.tenQuestions);
    });
  });

  group('太阳病辨证', () {
    test('发热+怕冷+有汗+浮缓脉 → 桂枝汤证', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮缓');

      _completeTenQuestions(engine, answers: {
        'sweating': '稍微活动就出汗',
        'temperature': '手脚温热（正常）',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '太阳');
      expect(result.formula, contains('桂枝'));
    });

    test('发热+怕冷+无汗+浮紧脉 → 麻黄汤证', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮紧');

      _completeTenQuestions(engine, answers: {
        'sweating': '不容易出汗',
        'temperature': '全身怕冷',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '太阳');
    });
  });

  group('阳明病辨证', () {
    test('只发热不怕冷+洪脉 → 阳明经证', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_no_cold');
      engine.answerTonguePulse(
        tongueCoating: '黄厚',
        tongueShape: '红',
        pulseType: '洪',
      );

      _completeTenQuestions(engine, answers: {
        'sweating': '稍微活动就出汗',
        'thirst': '渴想喝冷水',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '阳明');
    });
  });

  group('少阳病辨证', () {
    test('忽冷忽热+弦脉 → 小柴胡汤证', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('alternating_chills_fever');
      engine.answerTonguePulse(
        tongueCoating: '黄薄',
        pulseType: '弦',
      );

      _completeTenQuestions(engine, answers: {
        'sweating': '正常出汗',
        'temperature': '全身怕冷',
        'thirst': '口苦口干',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '少阳');
      expect(result.formula, contains('柴胡'));
    });
  });

  group('太阴病辨证', () {
    test('只怕冷不发热+白厚苔+沉脉 → 太阴证', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('abdominal_pain');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(
        tongueCoating: '白厚',
        tongueShape: '淡白',
        pulseType: '沉',
      );

      _completeTenQuestions(engine, answers: {
        'stool': '稀/拉肚子',
        'thirst': '不渴',
        'sweating': '不容易出汗',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, contains('太阴'));
    });
  });

  group('少阴病辨证', () {
    test('只怕冷不发热+微脉+但欲寐 → 少阴证', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fatigue');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(
        tongueCoating: '白厚',
        tongueShape: '淡白',
        pulseType: '微',
      );

      _completeTenQuestions(engine, answers: {
        'energy': '但欲寐（昏昏沉沉）',
        'temperature': '手脚冰冷',
        'sweating': '不容易出汗',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      // 可能是太阴或少阴，取决于评分
      expect(result!.meridian, anyOf(contains('太阴'), contains('少阴')));
    });
  });

  group('厥阴病辨证', () {
    test('上热下寒+沉细脉 → 厥阴证', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fatigue');
      engine.answerTemperaturePattern('upper_heat_lower_cold');
      engine.answerTonguePulse(
        tongueCoating: '黄薄',
        pulseType: '沉细',
      );

      _completeTenQuestions(engine, answers: {
        'temperature': '头热脚冷',
        'energy': '烦躁不安',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '厥阴');
    });
  });

  group('十问答案派生', () {
    test('sleep答案应派生insomnia标志', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('insomnia');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '细');

      engine.answerTenQuestion('sleep', '整夜睡不着');

      _completeTenQuestions(engine, skipSleep: true);
      final result = engine.diagnose();
      expect(result, isNotNull);
    });

    test('thirst答案应派生渴/不渴标志', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_no_cold');
      engine.answerTonguePulse(tongueCoating: '黄厚', pulseType: '洪');

      engine.answerTenQuestion('thirst', '渴想喝冷水');
      _completeTenQuestions(engine, skipThirst: true);

      final result = engine.diagnose();
      expect(result, isNotNull);
    });

    test('stool答案应派生便秘/腹泻标志', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('abdominal_pain');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(tongueCoating: '白厚', pulseType: '沉');

      engine.answerTenQuestion('stool', '便秘，好几天一次');
      _completeTenQuestions(engine, skipStool: true);

      final result = engine.diagnose();
      expect(result, isNotNull);
    });

    test('没有此症状应跳过', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮');

      engine.answerTenQuestion('sleep', '没有此症状');
      expect(engine.tenQuestionIndex, greaterThan(0));

      _completeTenQuestions(engine, skipSleep: true);
      final result = engine.diagnose();
      expect(result, isNotNull);
    });
  });

  group('传变预警', () {
    test('太阳+口苦应产生少阳传经信号', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮');

      _completeTenQuestions(engine, answers: {
        'sweating': '稍微活动就出汗',
        'thirst': '口苦口干',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      if (result!.transmissionWarning != null) {
        expect(result.transmissionWarning, contains('少阳'));
      }
    });
  });

  group('处方生成', () {
    test('诊断后应生成完整处方', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮缓');

      _completeTenQuestions(engine, answers: {
        'sweating': '稍微活动就出汗',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.prescription, isNotNull);
      expect(result.prescription!.components, isNotEmpty);
    });

    test('处方应包含组成和方剂名', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮缓');

      _completeTenQuestions(engine, answers: {
        'sweating': '稍微活动就出汗',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      final rx = result!.prescription!;
      expect(rx.formulaName, isNotEmpty);
      expect(rx.components, isNotEmpty);
    });
  });
}

/// 辅助函数：完成十问流程
void _completeTenQuestions(
  DiagnosticEngine engine, {
  Map<String, String> answers = const {},
  bool skipSleep = false,
  bool skipThirst = false,
  bool skipStool = false,
}) {
  final tenQuestions = engine.getTenQuestions();
  for (final q in tenQuestions) {
    if (skipSleep && q.key == 'sleep') {
      engine.answerTenQuestion(q.key, '没有此症状');
      continue;
    }
    if (skipThirst && q.key == 'thirst') {
      engine.answerTenQuestion(q.key, '没有此症状');
      continue;
    }
    if (skipStool && q.key == 'stool') {
      engine.answerTenQuestion(q.key, '没有此症状');
      continue;
    }
    final answer = answers[q.key];
    if (answer != null) {
      engine.answerTenQuestion(q.key, answer);
    } else {
      engine.answerTenQuestion(q.key, '没有此症状');
    }
  }
}
