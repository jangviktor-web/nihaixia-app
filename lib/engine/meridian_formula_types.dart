/// 六经公式分型速查（v1.11.8 新增，供诊断结果页「六经公式分型」展示）。
///
/// 结构借鉴《命理统一工作台》中医辨证模块（Wsy-prog/tcm-diagnosis-system v3.4，
/// MIT）的 DIAG_FORMULAS 分型组织法：每经下分若干「公式分型」，
/// 各含 核心症状 / 脉象 / 治法 / 代表方，并附本经辨证要点（keys）。
/// 数据依倪师经方口径逐条核对（与 App 引擎 diagnostic_rules 同源）。
/// 仅供中医学习，不构成医疗建议。
library;

class MeridianFormulaType {
  final String name; // 分型名，如「中风」「经热」「寒化」
  final String sym; // 核心症状
  final String pulse; // 脉象
  final String treat; // 治法
  final String rx; // 代表方
  const MeridianFormulaType({
    required this.name,
    required this.sym,
    required this.pulse,
    required this.treat,
    required this.rx,
  });
}

class MeridianFormulaFamily {
  final String meridian; // 六经名
  final String tag; // 提纲
  final List<String> ifs; // 提纲要点
  final String keys; // 本经辨证要点/铁律
  final List<MeridianFormulaType> types; // 公式分型
  const MeridianFormulaFamily({
    required this.meridian,
    required this.tag,
    required this.ifs,
    required this.keys,
    required this.types,
  });
}

/// 六经公式分型全集（太阳 / 阳明 / 少阳 / 太阴 / 少阴 / 厥阴）。
const List<MeridianFormulaFamily> meridianFormulaTypes = [
  MeridianFormulaFamily(
    meridian: '太阳',
    tag: '提纲：脉浮，头项强痛而恶寒',
    ifs: ['脉浮', '头项强痛', '恶寒'],
    keys: '有汗 vs 无汗是太阳病第一鉴别点。禁忌：酒客不可用桂枝汤；脉浮紧无汗者不可用桂枝汤；有表证时绝对不可攻里。',
    types: [
      MeridianFormulaType(
        name: '中风',
        sym: '发热 + 汗出 + 恶风',
        pulse: '浮缓',
        treat: '解肌',
        rx: '桂枝汤',
      ),
      MeridianFormulaType(
        name: '伤寒',
        sym: '发热 + 无汗 + 恶寒 + 体痛',
        pulse: '浮紧',
        treat: '发汗',
        rx: '麻黄汤',
      ),
      MeridianFormulaType(
        name: '温病',
        sym: '发热而渴 + 不恶寒',
        pulse: '浮数',
        treat: '生津解表',
        rx: '桂枝加葛根汤',
      ),
    ],
  ),
  MeridianFormulaFamily(
    meridian: '阳明',
    tag: '提纲：胃家实是也',
    ifs: ['身热', '汗自出', '不恶寒反恶热', '脉大'],
    keys: '阳明无寒证，全是热证。舌苔黄燥→阳明；大渴饮冷→阳明。腑实分层：轻证调胃承气汤、中证小承气汤、重证大承气汤。',
    types: [
      MeridianFormulaType(
        name: '经热',
        sym: '大汗 + 大烦渴 + 脉洪大',
        pulse: '洪大',
        treat: '清热生津',
        rx: '白虎汤（加人参）',
      ),
      MeridianFormulaType(
        name: '腑热',
        sym: '腹满 + 便秘 + 谵语',
        pulse: '沉实',
        treat: '攻下',
        rx: '承气汤类',
      ),
    ],
  ),
  MeridianFormulaFamily(
    meridian: '少阳',
    tag: '提纲：口苦，咽干，目眩也',
    ifs: ['口苦', '咽干', '目眩', '往来寒热', '胸胁苦满', '呕'],
    keys: '少阳三禁（铁律）：汗之则谵语，下之则悸而惊，吐之则烦而悸。只能和解。有呕就想到少阳。但见一证便是，不必悉具。',
    types: [
      MeridianFormulaType(
        name: '少阳主证',
        sym: '口苦 + 咽干 + 目眩 + 往来寒热 + 胸胁苦满 + 呕',
        pulse: '弦',
        treat: '和解',
        rx: '小柴胡汤',
      ),
    ],
  ),
  MeridianFormulaFamily(
    meridian: '太阴',
    tag: '提纲：腹满而吐，食不下，自利益甚，时腹自痛',
    ifs: ['腹满', '呕吐', '食不下', '自利', '时腹自痛', '不口渴'],
    keys: '太阴 = 脾，阴之始。下利是湿的溏的（不是水泻）。不口渴 = 湿在中焦。太阴 vs 阳明：寒 vs 热、不渴 vs 大渴、溏 vs 秘、喜按 vs 拒按、白厚 vs 黄燥。',
    types: [
      MeridianFormulaType(
        name: '太阴脾虚',
        sym: '腹满 + 下利（溏湿）+ 不口渴 + 舌苔白厚',
        pulse: '浮缓/弱',
        treat: '温中',
        rx: '理中汤/理中丸、四逆辈',
      ),
    ],
  ),
  MeridianFormulaFamily(
    meridian: '少阴',
    tag: '提纲：脉微细，但欲寐也',
    ifs: ['脉微细', '但欲寐', '恶寒蜷卧', '手足逆冷'],
    keys: '少阴 = 心 + 肾，阴之中。微脉 = 气衰弱，细脉 = 血不够。绝对不可发汗（亡阳），不可攻下。自利而渴者属少阴（引水自救）。小便色白 = 下焦虚寒。',
    types: [
      MeridianFormulaType(
        name: '寒化',
        sym: '舌淡苔白 + 脉微细 + 但欲寐 + 小便清长',
        pulse: '微细沉微',
        treat: '回阳救逆',
        rx: '四逆汤/真武汤',
      ),
      MeridianFormulaType(
        name: '热化',
        sym: '舌红少苔 + 脉细数 + 心烦不得卧',
        pulse: '细数',
        treat: '滋阴清热',
        rx: '黄连阿胶汤',
      ),
    ],
  ),
  MeridianFormulaFamily(
    meridian: '厥阴',
    tag: '提纲：消渴，气上撞心，心中疼热，饥而不欲食，食则吐蛔',
    ifs: ['消渴', '气上撞心', '心中疼热', '饥而不欲食', '下利', '手足厥逆', '寒热错杂'],
    keys: '厥阴 = 肝 + 心包，阴之尽。寒热并见是厥阴最典型特征。治肝三法：补用酸（乌梅丸）、助用焦苦（吴茱萸汤）、益用甘味（小建中汤）。',
    types: [
      MeridianFormulaType(
        name: '寒热错杂',
        sym: '上热（消渴、心中疼热）+ 中寒（饥不欲食）+ 下寒（下利）',
        pulse: '沉弦',
        treat: '寒热并用',
        rx: '乌梅丸（厥阴主方）',
      ),
      MeridianFormulaType(
        name: '血虚寒厥',
        sym: '手足厥寒 + 脉细欲绝',
        pulse: '细欲绝',
        treat: '养血温经',
        rx: '当归四逆汤',
      ),
    ],
  ),
];

/// 按经名取分型族（未命中返 null）。
MeridianFormulaFamily? meridianFormulaFamilyOf(String meridian) {
  for (final f in meridianFormulaTypes) {
    if (f.meridian == meridian) return f;
  }
  return null;
}
