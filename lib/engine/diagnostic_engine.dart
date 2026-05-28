import '../models/diagnosis.dart';
import '../data/formula_repository.dart';
import 'diagnostic_rules.dart';

/// 引擎快照，用于返回上一步
class EngineSnapshot {
  final DiagnosticStage stage;
  final List<String> selectedSymptoms;
  final String? meridianDirection;
  final String? combinedMeridian;
  final Map<String, dynamic> answers;
  final int tenQuestionIndex;
  final String? tongueCoating;
  final String? tongueShape;
  final String? pulseType;

  EngineSnapshot({
    required this.stage,
    required this.selectedSymptoms,
    this.meridianDirection,
    this.combinedMeridian,
    required this.answers,
    required this.tenQuestionIndex,
    this.tongueCoating,
    this.tongueShape,
    this.pulseType,
  });
}

class DiagnosticEngine {
  DiagnosticStage _stage = DiagnosticStage.chiefComplaint;
  List<String> _selectedSymptoms = [];
  String? _meridianDirection;
  String? _combinedMeridian;
  String? _combinedPatternCondition; // 精确匹配的合病条件key
  Map<String, dynamic> _answers = {};
  int _tenQuestionIndex = 0;
  String? _tongueCoating;
  String? _tongueShape;
  String? _pulseType;

  DiagnosticStage get stage => _stage;
  List<String> get selectedSymptoms => List.unmodifiable(_selectedSymptoms);
  int get tenQuestionIndex => _tenQuestionIndex;

  void reset() {
    _stage = DiagnosticStage.chiefComplaint;
    _selectedSymptoms = [];
    _meridianDirection = null;
    _combinedMeridian = null;
    _combinedPatternCondition = null;
    _answers = {};
    _tenQuestionIndex = 0;
    _tongueCoating = null;
    _tongueShape = null;
    _pulseType = null;
  }

  // ==================== 快照系统 ====================

  EngineSnapshot createSnapshot() {
    return EngineSnapshot(
      stage: _stage,
      selectedSymptoms: List.from(_selectedSymptoms),
      meridianDirection: _meridianDirection,
      combinedMeridian: _combinedMeridian,
      answers: Map.from(_answers),
      tenQuestionIndex: _tenQuestionIndex,
      tongueCoating: _tongueCoating,
      tongueShape: _tongueShape,
      pulseType: _pulseType,
    );
  }

  void restoreSnapshot(EngineSnapshot snapshot) {
    _stage = snapshot.stage;
    _selectedSymptoms = List.from(snapshot.selectedSymptoms);
    _meridianDirection = snapshot.meridianDirection;
    _combinedMeridian = snapshot.combinedMeridian;
    _answers = Map.from(snapshot.answers);
    _tenQuestionIndex = snapshot.tenQuestionIndex;
    _tongueCoating = snapshot.tongueCoating;
    _tongueShape = snapshot.tongueShape;
    _pulseType = snapshot.pulseType;
  }

  // ==================== 问候与选项 ====================

  String getInitialGreeting() {
    return '你好，我是汉唐中医辨证助手。\n\n'
        '我将按照倪海厦老师的辨证方法，通过六步问诊帮你分析：\n'
        '1️⃣ 主诉症状\n'
        '2️⃣ 寒热辨经\n'
        '3️⃣ 舌诊脉诊（望诊）\n'
        '4️⃣ 倪海厦九问\n'
        '5️⃣ 六经定位\n'
        '6️⃣ 鉴别诊断\n\n'
        '请告诉我你哪里不舒服？';
  }

  List<SymptomOption> getChiefComplaintOptions() {
    return DiagnosticRules.chiefComplaints;
  }

  List<TemperatureOption> getTemperatureQuestions() {
    return DiagnosticRules.temperaturePatterns;
  }

  List<FollowUpQuestion> getFollowUpQuestions(String meridian) {
    return DiagnosticRules.followUpQuestions[meridian] ?? [];
  }

  List<FollowUpQuestion> getTenQuestions() {
    return DiagnosticRules.tenQuestions;
  }

  // ==================== 舌诊脉诊选项 ====================

  List<String> getTongueCoatingOptions() => DiagnosticRules.tongueCoatingOptions;
  List<String> getTongueShapeOptions() => DiagnosticRules.tongueShapeOptions;
  List<String> getPulseOptions() => DiagnosticRules.pulseOptions;

  // ==================== 诊断流程 ====================

  void selectChiefComplaint(String symptomKey) {
    _selectedSymptoms.add(symptomKey);
    // 主诉症状同时写入 _answers，供合病评分使用
    _answers[symptomKey] = true;
    _stage = DiagnosticStage.temperaturePattern;
  }

  void answerTemperaturePattern(String patternKey) {
    _meridianDirection = DiagnosticRules.temperatureToMeridian[patternKey];
    _answers['temperature'] = patternKey;
    _stage = DiagnosticStage.tonguePulse;
  }

