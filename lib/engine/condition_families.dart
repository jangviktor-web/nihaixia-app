// 自动生成：金匮证候族鉴别树（双轨通道B） — 由 gen_families.py 产出
// 每个族 1 问；选项文本 = 触发词+证候（→方剂），子串匹配即命中引擎。
import 'diagnostic_rules.dart';

/// 主诉两级导航·第一级大类
class ChiefCategory {
  final String id;
  final String name;
  final String emoji;
  const ChiefCategory({required this.id, required this.name, required this.emoji});
}

/// 主诉两级导航·第二级证候词（= 证候族）
class ConditionTerm {
  final String key;        // 如 'fam_chest_bi'
  final String label;     // 白话+原文：'胸痹（胸闷胸痛）'
  final String family;    // 证候族 id
  final String emoji;
  const ConditionTerm({required this.key, required this.label, required this.family, this.emoji = '🩺'});
}

class ConditionFamilyData {
  static const List<ChiefCategory> chiefCategories = [
    ChiefCategory(id: 'cat1', name: '感冒发热', emoji: '🤒'),
    ChiefCategory(id: 'cat2', name: '头面颈项', emoji: '🤕'),
    ChiefCategory(id: 'cat3', name: '咳喘胸痹', emoji: '😷'),
    ChiefCategory(id: 'cat4', name: '心下胃脘', emoji: '🤢'),
    ChiefCategory(id: 'cat5', name: '腹满寒疝', emoji: '🫃'),
    ChiefCategory(id: 'cat6', name: '呕吐下利', emoji: '🤮'),
    ChiefCategory(id: 'cat7', name: '水肿小便', emoji: '💧'),
    ChiefCategory(id: 'cat8', name: '黄疸', emoji: '🟡'),
    ChiefCategory(id: 'cat9', name: '肢体痹痛', emoji: '🦴'),
    ChiefCategory(id: 'cat10', name: '妇人病', emoji: '🩸'),
    ChiefCategory(id: 'cat11', name: '虚劳失眠', emoji: '😴'),
    ChiefCategory(id: 'cat12', name: '杂病疑难', emoji: '🩹'),
  ];

  /// 二级证候词（Step1 两级导航的叶子节点，按大类分组）
  static const List<ConditionTerm> conditionTerms = [
    ConditionTerm(key: 'fam_bai_he', label: '百合狐惑（精神恍惚、口咽溃疡）', family: 'bai_he'),
    ConditionTerm(key: 'fam_ben_tun', label: '奔豚（气从下腹往上冲）', family: 'ben_tun'),
    ConditionTerm(key: 'fam_chan_hou', label: '妇人产后（产后腹痛、中风、下利）', family: 'chan_hou'),
    ConditionTerm(key: 'fam_chest_bi', label: '胸痹（胸闷胸痛、心痛彻背）', family: 'chest_bi'),
    ConditionTerm(key: 'fam_chong', label: '蛔虫狐疝（蛔虫、疝气、抽筋）', family: 'chong'),
    ConditionTerm(key: 'fam_chuang_yong', label: '疮痈肠痈（疮疡肿毒、肠痈）', family: 'chuang_yong'),
    ConditionTerm(key: 'fam_fei_wei', label: '肺痿肺痈（咳吐浊痰、肺中热壅）', family: 'fei_wei'),
    ConditionTerm(key: 'fam_fu_man', label: '腹满寒疝（肚子胀满、寒气攻痛）', family: 'fu_man'),
    ConditionTerm(key: 'fam_huang_dan', label: '黄疸（皮肤眼睛发黄）', family: 'huang_dan'),
    ConditionTerm(key: 'fam_jie_xiong', label: '结胸痞证（胸口或胃脘硬满、按着痛）', family: 'jie_xiong'),
    ConditionTerm(key: 'fam_jing_ji', label: '惊悸吐衄（心悸、吐血、便血）', family: 'jing_ji'),
    ConditionTerm(key: 'fam_nve', label: '疟病（寒热往来像打摆子）', family: 'nve'),
    ConditionTerm(key: 'fam_ou_tu', label: '呕吐哕下利（呕吐、呃逆、下利）', family: 'ou_tu'),
    ConditionTerm(key: 'fam_ren_shen', label: '妇人妊娠（怀孕期间诸症）', family: 'ren_shen'),
    ConditionTerm(key: 'fam_shang_han_bian', label: '伤寒表变（表证变方、寒热往来）', family: 'shang_han_bian'),
    ConditionTerm(key: 'fam_shui_qi', label: '水气水肿（身体浮肿、水液停留）', family: 'shui_qi'),
    ConditionTerm(key: 'fam_tan_yin', label: '痰饮咳嗽（水饮停聚、咳喘痰多）', family: 'tan_yin'),
    ConditionTerm(key: 'fam_xiao_ke', label: '消渴小便（口渴多饮、小便异常）', family: 'xiao_ke'),
    ConditionTerm(key: 'fam_xu_lao', label: '虚劳血痹（体虚乏力、失眠、失精）', family: 'xu_lao'),
    ConditionTerm(key: 'fam_za_bing', label: '杂病综合（其他杂病）', family: 'za_bing'),
    ConditionTerm(key: 'fam_za_bing_fu', label: '妇人杂病（月经不调、带下、情志）', family: 'za_bing_fu'),
    ConditionTerm(key: 'fam_zhong_feng', label: '中风历节（半身不遂、关节剧痛）', family: 'zhong_feng'),
  ];

