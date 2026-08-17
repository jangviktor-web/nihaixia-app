/// 《人纪·黄帝内经》知识卡数据（倪师讲稿书面整理版提炼）。
///
/// 三大块：五脏六腑脏象卡 / 五色望诊速查 / 常见脉象速查。
/// 内容忠于《灵兰秘典论》《六节藏象论》《阴阳应象大论》《五脏生成》
/// 《脉要精微论》《平人气象论》《阴阳别论》等篇原文 + 倪师讲解要点。
/// 出处字段便于回查原文；属传统文化参考，非医疗建议。
library;

/// 五脏六腑脏象卡。
class ZangFuCard {
  final String name; // 心
  final String zhiGuan; // 官职（灵兰秘典论）
  final String func; // 功能（…出焉）
  final String huaZai; // 其华在
  final String chongZai; // 其充在
  final String kaiQiao; // 开窍
  final String wuXing; // 五行
  final String qingZhi; // 情志（在志）
  final String shengKe; // 情志相胜（…胜…）
  final String tongYu; // 通于
  final String niShi; // 倪师解读要点
  final String source; // 出处

  const ZangFuCard({
    required this.name,
    required this.zhiGuan,
    required this.func,
    required this.huaZai,
    required this.chongZai,
    required this.kaiQiao,
    required this.wuXing,
    required this.qingZhi,
    required this.shengKe,
    required this.tongYu,
    required this.niShi,
    required this.source,
  });
}

