import '../models/diagnosis.dart';

// ==================== 数据类 ====================

class SymptomOption {
  final String key;
  final String label;
  final String emoji;
  final String description;

  SymptomOption({
    required this.key,
    required this.label,
    this.emoji = '',
    this.description = '',
  });
}

class TemperatureOption {
  final String key;
  final String label;
  final String description;
  final String targetMeridian;

  TemperatureOption({
    required this.key,
    required this.label,
    required this.description,
    required this.targetMeridian,
  });
}

class FollowUpQuestion {
  final String key;
  final String question;
  final List<String> options;

  const FollowUpQuestion({
    required this.key,
    required this.question,
    required this.options,
  });
}

class CombinedPattern {
  final List<String> meridians;
  final String condition;
  final String formula;
  final String description;
  final String source;

  const CombinedPattern({
    required this.meridians,
    required this.condition,
    required this.formula,
    required this.description,
    required this.source,
  });
}

class DifferentialDiagnosis {
  final String name1;
  final String formula1;
  final String name2;
  final String formula2;
  final String keyDifference;
  final Map<String, String> details;

  DifferentialDiagnosis({
    required this.name1,
    required this.formula1,
    required this.name2,
    required this.formula2,
    required this.keyDifference,
    required this.details,
  });
}

class CareAdvice {
  final List<String> diet;
  final List<String> rest;
  final List<String> moxibustion;
  final List<String> avoid;

  CareAdvice({
    required this.diet,
    required this.rest,
    required this.moxibustion,
    required this.avoid,
  });
}

// ==================== 诊断规则 ====================

class DiagnosticRules {
  // ==================== 症状权重表 ====================
  static const Map<String, double> symptomWeights = {
    // 太阳病核心（高权重）
    'pulse_float': 0.9,
    'headache': 0.8,
    'neck_stiff': 0.8,
    'chills': 0.9,
    'body_pain': 0.7,
    'no_sweat': 0.85,
    'fever_chills': 0.9,
    // 阳明病核心
    'high_fever': 0.9,
    'no_chills': 0.85,
    'sweating': 0.7,
    'thirst_strong': 0.8,
    'pulse_large': 0.8,
    'constipated': 0.75,
    // 少阳病核心
    'bitter_mouth': 0.9,
    'dry_throat': 0.85,
    'dizziness': 0.7,
    'alternating_chills': 0.9,
    'chest_flank_fullness': 0.85,
    'nausea_vomiting': 0.7,
    // 太阴病核心
    'abdominal_pain': 0.8,
    'diarrhea': 0.75,
    'no_thirst': 0.8,
    'tongue_pale_coated_white': 0.85,
    // 少阴病核心
    'drowsy': 0.95,
    'pulse_thin_weak': 0.9,
    'cold_limbs': 0.85,
    'clear_urine': 0.7,
    'diarrhea_clear': 0.8,
    // 厥阴病核心
    'thirst_no_drink': 0.9,
    'upper_heat_lower_cold': 0.85,
    'hunger_no_eat': 0.8,
    'vomit_roundworm': 0.95,
    // FIX-P3: 扩充证据闸白名单——以下真实辨证标志此前不计入 P0-2 证据闸计数，
    // 导致"心下痞按之濡""小便不利+心烦失眠"等典型经方输入被静默建议面诊。
    // 权重取 0.5~0.6（低于六经核心主证，避免扭曲置信度排序）。
    'has_sweat': 0.6,
    'abdomen_pain_press': 0.5,
    'abdomen_pain_relief': 0.5,
    'urine_difficult': 0.5,
    'irritable': 0.5,
    'insomnia': 0.5,
    'edema': 0.5,
    'cough': 0.5,
    'vomiting': 0.5,
    'joint_pain': 0.5,
    'palpitation': 0.6,
    'history_mistreatment': 0.5,
  };

  // ==================== 合病/并病规则 ====================
  static const List<CombinedPattern> combinedPatterns = [
    CombinedPattern(
      meridians: ['太阳', '阳明'],
      condition: 'sun_symptoms + yangming_symptoms',
      formula: '葛根汤',
      description: '太阳与阳明合病，必自下利',
      source: '伤寒论第32条',
    ),
    CombinedPattern(
      meridians: ['太阳', '少阳'],
      condition: 'sun_symptoms + shao_yang_symptoms',
      formula: '柴胡桂枝汤',
      description: '太阳少阳合病，发热微恶寒，支节烦痛，微呕',
      source: '伤寒论第109条',
    ),
    CombinedPattern(
      meridians: ['少阳', '阳明'],
      condition: 'shao_yang_symptoms + yangming_symptoms',
      formula: '大柴胡汤',
      description: '少阳阳明合病，呕不止，心下急',
      source: '伤寒论第116条',
    ),
    CombinedPattern(
      meridians: ['太阳', '阳明', '少阳'],
      condition: 'three_yang_symptoms',
      formula: '小柴胡汤',
      description: '三阳并病，必须合解少阳',
      source: '伤寒论第99条',
    ),
    CombinedPattern(
      meridians: ['太阴', '少阴'],
      condition: 'taiyin_symptoms + shaoyin_symptoms',
      formula: '四逆汤',
      description: '太阴少阴合病，脾肾阳虚',
      source: '临床经验',
    ),
    // ---- 以下为新增7种合病 ----
    CombinedPattern(
      meridians: ['太阳', '阳明'],
      condition: 'sun+yangming_vomit',
      formula: '葛根加半夏汤',
      description: '太阳阳明合病，不下利但呕者',
      source: '伤寒论第37条',
    ),
    CombinedPattern(
      meridians: ['太阳', '阳明'],
      condition: 'sun+yangming_chest_full',
      formula: '麻黄汤',
      description: '太阳阳明合病，喘而胸满',
      source: '伤寒论第40条',
    ),
    CombinedPattern(
      meridians: ['太阳', '少阳'],
      condition: 'sun+shaoyang_diarrhea',
      formula: '黄芩汤',
      description: '太阳少阳合病，自下利',
      source: '伤寒论第172条',
    ),
    CombinedPattern(
      meridians: ['太阳', '少阳'],
      condition: 'sun+shaoyang_vomit',
      formula: '黄芩加半夏生姜汤',
      description: '太阳少阳合病，呕者',
      source: '伤寒论第172条',
    ),
    CombinedPattern(
      meridians: ['少阳', '阳明'],
      condition: 'shaoyang+yangming_tidal_fever',
      formula: '柴胡加芒硝汤',
      description: '少阳阳明合病，潮热',
      source: '伤寒论第104条',
    ),
    CombinedPattern(
      meridians: ['阳明', '少阴'],
      condition: 'yangming+shaoyin_urgent',
      formula: '大承气汤',
      description: '少阴病得之二三日，口燥咽干者，急下之',
      source: '伤寒论第320条',
    ),
    CombinedPattern(
      meridians: ['厥阴', '少阳'],
      condition: 'jueyin+shaoyang',
      formula: '乌梅丸',
      description: '厥阴少阳合病，寒热错杂',
      source: '临床经验',
    ),
    CombinedPattern(
      meridians: ['太阳', '阳明'],
      condition: 'sun+yangming_unresolved',
      formula: '桂枝汤',
      description: '二阳并病，太阳证未罢，面色缘缘正赤，当小发汗',
      source: '伤寒论第53条',
    ),
    CombinedPattern(
      meridians: ['太阳', '阳明', '少阳'],
      condition: 'three_yang_sleep',
      formula: '小柴胡汤',
      description: '三阳合病，脉浮大上关上，但欲眠睡，目合则汗',
      source: '伤寒论第268条',
    ),
    // ---- 补充2种合病（测试发现缺失）----
    CombinedPattern(
      meridians: ['太阳', '阳明'],
      condition: 'sun+yangming_interior_heat',
      formula: '大青龙汤',
      description: '太阳阳明合病，表寒里热俱实，无汗恶寒身痛+口渴烦躁',
      source: '伤寒论第38条',
    ),
    CombinedPattern(
      meridians: ['太阳', '少阴'],
      condition: 'sun+shaoyin_two_cold',
      formula: '麻黄附子细辛汤',
      description: '太阳少阴两感，始得之，发热恶寒脉沉',
      source: '伤寒论第301条',
    ),
    // ---- 新增合病（来自六经辨证公式）----
    CombinedPattern(
      meridians: ['少阳', '太阴'],
      condition: 'shaoyang+taiyin',
      formula: '柴胡桂枝干姜汤',
      description: '少阳太阴合病，往来寒热+腹满便溏食不下',
      source: '伤寒论第147条',
    ),
    CombinedPattern(
      meridians: ['太阳', '太阴'],
      condition: 'sun+taiyin',
      formula: '桂枝人参汤',
      description: '太阳太阴并病，里虚寒+表证未罢',
      source: '伤寒论第163条',
    ),
    CombinedPattern(
      meridians: ['太阳', '阳明'],
      condition: 'sun+yangming_diarrhea_heat',
      formula: '葛根芩连汤',
      description: '太阳阳明合病，表证轻里热重，下利臭秽',
      source: '伤寒论第34条',
    ),
  ];

  // ==================== 症状→方剂 数据表（P2-1：零代码增方） ====================
  // 引擎在规则弱命中时查阅此表作提示；新增方剂只需在此加一行，无需改引擎逻辑。
  static const Map<String, String> symptomFormulaHints = {
    '但欲寐': '四逆汤',
    '下利清谷': '四逆汤',
    '往来寒热': '小柴胡汤',
    '口苦咽干目眩': '小柴胡汤',
    '胸胁苦满': '小柴胡汤',
    '消渴': '乌梅丸',
    '气上撞心': '乌梅丸',
    '心下痞': '半夏泻心汤',
    '大热大渴': '白虎汤',
    '腹满燥实': '大承气汤',
    '头痛吐涎沫': '吴茱萸汤',
    '心悸头眩身瞤动': '真武汤',
    '发热恶寒无汗': '麻黄汤',
    '发热恶风有汗': '桂枝汤',
  };