  /// 证候族 → 鉴别问（金匮证候族，对应 Step5 通道B）
  static const Map<String, List<FollowUpQuestion>> conditionFollowUps = {
    'bai_he': [
      FollowUpQuestion(key: 'cf_bai_he', question: '【百合狐惑族鉴别】你的情况更像哪种？（精神恍惚、口咽溃疡）', options: [
          '阳毒（→升麻鳖甲汤）',
          '百合病（→栝蒌牡蛎散）',
          '百合病（→百合地黄汤）',
          '百合病，下之后（→百合滑石代赭汤）',
          '百合病，发热（→百合滑石散）',
          '百合病，发汗后（→百合知母汤）',
          '百合病，吐之后（→百合鸡子黄汤）',
          '狐惑（→赤豆当归散）',
      ]),
    ],
    'ben_tun': [
      FollowUpQuestion(key: 'cf_ben_tun', question: '【奔豚族鉴别】你的情况更像哪种？（气从下腹往上冲）', options: [
          '奔豚，往来寒热（→奔豚汤）',
          '奔豚（→桂枝加桂汤）',
          '脐下悸（→苓桂甘枣汤）',
      ]),
    ],
    'chan_hou': [
      FollowUpQuestion(key: 'cf_chan_hou', question: '【妇人产后族鉴别】你的情况更像哪种？（产后腹痛、中风、下利）', options: [
          '产后腹痛（→下瘀血汤）',
          '产后腹痛，烦满不得卧（→枳实芍药散）',
          '产后下利（→白头翁加甘草阿胶汤）',
          '产后中风（→竹叶汤）',
          '漏下黑不解（→胶姜汤）',
      ]),
    ],
    'chest_bi': [
      FollowUpQuestion(key: 'cf_chest_bi', question: '【胸痹族鉴别】你的情况更像哪种？（胸闷胸痛、心痛彻背）', options: [
          '心痛彻背（→乌头赤石脂丸）',
          '胸痹，胁下逆抢心（→枳实薤白桂枝汤）',
          '胸痹，不得卧（→栝蒌薤白半夏汤）',
          '胸痹（→栝蒌薤白白酒汤）',
          '心中痞，心悬痛（→桂枝生姜枳实汤）',
          '胸痹，胸中气塞（→橘枳生姜汤）',
          '胸痹，短气，胸中气塞（→茯苓杏仁甘草汤）',
          '胸痹，缓急（→薏苡附子散）',
      ]),
    ],
    'chong': [
      FollowUpQuestion(key: 'cf_chong', question: '【蛔虫狐疝族鉴别】你的情况更像哪种？（蛔虫、疝气、抽筋）', options: [
          '蛔虫（→甘草粉蜜汤）',
          '狐疝（→蜘蛛散）',
          '转筋（→鸡矢白散）',
      ]),
    ],
    'chuang_yong': [
      FollowUpQuestion(key: 'cf_chuang_yong', question: '【疮痈肠痈族鉴别】你的情况更像哪种？（疮疡肿毒、肠痈）', options: [
          '肠痈（→大黄牡丹汤）',
          '疮痈，脓已成（→排脓散/排脓汤）',
          '排脓，乳癌（→术附汤）',
          '肠痈，脓已成（→薏苡附子败酱散）',
          '阴疽（→阳和汤）',
          '足烂疮（→附子散）',
      ]),
    ],
    'fei_wei': [
      FollowUpQuestion(key: 'cf_fei_wei', question: '【肺痿肺痈族鉴别】你的情况更像哪种？（咳吐浊痰、肺中热壅）', options: [
          '肺胀（→小青龙加石膏汤）',
          '肺痛（→紫参汤）',
          '肺痈，喘不得卧（→葶苈大枣泻肺汤）',
          '肺胀，目如脱状（→越婢加半夏汤）',
          '火逆上气（→麦门冬汤）',
      ]),
    ],
    'fu_man': [
      FollowUpQuestion(key: 'cf_fu_man', question: '【腹满寒疝族鉴别】你的情况更像哪种？（肚子胀满、寒气攻痛）', options: [
          '寒疝，手足不仁（→乌头桂枝汤）',
          '心胸中大寒痛（→大建中汤）',
          '胁下偏痛（→大黄附子汤）',
          '寒疝，胁痛里急（→当归生姜羊肉汤）',
          '寒气厥逆（→赤丸）',
          '雷鸣切痛（→附子粳米汤）',
      ]),
    ],
    'huang_dan': [
      FollowUpQuestion(key: 'cf_huang_dan', question: '【黄疸族鉴别】你的情况更像哪种？（皮肤眼睛发黄）', options: [
          '黄疸，腹满，小便赤（→大黄硝石汤）',
          '诸黄（→猪膏髪煎）',
          '女劳（→硝石矾石散）',
          '黄疸（→茵陈五苓散）',
      ]),
    ],
    'jie_xiong': [
      FollowUpQuestion(key: 'cf_jie_xiong', question: '【结胸痞证族鉴别】你的情况更像哪种？（胸口或胃脘硬满、按着痛）', options: [
          '结胸（→三物小白散）',
          '心下痞，腹中雷鸣（→半夏泻心汤）',
          '结胸，项强（→大陷胸丸）',
          '结胸（→大陷胸汤）',
          '结胸（→小陷胸汤）',
          '心下痞，噫气（→旋覆代赭石汤）',
          '心中结痛（→栀子枳实汤）',
          '胸中痞硬，气上冲（→瓜蒂散）',
          '心下痞，腹中雷鸣，食臭（→生姜泻心汤）',
      ]),
    ],
    'jing_ji': [
      FollowUpQuestion(key: 'cf_jing_ji', question: '【惊悸吐衄族鉴别】你的情况更像哪种？（心悸、吐血、便血）', options: [
          '吐血不止（→柏叶汤）',
          '心气不足（→泻心汤）',
          '先便后血（→黄土汤）',
      ]),
    ],
    'nve': [
      FollowUpQuestion(key: 'cf_nve', question: '【疟病族鉴别】你的情况更像哪种？（寒热往来像打摆子）', options: [
          '牝疟（→蜀漆散）',
          '疟母（→鳖甲煎丸）',
      ]),
    ],
    'ou_tu': [
      FollowUpQuestion(key: 'cf_ou_tu', question: '【呕吐哕下利族鉴别】你的情况更像哪种？（呕吐、呃逆、下利）', options: [
          '霍乱（→四逆加人参汤）',
          '胃反（→大半夏汤）',
          '食已即吐（→大黄甘草汤）',
          '饮水不止（→文蛤散）',
          '哕逆（→橘皮汤）',
          '呃逆（→橘皮竹茹汤）',
          '似喘不喘（→生姜半夏汤）',
          '胃反（→茯苓泽泻汤）',
          '气利（→诃黎勒散）',
          '吐已下断（→通脉四逆加猪胆汁汤）',
          '里寒外热（→通脉四逆汤）',
      ]),
    ],
    'ren_shen': [
      FollowUpQuestion(key: 'cf_ren_shen', question: '【妇人妊娠族鉴别】你的情况更像哪种？（怀孕期间诸症）', options: [
          '妊娠，养胎（→当归散）',
          '妊娠，腹中㽲痛（→当归芍药散）',
          '妊娠，小便难（→当归贝母苦参丸）',
          '症病（→桂枝茯苓丸）',
          '妊娠，白术散（→白术散）',
          '妊娠（→葵子茯苓散）',
      ]),
    ],
    'shang_han_bian': [
      FollowUpQuestion(key: 'cf_shang_han_bian', question: '【伤寒表变族鉴别】你的情况更像哪种？（表证变方、寒热往来）', options: [
          '少腹硬满，发狂（→抵当汤）',
          '劳复（→枳实栀子豉汤）',
          '潮热，胸胁满（→柴胡加芒硝汤）',
          '胸胁满微结（→柴胡桂枝干姜汤）',
          '支节烦疼（→柴胡桂枝汤）',
          '热多寒少（→桂枝二越婢一汤）',
          '日再发（→桂枝二麻黄一汤）',
          '惊狂（→桂枝去芍药加蜀漆龙骨牡蛎救逆汤）',
          '拉肚子+发热（→葛根黄芩黄连汤）',
      ]),
    ],
    'shui_qi': [
      FollowUpQuestion(key: 'cf_shui_qi', question: '【水气水肿族鉴别】你的情况更像哪种？（身体浮肿、水液停留）', options: [
          '心下坚，大如盘（→枳术汤）',
          '黄汗（→桂枝加黄芪汤）',
          '大病差后，腰以下水气（→牡蛎泽泻散）',
          '腰中冷（→甘姜苓术汤）',
          '身面浮肿（→甘草麻黄汤）',
          '身肿（→越婢加术汤）',
          '风水，一身悉肿（→越婢汤）',
          '四肢肿，聂聂动（→防己茯苓汤）',
      ]),
    ],
    'tan_yin': [
      FollowUpQuestion(key: 'cf_tan_yin', question: '【痰饮咳嗽族鉴别】你的情况更像哪种？（水饮停聚、咳喘痰多）', options: [
          '心下痞硬，引胁下痛（→十枣汤）',
          '支饮，胸满（→厚朴大黄汤）',
          '膈间有水（→小半夏加茯苓汤）',
          '谷不得下（→小半夏汤）',
          '支饮（→小青龙汤加减）',
          '腹满，口舌干燥（→己椒苈黄丸）',
          '膈间支饮（→木防己汤）',
          '苦冒眩（→泽泻汤）',
          '留饮（→甘遂半夏汤）',
          '痰饮咳嗽（→苓甘五味姜辛汤）',
      ]),
    ],
    'xiao_ke': [
      FollowUpQuestion(key: 'cf_xiao_ke', question: '【消渴小便族鉴别】你的情况更像哪种？（口渴多饮、小便异常）', options: [
          '小便不利，水入即吐（→五苓散）',
          '白鱼（→滑石白鱼散）',
          '戎盐（→茯苓戎盐汤）',
          '小便数（→麻子仁丸）',
      ]),
    ],
    'xu_lao': [
      FollowUpQuestion(key: 'cf_xu_lao', question: '【虚劳血痹族鉴别】你的情况更像哪种？（体虚乏力、失眠、失精）', options: [
          '肌肤甲错（→大黄蟅虫丸）',
          '失精（→天雄散）',
          '血虚兼血瘀（→桃红四物汤）',
          '虚羸少气（→竹叶石膏汤）',
          '虚烦（→酸枣仁汤）',
          '身体不仁（→黄芪桂枝五物汤）',
      ]),
    ],
    'za_bing': [
      FollowUpQuestion(key: 'cf_za_bing', question: '【杂病综合族鉴别】你的情况更像哪种？（其他杂病）', options: [
          '肝着（→旋覆花汤）',
      ]),
    ],
    'za_bing_fu': [
      FollowUpQuestion(key: 'cf_za_bing_fu', question: '【妇人杂病族鉴别】你的情况更像哪种？（月经不调、带下、情志）', options: [
          '梅核气（→半夏厚朴汤）',
          '经水不利，少腹满痛（→土瓜根散）',
          '水与血俱结（→大黄甘遂汤）',
          '月经不调（→温经汤）',
          '经水闭不利（→矾石丸）',
      ]),
    ],
    'zhong_feng': [
      FollowUpQuestion(key: 'cf_zhong_feng', question: '【中风历节族鉴别】你的情况更像哪种？（半身不遂、关节剧痛）', options: [
          '四肢烦重（→侯氏黑散）',
          '手足拘急，百节疼痛（→千金三黄汤）',
          '中风，半身不遂（→小续命汤）',
          '肢节疼痛，脚肿（→桂枝芍药知母汤）',
          '身体疼烦，不能自转侧（→桂枝附子汤）',
          '骨节疼烦，掣痛（→甘草附子汤）',
          '如狂，独语不休（→防己地黄汤）',
          '惊痫（→风引汤）',
          '身烦疼，湿（→麻黄加术汤）',
          '一身尽疼（→麻黄杏仁薏苡甘草汤）',
      ]),
    ],
  };

  /// 证候族 → 大类（供 Step1 两级导航分组）
  static const Map<String, String> familyCategory = {
    'chest_bi': 'cat3',
    'jie_xiong': 'cat4',
    'ben_tun': 'cat12',
    'tan_yin': 'cat3',
    'shui_qi': 'cat7',
    'huang_dan': 'cat8',
    'ren_shen': 'cat10',
    'chan_hou': 'cat10',
    'za_bing_fu': 'cat10',
    'bai_he': 'cat12',
    'nve': 'cat12',
    'fei_wei': 'cat3',
    'xu_lao': 'cat11',
    'fu_man': 'cat5',
    'chuang_yong': 'cat12',
    'ou_tu': 'cat6',
    'jing_ji': 'cat11',
    'zhong_feng': 'cat9',
    'chong': 'cat12',
    'xiao_ke': 'cat7',
    'shang_han_bian': 'cat1',
    'za_bing': 'cat12',
  };
}
