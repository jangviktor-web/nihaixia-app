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
  final String? gender;

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
    this.gender,
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
  String? _gender; // 'male' or 'female'

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
    _gender = null;
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
      gender: _gender,
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
    _gender = snapshot.gender;
  }

  // ==================== 问候与选项 ====================

  String getInitialGreeting() {
    return '你好，我是汉唐中医辨证助手。\n\n'
        '我将按照倪海厦老师的辨证方法，通过七步问诊帮你分析：\n'
        '1️⃣ 主诉症状\n'
        '2️⃣ 寒热辨经\n'
        '3️⃣ 舌诊脉诊（望诊）\n'
        '4️⃣ 倪海厦十问\n'
        '5️⃣ 六经定位\n'
        '6️⃣ 鉴别诊断\n'
        '7️⃣ 用药指导\n\n'
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

  List<FollowUpQuestion> getTenQuestions({String? defaultGender}) {
    final questions = List<FollowUpQuestion>.from(DiagnosticRules.tenQuestions);
    // 如果已设置默认性别，跳过性别问题并自动设置
    if (defaultGender != null && defaultGender.isNotEmpty) {
      _gender = defaultGender;
      questions.removeWhere((q) => q.key == 'gender');
    }
    return questions;
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
    // FIX-P0-1: fever 标志此前从未被赋值，导致依赖 fever 的方剂
    // （麻黄附子细辛汤/葛根黄芩黄连汤/麻杏薏甘汤/厚朴七物汤/栀子枳实汤）全部不可达。
    // 按寒热辨经模式直接推导（'chills_no_fever' 虽含子串 'fever' 但语义为无热，须精确匹配）。
    _answers['fever'] = patternKey == 'fever_chills' ||
        patternKey == 'fever_no_cold' ||
        patternKey == 'fever_thirst_no_cold';
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
        // 偏寒 → 太阴/少阴，但不在此处决定，留给 _decideMeridianDirection 的评分系统
        // 白厚舌苔可见于太阴（寒湿）或少阴（阳虚），需结合但欲寐、四肢厥冷等症状区分
      } else if (value == '黄厚') {
        // 偏热 → 阳明（黄厚苔是阳明腑实的典型舌象）
        if (_meridianDirection == '太阴/少阴') {
          _meridianDirection = '阳明';
        }
      } else if (value == '黄薄') {
        // 偏热 → 可能是少阳或少阴热化，不在此处决定
        // 黄薄苔可见于少阳（口苦咽干）或少阴热化（心烦不得卧），需结合其他症状区分
      }
    }
  }

  void _adjustMeridianByPulse(String pulse) {
    final weights = DiagnosticRules.tonguePulseWeights['pulse'];
    if (weights == null) return;
    final weight = weights[pulse] ?? 0.0;
    if (weight <= 0.3) return;

    if (pulse == '浮' || pulse == '紧') {
      // 浮脉/紧脉 → 太阳，但仅当温度模式为 fever_chills（表证）时
      // chills_no_fever + 浮脉 可见于太阴风水（里虚寒+表虚），不应直接设为太阳
      if (_meridianDirection == '太阴/少阴' && _answers['temperature'] == 'fever_chills') {
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
      // FIX-P0-4: 沉脉不再把已定向的太阳改写为'太阴/少阴'。
      // 原逻辑在 answerTonguePulse（十问后设脉时）执行会把方向改成'太阴/少阴'，
      // 而 diagnose() 的 switch 无该 case → 返回 null（新加汤证"发汗后身痛脉沉"直接无结果）。
      // 表寒+沉脉的少阴兼表判断已由 _decideMeridianDirection L422（fever_chills+脉沉）负责。
      // 保留：仅当方向仍为'太阴/少阴'（未定）时，沉脉不做改写。
    }
  }

  void answerTenQuestion(String questionKey, String answer) {
    // Use prefixed key for temperature ten-question to avoid overwriting the temperature pattern
    if (questionKey == 'temperature') {
      _answers['temp_question'] = answer;
    } else {
      _answers[questionKey] = answer;
    }

    // 性别问题特殊处理
    if (questionKey == 'gender') {
      _gender = answer == '男' ? 'male' : 'female';
      _tenQuestionIndex++;
      // 男性跳过月经问题
      if (_gender == 'male' &&
          _tenQuestionIndex < DiagnosticRules.tenQuestions.length &&
          DiagnosticRules.tenQuestions[_tenQuestionIndex].key == 'menstrual') {
        _tenQuestionIndex++;
      }
      if (_tenQuestionIndex >= DiagnosticRules.tenQuestions.length) {
        _decideMeridianDirection();
      }
      return;
    }

    // "没有此症状"跳过所有症状解析
    if (answer == '没有此症状') {
      _tenQuestionIndex++;
      // 男性跳过月经问题
      if (_gender == 'male' &&
          _tenQuestionIndex < DiagnosticRules.tenQuestions.length &&
          DiagnosticRules.tenQuestions[_tenQuestionIndex].key == 'menstrual') {
        _tenQuestionIndex++;
      }
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
      // FIX-P1-1: '不渴'.contains('渴')==true，原逻辑把"不渴"误判为口渴（thirsty=true），
      // 波及白虎汤/五苓散/栝蒌瞿麦丸/文蛤散等所有读 thirsty 的分支。排除 '不渴' 后修正。
      _answers['thirsty'] = answer.contains('渴') && !answer.contains('不渴');
      _answers['cold_drink'] = answer.contains('冷水');
      _answers['hot_drink'] = answer.contains('热水');
      _answers['thirst_no_drink'] = answer.contains('渴但不想喝');
      _answers['xiaoke'] = answer.contains('消渴');
      _answers['thirst_strong'] = answer.contains('渴') && answer.contains('冷水') && !answer.contains('不渴');
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
      _answers['alternating_chills'] = answer.contains('往来寒热') || answer.contains('忽冷忽热');
    }
    if (questionKey == 'sweating') {
      _answers['no_sweat'] = answer.contains('不容易出汗');
      // "不容易出汗" contains "出汗" but means NO sweat — check no_sweat first
      _answers['has_sweat'] = _answers['no_sweat'] != true &&
          (answer.contains('出汗') || answer.contains('盗汗') || answer.contains('自汗'));
      _answers['night_sweat'] = answer.contains('盗汗');
      _answers['head_sweat'] = answer.contains('头汗');
      _answers['hand_foot_sweat'] = answer.contains('手足汗');
      _answers['sweating'] = _answers['has_sweat'] == true;
      _answers['profuse_sweat'] = answer.contains('大汗');
    }
    if (questionKey == 'energy') {
      _answers['drowsy'] = answer.contains('欲寐') || answer.contains('昏昏沉沉');
      _answers['irritable'] = answer.contains('烦躁');
      _answers['weak_speech'] = answer.contains('说话没力气');
      _answers['qi_rushing'] = answer.contains('气上撞心') || answer.contains('气往上冲');
    }
    // 注意：舌诊数据已统一由 Step 3 (answerTonguePulse) 处理，不再在此重复
    if (questionKey == 'pain') {
      _answers['headache_front'] = answer.contains('前额');
      _answers['headache_side'] = answer.contains('两侧');
      _answers['headache_back'] = answer.contains('后脑');
      _answers['chest_pain'] = answer.contains('胸胁');
      _answers['abdomen_pain_press'] = answer.contains('拒按') || answer.contains('按了更痛') || answer.contains('压痛');
      _answers['abdomen_pain_relief'] = answer.contains('喜按') || answer.contains('按了舒服');
      _answers['joint_wandering'] = answer.contains('游走');
      _answers['body_joint_pain'] = answer.contains('身体痛') && answer.contains('骨节');
      _answers['body_pain'] = answer.contains('身体痛');
      _answers['joint_pain'] = answer.contains('骨节');
      _answers['epigastric_fullness'] = answer.contains('心下痞');
    }
    if (questionKey == 'menstrual') {
      _answers['menstrual_pain'] = answer.contains('痛经');
      _answers['menstrual_irregular'] = answer.contains('不调') || answer.contains('先后无定期');
      _answers['menstrual_excess'] = answer.contains('量多');
      _answers['menstrual_deficient'] = answer.contains('量少');
      _answers['sexual_deficiency'] = answer.contains('性功能减退');
    }
    // Extra symptom keys (not in ten questions but used by diagnosis methods)
    if (questionKey == 'edema') {
      _answers['edema'] = answer.contains('水肿') || answer.contains('肿');
    }
    if (questionKey == 'joint_pain') {
      _answers['joint_pain'] = answer.contains('关节') || answer.contains('骨节');
    }
    if (questionKey == 'neck') {
      _answers['neck_stiff'] = answer.contains('僵硬');
    }
    if (questionKey == 'vomiting') {
      _answers['vomiting'] = answer.contains('呕') || answer.contains('吐');
    }
    if (questionKey == 'cough') {
      _answers['cough'] = answer.contains('咳');
    }
    if (questionKey == 'headache') {
      _answers['headache'] = answer.contains('头痛');
    }

    _tenQuestionIndex++;

    // 男性跳过月经问题
    if (_gender == 'male' &&
        _tenQuestionIndex < DiagnosticRules.tenQuestions.length &&
        DiagnosticRules.tenQuestions[_tenQuestionIndex].key == 'menstrual') {
      _tenQuestionIndex++;
    }

    if (_tenQuestionIndex >= DiagnosticRules.tenQuestions.length) {
      _decideMeridianDirection();
    }
  }

  void _decideMeridianDirection() {
    // ==================== 七步走第一步：定表里 ====================
    // 快速诊断流程图（来自倪海厦六经辨证公式）
    // 有恶寒？→ 脉浮？→ 有汗？
    // 不恶寒反恶热？→ 阳明
    // 往来寒热？→ 少阳
    // 腹满+自利+不渴？→ 太阴
    // 脉微细+但欲寐？→ 少阴
    // 寒热错杂+饥不欲食？→ 厥阴

    if (_meridianDirection == null || _meridianDirection == '太阴/少阴') {
      // ===== 快速诊断流程图精确匹配 =====

      // 0. 温病 → 太阳（发热而渴，不恶寒）
      if (_answers['temperature'] == 'fever_thirst_no_cold') {
        _meridianDirection = '太阳';
      }
      // 1. 恶寒+脉浮 → 太阳（已在 temperaturePattern 阶段处理）
      // 2. 恶寒+脉沉 → 少阴兼表
      else if (_answers['temperature'] == 'fever_chills' && _pulseType == '沉') {
        _meridianDirection = '少阴';
        _answers['_shaoyin_with_table'] = true; // 标记少阴兼表证
      }
      // 3. 不恶寒反恶热 → 阳明
      else if (_answers['temperature'] == 'fever_no_cold' ||
               (_answers['thirst_strong'] == true && _answers['constipated'] == true)) {
        _meridianDirection = '阳明';
      }
      // 4. 往来寒热 → 少阳
      else if (_answers['temperature'] == 'alternating_chills_fever' ||
               _answers['bitter_mouth'] == true) {
        _meridianDirection = '少阳';
      }
      // 5. 上热下寒 → 厥阴
      else if (_answers['temperature'] == 'upper_heat_lower_cold' ||
               (_answers['upper_heat_lower_cold'] == true && _answers['xiaoke'] == true)) {
        _meridianDirection = '厥阴';
      }
      // 6. 太阴 vs 少阴 精确判断（需要评分区分）
      else if (_meridianDirection == null || _meridianDirection == '太阴/少阴') {
        // 少阴核心：但欲寐、四肢厥冷、小便清长（心肾阳虚）
        int shaoyinScore = 0;
        if (_answers['drowsy'] == true) shaoyinScore += 4;  // 但欲寐是少阴核心特征
        // FIX-P2-1: cold_limbs 权重 3→2。原 3 分使"太阴寒证兼手足不温"（如理中汤证：
        // 腹满吐利+手足不温）被拉向少阴→四逆汤，理中汤（煎剂）永远不可达。
        // 少阴核心仍由但欲寐（+4）/脉微细（+3）/小便清长（+3）决定；单纯手足冷+太阴下利
        // （taiyin diarrhea+3 > shaoyin 2）归太阴理中汤；但欲寐/脉微细则归少阴四逆汤，符合倪师
        // "厥冷过肘膝用四逆、未过肘膝用理中"的辨法。
        if (_answers['cold_limbs'] == true) shaoyinScore += 2;
        if (_answers['urine_clear'] == true) shaoyinScore += 3;  // 小便清长=肾阳虚
        if (_answers['palpitation'] == true) shaoyinScore += 2;
        if (_answers['weak_speech'] == true) shaoyinScore += 1;

        // 太阴核心：腹泻、舌淡苔白、腹满呕吐、食不下（脾虚寒湿）
        int taiyinScore = 0;
        if (_answers['diarrhea'] == true) taiyinScore += 3;
        if (_answers['tongue_pale_coated_white'] == true) taiyinScore += 2;
        if (_answers['tongue_swollen'] == true) taiyinScore += 2;
        if (_answers['abdomen_pain_relief'] == true) taiyinScore += 2;
        if (_answers['appetite'] == '吃不下') taiyinScore += 2;

        // 太阴少阴交界判断（来自六经辨证公式）
        // 口渴判断：太阴不渴（湿在中焦），少阴渴（引水自救）
        if (_answers['no_thirst'] == true) taiyinScore += 2;
        if (_answers['thirsty'] == true && _answers['hot_drink'] == true) shaoyinScore += 1;

        // 脉象判断：太阴脉缓/弱，少阴脉微/细
        if (_pulseType == '微' || _pulseType == '细') shaoyinScore += 3;
        if (_pulseType == '弱' || _pulseType == '缓') taiyinScore += 2;

        if (shaoyinScore > taiyinScore) {
          _meridianDirection = '少阴';
        } else if (taiyinScore > shaoyinScore) {
          _meridianDirection = '太阴';
        } else {
          // 分数相等或都为0→默认少阴（更危急，优先处理）
          _meridianDirection = '少阴';
        }
      }
    }

    _detectCombinedPattern();
    _detectTaiyinShaoyinBoundary(); // 太阴少阴交界判断
    // FIX-P3: 写入定稿六经方向。此前 _answers['meridian'] 从未赋值，
    // 导致跟进问诊中按 `_answers['meridian'] == 'X'` 分流的解析器
    // （太阳辨汗 L637、少阴辨寒热 L671、少阴辨身痛 L677、厥阴辨饥不欲食 L694、
    //  厥阴辨寒热 L699）全部静默失效。
    _answers['meridian'] = _meridianDirection;
    _stage = DiagnosticStage.meridianLocation;
  }

  // ==================== 太阴少阴交界判断 ====================

  void _detectTaiyinShaoyinBoundary() {
    // 来自六经辨证公式：太阴日久及肾
    // 脉由沉迟转沉微，精神由倦怠转萎靡，当从少阴论治
    if (_meridianDirection == '太阴') {
      // 检查是否有少阴转化信号
      bool hasShaoyinSigns = false;
      if (_answers['drowsy'] == true) hasShaoyinSigns = true;
      if (_pulseType == '微' || _pulseType == '细') hasShaoyinSigns = true;
      if (_answers['cold_limbs'] == true && _answers['urine_clear'] == true) hasShaoyinSigns = true;

      if (hasShaoyinSigns) {
        // 太阴已有少阴转化信号，标记传变预警
        _answers['_taiyin_to_shaoyin'] = true;
      }
    }
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
      if (_answers['irritable'] == true && _answers['has_sweat'] == false) {
        _combinedPatternCondition = 'sun+yangming_interior_heat'; // 大青龙汤（表寒里热）
      } else if (_answers['nausea'] == true || _answers['vomiting'] == true) {
        _combinedPatternCondition = 'sun+yangming_vomit'; // 葛根加半夏汤
      } else if (_answers['breathing'] == '喘' || _answers['chest_fullness'] == true) {
        _combinedPatternCondition = 'sun+yangming_chest_full'; // 麻黄汤
      } else if (_answers['has_sweat'] == true && yangmingScore < 5) {
        _combinedPatternCondition = 'sun+yangming_unresolved'; // 二阳并病，表证未罢，小发汗
      }
    } else if (primary == '太阳' && shaoyinScore >= 3) {
      // 太阳少阴两感：发热恶寒+脉沉+但欲寐
      _combinedMeridian = '少阴';
      _combinedPatternCondition = 'sun+shaoyin_two_cold'; // 麻黄附子细辛汤
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
    } else if (primary == '少阳' && taiyinScore >= 3) {
      // 少阳太阴合病：往来寒热+腹满便溏食不下
      _combinedMeridian = '太阴';
      _combinedPatternCondition = 'shaoyang+taiyin'; // 柴胡桂枝干姜汤
    } else if (primary == '太阳' && taiyinScore >= 3) {
      // 太阳太阴并病：里虚寒+表证未罢
      _combinedMeridian = '太阴';
      _combinedPatternCondition = 'sun+taiyin'; // 桂枝人参汤
    } else if (primary == '太阳' && yangmingScore >= 3 && _answers['diarrhea'] == true) {
      // 太阳阳明合病下利热：下利臭秽+高热
      _combinedMeridian = '阳明';
      _combinedPatternCondition = 'sun+yangming_diarrhea_heat'; // 葛根芩连汤
    }
  }

  void answerFollowUp(String questionKey, String answer) {
    _answers[questionKey] = answer;
    // "没有此症状"不写入 _selectedSymptoms，避免干扰诊断
    if (answer != '没有此症状') {
      _selectedSymptoms.add(answer);
    }
    // 跟进问诊派生布尔标志（六经辨证公式优化版）
    if (questionKey == 'throat') {
      _answers['sore_throat'] = answer.contains('痛');
      _answers['throat_ulcer'] = answer.contains('生疮');
      _answers['difficulty_speak'] = answer.contains('不能') && answer.contains('说话');
      _answers['throat_pus'] = answer.contains('化脓');
    }
    if (questionKey == 'sputum') {
      _answers['bloody_sputum'] = answer.contains('脓血');
    }
    if (questionKey == 'treatment_history') {
      _answers['history_mistreatment'] = answer.contains('误下') || answer.contains('被误下');
    }
    if (questionKey == 'diarrhea') {
      _answers['severe_diarrhea'] = answer.contains('清谷') || answer.contains('完谷不化');
      _answers['bloody_stool'] = answer.contains('脓血');
    }
    // 太阳跟进：辨桂枝/麻黄/葛根汤
    if (questionKey == 'sweating' && _answers['meridian'] == '太阳') {
      _answers['has_sweat'] = answer.contains('有汗');
      _answers['no_sweat'] = answer.contains('没汗');
      _answers['profuse_sweat'] = answer.contains('汗出不止');
    }
    // 太阳跟进：辨喘证
    if (questionKey == 'breathing') {
      _answers['cough'] = answer.contains('咳嗽');
      _answers['asthma'] = answer.contains('气喘') || answer.contains('喘');
      _answers['phlegm_cold'] = answer.contains('白痰');
      _answers['phlegm_hot'] = answer.contains('黄痰');
    }
    // 阳明跟进：辨谵语
    if (questionKey == 'speech') {
      _answers['delirium'] = answer.contains('胡话') || answer.contains('谵语');
      _answers['restlessness'] = answer.contains('烦躁');
      _answers['chest_discomfort'] = answer.contains('懊憹');
    }
    // 阳明跟进：辨潮热
    if (questionKey == 'tidal_fever') {
      _answers['tidal_fever'] = answer.contains('潮热');
      _answers['jaundice'] = answer.contains('身黄');
    }
    // 少阳跟进：辨口苦/咽干/目眩
    if (questionKey == 'bitter_mouth') {
      _answers['bitter_mouth'] = answer.contains('苦');
      _answers['shaoyang_triad'] = answer.contains('口苦') && answer.contains('咽干') && answer.contains('目眩');
    }
    // 少阴跟进：辨但欲寐
    if (questionKey == 'spirit') {
      _answers['drowsy'] = answer.contains('但欲寐') || answer.contains('昏昏沉沉');
      _answers['day_night_different'] = answer.contains('昼日烦躁');
    }
    // 少阴跟进：辨寒化/热化
    if (questionKey == 'extremities' && _answers['meridian'] == '少阴') {
      _answers['cold_limbs'] = answer.contains('冰冷');
      _answers['hot_limbs'] = answer.contains('手脚心热');
      _answers['hand_foot_cold_pulse_fine'] = answer.contains('脉细欲绝');
    }
    // 少阴跟进：辨身痛证
    if (questionKey == 'pain' && _answers['meridian'] == '少阴') {
      _answers['body_joint_pain'] = answer.contains('身体痛') && answer.contains('骨节');
      _answers['body_pain'] = answer.contains('身体痛');
      _answers['joint_pain'] = answer.contains('骨节');
      _answers['heavy_limbs_pain'] = answer.contains('四肢沉重');
    }
    // 少阴跟进：辨少阴兼表
    if (questionKey == 'table') {
      _answers['shaoyin_with_table'] = answer.contains('发热') || answer.contains('反发热');
    }
    // 厥阴跟进：辨气上撞心
    if (questionKey == 'chest_sensation') {
      _answers['qi_rushing'] = answer.contains('气上撞心');
      _answers['heart_heat'] = answer.contains('心中疼热');
      _answers['vomit_frogs'] = answer.contains('吐涎沫');
    }
    // 厥阴跟进：辨饥不欲食
    if (questionKey == 'appetite' && _answers['meridian'] == '厥阴') {
      _answers['hungry_no_eat'] = answer.contains('饿但不想吃');
      _answers['vomit_on_eat'] = answer.contains('食谷欲呕');
    }
    // 厥阴跟进：辨寒热错杂
    if (questionKey == 'extremities' && _answers['meridian'] == '厥阴') {
      _answers['alternating_hot_cold'] = answer.contains('时冷时热');
      _answers['hand_foot_cold_pulse_fine'] = answer.contains('脉细欲绝');
    }
  }

  // ==================== 症状权重计算 ====================

  double _calculateConfidence(String meridian) {
    int count = 0;
    for (final entry in _answers.entries) {
      if (DiagnosticRules.symptomWeights.containsKey(entry.key) &&
          entry.value == true) {
        count++;
      }
    }
    if (count == 0) return 0.4;
    // P1-2: 真置信度——基于命中关键症状数，保留区分度（不再堆在 0.7~0.95）
    return (0.5 + 0.09 * count).clamp(0.5, 0.97);
  }

  // ==================== P2: 相似度兜底 + 数据表提示 ====================

  /// P2-2: 按用户关键症状与方剂 keywords/indication 重叠度打分，返回 Top-K
  List<(String, int)> getSimilarityRanking({int topK = 5}) {
    final formulas = FormulaRepository.getAll();
    final queryTerms = _selectedSymptoms
        .where((s) => s.isNotEmpty && s != '没有此症状')
        .toList();
    if (queryTerms.isEmpty) return <(String, int)>[];

    final scored = <(String, int)>[];
    for (final f in formulas) {
      int score = 0;
      final haystack = <String>[...f.keywords, f.indication, f.name, f.alias];
      for (final term in queryTerms) {
        for (final k in haystack) {
          if (k.contains(term) || term.contains(k)) score++;
        }
      }
      if (score > 0) scored.add((f.name, score));
    }
    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return scored.take(topK).toList();
  }

  /// P2-1: 数据表直接提示（症状短语 → 方剂）
  String? suggestByTable() {
    for (final s in _selectedSymptoms) {
      for (final entry in DiagnosticRules.symptomFormulaHints.entries) {
        if (s.contains(entry.key) || entry.key.contains(s)) {
          return entry.value;
        }
      }
    }
    return null;
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

  // ==================== P0-2: 脉舌矛盾检测（以舌为准原则） ====================

  String? _detectPulseTongueContradiction() {
    if (_pulseType == null || _tongueCoating == null && _tongueShape == null) return null;

    // 核心原则：脉舌矛盾时以舌为准——舌象反映脏腑本质，脉象受干扰因素多
    String? warning;
    String? suggestion;

    // 数脉+淡白舌 → 真寒假热（以舌为准→寒）
    if (_pulseType == '数' && (_tongueShape == '淡白' || _tongueShape == '淡红')) {
      warning = '⚠️ 脉数（热象）但舌淡白（虚寒），脉舌矛盾';
      suggestion = '以舌为准→真寒假热可能。查：渴喜热饮？小便清长？四肢厥冷？按之脉无力？';
    }
    // 迟脉+红舌 → 真热假寒（以舌为准→热）
    else if (_pulseType == '迟' && (_tongueShape == '红' || _tongueShape == '绛紫')) {
      warning = '⚠️ 脉迟（寒象）但舌红（热象），脉舌矛盾';
      suggestion = '以舌为准→真热假寒可能。查：胸腹热？渴喜冷饮？小便黄赤？';
    }
    // 浮脉+厚腻苔 → 里证为主（以舌为准→里）
    else if ((_pulseType == '浮') && (_tongueCoating == '白厚' || _tongueCoating == '黄厚')) {
      warning = '⚠️ 脉浮（表证）但苔厚腻（里证），脉舌矛盾';
      suggestion = '以舌为准→里证为主，脉浮为假象。可能为真寒假热。';
    }
    // 沉脉+薄白苔 → 可能表证未解
    else if (_pulseType == '沉' && _tongueCoating == '薄白') {
      warning = '⚠️ 脉沉（里证）但苔薄白（正常/表证），脉舌不一致';
      suggestion = '可能为里证初起或表证已解，需结合问诊判断。';
    }
    // 弦脉+淡白苔 → 少阳兼太阴
    else if (_pulseType == '弦' && (_tongueShape == '淡白' || _tongueShape == '淡红') && _tongueCoating == '白厚') {
      warning = '⚠️ 脉弦（少阳）但舌淡苔白（太阴虚寒），寒热矛盾';
      suggestion = '以舌为准→少阳兼太阴虚。柴胡桂枝干姜汤证可能。';
    }

    if (warning != null) {
      return '$warning\n💡 $suggestion';
    }

    // 检查预设的矛盾组合
    final key = '${_pulseType}脉+${_tongueCoating}苔';
    final contradiction = DiagnosticRules.pulseTongueContradictions[key];
    if (contradiction != null) {
      return '${contradiction['warning']}\n💡 ${contradiction['suggestion']}';
    }

    return null;
  }

  // ==================== P1-4: 组合脉象检测 ====================

  PulseCombination? _detectPulseCombination() {
    if (_pulseType == null) return null;
    for (final pc in DiagnosticRules.pulseCombinations) {
      if (_pulseType == pc.pulse1 || _pulseType == pc.pulse2) {
        // 如果脉象匹配组合中的任一脉，返回该组合
        if (_pulseType == pc.pulse1) return pc;
      }
    }
    return null;
  }

  // ==================== P1-3: 瘀血五法检测 ====================

  List<BloodStasisSign>? _detectBloodStasis() {
    List<BloodStasisSign> signs = [];
    bool hasBloodStasis = false;

    // 望诊：舌绛紫
    if (_tongueShape == '绛紫') hasBloodStasis = true;
    // 问诊：疼痛固定/夜间加重（从 answers 中检测）
    if (_answers['pain'] == '骨节疼痛' || _answers['pain'] == '全身酸痛') {
      // 骨节疼痛固定→瘀血可能
    }
    // 切诊：脉涩
    if (_pulseType == '涩') hasBloodStasis = true;

    if (hasBloodStasis) {
      signs = List.from(DiagnosticRules.bloodStasisFiveMethods);
    }
    return signs.isEmpty ? null : signs;
  }

  // ==================== P0-5: 汗法禁忌检测 ====================

  List<SweatingContraindication>? _detectSweatingContraindications() {
    List<SweatingContraindication> result = [];
    final meridian = _meridianDirection;

    // 根据当前六经方向检测汗法禁忌
    if (meridian == '阳明' || meridian == '少阳' ||
        meridian == '太阴' || meridian == '少阴' || meridian == '厥阴') {
      // 非太阳经，汗法一般不适用
      for (final sc in DiagnosticRules.sweatingContraindications) {
        if (sc.condition.contains(meridian!) || sc.condition.contains('津液')) {
          result.add(sc);
        }
      }
    }

    // 通用禁忌：咽喉干燥、淋家、疮家等
    if (_answers['throat'] == '咽干') {
      result.add(DiagnosticRules.sweatingContraindications[5]); // 咽喉干燥
    }

    return result.isEmpty ? null : result;
  }

  // ==================== P1-7: 传经判断 ====================

  MeridianTransmission? _detectTransmission() {
    final meridian = _meridianDirection;
    if (meridian == null) return null;

    // 检测是否有传经信号
    for (final t in DiagnosticRules.meridianTransmissions) {
      if (t.from == meridian) {
        // 检查是否有传经的症状信号
        if (t.to == '阳明' && (_answers['thirst_strong'] == true || _answers['constipated'] == true)) {
          return t;
        }
        if (t.to == '少阳' && (_answers['mouth_dry'] == true || _answers['vomiting'] == true)) {
          return t;
        }
        if (t.to == '少阴' && (_answers['drowsy'] == true || _answers['cold_limbs'] == true)) {
          if (meridian == '太阳' || meridian == '太阴') return t;
        }
        if (t.to == '厥阴' && (_answers['xiaoke'] == true || _answers['upper_heat_lower_cold'] == true)) {
          if (meridian == '少阴') return t;
        }
      }
    }
    return null;
  }

  // ==================== P0-1: 真寒假热/真热假寒检测 ====================

  TrueFalseHeatCold? _detectTrueFalseHeatCold() {
    final meridian = _meridianDirection;
    if (meridian == null) return null;

    // 真寒假热检测
    if (meridian == '少阴' || meridian == '太阴') {
      final hasUpperHeat = _answers['upper_heat_lower_cold'] == true ||
          _answers['thirst_strong'] == true;
      final hasLowerCold = _answers['cold_limbs'] == true ||
          _answers['drowsy'] == true ||
          _answers['urine_clear'] == true;
      if (hasUpperHeat && hasLowerCold) {
        return DiagnosticRules.trueFalseHeatColdData['真寒假热'];
      }
    }

    // 真热假寒检测
    if (meridian == '阳明' || meridian == '少阳') {
      final hasColdSigns = _answers['cold_limbs'] == true;
      final hasHeatSigns = _answers['thirst_strong'] == true ||
          _answers['constipated'] == true ||
          _pulseType == '洪' || _pulseType == '数';
      if (hasColdSigns && hasHeatSigns) {
        return DiagnosticRules.trueFalseHeatColdData['真热假寒'];
      }
    }

    return null;
  }

  // ==================== 用药铁律检测 ====================

  List<MedicationRule>? _detectMedicationRules() {
    final meridian = _meridianDirection;
    if (meridian == null) return null;

    List<MedicationRule> result = [];
    for (final rule in DiagnosticRules.medicationRules) {
      if (rule.condition.contains(meridian)) {
        result.add(rule);
      }
    }
    return result.isEmpty ? null : result;
  }

  // ==================== 主诊断 ====================

  DiagnosisResult? diagnose() {
    if (_meridianDirection == null) return null;

    final meridian = _meridianDirection!;
    DiagnosisResult? result;

    // 优先检查杂病/跨经方剂（五苓散、痞证、胸痹、蓄血等）
    result = _diagnoseMiscellaneous(_answers);
    if (result != null) {
      final weightedConfidence = _calculateConfidence(result.meridian);
      return DiagnosisResult(
        meridian: result.meridian,
        pattern: result.pattern,
        patternDetail: result.patternDetail,
        formula: result.formula,
        explanation: result.explanation,
        confidence: weightedConfidence,
        matchedSymptoms: result.matchedSymptoms,
        prescription: result.prescription,
        transmission: result.transmission,
        transmissionWarning: result.transmissionWarning,
      );
    }

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

    // 经方两大补虚方优先规则（来自六经辨证公式）
    // 遇到桂枝汤证/麻黄汤证时，若兼表阳虚，先用小建中汤
    // 遇到脉结代，先用炙甘草汤补足里阴，再治其他
    if (meridian == '太阳' && result.formula == '桂枝汤') {
      if (_answers['weak_speech'] == true || _answers['palpitation'] == true) {
        formulaOverride = '小建中汤';
        result = DiagnosisResult(
          meridian: result.meridian,
          pattern: '太阳表虚兼里虚（小建中汤证）',
          patternDetail: '桂枝汤证兼表阳虚，腹中痛，喜按。虚劳里急。',
          formula: '小建中汤',
          explanation: '经方两大补虚方之一。小建中汤=桂枝汤倍芍药加饴糖。表阳虚兼太阴脾虚，先补后解表。',
          confidence: 0.85,
          matchedSymptoms: _selectedSymptoms,
        );
      }
    }
    if (result.formula == '炙甘草汤' || (_pulseType == '结' || _pulseType == '代')) {
      if (_answers['palpitation'] == true) {
        formulaOverride = '炙甘草汤';
        result = DiagnosisResult(
          meridian: result.meridian,
          pattern: '阴阳两虚（炙甘草汤证）',
          patternDetail: '脉结代，心动悸。阴阳两虚。',
          formula: '炙甘草汤',
          explanation: '经方两大补虚方之一。炙甘草汤补益气阴、通阳复脉。脉结代心动悸主方。',
          confidence: 0.9,
          matchedSymptoms: _selectedSymptoms,
        );
      }
    }

    // 传变预警（来自六经辨证公式）
    String? transmissionWarning;
    if (meridian == '太阳' && (_answers['bitter_mouth'] == true || _answers['dry_throat'] == true)) {
      transmissionWarning = '⚠️ 太阳→少阳传经信号：口苦咽干，注意是否传入少阳';
    } else if (meridian == '太阳' && (_answers['thirst_strong'] == true || _answers['constipated'] == true)) {
      transmissionWarning = '⚠️ 太阳→阳明传经信号：大渴便秘，注意是否传入阳明';
    } else if (meridian == '太阴' && (_answers['drowsy'] == true || _answers['urine_clear'] == true)) {
      transmissionWarning = '⚠️ 太阴→少阴传经信号：但欲寐、小便清长，当从少阴论治';
    } else if (meridian == '少阴' && (_answers['upper_heat_lower_cold'] == true || _answers['xiaoke'] == true)) {
      transmissionWarning = '⚠️ 少阴→厥阴传经信号：寒热错杂，注意厥阴转化';
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

    // P0-2: 脉舌矛盾检测
    final contradiction = _detectPulseTongueContradiction();
    // P0-1: 真寒假热/真热假寒
    final trueFalseHC = _detectTrueFalseHeatCold();
    // P0-4: 用药铁律
    final medRules = _detectMedicationRules();
    // P0-5: 汗法禁忌
    final sweatContra = _detectSweatingContraindications();
    // P1-3: 瘀血五法
    final bloodStasis = _detectBloodStasis();
    // P1-4: 组合脉象
    final pulseCombo = _detectPulseCombination();
    // P1-7: 传经判断
    final transmission = _detectTransmission();

    // P0-2: 证据不足 → 建议面诊，避免静默退化为峻烈方
    final matchedSymptomCount = _answers.entries
        .where((e) =>
            e.value == true && DiagnosticRules.symptomWeights.containsKey(e.key))
        .length;
    if (matchedSymptomCount < 2) {
      return DiagnosisResult(
        meridian: meridian,
        pattern: '辨证依据不足',
        formula: '',
        explanation: '当前提供的信息较少，难以确定方证。为避免误治，建议线下就诊，'
            '由执业中医师四诊合参后辨证处方。',
        confidence: finalConfidence,
        recommendConsult: true,
        answers: Map.from(_answers),
      );
    }

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
      // P0+P1 新增字段
      pulseTongueContradiction: contradiction,
      trueFalseHeatCold: trueFalseHC,
      medicationRules: medRules,
      sweatingContraindications: sweatContra,
      bloodStasisSigns: bloodStasis,
      pulseCombination: pulseCombo,
      transmission: transmission,
      transmissionWarning: transmissionWarning,
    );
  }

  // ==================== 六经辨证 ====================

  DiagnosisResult _diagnoseTaiYang(Map<String, dynamic> answers) {
    final hasSweat = answers['has_sweat'] as bool?;
    final tempPattern = answers['temperature'] as String?;
    final hasAbdomenPain = answers['abdomen_pain_press'] == true ||
        answers['abdomen_pain_relief'] == true ||
        _selectedSymptoms.contains('腹痛') ||
        _selectedSymptoms.contains('腹满');

    // 太阳误下转太阴系列（腹满时痛/实痛）
    // 需要：太阳病史 + 误下 + 腹痛
    final hasMistreatmentHistory = _answers['history_mistreatment'] == true ||
        _selectedSymptoms.contains('误下') ||
        _selectedSymptoms.contains('被下');
    if (hasMistreatmentHistory && hasAbdomenPain) {
      final hasPressPain = answers['abdomen_pain_press'] == true;
      // 桂枝加大黄汤：腹满实痛（拒按）
      if (hasPressPain) {
        return DiagnosisResult(
          meridian: '太阴',
          pattern: '太阳转太阴实痛（桂枝加大黄汤证）',
          patternDetail: '太阳病误下，腹满实痛，拒按。',
          formula: '桂枝加大黄汤',
          explanation: '桂枝汤调和营卫，重用芍药缓急止痛，加大黄泻下实邪。',
          confidence: 0.85,
          matchedSymptoms: _selectedSymptoms,
        );
      }

      // 桂枝加芍药汤：腹满时痛（喜按）
      final hasReliefPain = answers['abdomen_pain_relief'] == true;
      if (hasReliefPain) {
        return DiagnosisResult(
          meridian: '太阴',
          pattern: '太阳转太阴时痛（桂枝加芍药汤证）',
          patternDetail: '太阳病误下，腹满时痛，喜按。',
          formula: '桂枝加芍药汤',
          explanation: '桂枝汤调和营卫，重用芍药缓急止痛。',
          confidence: 0.85,
          matchedSymptoms: _selectedSymptoms,
        );
      }
    }

    // ========== 太阳经新增方剂触发逻辑 ==========

    // 小青龙汤：表寒里寒，水饮咳喘（无汗+咳喘+痰白清稀/心下有水气）
    final hasCoughAny = answers['cough'] == true ||
        (_answers['breathing'] != null &&
         _answers['breathing'] != '没有' &&
         _answers['breathing'] != '没有此症状');
    final hasPhlegmCold = _answers['breathing'] == '咳嗽有白痰' ||
        _selectedSymptoms.contains('痰白') ||
        _selectedSymptoms.contains('清稀痰') ||
        _selectedSymptoms.contains('心下有水气');
    if (hasSweat == false && hasCoughAny && hasPhlegmCold) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '表寒里寒水饮（小青龙汤证）',
        patternDetail: '伤寒表不解，心下有水气，干呕发热而咳。',
        formula: '小青龙汤',
        explanation: '麻黄桂枝解表，干姜细辛温肺化饮，半夏燥湿，五味子敛肺，芍药甘草调和。表寒里饮双解。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 桂枝甘草汤：发汗过多心阳虚，心悸叉手自冒心
    final hasPalpitations = answers['palpitations'] == true ||
        _selectedSymptoms.contains('心悸') ||
        _selectedSymptoms.contains('叉手自冒心') ||
        _selectedSymptoms.contains('心下悸');
    if (hasPalpitations && hasSweat == true &&
        _pulseType != null && (_pulseType == '虚' || _pulseType == '大' || _pulseType == '缓')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '发汗过多心阳虚（桂枝甘草汤证）',
        patternDetail: '发汗过多，其人叉手自冒心，心下悸，欲得按。',
        formula: '桂枝甘草汤',
        explanation: '桂枝强心阳，炙甘草补中缓急。心阳受损，悸而喜按。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 桂枝加龙骨牡蛎汤：虚劳失精，目眩发落
    final hasDizziness = answers['headache_back'] == true ||
        _selectedSymptoms.contains('目眩') ||
        _selectedSymptoms.contains('头晕');
    final hasHairLoss = _selectedSymptoms.contains('发落') ||
        _selectedSymptoms.contains('脱发');
    final hasInsomniaOrDreams = answers['insomnia'] == true ||
        _selectedSymptoms.contains('多梦') ||
        _selectedSymptoms.contains('失精');
    if (hasSweat == true && hasDizziness && (hasHairLoss || hasInsomniaOrDreams)) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '虚劳失精（桂枝加龙骨牡蛎汤证）',
        patternDetail: '虚劳里急，悸衄腹中痛，梦失精，四肢酸疼，手足烦热，咽干口燥。',
        formula: '桂枝加龙骨牡蛎汤',
        explanation: '桂枝汤调和营卫，加龙骨牡蛎潜阳固精。虚劳失精主方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 桂枝去芍药汤：太阳病误下后脉促胸满
    final hasChestFullness = answers['chest_pain'] == true ||
        _selectedSymptoms.contains('胸满') ||
        _selectedSymptoms.contains('胸闷');
    final hasNeckStiffnessCheck = _answers['neck_stiff'] == true ||
        (_answers['neck'] is String && (_answers['neck'] as String).contains('僵硬'));
    if (hasSweat == true && hasChestFullness && !hasNeckStiffnessCheck && !hasCoughAny) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '太阳胸满（桂枝去芍药汤证）',
        patternDetail: '太阳病误下后，脉促胸满。胸阳受损。',
        formula: '桂枝去芍药汤',
        explanation: '桂枝汤去芍药。芍药酸寒不利于胸阳宣通，去之以通胸阳。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 桂枝新加汤：发汗后身痛脉沉迟
    final hasBodyPainNew = answers['body_pain'] == true ||
        _selectedSymptoms.contains('身疼痛') ||
        _selectedSymptoms.contains('全身酸痛');
    if (hasBodyPainNew && _pulseType == '沉' || _pulseType == '迟') {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '发汗后身痛（桂枝新加汤证）',
        patternDetail: '发汗后，身疼痛，脉沉迟。气营两伤。',
        formula: '新加汤',
        explanation: '桂枝汤加人参生姜芍药。发汗后气营不足，身痛脉沉迟。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 栝蒌桂枝汤：痉病兼津液不足（项背强几几+发热+津液不足）
    final hasSpasm = _selectedSymptoms.contains('痉') ||
        _selectedSymptoms.contains('抽搐') ||
        (_selectedSymptoms.contains('项背强') && answers['thirsty'] == true);
    if (hasSpasm && hasSweat == true) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '痉病津亏（栝蒌桂枝汤证）',
        patternDetail: '太阳病，其证备，身体强，几几然，脉反沉迟。痉病兼津液不足。',
        formula: '栝蒌桂枝汤',
        explanation: '栝蒌根生津润燥，桂枝汤调和营卫。痉病津液不足者。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 桃核承气汤：膀胱蓄血轻证（少腹急结+如狂）
    final hasLowerAbdomen = _selectedSymptoms.contains('少腹急结') ||
        _selectedSymptoms.contains('小腹痛') ||
        answers['lower_abdomen_pain'] == true;
    final hasManic = _selectedSymptoms.contains('如狂') ||
        _selectedSymptoms.contains('发狂') ||
        answers['irritable'] == true;
    if (hasLowerAbdomen && hasManic && hasSweat == false) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '膀胱蓄血轻证（桃核承气汤证）',
        patternDetail: '太阳病不解，热结膀胱，其人如狂，少腹急结。',
        formula: '桃核承气汤',
        explanation: '桃仁活血化瘀，大黄泻下逐瘀，芒硝软坚，桂枝通经，甘草调和。蓄血轻证主方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 温病（发热而渴，不恶寒）
    if (tempPattern == 'fever_thirst_no_cold' ||
        (answers['thirsty'] == true && answers['cold_drink'] == true)) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '温病',
        patternDetail: '发热而渴，不恶寒者，为温病。津液不足。',
        formula: '桂枝加葛根汤/栝蒌桂枝汤',
        explanation: '温病津液不足，需生津液。张仲景治温病的处方一定加上很多生津液的药。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    if (hasSweat == true) {
      bool hasNeckStiffness = _answers['neck_stiff'] == true ||
          (_answers['neck'] is String && (_answers['neck'] as String).contains('僵硬'));
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

    // ========== 阳明经新增方剂触发逻辑 ==========

    // 大黄黄连泻心汤：热痞，心下痞按之濡
    final hasEpigastric = _selectedSymptoms.contains('心下痞') ||
        _selectedSymptoms.contains('胃脘痞满');
    if (hasEpigastric && abdomenPress != true) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '热痞（大黄黄连泻心汤证）',
        patternDetail: '心下痞，按之濡。热痞。',
        formula: '大黄黄连泻心汤',
        explanation: '大黄泻热，黄连清心胃之火。以麻沸汤渍之，取气不取味。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 栀子厚朴枳实汤：心烦腹满卧起不安
    final hasRestlessness = _selectedSymptoms.contains('卧起不安') ||
        (_answers['irritable'] == true && _selectedSymptoms.contains('腹满'));
    if (hasRestlessness) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '心烦腹满（栀子厚朴枳实汤证）',
        patternDetail: '心烦腹满，卧起不安。',
        formula: '栀子厚朴枳实汤',
        explanation: '栀子清心除烦，厚朴行气消满，枳实破气消痞。心烦腹满两解。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 栀子大黄汤：酒黄疸心中懊憹
    final hasAlcoholJaundice = _selectedSymptoms.contains('酒黄疸') ||
        _selectedSymptoms.contains('心中懊憹') ||
        (_selectedSymptoms.contains('身黄') && _selectedSymptoms.contains('心中热'));
    if (hasAlcoholJaundice) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '酒黄疸（栀子大黄汤证）',
        patternDetail: '心中懊憹而热，不能食，时欲吐。酒疸。',
        formula: '栀子大黄汤',
        explanation: '栀子清热利湿，大黄泻下除积，枳实行气，香豉宣郁。酒疸主方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 厚朴三物汤：腹痛便秘偏于行气（腹胀痛+便秘，重在行气除满）
    final hasAbdomenDistension = _selectedSymptoms.contains('腹胀痛') ||
        _selectedSymptoms.contains('腹满痛');
    if (hasAbdomenDistension && constipated == true && abdomenPress == true) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '气滞腹满（厚朴三物汤证）',
        patternDetail: '痛而闭。腹胀痛，大便不通。偏于行气除满。',
        formula: '厚朴三物汤',
        explanation: '厚朴为主药行气消满，枳实破气，大黄泻下。与小承气汤药同量异。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 芍药甘草汤：脚挛急、腿抽筋（去杖汤）
    final hasLegCramp = _selectedSymptoms.contains('脚挛急') ||
        _selectedSymptoms.contains('腿抽筋') ||
        _selectedSymptoms.contains('下肢拘挛');
    if (hasLegCramp) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '筋脉拘急（芍药甘草汤证）',
        patternDetail: '脚挛急。筋脉拘急。',
        formula: '芍药甘草汤',
        explanation: '芍药柔肝缓急，甘草补中缓急。酸甘化阴，缓急止痛。又名去杖汤。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 芍药甘草附子汤：发汗后虚证恶寒
    final hasPostSweatChills = _selectedSymptoms.contains('恶寒') &&
        (_selectedSymptoms.contains('发汗后') || _selectedSymptoms.contains('汗后'));
    if (hasPostSweatChills) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '发汗后虚寒（芍药甘草附子汤证）',
        patternDetail: '发汗后，病不解，反恶寒者。阴阳两虚。',
        formula: '芍药甘草附子汤',
        explanation: '附子温阳，芍药甘草养阴缓急。发汗后阴阳两虚恶寒者。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 白虎加桂枝汤：温疟骨节疼烦
    final hasMalaria = _selectedSymptoms.contains('温疟') ||
        _selectedSymptoms.contains('骨节疼烦');
    if (hasMalaria) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '温疟（白虎加桂枝汤证）',
        patternDetail: '身热，骨节疼烦，时呕。温疟。',
        formula: '白虎加桂枝汤',
        explanation: '白虎汤清热，桂枝解表通经。温疟身热骨节疼烦者。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 猪苓汤：阴虚水热互结（心烦不得眠+小便不利+发热）
    final hasInsomnia = answers['insomnia'] == true;
    final hasUrinationProblem = answers['urine_difficult'] == true ||
        _selectedSymptoms.contains('小便不利');
    final hasFever = _answers['fever'] == true || _selectedSymptoms.contains('发热');
    if (hasInsomnia && hasUrinationProblem && hasFever) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '阴虚水热互结（猪苓汤证）',
        patternDetail: '发热，心烦不得眠，小便不利。阴虚水热互结。',
        formula: '猪苓汤',
        explanation: '猪苓茯苓泽泻利水，阿胶滋阴，滑石清热。利水不伤阴，滋阴不碍湿。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 阳明湿热发黄系列
    final hasJaundice = _answers['jaundice'] == true ||
        _selectedSymptoms.contains('身黄') ||
        _selectedSymptoms.contains('黄疸') ||
        _selectedSymptoms.contains('发黄');
    if (hasJaundice) {
      final hasBodyPain = _answers['joint_pain'] == true ||
          _selectedSymptoms.contains('骨节疼烦') ||
          _selectedSymptoms.contains('身痒');
      // 麻黄连轺赤小豆汤：湿热发黄+表证（身黄+身痒/骨节疼烦）
      if (hasBodyPain) {
        return DiagnosisResult(
          meridian: '阳明',
          pattern: '阳明湿热发黄兼表证（麻黄连轺赤小豆汤证）',
          patternDetail: '身黄如橘子色，兼有表证。',
          formula: '麻黄连轺赤小豆汤',
          explanation: '麻黄解表，连轺赤小豆清热利湿，表里双解。',
          confidence: 0.85,
          matchedSymptoms: _selectedSymptoms,
        );
      }

      // 栀子柏皮汤：湿热发黄热重于湿（身黄+发热）
      // FIX-P1-2: fever 标志修复后，阳明定向必然 fever=true，栀子柏皮（身黄+fever）把
      // 茵陈蒿汤（身黄+腹满+小便不利，里实湿重）全部遮蔽。加腹满/小便不利排除：
      // 无腹满无小便不利的"身黄发热"归栀子柏皮；兼腹满小便不利归茵陈蒿汤。
      final hasFever = _answers['fever'] == true || _selectedSymptoms.contains('发热');
      if (hasFever &&
          !_selectedSymptoms.contains('腹满') &&
          !_selectedSymptoms.contains('小便不利')) {
        return DiagnosisResult(
          meridian: '阳明',
          pattern: '阳明湿热发黄热重于湿（栀子柏皮汤证）',
          patternDetail: '身黄发热。热重于湿。',
          formula: '栀子柏皮汤',
          explanation: '栀子清热利湿，黄柏清热燥湿，甘草调和。',
          confidence: 0.85,
          matchedSymptoms: _selectedSymptoms,
        );
      }

      // 茵陈蒿汤：湿热发黄基础方
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '阳明湿热发黄（茵陈蒿汤证）',
        patternDetail: '身黄如橘子色，发热汗出。',
        formula: '茵陈蒿汤',
        explanation: '茵陈蒿清热利湿退黄，栀子清热，大黄泻下。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 津液内竭大便硬（外用法）
    // 需要特殊症状：自汗出+小便自利+大便硬但无腹痛拒按
    final hasSelfSweat = _answers['has_sweat'] == true;
    final hasUrinationNormal = _answers['urine_difficult'] != true;
    if (hasSelfSweat && hasUrinationNormal && constipated == true && abdomenPress != true) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '津液内竭大便硬（蜜煎方/土瓜根方证）',
        patternDetail: '自汗出，小便自利，大便硬。津液内竭，不可攻之。',
        formula: '蜜煎方/土瓜根方',
        explanation: '津液内竭所致大便硬，不可攻下。蜜煎润肠通便，外用导法。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 腑实证需要便秘+腹痛拒按同时满足，避免单纯腹痛误入承气汤
    // 放宽条件：接受 _answers['constipated']（来自十问回答）或主诉精确匹配
    if (constipated == true && (abdomenPress == true ||
        _selectedSymptoms.contains('便秘好几天不通') ||
        _answers['constipated'] == true)) {
      bool severeConstipation = _selectedSymptoms.contains('便秘好几天不通') ||
          (_answers['constipated'] == true && abdomenPress == true);
      bool stomachPain = _selectedSymptoms.contains('只胃脘痛');
      // FIX-P0-3: 精确串比较与 UI 选项后缀（（→承气汤）等）不兼容，改子串匹配。
      // 兼容 answerFollowUp 的两种存储形态：speech 存原始文本（L614），
      // tidal_fever 被 L657 覆盖为 bool（contains('潮热')）。
      final speechAns = _answers['speech'];
      final tidalAns = _answers['tidal_fever'];
      bool hasDelirium = _answers['delirium'] == true ||
          (speechAns is String &&
              (speechAns.contains('胡话') || speechAns.contains('谵语')));
      bool hasTidalFever = tidalAns == true ||
          (tidalAns is String &&
              (tidalAns.contains('潮热') || tidalAns.contains('手足汗出')));

      // 大承气汤证：腹满痛拒按+便秘+谵语+潮热（四证俱备）
      if (severeConstipation && hasDelirium && hasTidalFever) {
        return DiagnosisResult(
          meridian: '阳明',
          pattern: '腑实重证（大承气汤证）',
          patternDetail: '大便硬，腹满痛拒按，谵语，潮热。四证俱备。',
          formula: '大承气汤',
          explanation: '大黄芒硝攻下热结，厚朴枳实行气消满。急下存阴之峻剂。四证俱备方可峻攻。',
          confidence: 0.95,
          matchedSymptoms: _selectedSymptoms,
        );
      }

      // 大承气汤轻用：便秘+谵语但无潮热
      if (severeConstipation && hasDelirium) {
        return DiagnosisResult(
          meridian: '阳明',
          pattern: '腑实证（大承气汤轻用）',
          patternDetail: '大便硬，谵语。热结已重但潮热未显。',
          formula: '大承气汤',
          explanation: '谵语为热上冲脑，虽无潮热但热结已重，可轻用大承气汤。',
          confidence: 0.85,
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
    final hasChestRibFullness = answers['chest_pain'] == true ||
        _selectedSymptoms.contains('胸胁苦满');

    // 大柴胡汤：少阳+阳明合病，需要胸胁苦满+便秘/腹痛拒按
    if (hasConstipation == true && hasChestRibFullness) {
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

    // 四逆散：少阳气郁致厥（四肢厥冷+胸胁苦满+脉弦）
    final hasColdLimbs = answers['cold_limbs'] == true;
    final hasPulseStringy = _pulseType == '弦';
    if (hasColdLimbs && hasChestRibFullness && hasPulseStringy) {
      return DiagnosisResult(
        meridian: '少阳',
        pattern: '少阳气郁致厥（四逆散证）',
        patternDetail: '少阴病，四逆，其人或咳或悸或小便不利，或腹中痛。气郁致厥。',
        formula: '四逆散',
        explanation: '柴胡疏肝解郁，枳实破气消痞，芍药柔肝缓急，甘草调和。阳郁不达四末。',
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
      // 太阴虚寒用理中汤（温中健脾），四逆汤留给少阴（回阳救逆）
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '太阴虚寒（理中汤证）',
        patternDetail: '腹满而吐，食不下，自利益甚，手足不温。脾阳虚衰。',
        formula: '理中汤',
        explanation: '干姜温中散寒，人参补气健脾，白术燥湿，甘草调和。太阴虚寒主方。若寒重及肾（四肢厥冷过肘膝）则转少阴用四逆汤。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 甘草干姜汤：脾阳虚厥逆（四肢厥冷+烦躁+吐涎沫）
    final hasSpitting = _selectedSymptoms.contains('涎沫') ||
        _selectedSymptoms.contains('吐涎沫');
    if (answers['irritable'] == true && hasSpitting) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '脾阳虚厥逆（甘草干姜汤证）',
        patternDetail: '四肢厥冷，烦躁，吐涎沫。脾阳不足。',
        formula: '甘草干姜汤',
        explanation: '干姜温脾阳，炙甘草补中缓急。回阳轻剂，厥逆回后以理中汤善后。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 甘麦大枣汤：妇人脏躁（喜悲伤欲哭+精神恍惚）
    final hasEmotionalCry = _selectedSymptoms.contains('脏躁') ||
        _selectedSymptoms.contains('喜悲伤欲哭') ||
        _selectedSymptoms.contains('精神恍惚');
    if (hasEmotionalCry) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '妇人脏躁（甘麦大枣汤证）',
        patternDetail: '妇人脏躁，喜悲伤欲哭，象如神灵所作，数欠伸。',
        formula: '甘麦大枣汤',
        explanation: '甘草缓急，小麦养心，大枣补脾。甘润缓急，养心安神。脏躁专方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 黄芩汤：太阳少阳合病自下利
    final hasDiarrhea = answers['diarrhea'] == true;
    if (hasDiarrhea && answers['bitter_mouth'] == true) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '太阳少阳合病下利（黄芩汤证）',
        patternDetail: '太阳与少阳合病，自下利。腹痛，口苦。',
        formula: '黄芩汤',
        explanation: '黄芩清热止利，芍药敛阴缓急，甘草大枣和中。太少合病下利主方。',
        confidence: 0.8,
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
        _selectedSymptoms.contains('骨节疼痛') ||
        _selectedSymptoms.contains('全身酸痛');

    // ========== 少阴热化证（六经辨证公式）==========
    // 热化辨证公式：脉细数 + 心烦不得卧 + 舌红少苔
    // 鉴别要点：舌红少苔/脉细数 → 热化；舌淡苔白/脉微细 → 寒化
    final hasIrritability = hasHeat == true;
    final hasInsomnia = answers['insomnia'] == true;
    final hasTongueRed = _tongueShape == '红' || _tongueShape == '绛紫';
    final hasThinCoating = _tongueCoating == '无苔' || _tongueCoating == '黄薄';
    final hasPulseThinFast = _pulseType == '细' || _pulseType == '数';
    // 热化核心：烦躁不得卧 + (舌红 或 脉细数)
    if (hasIrritability && hasInsomnia && (hasTongueRed || hasPulseThinFast)) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '少阴热化（黄连阿胶汤证）',
        patternDetail: '心中烦，不得卧。心肾不交。${hasTongueRed ? "舌红" : ""}${hasThinCoating ? "少苔" : ""}${hasPulseThinFast ? "脉细数" : ""}',
        formula: '黄连阿胶汤',
        explanation: '黄连黄芩清心火，阿胶鸡子黄补心血，芍药敛阴。交通心肾。少阴热化专方。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }
    // 热化轻证：仅烦躁失眠但无明显舌脉热象 → 栀子豉汤
    if (hasIrritability && hasInsomnia) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '少阴虚热（栀子豉汤证）',
        patternDetail: '虚烦不得眠，心中懊憹。余热未尽。',
        formula: '栀子豉汤',
        explanation: '栀子清心除烦，香豉宣透郁热。虚烦失眠轻方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // ========== 少阴新增方剂触发逻辑 ==========

    // 干姜附子汤：昼日烦躁夜而安静（阳虚阴盛，昼日阳气争）
    final hasDaytimeIrritability = answers['irritable'] == true &&
        (_selectedSymptoms.contains('昼日烦躁') || _selectedSymptoms.contains('夜而安静'));
    if (hasDaytimeIrritability) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '阳虚阴盛（干姜附子汤证）',
        patternDetail: '昼日烦躁不得眠，夜而安静。阳虚阴盛。',
        formula: '干姜附子汤',
        explanation: '干姜温中，生附子回阳。顿服，急救回阳。不呕不渴无表证者。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 桂枝加附子汤：汗出不止恶风（表阳不固）
    final hasSweatProfuse = _selectedSymptoms.contains('汗出不止') ||
        _selectedSymptoms.contains('遂漏不止') ||
        (answers['has_sweat'] == true && answers['drowsy'] != true);
    if (hasSweatProfuse && answers['cold_limbs'] != true) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '表阳不固（桂枝加附子汤证）',
        patternDetail: '太阳病，发汗，遂漏不止，其人恶风。表阳不固。',
        formula: '桂枝加附子汤',
        explanation: '桂枝汤调和营卫，炮附子温经固表。汗出不止恶风者。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 茯苓四逆汤：阳虚烦躁（烦躁+四逆+脉微细）
    final hasSevereCold = answers['cold_limbs'] == true &&
        (_pulseType == '微' || _pulseType == '细');
    if (hasIrritability && hasSevereCold) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '阳虚烦躁（茯苓四逆汤证）',
        patternDetail: '发汗，若下之，病不解，烦躁。阳虚阴盛。',
        formula: '茯苓四逆汤',
        explanation: '茯苓安神，人参补气，附子回阳，干姜温中，甘草调和。阴阳双补。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // ========== 少阴寒化证 ==========
    // 寒化+便脓血 → 桃花汤（下利不止便脓血）
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

    // 寒化+水饮 → 真武汤（阳虚水泛）
    // FIX-P1-2: 真武汤（水饮兜底）条件过宽，遮蔽麻黄附子汤（水气+脉沉+无悸无眩）。
    // 窄化：脉沉且无心悸无头晕时归麻黄附子汤（少阴水肿），其余归真武汤。
    if (hasWaterRetention == true &&
        !(_pulseType == '沉' &&
          answers['palpitation'] != true &&
          answers['dizziness'] != true)) {
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

    // 麻黄附子汤：水气脉沉小属少阴（真武汤之后，用于单纯水气无心悸头眩）
    if (hasWaterRetention == true && _pulseType == '沉' &&
        answers['palpitation'] != true && answers['dizziness'] != true) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '少阴水肿（麻黄附子汤证）',
        patternDetail: '水之为病，其脉沉小，属少阴。',
        formula: '麻黄附子汤',
        explanation: '麻黄发汗利水，附子温经。少阴水肿。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 少阴咽痛系列（来自伤寒论少阴病篇）
    // 需要在十问中添加咽痛症状的采集
    final hasSoreThroat = _answers['sore_throat'] == true ||
        _selectedSymptoms.contains('咽痛') ||
        _selectedSymptoms.contains('喉咙痛');
    final hasThroatUlcer = _answers['throat_ulcer'] == true ||
        _selectedSymptoms.contains('咽中伤') ||
        _selectedSymptoms.contains('生疮');
    final hasDifficultySpeak = _answers['difficulty_speak'] == true ||
        _selectedSymptoms.contains('不能语言');

    if (hasSoreThroat || hasThroatUlcer) {
      // 苦酒汤：咽中伤生疮，不能语言
      if (hasThroatUlcer && hasDifficultySpeak) {
        return DiagnosisResult(
          meridian: '少阴',
          pattern: '少阴痰热咽痛（苦酒汤证）',
          patternDetail: '咽中伤，生疮，不能语言，声不出。',
          formula: '苦酒汤',
          explanation: '半夏化痰散结，鸡子清润喉，苦酒散瘀消肿。含咽法使药力直达病所。',
          confidence: 0.85,
          matchedSymptoms: _selectedSymptoms,
        );
      }

      // 桔梗汤：咽痛化脓
      final hasPus = _answers['throat_pus'] == true ||
          _selectedSymptoms.contains('化脓') ||
          _selectedSymptoms.contains('脓');
      if (hasPus) {
        return DiagnosisResult(
          meridian: '少阴',
          pattern: '少阴咽痛化脓（桔梗汤证）',
          patternDetail: '咽痛，化脓。',
          formula: '桔梗汤',
          explanation: '桔梗开提肺气，化痰排脓，配甘草清热解毒。',
          confidence: 0.85,
          matchedSymptoms: _selectedSymptoms,
        );
      }

      // 半夏散及汤：客寒咽痛（咽痛+怕冷+无热象）
      final hasChills = _answers['chills'] == true || _answers['cold_limbs'] == true;
      final hasHeatSigns = _answers['thirst_strong'] == true || _tongueCoating == '黄';
      if (hasChills && !hasHeatSigns) {
        return DiagnosisResult(
          meridian: '少阴',
          pattern: '少阴客寒咽痛（半夏散及汤证）',
          patternDetail: '咽中痛，畏寒，无热象。',
          formula: '半夏散及汤',
          explanation: '半夏散寒化痰，桂枝通阳散寒，甘草缓急止痛。寒邪客于少阴经脉。',
          confidence: 0.85,
          matchedSymptoms: _selectedSymptoms,
        );
      }

      // 猪肤汤：虚火咽痛（咽痛+下利+胸满心烦）
      final hasDiarrhea = _answers['diarrhea'] == true;
      final hasChestFullness = _answers['chest_fullness'] == true ||
          _selectedSymptoms.contains('胸满');
      if (hasDiarrhea && hasChestFullness) {
        return DiagnosisResult(
          meridian: '少阴',
          pattern: '少阴虚火咽痛（猪肤汤证）',
          patternDetail: '下利咽痛，胸满心烦。',
          formula: '猪肤汤',
          explanation: '猪肤滋阴润燥，白蜜润肺，白粉益气和中。甘润平和，最宜虚火咽痛。',
          confidence: 0.8,
          matchedSymptoms: _selectedSymptoms,
        );
      }

      // 甘草汤：咽痛初起（轻证）
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '少阴咽痛（甘草汤证）',
        patternDetail: '少阴病，咽痛。',
        formula: '甘草汤',
        explanation: '生甘草清热解毒，缓急止痛。为咽痛基础方，不差者用桔梗汤。',
        confidence: 0.75,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 乌头汤：寒湿历节关节剧痛（关节剧痛+不可屈伸）
    final hasSevereJointPain = _selectedSymptoms.contains('历节') ||
        _selectedSymptoms.contains('关节剧痛') ||
        _selectedSymptoms.contains('不可屈伸');
    if (hasSevereJointPain) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '寒湿历节（乌头汤证）',
        patternDetail: '病历节，不可屈伸，疼痛。寒湿痹阻。',
        formula: '乌头汤',
        explanation: '乌头散寒止痛，麻黄发汗散寒，芍药甘草缓急。寒湿历节剧痛者。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 乌头煎：寒疝绕脐痛（寒疝+绕脐痛+发冷白汗）
    final hasHerniaPain = _selectedSymptoms.contains('寒疝') ||
        _selectedSymptoms.contains('绕脐痛');
    if (hasHerniaPain) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '寒疝腹痛（乌头煎证）',
        patternDetail: '腹痛，绕脐痛，发则白汗出，手足厥冷。',
        formula: '乌头煎',
        explanation: '乌头大热散寒止痛，蜜制缓毒。寒疝剧痛专方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 寒化+经脉寒湿 → 附子汤（身体痛骨节痛）
    // 也检查 _answers['pain'] 中的疼痛描述
    final painAnswer = _answers['pain'] as String?;
    final hasBodyPainFromAnswer = painAnswer != null &&
        (painAnswer.contains('全身酸痛') || painAnswer.contains('骨节疼痛') || painAnswer.contains('关节'));
    if (bodyPain == true || hasBodyPainFromAnswer) {
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

    // 麻黄附子甘草汤：少阴表证缓和（少阴病得之二三日+无里证）
    final hasMildCold = _selectedSymptoms.contains('少阴表证') ||
        (_selectedSymptoms.contains('无汗') && answers['drowsy'] == true);
    if (hasMildCold && answers['diarrhea'] != true) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '少阴表证缓和（麻黄附子甘草汤证）',
        patternDetail: '少阴病，得之二三日，无里证。微发汗。',
        formula: '麻黄附子甘草汤',
        explanation: '麻黄发汗，附子温经，甘草调和。少阴兼表轻证，微发其汗。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 少阴下利系列
    final hasDiarrhea = _answers['diarrhea'] == true;
    if (hasDiarrhea) {
      // 白通加猪胆汁汤：阴盛格阳（下利+脉绝/无脉）
      final hasNoPulse = _pulseType == '微' || _pulseType == '绝' || _pulseType == '无';
      if (hasNoPulse) {
        return DiagnosisResult(
          meridian: '少阴',
          pattern: '少阴阴盛格阳（白通加猪胆汁汤证）',
          patternDetail: '下利不止，脉绝。阴盛格阳。',
          formula: '白通加猪胆汁汤',
          explanation: '白通汤破阴通阳，加人尿猪胆汁咸寒反佐，引阳药入阴。热因寒用。',
          confidence: 0.9,
          matchedSymptoms: _selectedSymptoms,
        );
      }

      // 白通汤：少阴下利（无格阳）
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '少阴下利（白通汤证）',
        patternDetail: '少阴病下利。阴寒内盛。',
        formula: '白通汤',
        explanation: '葱白通阳，干姜温中，附子回阳。三药合用，通阳破阴。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 肾气丸：虚劳腰痛脚冷（腰痛+脚冷+小便不利/频数）
    final hasLoinPain = _selectedSymptoms.contains('腰痛') ||
        _selectedSymptoms.contains('腰酸') ||
        answers['back_pain'] == true;
    final hasColdFeet = _selectedSymptoms.contains('脚冷') ||
        _selectedSymptoms.contains('足冷');
    if (hasLoinPain && hasColdFeet) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '肾阳虚腰痛（肾气丸证）',
        patternDetail: '虚劳腰痛，少腹拘急，小便不利。肾阳不足。',
        formula: '肾气丸',
        explanation: '六味地黄丸加桂枝附子。少火生气，温补肾阳。虚劳腰痛专方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 寒化基础方 → 四逆汤（脉微细但欲寐四肢厥冷）
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

    // 厥热胜复判断（来自六经辨证公式）
    // 厥多热少→病进；热多厥少→病退；厥热相等→病稳
    String? jueReAssessment;
    int coldCount = 0;
    int heatCount = 0;
    if (hasColdLimbs == true) coldCount++;
    if (_answers['upper_heat_lower_cold'] == true) { coldCount++; heatCount++; }
    if (_answers['thirst_strong'] == true) heatCount++;
    if (_answers['xiaoke'] == true) heatCount++;
    if (_answers['irritable'] == true) heatCount++;
    if (_answers['diarrhea'] == true) coldCount++;

    if (coldCount > heatCount) {
      jueReAssessment = '厥多热少→病进，阳气渐衰，预后差';
    } else if (heatCount > coldCount) {
      jueReAssessment = '热多厥少→病退，阳气来复，预后好';
    } else if (coldCount > 0 && heatCount > 0) {
      jueReAssessment = '厥热相等→病稳，正邪相持';
    }

    // 治肝三法提示（来自六经辨证公式）
    String liverTreatment = '';
    if (_answers['menstrual_pain'] == true || _answers['joint_wandering'] == true ||
        _answers['lower_abdomen_pain'] == true) {
      liverTreatment = '\n治肝三法：补用酸（乌梅丸）、助用焦苦（吴茱萸汤）、益用甘味（小建中汤）';
    }

    // 干姜黄芩黄连人参汤：厥阴寒格——上热下寒，食入即吐
    if (_answers['vomiting'] == true && _answers['thirst_strong'] == true &&
        hasColdLimbs == true) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '厥阴寒格（干姜黄芩黄连人参汤证）',
        patternDetail: '寒格于内，食入口即吐。上热下寒。',
        formula: '干姜黄芩黄连人参汤',
        explanation: '黄芩黄连清上热，干姜温下寒，人参补中。寒热格拒，开上热降逆，温下寒复阳。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 麻黄升麻汤：厥阴寒热错杂重证（寸脉沉迟手足厥逆，唾脓血，泄利不止）
    final hasBloodySputum = _answers['bloody_sputum'] == true ||
        _selectedSymptoms.contains('唾脓血') ||
        _selectedSymptoms.contains('咳血');
    final hasSevereDiarrhea = _answers['diarrhea'] == true &&
        (_answers['severe_diarrhea'] == true || _selectedSymptoms.contains('泄利不止'));
    if (hasBloodySputum && hasSevereDiarrhea && hasColdLimbs == true) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '厥阴寒热错杂重证（麻黄升麻汤证）',
        patternDetail: '手足厥逆，唾脓血，泄利不止。上热下寒，寒热错杂。',
        formula: '麻黄升麻汤',
        explanation: '麻黄升麻发越郁阳，芩石膏清上热，姜术温下寒，归芍天冬葳蕤养阴血。寒热并用，表里兼顾。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 吴茱萸汤：厥阴干呕吐涎沫，头痛
    if (_answers['vomiting'] == true && _answers['headache_back'] == true) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '厥阴寒逆（吴茱萸汤证）',
        patternDetail: '干呕吐涎沫，头痛。肝寒犯胃，浊阴上逆。',
        formula: '吴茱萸汤',
        explanation: '吴茱萸温肝降逆，生姜散寒止呕，人参大枣补中。厥阴经寒上逆之主方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    if (hasColdLimbs == true) {
      // 当归四逆加吴茱萸生姜汤：厥阴久寒（手足厥冷+内有久寒/腹冷痛）
      final hasChronicCold = _selectedSymptoms.contains('内有久寒') ||
          _selectedSymptoms.contains('腹冷痛') ||
          _selectedSymptoms.contains('久寒');
      if (hasChronicCold) {
        return DiagnosisResult(
          meridian: '厥阴',
          pattern: '厥阴久寒（当归四逆加吴茱萸生姜汤证）',
          patternDetail: '手足厥寒，脉细欲绝，内有久寒。血虚寒凝，久寒在里。',
          formula: '当归四逆加吴茱萸生姜汤',
          explanation: '当归四逆汤温经散寒，加吴茱萸生姜温里散寒。厥阴久寒重证。',
          confidence: 0.85,
          matchedSymptoms: _selectedSymptoms,
        );
      }

      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '厥阴寒凝（当归四逆汤证）',
        patternDetail: '手足厥寒，脉细欲绝。血虚寒凝。'
            '${jueReAssessment != null ? "\n$jueReAssessment" : ""}',
        formula: '当归四逆汤',
        explanation: '当归补血，桂枝细辛温经散寒，通草通血脉。'
            '$liverTreatment',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    return DiagnosisResult(
      meridian: '厥阴',
      pattern: '厥阴病（乌梅丸证）',
      patternDetail: '消渴，气上撞心，心中疼热，饥而不欲食。上热下寒。'
          '${jueReAssessment != null ? "\n$jueReAssessment" : ""}',
      formula: '乌梅丸',
      explanation: '乌梅酸收敛，细辛干姜温里，黄连黄柏清上热，附子桂枝温下寒。寒热并用。'
          '$liverTreatment',
      confidence: 0.9,
      matchedSymptoms: _selectedSymptoms,
    );
  }

  // ==================== 杂病/跨经方剂 ====================
  DiagnosisResult? _diagnoseMiscellaneous(Map<String, dynamic> answers) {
    final hasUrinationProblem = answers['urine_difficult'] == true ||
        _selectedSymptoms.contains('小便不利');
    final thirsty = answers['thirsty'] == true;

    // 五苓散：膀胱蓄水证（渴+小便不利+水入即吐）
    final hasWaterVomit = _selectedSymptoms.contains('水入即吐') ||
        _selectedSymptoms.contains('渴而饮水不止');
    if (thirsty && hasUrinationProblem && hasWaterVomit) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '膀胱蓄水（五苓散证）',
        patternDetail: '脉浮，小便不利，微热消渴。水蓄膀胱。',
        formula: '五苓散',
        explanation: '猪苓泽泻利水，茯苓白术健脾，桂枝化气利水。表里双解，化气行水。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 半夏泻心汤：痞证主方（心下痞满+呕+肠鸣）
    final hasEpigastric = _selectedSymptoms.contains('心下痞') ||
        _selectedSymptoms.contains('胃脘痞满') ||
        _selectedSymptoms.contains('痞硬');
    final hasBorborygmus = _selectedSymptoms.contains('肠鸣') ||
        _selectedSymptoms.contains('腹中雷鸣');
    final hasFoodStinkB = _selectedSymptoms.contains('食臭') ||
        _selectedSymptoms.contains('噫气食臭');
    final hasSevereDiarrheaB = _selectedSymptoms.contains('下利不止') ||
        _selectedSymptoms.contains('日数十行');
    // FIX-P1-2: 半夏泻心汤（痞证基础方）条件过宽，把生姜泻心（+食臭）和甘草泻心（+下利不止）全部遮蔽。
    // 加排除后三者各得其所：半夏泻心=心下痞+呕/肠鸣（无食臭无下利不止）。
    if (hasEpigastric && (answers['vomiting'] == true || hasBorborygmus) &&
        !hasFoodStinkB && !hasSevereDiarrheaB) {
      return DiagnosisResult(
        meridian: '少阳',
        pattern: '寒热痞（半夏泻心汤证）',
        patternDetail: '呕而发热，心下痞硬。寒热错杂之痞。',
        formula: '半夏泻心汤',
        explanation: '半夏干姜辛温开痞，黄芩黄连苦寒清热，人参甘草大枣补中。辛开苦降。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 生姜泻心汤：水饮食滞痞（心下痞+干噫食臭+腹中雷鸣下利）
    final hasFoodStink = _selectedSymptoms.contains('食臭') ||
        _selectedSymptoms.contains('噫气食臭');
    if (hasEpigastric && hasBorborygmus && hasFoodStink) {
      return DiagnosisResult(
        meridian: '少阳',
        pattern: '水饮食滞痞（生姜泻心汤证）',
        patternDetail: '心下痞硬，干噫食臭，腹中雷鸣下利。',
        formula: '生姜泻心汤',
        explanation: '半夏泻心汤加生姜，重用生姜散水消痞。水饮食滞痞专方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 甘草泻心汤：痞利俱甚（心下痞+下利不止+干呕心烦）
    final hasSevereDiarrhea = _selectedSymptoms.contains('下利不止') ||
        _selectedSymptoms.contains('日数十行');
    if (hasEpigastric && hasSevereDiarrhea) {
      return DiagnosisResult(
        meridian: '少阳',
        pattern: '痞利俱甚（甘草泻心汤证）',
        patternDetail: '心下痞硬而满，下利日数十行，干呕心烦。',
        formula: '甘草泻心汤',
        explanation: '半夏泻心汤重用甘草。缓急和中，止利止呕。狐惑病亦用此方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 大陷胸汤：水热互结结胸（心下满痛拒按+便秘+短气烦躁）
    final hasChestPain = _selectedSymptoms.contains('结胸') ||
        _selectedSymptoms.contains('心下满痛') ||
        _selectedSymptoms.contains('从心下至少腹');
    if (hasChestPain && answers['constipated'] == true) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '水热互结结胸（大陷胸汤证）',
        patternDetail: '心下满而硬痛，便秘，短气烦躁。结胸重证。',
        formula: '大陷胸汤',
        explanation: '大黄芒硝泻热，甘遂逐水。结胸重证峻下逐水。非结胸不可用。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 小陷胸汤：痰热结胸（心下按之痛+脉浮滑）
    if (hasChestPain && _pulseType == '浮' || _pulseType == '滑') {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '痰热结胸（小陷胸汤证）',
        patternDetail: '小结胸病，正在心下，按之则痛，脉浮滑。',
        formula: '小陷胸汤',
        explanation: '黄连清热，半夏化痰，栝蒌宽胸散结。痰热互结之小结胸。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 旋覆代赭石汤：胃虚痰阻噫气（心下痞硬+噫气不除）
    final hasBelching = _selectedSymptoms.contains('噫气') ||
        _selectedSymptoms.contains('嗳气') ||
        _selectedSymptoms.contains('打嗝');
    if (hasEpigastric && hasBelching) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '胃虚痰阻（旋覆代赭石汤证）',
        patternDetail: '心下痞硬，噫气不除。胃虚痰阻，气逆不降。',
        formula: '旋覆代赭石汤',
        explanation: '旋覆花降气消痰，代赭石重镇降逆，半夏生姜化痰和胃。噫气不除专方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 胸痹系列
    final hasChestBi = _selectedSymptoms.contains('胸痹') ||
        _selectedSymptoms.contains('胸背痛') ||
        _selectedSymptoms.contains('喘息咳唾');
    if (hasChestBi) {
      final hasShortnessBreath = _selectedSymptoms.contains('短气') ||
          _selectedSymptoms.contains('不得卧');
      // 栝蒌薤白半夏汤：胸痹重证（胸背痛+不得卧+心痛彻背）
      // FIX-P1-2: 排除胸中气塞（轻证归橘枳生姜/茯苓杏仁甘草），避免遮蔽。
      if (hasShortnessBreath && !_selectedSymptoms.contains('胸中气塞')) {
        return DiagnosisResult(
          meridian: '太阳',
          pattern: '胸痹重证（栝蒌薤白半夏汤证）',
          patternDetail: '胸痹不得卧，心痛彻背。痰浊壅盛。',
          formula: '栝蒌薤白半夏汤',
          explanation: '栝蒌宽胸散结，薤白通阳散结，半夏化痰。胸痹重证。',
          confidence: 0.85,
          matchedSymptoms: _selectedSymptoms,
        );
      }
      // 枳实薤白桂枝汤：胸痹气滞（胸满+胁下逆抢心）
      final hasRetrosternal = _selectedSymptoms.contains('胁下逆抢心') ||
          _selectedSymptoms.contains('气从胁下冲心');
      if (hasRetrosternal) {
        return DiagnosisResult(
          meridian: '太阳',
          pattern: '胸痹气滞（枳实薤白桂枝汤证）',
          patternDetail: '胸痹，心中痞气，气结在胸，胁下逆抢心。',
          formula: '枳实薤白桂枝汤',
          explanation: '栝蒌薤白通阳散结，枳实行气消痞，厚朴下气除满。胸痹气滞专方。',
          confidence: 0.85,
          matchedSymptoms: _selectedSymptoms,
        );
      }
      // 栝蒌薤白白酒汤：胸痹基础方
      // FIX-P1-2: 白酒汤（胸痹兜底）条件过宽，把栝蒌薤白半夏（不得卧/短气）、
      // 枳实薤白桂枝（胁下逆抢心）、薏苡附子散（缓急）全部遮蔽。加排除词后作真兜底。
      if (!hasShortnessBreath && !hasRetrosternal &&
          !_selectedSymptoms.contains('缓急') &&
          !_selectedSymptoms.contains('胸中气塞')) {
        return DiagnosisResult(
          meridian: '太阳',
          pattern: '胸痹（栝蒌薤白白酒汤证）',
          patternDetail: '胸痹之病，喘息咳唾，胸背痛，短气。',
          formula: '栝蒌薤白白酒汤',
          explanation: '栝蒌宽胸散结，薤白通阳散结，白酒行气活血。胸痹基础方。',
          confidence: 0.8,
          matchedSymptoms: _selectedSymptoms,
        );
      }
    }

    // 抵当汤/抵当丸：蓄血重证（少腹硬满+发狂+小便利）
    final hasHardAbdomen = _selectedSymptoms.contains('少腹硬满') ||
        _selectedSymptoms.contains('少腹坚硬');
    final hasManic = _selectedSymptoms.contains('发狂') ||
        _selectedSymptoms.contains('如狂');
    if (hasHardAbdomen && hasManic) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '蓄血重证（抵当汤证）',
        patternDetail: '太阳病不解，热结膀胱，其人如狂，少腹硬满。蓄血重证。',
        formula: '抵当汤',
        explanation: '水蛭虻虫破血逐瘀，桃仁大黄活血泻下。蓄血重证峻攻。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 白头翁汤：热利下重（腹痛+里急后重+便脓血）
    final hasDysentery = _selectedSymptoms.contains('热利') ||
        _selectedSymptoms.contains('里急后重') ||
        _selectedSymptoms.contains('下重');
    if (hasDysentery) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '热利下重（白头翁汤证）',
        patternDetail: '热利下重，腹痛，便脓血。肝经湿热下迫大肠。',
        formula: '白头翁汤',
        explanation: '白头翁清热凉血，黄连黄柏清热燥湿，秦皮清热止利。热利主方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 大黄附子汤：寒积腹痛便秘（腹痛+便秘+胁下偏痛+脉紧弦）
    final hasSevereAbdomenPain = _selectedSymptoms.contains('腹痛剧烈') ||
        _selectedSymptoms.contains('胁下偏痛');
    if (hasSevereAbdomenPain && answers['constipated'] == true && answers['cold_limbs'] == true) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '寒积腹痛（大黄附子汤证）',
        patternDetail: '胁下偏痛，发热，脉紧弦。寒积内实。',
        formula: '大黄附子汤',
        explanation: '大黄泻下，附子细辛温里散寒。寒积腹痛专方，温下并用。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 温经汤：妇人月经病（月经不调+久不受孕+傍晚发热）
    final hasGynecology = _selectedSymptoms.contains('月经不调') ||
        _selectedSymptoms.contains('久不受孕') ||
        _selectedSymptoms.contains('宫寒');
    if (hasGynecology) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '妇人月经病（温经汤证）',
        patternDetail: '妇人年五十所，病下利数十日不止，暮即发热。冲任虚寒。',
        formula: '温经汤',
        explanation: '吴茱萸桂枝温经散寒，当归川芎养血，人参阿胶补虚。温经养血调经。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 当归芍药散：妊娠腹痛（妊娠+腹中㽲痛+小便不利）
    final isPregnant = _selectedSymptoms.contains('妊娠') ||
        _selectedSymptoms.contains('怀孕');
    if (isPregnant && _selectedSymptoms.contains('腹中㽲痛')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '妊娠腹痛（当归芍药散证）',
        patternDetail: '妇人怀妊，腹中㽲痛。肝脾不调。',
        formula: '当归芍药散',
        explanation: '当归芍药养血柔肝，川芎活血，茯苓白术泽泻健脾利水。妊娠腹痛专方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }


    // ========== 金匮要略·太阳/阳明系统 ==========

    // 葛根汤：太阳阳明合病（项背强几几+无汗恶风）
    if (_selectedSymptoms.contains('项背强') && answers['has_sweat'] != true) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '太阳阳明合病（葛根汤证）',
        patternDetail: '太阳病，项背强几几，无汗恶风。',
        formula: '葛根汤',
        explanation: '葛根升津舒经，麻黄桂枝解表，芍药甘草缓急。太阳阳明合病主方。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 葛根加半夏汤：太阳阳明合病呕
    if (_selectedSymptoms.contains('项背强') && answers['vomiting'] == true) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '太阳阳明合病呕（葛根加半夏汤证）',
        patternDetail: '太阳阳明合病，不下利但呕者。',
        formula: '葛根加半夏汤',
        explanation: '葛根汤解表，半夏降逆止呕。太阳阳明合病呕者。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 葛根黄芩黄连汤：热利不止（下利+发热+脉促）
    if (answers['diarrhea'] == true && _answers['fever'] == true &&
        _pulseType == '促') {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '热利不止（葛根黄芩黄连汤证）',
        patternDetail: '太阳病，桂枝证，医反下之，利遂不止，脉促者。',
        formula: '葛根黄芩黄连汤',
        explanation: '葛根升津止利，黄芩黄连清热燥湿，甘草调和。表里双解之热利方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 麻黄加术汤：湿家身烦疼
    if (answers['has_sweat'] != true && _selectedSymptoms.contains('身烦疼') &&
        _selectedSymptoms.contains('湿')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '寒湿身疼（麻黄加术汤证）',
        patternDetail: '湿家身烦疼。',
        formula: '麻黄加术汤',
        explanation: '麻黄汤解表，白术健脾祛湿。寒湿在表，身烦疼者。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 麻黄杏仁薏苡甘草汤：风湿一身尽疼
    if (_selectedSymptoms.contains('一身尽疼') && _answers['fever'] == true) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '风湿身疼（麻杏薏甘汤证）',
        patternDetail: '病者一身尽疼，发热，日晡所剧者，名风湿。',
        formula: '麻黄杏仁薏苡甘草汤',
        explanation: '麻黄解表，杏仁宣肺，薏苡仁利湿，甘草调和。风湿在表。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 桂枝二麻黄一汤：形似疟日再发
    if (_selectedSymptoms.contains('日再发') || _selectedSymptoms.contains('似疟')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '中风轻证（桂二麻一汤证）',
        patternDetail: '服桂枝汤，大汗出，脉洪大，形似疟，日再发。',
        formula: '桂枝二麻黄一汤',
        explanation: '桂枝汤量多重用，麻黄量少。中风轻证，汗后表未解。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 桂枝二越婢一汤：发热恶寒热多寒少
    if (_selectedSymptoms.contains('热多寒少') && _pulseType == '微弱') {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '太阳轻证（桂二越一汤证）',
        patternDetail: '发热恶寒，热多寒少，脉微弱。此无阳也。',
        formula: '桂枝二越婢一汤',
        explanation: '桂枝汤加石膏。太阳轻证，热多寒少。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 桂枝加桂汤：奔豚气上冲
    // FIX-P1-2: 桂枝加桂（奔豚||气上冲）条件过宽，遮蔽瓜蒂散（胸中痞硬+气上冲）与
    // 奔豚汤（奔豚+往来寒热）。加专属词排除。
    if ((_selectedSymptoms.contains('奔豚') || _selectedSymptoms.contains('气上冲')) &&
        !_selectedSymptoms.contains('胸中痞硬') &&
        !_selectedSymptoms.contains('往来寒热')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '奔豚气上冲（桂枝加桂汤证）',
        patternDetail: '发汗后，烧针令其汗，针处被寒，核起而赤者，必发奔豚。',
        formula: '桂枝加桂汤',
        explanation: '桂枝汤加重桂枝用量。平冲降逆，治奔豚气上冲。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 桂枝去桂加茯苓白术汤：心下满微痛小便不利
    if (_selectedSymptoms.contains('心下满微痛') && answers['urine_difficult'] == true) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '水饮内停（桂去桂加苓术汤证）',
        patternDetail: '头项强痛，翕翕发热，无汗，心下满微痛，小便不利。',
        formula: '桂枝去桂加茯苓白术汤',
        explanation: '芍药甘草生姜大枣，加茯苓白术利水。水饮内停，头项强痛。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 桂枝去芍药加附子汤：脉促胸满微恶寒（已在规则中，跳过）

    // 桂枝去芍药加蜀漆龙骨牡蛎救逆汤：亡阳惊狂
    final hasMistreatmentHistoryG = _answers['history_mistreatment'] == true ||
        _selectedSymptoms.contains('误下') ||
        _selectedSymptoms.contains('被下');
    // FIX-P1-2: 桂枝救逆（惊狂||卧起不安）条件过宽，遮蔽阳明栀子厚朴枳实汤（卧起不安）。
    // 窄化：仅"惊狂"或"误治后卧起不安"命中，纯"卧起不安"归栀子厚朴枳实汤。
    if (_selectedSymptoms.contains('惊狂') ||
        (_selectedSymptoms.contains('卧起不安') && hasMistreatmentHistoryG)) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '亡阳惊狂（桂枝救逆汤证）',
        patternDetail: '伤寒脉浮，以火灸劫之，亡阳必惊狂，卧起不安。',
        formula: '桂枝去芍药加蜀漆龙骨牡蛎救逆汤',
        explanation: '桂枝汤去芍药加蜀漆涌吐痰涎，龙骨牡蛎镇惊。亡阳惊狂专方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 小青龙加石膏汤：肺胀烦躁而喘
    if (_selectedSymptoms.contains('肺胀') && answers['irritable'] == true) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '肺胀烦躁（小青龙加石膏汤证）',
        patternDetail: '肺胀，咳而上气，烦躁而喘，脉浮者，心下有水气。',
        formula: '小青龙加石膏汤',
        explanation: '小青龙汤解表化饮，加石膏清热除烦。水饮化热者。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 三物小白散：寒实结胸
    if (_selectedSymptoms.contains('结胸') && answers['cold_limbs'] == true) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '寒实结胸（三物小白散证）',
        patternDetail: '寒实结胸，无热证者。',
        formula: '三物小白散',
        explanation: '巴豆攻下寒积，桔梗开提，贝母化痰。寒实结胸峻下。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 麻杏甘石汤：汗出而喘无大热（肺热咳喘，非桂枝汤证）
    // 需排除 feber_chills（太阳中风/伤寒），因为那是桂枝汤/麻黄汤的适应证
    if (answers['has_sweat'] == true && answers['cough'] == true &&
        answers['cold_limbs'] != true && answers['temperature'] != 'fever_chills') {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '肺热咳喘（麻杏甘石汤证）',
        patternDetail: '发汗后，不可更行桂枝汤。汗出而喘，无大热者。',
        formula: '麻杏甘石汤',
        explanation: '麻黄宣肺，杏仁降气，石膏清肺热，甘草调和。肺热咳喘主方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 苓桂术甘汤：心下逆满气上冲胸
    if (_selectedSymptoms.contains('气上冲胸') || _selectedSymptoms.contains('起则头眩')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '痰饮中焦（苓桂术甘汤证）',
        patternDetail: '心下逆满，气上冲胸，起则头眩，脉沉紧。',
        formula: '苓桂术甘汤',
        explanation: '茯苓利水，桂枝通阳，白术健脾，甘草调和。痰饮主方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 苓桂甘枣汤：脐下悸欲作奔豚
    if (_selectedSymptoms.contains('脐下悸') || _selectedSymptoms.contains('欲作奔豚')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '奔豚欲作（苓桂甘枣汤证）',
        patternDetail: '发汗后，其人脐下悸者，欲作奔豚。',
        formula: '苓桂甘枣汤',
        explanation: '茯苓利水，桂枝平冲，甘草大枣补中。奔豚预防方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 茯苓甘草汤：厥而心下悸
    if (answers['cold_limbs'] == true && _selectedSymptoms.contains('心下悸')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '水饮厥逆（茯苓甘草汤证）',
        patternDetail: '伤寒汗出而渴者，五苓散主之；不渴者，茯苓甘草汤主之。',
        formula: '茯苓甘草汤',
        explanation: '茯苓利水，桂枝通阳，生姜散水，甘草调和。水饮厥逆。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 黄芪桂枝五物汤：血痹身体不仁
    if (_selectedSymptoms.contains('身体不仁') || _selectedSymptoms.contains('血痹')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '血痹（黄芪桂枝五物汤证）',
        patternDetail: '血痹，阴阳俱微，外证身体不仁，如风痹状。',
        formula: '黄芪桂枝五物汤',
        explanation: '黄芪益气固表，桂枝芍药调营卫，生姜大枣和中。血痹专方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 桂枝加黄芪汤：黄汗
    if (_selectedSymptoms.contains('黄汗') || _selectedSymptoms.contains('汗沾衣色黄')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '黄汗（桂枝加黄芪汤证）',
        patternDetail: '黄汗之病，两胫自冷。汗沾衣，色正黄如柏汁。',
        formula: '桂枝加黄芪汤',
        explanation: '桂枝汤调和营卫，黄芪益气固表。黄汗主方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 瓜蒂散：胸中痞硬气上冲喉咽
    if (_selectedSymptoms.contains('胸中痞硬') && _selectedSymptoms.contains('气上冲')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '痰实胸中（瓜蒂散证）',
        patternDetail: '病如桂枝证，头不痛，项不强，寸脉微浮，胸中痞硬，气上冲喉咽。',
        formula: '瓜蒂散',
        explanation: '瓜蒂涌吐痰实，赤小豆催吐。胸中痰实，因势利导。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 十枣汤：悬饮（心下痞硬满引胁下痛）
    if (_selectedSymptoms.contains('心下痞硬') && _selectedSymptoms.contains('引胁下痛')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '悬饮（十枣汤证）',
        patternDetail: '太阳中风，下利呕逆，其人漐漐汗出，发作有时，心下痞硬满。',
        formula: '十枣汤',
        explanation: '芫花甘遂大戟攻逐水饮，大枣缓毒。悬饮峻下方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 栀子甘草豉汤/栀子生姜豉汤/栀子干姜豉汤
    // FIX-P1-2: misc 栀子豉系列（懊憹）条件过宽，遮蔽阳明栀子大黄汤（酒黄疸/身黄+心中热）。
    // 排除黄疸相关词：酒黄疸归栀子大黄汤，纯虚烦懊憹归本系列。
    if ((_selectedSymptoms.contains('心中懊憹') || _selectedSymptoms.contains('反复颠倒')) &&
        !_selectedSymptoms.contains('酒黄疸') &&
        !_selectedSymptoms.contains('身黄')) {
      if (answers['vomiting'] == true) {
        return DiagnosisResult(
          meridian: '阳明',
          pattern: '虚烦兼呕（栀子生姜豉汤证）',
          patternDetail: '虚烦不得眠，心中懊憹，兼呕。',
          formula: '栀子生姜豉汤',
          explanation: '栀子清热除烦，生姜止呕，香豉宣郁。虚烦兼呕。',
          confidence: 0.8,
          matchedSymptoms: _selectedSymptoms,
        );
      }
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '虚烦懊憹（栀子甘草豉汤证）',
        patternDetail: '虚烦不得眠，心中懊憹，兼少气。',
        formula: '栀子甘草豉汤',
        explanation: '栀子清热除烦，甘草益气，香豉宣郁。虚烦兼少气。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 麻子仁丸：脾约（大便硬+小便数+趺阳脉浮涩）
    if (answers['constipated'] == true && _selectedSymptoms.contains('小便数')) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '脾约（麻子仁丸证）',
        patternDetail: '趺阳脉浮而涩，浮则胃气强，涩则小便数，大便则硬。',
        formula: '麻子仁丸',
        explanation: '麻子仁润肠，大黄泻下，枳实厚朴行气，芍药养阴，杏仁润燥。脾约便秘。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 竹叶石膏汤：伤寒解后虚羸少气
    if (_selectedSymptoms.contains('虚羸少气') || _selectedSymptoms.contains('气逆欲吐')) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '余热未清（竹叶石膏汤证）',
        patternDetail: '伤寒解后，虚羸少气，气逆欲吐。',
        formula: '竹叶石膏汤',
        explanation: '竹叶石膏清余热，人参麦冬半夏甘草粳米益气生津。伤寒后期调理方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 厚朴七物汤：腹满发热脉浮数
    if (_selectedSymptoms.contains('腹满') && _answers['fever'] == true && _pulseType == '浮') {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '表里双解（厚朴七物汤证）',
        patternDetail: '病腹满，发热十日，脉浮而数，饮食如故。',
        formula: '厚朴七物汤',
        explanation: '厚朴三物汤攻里，桂枝汤解表。表里双解之腹满方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 大陷胸丸：结胸项亦强如柔痉状
    if (_selectedSymptoms.contains('结胸') && _selectedSymptoms.contains('项强')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '结胸项强（大陷胸丸证）',
        patternDetail: '结胸者，项亦强，如柔痉状，下之则和。',
        formula: '大陷胸丸',
        explanation: '大黄芒硝泻热，甘遂葶苈子逐水，杏仁开肺。结胸在上者。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 瓜蒂散已加，跳过一物瓜蒂汤

    // ========== 金匮要略·中风/历节 ==========

    // 千金三黄汤：中风手足拘急
    if (_selectedSymptoms.contains('手足拘急') && _selectedSymptoms.contains('百节疼痛')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '中风历节（千金三黄汤证）',
        patternDetail: '中风手足拘急，百节疼痛，烦热心乱，恶寒。',
        formula: '千金三黄汤',
        explanation: '麻黄细辛黄芪独活黄芩。中风手足拘急，表里同治。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 小续命汤：中风卒然不知人
    if (_selectedSymptoms.contains('中风') && _selectedSymptoms.contains('半身不遂')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '中风（小续命汤证）',
        patternDetail: '中风卒然不知人，手足拘急，或半身不遂，口眼歪斜。',
        formula: '小续命汤',
        explanation: '麻黄桂枝解表，防风祛风，人参附子补虚。中风通治方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 桂枝芍药知母汤：诸肢节疼痛尪羸
    if (_selectedSymptoms.contains('肢节疼痛') && _selectedSymptoms.contains('脚肿')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '历节尪羸（桂枝芍药知母汤证）',
        patternDetail: '诸肢节疼痛，身体尪羸，脚肿如脱，头眩短气。',
        formula: '桂枝芍药知母汤',
        explanation: '桂枝芍药知母附子麻黄，祛风除湿清热。历节尪羸主方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 桂枝附子汤：风湿相搏身体疼烦
    if (_selectedSymptoms.contains('身体疼烦') && _selectedSymptoms.contains('不能自转侧')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '风湿相搏（桂枝附子汤证）',
        patternDetail: '伤寒八九日，风湿相搏，身体疼烦，不能自转侧。',
        formula: '桂枝附子汤',
        explanation: '桂枝解表，附子温经散寒，白术祛湿。风湿在表。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 白术附子汤：风湿身体疼烦不能自转侧（与桂枝附子汤类似，偏于里湿）
    if (_selectedSymptoms.contains('身体疼烦') && answers['vomiting'] != true &&
        answers['thirsty'] != true) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '风湿里湿（白术附子汤证）',
        patternDetail: '伤寒八九日，风湿相搏，身体疼烦，不能自转侧，不呕不渴。',
        formula: '白术附子汤',
        explanation: '白术健脾祛湿，附子温经散寒。风湿在里，偏于湿者。',
        confidence: 0.75,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 甘草附子汤：风湿骨节疼烦掣痛
    if (_selectedSymptoms.contains('骨节疼烦') && _selectedSymptoms.contains('掣痛')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '风湿骨节（甘草附子汤证）',
        patternDetail: '风湿相搏，骨节疼烦，掣痛不得屈伸，近之则痛剧。',
        formula: '甘草附子汤',
        explanation: '甘草附子白术桂枝。风湿骨节疼烦，掣痛不得屈伸。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 防己茯苓汤：皮水四肢肿聂聂动
    if (_selectedSymptoms.contains('四肢肿') && _selectedSymptoms.contains('聂聂动')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '皮水（防己茯苓汤证）',
        patternDetail: '皮水为病，四肢肿，水气在皮肤中，四肢聂聂动。',
        formula: '防己茯苓汤',
        explanation: '防己茯苓利水，黄芪益气固表，桂枝通阳。皮水专方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 越婢汤：风水恶风一身悉肿
    if (_selectedSymptoms.contains('风水') && _selectedSymptoms.contains('一身悉肿')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '风水（越婢汤证）',
        patternDetail: '风水恶风，一身悉肿，脉浮不渴，续自汗出。',
        formula: '越婢汤',
        explanation: '麻黄石膏解表清热，生姜大枣甘草调和。风水主方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 越婢加术汤：里水身肿小便不利
    if (_selectedSymptoms.contains('身肿') && answers['urine_difficult'] == true) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '里水（越婢加术汤证）',
        patternDetail: '里水，越婢加术汤主之。',
        formula: '越婢加术汤',
        explanation: '越婢汤加白术。里水身肿，小便不利。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 甘草麻黄汤：皮水身面浮肿
    if (_selectedSymptoms.contains('身面浮肿') && answers['has_sweat'] != true) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '皮水（甘草麻黄汤证）',
        patternDetail: '皮水，身面浮肿，小便不利。',
        formula: '甘草麻黄汤',
        explanation: '麻黄发汗利水，甘草调和。皮水无汗者。',
        confidence: 0.75,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 木防己汤：膈间支饮心下痞坚
    if (_selectedSymptoms.contains('膈间支饮') || _selectedSymptoms.contains('心下痞坚')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '膈间支饮（木防己汤证）',
        patternDetail: '膈间支饮，其人喘满，心下痞坚，面色黧黑。',
        formula: '木防己汤',
        explanation: '防己桂枝通阳，石膏清热，人参补虚。支饮重证。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 栝蒌瞿麦丸：小便不利有水气苦渴
    if (answers['urine_difficult'] == true && answers['thirsty'] == true) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '水气苦渴（栝蒌瞿麦丸证）',
        patternDetail: '小便不利者，有水气，其人苦渴。',
        formula: '栝蒌瞿麦丸',
        explanation: '栝蒌瞿麦利水，附子温阳，茯苓山药健脾。肾虚水停。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // ========== 金匮要略·胸痹/心痛 ==========

    // 薏苡附子散：胸痹缓急
    if (_selectedSymptoms.contains('胸痹') && _selectedSymptoms.contains('缓急')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '胸痹缓急（薏苡附子散证）',
        patternDetail: '胸痹缓急者。胸痹发作有时。',
        formula: '薏苡附子散',
        explanation: '薏苡仁除湿，附子温阳。胸痹缓急，发作有时。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 桂枝生姜枳实汤：心中痞诸逆心悬痛
    if (_selectedSymptoms.contains('心中痞') && _selectedSymptoms.contains('心悬痛')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '心中痞逆（桂枝生姜枳实汤证）',
        patternDetail: '心中痞，诸逆，心悬痛。',
        formula: '桂枝生姜枳实汤',
        explanation: '桂枝通阳，生姜散寒，枳实行气。心中痞逆心悬痛。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 乌头赤石脂丸：心痛彻背背痛彻心
    if (_selectedSymptoms.contains('心痛彻背') || _selectedSymptoms.contains('背痛彻心')) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '阴寒心痛（乌头赤石脂丸证）',
        patternDetail: '心痛彻背，背痛彻心。阴寒瘤结。',
        formula: '乌头赤石脂丸',
        explanation: '乌头附子蜀椒干姜大热散寒，赤石脂固涩。阴寒心痛重证。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 枳实薤白桂枝汤已加，跳过

    // ========== 金匮要略·腹满/寒疝 ==========

    // 大建中汤：心胸中大寒痛呕不能食
    if (_selectedSymptoms.contains('心胸中大寒痛') || _selectedSymptoms.contains('上冲皮起')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '虚寒腹痛（大建中汤证）',
        patternDetail: '心胸中大寒痛，呕不能饮食，腹中寒，上冲皮起。',
        formula: '大建中汤',
        explanation: '蜀椒干姜温中散寒，人参饴糖补虚。虚寒腹痛重证。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 附子粳米汤：腹中寒气雷鸣切痛
    if (_selectedSymptoms.contains('雷鸣切痛') || _selectedSymptoms.contains('腹中寒气')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '腹中寒气（附子粳米汤证）',
        patternDetail: '腹中寒气，雷鸣切痛，胸胁逆满，呕吐。',
        formula: '附子粳米汤',
        explanation: '附子温阳，半夏止呕，粳米甘草大枣补中。腹中寒气雷鸣。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 厚朴三物汤已在阳明中加，跳过

    // 大黄附子汤已在少阴中加，跳过

    // 当归生姜羊肉汤：寒疝腹中痛胁痛里急
    if (_selectedSymptoms.contains('寒疝') && _selectedSymptoms.contains('胁痛里急')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '寒疝虚证（当归生姜羊肉汤证）',
        patternDetail: '寒疝腹中痛，及胁痛里急者。',
        formula: '当归生姜羊肉汤',
        explanation: '当归养血，生姜散寒，羊肉补虚。寒疝虚证，血虚寒凝。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 乌头桂枝汤：寒疝腹中痛逆冷手足不仁
    if (_selectedSymptoms.contains('寒疝') && _selectedSymptoms.contains('手足不仁')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '寒疝表里同病（乌头桂枝汤证）',
        patternDetail: '寒疝腹中痛，逆冷，手足不仁，若身疼痛。',
        formula: '乌头桂枝汤',
        explanation: '乌头散寒止痛，桂枝汤解表。寒疝兼表者。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 蜘蛛散：阴狐疝气
    if (_selectedSymptoms.contains('狐疝') || _selectedSymptoms.contains('偏有大小')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '狐疝（蜘蛛散证）',
        patternDetail: '阴狐疝气者，偏有大小，时时上下。',
        formula: '蜘蛛散',
        explanation: '蜘蛛破结通疝，桂枝温经。狐疝专方。',
        confidence: 0.75,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // ========== 金匮要略·痰饮/咳嗽 ==========

    // 小青龙汤加减：支饮咳逆倚息不得卧
    // FIX-P1-2: 小青龙加减（支饮兜底）条件过宽，遮蔽厚朴大黄汤（支饮+胸满）。加排除。
    if ((_selectedSymptoms.contains('支饮') || _selectedSymptoms.contains('咳逆倚息')) &&
        !_selectedSymptoms.contains('胸满')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '支饮（小青龙加减汤证）',
        patternDetail: '咳逆倚息不得卧。支饮水饮停于胸膈。',
        formula: '小青龙汤加减',
        explanation: '小青龙汤基础上随证加减。支饮主方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 越婢加半夏汤：肺胀喘目如脱状
    if (_selectedSymptoms.contains('肺胀') && _selectedSymptoms.contains('目如脱状')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '肺胀重证（越婢加半夏汤证）',
        patternDetail: '咳而上气，此为肺胀，其人喘，目如脱状。',
        formula: '越婢加半夏汤',
        explanation: '越婢汤解表清热，半夏化痰降逆。肺胀重证。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 葶苈大枣泻肺汤：肺痈喘不得卧
    if (_selectedSymptoms.contains('肺痈') && _selectedSymptoms.contains('喘不得卧')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '肺痈（葶苈大枣泻肺汤证）',
        patternDetail: '肺痈，喘不得卧。肺痈胸满胀。',
        formula: '葶苈大枣泻肺汤',
        explanation: '葶苈子泻肺逐痰，大枣护胃。肺痈喘不得卧。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 橘枳生姜汤：胸痹胸中气塞短气
    // FIX-P1-2: 排除短气（主短气者归茯苓杏仁甘草汤），橘枳生姜主行气、偏气塞。
    if (_selectedSymptoms.contains('胸痹') && _selectedSymptoms.contains('胸中气塞') &&
        !_selectedSymptoms.contains('短气')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '胸痹气塞（橘枳生姜汤证）',
        patternDetail: '胸痹，胸中气塞，短气。',
        formula: '橘枳生姜汤',
        explanation: '橘皮枳实行气，生姜散寒。胸痹气塞短气。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 茯苓杏仁甘草汤：胸痹胸中气塞短气
    if (_selectedSymptoms.contains('胸痹') && _selectedSymptoms.contains('短气')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '胸痹短气（茯苓杏仁甘草汤证）',
        patternDetail: '胸痹，胸中气塞，短气。',
        formula: '茯苓杏仁甘草汤',
        explanation: '茯苓利水，杏仁宣肺，甘草调和。胸痹水饮短气。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 半夏厚朴汤：妇人咽中如有炙脔
    if (_selectedSymptoms.contains('咽中如有炙脔') || _selectedSymptoms.contains('梅核气')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '梅核气（半夏厚朴汤证）',
        patternDetail: '妇人咽中如有炙脔。气滞痰凝。',
        formula: '半夏厚朴汤',
        explanation: '半夏化痰，厚朴行气，茯苓利水，生姜紫苏。梅核气专方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 泽泻汤：心下支饮苦冒眩
    if (_selectedSymptoms.contains('苦冒眩') || _selectedSymptoms.contains('支饮冒眩')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '支饮冒眩（泽泻汤证）',
        patternDetail: '心下有支饮，其人苦冒眩。',
        formula: '泽泻汤',
        explanation: '泽泻利水，白术健脾。支饮冒眩专方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 枳术汤：心下坚大如盘
    if (_selectedSymptoms.contains('心下坚') && _selectedSymptoms.contains('大如盘')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '水饮痞坚（枳术汤证）',
        patternDetail: '心下坚，大如盘，边如旋盘，水饮所作。',
        formula: '枳术汤',
        explanation: '枳实行气消痞，白术健脾。水饮痞坚。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 甘草干姜附子汤：昼日烦躁夜安静（已在少阴中加，跳过）

    // 麻黄附子细辛汤：少阴始得之反发热脉沉
    if (answers['drowsy'] == true && _answers['fever'] == true && _pulseType == '沉') {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '少阴兼表（麻黄附子细辛汤证）',
        patternDetail: '少阴病，始得之，反发热，脉沉者。',
        formula: '麻黄附子细辛汤',
        explanation: '麻黄解表，附子温经，细辛散寒。少阴兼表，太少两感。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 四逆加人参汤：霍乱吐利止后恶寒脉微
    if (_selectedSymptoms.contains('霍乱') || _selectedSymptoms.contains('吐利止')) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '亡阳液脱（四逆加人参汤证）',
        patternDetail: '霍乱，吐利止而身痛不休。恶寒脉微而复利，利止亡血。',
        formula: '四逆加人参汤',
        explanation: '四逆汤回阳，人参益气固脱。吐利后亡阳液脱。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 通脉四逆汤：少阴下利清谷里寒外热
    if (answers['diarrhea'] == true && _selectedSymptoms.contains('里寒外热')) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '阴盛格阳（通脉四逆汤证）',
        patternDetail: '少阴病，下利清谷，里寒外热，手足厥逆，脉微欲绝。',
        formula: '通脉四逆汤',
        explanation: '重用干姜附子回阳通脉。阴盛格阳，里寒外热重证。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 通脉四逆加猪胆汁汤：吐已下断脉微欲绝
    if (_selectedSymptoms.contains('吐已下断') || _selectedSymptoms.contains('四肢拘急')) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '阳亡阴竭（通脉四逆加猪胆汁汤证）',
        patternDetail: '吐已下断，汗出而厥，四肢拘急不解，脉微欲绝。',
        formula: '通脉四逆加猪胆汁汤',
        explanation: '通脉四逆汤回阳，猪胆汁反佐。阳亡阴竭重证。',
        confidence: 0.9,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 甘草干姜附子汤：昼日烦躁夜安静
    if (_selectedSymptoms.contains('昼日烦躁') && _selectedSymptoms.contains('夜安静')) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '阳虚烦躁（甘草干姜附子汤证）',
        patternDetail: '下之后，复发汗，昼日烦躁不得眠，夜而安静。',
        formula: '甘草干姜附子汤',
        explanation: '甘草干姜附子。昼日烦躁夜安静，阳虚阴盛。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 牡蛎泽泻散：大病差后腰以下水气
    if (_selectedSymptoms.contains('大病差后') && _selectedSymptoms.contains('腰以下水气')) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '病后水气（牡蛎泽泻散证）',
        patternDetail: '大病差后，从腰以下有水气。',
        formula: '牡蛎泽泻散',
        explanation: '牡蛎泽泻蜀漆葶苈子商陆根。大病后腰以下水气。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // ========== 金匮要略·黄疸 ==========

    // 茵陈五苓散：黄疸（湿重于热）
    if (_selectedSymptoms.contains('黄疸') && answers['urine_difficult'] == true) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '黄疸湿重（茵陈五苓散证）',
        patternDetail: '黄疸病，茵陈五苓散主之。',
        formula: '茵陈五苓散',
        explanation: '茵陈蒿利湿退黄，五苓散利水。黄疸湿重于热。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 硝石矾石散：女劳疸（膀胱急少腹满）
    if (_selectedSymptoms.contains('女劳') || _selectedSymptoms.contains('膀胱急')) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '女劳疸（硝石矾石散证）',
        patternDetail: '黄家日晡所发热，而反恶寒，此为女劳得之。',
        formula: '硝石矾石散',
        explanation: '硝石活血化瘀，矾石燥湿。女劳疸专方。',
        confidence: 0.75,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 猪膏髪煎：诸黄
    if (_selectedSymptoms.contains('诸黄') || _selectedSymptoms.contains('黄疸通用')) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '黄疸通治（猪膏髪煎证）',
        patternDetail: '诸黄，猪膏发煎主之。',
        formula: '猪膏髪煎',
        explanation: '猪膏润燥，乱发消瘀。黄疸通治方。',
        confidence: 0.7,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 大黄硝石汤：黄疸腹满小便不利而赤
    if (_selectedSymptoms.contains('黄疸') && _selectedSymptoms.contains('腹满') &&
        _selectedSymptoms.contains('小便赤')) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '黄疸里实（大黄硝石汤证）',
        patternDetail: '黄疸腹满，小便不利而赤，自汗出，此为表和里实。',
        formula: '大黄硝石汤',
        explanation: '大黄硝石栀子黄柏。黄疸里实，表和里实者。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // ========== 金匮要略·惊悸/吐衄/瘀血 ==========

    // 半夏麻黄丸：心下悸
    // FIX-P1-2: 半夏麻黄丸（心下悸）条件过宽，遮蔽六经桂枝甘草汤（心悸+有汗+脉虚）。
    // 加 has_sweat!=true 排除：有汗心悸归桂枝甘草汤，无汗水饮心悸归半夏麻黄丸。
    if (_selectedSymptoms.contains('心下悸') && !_selectedSymptoms.contains('水气') &&
        answers['has_sweat'] != true) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '心悸水饮（半夏麻黄丸证）',
        patternDetail: '心下悸者，半夏麻黄丸主之。',
        formula: '半夏麻黄丸',
        explanation: '半夏化痰，麻黄宣肺。心下悸水饮所致。',
        confidence: 0.75,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 柏叶汤：吐血不止
    if (_selectedSymptoms.contains('吐血') || _selectedSymptoms.contains('吐血不止')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '吐血（柏叶汤证）',
        patternDetail: '吐血不止者。',
        formula: '柏叶汤',
        explanation: '侧柏叶干姜艾叶。温经止血。吐血不止。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 泻心汤：心气不足吐血衄血
    if (_selectedSymptoms.contains('吐血衄血') || _selectedSymptoms.contains('心气不足')) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '热盛吐衄（泻心汤证）',
        patternDetail: '心气不足，吐血衄血。',
        formula: '泻心汤',
        explanation: '大黄黄连黄芩。苦寒泻火。热盛吐衄专方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 黄土汤：远血（先便后血）
    if (_selectedSymptoms.contains('先便后血') || _selectedSymptoms.contains('远血')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '脾虚便血（黄土汤证）',
        patternDetail: '下血，先便后血，此远血也。',
        formula: '黄土汤',
        explanation: '黄土（伏龙肝）温中止血，附子白术温脾。脾虚便血。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 赤小豆当归散：目赤如鸠眼（狐惑病）
    if (_selectedSymptoms.contains('目赤如鸠眼') || _selectedSymptoms.contains('狐惑')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '狐惑病（赤豆当归散证）',
        patternDetail: '病者脉数，无热，微烦，默默但欲卧，汗出，目赤如鸠眼。',
        formula: '赤豆当归散',
        explanation: '赤小豆当归。清热利湿，活血排脓。狐惑病目赤者。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 防己地黄汤：病如狂状妄行独语不休
    if (_selectedSymptoms.contains('如狂') && _selectedSymptoms.contains('独语不休')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '肝火如狂（防己地黄汤证）',
        patternDetail: '病如狂状，妄行，独语不休，无寒热，其脉浮。',
        formula: '防己地黄汤',
        explanation: '防己地黄桂枝防风。肝火如狂，脉浮者。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 大黄蟅虫丸：五劳虚极羸瘦内有干血
    if (_selectedSymptoms.contains('肌肤甲错') || _selectedSymptoms.contains('两目黯黑')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '干血劳（大黄蟅虫丸证）',
        patternDetail: '五劳虚极，羸瘦腹满，不能饮食。内有干血，肌肤甲错。',
        formula: '大黄蟅虫丸',
        explanation: '大黄蟅虫水蛭虻虫桃仁活血，地黄芍药养血。干血劳专方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 下瘀血汤：产后腹痛有干血着脐下
    // FIX-P1-2: 下瘀血（产后腹痛兜底）条件过宽，遮蔽枳实芍药散（产后腹痛+烦满不得卧）。加排除。
    if ((_selectedSymptoms.contains('产后腹痛') || _selectedSymptoms.contains('干血着脐下')) &&
        !_selectedSymptoms.contains('烦满不得卧')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '产后瘀血（下瘀血汤证）',
        patternDetail: '产后腹痛，腹中有干血着脐下。',
        formula: '下瘀血汤',
        explanation: '大黄桃仁蟅虫。活血逐瘀。产后瘀血腹痛。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 大黄甘遂汤：水与血俱结在血室
    if (_selectedSymptoms.contains('水与血俱结') || _selectedSymptoms.contains('血室')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '水血互结（大黄甘遂汤证）',
        patternDetail: '妇人少腹满如敦状，小便微难而不渴，此为水与血俱结在血室。',
        formula: '大黄甘遂汤',
        explanation: '大黄逐瘀，甘遂逐水，阿胶养血。水血互结血室。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 桃红四物汤：血虚兼血瘀
    if (_selectedSymptoms.contains('血虚兼血瘀') || _selectedSymptoms.contains('面色萎黄')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '血虚血瘀（桃红四物汤证）',
        patternDetail: '血虚兼血瘀证，面色萎黄，胸胁刺痛。',
        formula: '桃红四物汤',
        explanation: '四物汤养血，桃仁红花活血。血虚血瘀通用方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // ========== 金匮要略·妇人/妊娠 ==========

    // 桂枝茯苓丸：妇人宿有症病漏下
    if (_selectedSymptoms.contains('症病') || _selectedSymptoms.contains('漏下不止')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '症瘕（桂枝茯苓丸证）',
        patternDetail: '妇人宿有症病，经断未及三月，而得漏下不止。',
        formula: '桂枝茯苓丸',
        explanation: '桂枝芍药桃仁丹皮茯苓。活血化瘀消症。妇科症瘕专方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 温经汤已在杂病中加，跳过

    // 当归散：妊娠养胎
    if (_selectedSymptoms.contains('妊娠') && _selectedSymptoms.contains('养胎')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '妊娠养胎（当归散证）',
        patternDetail: '妇人妊娠，宜常服当归散。',
        formula: '当归散',
        explanation: '当归芍药黄芩白术川芎。妊娠养胎，安胎圣方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 白术散：妊娠养胎
    if (_selectedSymptoms.contains('妊娠') && _selectedSymptoms.contains('白术散')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '妊娠寒湿（白术散证）',
        patternDetail: '妊娠养胎，白术散主之。',
        formula: '白术散',
        explanation: '白术川芎蜀椒牡蛎。妊娠寒湿养胎。',
        confidence: 0.75,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 胶姜汤：妇人陷经漏下黑不解
    if (_selectedSymptoms.contains('漏下黑不解') || _selectedSymptoms.contains('陷经')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '虚寒漏下（胶姜汤证）',
        patternDetail: '妇人陷经，漏下黑不解。',
        formula: '胶姜汤',
        explanation: '阿胶干姜。温经止血。虚寒漏下。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 当归芍药散已在杂病中加，跳过

    // 矾石丸：妇人经水闭不利中有干血
    if (_selectedSymptoms.contains('经水闭不利') || _selectedSymptoms.contains('下白物')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '干血内停（矾石丸证）',
        patternDetail: '妇人经水闭不利，脏坚癖不止，中有干血，下白物。',
        formula: '矾石丸',
        explanation: '矾石杏仁。外用丸剂，化瘀消症。干血内停外治方。',
        confidence: 0.7,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 土瓜根散：带下经水不利少腹满痛
    if (_selectedSymptoms.contains('经水不利') && _selectedSymptoms.contains('少腹满痛')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '瘀血经不利（土瓜根散证）',
        patternDetail: '带下经水不利，少腹满痛，经一月再见者。',
        formula: '土瓜根散',
        explanation: '土瓜根芍药桂枝䗪虫。活血通经。瘀血经不利。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 竹叶汤：产后中风
    if (_selectedSymptoms.contains('产后中风') || _selectedSymptoms.contains('产后发热')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '产后中风（竹叶汤证）',
        patternDetail: '产后中风，发热，面正赤，喘而头痛。',
        formula: '竹叶汤',
        explanation: '竹叶葛根防风桂枝桔梗。产后中风表里同治。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 奔豚汤：奔豚气上冲胸腹痛往来寒热
    if (_selectedSymptoms.contains('奔豚') && _selectedSymptoms.contains('往来寒热')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '奔豚（奔豚汤证）',
        patternDetail: '奔豚气上冲胸，腹痛，往来寒热。',
        formula: '奔豚汤',
        explanation: '李根白皮葛根黄芩当归芍药川芎半夏。奔豚兼少阳。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // ========== 金匮要略·百合病 ==========

    // 百合地黄汤：百合病不经吐下发汗病形如初
    // FIX-P1-2: 百合地黄（基础方）条件过宽，把百合知母（发汗后）/滑石代赭（下之后）/
    // 滑石散（发热）/栝蒌牡蛎（渴）/鸡子黄（吐之后）全部遮蔽。加变证排除词。
    if ((_selectedSymptoms.contains('百合病') || _selectedSymptoms.contains('意欲食复不能食')) &&
        !_selectedSymptoms.contains('发汗后') &&
        !_selectedSymptoms.contains('下之后') &&
        !_selectedSymptoms.contains('吐之后') &&
        !_selectedSymptoms.contains('发热') &&
        answers['thirsty'] != true) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '百合病（百合地黄汤证）',
        patternDetail: '百合病，不经吐下发汗，病形如初。',
        formula: '百合地黄汤',
        explanation: '百合生地黄汁。养阴清热。百合病基础方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 百合知母汤：百合病发汗后
    if (_selectedSymptoms.contains('百合病') && _selectedSymptoms.contains('发汗后')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '百合病汗后（百合知母汤证）',
        patternDetail: '发汗后，百合病不解者。',
        formula: '百合知母汤',
        explanation: '百合知母。养阴清热。百合病发汗后。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 百合滑石代赭汤：百合病下之后
    if (_selectedSymptoms.contains('百合病') && _selectedSymptoms.contains('下之后')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '百合病下后（百合滑石代赭汤证）',
        patternDetail: '百合病下之后者。',
        formula: '百合滑石代赭汤',
        explanation: '百合滑石代赭石。养阴清热利湿。百合病攻下后。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 百合滑石散：百合病变发热
    if (_selectedSymptoms.contains('百合病') && _selectedSymptoms.contains('发热')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '百合病发热（百合滑石散证）',
        patternDetail: '百合病变发热者。',
        formula: '百合滑石散',
        explanation: '百合滑石。养阴清热。百合病发热。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 栝蒌牡蛎散：百合病变渴
    if (_selectedSymptoms.contains('百合病') && answers['thirsty'] == true) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '百合病渴（栝蒌牡蛎散证）',
        patternDetail: '百合病变渴者。',
        formula: '栝蒌牡蛎散',
        explanation: '栝蒌牡蛎。生津止渴。百合病口渴。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 百合鸡子黄汤：百合病吐之后
    if (_selectedSymptoms.contains('百合病') && _selectedSymptoms.contains('吐之后')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '百合病吐后（百合鸡子黄汤证）',
        patternDetail: '百合病，吐之后者。',
        formula: '百合鸡子黄汤',
        explanation: '百合鸡子黄。养阴和中。百合病催吐后。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // ========== 金匮要略·疮痈/肠痈 ==========

    // 大黄牡丹汤：肠痈
    // FIX-P1-2: 大黄牡丹（肠痈基础方）条件过宽，遮蔽薏苡附子败酱散（肠痈+脓已成）。加排除。
    if ((_selectedSymptoms.contains('肠痈') || _selectedSymptoms.contains('腹皮急按之濡')) &&
        !_selectedSymptoms.contains('脓已成')) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '肠痈（大黄牡丹汤证）',
        patternDetail: '肠痈之为病，其身甲错，腹皮急，按之濡，如肿状。',
        formula: '大黄牡丹汤',
        explanation: '大黄牡丹皮桃仁芒硝。泻热逐瘀。肠痈专方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 薏苡附子败酱散：肠痈脓已成
    if (_selectedSymptoms.contains('肠痈') && _selectedSymptoms.contains('脓已成')) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '肠痈脓成（薏苡附子败酱散证）',
        patternDetail: '肠痈之为病，其身甲错，腹皮急，按之濡。',
        formula: '薏苡附子败酱散',
        explanation: '薏苡仁败酱草排脓，附子温阳。肠痈脓已成。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 排脓散/排脓汤：疮痈脓已成
    if (_selectedSymptoms.contains('疮痈') && _selectedSymptoms.contains('脓已成')) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '疮痈排脓（排脓散/汤证）',
        patternDetail: '疮痈脓已成。',
        formula: '排脓散/排脓汤',
        explanation: '枳实芍药桔梗。排脓消痈。疮痈脓已成。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 升麻鳖甲汤：阳毒面赤斑斑如锦纹
    if (_selectedSymptoms.contains('阳毒') || _selectedSymptoms.contains('面赤斑斑如锦纹')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '阳毒（升麻鳖甲汤证）',
        patternDetail: '阳毒之为病，面赤斑斑如锦纹，咽喉痛，唾脓血。',
        formula: '升麻鳖甲汤',
        explanation: '升麻鳖甲当归蜀椒雄黄。清热解毒活血。阳毒专方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // ========== 金匮要略·呕吐/哕/下利 ==========

    // 小半夏汤：诸呕吐谷不得下
    if (answers['vomiting'] == true && _selectedSymptoms.contains('谷不得下')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '痰饮呕吐（小半夏汤证）',
        patternDetail: '诸呕吐，谷不得下者。',
        formula: '小半夏汤',
        explanation: '半夏生姜。化痰止呕。呕吐基础方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 小半夏加茯苓汤：卒呕吐心下痞膈间有水眩悸
    if (answers['vomiting'] == true && _selectedSymptoms.contains('膈间有水')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '痰饮眩悸（小半夏加茯苓汤证）',
        patternDetail: '卒呕吐，心下痞，膈间有水，眩悸者。',
        formula: '小半夏加茯苓汤',
        explanation: '小半夏汤加茯苓。化饮止呕。痰饮眩悸。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 大半夏汤：胃反朝食暮吐
    // FIX-P1-2: 大半夏（胃反兜底）条件过宽，遮蔽茯苓泽泻汤（胃反+渴）。加排除。
    if ((_selectedSymptoms.contains('胃反') || _selectedSymptoms.contains('朝食暮吐')) &&
        answers['thirsty'] != true) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '胃反（大半夏汤证）',
        patternDetail: '胃反呕吐者，朝食暮吐，暮食朝吐。',
        formula: '大半夏汤',
        explanation: '半夏降逆，人参白蜜补虚。胃反呕吐专方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 半夏干姜散：干呕吐逆吐涎沫
    if (answers['vomiting'] == true && _selectedSymptoms.contains('吐涎沫')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '胃寒呕吐（半夏干姜散证）',
        patternDetail: '干呕吐逆，吐涎沫。',
        formula: '半夏干姜散',
        explanation: '半夏干姜。温胃止呕。胃寒呕吐涎沫。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 生姜半夏汤：似喘不喘似呕不呕
    if (_selectedSymptoms.contains('似喘不喘') || _selectedSymptoms.contains('彻心中愦愦然无奈')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '痰饮郁膈（生姜半夏汤证）',
        patternDetail: '病人胸中似喘不喘，似呕不呕，似哕不哕。',
        formula: '生姜半夏汤',
        explanation: '生姜汁半夏。辛散开结。痰饮郁膈。',
        confidence: 0.75,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 橘皮汤：干呕哕手足厥（需排除厥阴证和少阴证）
    // 橘皮汤是轻证，仅用于单纯胃寒哕逆，不适用于厥阴寒逆或少阴证
    if (answers['vomiting'] == true && answers['cold_limbs'] == true &&
        answers['temperature'] != 'upper_heat_lower_cold' &&
        answers['drowsy'] != true &&  // 排除少阴（但欲寐）
        answers['headache_back'] != true) {  // 排除厥阴（吴茱萸汤证）
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '胃寒哕逆（橘皮汤证）',
        patternDetail: '干呕哕，若手足厥者。',
        formula: '橘皮汤',
        explanation: '橘皮生姜。理气止呕。胃寒哕逆手足冷。',
        confidence: 0.75,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 橘皮竹茹汤：哕逆
    if (_selectedSymptoms.contains('哕逆') || _selectedSymptoms.contains('呃逆')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '胃虚哕逆（橘皮竹茹汤证）',
        patternDetail: '哕逆者。',
        formula: '橘皮竹茹汤',
        explanation: '橘皮竹茹人参甘草生姜大枣。益气清热止哕。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 茯苓泽泻汤：胃反吐而渴欲饮水
    if (_selectedSymptoms.contains('胃反') && answers['thirsty'] == true) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '水饮胃反（茯苓泽泻汤证）',
        patternDetail: '胃反，吐而渴欲饮水者。',
        formula: '茯苓泽泻汤',
        explanation: '茯苓泽泻利水，白术桂枝健脾。水饮胃反。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 大黄甘草汤：食已即吐
    if (_selectedSymptoms.contains('食已即吐')) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '胃肠实热（大黄甘草汤证）',
        patternDetail: '食已即吐者。',
        formula: '大黄甘草汤',
        explanation: '大黄泻热，甘草缓和。食已即吐，胃肠实热。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 赤石脂禹余粮汤：下利不止心下痞硬
    if (answers['diarrhea'] == true && _selectedSymptoms.contains('下利不止')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '滑脱下利（赤石脂禹余粮汤证）',
        patternDetail: '伤寒服汤药，下利不止，心下痞硬。',
        formula: '赤石脂禹余粮汤',
        explanation: '赤石脂禹余粮。涩肠固脱。下利不止滑脱者。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 诃黎勒散：气利
    if (_selectedSymptoms.contains('气利') || _selectedSymptoms.contains('矢气时大便随之而出')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '气利（诃黎勒散证）',
        patternDetail: '气利。矢气时大便随之而出。',
        formula: '诃黎勒散',
        explanation: '诃黎勒涩肠固脱。气利专方。',
        confidence: 0.75,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 紫参汤：下利肺痛
    if (answers['diarrhea'] == true && _selectedSymptoms.contains('肺痛')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '下利肺痛（紫参汤证）',
        patternDetail: '下利肺痛者。',
        formula: '紫参汤',
        explanation: '紫参清热解毒，甘草和中。下利肺痛。',
        confidence: 0.7,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 白头翁加甘草阿胶汤：产后下利虚极
    if (_selectedSymptoms.contains('产后下利') || _selectedSymptoms.contains('下利虚极')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '产后热利（白头翁加甘草阿胶汤证）',
        patternDetail: '产后下利虚极。',
        formula: '白头翁加甘草阿胶汤',
        explanation: '白头翁汤清热止利，甘草阿胶养血。产后下利虚极。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // ========== 金匮要略·其他 ==========

    // 麦门冬汤：火逆上气咽喉不利
    if (_selectedSymptoms.contains('火逆上气') || _selectedSymptoms.contains('咽喉不利')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '虚火上炎（麦门冬汤证）',
        patternDetail: '火逆上气，咽喉不利，止逆下气者。',
        formula: '麦门冬汤',
        explanation: '麦冬半夏人参甘草粳米大枣。养阴清热降逆。虚火上炎。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 酸枣仁汤：虚劳虚烦不得眠
    if (answers['insomnia'] == true && _selectedSymptoms.contains('虚烦')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '虚劳失眠（酸枣仁汤证）',
        patternDetail: '虚劳虚烦不得眠。',
        formula: '酸枣仁汤',
        explanation: '酸枣仁养肝血，茯苓知母川芎甘草。虚劳失眠专方。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 甘草粉蜜汤：蛔虫吐涎心痛
    if (_selectedSymptoms.contains('蛔虫') || _selectedSymptoms.contains('心痛发作有时')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '蛔虫（甘草粉蜜汤证）',
        patternDetail: '蛔虫之为病，令人吐涎，心痛，发作有时。',
        formula: '甘草粉蜜汤',
        explanation: '甘草粉蜜。安蛔止痛。蛔虫心痛。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 鸡矢白散：转筋入腹
    if (_selectedSymptoms.contains('转筋') || _selectedSymptoms.contains('臂脚直')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '转筋（鸡矢白散证）',
        patternDetail: '转筋之为病，其人臂脚直，脉上下行，微弦。',
        formula: '鸡矢白散',
        explanation: '鸡矢白。通络缓急。转筋专方。',
        confidence: 0.7,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 蜀漆散：牝疟多寒
    if (_selectedSymptoms.contains('牝疟') || _selectedSymptoms.contains('疟多寒')) {
      return DiagnosisResult(
        meridian: '少阳',
        pattern: '牝疟（蜀漆散证）',
        patternDetail: '疟多寒者，名曰牝疟。',
        formula: '蜀漆散',
        explanation: '蜀漆云母龙骨。祛痰截疟。牝疟多寒。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 旋覆花汤：肝着常欲蹈其胸上
    if (_selectedSymptoms.contains('肝着') || _selectedSymptoms.contains('常欲蹈其胸上')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '肝着（旋覆花汤证）',
        patternDetail: '肝着，其人常欲蹈其胸上，先未苦时，但欲饮热。',
        formula: '旋覆花汤',
        explanation: '旋覆花葱新绛。通络散结。肝着专方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 枳实芍药散：产后腹痛烦满不得卧
    if (_selectedSymptoms.contains('产后腹痛') && _selectedSymptoms.contains('烦满不得卧')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '产后气滞（枳实芍药散证）',
        patternDetail: '产后腹痛，烦满不得卧。',
        formula: '枳实芍药散',
        explanation: '枳实行气，芍药养血。产后腹痛烦满。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 鳖甲煎丸：疟母
    if (_selectedSymptoms.contains('疟母') || _selectedSymptoms.contains('脾脏肿大')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '疟母（鳖甲煎丸证）',
        patternDetail: '疟母。疟疾日久，脾脏肿大，胁下有块。',
        formula: '鳖甲煎丸',
        explanation: '鳖甲柴胡黄芩等二十三味。消症化积。疟母专方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 黄连汤已在规则中加，跳过

    // 附子泻心汤：心下痞恶寒汗出
    if (_selectedSymptoms.contains('心下痞') && answers['cold_limbs'] == true) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '热痞兼阳虚（附子泻心汤证）',
        patternDetail: '心下痞，而复恶寒汗出者。',
        formula: '附子泻心汤',
        explanation: '大黄黄连黄芩清热消痞，附子温阳。寒热并用。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 柴胡桂枝汤：发热微恶寒支节烦疼微呕
    if (_selectedSymptoms.contains('支节烦疼') && answers['vomiting'] == true) {
      return DiagnosisResult(
        meridian: '少阳',
        pattern: '太阳少阳合病（柴胡桂枝汤证）',
        patternDetail: '发热，微恶寒，支节烦疼，微呕，心下支结。',
        formula: '柴胡桂枝汤',
        explanation: '小柴胡汤加桂枝。太少合病，表里双解。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 柴胡桂枝干姜汤：胸胁满微结小便不利
    if (_selectedSymptoms.contains('胸胁满微结') && answers['urine_difficult'] == true) {
      return DiagnosisResult(
        meridian: '少阳',
        pattern: '少阳太阴合病（柴胡桂枝干姜汤证）',
        patternDetail: '胸胁满微结，小便不利，渴而不呕。',
        formula: '柴胡桂枝干姜汤',
        explanation: '柴胡黄芩和解少阳，桂枝干姜温里。太少合病。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 柴胡加芒硝汤：日晡所发潮热
    if (_selectedSymptoms.contains('潮热') && _selectedSymptoms.contains('胸胁满')) {
      return DiagnosisResult(
        meridian: '少阳',
        pattern: '少阳阳明合病（柴胡加芒硝汤证）',
        patternDetail: '胸胁满而呕，日晡所发潮热。',
        formula: '柴胡加芒硝汤',
        explanation: '小柴胡汤加芒硝。少阳阳明合病，潮热者。',
        confidence: 0.85,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 黄芩加半夏生姜汤：太阳少阳合病下利而呕
    if (answers['diarrhea'] == true && answers['vomiting'] == true &&
        answers['bitter_mouth'] == true) {
      return DiagnosisResult(
        meridian: '少阳',
        pattern: '太少合病（黄芩加半夏生姜汤证）',
        patternDetail: '太阳与少阳合病，自下利者，兼呕。',
        formula: '黄芩加半夏生姜汤',
        explanation: '黄芩汤清热止利，半夏生姜降逆止呕。太少合病下利而呕。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 栀子枳实汤：大下后身热不去心中结痛
    if (_selectedSymptoms.contains('心中结痛') && _answers['fever'] == true) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '热郁胸膈（栀子枳实汤证）',
        patternDetail: '伤寒，大下后，身热不去，心中结痛。',
        formula: '栀子枳实汤',
        explanation: '栀子香豉枳实。清热除烦消痞。大下后热郁。',
        confidence: 0.75,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 文蛤散：渴欲饮水不止
    if (answers['thirsty'] == true && _selectedSymptoms.contains('饮水不止')) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '消渴（文蛤散证）',
        patternDetail: '渴欲饮水不止者。',
        formula: '文蛤散',
        explanation: '文蛤。生津止渴。渴饮不止。',
        confidence: 0.7,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 枳实栀子豉汤：大病差后劳复
    if (_selectedSymptoms.contains('劳复') || _selectedSymptoms.contains('大病差后')) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '劳复（枳实栀子豉汤证）',
        patternDetail: '大病差后，劳复者。',
        formula: '枳实栀子豉汤',
        explanation: '枳实栀子香豉。清热除烦。大病后劳复。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 厚朴大黄汤：支饮胸满
    if (_selectedSymptoms.contains('支饮') && _selectedSymptoms.contains('胸满')) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '支饮胸满（厚朴大黄汤证）',
        patternDetail: '支饮胸满者。',
        formula: '厚朴大黄汤',
        explanation: '厚朴枳实大黄。泻下逐饮。支饮胸满。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 甘姜苓术汤：肾着之病腰中冷
    if (_selectedSymptoms.contains('腰中冷') || _selectedSymptoms.contains('肾着')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '肾着（甘姜苓术汤证）',
        patternDetail: '肾着之病，其人身体重，腰中冷，如坐水中。',
        formula: '甘姜苓术汤',
        explanation: '干姜茯苓白术甘草。温脾散寒。肾着腰冷。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 苓甘五味姜辛汤系列：痰饮咳嗽
    if (_selectedSymptoms.contains('痰饮咳嗽') || _selectedSymptoms.contains('咳满')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '痰饮咳嗽（苓甘五味姜辛汤证）',
        patternDetail: '咳满即止，而更复渴，冲气复发。',
        formula: '苓甘五味姜辛汤',
        explanation: '茯苓甘草五味子干姜细辛。温肺化饮。痰饮咳嗽。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 蒲灰散：小便不利（排除有明确经络归属的情况）
    // FIX-P1-2: 蒲灰（小便不利兜底）条件过宽，把滑石白鱼散（白鱼）/茯苓戎盐汤（戎盐）/
    // 葵子茯苓散（妊娠）全部遮蔽。加专属症状词排除。
    if (answers['urine_difficult'] == true &&
        answers['edema'] != true &&
        answers['cold_limbs'] != true &&
        answers['drowsy'] != true &&
        answers['diarrhea'] != true &&
        !_selectedSymptoms.contains('白鱼') &&
        !_selectedSymptoms.contains('戎盐') &&
        !_selectedSymptoms.contains('妊娠')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '小便不利（蒲灰散证）',
        patternDetail: '小便不利，蒲灰散主之。',
        formula: '蒲灰散',
        explanation: '蒲灰滑石。利水通淋。小便不利。',
        confidence: 0.7,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 滑石白鱼散：小便不利
    if (answers['urine_difficult'] == true && _selectedSymptoms.contains('白鱼')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '小便不利（滑石白鱼散证）',
        patternDetail: '小便不利，滑石白鱼散主之。',
        formula: '滑石白鱼散',
        explanation: '滑石白鱼乱发。利水止血。小便不利兼血淋。',
        confidence: 0.7,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 茯苓戎盐汤：小便不利
    if (answers['urine_difficult'] == true && _selectedSymptoms.contains('戎盐')) {
      return DiagnosisResult(
        meridian: '太阳',
        pattern: '小便不利（茯苓戎盐汤证）',
        patternDetail: '小便不利，茯苓戎盐汤主之。',
        formula: '茯苓戎盐汤',
        explanation: '茯苓白术戎盐。健脾利水。小便不利脾虚者。',
        confidence: 0.7,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 葵子茯苓散：妊娠水气身重小便不利
    if (_selectedSymptoms.contains('妊娠') && answers['urine_difficult'] == true) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '妊娠水肿（葵子茯苓散证）',
        patternDetail: '妊娠有水气，身重，小便不利，洒淅恶寒。',
        formula: '葵子茯苓散',
        explanation: '葵子茯苓。利水通阳。妊娠水肿。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 当归贝母苦参丸：妊娠小便难
    if (_selectedSymptoms.contains('妊娠') && _selectedSymptoms.contains('小便难')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '妊娠小便难（当归贝母苦参丸证）',
        patternDetail: '妊娠，小便难，饮食如故。',
        formula: '当归贝母苦参丸',
        explanation: '当归贝母苦参。润燥清热。妊娠小便难。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 己椒苈黄丸：腹满口舌干燥肠间有水气
    if (_selectedSymptoms.contains('腹满') && _selectedSymptoms.contains('口舌干燥')) {
      return DiagnosisResult(
        meridian: '阳明',
        pattern: '肠间水气（己椒苈黄丸证）',
        patternDetail: '腹满，口舌干燥，此肠间有水气。',
        formula: '己椒苈黄丸',
        explanation: '防己椒目葶苈子大黄。攻下逐水。肠间水气。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 甘遂半夏汤：留饮欲去利反快
    if (_selectedSymptoms.contains('留饮') || _selectedSymptoms.contains('利反快')) {
      return DiagnosisResult(
        meridian: '太阴',
        pattern: '留饮（甘遂半夏汤证）',
        patternDetail: '病者脉伏，其人欲自利，利反快，虽利，心下续坚满。',
        formula: '甘遂半夏汤',
        explanation: '甘遂半夏芍药甘草。攻逐留饮。留饮欲去。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 防己地黄汤已在前面加，跳过

    // 侯氏黑散：大风四肢烦重
    if (_selectedSymptoms.contains('四肢烦重') || _selectedSymptoms.contains('大风')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '大风（侯氏黑散证）',
        patternDetail: '大风四肢烦重，心中恶寒不足者。',
        formula: '侯氏黑散',
        explanation: '菊花白术防风细辛等。祛风补虚。大风四肢烦重。',
        confidence: 0.75,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 风引汤：大人风引少小惊痫
    if (_selectedSymptoms.contains('惊痫') || _selectedSymptoms.contains('瘛疭')) {
      return DiagnosisResult(
        meridian: '厥阴',
        pattern: '风痫（风引汤证）',
        patternDetail: '大人风引，少小惊痫瘛疭，日数十发。',
        formula: '风引汤',
        explanation: '大黄干姜龙骨桂枝等。重镇熄风。惊痫瘛疭。',
        confidence: 0.75,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 天雄散：男子失精腰膝冷痛
    // FIX-P1-2: 天雄散（失精||腰膝冷痛）条件过宽，遮蔽六经桂枝加龙骨牡蛎汤
    // （虚劳失精+目眩+有汗）。加 has_sweat!=true：有汗虚劳失精归桂枝加龙骨牡蛎汤。
    if ((_selectedSymptoms.contains('失精') || _selectedSymptoms.contains('腰膝冷痛')) &&
        answers['has_sweat'] != true) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '失精（天雄散证）',
        patternDetail: '男子失精，腰膝冷痛。',
        formula: '天雄散',
        explanation: '天雄白术桂枝龙骨。温阳固精。失精腰冷。',
        confidence: 0.75,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 赤丸：寒气厥逆
    if (_selectedSymptoms.contains('寒气厥逆') || _selectedSymptoms.contains('赤丸')) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '寒气厥逆（赤丸证）',
        patternDetail: '寒气厥逆。',
        formula: '赤丸',
        explanation: '乌头茯苓半夏细辛。散寒止痛。寒气厥逆。',
        confidence: 0.75,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 术附汤：排脓（末期乳癌）
    if (_selectedSymptoms.contains('排脓') && _selectedSymptoms.contains('乳癌')) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '排脓（术附汤证）',
        patternDetail: '乳房周围黑色脓肿期排脓。',
        formula: '术附汤',
        explanation: '白术附子。温阳排脓。阴证疮疡排脓。',
        confidence: 0.7,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 阳和汤：阴疽贴骨疽鹤膝风
    if (_selectedSymptoms.contains('阴疽') || _selectedSymptoms.contains('贴骨疽') ||
        _selectedSymptoms.contains('鹤膝风')) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '阴疽（阳和汤证）',
        patternDetail: '阴疽，贴骨疽，鹤膝风。阴寒凝滞。',
        formula: '阳和汤',
        explanation: '熟地鹿角胶肉桂炮姜麻黄白芥子甘草。温阳补血散寒。阴疽专方。',
        confidence: 0.8,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 附子散：小儿足烂疮阴证疮疡
    if (_selectedSymptoms.contains('足烂疮') || _selectedSymptoms.contains('阴证疮疡')) {
      return DiagnosisResult(
        meridian: '少阴',
        pattern: '阴证疮疡（附子散证）',
        patternDetail: '小儿足烂疮，阴证疮疡。',
        formula: '附子散',
        explanation: '附子。温阳散寒。阴证疮疡外敷。',
        confidence: 0.7,
        matchedSymptoms: _selectedSymptoms,
      );
    }

    // 柏叶汤已加，跳过

    // 麦门冬汤已加，跳过

    // 薏苡附子散已加，跳过

    return null;
  }

  bool get isComplete => _stage == DiagnosticStage.result;
}