  // ==================== 鉴别诊断表 ====================
  static final Map<String, DifferentialDiagnosis> differentialDiagnoses = {
    '太阳中风_vs_伤寒': DifferentialDiagnosis(
      name1: '太阳中风',
      formula1: '桂枝汤',
      name2: '太阳伤寒',
      formula2: '麻黄汤',
      keyDifference: '有汗无汗',
      details: {
        '中风': '有汗、恶风、脉浮缓',
        '伤寒': '无汗、恶寒、脉浮紧',
      },
    ),
    '苓桂术甘_vs_真武': DifferentialDiagnosis(
      name1: '苓桂术甘汤证',
      formula1: '苓桂术甘汤',
      name2: '真武汤证',
      formula2: '真武汤',
      keyDifference: '水饮位置与阳虚程度',
      details: {
        '苓桂术甘': '中膈水饮、起则头眩、脉沉紧',
        '真武': '全身阳虚、躺着也晕、脉细小而迟、脚冷',
      },
    ),
    '大青龙_vs_小青龙': DifferentialDiagnosis(
      name1: '大青龙汤证',
      formula1: '大青龙汤',
      name2: '小青龙汤证',
      formula2: '小青龙汤',
      keyDifference: '里热里寒',
      details: {
        '大青龙': '表寒里热、烦躁、黄痰',
        '小青龙': '表寒里寒、白沫痰、不渴',
      },
    ),
    '白虎_承气': DifferentialDiagnosis(
      name1: '白虎汤证',
      formula1: '白虎汤',
      name2: '承气汤证',
      formula2: '承气汤',
      keyDifference: '大便是否燥结',
      details: {
        '白虎': '大热大渴、大便正常',
        '承气': '腹满燥实、大便不通',
      },
    ),
    // ---- 以下为新增6对鉴别诊断 ----
    '小柴胡_vs_大柴胡': DifferentialDiagnosis(
      name1: '小柴胡汤证',
      formula1: '小柴胡汤',
      name2: '大柴胡汤证',
      formula2: '大柴胡汤',
      keyDifference: '有无便秘',
      details: {
        '小柴胡': '口苦咽干目眩、往来寒热、胸胁苦满、大便正常',
        '大柴胡': '呕不止、心下急、郁郁微烦、大便秘结',
      },
    ),
    '桂枝加附子_vs_真武': DifferentialDiagnosis(
      name1: '桂枝加附子汤证',
      formula1: '桂枝加附子汤',
      name2: '真武汤证',
      formula2: '真武汤',
      keyDifference: '表虚程度与阳虚范围',
      details: {
        '桂枝加附子': '表阳虚、汗出不止、恶风、四肢微急',
        '真武': '里阳虚、心悸头眩、身瞤动、小便不利、四肢沉重',
      },
    ),
    '四逆_vs_通脉四逆': DifferentialDiagnosis(
      name1: '四逆汤证',
      formula1: '四逆汤',
      name2: '通脉四逆汤证',
      formula2: '通脉四逆汤',
      keyDifference: '有无阴盛格阳',
      details: {
        '四逆': '四肢厥逆、脉微欲绝、下利清谷',
        '通脉四逆': '身反不恶寒、面色赤、阴盛格阳于外',
      },
    ),
    '理中_vs_四逆': DifferentialDiagnosis(
      name1: '理中汤证',
      formula1: '理中汤',
      name2: '四逆汤证',
      formula2: '四逆汤',
      keyDifference: '脾虚寒湿 vs 脾肾俱虚',
      details: {
        '理中': '腹满吐利、食不下、时腹自痛、病在中焦',
        '四逆': '四肢厥逆、脉微欲绝、下利清谷、病在下焦',
      },
    ),
    '麻黄_vs_麻杏甘石': DifferentialDiagnosis(
      name1: '麻黄汤证',
      formula1: '麻黄汤',
      name2: '麻杏甘石汤证',
      formula2: '麻杏甘石汤',
      keyDifference: '表寒闭肺 vs 肺热壅盛',
      details: {
        '麻黄': '恶寒无汗、体痛呕逆、脉浮紧、咳喘',
        '麻杏甘石': '汗出而喘、无大热、口渴、痰黄',
      },
    ),
    '五苓_vs_猪苓': DifferentialDiagnosis(
      name1: '五苓散证',
      formula1: '五苓散',
      name2: '猪苓汤证',
      formula2: '猪苓汤',
      keyDifference: '水气不化 vs 阴虚水热',
      details: {
        '五苓': '口渴、小便不利、水入则吐、脉浮',
        '猪苓': '渴欲饮水、小便不利、心烦不得眠、咳呕',
      },
    ),
    // ---- 以下为倪海厦skill知识库扩展鉴别 ----
    '茯苓四逆_vs_干姜附子': DifferentialDiagnosis(
      name1: '茯苓四逆汤证',
      formula1: '茯苓四逆汤',
      name2: '干姜附子汤证',
      formula2: '干姜附子汤',
      keyDifference: '阴阳两虚烦躁 vs 纯阳虚',
      details: {
        '茯苓四逆': '烦躁、四逆、阴阳两虚、水气上冲',
        '干姜附子': '昼日烦躁不得眠、夜而安静、脉沉微、纯阳虚',
      },
    ),
    '真武_vs_附子汤': DifferentialDiagnosis(
      name1: '真武汤证',
      formula1: '真武汤',
      name2: '附子汤证',
      formula2: '附子汤',
      keyDifference: '阳虚水泛 vs 气虚骨痛',
      details: {
        '真武': '心下悸、头眩、身瞤动、振振欲擗地、阳虚水泛',
        '附子': '身体痛、手足寒、骨节痛、气虚寒凝',
      },
    ),
    '桂枝加附子_vs_桂枝去芍药_vs_新加汤': DifferentialDiagnosis(
      name1: '桂枝加附子汤证',
      formula1: '桂枝加附子汤',
      name2: '桂枝去芍药/新加汤',
      formula2: '桂枝去芍药汤/桂枝新加汤',
      keyDifference: '汗不止 vs 胸满 vs 身痛',
      details: {
        '桂枝加附子': '汗出不止、恶风、小便难、四肢微急（收表）',
        '桂枝去芍药': '脉促、胸满（心脏病不用芍药）',
        '桂枝新加汤': '身疼痛、脉沉迟（津液伤、重芍药加人参）',
      },
    ),
    '栀子豉_vs_黄连阿胶': DifferentialDiagnosis(
      name1: '栀子豉汤证',
      formula1: '栀子豉汤',
      name2: '黄连阿胶汤证',
      formula2: '黄连阿胶汤',
      keyDifference: '余热虚烦 vs 心血不足',
      details: {
        '栀子豉': '虚烦不得眠、反复颠倒、心中懊憹、舌淡黄脉无力',
        '黄连阿胶': '心中烦不得卧、中空脉、舌黄干、心肾不交',
      },
    ),
    '半夏泻心_vs_生姜泻心_vs_甘草泻心': DifferentialDiagnosis(
      name1: '半夏泻心汤证',
      formula1: '半夏泻心汤',
      name2: '生姜/甘草泻心汤证',
      formula2: '生姜泻心汤/甘草泻心汤',
      keyDifference: '痞证三型鉴别',
      details: {
        '半夏泻心': '心下痞+腹痛+肠鸣（治痞主方）',
        '生姜泻心': '心下痞+严重下利+肠鸣重（重用生姜排水）',
        '甘草泻心': '心下痞+恶心、无肠鸣无腹痛（去黄连）',
      },
    ),
    '乌梅丸_vs_当归四逆': DifferentialDiagnosis(
      name1: '乌梅丸证',
      formula1: '乌梅丸',
      name2: '当归四逆汤证',
      formula2: '当归四逆汤',
      keyDifference: '寒热错杂 vs 血虚寒凝',
      details: {
        '乌梅丸': '消渴、气上撞心、心中疼热、饥而不欲食（寒热错杂）',
        '当归四逆': '手足厥寒、脉细欲绝、月经不来（血虚寒凝）',
      },
    ),
    '栀子豉_vs_白虎': DifferentialDiagnosis(
      name1: '栀子豉汤证',
      formula1: '栀子豉汤',
      name2: '白虎汤证',
      formula2: '白虎汤',
      keyDifference: '虚热 vs 实热',
      details: {
        '栀子豉': '虚烦、舌苔淡黄、脉无力重按不见（余热未尽）',
        '白虎': '大热大渴、舌苔黄且干燥、脉洪大（阳明实热）',
      },
    ),
    '四逆_vs_茯苓四逆_vs_干姜附子': DifferentialDiagnosis(
      name1: '四逆汤证',
      formula1: '四逆汤',
      name2: '茯苓四逆/干姜附子',
      formula2: '茯苓四逆汤/干姜附子汤',
      keyDifference: '回阳三方鉴别',
      details: {
        '四逆': '四逆、下利清谷、脉微欲绝（回阳救逆基础方）',
        '茯苓四逆': '四逆+烦躁（阴阳两虚，茯苓为君）',
        '干姜附子': '昼烦夜安、脉沉微（纯阳虚，去甘草之缓）',
      },
    ),
    // ---- 第二轮倪海厦skill扩展鉴别 ----
    '麻黄附子细辛_vs_麻黄附子甘草': DifferentialDiagnosis(
      name1: '麻黄附子细辛汤证',
      formula1: '麻黄附子细辛汤',
      name2: '麻黄附子甘草汤证',
      formula2: '麻黄附子甘草汤',
      keyDifference: '少阴表证：峻烈去寒 vs 缓和利尿',
      details: {
        '麻附细辛': '里寒极盛、阴寒水肿、小便难、壮肾阳去里寒',
        '麻附甘草': '肾阳虚水肿、脉沉小、甘草缓和、利尿消肿',
      },
    ),
    '白虎_vs_白虎人参': DifferentialDiagnosis(
      name1: '白虎汤证',
      formula1: '白虎汤',
      name2: '白虎加人参汤证',
      formula2: '白虎加人参汤',
      keyDifference: '津液亏损程度',
      details: {
        '白虎': '纯阳明经热、大热大汗、津液未大伤',
        '白虎人参': '大烦渴不解、脉洪大、津液明显亏损、高热汗出',
      },
    ),
    '小建中_vs_理中': DifferentialDiagnosis(
      name1: '小建中汤证',
      formula1: '小建中汤',
      name2: '理中汤证',
      formula2: '理中汤',
      keyDifference: '虚寒腹痛 vs 脾虚寒湿',
      details: {
        '小建中': '隐痛喜按、面色苍白、食欲不振、脾津液不足',
        '理中': '腹满吐利、食不下、舌苔白厚、寒湿困脾',
      },
    ),
    '桃核承气_vs_抵当汤': DifferentialDiagnosis(
      name1: '桃核承气汤证',
      formula1: '桃核承气汤',
      name2: '抵当汤证',
      formula2: '抵当汤',
      keyDifference: '蓄血轻重：小便带血如狂 vs 小便自利发狂',
      details: {
        '桃核承气': '热结膀胱、其人如狂、小便带血、少腹急结',
        '抵当': '小便自利、大便黑、发狂善忘、少腹剧痛固定',
      },
    ),
    '十枣_vs_陷胸': DifferentialDiagnosis(
      name1: '十枣汤证',
      formula1: '十枣汤',
      name2: '大/小陷胸汤证',
      formula2: '大陷胸汤/小陷胸汤',
      keyDifference: '水饮 vs 痰实',
      details: {
        '十枣': '肺积水满、不能卧、悬饮留饮',
        '大陷胸': '热实结胸、痰堵胸腔、热痰实证',
        '小陷胸': '轻症结胸、抽烟咳喘、黄痰在胸腔',
      },
    ),
    '麻子仁_vs_承气': DifferentialDiagnosis(
      name1: '麻子仁丸证',
      formula1: '麻子仁丸',
      name2: '承气汤证',
      formula2: '承气汤',
      keyDifference: '虚秘 vs 热秘',
      details: {
        '麻子仁': '虚秘、宿食堵小肠较轻、润下缓通',
        '承气': '热秘、宿食堵小肠较重、攻下峻猛',
      },
    ),
    '吴茱萸_vs_四逆': DifferentialDiagnosis(
      name1: '吴茱萸汤证',
      formula1: '吴茱萸汤',
      name2: '四逆汤证',
      formula2: '四逆汤',
      keyDifference: '厥阴肝虚 vs 少阴心肾阳虚',
      details: {
        '吴茱萸': '头痛呕吐、吐涎沫、呕酸、肝虚寒',
        '四逆': '脉微细但欲寐、手足逆冷、心肾阳虚',
      },
    ),
    '当归四逆_vs_四逆': DifferentialDiagnosis(
      name1: '当归四逆汤证',
      formula1: '当归四逆汤',
      name2: '四逆汤证',
      formula2: '四逆汤',
      keyDifference: '血虚寒凝 vs 阳气衰微',
      details: {
        '当归四逆': '手足厥寒、脉细欲绝、月经不来、血虚寒凝',
        '四逆': '手足逆冷至膝肘、脉微细但欲寐、阳气衰微',
      },
    ),
  };