  void answerTonguePulse({
    String? tongueCoating,
    String? tongueShape,
    String? pulseType,
  }) {
    _tongueCoating = tongueCoating;
    _tongueShape = tongueShape;
    _pulseType = pulseType;

    // 将舌脉数据纳入答案并调整经络方向
    if (tongueCoating != null) {
      _answers['tongue_coating'] = tongueCoating;
      // 设置布尔标志供 _decideMeridianDirection 使用
      if (tongueCoating == '黄厚' || tongueCoating == '黄薄') {
        _answers['tongue_red_coated_yellow'] = true;
      }
      if (tongueCoating == '白厚' || tongueCoating == '薄白') {
        _answers['tongue_pale_coated_white'] = true;
      }
      _adjustMeridianByTongue('tongue_coating', tongueCoating);
    }
    if (tongueShape != null) {
      _answers['tongue_shape'] = tongueShape;
      // 设置布尔标志供 _decideMeridianDirection 使用
      if (tongueShape == '淡白') {
        _answers['tongue_pale_coated_white'] = true;
      }
      if (tongueShape == '红') {
        _answers['tongue_red_coated_yellow'] = true;
      }
      if (tongueShape == '绛紫') {
        _answers['tongue_purple'] = true;
      }
      if (tongueShape == '胖大' || tongueShape == '齿痕') {
        _answers['tongue_swollen'] = true;
      }
      _adjustMeridianByTongue('tongue_shape', tongueShape);
    }
    if (pulseType != null) {
      _answers['pulse_type'] = pulseType;
      _adjustMeridianByPulse(pulseType);
    }

    _stage = DiagnosticStage.tenQuestions;
    _tenQuestionIndex = 0;
  }

  void _adjustMeridianByTongue(String type, String value) {
    final weights = DiagnosticRules.tonguePulseWeights[type];
    if (weights == null) return;
    final weight = weights[value] ?? 0.0;
    if (weight <= 0.0) return;

    // 舌苔/舌形对经络的影响
    if (type == 'tongue_coating') {
      if (value == '白厚' || value == '灰黑') {
        // 偏寒 → 太阴/少阴
        if (_meridianDirection == '太阴/少阴') {
          _meridianDirection = weight > 0.4 ? '少阴' : '太阴';
        }
      } else if (value == '黄厚') {
        // 偏热 → 阳明
        if (_meridianDirection == '太阴/少阴') {
          _meridianDirection = '阳明';
        }
      } else if (value == '黄薄') {
        // 偏热 → 阳明/少阳
        if (_meridianDirection == '太阴/少阴') {
          _meridianDirection = '少阳';
        }
      }
    }
  }

  void _adjustMeridianByPulse(String pulse) {
    final weights = DiagnosticRules.tonguePulseWeights['pulse'];
    if (weights == null) return;
    final weight = weights[pulse] ?? 0.0;
    if (weight <= 0.3) return;

    if (pulse == '浮' || pulse == '紧') {
      // 浮脉/紧脉 → 太阳
      if (_meridianDirection == '太阴/少阴') {
        _meridianDirection = '太阳';
      }
    } else if (pulse == '洪') {
      // 洪脉 → 阳明
      if (_meridianDirection == '太阴/少阴') {
        _meridianDirection = '阳明';
      }
    } else if (pulse == '弦') {
      // 弦脉 → 少阳
      if (_meridianDirection == '太阴/少阴') {
        _meridianDirection = '少阳';
      }
    } else if (pulse == '微' || pulse == '细') {
      // 微脉/细脉 → 少阴
      if (_meridianDirection == '太阴/少阴') {
        _meridianDirection = '少阴';
      }
    } else if (pulse == '沉') {
      // 沉脉 → 里证
      if (_meridianDirection == '太阳') {
        _meridianDirection = '太阴/少阴';
      }
    }
  }