/// 十二脏象（含膻中）。
const List<ZangFuCard> kZangFuCards = [
  ZangFuCard(
    name: '心',
    zhiGuan: '君主之官',
    func: '神明出焉',
    huaZai: '面',
    chongZai: '血脉',
    kaiQiao: '舌',
    wuXing: '火',
    qingZhi: '喜',
    shengKe: '恐胜喜',
    tongYu: '夏气',
    niShi: '心为火，跳动一生故不受病（无心脏癌）；心藏神，神之源头来自肾。主明则下安，诸脏皆宁；失眠多因神不守，安眠药强压睡眠、神伤更甚。',
    source: '《灵兰秘典论》《六节藏象论》',
  ),
  ZangFuCard(
    name: '肺',
    zhiGuan: '相傅之官',
    func: '治节出焉',
    huaZai: '毛',
    chongZai: '皮',
    kaiQiao: '鼻',
    wuXing: '金',
    qingZhi: '忧',
    shengKe: '喜胜忧',
    tongYu: '秋气',
    niShi: '肺为天幕，治节百官、节制诸脏；肺主皮毛，毛为血之余（血气化而毛生）。肺主燥金、主肃杀，秋金克木而草木凋。',
    source: '《灵兰秘典论》《六节藏象论》',
  ),
  ZangFuCard(
    name: '肝',
    zhiGuan: '将军之官',
    func: '谋虑出焉',
    huaZai: '爪',
    chongZai: '筋',
    kaiQiao: '目',
    wuXing: '木',
    qingZhi: '怒',
    shengKe: '悲胜怒',
    tongYu: '春气',
    niShi: '肝主目主握：肝病则目退化、握无力（危险时握不起来）。胆为肝之府，胆气足方能决断；胆逆（胆翻转）则视物颠倒。',
    source: '《灵兰秘典论》《六节藏象论》',
  ),
  ZangFuCard(
    name: '肾',
    zhiGuan: '作强之官',
    func: '伎巧出焉',
    huaZai: '发',
    chongZai: '骨',
    kaiQiao: '耳',
    wuXing: '水',
    qingZhi: '恐',
    shengKe: '思胜恐',
    tongYu: '冬气',
    niShi: '肾主蛰、封藏之本，精力之源；齿为骨之余。膀胱之津液受肾阳蒸化方能气化排出，废水不走则好水入肝再利用，人应不浪费一滴水。',
    source: '《灵兰秘典论》《六节藏象论》',
  ),
  ZangFuCard(
    name: '脾',
    zhiGuan: '仓廪之官（与胃）',
    func: '五味出焉',
    huaZai: '唇四白',
    chongZai: '肌',
    kaiQiao: '口',
    wuXing: '土',
    qingZhi: '思',
    shengKe: '怒胜思',
    tongYu: '土气（长夏）',
    niShi: '脾主口之津液、主肌肉；三焦之油来自脾，脾病则油竭、水停三焦。呼吸定息之「停」属脾土，一呼一吸定息脉五动为平人。',
    source: '《灵兰秘典论》《六节藏象论》',
  ),
  ZangFuCard(
    name: '胃',
    zhiGuan: '仓廪之官（与脾）',
    func: '受纳水谷',
    huaZai: '唇四白（同脾）',
    chongZai: '肌（同脾）',
    kaiQiao: '口',
    wuXing: '土',
    qingZhi: '—',
    shengKe: '—',
    tongYu: '土气',
    niShi: '胃为水谷之海，与脾共司消化。倪师：早起一杯冷水入胃，四肢之阳瞬间回胃蠕动，常年不生胃病（护胃养生法）。',
    source: '《灵兰秘典论》《六节藏象论》',
  ),
  ZangFuCard(
    name: '胆',
    zhiGuan: '中正之官',
    func: '决断出焉',
    huaZai: '—',
    chongZai: '—',
    kaiQiao: '（附肝）',
    wuXing: '木（阳木）',
    qingZhi: '—',
    shengKe: '—',
    tongYu: '春气',
    niShi: '胆主决断，胆气不足则无胆识。六节藏象论：凡十一脏取决于胆。胆与肝同属木，肝为阴木、胆为阳木；胆病亦可致目疾。',
    source: '《灵兰秘典论》《六节藏象论》',
  ),
  ZangFuCard(
    name: '小肠',
    zhiGuan: '受盛之官',
    func: '化物出焉',
    huaZai: '—',
    chongZai: '—',
    kaiQiao: '—',
    wuXing: '火',
    qingZhi: '—',
    shengKe: '—',
    tongYu: '—',
    niShi: '小肠受盛化物、吸收营养精华。小肠为火，紧贴膀胱故能蒸化津液（气化则能出矣）；热证移热常循小肠传变。',
    source: '《灵兰秘典论》',
  ),
  ZangFuCard(
    name: '大肠',
    zhiGuan: '传导之官',
    func: '变化出焉',
    huaZai: '—',
    chongZai: '—',
    kaiQiao: '—',
    wuXing: '金',
    qingZhi: '—',
    shengKe: '—',
    tongYu: '—',
    niShi: '大肠司传导变化，吸收水分、排出残渣。肺与大肠相表里，肺气肃降则大肠通调。',
    source: '《灵兰秘典论》',
  ),
  ZangFuCard(
    name: '膀胱',
    zhiGuan: '州都之官',
    func: '津液藏焉，气化则能出矣',
    huaZai: '—',
    chongZai: '—',
    kaiQiao: '—',
    wuXing: '水',
    qingZhi: '—',
    shengKe: '—',
    tongYu: '冬气',
    niShi: '膀胱聚一身代谢之废水，须肾阳蒸化方能排出；肾阳不足则气化不利。倪师：人应不浪费一滴水，好水经三焦回肝再利用。',
    source: '《灵兰秘典论》',
  ),
  ZangFuCard(
    name: '三焦',
    zhiGuan: '决渎之官',
    func: '水道出焉',
    huaZai: '—',
    chongZai: '—',
    kaiQiao: '—',
    wuXing: '火（相火）',
    qingZhi: '—',
    shengKe: '—',
    tongYu: '—',
    niShi: '三焦为脏腑间油网，源自肾间（第十三椎至关元），横膈上为上焦、膈至脐为中焦、脐下为下焦。油来自脾，脾病则油竭水停；水道通利赖肾阳之热与脾油之滑。',
    source: '《灵兰秘典论》',
  ),
  ZangFuCard(
    name: '膻中（心包）',
    zhiGuan: '臣使之官',
    func: '喜乐出焉',
    huaZai: '—',
    chongZai: '—',
    kaiQiao: '—',
    wuXing: '火',
    qingZhi: '喜',
    shengKe: '—',
    tongYu: '—',
    niShi: '膻中即心包络，喜乐之源，代心受邪、护卫君主。心包与三焦相表里（同属相火）。',
    source: '《灵兰秘典论》',
  ),
];