  // ==================== 经方加减法规则 ====================
  static final Map<String, List<FormulaModification>> formulaModifications = {
    '桂枝汤': [
      FormulaModification(
        condition: '兼咳喘',
        symptom: 'cough',
        type: ModificationType.add,
        herbName: '厚朴、杏仁',
        resultFormula: '桂枝加厚朴杏仁汤',
        description: '加厚朴、杏仁以降气平喘',
      ),
      FormulaModification(
        condition: '兼项背强',
        symptom: 'neck_stiff',
        type: ModificationType.add,
        herbName: '葛根',
        resultFormula: '桂枝加葛根汤',
        description: '加葛根以舒经通络',
      ),
      FormulaModification(
        condition: '兼汗多心悸',
        symptom: 'palpitations',
        type: ModificationType.add,
        herbName: '龙骨、牡蛎',
        resultFormula: '桂枝加龙骨牡蛎汤',
        description: '加龙骨、牡蛎以潜阳安神',
      ),
      FormulaModification(
        condition: '兼胸满',
        symptom: 'chest_fullness',
        type: ModificationType.remove,
        herbName: '芍药',
        resultFormula: '桂枝去芍药汤',
        description: '去芍药以免酸收敛邪（心脏病不用芍药）',
      ),
      FormulaModification(
        condition: '兼身痛脉沉迟',
        symptom: 'body_pain',
        type: ModificationType.add,
        herbName: '人参',
        resultFormula: '桂枝新加汤',
        description: '加重芍药、生姜，加人参以补津液止痛',
      ),
    ],
    '小柴胡汤': [
      FormulaModification(
        condition: '兼便秘',
        symptom: 'constipation',
        type: ModificationType.add,
        herbName: '大黄、枳实',
        resultFormula: '大柴胡汤',
        description: '加大黄、枳实以攻下',
      ),
      FormulaModification(
        condition: '兼口渴',
        symptom: 'thirst_strong',
        type: ModificationType.add,
        herbName: '栝蒌根',
        resultFormula: '柴胡去半夏加栝蒌汤',
        description: '去半夏加栝蒌根以生津止渴',
      ),
    ],
    '真武汤': [
      FormulaModification(
        condition: '兼咳',
        symptom: 'cough',
        type: ModificationType.add,
        herbName: '五味子、细辛、干姜',
        resultFormula: '',
        description: '加五味子、细辛、干姜以温肺止咳',
      ),
      FormulaModification(
        condition: '兼下利',
        symptom: 'diarrhea',
        type: ModificationType.replace,
        herbName: '芍药',
        replaceWith: '干姜',
        resultFormula: '',
        description: '去芍药加干姜以温中止利',
      ),
    ],
    '四逆汤': [
      FormulaModification(
        condition: '兼脉绝',
        symptom: 'pulse_gone',
        type: ModificationType.add,
        herbName: '人参',
        resultFormula: '四逆加人参汤',
        description: '加人参以益气复脉',
      ),
      FormulaModification(
        condition: '兼阴盛格阳',
        symptom: 'upper_heat_lower_cold',
        type: ModificationType.add,
        herbName: '葱白',
        resultFormula: '通脉四逆汤',
        description: '加葱白以通阳破阴',
      ),
      FormulaModification(
        condition: '兼烦躁',
        symptom: 'irritability',
        type: ModificationType.add,
        herbName: '茯苓、人参',
        resultFormula: '茯苓四逆汤',
        description: '加茯苓六两、人参一两以利水宁心（烦躁为辨证关键）',
      ),
    ],
    '理中汤': [
      FormulaModification(
        condition: '兼呕吐多',
        symptom: 'vomiting',
        type: ModificationType.add,
        herbName: '生姜',
        resultFormula: '',
        description: '加生姜以和胃止呕',
      ),
      FormulaModification(
        condition: '兼下利多',
        symptom: 'diarrhea',
        type: ModificationType.add,
        herbName: '附子',
        resultFormula: '附子理中汤',
        description: '加附子以温阳止利',
      ),
    ],
    '麻黄汤': [
      FormulaModification(
        condition: '兼烦躁',
        symptom: 'irritability',
        type: ModificationType.add,
        herbName: '石膏',
        resultFormula: '大青龙汤',
        description: '加石膏以清里热（表寒里热）',
      ),
    ],
    '白虎汤': [
      FormulaModification(
        condition: '兼气虚',
        symptom: 'weakness',
        type: ModificationType.add,
        herbName: '人参',
        resultFormula: '白虎加人参汤',
        description: '加人参以益气生津',
      ),
    ],
    '麻黄附子细辛汤': [
      FormulaModification(
        condition: '兼水肿轻症',
        symptom: 'edema',
        type: ModificationType.replace,
        herbName: '细辛',
        replaceWith: '甘草',
        resultFormula: '麻黄附子甘草汤',
        description: '去细辛加甘草，缓和利尿消肿',
      ),
    ],
    '小建中汤': [
      FormulaModification(
        condition: '兼心悸',
        symptom: 'palpitations',
        type: ModificationType.add,
        herbName: '炙甘草',
        resultFormula: '炙甘草汤',
        description: '重用炙甘草以补心血（脉结代）',
      ),
    ],
    '吴茱萸汤': [
      FormulaModification(
        condition: '兼头痛剧烈',
        symptom: 'headache',
        type: ModificationType.add,
        herbName: '川芎',
        resultFormula: '',
        description: '加川芎以活血止痛',
      ),
    ],
    '当归四逆汤': [
      FormulaModification(
        condition: '兼内有久寒',
        symptom: 'chronic_cold',
        type: ModificationType.add,
        herbName: '吴茱萸、生姜',
        resultFormula: '当归四逆加吴茱萸生姜汤',
        description: '加吴茱萸、生姜以温里散寒',
      ),
    ],
    '栀子豉汤': [
      FormulaModification(
        condition: '兼少气',
        symptom: 'weakness',
        type: ModificationType.add,
        herbName: '甘草',
        resultFormula: '栀子甘草豉汤',
        description: '加甘草以益气',
      ),
      FormulaModification(
        condition: '兼呕吐',
        symptom: 'vomiting',
        type: ModificationType.add,
        herbName: '生姜',
        resultFormula: '栀子生姜豉汤',
        description: '加生姜以止呕',
      ),
    ],
  };

  // ==================== 舌诊选项 ====================
  static const List<String> tongueCoatingOptions = [
    '薄白', '白厚', '黄薄', '黄厚', '灰黑', '无苔',
  ];
  static const List<String> tongueShapeOptions = [
    '淡红', '淡白', '红', '绛紫', '胖大', '瘦小', '齿痕',
  ];

  // ==================== 脉诊选项 ====================
  static const List<String> pulseOptions = [
    '浮', '沉', '迟', '数', '滑', '涩', '弦', '紧', '缓', '弱',
    '微', '细', '洪', '实', '虚',
    // P2-E: 金匮/伤寒补充脉象（促=热利葛根芩连/大承气；结代=炙甘草汤；芤=失血；革=失精；微弱=桂枝二越婢一）
    '促', '结', '代', '芤', '革', '微弱',
  ];

  // ==================== 调护建议 ====================
  static final Map<String, CareAdvice> careAdvice = {
    '太阳': CareAdvice(
      diet: ['禁生冷、粘滑、肉面、五辛、酒酪', '宜热稀粥助药力', '宜清淡易消化'],
      rest: ['被子盖好躺二小时', '遍身漐漐微汗为佳', '不可令如水流漓'],
      moxibustion: ['可灸风池、风府、大椎'],
      avoid: ['不可吹风', '不可冷水洗澡'],
    ),
    '阳明': CareAdvice(
      diet: ['禁辛辣燥热', '宜清淡流质', '大便通后渐增饮食'],
      rest: ['高热时卧床休息', '保持室内通风'],
      moxibustion: ['实热证不可灸', '白虎汤证可灸足三里健胃'],
      avoid: ['不可发汗', '不可温灸（实热证时）'],
    ),
    '少阳': CareAdvice(
      diet: ['禁发汗、吐、下', '宜疏肝理气之品', '少食多餐'],
      rest: ['保持情志舒畅', '避免熬夜'],
      moxibustion: ['可灸阳陵泉、期门'],
      avoid: ['不可发汗（发汗则谵语）', '不可吐下（吐下则悸而惊）'],
    ),
    '太阴': CareAdvice(
      diet: ['禁寒凉生冷', '宜温热健脾', '理中汤类温服'],
      rest: ['腹部保暖', '避免受寒'],
      moxibustion: ['可灸中脘、足三里、脾俞', '虚寒证宜灸'],
      avoid: ['不可攻下', '攻下会更胸下结硬'],
    ),
    '少阴': CareAdvice(
      diet: ['禁一切寒凉', '宜温阳回逆', '四逆汤类温服'],
      rest: ['充分休息', '避免过劳', '保暖'],
      moxibustion: ['可灸关元、气海、命门', '重灸回阳'],
      avoid: ['不可发汗', '不可攻下', '避免受寒'],
    ),
    '厥阴': CareAdvice(
      diet: ['寒热错杂需寒热并用', '禁生冷', '宜乌梅丸'],
      rest: ['调畅情志', '避免郁怒'],
      moxibustion: ['可灸太冲、期门', '寒证可灸关元'],
      avoid: ['不可单独攻下', '不可单独发汗'],
    ),
  };