  void answerTenQuestion(String questionKey, String answer) {
    _answers[questionKey] = answer;

    // "没有此症状"跳过所有症状解析
    if (answer == '没有此症状') {
      _tenQuestionIndex++;
      if (_tenQuestionIndex >= DiagnosticRules.tenQuestions.length) {
        _decideMeridianDirection();
      }
      return;
    }

    // 特殊答案处理
    if (questionKey == 'sleep') {
      _answers['sleep_quality'] = answer;
      _answers['insomnia'] = !answer.contains('一觉到天亮');
      _answers['early_wake_1_3'] = answer.contains('1-3');
      _answers['early_wake_3_5'] = answer.contains('3-5');
    }
    if (questionKey == 'thirst') {
      _answers['thirsty'] = answer.contains('渴');
      _answers['cold_drink'] = answer.contains('冷水');
      _answers['hot_drink'] = answer.contains('热水');
      _answers['thirst_no_drink'] = answer.contains('渴但不想喝');
      _answers['xiaoke'] = answer.contains('消渴');
      _answers['thirst_strong'] = answer.contains('渴') && answer.contains('冷水');
      _answers['no_thirst'] = answer == '不渴';
      _answers['mouth_dry'] = answer.contains('口干');
    }
    if (questionKey == 'stool') {
      _answers['constipated'] = answer.contains('便秘');
      _answers['diarrhea'] = answer.contains('稀') || answer.contains('拉肚子') || answer.contains('水样');
      _answers['bloody_stool'] = answer.contains('脓血');
    }
    if (questionKey == 'urine') {
      _answers['urine_clear'] = answer.contains('清长');
      _answers['urine_difficult'] = answer.contains('不利');
      _answers['urine_nocturia'] = answer.contains('夜尿');
    }
    if (questionKey == 'temperature') {
      _answers['cold_limbs'] = answer.contains('冰冷');
      _answers['warm_limbs'] = answer.contains('温热');
      _answers['hot_palms_soles'] = answer.contains('手心脚心热');
      _answers['upper_heat_lower_cold'] = answer.contains('头热脚冷') || answer.contains('上半身热');
      _answers['chills'] = answer.contains('全身怕冷');
      _answers['no_chills'] = !answer.contains('冷');
    }
    if (questionKey == 'sweating') {
      _answers['has_sweat'] = answer.contains('出汗') || answer.contains('盗汗') || answer.contains('自汗');
      _answers['night_sweat'] = answer.contains('盗汗');
      _answers['head_sweat'] = answer.contains('头汗');
      _answers['hand_foot_sweat'] = answer.contains('手足汗');
      _answers['no_sweat'] = answer.contains('不容易出汗');
      _answers['sweating'] = answer.contains('出汗') && !answer.contains('不容易');
    }
    if (questionKey == 'energy') {
      _answers['drowsy'] = answer.contains('欲寐') || answer.contains('昏昏沉沉');
      _answers['irritable'] = answer.contains('烦躁');
      _answers['weak_speech'] = answer.contains('说话没力气');
    }
    // 注意：舌诊数据已统一由 Step 3 (answerTonguePulse) 处理，不再在此重复
    if (questionKey == 'pain') {
      _answers['headache_front'] = answer.contains('前额');
      _answers['headache_side'] = answer.contains('两侧');
      _answers['headache_back'] = answer.contains('后脑');
      _answers['chest_pain'] = answer.contains('胸胁');
      _answers['abdomen_pain_press'] = answer.contains('拒按');
      _answers['abdomen_pain_relief'] = answer.contains('喜按');
      _answers['joint_wandering'] = answer.contains('游走');
    }

    _tenQuestionIndex++;

    if (_tenQuestionIndex >= DiagnosticRules.tenQuestions.length) {
      _decideMeridianDirection();
    }
  }

  void _decideMeridianDirection() {
    if (_meridianDirection == null || _meridianDirection == '太阴/少阴') {
      // 少阴核心：但欲寐、四肢厥冷、小便清长（心肾阳虚）
      int shaoyinScore = 0;
      if (_answers['drowsy'] == true) shaoyinScore += 3;
      if (_answers['cold_limbs'] == true) shaoyinScore += 2;
      if (_answers['urine_clear'] == true) shaoyinScore += 2;
      if (_answers['palpitation'] == true) shaoyinScore += 2;
      if (_answers['weak_speech'] == true) shaoyinScore += 1;

      // 太阴核心：腹泻、舌淡苔白、腹满呕吐、食不下（脾虚寒湿）
      int taiyinScore = 0;
      if (_answers['diarrhea'] == true) taiyinScore += 3;
      if (_answers['tongue_pale_coated_white'] == true) taiyinScore += 2;
      if (_answers['tongue_swollen'] == true) taiyinScore += 2;
      if (_answers['abdomen_pain_relief'] == true) taiyinScore += 2;
      if (_answers['appetite'] == '吃不下') taiyinScore += 2;

      if (shaoyinScore > taiyinScore) {
        _meridianDirection = '少阴';
      } else if (taiyinScore > shaoyinScore) {
        _meridianDirection = '太阴';
      } else if (shaoyinScore > 0) {
        // 分数相等但有症状→默认少阴（更危急，优先处理）
        _meridianDirection = '少阴';
      } else {
        // 完全无里证症状→保持原方向（可能来自寒热辨经步骤）
        // 如果仍为null，默认少阴以防漏诊
        _meridianDirection ??= '少阴';
      }
    }

    _detectCombinedPattern();
    _stage = DiagnosticStage.meridianLocation;
  }

  // ==================== 合病检测增强 ====================

