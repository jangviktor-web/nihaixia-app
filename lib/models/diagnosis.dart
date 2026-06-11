enum ModificationType { add, remove, replace }

class FormulaModification {
  final String condition;
  final String symptom;
  final ModificationType type;
  final String herbName;
  final String? replaceWith;
  final String resultFormula;
  final String description;

  const FormulaModification({
    required this.condition,
    required this.symptom,
    required this.type,
    required this.herbName,
    this.replaceWith,
    this.resultFormula = '',
    this.description = '',
  });
}

class FormulaPrescription {
  final String formulaName;
  final List<PrescriptionComponent> components;
  final String dosage;
  final String preparation;
  final String contraindication;
  final List<FormulaModification>? modifications;

  const FormulaPrescription({
    required this.formulaName,
    required this.components,
    this.dosage = '',
    this.preparation = '',
    this.contraindication = '',
    this.modifications,
  });

  String get componentsText =>
      components.map((c) => '${c.name} ${c.dosage}').join('  ');

  String toCopyText() {
    final buf = StringBuffer();
    buf.writeln('📋 处方: $formulaName');
    buf.writeln('─────────────────');
    buf.write('组成: ');
    buf.writeln(components.map((c) => '${c.name}${c.dosage}').join('  '));
    if (dosage.isNotEmpty) buf.writeln('\n💊 剂量: $dosage');
    if (preparation.isNotEmpty) buf.writeln('\n💊 煎服法:\n$preparation');
    if (contraindication.isNotEmpty) buf.writeln('\n⚠️ 禁忌:\n$contraindication');
    if (modifications != null && modifications!.isNotEmpty) {
      buf.writeln('\n🔄 加减建议:');
      for (final m in modifications!) {
        buf.writeln('• ${m.condition} → ${m.description}');
      }
    }
    return buf.toString();
  }
}

class PrescriptionComponent {
  final String name;
  final String dosage;
  final String role;

  const PrescriptionComponent({
    required this.name,
    this.dosage = '',
    this.role = '',
  });
}

class DiagnosisResult {
  final String meridian;
  final String pattern;
  final String patternDetail;
  final String formula;
  final String explanation;
  final double confidence;
  final List<String> matchedSymptoms;
  final List<String> followUpQuestions;
  final String? combinedMeridian;
  final String? tongueCoating;
  final String? tongueShape;
  final String? pulseType;
  final Map<String, List<String>>? careAdvice;
  final DifferentialDiagnosisResult? differential;
  final FormulaPrescription? prescription;
  final Map<String, dynamic> answers;

  // P0-1: 真寒假热/真热假寒鉴别
  final TrueFalseHeatCold? trueFalseHeatCold;
  // P0-4: 用药铁律
  final List<MedicationRule>? medicationRules;
  // P0-5: 汗法禁忌
  final List<SweatingContraindication>? sweatingContraindications;
  // P1-3: 瘀血五法
  final List<BloodStasisSign>? bloodStasisSigns;
  // P1-4: 组合脉象
  final PulseCombination? pulseCombination;
  // P1-5: 望面色
  final FacialComplexion? facialComplexion;
  // P1-6: 条文级鉴别
  final PatternDifferential? patternDifferential;
  // P1-7: 传经判断
  final MeridianTransmission? transmission;
  // 传经预警文本
  final String? transmissionWarning;
  // 脉舌矛盾警告
  final String? pulseTongueContradiction;

  DiagnosisResult({
    required this.meridian,
    required this.pattern,
    this.patternDetail = '',
    required this.formula,
    this.explanation = '',
    this.confidence = 1.0,
    this.matchedSymptoms = const [],
    this.followUpQuestions = const [],
    this.combinedMeridian,
    this.tongueCoating,
    this.tongueShape,
    this.pulseType,
    this.careAdvice,
    this.differential,
    this.prescription,
    this.answers = const {},
    this.trueFalseHeatCold,
    this.medicationRules,
    this.sweatingContraindications,
    this.bloodStasisSigns,
    this.pulseCombination,
    this.facialComplexion,
    this.patternDifferential,
    this.transmission,
    this.transmissionWarning,
    this.pulseTongueContradiction,
  });

  bool get isCombined => combinedMeridian != null;