  // ==================== 舌脉对经络权重的影响 ====================
  static const Map<String, Map<String, double>> tonguePulseWeights = {
    // 舌苔对经络的影响
    'tongue_coating': {
      '薄白': 0.0,  // 正常，无偏向
      '白厚': 0.3,  // 偏向太阴/少阴
      '黄薄': 0.3,  // 偏向阳明/少阳
      '黄厚': 0.5,  // 强烈偏向阳明
      '灰黑': 0.4,  // 偏向少阴（寒化）或阳明（热化）
      '无苔': 0.3,  // 偏向少阴（阴虚）
    },
    // 舌形对经络的影响
    'tongue_shape': {
      '淡红': 0.0,  // 正常
      '淡白': 0.3,  // 偏向太阴/少阴（虚寒）
      '红': 0.3,    // 偏向阳明/少阳（热）
      '绛紫': 0.4,  // 偏向厥阴（瘀血）
      '胖大': 0.3,  // 偏向太阴（脾虚湿盛）
      '瘦小': 0.3,  // 偏向少阴（阴虚）
      '齿痕': 0.3,  // 偏向太阴（脾虚）
    },
    // 脉象对经络的影响
    'pulse': {
      '浮': 0.5,    // 强烈偏向太阳
      '沉': 0.4,    // 偏向里证（太阴/少阴）
      '迟': 0.4,    // 偏向寒证（少阴）
      '数': 0.4,    // 偏向热证（阳明/少阳）
      '滑': 0.3,    // 偏向阳明/痰湿
      '涩': 0.3,    // 偏向血瘀/厥阴
      '弦': 0.4,    // 偏向少阳
      '紧': 0.4,    // 偏向太阳伤寒
      '缓': 0.3,    // 偏向太阳中风
      '弱': 0.3,    // 偏向太阴/少阴
      '微': 0.5,    // 强烈偏向少阴
      '细': 0.4,    // 偏向少阴
      '洪': 0.5,    // 强烈偏向阳明
      '实': 0.4,    // 偏向阳明实证
      '虚': 0.4,    // 偏向虚证（太阴/少阴）
    },
  };

  // ==================== 主诉选项（25项）====================
  static final List<SymptomOption> chiefComplaints = [
    // -- 表证 --
    SymptomOption(key: 'fever_chills', label: '发烧怕冷', emoji: '🤒', description: '发热同时怕冷，太阳表证'),
    SymptomOption(key: 'fever_only', label: '只发烧不怕冷', emoji: '🌡️', description: '发热但不怕冷，阳明或温病'),
    SymptomOption(key: 'chills_only', label: '只怕冷不发烧', emoji: '🥶', description: '畏寒但不发热，太阴少阴'),
    SymptomOption(key: 'alternating', label: '忽冷忽热', emoji: '🔄', description: '一阵冷一阵热，少阳证'),
    SymptomOption(key: 'upper_heat_lower_cold', label: '上热下寒', emoji: '☯️', description: '口干口苦但手脚冰，厥阴'),
    SymptomOption(key: 'headache', label: '头痛', emoji: '🤕', description: '头部疼痛，需辨经络'),
    SymptomOption(key: 'neck_stiff', label: '脖子僵硬', emoji: '🦴', description: '项背强几几，太阳经输不利'),
    SymptomOption(key: 'body_pain', label: '全身酸痛', emoji: '💪', description: '骨节疼痛，伤寒表实'),
    SymptomOption(key: 'cough', label: '咳嗽气喘', emoji: '😷', description: '肺系症状，需辨寒热'),
    // -- 里证 --
    SymptomOption(key: 'abdominal_pain', label: '肚子痛', emoji: '🤢', description: '腹痛，需辨虚实寒热'),
    SymptomOption(key: 'diarrhea', label: '拉肚子', emoji: '💨', description: '下利，需辨寒热'),
    SymptomOption(key: 'constipation', label: '便秘', emoji: '😰', description: '大便不通，阳明腑实'),
    SymptomOption(key: 'vomiting', label: '呕吐', emoji: '🤮', description: '呕吐，少阳太阴皆有'),
    SymptomOption(key: 'bitter_mouth', label: '嘴苦', emoji: '😖', description: '口苦咽干，少阳胆火'),
    // -- 虚证 --
    SymptomOption(key: 'fatigue', label: '很累很困', emoji: '😴', description: '精神疲倦但欲寐，少阴'),
    SymptomOption(key: 'insomnia', label: '睡不着烦躁', emoji: '😫', description: '失眠心烦，少阴热化'),
    SymptomOption(key: 'palpitation', label: '心悸心慌', emoji: '💗', description: '心跳异常，心阳虚'),
    SymptomOption(key: 'dizziness', label: '头晕目眩', emoji: '💫', description: '眩晕，水饮或少阳'),
    SymptomOption(key: 'cold_limbs', label: '手脚冰冷', emoji: '🧊', description: '四肢厥冷，阳虚'),
    // -- 杂病 --
    SymptomOption(key: 'edema', label: '水肿', emoji: '💧', description: '身体浮肿，阳虚水泛'),
    SymptomOption(key: 'joint_pain', label: '关节疼痛', emoji: '🦴', description: '风湿痹证'),
    SymptomOption(key: 'skin', label: '皮肤问题', emoji: '🩹', description: '疮疡、瘙痒、过敏'),
    SymptomOption(key: 'urination', label: '小便异常', emoji: '🚽', description: '尿频、尿痛、不利'),
    SymptomOption(key: 'menstrual', label: '月经问题', emoji: '🩸', description: '痛经、量少、不调'),
  ];

  // ==================== 寒热辨经（5项→六经定位）====================
  static final List<TemperatureOption> temperaturePatterns = [
    TemperatureOption(
      key: 'fever_chills',
      label: '发热 + 怕冷',
      description: '发烧的同时也怕冷，太阳表证',
      targetMeridian: '太阳',
    ),
    TemperatureOption(
      key: 'fever_no_cold',
      label: '只发热不怕冷',
      description: '发烧但不怕冷，反而怕热。但热不寒为阳明。',
      targetMeridian: '阳明',
    ),
    TemperatureOption(
      key: 'chills_no_fever',
      label: '只怕冷不发热',
      description: '畏寒但体温不高，里虚寒证',
      targetMeridian: '太阴/少阴',
    ),
    TemperatureOption(
      key: 'alternating_chills_fever',
      label: '一阵冷一阵热',
      description: '忽冷忽热像打摆子，半表半里',
      targetMeridian: '少阳',
    ),
    TemperatureOption(
      key: 'upper_heat_lower_cold',
      label: '上热下寒',
      description: '上面口干口苦，下面手脚冰冷，寒热错杂',
      targetMeridian: '厥阴',
    ),
    TemperatureOption(
      key: 'fever_thirst_no_cold',
      label: '发热而渴，不恶寒',
      description: '发热口渴但不怕冷，温病。津液不足。',
      targetMeridian: '太阳',
    ),
    TemperatureOption(
      key: 'no_fever_no_chill',
      label: '不发烧也不怕冷',
      description: '体温正常，没有明显怕冷怕热；或仅局部寒热（如皮肤患处发凉或发热）。寒热不显，需结合其他症状辨证。',
      targetMeridian: '太阴/少阴',
    ),
  ];

  static final Map<String, String> temperatureToMeridian = {
    'fever_chills': '太阳',
    'fever_no_cold': '阳明',
    'chills_no_fever': '太阴/少阴',
    'alternating_chills_fever': '少阳',
    'upper_heat_lower_cold': '厥阴',
    'fever_thirst_no_cold': '太阳',
    'no_fever_no_chill': '太阴/少阴',
  };

  // ==================== 倪海厦诊病十问（六经辨证优化版）====================
  // 基于《伤寒论113方六经辨证公式》优化，确保能覆盖六经关键辨证要素
  static final List<FollowUpQuestion> tenQuestions = [
    FollowUpQuestion(
      key: 'gender',
      question: '请问您的性别？（影响月经问题的问诊）',
      options: ['男', '女'],
    ),
    FollowUpQuestion(
      key: 'sleep',
      question: '【一问睡眠】晚上能一觉到天亮吗？几点醒？',
      options: ['一觉到天亮', '半夜1-3点醒', '半夜3-5点醒', '整夜睡不着', '多梦易醒', '嗜睡但睡不够'],
    ),
    FollowUpQuestion(
      key: 'appetite',
      question: '【二问胃口】三餐正常吗？有没有特别想吃或不想吃的？',
      options: ['正常三餐', '没有胃口', '特别能吃', '饿但不想吃（厥阴）', '想吃冷的', '想吃热的', '食不下（太阴）'],
    ),
    FollowUpQuestion(
      key: 'stool',
      question: '【三问大便】每天有大便吗？成形还是稀的？颜色？',
      options: ['每天有，成形', '便秘，好几天一次', '稀/拉肚子', '先硬后稀', '水样便', '便脓血', '下利清谷（完谷不化）'],
    ),
    FollowUpQuestion(
      key: 'urine',
      question: '【四问小便】一天几次？颜色？量多量少？',
      options: ['5-7次淡黄色（正常）', '次数多量少', '次数少颜色深', '夜尿多', '小便不利', '小便黄赤', '小便清长'],
    ),
    FollowUpQuestion(
      key: 'thirst',
      question: '【五问口渴】渴不渴？想喝冷水还是热水？',
      options: ['不渴', '渴想喝冷水', '渴想喝热水', '渴但不想喝', '口苦口干（少阳）', '消渴（喝水不止渴）', '大渴（阳明）'],
    ),
    FollowUpQuestion(
      key: 'temperature',
      question: '【六问寒热】怕冷还是怕热？手脚温度？',
      options: ['手脚温热（正常）', '手脚冰冷', '手心脚心热', '头热脚冷', '上半身热下半身冷', '全身怕冷', '往来寒热（忽冷忽热）'],
    ),
    FollowUpQuestion(
      key: 'sweating',
      question: '【七问汗】容易出汗吗？什么时间出汗？',
      options: ['不容易出汗', '稍微活动就出汗', '睡觉出汗（盗汗）', '白天也出汗（自汗）', '但头汗出', '手足汗出', '大汗出（阳明）'],
    ),
    FollowUpQuestion(
      key: 'energy',
      question: '【八问精神】精神体力怎样？有没有特殊感觉？',
      options: ['精力充沛', '容易疲倦', '但欲寐（昏昏沉沉想睡）', '烦躁不安', '说话没力气', '气上撞心（感觉有气往上冲）'],
    ),
    // 注意：舌诊已统一在 Step 3（舌诊脉诊步骤）处理，十问中不再重复
    FollowUpQuestion(
      key: 'pain',
      question: '【九问疼痛】哪里痛？什么性质的痛？',
      options: ['不痛', '头痛（前额）', '头痛（两侧）', '头痛（后脑）', '胸胁胀痛（少阳）', '腹痛喜按', '腹痛拒按', '关节游走痛', '身体痛+骨节痛（少阴）', '心下痞满（按之软）'],
    ),
    FollowUpQuestion(
      key: 'menstrual',
      question: '【十问月经/性功能】月经怎样？（男问性功能）',
      options: ['没有此症状', '月经正常', '痛经/量少/色暗有块', '月经量多/色红', '月经不调/先后无定期', '已绝经', '性功能正常', '性功能减退/腰酸'],
    ),
  ];