  void _detectCombinedPattern() {
    final primary = _meridianDirection;
    if (primary == null) return;

    int sunScore = 0;
    int yangmingScore = 0;
    int shaoyangScore = 0;
    int taiyinScore = 0;
    int shaoyinScore = 0;
    int jueyinScore = 0;

    // 太阳症状评分
    if (_answers['temperature'] == 'fever_chills') sunScore += 3;
    if (_answers['has_sweat'] == false) sunScore += 2;
    if (_answers['cold_limbs'] != true) sunScore += 1;
    if (_answers['headache'] == true) sunScore += 1;
    if (_answers['neck_stiff'] == true) sunScore += 1;

    // 阳明症状评分
    if (_answers['thirsty'] == true) yangmingScore += 2;
    if (_answers['constipated'] == true) yangmingScore += 3;
    if (_answers['hot_palms_soles'] == true) yangmingScore += 2;
    if (_answers['temperature'] == 'fever_thirst_no_cold') yangmingScore += 3;

    // 少阳症状评分
    if (_answers['bitter_mouth'] == true) shaoyangScore += 3;
    if (_answers['dry_throat'] == true) shaoyangScore += 2;
    if (_answers['temperature'] == 'alternating_chills_fever') shaoyangScore += 3;
    if (_answers['nausea'] == true) shaoyangScore += 1;

    // 太阴症状评分
    if (_answers['diarrhea'] == true) taiyinScore += 2;
    if (_answers['tongue_pale_coated_white'] == true) taiyinScore += 2;
    if (_answers['abdominal_pain'] == true) taiyinScore += 2;

    // 少阴症状评分
    if (_answers['drowsy'] == true) shaoyinScore += 3;
    if (_answers['cold_limbs'] == true) shaoyinScore += 2;
    if (_answers['urine_clear'] == true) shaoyinScore += 2;
    if (_answers['pulse_thin_weak'] == true) shaoyinScore += 2;

    // 厥阴症状评分
    if (_answers['upper_heat_lower_cold'] == true) jueyinScore += 3;
    if (_answers['thirst_no_drink'] == true) jueyinScore += 2;
    if (_answers['hunger_no_eat'] == true) jueyinScore += 2;

    // 规则匹配：精确合病条件
    if (primary == '太阳' && yangmingScore >= 3) {
      _combinedMeridian = '阳明';
      // 区分太阳+阳明的不同场景
      if (_answers['nausea'] == true || _answers['vomiting'] == true) {
        _combinedPatternCondition = 'sun+yangming_vomit'; // 葛根加半夏汤
      } else if (_answers['breathing'] == '喘' || _answers['chest_fullness'] == true) {
        _combinedPatternCondition = 'sun+yangming_chest_full'; // 麻黄汤
      } else if (_answers['has_sweat'] == true && yangmingScore < 5) {
        _combinedPatternCondition = 'sun+yangming_unresolved'; // 二阳并病，表证未罢，小发汗
      }
      // 默认: sun_symptoms + yangming_symptoms → 葛根汤
    } else if (primary == '太阳' && shaoyangScore >= 2) {
      _combinedMeridian = '少阳';
      // 区分太阳+少阳的不同场景
      if (_answers['diarrhea'] == true) {
        _combinedPatternCondition = 'sun+shaoyang_diarrhea'; // 黄芩汤
      } else if (_answers['nausea'] == true || _answers['vomiting'] == true) {
        _combinedPatternCondition = 'sun+shaoyang_vomit'; // 黄芩加半夏生姜汤
      }
    } else if (primary == '少阳' && yangmingScore >= 3) {
      _combinedMeridian = '阳明';
      if (_answers['tidal_fever'] == true) {
        _combinedPatternCondition = 'shaoyang+yangming_tidal_fever'; // 柴胡加芒硝汤
      }
    } else if (primary == '太阴' && shaoyinScore >= 3) {
      _combinedMeridian = '少阴';
    } else if (primary == '太阳' && yangmingScore >= 2 && shaoyangScore >= 2) {
      _combinedMeridian = '阳明少阳'; // 三阳并病
      if (_answers['drowsy'] == true && _answers['has_sweat'] == true) {
        _combinedPatternCondition = 'three_yang_sleep'; // 三阳合病，目合则汗
      }
    } else if (primary == '阳明' && shaoyinScore >= 3) {
      _combinedMeridian = '少阴';
      _combinedPatternCondition = 'yangming+shaoyin_urgent'; // 大承气汤急下
    } else if (primary == '厥阴' && shaoyangScore >= 2) {
      _combinedMeridian = '少阳';
      _combinedPatternCondition = 'jueyin+shaoyang'; // 乌梅丸
    } else if (primary == '少阳' && jueyinScore >= 2) {
      _combinedMeridian = '厥阴';
      _combinedPatternCondition = 'jueyin+shaoyang';
    }
  }

  void answerFollowUp(String questionKey, String answer) {
    _answers[questionKey] = answer;
    // "没有此症状"不写入 _selectedSymptoms，避免干扰诊断
    if (answer != '没有此症状') {
      _selectedSymptoms.add(answer);
    }
  }

  // ==================== 症状权重计算 ====================

