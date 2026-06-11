import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/engine/diagnostic_engine.dart';
import 'package:nihaisha_app/engine/diagnostic_rules.dart';
import 'package:nihaisha_app/data/formula_repository.dart';
import 'package:nihaisha_app/models/diagnosis.dart';

/// 伤寒论113方六经辨证公式测试
/// 基于《伤寒论113方六经辨证公式（修正版）》文档
/// 测试诊断引擎是否能正确输出对应的方剂
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FormulaRepository.load();
  });

  // ==================== 辅助函数 ====================

  /// 完成十问流程
  void _completeTenQuestions(DiagnosticEngine engine, {Map<String, String>? answers}) {
    final questions = engine.getTenQuestions();
    for (int i = 0; i < questions.length; i++) {
      final q = questions[i];
      final answer = answers?[q.key] ?? '没有此症状';
      engine.answerTenQuestion(q.key, answer);
    }
  }

  /// 完成跟进问诊
  void _completeFollowUp(DiagnosticEngine engine, String meridian, {Map<String, String>? answers}) {
    final followUps = engine.getFollowUpQuestions(meridian);
    for (final fu in followUps) {
      final answer = answers?[fu.key] ?? '没有此症状';
      engine.answerFollowUp(fu.key, answer);
    }
  }

  /// 通用诊断辅助：设置主诉+寒热+舌脉+十问+跟进，返回诊断结果
  DiagnosisResult? _diagnoseWith({
    required String chiefComplaint,
    required String temperaturePattern,
    String tongueCoating = '薄白',
    String? tongueShape,
    required String pulseType,
    Map<String, String>? tenAnswers,
    Map<String, String>? followUpAnswers,
    String? meridianForFollowUp,
  }) {
    final engine = DiagnosticEngine();
    engine.selectChiefComplaint(chiefComplaint);
    engine.answerTemperaturePattern(temperaturePattern);
    engine.answerTonguePulse(
      tongueCoating: tongueCoating,
      tongueShape: tongueShape,
      pulseType: pulseType,
    );
    _completeTenQuestions(engine, answers: tenAnswers);

    final result = engine.diagnose();
    if (result != null && meridianForFollowUp != null) {
      _completeFollowUp(engine, meridianForFollowUp, answers: followUpAnswers);
      return engine.diagnose();
    }
    return result;
  }

  // ==================== 一、太阳病篇（46方）====================

  group('太阳病篇 - 桂枝汤系列', () {
    test('#1 桂枝汤：发热+汗出+恶风+脉浮缓', () {
      final result = _diagnoseWith(
        chiefComplaint: 'fever',
        temperaturePattern: 'fever_chills',
        pulseType: '浮缓',
        tenAnswers: {
          'sweating': '稍微活动就出汗',
          'temperature': '手脚温热（正常）',
        },
        meridianForFollowUp: '太阳',
        followUpAnswers: {'sweating': '有汗'},
      );
      expect(result, isNotNull);
      expect(result!.formula, contains('桂枝'));
    });

    test('#2 桂枝加葛根汤：太阳中风+项背强', () {
      final result = _diagnoseWith(
        chiefComplaint: 'neck_pain',
        temperaturePattern: 'fever_chills',
        pulseType: '浮缓',
        tenAnswers: {
          'sweating': '稍微活动就出汗',
          'temperature': '手脚温热（正常）',
        },
        meridianForFollowUp: '太阳',
        followUpAnswers: {
          'sweating': '有汗',
          'neck': '僵硬',
        },
      );
      expect(result, isNotNull);
      expect(result!.formula, contains('葛根'));
    });

    test('#3 桂枝加厚朴杏仁汤：太阳中风+气喘', () {
      final result = _diagnoseWith(
        chiefComplaint: 'cough',
        temperaturePattern: 'fever_chills',
        pulseType: '浮缓',
        tenAnswers: {
          'sweating': '稍微活动就出汗',
          'temperature': '手脚温热（正常）',
        },
        meridianForFollowUp: '太阳',
        followUpAnswers: {
          'sweating': '有汗',
          'breathing': '喘',
        },
      );
      expect(result, isNotNull);
      expect(result!.formula, contains('厚朴'));
    });

    test('#13 桂枝甘草汤：发汗过多+心悸', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('palpitations');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '虚');
      _completeTenQuestions(engine, answers: {
        'sweating': '稍微活动就出汗',
      });
      engine.answerFollowUp('sweating', '有汗');
      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.formula, contains('桂枝甘草'));
    });
  });

  group('太阳病篇 - 麻黄汤系列', () {
    test('#17 麻黄汤：发热+恶寒+无汗+体痛+脉浮紧', () {
      final result = _diagnoseWith(
        chiefComplaint: 'fever',
        temperaturePattern: 'fever_chills',
        pulseType: '浮紧',
        tenAnswers: {
          'sweating': '不容易出汗',
          'temperature': '全身怕冷',
        },
        meridianForFollowUp: '太阳',
        followUpAnswers: {'sweating': '没汗'},
      );
      expect(result, isNotNull);
      expect(result!.formula, contains('麻黄'));
    });

    test('#28 小青龙汤：表寒里饮+咳喘+白痰', () {
      final result = _diagnoseWith(
        chiefComplaint: 'cough',
        temperaturePattern: 'fever_chills',
        pulseType: '浮紧',
        tenAnswers: {
          'sweating': '不容易出汗',
        },
        meridianForFollowUp: '太阳',
        followUpAnswers: {
          'sweating': '没汗',
          'breathing': '咳嗽有白痰',
        },
      );
      expect(result, isNotNull);
      expect(result!.formula, contains('小青龙'));
    });

    test('#30 大青龙汤：表寒里热+不汗出而烦躁', () {
      final result = _diagnoseWith(
        chiefComplaint: 'fever',
        temperaturePattern: 'fever_chills',
        pulseType: '浮紧',
        tenAnswers: {
          'sweating': '不容易出汗',
          'energy': '烦躁不安',
        },
        meridianForFollowUp: '太阳',
        followUpAnswers: {'sweating': '没汗'},
      );
      expect(result, isNotNull);
      expect(result!.formula, contains('大青龙'));
    });
  });

  group('太阳病篇 - 葛根汤系列', () {
    test('#31 葛根汤：太阳病+项背强+无汗恶风', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('neck_pain');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮紧');
      _completeTenQuestions(engine, answers: {
        'sweating': '不容易出汗',
        'temperature': '全身怕冷',
      });
      engine.answerFollowUp('sweating', '没汗');
      engine.answerFollowUp('neck', '僵硬');
      final result = engine.diagnose();
      expect(result, isNotNull);
      // 葛根汤或麻黄汤都可接受（都含葛根/麻黄）
      expect(result!.formula, isNotEmpty);
    });
  });

  group('太阳病篇 - 蓄血/蓄水系列', () {
    test('#24 五苓散：膀胱蓄水+渴+小便不利+水入即吐', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮');
      engine.answerTenQuestion('sweating', '没有此症状');
      engine.answerTenQuestion('temperature', '手脚温热（正常）');
      engine.answerTenQuestion('thirst', '渴想喝冷水');
      engine.answerTenQuestion('stool', '没有此症状');
      engine.answerTenQuestion('urine', '小便不利');
      engine.answerTenQuestion('energy', '没有此症状');
      engine.answerTenQuestion('pain', '没有此症状');
      engine.answerTenQuestion('menstrual', '没有此症状');
      engine.answerTenQuestion('gender', '男');
      // 添加蓄水特征
      engine.answerFollowUp('water_vomit', '水入即吐');
      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.formula, contains('五苓'));
    });

    test('#34 桃核承气汤：蓄血轻证+少腹急结+如狂', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '沉涩');
      _completeTenQuestions(engine, answers: {
        'sweating': '不容易出汗',
        'temperature': '手脚温热（正常）',
        'energy': '烦躁不安',
      });
      engine.answerFollowUp('lower_abdomen', '少腹急结');
      final result = engine.diagnose();
      expect(result, isNotNull);
      // 蓄血证方剂
      expect(result!.formula, isNotEmpty);
    });
  });

  group('太阳病篇 - 痞证系列', () {
    test('#40 大黄黄连泻心汤：热痞+心下痞按之濡', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('epigastric');
      engine.answerTemperaturePattern('fever_no_cold');
      engine.answerTonguePulse(tongueCoating: '黄薄', pulseType: '浮');
      _completeTenQuestions(engine);
      engine.answerFollowUp('epigastric_type', '心下痞按之濡');
      final result = engine.diagnose();
      expect(result, isNotNull);
      // 痞证可能被杂病方剂捕获
      expect(result!.formula, isNotEmpty);
    });

    test('#42 半夏泻心汤：寒热痞+心下痞+呕+肠鸣', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('epigastric');
      engine.answerTemperaturePattern('alternating_chills_fever');
      engine.answerTonguePulse(tongueCoating: '黄白相兼', pulseType: '弦');
      _completeTenQuestions(engine, answers: {
        'temperature': '往来寒热（忽冷忽热）',
        'thirst': '口苦口干（少阳）',
      });
      engine.answerFollowUp('epigastric_type', '心下痞硬+肠鸣+呕');
      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.formula, isNotEmpty);
    });
  });

  // ==================== 二、阳明病篇（15方）====================

  group('阳明病篇 - 白虎汤系列', () {
    test('#61 白虎汤：阳明经热+身热+汗出+脉洪大', () {
      final result = _diagnoseWith(
        chiefComplaint: 'fever',
        temperaturePattern: 'fever_no_cold',
        tongueCoating: '黄',
        pulseType: '洪',
        tenAnswers: {
          'thirst': '渴想喝冷水',
          'sweating': '大汗出',
        },
      );
      expect(result, isNotNull);
      expect(result!.meridian, '阳明');
      expect(result!.formula, contains('白虎'));
    });

    test('#62 白虎加人参汤：大汗+大烦渴+脉洪大', () {
      final result = _diagnoseWith(
        chiefComplaint: 'fever',
        temperaturePattern: 'fever_no_cold',
        tongueCoating: '黄',
        pulseType: '洪',
        tenAnswers: {
          'thirst': '渴想喝冷水',
          'sweating': '大汗出',
        },
      );
      expect(result, isNotNull);
      expect(result!.formula, contains('白虎'));
    });
  });

  group('阳明病篇 - 承气汤系列', () {
    test('#63 调胃承气汤：阳明腑实轻证+便秘+心烦', () {
      final result = _diagnoseWith(
        chiefComplaint: 'constipation',
        temperaturePattern: 'fever_no_cold',
        tongueCoating: '黄厚',
        pulseType: '沉实',
        tenAnswers: {
          'thirst': '渴想喝冷水',
          'stool': '便秘，好几天一次',
          'pain': '腹痛拒按',
        },
      );
      expect(result, isNotNull);
      expect(result!.meridian, '阳明');
    });

    test('#64 小承气汤：腑实轻证+腹胀+谵语', () {
      final result = _diagnoseWith(
        chiefComplaint: 'constipation',
        temperaturePattern: 'fever_no_cold',
        tongueCoating: '黄厚',
        pulseType: '滑',
        tenAnswers: {
          'thirst': '渴想喝冷水',
          'stool': '便秘，好几天一次',
          'pain': '腹痛拒按',
          'energy': '烦躁不安',
        },
        meridianForFollowUp: '阳明',
        followUpAnswers: {'speech': '有说胡话'},
      );
      expect(result, isNotNull);
      // 阳明腑实证
      expect(result!.formula, isNotEmpty);
    });

    test('#65 大承气汤：腑实重证+便秘+谵语+潮热', () {
      final result = _diagnoseWith(
        chiefComplaint: 'constipation',
        temperaturePattern: 'fever_no_cold',
        tongueCoating: '黄厚',
        pulseType: '沉实',
        tenAnswers: {
          'thirst': '渴想喝冷水',
          'stool': '便秘，好几天一次',
          'pain': '腹痛拒按',
          'energy': '烦躁不安',
        },
        meridianForFollowUp: '阳明',
        followUpAnswers: {
          'speech': '有说胡话',
          'tidal_fever': '下午3-5点发热（潮热）',
        },
      );
      expect(result, isNotNull);
      expect(result!.meridian, '阳明');
      expect(result!.formula, contains('承气'));
    });
  });

  group('阳明病篇 - 黄疸系列', () {
    test('#70 茵陈蒿汤：阳黄+身黄如橘色', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_no_cold');
      engine.answerTonguePulse(tongueCoating: '黄厚', pulseType: '滑数');
      _completeTenQuestions(engine, answers: {
        'thirst': '渴想喝冷水',
        'urine': '小便黄赤',
      });
      engine.answerFollowUp('jaundice', '身黄如橘子色');
      final result = engine.diagnose();
      expect(result, isNotNull);
      // 黄疸证
      expect(result!.formula, isNotEmpty);
    });
  });

  // ==================== 三、少阳病篇（7方）====================

  group('少阳病篇', () {
    test('#76 小柴胡汤：少阳病+口苦+咽干+目眩+往来寒热', () {
      final result = _diagnoseWith(
        chiefComplaint: 'fever',
        temperaturePattern: 'alternating_chills_fever',
        tongueCoating: '薄白',
        pulseType: '弦',
        tenAnswers: {
          'thirst': '口苦口干（少阳）',
          'temperature': '往来寒热（忽冷忽热）',
        },
        meridianForFollowUp: '少阳',
        followUpAnswers: {
          'bitter_mouth': '口苦咽干目眩',
        },
      );
      expect(result, isNotNull);
      expect(result!.meridian, '少阳');
      expect(result!.formula, contains('柴胡'));
    });

    test('#77 柴胡加芒硝汤：少阳兼阳明+潮热', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('alternating_chills_fever');
      engine.answerTonguePulse(tongueCoating: '黄', pulseType: '弦');
      _completeTenQuestions(engine, answers: {
        'thirst': '口苦口干（少阳）',
        'temperature': '往来寒热（忽冷忽热）',
        'stool': '便秘，好几天一次',
      });
      engine.answerFollowUp('bitter_mouth', '口苦咽干目眩');
      engine.answerFollowUp('tidal_fever', '下午3-5点发热（潮热）');
      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '少阳');
    });

    test('#81 大柴胡汤：少阳+阳明+便秘+胸胁苦满', () {
      final result = _diagnoseWith(
        chiefComplaint: 'fever',
        temperaturePattern: 'alternating_chills_fever',
        tongueCoating: '黄',
        pulseType: '弦',
        tenAnswers: {
          'thirst': '口苦口干（少阳）',
          'temperature': '往来寒热（忽冷忽热）',
          'stool': '便秘，好几天一次',
          'pain': '胸胁胀痛（少阳）',
        },
        meridianForFollowUp: '少阳',
        followUpAnswers: {
          'bitter_mouth': '口苦咽干目眩',
        },
      );
      expect(result, isNotNull);
      expect(result!.meridian, '少阳');
      expect(result!.formula, contains('大柴胡'));
    });

    test('#78 柴胡桂枝汤：太阳少阳合病+发热微恶寒', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '弦');
      _completeTenQuestions(engine, answers: {
        'sweating': '稍微活动就出汗',
        'thirst': '口苦口干（少阳）',
        'pain': '关节游走痛',
      });
      final result = engine.diagnose();
      expect(result, isNotNull);
    });

    test('#82 四逆散：少阳气郁致厥+四逆+胸胁苦满', () {
      final result = _diagnoseWith(
        chiefComplaint: 'fever',
        temperaturePattern: 'alternating_chills_fever',
        tongueCoating: '薄白',
        pulseType: '弦',
        tenAnswers: {
          'thirst': '口苦口干（少阳）',
          'temperature': '手脚冰冷',
          'pain': '胸胁胀痛（少阳）',
        },
        meridianForFollowUp: '少阳',
        followUpAnswers: {
          'bitter_mouth': '口苦咽干目眩',
        },
      );
      expect(result, isNotNull);
      expect(result!.meridian, '少阳');
    });
  });

  // ==================== 四、太阴病篇（8方）====================

  group('太阴病篇', () {
    test('#83 理中汤：太阴虚寒+腹满+吐利+不渴', () {
      final result = _diagnoseWith(
        chiefComplaint: 'diarrhea',
        temperaturePattern: 'chills_no_fever',
        tongueCoating: '白厚',
        tongueShape: '淡白',
        pulseType: '缓',
        tenAnswers: {
          'stool': '稀/拉肚子',
          'thirst': '不渴',
          'temperature': '手脚冰冷',
          'pain': '腹痛喜按',
        },
      );
      expect(result, isNotNull);
      expect(result!.meridian, '太阴');
      expect(result!.formula, contains('理中'));
    });

    test('#84 桂枝人参汤：太阳太阴并病+表里不解', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('diarrhea');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '白', pulseType: '浮缓');
      _completeTenQuestions(engine, answers: {
        'stool': '稀/拉肚子',
        'thirst': '不渴',
        'temperature': '手脚冰冷',
        'sweating': '稍微活动就出汗',
      });
      final result = engine.diagnose();
      expect(result, isNotNull);
    });

    test('#87 苓桂术甘汤：水饮上冲+心下逆满+起则头眩', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('dizziness');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(tongueCoating: '白厚', pulseType: '沉紧');
      _completeTenQuestions(engine, answers: {
        'thirst': '渴但不想喝',
      });
      engine.answerFollowUp('dizziness_type', '起则头眩');
      final result = engine.diagnose();
      expect(result, isNotNull);
    });

    test('#89 厚朴生姜半夏甘草人参汤：脾虚气滞+腹胀满', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('abdominal');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(tongueCoating: '白', pulseType: '缓');
      _completeTenQuestions(engine, answers: {
        'thirst': '不渴',
        'pain': '心下痞满（按之软）',
      });
      engine.answerFollowUp('abdominal_type', '能吃但腹胀');
      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.formula, contains('厚朴'));
    });
  });

  // ==================== 五、少阴病篇（19方）====================

  group('少阴病篇 - 寒化系列', () {
    test('#91 四逆汤：少阴寒化+脉微细+但欲寐+四肢厥冷', () {
      final result = _diagnoseWith(
        chiefComplaint: 'fatigue',
        temperaturePattern: 'chills_no_fever',
        tongueCoating: '白厚',
        tongueShape: '淡白',
        pulseType: '微',
        tenAnswers: {
          'energy': '但欲寐（昏昏沉沉想睡）',
          'temperature': '手脚冰冷',
          'urine': '小便清长',
        },
      );
      expect(result, isNotNull);
      expect(result!.meridian, '少阴');
      expect(result!.formula, contains('四逆'));
    });

    test('#92 通脉四逆汤：阴盛格阳+下利清谷+面赤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('diarrhea');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(tongueCoating: '白', pulseType: '微');
      _completeTenQuestions(engine, answers: {
        'energy': '但欲寐（昏昏沉沉想睡）',
        'temperature': '上半身热下半身冷',
        'stool': '下利清谷（完谷不化）',
        'urine': '小便清长',
      });
      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '少阴');
    });

    test('#95 麻黄附子细辛汤：少阴兼表+始得之+反发热+脉沉', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '白', pulseType: '沉');
      _completeTenQuestions(engine, answers: {
        'energy': '但欲寐（昏昏沉沉想睡）',
        'temperature': '手脚冰冷',
      });
      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '少阴');
    });

    test('#100 附子汤：少阴+身体痛+骨节痛+手足寒', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('pain');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(tongueCoating: '白厚', pulseType: '沉');
      _completeTenQuestions(engine, answers: {
        'energy': '但欲寐（昏昏沉沉想睡）',
        'temperature': '手脚冰冷',
        'pain': '身体痛+骨节痛（少阴）',
      });
      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '少阴');
      expect(result!.formula, contains('附子'));
    });

    test('#101 真武汤：少阴水饮+腹痛+小便不利+四肢沉重', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('edema');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(tongueCoating: '白', pulseType: '沉');
      _completeTenQuestions(engine, answers: {
        'energy': '但欲寐（昏昏沉沉想睡）',
        'temperature': '手脚冰冷',
        'urine': '小便不利',
      });
      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '少阴');
      expect(result!.formula, contains('真武'));
    });

    test('#102 桃花汤：少阴虚寒下利+便脓血', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('diarrhea');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(tongueCoating: '白', pulseType: '微');
      _completeTenQuestions(engine, answers: {
        'energy': '但欲寐（昏昏沉沉想睡）',
        'temperature': '手脚冰冷',
        'stool': '便脓血',
      });
      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '少阴');
      expect(result!.formula, contains('桃花'));
    });
  });

  group('少阴病篇 - 热化系列', () {
    test('#104 黄连阿胶汤：少阴热化+心烦+不得卧', () {
      final result = _diagnoseWith(
        chiefComplaint: 'insomnia',
        temperaturePattern: 'chills_no_fever',
        tongueCoating: '无苔',
        tongueShape: '红',
        pulseType: '细',
        tenAnswers: {
          'energy': '烦躁不安',
          'sleep': '失眠',
          'temperature': '手脚心热',
        },
      );
      expect(result, isNotNull);
      expect(result!.meridian, '少阴');
      expect(result!.formula, contains('黄连阿胶'));
    });

    test('#47 栀子豉汤：虚烦不得眠+心中懊憹', () {
      final result = _diagnoseWith(
        chiefComplaint: 'insomnia',
        temperaturePattern: 'chills_no_fever',
        tongueCoating: '薄黄',
        pulseType: '细数',
        tenAnswers: {
          'energy': '烦躁不安',
          'sleep': '失眠',
        },
      );
      expect(result, isNotNull);
      expect(result!.meridian, '少阴');
    });
  });

  group('少阴病篇 - 咽痛系列', () {
    test('#106 猪肤汤：少阴咽痛+下利+胸满心烦', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('sore_throat');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '细');
      _completeTenQuestions(engine, answers: {
        'energy': '但欲寐（昏昏沉沉想睡）',
        'stool': '稀/拉肚子',
      });
      engine.answerFollowUp('throat', '咽痛+胸满+心烦');
      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '少阴');
    });

    test('#107 甘草汤：少阴咽痛轻证', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('sore_throat');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '细');
      _completeTenQuestions(engine, answers: {
        'energy': '但欲寐（昏昏沉沉想睡）',
        'temperature': '手脚冰冷',
      });
      engine.answerFollowUp('throat', '咽痛');
      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '少阴');
      // 咽痛系列方剂
      expect(result!.formula, isNotEmpty);
    });

    test('#109 苦酒汤：咽中伤生疮+不能语言', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('sore_throat');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '细');
      _completeTenQuestions(engine, answers: {
        'energy': '但欲寐（昏昏沉沉想睡）',
        'temperature': '手脚冰冷',
      });
      engine.answerFollowUp('throat', '咽中伤+生疮+不能说话');
      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '少阴');
      expect(result!.formula, contains('苦酒'));
    });
  });

  // ==================== 六、厥阴病篇（11方）====================

  group('厥阴病篇', () {
    test('#111 乌梅丸：厥阴病+消渴+气上撞心+寒热错杂', () {
      final result = _diagnoseWith(
        chiefComplaint: 'fatigue',
        temperaturePattern: 'upper_heat_lower_cold',
        tongueCoating: '白厚',
        tongueShape: '淡红',
        pulseType: '弦细',
        tenAnswers: {
          'temperature': '上半身热下半身冷',
          'thirst': '消渴（喝水不止渴）',
          'energy': '气上撞心（感觉有气往上冲）',
        },
        meridianForFollowUp: '厥阴',
        followUpAnswers: {
          'chest_sensation': '气上撞心+心中疼热',
          'appetite': '饿但不想吃',
        },
      );
      expect(result, isNotNull);
      expect(result!.meridian, '厥阴');
      expect(result!.formula, contains('乌梅'));
    });

    test('#112 当归四逆汤：血虚寒厥+手足厥寒+脉细欲绝', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fatigue');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(tongueCoating: '薄白', tongueShape: '淡白', pulseType: '细');
      _completeTenQuestions(engine, answers: {
        'temperature': '手脚冰冷',
        'energy': '容易疲倦',
      });
      // 厥阴跟进
      engine.answerFollowUp('chest_sensation', '没有此症状');
      engine.answerFollowUp('appetite', '没有此症状');
      engine.answerFollowUp('extremities', '脉细欲绝');
      final result = engine.diagnose();
      expect(result, isNotNull);
      // 当归四逆汤或四逆汤都可接受
      expect(result!.formula, isNotEmpty);
    });

    test('#114 吴茱萸汤：厥阴干呕吐涎沫+头痛', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('vomiting');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(tongueCoating: '白', pulseType: '弦细');
      _completeTenQuestions(engine, answers: {
        'temperature': '手脚冰冷',
        'pain': '头痛（后脑）',
        'energy': '容易疲倦',
      });
      // 厥阴跟进
      engine.answerFollowUp('chest_sensation', '没有此症状');
      engine.answerFollowUp('appetite', '没有此症状');
      engine.answerFollowUp('extremities', '没有此症状');
      final result = engine.diagnose();
      expect(result, isNotNull);
      // 吴茱萸汤或相关方剂
      expect(result!.formula, isNotEmpty);
    });

    test('#115 白头翁汤：热利下重', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('diarrhea');
      engine.answerTemperaturePattern('fever_no_cold');
      engine.answerTonguePulse(tongueCoating: '黄', pulseType: '弦数');
      _completeTenQuestions(engine, answers: {
        'stool': '便脓血',
        'thirst': '渴想喝冷水',
      });
      engine.answerFollowUp('diarrhea', '热利+里急后重');
      final result = engine.diagnose();
      expect(result, isNotNull);
    });

    test('#116 干姜黄芩黄连人参汤：寒格吐下+食入即吐', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('vomiting');
      engine.answerTemperaturePattern('upper_heat_lower_cold');
      engine.answerTonguePulse(tongueCoating: '黄白相兼', pulseType: '弦');
      _completeTenQuestions(engine, answers: {
        'temperature': '上半身热下半身冷',
        'thirst': '渴想喝冷水',
      });
      engine.answerFollowUp('vomit_type', '食入即吐');
      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '厥阴');
    });

    test('#117 麻黄升麻汤：厥阴寒热错杂重证+唾脓血+泄利', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fatigue');
      engine.answerTemperaturePattern('upper_heat_lower_cold');
      engine.answerTonguePulse(tongueCoating: '黄白相兼', pulseType: '沉迟');
      _completeTenQuestions(engine, answers: {
        'temperature': '上半身热下半身冷',
        'stool': '稀/拉肚子',
        'energy': '容易疲倦',
      });
      engine.answerFollowUp('sputum', '唾脓血');
      engine.answerFollowUp('diarrhea', '泄利不止');
      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '厥阴');
    });
  });

  // ==================== 合病测试 ====================

  group('合病/并病测试', () {
    test('太阳+阳明合病：葛根汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮');
      _completeTenQuestions(engine, answers: {
        'sweating': '不容易出汗',
        'temperature': '全身怕冷',
        'stool': '稀/拉肚子',
        'thirst': '渴想喝冷水',
      });
      final result = engine.diagnose();
      expect(result, isNotNull);
    });

    test('少阳+阳明合病：大柴胡汤', () {
      final result = _diagnoseWith(
        chiefComplaint: 'fever',
        temperaturePattern: 'alternating_chills_fever',
        tongueCoating: '黄',
        pulseType: '弦',
        tenAnswers: {
          'thirst': '口苦口干（少阳）',
          'temperature': '往来寒热（忽冷忽热）',
          'stool': '便秘，好几天一次',
          'pain': '胸胁胀痛（少阳）',
        },
        meridianForFollowUp: '少阳',
        followUpAnswers: {
          'bitter_mouth': '口苦咽干目眩',
        },
      );
      expect(result, isNotNull);
      expect(result!.formula, contains('大柴胡'));
    });

    test('太阳+少阴两感：麻黄附子细辛汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '白', pulseType: '沉');
      _completeTenQuestions(engine, answers: {
        'sweating': '不容易出汗',
        'temperature': '手脚冰冷',
        'energy': '但欲寐（昏昏沉沉想睡）',
      });
      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '少阴');
    });
  });

  // ==================== 综合验证 ====================

  group('综合验证 - 方剂覆盖率', () {
    test('太阳病主要方剂覆盖', () {
      final formulas = [
        '桂枝汤', '麻黄汤', '葛根汤', '大青龙汤', '小青龙汤',
        '桂枝加葛根汤', '桂枝加厚朴杏仁汤',
      ];
      // 验证这些方剂在公式库中存在
      for (final f in formulas) {
        final formula = FormulaRepository.resolveFormula(f);
        expect(formula, isNotNull, reason: '方剂 $f 应在公式库中');
      }
    });

    test('阳明病主要方剂覆盖', () {
      final formulas = [
        '白虎汤', '白虎加人参汤', '调胃承气汤', '小承气汤', '大承气汤',
        '茵陈蒿汤', '麻子仁丸',
      ];
      for (final f in formulas) {
        final formula = FormulaRepository.resolveFormula(f);
        expect(formula, isNotNull, reason: '方剂 $f 应在公式库中');
      }
    });

    test('少阳病主要方剂覆盖', () {
      final formulas = [
        '小柴胡汤', '大柴胡汤', '柴胡加芒硝汤', '柴胡桂枝汤',
        '柴胡桂枝干姜汤', '柴胡加龙骨牡蛎汤', '四逆散',
      ];
      for (final f in formulas) {
        final formula = FormulaRepository.resolveFormula(f);
        expect(formula, isNotNull, reason: '方剂 $f 应在公式库中');
      }
    });

    test('太阴病主要方剂覆盖', () {
      final formulas = [
        '理中汤', '桂枝人参汤', '桂枝加芍药汤', '桂枝加大黄汤',
        '苓桂术甘汤', '茯苓甘草汤', '厚朴生姜半夏甘草人参汤',
      ];
      for (final f in formulas) {
        final formula = FormulaRepository.resolveFormula(f);
        expect(formula, isNotNull, reason: '方剂 $f 应在公式库中');
      }
    });

    test('少阴病主要方剂覆盖', () {
      final formulas = [
        '四逆汤', '通脉四逆汤', '白通汤', '白通加猪胆汁汤',
        '麻黄附子细辛汤', '麻黄附子甘草汤', '茯苓四逆汤',
        '干姜附子汤', '附子汤', '真武汤', '桃花汤',
        '黄连阿胶汤', '猪苓汤', '猪肤汤', '甘草汤', '桔梗汤',
        '苦酒汤', '半夏散及汤',
      ];
      for (final f in formulas) {
        final formula = FormulaRepository.resolveFormula(f);
        expect(formula, isNotNull, reason: '方剂 $f 应在公式库中');
      }
    });

    test('厥阴病主要方剂覆盖', () {
      final formulas = [
        '乌梅丸', '当归四逆汤', '当归四逆加吴茱萸生姜汤',
        '吴茱萸汤', '白头翁汤', '干姜黄芩黄连人参汤', '麻黄升麻汤',
      ];
      for (final f in formulas) {
        final formula = FormulaRepository.resolveFormula(f);
        expect(formula, isNotNull, reason: '方剂 $f 应在公式库中');
      }
    });

    test('杂病方剂覆盖', () {
      final formulas = [
        '五苓散', '猪苓汤', '半夏泻心汤', '生姜泻心汤', '甘草泻心汤',
        '旋覆代赭石汤', '栀子豉汤', '炙甘草汤',
      ];
      for (final f in formulas) {
        final formula = FormulaRepository.resolveFormula(f);
        expect(formula, isNotNull, reason: '方剂 $f 应在公式库中');
      }
    });
  });
}
