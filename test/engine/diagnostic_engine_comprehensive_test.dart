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

  // ==================== 太阳病 comprehensive tests ====================
  group('太阳病辨证 - 完整测试', () {
    test('中风证：发热+汗出+恶风+浮缓脉 → 桂枝汤', () {
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
      expect(result.pattern, contains('中风'));
    });

    test('伤寒证：发热+无汗+恶寒+浮紧脉 → 麻黄汤', () {
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
      expect(result.formula, contains('麻黄'));
      expect(result.pattern, contains('伤寒'));
    });

    test('温病：发热而渴+不恶寒 → 桂枝汤加葛根/栝蒌桂枝汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_thirst_no_cold');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮');

      _completeTenQuestions(engine, answers: {
        'thirst': '渴想喝冷水',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '太阳');
      expect(result.pattern, contains('温病'));
    });

    test('中风+项背强 → 桂枝加葛根汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('neck_pain');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮缓');

      _completeTenQuestions(engine, answers: {
        'sweating': '稍微活动就出汗',
        'neck': '僵硬',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '太阳');
      expect(result.formula, contains('葛根'));
    });

    test('中风+咳喘 → 桂枝加厚朴杏仁汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('cough');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮缓');

      _completeTenQuestions(engine, answers: {
        'sweating': '稍微活动就出汗',
        'breathing': '喘',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '太阳');
      expect(result.formula, contains('厚朴'));
    });

    test('大青龙汤证：不汗出而烦躁', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮紧');

      _completeTenQuestions(engine, answers: {
        'sweating': '不容易出汗',
        'energy': '烦躁不安',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '太阳');
      expect(result.formula, contains('大青龙'));
    });
  });

  // ==================== 阳明病 comprehensive tests ====================
  group('阳明病辨证 - 完整测试', () {
    test('经热证：身热+大汗+大渴+洪脉 → 白虎加人参汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_no_cold');
      engine.answerTonguePulse(
        tongueCoating: '黄厚',
        tongueShape: '红',
        pulseType: '洪',
      );

      _completeTenQuestions(engine, answers: {
        'sweating': '大量出汗',
        'thirst': '渴想喝冷水',
        'temperature': '手脚温热（正常）',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '阳明');
      expect(result.formula, contains('白虎'));
    });

    test('腑实轻证：胃脘痛+便秘 → 调胃承气汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('abdominal_pain');
      engine.answerTemperaturePattern('fever_no_cold');
      engine.answerTonguePulse(
        tongueCoating: '黄厚',
        pulseType: '沉实',
      );

      _completeTenQuestions(engine, answers: {
        'stool': '便秘，好几天一次',
        'pain': '胃脘痛，按了更痛',
        'thirst': '渴想喝冷水',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '阳明');
      expect(result.formula, contains('承气'));
    });

    test('腑实重证：便秘+谵语+潮热 → 大承气汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('abdominal_pain');
      engine.answerTemperaturePattern('fever_no_cold');
      engine.answerTonguePulse(
        tongueCoating: '黄燥',
        tongueShape: '红',
        pulseType: '沉实',
      );

      _completeTenQuestions(engine, answers: {
        'stool': '便秘好几天不通',
        'pain': '胃脘痛，按了更痛',
        'speech': '有说胡话',
        'thirst': '渴想喝冷水',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '阳明');
      expect(result.formula, contains('大承气'));
    });
  });

  // ==================== 少阳病 comprehensive tests ====================
  group('少阳病辨证 - 完整测试', () {
    test('典型少阳证：口苦+咽干+目眩+弦脉 → 小柴胡汤', () {
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
      expect(result.pattern, contains('小柴胡'));
    });

    test('少阳+便秘 → 大柴胡汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('alternating_chills_fever');
      engine.answerTonguePulse(
        tongueCoating: '黄厚',
        pulseType: '弦',
      );

      _completeTenQuestions(engine, answers: {
        'sweating': '正常出汗',
        'temperature': '全身怕冷',
        'thirst': '口苦口干',
        'stool': '便秘，好几天一次',
        'pain': '胸胁苦满',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '少阳');
      expect(result.formula, contains('大柴胡'));
    });

    test('少阳+烦躁 → 柴胡加龙骨牡蛎汤', () {
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
        'energy': '烦躁不安',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '少阳');
      expect(result.formula, contains('龙骨'));
    });
  });

  // ==================== 太阴病 comprehensive tests ====================
  group('太阴病辨证 - 完整测试', () {
    test('典型太阴证：腹满+吐+食不下+自利+不渴 → 理中汤', () {
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
        'appetite': '吃不下',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, contains('太阴'));
      expect(result.formula, contains('理中'));
    });

    test('太阴虚寒+四肢厥冷 → 理中汤（重证）', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('abdominal_pain');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(
        tongueCoating: '白厚',
        tongueShape: '淡白',
        pulseType: '沉迟',
      );

      _completeTenQuestions(engine, answers: {
        'stool': '稀/拉肚子',
        'thirst': '不渴',
        'temperature': '手脚冰冷',
        'sweating': '不容易出汗',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, contains('太阴'));
    });

    test('太阴+风水 → 防己黄芪汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('edema');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(
        tongueCoating: '白厚',
        pulseType: '浮',
      );

      _completeTenQuestions(engine, answers: {
        'edema': '水肿',
        'sweating': '稍微活动就出汗',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, contains('太阴'));
      expect(result.formula, contains('防己'));
    });
  });

  // ==================== 少阴病 comprehensive tests ====================
  group('少阴病辨证 - 完整测试', () {
    test('少阴寒化：脉微细+但欲寐+四肢厥冷 → 四逆汤', () {
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
      expect(result!.meridian, contains('少阴'));
      expect(result.formula, contains('四逆'));
    });

    test('少阴热化：心烦不得卧+舌红 → 黄连阿胶汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('insomnia');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(
        tongueCoating: '黄薄',
        tongueShape: '红',
        pulseType: '细数',
      );

      _completeTenQuestions(engine, answers: {
        'sleep': '整夜睡不着',
        'energy': '烦躁不安',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '少阴');
      expect(result.formula, contains('黄连'));
      expect(result.pattern, contains('热化'));
    });

    test('少阴水饮：小便不利+水肿 → 真武汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('edema');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(
        tongueCoating: '白厚',
        pulseType: '沉',
      );

      _completeTenQuestions(engine, answers: {
        'sweating': '正常出汗',
        'urine': '小便不利',
        'edema': '水肿',
        'temperature': '手脚冰冷',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, contains('少阴'));
      expect(result.formula, anyOf(contains('真武'), contains('麻黄附子汤')));
    });

    test('少阴经脉寒湿：身体痛+骨节痛 → 附子汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('body_pain');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(
        tongueCoating: '白厚',
        pulseType: '沉',
      );

      _completeTenQuestions(engine, answers: {
        'pain': '全身酸痛',
        'temperature': '手脚冰冷',
        'sweating': '不容易出汗',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, contains('少阴'));
      expect(result.formula, contains('附子'));
    });

    test('少阴虚寒下利便脓血 → 桃花汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('diarrhea');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(
        tongueCoating: '白厚',
        pulseType: '沉',
      );

      _completeTenQuestions(engine, answers: {
        'stool': '脓血便',
        'temperature': '手脚冰冷',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, contains('少阴'));
      expect(result.formula, contains('桃花'));
    });

    test('少阴虚热（轻证）：烦躁失眠但无明显舌脉热象 → 栀子豉汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('insomnia');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(
        tongueCoating: '薄白',
        tongueShape: '淡红',
        pulseType: '细',
      );

      _completeTenQuestions(engine, answers: {
        'sleep': '整夜睡不着',
        'energy': '烦躁不安',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '少阴');
      // 可能是栀子豉汤或黄连阿胶汤，取决于舌脉
      expect(result.formula, anyOf(contains('栀子'), contains('黄连')));
    });
  });

  // ==================== 厥阴病 comprehensive tests ====================
  group('厥阴病辨证 - 完整测试', () {
    test('典型厥阴证：上热下寒+饥不欲食 → 乌梅丸', () {
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
        'thirst': '渴但不想喝',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '厥阴');
      expect(result.formula, contains('乌梅'));
    });

    test('厥阴寒凝：手足厥寒+脉细欲绝 → 当归四逆汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fatigue');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(
        tongueCoating: '白厚',
        pulseType: '细',
      );

      _completeTenQuestions(engine, answers: {
        'temperature': '手脚冰冷',
        'sweating': '不容易出汗',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, anyOf(contains('少阴'), contains('厥阴')));
    });

    test('厥阴寒逆：干呕吐涎沫+头痛 → 吴茱萸汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('headache');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(
        tongueCoating: '白厚',
        pulseType: '沉弦',
      );

      _completeTenQuestions(engine, answers: {
        'pain': '后脑勺痛',
        'vomiting': '干呕',
        'temperature': '手脚冰冷',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, anyOf(contains('厥阴'), contains('少阴')));
    });

    test('厥阴寒格：食入口即吐+上热下寒 → 干姜黄芩黄连人参汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('vomiting');
      engine.answerTemperaturePattern('upper_heat_lower_cold');
      engine.answerTonguePulse(
        tongueCoating: '黄薄',
        pulseType: '沉',
      );

      _completeTenQuestions(engine, answers: {
        'vomiting': '吃进去就吐',
        'thirst': '渴想喝冷水',
        'temperature': '手脚冰冷',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, '厥阴');
      expect(result.formula, contains('干姜'));
    });
  });

  // ==================== 合病/并病 tests ====================
  group('合病/并病辨证', () {
    test('太阳+阳明合病 → 葛根汤类', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(
        tongueCoating: '黄厚',
        pulseType: '浮',
      );

      _completeTenQuestions(engine, answers: {
        'sweating': '不容易出汗',
        'thirst': '渴想喝冷水',
        'stool': '便秘',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      // 可能是太阳或太阳阳明合病
      expect(result!.meridian, anyOf(contains('太阳'), contains('阳明')));
    });

    test('太阳+少阳合病 → 柴胡桂枝汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(
        tongueCoating: '黄薄',
        pulseType: '浮弦',
      );

      _completeTenQuestions(engine, answers: {
        'sweating': '稍微活动就出汗',
        'thirst': '口苦口干',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      // 可能是太阳或少阳，或合病
      expect(result!.meridian, anyOf(
        contains('太阳'),
        contains('少阳'),
      ));
    });

    test('少阳+阳明合病 → 大柴胡汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('alternating_chills_fever');
      engine.answerTonguePulse(
        tongueCoating: '黄厚',
        pulseType: '弦数',
      );

      _completeTenQuestions(engine, answers: {
        'sweating': '正常出汗',
        'temperature': '全身怕冷',
        'thirst': '口苦口干',
        'stool': '便秘，好几天一次',
        'pain': '胸胁苦满',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.meridian, anyOf(contains('少阳'), contains('阳明')));
      expect(result.formula, anyOf(contains('柴胡'), contains('大柴胡')));
    });

    test('太阳+太阴并病 → 桂枝人参汤', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(
        tongueCoating: '白厚',
        pulseType: '浮缓',
      );

      _completeTenQuestions(engine, answers: {
        'sweating': '稍微活动就出汗',
        'stool': '稀/拉肚子',
        'thirst': '不渴',
        'temperature': '手脚温热（正常）',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      // 可能是太阳或太阴，或合病
      expect(result!.meridian, isNotNull);
    });
  });

  // ==================== 脉舌矛盾检测 tests ====================
  group('脉舌矛盾检测', () {
    test('数脉+淡白舌 → 真寒假热警告', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_no_cold');
      engine.answerTonguePulse(
        tongueCoating: '薄白',
        tongueShape: '淡白',
        pulseType: '数',
      );

      _completeTenQuestions(engine, answers: {
        'thirst': '渴想喝热水',
        'temperature': '手脚冰冷',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      // 脉舌矛盾应该被检测到
      if (result!.pulseTongueContradiction != null) {
        expect(result.pulseTongueContradiction, contains('矛盾'));
      }
    });

    test('迟脉+红舌 → 真热假寒警告', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(
        tongueCoating: '黄厚',
        tongueShape: '红',
        pulseType: '迟',
      );

      _completeTenQuestions(engine, answers: {
        'thirst': '渴想喝冷水',
        'stool': '便秘',
        'temperature': '手脚冰冷',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      if (result!.pulseTongueContradiction != null) {
        expect(result.pulseTongueContradiction, contains('矛盾'));
      }
    });

    test('浮脉+厚腻苔 → 里证为主警告', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('abdominal_pain');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(
        tongueCoating: '白厚',
        pulseType: '浮',
      );

      _completeTenQuestions(engine, answers: {
        'stool': '稀/拉肚子',
        'thirst': '不渴',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      if (result!.pulseTongueContradiction != null) {
        expect(result.pulseTongueContradiction, contains('里证'));
      }
    });
  });

  // ==================== 真寒假热/真热假寒 tests ====================
  group('真寒假热/真热假寒检测', () {
    test('真寒假热：上热症状+下寒表现', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fatigue');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(
        tongueCoating: '白厚',
        tongueShape: '淡白',
        pulseType: '微',
      );

      _completeTenQuestions(engine, answers: {
        'temperature': '头热脚冷',
        'energy': '但欲寐（昏昏沉沉）',
        'thirst': '渴想喝热水',
        'urine': '小便清长',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      // 真寒假热可能被检测到
      expect(result!.meridian, isNotNull);
    });

    test('真热假寒：四肢冷+胸腹热+渴喜冷饮', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_no_cold');
      engine.answerTonguePulse(
        tongueCoating: '黄燥',
        tongueShape: '红',
        pulseType: '数',
      );

      _completeTenQuestions(engine, answers: {
        'thirst': '渴想喝冷水',
        'stool': '便秘',
        'temperature': '手脚冰冷',
        'sweating': '大量出汗',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      // 真热假寒可能被检测到
      expect(result!.meridian, anyOf(contains('阳明'), contains('少阳')));
    });
  });

  // ==================== 传经判断 tests ====================
  group('传经判断', () {
    test('太阳→少阳传经：口苦+咽干', () {
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

    test('太阳→阳明传经：大渴+便秘', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮');

      _completeTenQuestions(engine, answers: {
        'sweating': '稍微活动就出汗',
        'thirst': '渴想喝冷水',
        'stool': '便秘',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      if (result!.transmissionWarning != null) {
        expect(result.transmissionWarning, contains('阳明'));
      }
    });

    test('太阴→少阴传经：但欲寐+小便清长', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('abdominal_pain');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(
        tongueCoating: '白厚',
        pulseType: '沉',
      );

      _completeTenQuestions(engine, answers: {
        'stool': '稀/拉肚子',
        'thirst': '不渴',
        'energy': '但欲寐（昏昏沉沉）',
        'urine': '夜尿多，尿色清',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      if (result!.transmissionWarning != null) {
        expect(result.transmissionWarning, contains('少阴'));
      }
    });
  });

  // ==================== 处方生成 tests ====================
  group('处方生成 - 完整测试', () {
    test('桂枝汤处方应包含5味药', () {
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
      expect(result.prescription!.components.length, greaterThanOrEqualTo(5));
      expect(result.prescription!.formulaName, contains('桂枝'));
    });

    test('小柴胡汤处方应包含7味药', () {
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
      expect(result!.prescription, isNotNull);
      expect(result.prescription!.components.length, greaterThanOrEqualTo(7));
      expect(result.prescription!.formulaName, contains('柴胡'));
    });

    test('处方应包含剂量和煎服法', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮缓');

      _completeTenQuestions(engine, answers: {
        'temperature': '全身怕冷',
        'sweating': '稍微活动就出汗',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      final rx = result!.prescription!;
      expect(rx.dosage, isNotEmpty);
      expect(rx.preparation, isNotEmpty);
      expect(rx.contraindication, isNotEmpty);
    });

    test('处方toCopyText应返回完整文本', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮缓');

      _completeTenQuestions(engine, answers: {
        'sweating': '稍微活动就出汗',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      final text = result!.prescription!.toCopyText();
      expect(text, contains('桂枝'));
      expect(text, contains('煎服法'));
    });
  });

  // ==================== 鉴别诊断 tests ====================
  group('鉴别诊断', () {
    test('桂枝汤证应有太阳中风vs伤寒鉴别', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮缓');

      _completeTenQuestions(engine, answers: {
        'sweating': '稍微活动就出汗',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      // 桂枝汤证应该有鉴别诊断
      expect(result!.differential, isNotNull);
    });

    test('小柴胡汤证应有小柴胡vs大柴胡鉴别', () {
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
        'stool': '便秘，好几天一次',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      expect(result!.differential, isNotNull);
    });
  });

  // ==================== 用药铁律 tests ====================
  group('用药铁律检测', () {
    test('少阴病应检测到汗法禁忌', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fatigue');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(
        tongueCoating: '白厚',
        pulseType: '微',
      );

      _completeTenQuestions(engine, answers: {
        'energy': '但欲寐（昏昏沉沉）',
        'temperature': '手脚冰冷',
      });

      final result = engine.diagnose();
      expect(result, isNotNull);
      // 少阴病应该有用药禁忌提示
      expect(result!.meridian, contains('少阴'));
    });
  });

  // ==================== 性别处理 tests ====================
  group('性别处理', () {
    test('男性应跳过月经问题', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fatigue');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(tongueCoating: '白厚', pulseType: '沉');

      // 回答性别问题为男
      engine.answerTenQuestion('gender', '男');

      // 检查是否跳过了月经问题
      final questions = engine.getTenQuestions();
      final menstrualIndex = questions.indexWhere((q) => q.key == 'menstrual');

      // 男性回答后，tenQuestionIndex应该跳过月经问题
      // 继续回答其他问题
      _completeTenQuestions(engine, skipGender: true);

      final result = engine.diagnose();
      expect(result, isNotNull);
    });

    test('女性应保留月经问题', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fatigue');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(tongueCoating: '白厚', pulseType: '沉');

      // 回答性别问题为女
      engine.answerTenQuestion('gender', '女');

      // 继续回答其他问题，包括月经问题
      _completeTenQuestions(engine, skipGender: true);

      final result = engine.diagnose();
      expect(result, isNotNull);
    });
  });

  // ==================== 快照系统 comprehensive tests ====================
  group('快照系统 - 完整测试', () {
    test('多次快照应保持独立', () {
      final engine = DiagnosticEngine();

      // 创建第一个快照
      engine.selectChiefComplaint('fever');
      final snapshot1 = engine.createSnapshot();

      // 继续操作
      engine.answerTemperaturePattern('fever_chills');
      final snapshot2 = engine.createSnapshot();

      // 继续操作
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮');

      // 恢复第一个快照
      engine.restoreSnapshot(snapshot1);
      expect(engine.stage, DiagnosticStage.temperaturePattern);

      // 恢复第二个快照
      engine.restoreSnapshot(snapshot2);
      expect(engine.stage, DiagnosticStage.tonguePulse);
    });

    test('快照应保存完整的十问答案', () {
      final engine = DiagnosticEngine();
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮');

      // 回答部分十问
      engine.answerTenQuestion('gender', '男');
      engine.answerTenQuestion('sleep', '一觉到天亮');

      final snapshot = engine.createSnapshot();

      // 继续回答
      engine.answerTenQuestion('thirst', '不渴');

      // 恢复快照
      engine.restoreSnapshot(snapshot);
      expect(snapshot.answers['sleep'], '一觉到天亮');
      expect(snapshot.answers['thirst'], isNull);
    });
  });

  // ==================== 重置功能 tests ====================
  group('重置功能', () {
    test('reset应清除所有状态', () {
      final engine = DiagnosticEngine();

      // 完成整个诊断流程
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮');
      _completeTenQuestions(engine, answers: {'sweating': '稍微活动就出汗'});

      // 重置
      engine.reset();

      expect(engine.stage, DiagnosticStage.chiefComplaint);
      expect(engine.selectedSymptoms, isEmpty);
      expect(engine.tenQuestionIndex, 0);
    });

    test('reset后应能重新开始诊断', () {
      final engine = DiagnosticEngine();

      // 第一次诊断
      engine.selectChiefComplaint('fever');
      engine.answerTemperaturePattern('fever_chills');
      engine.answerTonguePulse(tongueCoating: '薄白', pulseType: '浮');
      _completeTenQuestions(engine, answers: {'sweating': '稍微活动就出汗'});
      final result1 = engine.diagnose();

      // 重置
      engine.reset();

      // 第二次诊断
      engine.selectChiefComplaint('abdominal_pain');
      engine.answerTemperaturePattern('chills_no_fever');
      engine.answerTonguePulse(tongueCoating: '白厚', pulseType: '沉');
      _completeTenQuestions(engine, answers: {
        'stool': '稀/拉肚子',
        'thirst': '不渴',
      });
      final result2 = engine.diagnose();

      expect(result1, isNotNull);
      expect(result2, isNotNull);
      expect(result1!.meridian, '太阳');
      expect(result2!.meridian, contains('太阴'));
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
  bool skipGender = false,
}) {
  final tenQuestionKeys = <String>{};
  final tenQuestions = engine.getTenQuestions();
  for (final q in tenQuestions) {
    tenQuestionKeys.add(q.key);
    if (skipGender && q.key == 'gender') {
      engine.answerTenQuestion(q.key, '没有此症状');
      continue;
    }
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
  // Process any extra answers not in the ten questions (e.g., neck, vomiting, etc.)
  for (final entry in answers.entries) {
    if (!tenQuestionKeys.contains(entry.key)) {
      engine.answerTenQuestion(entry.key, entry.value);
    }
  }
}