  double _calculateConfidence(String meridian) {
    double weight = 0.0;
    int count = 0;

    for (final entry in _answers.entries) {
      if (DiagnosticRules.symptomWeights.containsKey(entry.key)) {
        final symptomWeight = DiagnosticRules.symptomWeights[entry.key]!;
        if (entry.value == true) {
          weight += symptomWeight;
          count++;
        }
      }
    }

    if (count == 0) return 0.8;
    return (weight / count).clamp(0.7, 0.95);
  }

  // ==================== 鉴别诊断匹配 ====================

  DifferentialDiagnosisResult? _matchDifferential(String meridian, String pattern) {
    // 按优先级匹配鉴别诊断：先按经分类，再按证型关键词
    String? matchKey;

    if (meridian == '太阳') {
      if (pattern.contains('中风') || pattern.contains('桂枝汤')) {
        matchKey = '太阳中风_vs_伤寒';
      } else if (pattern.contains('大青龙') || pattern.contains('小青龙')) {
        matchKey = '大青龙_vs_小青龙';
      } else if (pattern.contains('麻黄') && !pattern.contains('杏甘石')) {
        matchKey = '麻黄_vs_麻杏甘石';
      }
    } else if (meridian == '阳明') {
      if (pattern.contains('白虎')) {
        // 白虎汤 vs 白虎加人参优先（津液有无），其次 vs 承气
        if (_answers['thirst_strong'] == true || _answers['heavy_sweat'] == true) {
          matchKey = '白虎_vs_白虎人参';
        } else {
          matchKey = '白虎_承气';
        }
      } else if (pattern.contains('承气') || pattern.contains('便秘')) {
        matchKey = '承气_vs_麻子仁';
      }
    } else if (meridian == '少阳') {
      if (pattern.contains('柴胡')) {
        if (_answers['constipated'] == true) {
          matchKey = '小柴胡_vs_大柴胡';
        }
      }
    } else if (meridian == '太阴') {
      if (pattern.contains('理中')) {
        if (_answers['cold_limbs'] == true || _answers['drowsy'] == true) {
          matchKey = '理中_vs_四逆';
        } else {
          matchKey = '小建中_vs_理中';
        }
      }
    } else if (meridian == '少阴') {
      if (pattern.contains('真武') || pattern.contains('水饮')) {
        if (_answers['body_pain'] == true || _answers['joint_pain'] == true) {
          matchKey = '真武_vs_附子汤';
        } else {
          matchKey = '苓桂术甘_vs_真武';
        }
      } else if (pattern.contains('四逆')) {
        if (_answers['irritability'] == true) {
          matchKey = '四逆_vs_茯苓四逆_vs_干姜附子';
        } else if (_answers['upper_heat_lower_cold'] == true) {
          matchKey = '四逆_vs_通脉四逆';
        }
      }
    } else if (meridian == '厥阴') {
      if (pattern.contains('乌梅')) {
        matchKey = '乌梅丸_vs_当归四逆';
      } else if (pattern.contains('当归四逆')) {
        matchKey = '当归四逆_vs_四逆';
      } else if (pattern.contains('吴茱萸')) {
        matchKey = '吴茱萸_vs_四逆';
      }
    }

    // 少阴通用鉴别
    if (matchKey == null && meridian == '少阴') {
      if (_answers['drowsy'] == true && _answers['cold_limbs'] == true) {
        if (_answers['irritability'] == true) {
          matchKey = '茯苓四逆_vs_干姜附子';
        }
      }
    }

    // 栀子豉 vs 黄连阿胶（失眠鉴别，跨经）
    if (matchKey == null && pattern.contains('虚烦')) {
      matchKey = '栀子豉_vs_黄连阿胶';
    }

    // 痞证鉴别（泻心汤）
    if (matchKey == null && pattern.contains('痞')) {
      matchKey = '半夏泻心_vs_生姜泻心_vs_甘草泻心';
    }

    if (matchKey == null) return null;

    final d = DiagnosticRules.differentialDiagnoses[matchKey];
    if (d == null) return null;

    return DifferentialDiagnosisResult(
      name1: d.name1, formula1: d.formula1,
      name2: d.name2, formula2: d.formula2,
      keyDifference: d.keyDifference, details: d.details,
    );
  }

  // ==================== 调护建议 ====================

  Map<String, List<String>>? _getCareAdvice(String meridian) {
    final advice = DiagnosticRules.careAdvice[meridian];
    if (advice == null) return null;
    return {
      '饮食': advice.diet,
      '休息': advice.rest,
      '艾灸': advice.moxibustion,
      '禁忌': advice.avoid,
    };
  }

  // ==================== 主诊断 ====================