  // ==================== 六经跟进问诊（113方公式优化版）====================
  // 基于《伤寒论113方六经辨证公式》优化，每个跟进问题对应具体方剂辨证
  static final Map<String, List<FollowUpQuestion>> followUpQuestions = {
    '太阳': [
      FollowUpQuestion(
        key: 'sweating',
        question: '【辨桂枝/麻黄】有汗还是没汗？',
        options: ['有汗（中风→桂枝汤）', '没汗（伤寒→麻黄汤）', '汗出不止（→桂枝加附子汤）'],
      ),
      FollowUpQuestion(
        key: 'neck',
        question: '【辨葛根汤】脖子后面僵硬吗？牵连到背部？',
        options: ['僵硬（→葛根汤/桂枝加葛根汤）', '不僵硬', '项背强几几+无汗（→葛根汤）'],
      ),
      FollowUpQuestion(
        key: 'body_pain',
        question: '【辨身痛类型】全身骨节酸痛吗？',
        options: ['全身酸痛（伤寒）', '只有头痛', '只有腰痛', '不痛', '身体疼烦不能转侧（→桂枝附子汤）', '身痒（→桂麻各半汤）'],
      ),
      FollowUpQuestion(
        key: 'breathing',
        question: '【辨喘证】有没有咳嗽气喘？',
        options: ['没有', '咳嗽（→桂枝加厚朴杏仁汤）', '气喘（→桂枝加厚朴杏仁汤）', '咳而上气+烦躁（→小青龙加石膏汤）', '咳嗽有白痰（→小青龙汤）', '咳嗽有黄痰（→麻杏石甘汤）'],
      ),
      FollowUpQuestion(
        key: 'chest',
        question: '【辨心下证】胸口或心下有没有不舒服？',
        options: ['没有', '心下满微痛（→桂去桂加苓术汤）', '心下悸（→茯苓甘草汤）', '气上冲胸（→苓桂术甘汤）'],
      ),
      FollowUpQuestion(
        key: 'treatment_history',
        question: '【辨误治】之前有没有被误用过泻药或攻下？',
        options: ['没有', '被误下过', '吃坏肚子拉过', '烧针令汗（→桂枝加桂汤）'],
      ),
    ],
    '阳明': [
      FollowUpQuestion(
        key: 'stool',
        question: '【辨承气汤证】大便怎样？',
        options: ['便秘好几天不通', '大便硬但能通（→小承气汤）', '正常', '腹泻', '便秘+腹满痛拒按+谵语（→大承气汤）', '便秘+心烦（→调胃承气汤）'],
      ),
      FollowUpQuestion(
        key: 'thirst',
        question: '【辨白虎汤证】口渴吗？想喝什么？',
        options: ['大渴饮冷水（→白虎加人参汤）', '口渴喝温水', '不渴', '渴+小便不利（→猪苓汤）'],
      ),
      FollowUpQuestion(
        key: 'sweat',
        question: '【辨汗出类型】出汗多吗？',
        options: ['大汗出（→白虎汤）', '正常', '手足汗出（→承气汤）', '但头汗出+身无汗（→茵陈蒿汤）'],
      ),
      FollowUpQuestion(
        key: 'abdomen',
        question: '【辨腹证】肚子胀不胀？按着痛不痛？',
        options: ['胀满拒按（不能按→大承气汤）', '胀满喜按（按着舒服）', '不胀不痛', '只胃脘痛', '腹满+身黄（→茵陈蒿汤）', '心下痞+按之濡（→大黄黄连泻心汤）'],
      ),
      FollowUpQuestion(
        key: 'speech',
        question: '【辨谵语】有没有说胡话（谵语）？',
        options: ['没有', '有说胡话（→承气汤）', '烦躁不安', '心中懊憹（→栀子豉汤）'],
      ),
      FollowUpQuestion(
        key: 'tidal_fever',
        question: '【辨潮热】有没有下午发冷发热（潮热）？',
        options: ['没有', '下午3-5点发热（潮热→大承气汤）', '全身持续发热', '手足汗出', '身黄发热（→栀子蘖皮汤）'],
      ),
    ],
    '少阳': [
      FollowUpQuestion(
        key: 'bitter_mouth',
        question: '【辨少阳主证】嘴苦吗？',
        options: ['嘴苦（少阳主证）', '不苦', '口苦+咽干+目眩（→小柴胡汤）'],
      ),
      FollowUpQuestion(
        key: 'throat',
        question: '【辨少阳主证】喉咙干吗？',
        options: ['咽干（少阳主证）', '不干', '喉咙痛', '咽干+目眩（→小柴胡汤）'],
      ),
      FollowUpQuestion(
        key: 'chest',
        question: '【辨胸胁苦满】胸口两侧胀吗？',
        options: ['胸胁苦满（胀痛→小柴胡汤）', '不胀', '只有胸闷', '胸胁满+微结（→柴胡桂枝干姜汤）'],
      ),
      FollowUpQuestion(
        key: 'nausea',
        question: '【辨呕吐类型】想呕吐吗？',
        options: ['心烦喜呕（→小柴胡汤）', '不想吐', '干呕', '呕吐不止', '呕不止+心下急（→大柴胡汤）'],
      ),
      FollowUpQuestion(
        key: 'eyes',
        question: '【辨少阳主证】眼睛有没有不舒服？',
        options: ['目眩（眼花→少阳主证）', '眼睛干', '没有'],
      ),
      FollowUpQuestion(
        key: 'constipation',
        question: '【辨少阳兼证】大便怎样？',
        options: ['正常', '便秘（少阳阳明合病→大柴胡汤/柴胡加芒硝汤）', '腹泻', '胸胁满+微结+小便不利（→柴胡桂枝干姜汤）'],
      ),
      FollowUpQuestion(
        key: 'extremities',
        question: '【辨四逆散】手脚温度？有没有烦躁？',
        options: ['手脚温', '手脚冷但非寒证（→四逆散）', '烦躁+身重不可转侧（→柴胡加龙骨牡蛎汤）'],
      ),
    ],
    '太阴': [
      FollowUpQuestion(
        key: 'appetite',
        question: '【辨太阴主证】胃口怎样？',
        options: ['吃不下（太阴主证）', '能吃但腹胀', '正常', '饿但不想吃（→理中汤）'],
      ),
      FollowUpQuestion(
        key: 'diarrhea',
        question: '【辨下利类型】大便怎样？',
        options: ['稀/拉肚子（太阴湿利）', '水样便', '正常', '先硬后稀', '下利不止+滑脱不禁（→赤石脂禹余粮汤）'],
      ),
      FollowUpQuestion(
        key: 'abdomen',
        question: '【辨腹痛类型】肚子痛吗？',
        options: ['时腹自痛（隐痛→理中汤）', '腹满不痛', '不痛', '腹痛喜按', '腹满时痛（→桂枝加芍药汤）', '腹满大实痛（→桂枝加大黄汤）'],
      ),
      FollowUpQuestion(
        key: 'extremities',
        question: '【辨寒热】手脚温度怎样？',
        options: ['手脚冷（太阴虚寒）', '手脚温', '四肢烦疼（→桂枝附子汤）', '腹胀满+四肢倦怠（→厚朴姜夏甘参汤）'],
      ),
      FollowUpQuestion(
        key: 'vomiting',
        question: '【辨呕吐】有没有呕吐？',
        options: ['呕吐（太阴主证）', '不吐', '干呕', '呕吐+腹满（→理中汤）'],
      ),
      FollowUpQuestion(
        key: 'water_retention',
        question: '【辨水饮】有没有水气相关症状？',
        options: ['没有', '心下逆满+气上冲胸（→苓桂术甘汤）', '心下悸+厥而心下悸（→茯苓甘草汤）'],
      ),
    ],
    '少阴': [
      FollowUpQuestion(
        key: 'spirit',
        question: '【辨少阴主证】精神状态怎样？',
        options: ['但欲寐（昏昏沉沉想睡→少阴主证）', '精神还好', '烦躁不安（→黄连阿胶汤/热化）', '昼日烦躁夜安静（→干姜附子汤）'],
      ),
      FollowUpQuestion(
        key: 'extremities',
        question: '【辨寒化/热化】手脚温度？',
        options: ['冰冷（少阴寒化→四逆汤）', '温', '手脚心热（少阴热化）', '手足厥寒+脉细欲绝（→当归四逆汤）'],
      ),
      FollowUpQuestion(
        key: 'sleep',
        question: '【辨热化证】晚上能睡着吗？',
        options: ['心烦睡不着+舌红（→黄连阿胶汤）', '能睡', '嗜睡（寒化）', '心中烦+不得卧（→黄连阿胶汤）'],
      ),
      FollowUpQuestion(
        key: 'urine',
        question: '【辨水气证】小便怎样？',
        options: ['清长（肾阳虚）', '小便不利+水肿（→真武汤）', '小便黄', '正常', '小便不利+腹痛（→真武汤）'],
      ),
      FollowUpQuestion(
        key: 'diarrhea',
        question: '【辨下利类型】大便怎样？',
        options: ['下利清谷（完谷不化→四逆汤/通脉四逆汤）', '正常', '便秘', '便脓血（→桃花汤）', '下利+咽痛（→猪肤汤）', '下利六七日+咳而呕渴（→猪苓汤）'],
      ),
      FollowUpQuestion(
        key: 'pain',
        question: '【辨身痛证】身体有没有疼痛？',
        options: ['骨节疼痛（→附子汤）', '身体痛+手足寒+骨节痛+脉沉（→附子汤）', '心下悸', '没有明显疼痛', '四肢沉重疼痛（→真武汤）'],
      ),
      FollowUpQuestion(
        key: 'throat',
        question: '【辨咽痛证】喉咙怎样？',
        options: ['没有', '喉咙痛（→甘草汤/桔梗汤）', '咽中生疮+不能说话（→苦酒汤）', '不能说话', '咽中化脓', '咽痛+下利（→猪肤汤）'],
      ),
      FollowUpQuestion(
        key: 'table',
        question: '【辨少阴兼表】有没有发热？',
        options: ['没有发热', '反发热+脉沉（→麻黄附子细辛汤）', '得之二三日（→麻黄附子甘草汤）'],
      ),
    ],
    '厥阴': [
      FollowUpQuestion(
        key: 'thirst',
        question: '【辨厥阴主证】口渴吗？',
        options: ['消渴（喝水不止渴→厥阴主证）', '渴但不想喝', '不渴', '渴+下利（→乌梅丸）'],
      ),
      FollowUpQuestion(
        key: 'chest_sensation',
        question: '【辨气上撞心】胸口或胃有没有特殊感觉？',
        options: ['气上撞心（厥阴主证→乌梅丸）', '心中疼热（厥阴主证）', '没有', '干呕+吐涎沫+头痛（→吴茱萸汤）'],
      ),
      FollowUpQuestion(
        key: 'appetite',
        question: '【辨饥不欲食】饿吗？想吃东西吗？',
        options: ['饿但不想吃（厥阴主证→乌梅丸）', '不饿', '能吃', '食谷欲呕（→吴茱萸汤/阳明）'],
      ),
      FollowUpQuestion(
        key: 'extremities',
        question: '【辨厥证】手脚温度？',
        options: ['手脚冰冷（厥阴寒证）', '时冷时热（寒热错杂→乌梅丸）', '温', '手足厥寒+脉细欲绝（→当归四逆汤）'],
      ),
      FollowUpQuestion(
        key: 'vomiting',
        question: '【辨吐蛔】有没有呕吐？',
        options: ['食则吐蛔（→乌梅丸）', '呕吐', '不吐', '干呕+吐涎沫（→吴茱萸汤）'],
      ),
      FollowUpQuestion(
        key: 'stool',
        question: '【辨下利】大便怎样？',
        options: ['没有', '腹泻', '腹痛', '热利下重+便脓血（→白头翁汤）', '下利不止（→乌梅丸）', '食入口即吐（→干姜黄连黄芩人参汤）'],
      ),
      FollowUpQuestion(
        key: 'sputum',
        question: '【辨脓血】痰或唾液怎样？',
        options: ['没有', '白痰', '黄痰', '唾脓血（→麻黄升麻汤）'],
      ),
    ],
  };