/// 五色望诊条目。
class WangZhenEntry {
  final String color; // 青
  final String zangFu; // 肝
  final String normal; // 正常色
  final String abnormal; // 病色
  final String note; // 倪师解读
  final String source;

  const WangZhenEntry({
    required this.color,
    required this.zangFu,
    required this.normal,
    required this.abnormal,
    required this.note,
    required this.source,
  });
}

/// 五色望诊（脉要精微论：五色精微象）。
const List<WangZhenEntry> kWangZhenColors = [
  WangZhenEntry(
    color: '赤',
    zangFu: '心',
    normal: '如白裹朱（白绢裹朱砂，润而有光）',
    abnormal: '如赭（深红无光）',
    note: '面赤润泽为心气之华；赤而干暗为病。心主血脉，赤当心苦。',
    source: '《脉要精微论》《五脏生成》',
  ),
  WangZhenEntry(
    color: '白',
    zangFu: '肺',
    normal: '如鹅羽（白而有光泽）',
    abnormal: '如盐（白而无光）',
    note: '白当肺辛、主皮毛；苍白无华为肺气衰或血虚。',
    source: '《脉要精微论》《五脏生成》',
  ),
  WangZhenEntry(
    color: '青',
    zangFu: '肝',
    normal: '如苍璧之泽（青润如玉）',
    abnormal: '如蓝（青而深滞）',
    note: '青当肝酸、主筋；面青多属肝病、寒痛或惊风。正青色为青中带少许黄。',
    source: '《脉要精微论》《五脏生成》',
  ),
  WangZhenEntry(
    color: '黄',
    zangFu: '脾',
    normal: '如罗裹雄黄（润黄透亮）',
    abnormal: '如黄土（暗黄无光）',
    note: '黄当脾甘、主肉；暗黄如土为脾湿或黄疸之象。脾色宜黄中带润白。',
    source: '《脉要精微论》《五脏生成》',
  ),
  WangZhenEntry(
    color: '黑',
    zangFu: '肾',
    normal: '如重漆色（黑而有光泽）',
    abnormal: '如地苍（黑而枯暗）',
    note: '黑当肾咸、主骨；面黑枯暗为肾气衰败（水色外露）。肾色宜黑中透光。',
    source: '《脉要精微论》《五脏生成》',
  ),
];

/// 眼诊条目（五脏生成·倪师眼诊法）。
class EyeDiagEntry {
  final String zone; // 瞳孔
  final String zangFu; // 肾
  final String note;

  const EyeDiagEntry({
    required this.zone,
    required this.zangFu,
    required this.note,
  });
}

/// 眼诊分区（倪师：观眼辨五脏）。
const List<EyeDiagEntry> kEyeDiag = [
  EyeDiagEntry(
    zone: '瞳孔',
    zangFu: '肾',
    note: '瞳孔属肾主藏。瞳孔越小越能收藏、智慧越集中；手电筒照瞳孔不缩为肾阳已绝。',
  ),
  EyeDiagEntry(
    zone: '第二圈（虹膜内环）',
    zangFu: '脾',
    note: '土能制水，脾土截住肾水。脾区过旺（土反辱木）易见消渴（糖尿病）。',
  ),
  EyeDiagEntry(
    zone: '第三圈（虹膜外环）',
    zangFu: '肝',
    note: '肝木克脾土，木疏则土不流失。肝区应占三分之二、脾区三分之一。',
  ),
  EyeDiagEntry(
    zone: '眼白',
    zangFu: '肺',
    note: '眼白属肺。肺气盛则眼白少而黑珠灵动；眼白过多多属神气不聚。',
  ),
  EyeDiagEntry(
    zone: '内眦（睛明）',
    zangFu: '心',
    note: '内眦血脉属心。诸脉者皆属于目，血脉有病治心脏。',
  ),
];

/// 脉象速查条目。
class MaiZhenEntry {
  final String name; // 长
  final String diagnosis; // 长则气治
  final String detail; // 详解（原文+倪师）
  final String source;

  const MaiZhenEntry({
    required this.name,
    required this.diagnosis,
    required this.detail,
    required this.source,
  });
}

