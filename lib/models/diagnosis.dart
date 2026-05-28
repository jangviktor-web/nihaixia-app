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