  // ==================== 六经杂证补充（P2-2：非misc 24方触发词并入六经跟进） ====================
  // 引擎 getFollowUpQuestions 会合并本表；选项文本=触发词+证候（→方剂），子串匹配即命中。
  static final Map<String, List<FollowUpQuestion>> meridianSupplementFollowUps = {
    '太阳': [
      FollowUpQuestion(
        key: 'sup_sun_misc',
        question: '【太阳杂证补充】以下哪项符合你？（金匮/蓄血/表虚变证）',
        options: [
          '心下有水气（→小青龙汤）',
          '痉（→栝蒌桂枝汤）',
          '目眩+失精（→桂枝加龙骨牡蛎汤）',
          '胸满（→桂枝去芍药汤）',
          '少腹急结+如狂（→桃核承气汤）',
        ],
      ),
    ],
    '阳明': [
      FollowUpQuestion(
        key: 'sup_yangming_misc',
        question: '【阳明杂证补充】以下哪项符合你？（腹满/酒疸/温疟/痉湿暍）',
        options: [
          '腹胀痛（→厚朴三物汤）',
          '卧起不安（→栀子厚朴枳实汤）',
          '酒黄疸（→栀子大黄汤）',
          '温疟（→白虎加桂枝汤）',
          '脚挛急（→芍药甘草汤）',
          '恶寒+发汗后（→芍药甘草附子汤）',
          '身黄+身痒（→麻黄连轺赤小豆汤）',
          '身黄+发热（→栀子柏皮汤）',
        ],
      ),
    ],
    '太阴': [
      FollowUpQuestion(
        key: 'sup_taiyin_misc',
        question: '【太阴杂证补充】以下哪项符合你？（肺痿/脏躁）',
        options: [
          '吐涎沫（→甘草干姜汤）',
          '脏躁（→甘麦大枣汤）',
          '下利+口苦（→黄芩汤）',
          '心下痞+下利不止（→甘草泻心汤）',
        ],
      ),
    ],
    '少阴': [
      FollowUpQuestion(
        key: 'sup_shaoyin_misc',
        question: '【少阴杂证补充】以下哪项符合你？（寒疝/咽痛/肾气）',
        options: [
          '关节剧痛（→乌头汤）',
          '骨节疼烦+掣痛（→甘草附子汤）',
          '绕脐痛（→乌头煎）',
          '汗出不止（→桂枝加附子汤）',
          '咽痛+胸满（→猪肤汤）',
          '腰痛+脚冷（→肾气丸）',
          '生疮+不能语言（→苦酒汤）',
          '少阴表证（→麻黄附子甘草汤）',
          '咽痛（→甘草汤）',
        ],
      ),
    ],
    '厥阴': [
      FollowUpQuestion(
        key: 'sup_jueyin_misc',
        question: '【厥阴杂证补充】以下哪项符合你？（久寒/麻黄升麻）',
        options: [
          '内有久寒（→当归四逆加吴茱萸生姜汤）',
          '唾脓血+泄利不止（→麻黄升麻汤）',
        ],
      ),
    ],
  };

  // ==================== 快速诊断路径 ====================
  static final Map<String, Map<String, String>> quickDiagnosis = {
    '少阳': {
      'formula': '小柴胡汤',
      'pattern': '少阳病',
    },
    '阳明': {
      'formula': '白虎汤/承气汤',
      'pattern': '阳明病',
    },
    '太阴': {
      'formula': '理中汤',
      'pattern': '太阴病',
    },
    '少阴': {
      'formula': '四逆汤',
      'pattern': '少阴病',
    },
    '厥阴': {
      'formula': '乌梅丸',
      'pattern': '厥阴病',
    },
  };

  // ==================== 六经欲解时 ====================
  static final Map<String, String> meridianHealingTime = {
    '太阳': '巳至未（上午9点-下午1点）',
    '阳明': '申至戌（下午3点-晚上9点）',
    '少阳': '寅至辰（凌晨3点-上午9点）',
    '太阴': '亥至丑（晚上9点-凌晨3点）',
    '少阴': '子至寅（晚上11点-凌晨5点）',
    '厥阴': '丑至卯（凌晨1点-早上7点）',
  };

  // ==================== 头痛辨经 ====================
  static final Map<String, String> headacheLocation = {
    'front': '阳明头痛（前额印堂痛）→ 承气汤类',
    'side': '少阳头痛（两侧偏头痛）→ 小柴胡汤',
    'back': '太阳头痛（后脑脖子僵）→ 葛根汤/桂枝汤',
    'top': '厥阴头痛（头顶最痛）→ 吴茱萸汤',
  };

  // ==================== 失眠辨经 ====================
  static final Map<String, String> insomniaDiagnosis = {
    '太阴': '脾虚失眠 → 归脾汤/小建中汤',
    '少阴': '阴虚火旺失眠（热化，心烦不得卧）→ 黄连阿胶汤',
    '厥阴': '寒热错杂失眠 → 乌梅丸',
    '阳明': '胃不和失眠 → 调胃承气汤',
  };

  // ==================== 便秘辨证 ====================
  static final Map<String, String> constipationDiagnosis = {
    '热秘': '大便硬腹痛拒按 → 承气汤',
    '寒秘': '大便不通但腹冷喜温 → 大黄附子细辛汤',
    '虚秘': '无力排出 → 麻子仁丸',
  };

  // ==================== P0-1: 真寒假热/真热假寒八维鉴别 ====================
  static const Map<String, TrueFalseHeatCold> trueFalseHeatColdData = {
    '真寒假热': TrueFalseHeatCold(
      type: '真寒假热',
      description: '热在皮肤，寒在骨髓。外有假热象，内有真寒证。',
      dimensions: {
        '面色': '两颧色红，界限分明，红部鲜艳，不红部白中带青',
        '口鼻气': '呼出气不温，不急促，气不臭',
        '舌象': '舌虽干而质淡，或红而质润',
        '脉象': '脉虽浮数，按之则无力',
        '胸腹': '按之不蒸手，初按似热，久按不如平人',
        '口渴': '渴喜热饮，饮不多',
        '小便': '清长或不利',
        '大便': '稀溏或完谷不化',
      },
    ),
    '真热假寒': TrueFalseHeatCold(
      type: '真热假寒',
      description: '寒在皮肤，热在骨髓。外有假寒象，内有真热证。',
      dimensions: {
        '面色': '面色虽冷滞，两目炯炯有神',
        '口鼻气': '呼出气必温，急促，或有不臭',
        '舌象': '舌虽干而质燥，苔薄根厚，或黄而疏松',
        '脉象': '脉虽沉细，必兼数急',
        '胸腹': '四肢虽寒，胸腹必热，久按蒸蒸有热气',
        '口渴': '渴喜冷饮，饮多',
        '小便': '黄赤短少',
        '大便': '干结或热臭',
      },
    ),
  };