/// 常见脉象（脉要精微论）。
const List<MaiZhenEntry> kMaiZhenCommon = [
  MaiZhenEntry(
    name: '长脉',
    diagnosis: '长则气治',
    detail: '脉形恰到寸关尺常度，五脏之气平衡，为正常之脉。',
    source: '《脉要精微论》',
  ),
  MaiZhenEntry(
    name: '短脉',
    diagnosis: '短则气病',
    detail: '脉形缩短、不足常度。脉为气之府，短脉主气病（气虚不充）。',
    source: '《脉要精微论》',
  ),
  MaiZhenEntry(
    name: '数脉',
    diagnosis: '数则烦心',
    detail: '一呼一吸超过五动即数。数主热、主烦心（津液不足之象）。',
    source: '《脉要精微论》',
  ),
  MaiZhenEntry(
    name: '大脉',
    diagnosis: '大则病进',
    detail: '脉大须与人身成比例：瘦人脉大、或胖子脉反细，即病进之兆。',
    source: '《脉要精微论》',
  ),
  MaiZhenEntry(
    name: '代脉',
    diagnosis: '代则气衰',
    detail: '脉形更代变更、大小不一、断断续续，主气衰。',
    source: '《脉要精微论》',
  ),
  MaiZhenEntry(
    name: '细脉',
    diagnosis: '细则气少',
    detail: '脉形细小，主气少（气血不足）。',
    source: '《脉要精微论》',
  ),
  MaiZhenEntry(
    name: '涩脉',
    diagnosis: '涩则心痛',
    detail: '脉行滞涩、按之弹不回来、游转无力，主心痛。',
    source: '《脉要精微论》',
  ),
  MaiZhenEntry(
    name: '寸盛 / 尺盛',
    diagnosis: '上盛则气高，下盛则气胀',
    detail: '寸部属阳主胸（上盛气逆向上），尺部属阴主腹（下盛下腹胀满）。',
    source: '《脉要精微论》',
  ),
];

/// 死脉警示（平人气象论 + 脉要精微论 + 阴阳别论）。
class DeadPulseEntry {
  final String name;
  final String detail;
  final String source;

  const DeadPulseEntry({
    required this.name,
    required this.detail,
    required this.source,
  });
}

const List<DeadPulseEntry> kDeadPulses = [
  DeadPulseEntry(
    name: '浑浑革至如涌泉',
    detail: '脉洪大如泉水涌出、中空，阳气外越不能敛，病进而色弊。',
    source: '《脉要精微论》',
  ),
  DeadPulseEntry(
    name: '绵绵其出如弦绝',
    detail: '脉如弦紧绷、绵绵欲绝，真气将尽之候。',
    source: '《脉要精微论》',
  ),
  DeadPulseEntry(
    name: '一呼脉四动以上',
    detail: '一呼一吸脉动超过四至（即八动以上）为死候。',
    source: '《平人气象论》',
  ),
  DeadPulseEntry(
    name: '脉绝不至',
    detail: '脉已不跳动，阳气绝。',
    source: '《平人气象论》',
  ),
  DeadPulseEntry(
    name: '乍疏乍数',
    detail: '脉忽快忽慢、疏密不一，胃气已败。',
    source: '《平人气象论》',
  ),
];

/// 平人脉标准（平人气象论）。
const String kPingRenMai =
    '人一呼脉再动，一吸脉亦再动，呼吸定息脉五动，闰以太息，命曰平人。'
    '平人者，不病也。常以不病调病人。\n'
    '——以医生自己的呼吸为标准：一呼一吸加上定息，病人脉跳五次为平人；'
    '一呼一吸仅两次为少气；三次而躁为病温（尺热）或病风（尺不热脉滑）或痹（脉涩）。';

/// 脉之阴阳（阴阳别论）。
const String kMaiYinYang =
    '去者为阴，至者为阳；静者为阴，动者为阳；迟者为阴，数者为阳。'
    '寸部为阳，尺部为阴。阳脉主胃脘之阳（能受纳水谷），阴脉为五脏真藏之脉。'
    '真藏脉见（肝弦、心洪、脾缓、肺浮、肾沉如石），则五脏精气败绝。';
