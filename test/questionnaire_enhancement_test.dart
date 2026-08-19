import 'package:flutter_test/flutter_test.dart';

import 'package:nihaisha_app/engine/diagnostic_engine.dart';
import 'package:nihaisha_app/engine/meridian_formula_types.dart';

/// v1.11.8 问诊四项增强的回归测试：
/// ① 健康人基线判定（healthyBaselineOk）
/// ③ 寒热真假八维法（answerZhenJia → trueFalseHeatCold 触发）
/// ④ 六经公式分型表（meridianFormulaTypes 数据完整性）
/// （② 用药铁律为既有功能，本次仅调整渲染时机，不在引擎层新增）
DiagnosticEngine buildEngine({Map<String, String>? tenOverrides}) {
  final e = DiagnosticEngine();
  e.answerTemperaturePattern('chills_no_fever'); // → '太阴/少阴'，十问内精确定经
  e.answerTonguePulse(); // 跳过舌脉
  const normal = {
    'temperature': '手脚温热（正常·阳）',
    'pulse': '没摸过/不清楚',
    'thirst': '不渴',
    'sweating': '不容易出汗',
    'pain': '不痛',
    'stool': '每天有，成形',
    'urine': '5-7次淡黄色（正常）',
    'appetite': '正常三餐',
    'sleep': '一觉到天亮',
    'energy': '精力充沛',
    'menstrual': '没有此症状',
  };
  final qs = e.getTenQuestions(defaultGender: '男');
  for (final q in qs) {
    final a = tenOverrides?[q.key] ?? normal[q.key];
    if (a == null) continue;
    e.answerTenQuestion(q.key, a);
  }
  return e;
}

void main() {
  group('① 健康人基线判定', () {
    test('六条基线全达标 → healthyBaselineOk = true', () {
      final e = DiagnosticEngine();
      e.answerTenQuestion('temperature', '手脚温热（正常·阳）');
      e.answerTenQuestion('stool', '每天有，成形');
      e.answerTenQuestion('urine', '5-7次淡黄色（正常）');
      e.answerTenQuestion('appetite', '正常三餐');
      e.answerTenQuestion('sleep', '一觉到天亮');
      e.answerTenQuestion('energy', '精力充沛');
      expect(e.healthyBaselineOk, isTrue,
          reason: '六条基线全正常应判定为健康人');
    });

    test('睡眠异常 → healthyBaselineOk = false', () {
      final e = DiagnosticEngine();
      e.answerTenQuestion('temperature', '手脚温热（正常·阳）');
      e.answerTenQuestion('stool', '每天有，成形');
      e.answerTenQuestion('urine', '5-7次淡黄色（正常）');
      e.answerTenQuestion('appetite', '正常三餐');
      e.answerTenQuestion('sleep', '整夜睡不着');
      e.answerTenQuestion('energy', '精力充沛');
      expect(e.healthyBaselineOk, isFalse,
          reason: '睡眠不达标（失眠）不应判定为健康人');
    });
  });

  group('③ 寒热真假八维法', () {
    test('少阴证 + 面红如妆/小便清长线索 → 真寒假热', () {
      final e = buildEngine(tenOverrides: {
        'temperature': '手脚冰冷（阴·阳虚）', // cold_limbs
        'urine': '小便清长', // urine_clear
        'energy': '但欲寐（昏昏沉沉想睡）', // drowsy
      });
      // 显式八维线索（真寒假热方向）
      e.answerZhenJia('face_flush', '面红如妆（两颧鲜红界限分明）');
      e.answerZhenJia('urine_clear', '小便清长、尿色淡白');
      final r = e.diagnose();
      expect(r, isNotNull);
      expect(r!.trueFalseHeatCold, isNotNull,
          reason: '少阴证 + 显式寒热真假线索应触发真寒假热鉴别');
      expect(r.trueFalseHeatCold!.type, '真寒假热');
    });

    test('无异常信号 → 不触发寒热真假', () {
      final e = buildEngine();
      final r = e.diagnose();
      expect(r?.trueFalseHeatCold, isNull);
    });
  });

  group('④ 六经公式分型表', () {
    test('六经分型数据完整（6 经，各含分型）', () {
      expect(meridianFormulaTypes.length, 6);
      final total = meridianFormulaTypes.fold<int>(
          0, (sum, f) => sum + f.types.length);
      expect(total, greaterThanOrEqualTo(9),
          reason: '六经分型合计应 ≥ 9（太阳3/阳明2/少阳1/太阴1/少阴2/厥阴2）');
      for (final f in meridianFormulaTypes) {
        expect(f.types, isNotEmpty, reason: '${f.meridian} 应至少含 1 个分型');
        for (final t in f.types) {
          expect(t.name, isNotEmpty);
          expect(t.sym, isNotEmpty);
          expect(t.rx, isNotEmpty);
        }
      }
      // 按经名查询可用
      expect(meridianFormulaFamilyOf('太阳'), isNotNull);
      expect(meridianFormulaFamilyOf('厥阴')!.types.length, 2);
      expect(meridianFormulaFamilyOf('不存在'), isNull);
    });
  });
}