  // ==================== P1-3: 瘀血五法诊断 ====================
  static const List<BloodStasisSign> bloodStasisFiveMethods = [
    BloodStasisSign(
      method: '望诊',
      description: '面色黧黑，唇舌紫暗，舌有瘀斑瘀点，皮肤有青紫瘀斑',
      clinicalSignificance: '瘀血阻滞，血行不畅，面色失于濡养',
    ),
    BloodStasisSign(
      method: '问诊',
      description: '疼痛如刺、固定不移，夜间加重，或有跌打损伤史',
      clinicalSignificance: '瘀血阻络，不通则痛，夜属阴故夜间加重',
    ),
    BloodStasisSign(
      method: '切诊',
      description: '脉涩或弦紧，或有结代；腹诊可触及包块压痛',
      clinicalSignificance: '血行瘀滞，脉道不利',
    ),
    BloodStasisSign(
      method: '望舌下',
      description: '舌下络脉粗胀、迂曲、色暗紫',
      clinicalSignificance: '舌下络脉为瘀血最直接的望诊指标',
    ),
    BloodStasisSign(
      method: '望眼',
      description: '眼周暗黑，或白睛有赤脉络瘀曲',
      clinicalSignificance: '肝开窍于目，眼周暗黑为肝经瘀血',
    ),
  ];

  // ==================== P1-5: 望面色 ====================
  static final List<FacialComplexion> facialComplexions = [
    FacialComplexion(color: '青色', meridian: '肝/厥阴', formula: '当归四逆汤/吴茱萸汤', description: '面色青，主寒证、痛证、瘀血、惊风'),
    FacialComplexion(color: '赤色', meridian: '阳明/少阳', formula: '白虎汤/小柴胡汤', description: '面色红，主热证。满面通红为实热，午后颧红为虚热'),
    FacialComplexion(color: '黄色', meridian: '太阴/阳明', formula: '茵陈蒿汤/理中汤', description: '面色黄，主湿证、脾虚。鲜明为阳黄，暗淡为阴黄'),
    FacialComplexion(color: '白色', meridian: '太阴/少阴', formula: '四逆汤/理中汤', description: '面色白，主虚证、寒证、失血。晄白为阳虚，淡白为血虚'),
    FacialComplexion(color: '黑色', meridian: '少阴/厥阴', formula: '真武汤/肾气丸', description: '面色黑，主肾虚、寒证、痛证、瘀血、水饮'),
  ];

  // ==================== P0-4: 用药铁律（7禁忌+5误治急救） ====================
  static const List<MedicationRule> medicationRules = [
    // 7大禁忌
    MedicationRule(
      category: '禁忌',
      condition: '太阳表证',
      prohibition: '不可攻下',
      reason: '表证未解先攻里，会引邪入里，导致变证',
      emergencyTreatment: '误下后出现痞证，用半夏泻心汤和解',
    ),
    MedicationRule(
      category: '禁忌',
      condition: '阳明经热（白虎汤证）',
      prohibition: '不可发汗',
      reason: '经热已盛，发汗更伤津液，会导致谵语、烦躁',
      emergencyTreatment: '急下存阴，用承气汤通腑泄热',
    ),
    MedicationRule(
      category: '禁忌',
      condition: '少阳病',
      prohibition: '不可发汗、吐、下',
      reason: '少阳为半表半里，汗吐下皆会导致变证',
      emergencyTreatment: '发汗则谵语（柴胡加龙骨牡蛎汤），吐下则悸而惊（柴胡桂枝干姜汤）',
    ),
    MedicationRule(
      category: '禁忌',
      condition: '太阴虚寒证',
      prohibition: '不可攻下（寒凉药）',
      reason: '脾阳已虚，攻下更伤中阳，必致胸下结硬',
      emergencyTreatment: '理中汤温中健脾，或四逆汤回阳',
    ),
    MedicationRule(
      category: '禁忌',
      condition: '少阴病',
      prohibition: '不可发汗、不可攻下',
      reason: '心肾阳虚，发汗亡阳，攻下亡阴',
      emergencyTreatment: '急温回阳，四逆汤加人参',
    ),
    MedicationRule(
      category: '禁忌',
      condition: '厥阴病',
      prohibition: '不可单独攻下或发汗',
      reason: '寒热错杂，单用攻伐会加重病情',
      emergencyTreatment: '寒热并用，乌梅丸为主方',
    ),
    MedicationRule(
      category: '禁忌',
      condition: '津液亏虚（风温/温病）',
      prohibition: '不可发汗、攻下、火疗',
      reason: '津液已亏，三法皆更伤津液，会导致直视失溲、惊痫瘛疭',
      emergencyTreatment: '生津液为主，白虎加人参汤',
    ),
    // 5大误治急救
    MedicationRule(
      category: '误治急救',
      condition: '误发汗致小便不利',
      prohibition: '汗出过多伤津',
      reason: '津液亏损，化源不足',
      emergencyTreatment: '猪苓汤育阴利水，或五苓散通阳化气',
    ),
    MedicationRule(
      category: '误治急救',
      condition: '误攻下致直视失溲',
      prohibition: '下法伤正，肝血枯',
      reason: '胃肠营养源被截断，肝血不能上注于目',
      emergencyTreatment: '独参汤大补元气，或四逆加人参汤',
    ),
    MedicationRule(
      category: '误治急救',
      condition: '误火疗致发黄惊痫',
      prohibition: '火劫伤津，热入血分',
      reason: '火热内迫，津液枯竭，血分受热',
      emergencyTreatment: '茵陈蒿汤清利湿热，犀角地黄汤凉血',
    ),
    MedicationRule(
      category: '误治急救',
      condition: '误吐致胃气上逆',
      prohibition: '吐法伤胃气',
      reason: '胃气因吐而虚，气逆不降',
      emergencyTreatment: '小半夏汤降逆止呕，或生姜半夏汤',
    ),
    MedicationRule(
      category: '误治急救',
      condition: '误下致胸下结硬',
      prohibition: '下法伤中阳',
      reason: '脾阳受损，寒邪内结',
      emergencyTreatment: '理中汤温中散寒，或枳实薤白桂枝汤宽胸散结',
    ),
  ];

  // ==================== P0-5: 汗法禁忌（10种） ====================
  static const List<SweatingContraindication> sweatingContraindications = [
    SweatingContraindication(condition: '阳明经热证', reason: '里热炽盛，发汗更伤津液', consequence: '大渴引饮、烦躁谵语'),
    SweatingContraindication(condition: '少阳病', reason: '半表半里，汗法不适用', consequence: '发汗则谵语（条文265）'),
    SweatingContraindication(condition: '少阴病', reason: '心肾阳虚，发汗亡阳', consequence: '四肢厥冷加重，脉微欲绝'),
    SweatingContraindication(condition: '太阴虚寒证', reason: '脾阳不足，发汗更虚', consequence: '下利不止，腹满呕吐'),
    SweatingContraindication(condition: '厥阴病', reason: '阴阳错杂，发汗扰乱气机', consequence: '上热下寒加重'),
    SweatingContraindication(condition: '咽喉干燥者', reason: '津液不足（条文83）', consequence: '小便不利，咽喉更干'),
    SweatingContraindication(condition: '淋家', reason: '膀胱津亏（条文84）', consequence: '便血'),
    SweatingContraindication(condition: '疮家', reason: '气血两虚（条文85）', consequence: '痉（筋脉拘急）'),
    SweatingContraindication(condition: '衄家', reason: '失血亡阴（条文86）', consequence: '额上陷脉紧急，直视不能眴'),
    SweatingContraindication(condition: '亡血家', reason: '气血大虚（条文87）', consequence: '寒栗而振'),
  ];

  // ==================== P1-7: 传经判断 ====================
  static final List<MeridianTransmission> meridianTransmissions = [
    MeridianTransmission(from: '太阳', to: '阳明', sign: '烦躁、口渴、但热不寒', treatment: '清热泻下，白虎汤/承气汤'),
    MeridianTransmission(from: '太阳', to: '少阳', sign: '口苦、咽干、呕吐、往来寒热', treatment: '和解少阳，小柴胡汤'),
    MeridianTransmission(from: '太阳', to: '少阴', sign: '但欲寐、四肢厥冷、脉微细', treatment: '急温回阳，四逆汤'),
    MeridianTransmission(from: '少阳', to: '阳明', sign: '便秘、潮热、腹满痛', treatment: '和解兼攻下，大柴胡汤/柴胡加芒硝汤'),
    MeridianTransmission(from: '太阴', to: '少阴', sign: '但欲寐加重、下利清谷', treatment: '温阳回逆，四逆汤'),
    MeridianTransmission(from: '少阴', to: '厥阴', sign: '消渴、气上撞心、寒热错杂', treatment: '寒热并用，乌梅丸'),
  ];

  // ==================== P1-4: 组合脉象 ====================
  static const List<PulseCombination> pulseCombinations = [
    PulseCombination(pulse1: '浮', pulse2: '紧', meridian: '太阳', formula: '麻黄汤', description: '太阳伤寒表实证，无汗恶寒'),
    PulseCombination(pulse1: '浮', pulse2: '缓', meridian: '太阳', formula: '桂枝汤', description: '太阳中风表虚证，有汗恶风'),
    PulseCombination(pulse1: '浮', pulse2: '数', meridian: '太阳/阳明', formula: '桂枝二麻黄一汤/白虎汤', description: '表热或里热，需辨寒热'),
    PulseCombination(pulse1: '洪', pulse2: '大', meridian: '阳明', formula: '白虎汤', description: '阳明经热，大热大汗大渴'),
    PulseCombination(pulse1: '沉', pulse2: '迟', meridian: '少阴', formula: '四逆汤', description: '少阴寒化，阳虚寒盛'),
    PulseCombination(pulse1: '沉', pulse2: '细', meridian: '少阴', formula: '真武汤/附子汤', description: '少阴水饮或经脉寒湿'),
    PulseCombination(pulse1: '弦', pulse2: '细', meridian: '少阳', formula: '小柴胡汤', description: '少阳病，半表半里'),
    PulseCombination(pulse1: '弦', pulse2: '滑', meridian: '阳明/少阳', formula: '大柴胡汤', description: '少阳阳明合病，兼有里实'),
    PulseCombination(pulse1: '微', pulse2: '细', meridian: '少阴', formula: '四逆汤', description: '少阴病脉微细，但欲寐（条文281）'),
    PulseCombination(pulse1: '涩', pulse2: '弦', meridian: '厥阴', formula: '当归四逆汤', description: '血虚寒凝，脉细欲绝'),
    PulseCombination(pulse1: '结', pulse2: '代', meridian: '少阴', formula: '炙甘草汤', description: '气血两虚，脉结代心动悸'),
    PulseCombination(pulse1: '滑', pulse2: '数', meridian: '阳明', formula: '小承气汤', description: '阳明腑实，热结在里'),
  ];