  DiagnosisResult? diagnose() {
    if (_meridianDirection == null) return null;

    final meridian = _meridianDirection!;
    DiagnosisResult? result;

    switch (meridian) {
      case '太阳':
        result = _diagnoseTaiYang(_answers);
        break;
      case '阳明':
        result = _diagnoseYangMing(_answers);
        break;
      case '少阳':
        result = _diagnoseShaoYang(_answers);
        break;
      case '太阴':
        result = _diagnoseTaiYin(_answers);
        break;
      case '少阴':
        result = _diagnoseShaoYin(_answers);
        break;
      case '厥阴':
        result = _diagnoseJueYin(_answers);
        break;
      default:
        return null;
    }

    if (result == null) return null;

    // 计算权重置信度
    final weightedConfidence = _calculateConfidence(meridian);

    // 合病处理 — 根据精确条件选择方剂
    String? combinedMeridian = _combinedMeridian;
    String formulaOverride = result.formula;
    double finalConfidence = weightedConfidence;
    if (combinedMeridian != null) {
      if (combinedMeridian.contains('阳明') && combinedMeridian.contains('少阳')) {
        combinedMeridian = '阳明';
      }
      finalConfidence = weightedConfidence * 0.9;

      // 从 combinedPatterns 中查找精确匹配的合病方剂
      if (_combinedPatternCondition != null) {
        for (final cp in DiagnosticRules.combinedPatterns) {
          if (cp.condition == _combinedPatternCondition) {
            formulaOverride = cp.formula;
            break;
          }
        }
      }
    }

    // 处方生成 — 匹配方剂并检查加减法
    List<FormulaModification>? matchedMods;
    final mods = DiagnosticRules.formulaModifications[result.formula];
    if (mods != null) {
      matchedMods = [];
      for (final mod in mods) {
        final symptomValue = _answers[mod.symptom];
        if (symptomValue == true ||
            (symptomValue is String && symptomValue.isNotEmpty && symptomValue != '没有' && symptomValue != '没有此症状')) {
          matchedMods.add(mod);
        }
      }
      if (matchedMods.isEmpty) matchedMods = null;
    }

    final prescription = FormulaRepository.buildPrescription(
      formulaOverride,
      modifications: matchedMods,
    );

    // 鉴别诊断
    final differential = _matchDifferential(meridian, result.pattern);

    // 调护建议
    final careAdvice = _getCareAdvice(meridian);

    return DiagnosisResult(
      meridian: result.meridian,
      pattern: result.pattern,
      patternDetail: result.patternDetail,
      formula: formulaOverride,
      explanation: result.explanation,
      confidence: finalConfidence,
      matchedSymptoms: result.matchedSymptoms,
      combinedMeridian: combinedMeridian,
      tongueCoating: _tongueCoating,
      tongueShape: _tongueShape,
      pulseType: _pulseType,
      careAdvice: careAdvice,
      differential: differential,
      prescription: prescription,
      answers: Map.from(_answers),
    );
  }

  // ==================== 六经辨证 ====================