  String get displayMeridian {
    if (isCombined) return '$meridian${combinedMeridian}合病';
    return meridian;
  }

  String get meridianEmoji {
    switch (meridian) {
      case '太阳':
        return '☀️';
      case '阳明':
        return '🔥';
      case '少阳':
        return '🌅';
      case '太阴':
        return '🌙';
      case '少阴':
        return '🌑';
      case '厥阴':
        return '☯️';
      default:
        return '🏥';
    }
  }

  String get meridianColor {
    switch (meridian) {
      case '太阳':
        return '#FF9800';
      case '阳明':
        return '#F44336';
      case '少阳':
        return '#FF5722';
      case '太阴':
        return '#2196F3';
      case '少阴':
        return '#9C27B0';
      case '厥阴':
        return '#607D8B';
      default:
        return '#795548';
    }
  }
}

class DifferentialDiagnosisResult {
  final String name1;
  final String formula1;
  final String name2;
  final String formula2;
  final String keyDifference;
  final Map<String, String> details;

  DifferentialDiagnosisResult({
    required this.name1,
    required this.formula1,
    required this.name2,
    required this.formula2,
    required this.keyDifference,
    required this.details,
  });
}

enum DiagnosticStage {
  chiefComplaint,
  temperaturePattern,
  tonguePulse,
  tenQuestions,
  meridianLocation,
  formulaConfirmation,
  result,
}

// ==================== P0-1: 真寒假热/真热假寒八维鉴别 ====================

class TrueFalseHeatCold {
  final String type; // '真寒假热' or '真热假寒'
  final String description;
  final Map<String, String> dimensions; // 八个维度

  const TrueFalseHeatCold({
    required this.type,
    required this.description,
    required this.dimensions,
  });
}

// ==================== P1-3: 瘀血五法 ====================

class BloodStasisSign {
  final String method; // 诊断方法名
  final String description; // 具体表现
  final String clinicalSignificance; // 临床意义

  const BloodStasisSign({
    required this.method,
    required this.description,
    required this.clinicalSignificance,
  });
}

// ==================== P1-5: 望面色 ====================

class FacialComplexion {
  final String color; // 面色
  final String meridian; // 对应经络
  final String formula; // 对应方剂
  final String description; // 说明

  const FacialComplexion({
    required this.color,
    required this.meridian,
    required this.formula,
    required this.description,
  });
}

// ==================== P0-4: 用药铁律 ====================

class MedicationRule {
  final String category; // '禁忌' or '误治急救'
  final String condition; // 适用证型
  final String prohibition; // 禁忌内容
  final String reason; // 原因
  final String emergencyTreatment; // 误治后的急救方法（可选）

  const MedicationRule({
    required this.category,
    required this.condition,
    required this.prohibition,
    required this.reason,
    this.emergencyTreatment = '',
  });
}

// ==================== P0-5: 汗法禁忌 ====================

class SweatingContraindication {
  final String condition; // 禁忌证型
  final String reason; // 原因
  final String consequence; // 后果

  const SweatingContraindication({
    required this.condition,
    required this.reason,
    required this.consequence,
  });
}

// ==================== P1-7: 传经判断 ====================

class MeridianTransmission {
  final String from; // 传入前
  final String to; // 传入后
  final String sign; // 传经信号
  final String treatment; // 治疗原则

  const MeridianTransmission({
    required this.from,
    required this.to,
    required this.sign,
    required this.treatment,
  });
}

// ==================== P1-4: 组合脉象 ====================

class PulseCombination {
  final String pulse1;
  final String pulse2;
  final String meridian;
  final String formula;
  final String description;

  const PulseCombination({
    required this.pulse1,
    required this.pulse2,
    required this.meridian,
    required this.formula,
    required this.description,
  });
}

// ==================== P1-6: 条文级鉴别要点 ====================

class PatternDifferential {
  final String pattern1;
  final String pattern2;
  final String classicText; // 原文条文
  final String keyPoint; // 关键鉴别点
  final String niNote; // 倪海厦注解

  const PatternDifferential({
    required this.pattern1,
    required this.pattern2,
    required this.classicText,
    required this.keyPoint,
    required this.niNote,
  });
}