  // ==================== P1-6: 条文级鉴别要点扩展 ====================
  static const List<PatternDifferential> patternDifferentials = [
    PatternDifferential(
      pattern1: '桂枝汤证（中风）',
      pattern2: '麻黄汤证（伤寒）',
      classicText: '太阳病，发热汗出恶风脉缓者名为中风；或已发热或未发热，必恶寒体痛呕逆脉阴阳俱紧者名曰伤寒（条文2-3）',
      keyPoint: '有汗vs无汗——中风有汗用桂枝，伤寒无汗用麻黄',
      niNote: '滤过性病毒千百种，只分这两种——按症处方就是辨症论治',
    ),
    PatternDifferential(
      pattern1: '白虎汤证（经热）',
      pattern2: '承气汤证（腑实）',
      classicText: '阳明之为病胃家实是也（条文179）',
      keyPoint: '经热=大热大汗大渴脉洪大（白虎）；腑实=便秘腹满痛拒按（承气）',
      niNote: '先辨经热还是腑实，再选方。阳明无死证。',
    ),
    PatternDifferential(
      pattern1: '小柴胡汤证',
      pattern2: '大柴胡汤证',
      classicText: '太阳病过经十余日，反二三下之，后四五日柴胡证仍在者，先与小柴胡（条文101）',
      keyPoint: '小柴胡=无便秘；大柴胡=兼便秘腹满（少阳阳明合病）',
      niNote: '大柴胡是小柴胡去人参甘草，加枳实芍药大黄。有便秘才能用大黄。',
    ),
    PatternDifferential(
      pattern1: '真武汤证',
      pattern2: '附子汤证',
      classicText: '少阴病，身体痛，手足寒，骨节痛，脉沉者，附子汤主之（条文305）',
      keyPoint: '真武汤=水饮（心悸头眩身瞤动）；附子汤=经脉寒湿（身体痛骨节痛）',
      niNote: '真武汤重在利水，附子汤重在温经散寒止痛。',
    ),
    PatternDifferential(
      pattern1: '四逆汤证',
      pattern2: '通脉四逆汤证',
      classicText: '少阴病，下利清谷，里寒外热，手足厥逆，脉微欲绝（条文317）',
      keyPoint: '四逆汤=一般四肢厥冷；通脉四逆=阴盛格阳（身反不恶寒、面色赤）',
      niNote: '通脉四逆是四逆汤重用干姜，破阴通阳。',
    ),
    PatternDifferential(
      pattern1: '苓桂术甘汤证',
      pattern2: '真武汤证',
      classicText: '伤寒若吐若下后，心下逆满，气上冲胸，起则头眩（条文67）',
      keyPoint: '苓桂术甘=水气上冲（轻证，脾虚水停）；真武=阳虚水泛（重证，肾阳虚）',
      niNote: '苓桂术甘是水在中焦，真武汤是水在下焦波及全身。',
    ),
    PatternDifferential(
      pattern1: '黄连阿胶汤证',
      pattern2: '栀子豉汤证',
      classicText: '少阴病，得之二三日以上，心中烦，不得卧（条文303）',
      keyPoint: '黄连阿胶=心肾不交（失眠+舌红少苔）；栀子豉=虚烦（心中懊憹+无实热）',
      niNote: '黄连阿胶汤有阿胶鸡子黄补心血，栀子豉汤只是清虚热。',
    ),
    PatternDifferential(
      pattern1: '五苓散证',
      pattern2: '猪苓汤证',
      classicText: '太阳病，发汗后，脉浮，小便不利，微热消渴者（条文71）',
      keyPoint: '五苓散=水热互结偏表（脉浮+微热）；猪苓汤=阴虚水热（血尿+口渴）',
      niNote: '五苓散用桂枝通阳化气，猪苓汤用阿胶育阴利水。',
    ),
  ];

  // ==================== 舌脉矛盾检测 ====================
  static final Map<String, Map<String, String>> pulseTongueContradictions = {
    '浮脉+黄厚苔': {
      'warning': '脉浮（表证）但苔黄厚（里热），可能存在表里同病',
      'suggestion': '需鉴别：是否太阳阳明合病？有无恶寒？',
    },
    '沉脉+薄白苔': {
      'warning': '脉沉（里证）但苔薄白（正常/表证），舌脉不一致',
      'suggestion': '可能为里证初起或表证已解，需结合问诊判断',
    },
    '数脉+淡白舌': {
      'warning': '脉数（热证）但舌淡白（虚寒），寒热矛盾',
      'suggestion': '真寒假热可能？需查：渴喜热饮？小便清长？四肢厥冷？',
    },
    '迟脉+红舌': {
      'warning': '脉迟（寒证）但舌红（热证），寒热矛盾',
      'suggestion': '真热假寒可能？需查：胸腹热？渴喜冷饮？小便黄赤？',
    },
    '微脉+洪脉': {
      'warning': '脉微（虚极）与洪脉（实热）不可能同时出现',
      'suggestion': '请重新确认脉象，或为不同部位脉象不同（寸关尺异脉）',
    },
  };

  // ==================== 六经详情数据 ====================
  static final Map<String, Map<String, dynamic>> meridianDetails = {
    '太阳': {
      'emoji': '☀️',
      'color': '#FF9800',
      'nature': '寒水',
      'organ': '膀胱·小肠',
      'keyPulse': '脉浮，头项强痛而恶寒',
      'coreSymptoms': ['脉浮', '头项强痛', '恶寒', '发热'],
      'healingTime': '巳至未（上午9点-下午1点）',
      'transmissionIn': '外邪入侵第一站',
      'transmissionOut': ['阳明', '少阳', '少阴'],
      'classicText': '太阳之为病，脉浮，头项强痛而恶寒。（条文1）',
      'niNote': '太阳为寒水，常人皮肤表面冰凉，手脚温热。体表有太阳寒水保卫人体。浮脉是太阳病第一症状。',
      'formulas': ['桂枝汤', '麻黄汤', '桂枝加葛根汤', '大青龙汤', '小青龙汤', '葛根汤', '麻杏甘石汤'],
    },
    '阳明': {
      'emoji': '🔥',
      'color': '#F44336',
      'nature': '燥金',
      'organ': '胃·大肠',
      'keyPulse': '脉洪大，身热汗出，不恶寒反恶热',
      'coreSymptoms': ['但热不寒', '身热', '汗出', '大渴', '脉洪大', '便秘'],
      'healingTime': '申至戌（下午3点-晚上9点）',
      'transmissionIn': ['太阳', '少阳'],
      'transmissionOut': ['阳明无死证，病到此为止'],
      'classicText': '阳明之为病，胃家实是也。（条文179）',
      'niNote': '阳明病但热不寒，分经热（白虎汤）和腑实（承气汤）。阳明无死证，是最安全的经。',
      'formulas': ['白虎汤', '白虎加人参汤', '大承气汤', '小承气汤', '调胃承气汤', '栀子豉汤'],
    },
    '少阳': {
      'emoji': '🌅',
      'color': '#FF5722',
      'nature': '风木',
      'organ': '胆·三焦',
      'keyPulse': '脉弦，口苦咽干目眩',
      'coreSymptoms': ['口苦', '咽干', '目眩', '往来寒热', '胸胁苦满', '心烦喜呕'],
      'healingTime': '寅至辰（凌晨3点-上午9点）',
      'transmissionIn': ['太阳', '阳明'],
      'transmissionOut': ['太阴', '阳明'],
      'classicText': '少阳之为病，口苦，咽干，目眩也。（条文263）',
      'niNote': '少阳为半表半里，位于太阳和阳明之间。但见一证便是，不必悉具。小柴胡汤是和解第一方。',
      'formulas': ['小柴胡汤', '大柴胡汤', '柴胡加芒硝汤', '柴胡加龙骨牡蛎汤', '柴胡桂枝汤'],
    },
    '太阴': {
      'emoji': '🌙',
      'color': '#2196F3',
      'nature': '湿土',
      'organ': '脾·肺',
      'keyPulse': '脉缓弱，腹满而吐，食不下，自利益甚',
      'coreSymptoms': ['腹满', '呕吐', '食不下', '自利', '腹痛', '手足自温'],
      'healingTime': '亥至丑（晚上9点-凌晨3点）',
      'transmissionIn': ['少阳'],
      'transmissionOut': ['少阴'],
      'classicText': '太阴之为病，腹满而吐，食不下，自利益甚，时腹自痛。若下之，必胸下结硬。（条文273）',
      'niNote': '太阴是脾脏，脾虚寒湿。太阴病属里虚寒证，不可攻下。理中汤是太阴病主方。',
      'formulas': ['理中汤', '四逆汤', '小建中汤', '厚朴生姜半夏甘草人参汤', '防己黄芪汤'],
    },
    '少阴': {
      'emoji': '🌑',
      'color': '#9C27B0',
      'nature': '君火/寒水',
      'organ': '心·肾',
      'keyPulse': '脉微细，但欲寐',
      'coreSymptoms': ['脉微细', '但欲寐', '四肢厥冷', '下利清谷', '小便清长'],
      'healingTime': '子至寅（晚上11点-凌晨5点）',
      'transmissionIn': ['太阴'],
      'transmissionOut': ['厥阴'],
      'classicText': '少阴之为病，脉微细，但欲寐也。（条文281）',
      'niNote': '少阴是心肾阳虚，是最危险的经证之一。少阴病急温之，四逆汤为主方。分寒化和热化。',
      'formulas': ['四逆汤', '真武汤', '附子汤', '黄连阿胶汤', '桃花汤', '麻黄附子细辛汤'],
    },
    '厥阴': {
      'emoji': '☯️',
      'color': '#607D8B',
      'nature': '风木/相火',
      'organ': '肝·心包',
      'keyPulse': '脉弦或微欲绝，寒热错杂',
      'coreSymptoms': ['消渴', '气上撞心', '心中疼热', '饥而不欲食', '上热下寒'],
      'healingTime': '丑至卯（凌晨1点-早上7点）',
      'transmissionIn': ['少阴'],
      'transmissionOut': ['阴之尽，出则生'],
      'classicText': '厥阴之为病，消渴，气上撞心，心中疼热，饥而不欲食，食则吐蛔，下之利不止。（条文326）',
      'niNote': '厥阴是阴之尽，寒热并结。乌梅丸是厥阴病主方。阴阳不相顺接则为厥。厥阴病治好了会回到太阳。',
      'formulas': ['乌梅丸', '当归四逆汤', '吴茱萸汤', '四逆散'],
    },
  };
}