  DiagnosisResult _diagnoseTaiYang(Map<String, dynamic> answers) {
    final hasSweat = answers['has_sweat'] as bool?;
    final tempPattern = answers['temperature'] as String?;

    if (tempPattern == 'fever_thirst_no_cold' ||
        (answers['thirsty'] == true && answers['cold_drink'] == true)) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '温病',
        patternDetail: '发热而渴，不恶寒者，为温病。津液不足。',
        formula: '桂枝汤加葛根/栝蒌桂枝汤',
        explanation: '温病津液不足，需生津液。张仲景治温病的处方一定加上很多生津液的药。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    if (hasSweat == true) {
      bool hasNeckStiffness = _answers['neck_stiff'] == true ||
          _answers['neck'] == '僵硬';
      bool hasCough = _answers['cough'] == true ||
          (_answers['breathing'] != null &&
           _answers['breathing'] != '没有' &&
           _answers['breathing'] != '没有此症状');

      if (hasNeckStiffness) {
        return DiagnosisResult(
          meridian: '太阳',
          pattern: '中风 + 项背强几几',
          patternDetail: '太阳病，项背强几几，汗出恶风',
          formula: '桂枝加葛根汤',
          explanation: '葛根把水提升上来，靠桂枝把水排出去变成汗。葛根升水到头面颈脖。',
          confidence: 0.95,
          matchedSymptoms: _selectedSymptoms,
        );
      }

      if (hasCough) {
        return DiagnosisResult(
          meridian: '太阳',
          pattern: '中风 + 咳喘',
          patternDetail: '桂枝汤证兼咳嗽气喘',
          formula: '桂枝加厚朴杏仁汤',
          explanation: '桂枝汤证兼有咳嗽气喘，加厚朴去脾湿、杏仁去肺热化痰。',
          confidence: 0.9,
          matchedSymptoms: _selectedSymptoms,
        );
      }

      return DiagnosisResult(
        meridian: '太阳',
        pattern: '中风（桂枝汤证）',
        patternDetail: '发热，汗出，恶风，脉缓。阳浮而阴弱。',
        formula: '桂枝汤',
        explanation: '桂枝壮心阳，白芍让静脉加速回流，生姜刺激肠胃蠕动，大枣补津液，炙甘草解百毒。',
        confidence: 0.95,
        matchedSymptoms: _selectedSymptoms,
      );
    } else {
      bool hasIrritability = answers['irritable'] == true;
      if (hasIrritability) {
        return DiagnosisResult(
          meridian: '太阳',
          pattern: '表寒里热（大青龙汤证）',
          patternDetail: '太阳伤寒，脉浮紧，不汗出而烦躁。',
          formula: '大青龙汤',
          explanation: '麻黄汤加石膏。表寒里热，外面怕冷里面烦躁。脉微弱者禁用。',
          confidence: 0.9,
          matchedSymptoms: _selectedSymptoms,
        );
      }

      return DiagnosisResult(
        meridian: '太阳',
        pattern: '伤寒（麻黄汤证）',
        patternDetail: '或已发热，或未发热，必恶寒，体痛，呕逆，脉阴阳俱紧。',
        formula: '麻黄汤',
        explanation: '无汗用麻黄。麻黄开毛孔，桂枝强心阳，杏仁降肺气，甘草调和。',
        confidence: 0.95,
        matchedSymptoms: _selectedSymptoms,
      );
    }
  }

  DiagnosisResult _diagnoseYangMing(Map<String, dynamic> answers) {
    final constipated = answers['constipated'] as bool?;
    final thirsty = answers['thirsty'] as bool?;
    final abdomenPress = answers['abdomen_pain_press'] as bool?;

    if (constipated == true || abdomenPress == true) {
      bool severeConstipation = _selectedSymptoms.contains('便秘好几天不通');
      bool stomachPain = _selectedSymptoms.contains('只胃脘痛');

      if (severeConstipation) {
        return DiagnosisResult(
          meridian: '阳明',
          pattern: '腑实重证（大承气汤证）',
          patternDetail: '大便硬，腹满痛拒按，谵语，潮热。',
          formula: '大承气汤',
          explanation: '大黄芒硝攻下热结，厚朴枳实行气消满。急下存阴之峻剂。',
          confidence: 0.9,
          matchedSymptoms: _selectedSymptoms,
        );
      }

      if (stomachPain) {
        return DiagnosisResult(
          meridian: '阳明',
          pattern: '腑实轻证（调胃承气汤证）',
          patternDetail: '胃脘压痛，大便不通，心烦。',
          formula: '调胃承气汤',
          explanation: '大黄去实热，芒硝软坚，甘草缓和。腹诊下脘穴压痛。',
          confidence: 0.85,
          matchedSymptoms: _selectedSymptoms,
        );
      }

      return DiagnosisResult(
        meridian: '阳明',
        pattern: '腑实证（小承气汤证）',
        patternDetail: '腹胀谵语，大便硬。',
        formula: '小承气汤',
        explanation: '大黄攻下，厚朴行气，枳实消痞。腹诊关元穴压痛。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    if (thirsty == true && answers['cold_drink'] == true) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '经热证（白虎加人参汤证）',
        patternDetail: '身热，汗出，大渴，脉洪大。但热不寒。',
        formula: '白虎加人参汤',
        explanation: '石膏去肺热，知母除烦止渴生津，粳米保护肺泡，人参补气生津。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    return DiagnosisResult(
      meridian: '阳明',
      pattern: '阳明病',
      patternDetail: '但热不寒，身热汗出。阳明无死证。',
      formula: '白虎汤',
      explanation: '阳明病但热不寒。先辨是经热还是腑实，再选方。',
      confidence: 0.8,
      matchedSymptoms: _selectedSymptoms,
    );
  }

  DiagnosisResult _diagnoseShaoYang(Map<String, dynamic> answers) {
    final hasConstipation = answers['constipated'] as bool?;

    if (hasConstipation == true) {
      return DiagnosisResult(
        meridian: '少阳',
        pattern: '少阳阳明合病（大柴胡汤证）',
        patternDetail: '口苦咽干目眩，往来寒热，胸胁苦满，兼有便秘。',
        formula: '大柴胡汤',
        explanation: '小柴胡汤去人参甘草，加枳实芍药大黄。和解兼攻下。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    if (answers['irritable'] == true || answers['drowsy'] == true) {
      return DiagnosisResult(
        meridian: '少阳',
        pattern: '少阳病 + 虚烦（柴胡加龙骨牡蛎汤证）',
        patternDetail: '口苦咽干目眩，胸满惊烦，一身尽重。',
        formula: '柴胡加龙骨牡蛎汤',
        explanation: '柴胡和解少阳，龙骨牡蛎镇惊止烦，茯苓安神。虚人失眠很好用。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    return DiagnosisResult(
      meridian: '少阳',
      pattern: '少阳病（小柴胡汤证）',
      patternDetail: '口苦，咽干，目眩。往来寒热，胸胁苦满，心烦喜呕。',
      formula: '小柴胡汤',
      explanation: '柴胡和解少阳，黄芩清热，半夏止呕，人参补气。但见一证便是，不必悉具。',
      confidence: 0.95,
      matchedSymptoms: _selectedSymptoms,
    );
  }

  DiagnosisResult _diagnoseTaiYin(Map<String, dynamic> answers) {
    final coldLimbs = answers['cold_limbs'] as bool?;
    final hasEdema = answers['edema'] == true;
    final hasJointPain = answers['joint_pain'] == true ||
        answers['joint_wandering'] == true;

    if (hasEdema || hasJointPain) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '风水/风湿（防己黄芪汤证）',
        patternDetail: '风水或风湿，汗出恶风，身重，小便不利。',
        formula: '防己黄芪汤',
        explanation: '防己利水，黄芪固表益气，白术健脾去湿。虚人风水专用方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    if (coldLimbs == true) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '太阴虚寒（四逆汤证）',
        patternDetail: '腹满而吐，食不下，自利益甚，手足厥冷。',
        formula: '四逆汤',
        explanation: '生附子壮肾阳，干姜温脾阳，炙甘草补中。脾肾阳虚，温里回阳。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    if (_selectedSymptoms.contains('能吃但腹胀')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '脾虚气滞（厚朴生姜半夏甘草人参汤证）',
        patternDetail: '腹胀满者。脾虚气滞。',
        formula: '厚朴生姜半夏甘草人参汤',
        explanation: '厚朴行气消胀为主药，生姜半夏散水降逆，人参甘草补中。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    return DiagnosisResult(
      meridian: '太阴',
      pattern: '太阴病（理中汤证）',
      patternDetail: '腹满而吐，食不下，自利，腹痛。脾虚寒湿。',
      formula: '理中汤/理中丸',
      explanation: '人参补气，干姜温中，白术去湿，甘草调和。温中健脾。',
      confidence: 0.9,
      matchedSymptoms: _selectedSymptoms,
    );
  }

  DiagnosisResult _diagnoseShaoYin(Map<String, dynamic> answers) {
    final hasHeat = answers['irritable'] as bool?;
    final hasWaterRetention = answers['edema'] == true ||
        answers['urine_difficult'] == true;
    final bloodyStool = answers['bloody_stool'] as bool?;
    final bodyPain = answers['joint_pain'] == true ||
        answers['pain'] == '骨节疼痛' ||
        answers['body_pain'] == '全身酸痛';

    if (hasHeat == true && answers['insomnia'] == true) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '少阴热化（黄连阿胶汤证）',
        patternDetail: '心中烦，不得卧。心肾不交。',
        formula: '黄连阿胶汤',
        explanation: '黄连黄芩清心火，阿胶鸡子黄补心血，芍药敛阴。交通心肾。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    if (bloodyStool == true) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '少阴虚寒下利（桃花汤证）',
        patternDetail: '少阴病，下利不止，便脓血。',
        formula: '桃花汤',
        explanation: '赤石脂涩肠止利，干姜温中，粳米护胃。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    if (hasWaterRetention == true) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '少阴水饮（真武汤证）',
        patternDetail: '心下悸，头眩，身瞤动，小便不利。',
        formula: '真武汤',
        explanation: '附子壮肾阳，茯苓利水，白术健脾，芍药止痛，生姜散水。阳虚水泛。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    if (bodyPain == true) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '少阴经脉寒湿（附子汤证）',
        patternDetail: '身体痛，手足寒，骨节痛，脉沉。',
        formula: '附子汤',
        explanation: '附子温经散寒，茯苓利水，人参补气，白术健脾，芍药止痛。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    return DiagnosisResult(
      meridian: '少阴',
      pattern: '少阴寒化（四逆汤证）',
      patternDetail: '脉微细，但欲寐，四肢厥冷。心肾阳虚。',
      formula: '四逆汤',
      explanation: '生附子壮肾阳回阳救逆，干姜温中，炙甘草补中缓急。少阴病急温之。',
      confidence: 0.95,
      matchedSymptoms: _selectedSymptoms,
    );
  }

  DiagnosisResult _diagnoseJueYin(Map<String, dynamic> answers) {
    final hasColdLimbs = answers['cold_limbs'] as bool?;

    if (hasColdLimbs == true) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '厥阴寒凝（当归四逆汤证）',
        patternDetail: '手足厥寒，脉细欲绝。血虚寒凝。',
        formula: '当归四逆汤',
        explanation: '当归补血，桂枝细辛温经散寒，通草通血脉。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    return DiagnosisResult(
      meridian: '厥阴',
      pattern: '厥阴病（乌梅丸证）',
      patternDetail: '消渴，气上撞心，心中疼热，饥而不欲食。上热下寒。',
      formula: '乌梅丸',
      explanation: '乌梅酸收敛，细辛干姜温里，黄连黄柏清上热，附子桂枝温下寒。寒热并用。',
      confidence: 0.9,
      matchedSymptoms: _selectedSymptoms,
    );
  }

  bool get isComplete => _stage == DiagnosticStage.result;
}
