// 梅花易数起卦与体用生克推演。
//
// 数据源：宋代邵康节《梅花易数》。卦象、卦辞、爻辞直接复用本项目
//   `yijing_data.dart` 的 kTrigrams / kHexagrams（64 卦全覆盖，无需重复建库）。
//   体用总诀五关系、八卦万物类象、四时旺衰均为传统术数通行内容。
// 属民俗文化参考，非吉凶指令。
//
// 起卦口径（本模块实现三种，均为《梅花易数》原书所载）：
//   时间起卦：上卦=(年支序+月+日)%8；下卦=(年支序+月+日+时支序)%8；动爻=(年支序+月+日+时支序)%6
//   数字起卦：上卦=第一数%8；下卦=第二数%8；动爻=(两数之和)%6
//   随机起卦：三枚各取 1-8 / 1-8 / 1-6
// 未收录：字数起卦（需汉字笔画字典，本库无此数据）、方位取象起卦（需后天八卦方位映射，
//   与先天数卦序非同一套体系，混用易错）。二者非原书核心起卦法，故不硬凑。

import 'dart:math';

import 'yijing_data.dart';

/// 起卦方式。
enum MeihuaMethod {
  /// 年月日时起卦法
  time('时间起卦'),

  /// 报两个数起卦
  number('数字起卦'),

  /// 随机三数起卦
  random('随机起卦');

  const MeihuaMethod(this.label);

  final String label;
}

/// 体用五行关系（《梅花易数·体用总诀》）。
enum TiYongRelation {
  /// 体用同五行
  biHe('体用比和', '体用比和，则百事顺遂。'),

  /// 体卦五行克用卦五行
  tiKeYong('体克用', '体克用，诸事吉。'),

  /// 用卦五行克体卦五行
  yongKeTi('用克体', '用克体，诸事凶。'),

  /// 体卦生用卦
  tiShengYong('体生用', '体生用，有耗失之患。'),

  /// 用卦生体卦
  yongShengTi('用生体', '用生体，有进益之喜。');

  const TiYongRelation(this.label, this.verdict);

  /// 关系名。
  final String label;

  /// 《体用总诀》原句断语。
  final String verdict;
}

/// 四时旺相休囚死（以月令五行为基准）。
enum WangShuai {
  /// 当令
  wang('旺'),

  /// 月令生我
  xiang('相'),

  /// 我生月令
  xiu('休'),

  /// 我克月令
  qiu('囚'),

  /// 月令克我
  si('死');

  const WangShuai(this.label);

  final String label;
}

/// 先天数 1-8 → 八卦五行。
String wuxingOfXiantian(int xiantian) => switch (xiantian) {
      1 || 2 => '金',
      3 => '火',
      4 || 5 => '木',
      6 => '水',
      _ => '土', // 7 艮 / 8 坤
    };

/// 五行相生：key 生 value。
const _sheng = {'木': '火', '火': '土', '土': '金', '金': '水', '水': '木'};

/// 五行相克：key 克 value。
const _ke = {'木': '土', '土': '水', '水': '火', '火': '金', '金': '木'};

/// 月令五行下某五行的旺衰。
WangShuai wangShuaiOf(String wx, String monthWx) {
  if (wx == monthWx) return WangShuai.wang;
  if (_sheng[monthWx] == wx) return WangShuai.xiang;
  if (_sheng[wx] == monthWx) return WangShuai.xiu;
  if (_ke[wx] == monthWx) return WangShuai.qiu;
  return WangShuai.si;
}

/// 体用五行关系（以体卦为我）。
TiYongRelation tiYongRelation(String tiWx, String yongWx) {
  if (tiWx == yongWx) return TiYongRelation.biHe;
  if (_ke[tiWx] == yongWx) return TiYongRelation.tiKeYong;
  if (_ke[yongWx] == tiWx) return TiYongRelation.yongKeTi;
  if (_sheng[tiWx] == yongWx) return TiYongRelation.tiShengYong;
  return TiYongRelation.yongShengTi;
}

/// 八卦万物类象（《梅花易数·八卦万物类象》要旨）。
class TrigramXiang {
  final String name;
  final String wuxing;
  final String direction; // 先天方位
  final String family;
  final String body;
  final String matters;
  const TrigramXiang(this.name, this.wuxing, this.direction, this.family,
      this.body, this.matters);
}

const List<TrigramXiang> kTrigramXiang = [
  TrigramXiang('乾', '金', '西北', '父、长者、首领', '头、骨、肺', '刚健、开创、权柄、圆物、金玉、寒凉'),
  TrigramXiang('兑', '金', '东南', '少女、口舌之人', '口、舌、肺', '喜悦、缺折、毁折、口舌、歌乐、沼泽'),
  TrigramXiang('离', '火', '正南', '中女、文人', '目、心、小肠', '光明、文书、文明、华丽、中虚、甲胄'),
  TrigramXiang('震', '木', '正东', '长男、行人', '足、肝、发', '震动、奋起、惊恐、出行、树木、擂鼓'),
  TrigramXiang('巽', '木', '西南', '长女、商旅', '股、胆、呼吸', '风行、顺入、进退、不定、绳索、花草'),
  TrigramXiang('坎', '水', '正西', '中男、盗贼', '耳、肾、血', '险陷、隐伏、流动、书信、酒浆、弓轮'),
  TrigramXiang('艮', '土', '东北', '少男、童子', '手、背、胃', '止静、阻隔、丘陵、门阙、鼠、果实'),
  TrigramXiang('坤', '土', '西南', '母、老妇、众', '腹、脾、肉', '柔顺、承载、布帛、器物、田野、空虚'),
];

TrigramXiang xiangOf(Trigram t) => kTrigramXiang[t.xiantian - 1];

/// 农历月 → 月建地支序（正月建寅=3 … 十二月建丑=2）。
int monthBranchIndexOfLunarMonth(int lunarMonth) =>
    ((lunarMonth + 1) % 12) + 1;

/// 八卦序数（1-8）→ kTrigrams 下标（0-7）。
Trigram _trigramOfIndex(int xiantian) {
  final t = kTrigrams.firstWhere((t) => t.xiantian == xiantian);
  return t;
}

/// 按上下卦下标（0-7）取六十四卦。
Hexagram _hexOf(int upperIdx, int lowerIdx) => kHexagrams
    .firstWhere((h) => h.upper == upperIdx && h.lower == lowerIdx);

/// 由下→上三爻（1=阳 0=阴）反查八卦，返回先天数；找不到返回 null。
int? _trigramByLines(List<int> lines) {
  for (final t in kTrigrams) {
    bool same = true;
    for (var i = 0; i < 3; i++) {
      if (t.lines[i] != lines[i]) {
        same = false;
        break;
      }
    }
    if (same) return t.xiantian;
  }
  return null;
}

/// 三阶段（主卦 → 互卦 → 变卦）体用推演的一条结论。
class MeihuaStage {
  final String name; // 主卦 / 互卦 / 变卦
  final String hexName;
  final TiYongRelation relation;
  final String detail;
  const MeihuaStage(this.name, this.hexName, this.relation, this.detail);
}

/// 梅花易数一卦的完整推演结果。
class MeihuaChart {
  final MeihuaMethod method;
  final String methodLabel;

  /// 推算过程（每行一步，便于自核）。
  final List<String> trace;

  final Hexagram main;
  final Hexagram mutual;
  final Hexagram changed;

  /// 动爻位（1-6，自下而上）。
  final int movingYao;

  /// 动爻爻辞。
  final String movingYaoCi;

  final Trigram ti;
  final Trigram yong;
  final Trigram interTi;
  final Trigram interYong;
  final Trigram changedTi;
  final Trigram changedYong;

  /// 主卦体用关系。
  final TiYongRelation mainRelation;

  /// 体卦在当月月令下的旺衰。
  final WangShuai tiWangShuai;

  /// 月建地支名。
  final String monthBranch;

  /// 主断断语。
  final String verdict;

  /// 三阶段推演。
  final List<MeihuaStage> stages;

  const MeihuaChart({
    required this.method,
    required this.methodLabel,
    required this.trace,
    required this.main,
    required this.mutual,
    required this.changed,
    required this.movingYao,
    required this.movingYaoCi,
    required this.ti,
    required this.yong,
    required this.interTi,
    required this.interYong,
    required this.changedTi,
    required this.changedYong,
    required this.mainRelation,
    required this.tiWangShuai,
    required this.monthBranch,
    required this.verdict,
    required this.stages,
  });

  /// 体卦五行。
  String get tiWuxing => wuxingOfXiantian(ti.xiantian);

  /// 用卦五行。
  String get yongWuxing => wuxingOfXiantian(yong.xiantian);
}

const _kZhiNames = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

/// 8 余数归正：%8 得 0 时取 8（八卦无 0 宫）。
int _mod8(int n) => n % 8 == 0 ? 8 : n % 8;

/// 6 余数归正：%6 得 0 时取 6（动爻无 0 爻）。
int _mod6(int n) => n % 6 == 0 ? 6 : n % 6;

/// 定体用：动爻所在经卦为「用」，静止的另一经卦为「体」。
({Trigram ti, Trigram yong}) _tiYong(Trigram upper, Trigram lower, int movingYao) =>
    movingYao <= 3
        ? (ti: upper, yong: lower) // 动爻在下卦 → 下卦为用、上卦为体
        : (ti: lower, yong: upper); // 动爻在上卦 → 上卦为用、下卦为体

/// 按上卦/下卦/动爻完成主卦、互卦、变卦与体用推演。
MeihuaChart _build({
  required MeihuaMethod method,
  required int upperXiantian,
  required int lowerXiantian,
  required int movingYao,
  required int lunarMonth,
  required List<String> trace,
}) {
  if (upperXiantian < 1 || upperXiantian > 8) {
    throw ArgumentError.value(upperXiantian, 'upperXiantian', '上卦须在 1-8');
  }
  if (lowerXiantian < 1 || lowerXiantian > 8) {
    throw ArgumentError.value(lowerXiantian, 'lowerXiantian', '下卦须在 1-8');
  }
  if (movingYao < 1 || movingYao > 6) {
    throw ArgumentError.value(movingYao, 'movingYao', '动爻须在 1-6');
  }
  if (lunarMonth < 1 || lunarMonth > 12) {
    throw ArgumentError.value(lunarMonth, 'lunarMonth', '农历月须在 1-12');
  }

  final upper = _trigramOfIndex(upperXiantian);
  final lower = _trigramOfIndex(lowerXiantian);
  final main = _hexOf(upperXiantian - 1, lowerXiantian - 1);

  // 六爻自下而上：下卦三爻 + 上卦三爻。
  final mainLines = [...lower.lines, ...upper.lines];

  // 变卦：动爻阴阳互换。
  final changedLines = List<int>.of(mainLines);
  changedLines[movingYao - 1] = 1 - changedLines[movingYao - 1];

  // 互卦：取主卦 2-4 爻为下互、3-5 爻为上互。
  // 《梅花易数·互卦起例》「乾坤无互，互其变卦」：纯乾/纯坤改取变卦中间四爻。
  final pureQianKun = upperXiantian == lowerXiantian &&
      (upperXiantian == 1 || upperXiantian == 8);
  final mutualSrc = pureQianKun ? changedLines : mainLines;
  final interLowerXiantian = _trigramByLines(mutualSrc.sublist(1, 4));
  final interUpperXiantian = _trigramByLines(mutualSrc.sublist(2, 5));
  if (interLowerXiantian == null || interUpperXiantian == null) {
    throw StateError('互卦匹配失败');
  }
  final mutual = _hexOf(interUpperXiantian - 1, interLowerXiantian - 1);

  final changedLowerXiantian = _trigramByLines(changedLines.sublist(0, 3));
  final changedUpperXiantian = _trigramByLines(changedLines.sublist(3, 6));
  if (changedLowerXiantian == null || changedUpperXiantian == null) {
    throw StateError('变卦匹配失败');
  }
  final changed = _hexOf(changedUpperXiantian - 1, changedLowerXiantian - 1);

  // 体用（主卦 / 互卦 / 变卦各自定）
  final mainTY = _tiYong(upper, lower, movingYao);
  final interUpper = _trigramOfIndex(interUpperXiantian);
  final interLower = _trigramOfIndex(interLowerXiantian);
  // 体在上则上互为体互、下互为用互；体在下则反之（《体用互变之诀》）。
  final interTY = movingYao <= 3
      ? (ti: interUpper, yong: interLower)
      : (ti: interLower, yong: interUpper);
  final changedTY = _tiYong(
      _trigramOfIndex(changedUpperXiantian),
      _trigramOfIndex(changedLowerXiantian),
      movingYao);

  // 月令旺衰：体卦在月建五行下的状态。
  final monthBranch = _kZhiNames[monthBranchIndexOfLunarMonth(lunarMonth) - 1];
  final monthWx = _kZhiWuxing[monthBranch]!;
  final tiWx = wuxingOfXiantian(mainTY.ti.xiantian);
  final ws = wangShuaiOf(tiWx, monthWx);

  final mainRel = tiYongRelation(tiWx, wuxingOfXiantian(mainTY.yong.xiantian));

  final verdict = _verdictOf(mainRel, ws);

  final stages = <MeihuaStage>[
    _stageOf('主卦', main, mainTY.ti, mainTY.yong),
    _stageOf('互卦', mutual, interTY.ti, interTY.yong),
    _stageOf('变卦', changed, changedTY.ti, changedTY.yong),
  ];

  return MeihuaChart(
    method: method,
    methodLabel: method.label,
    trace: trace,
    main: main,
    mutual: mutual,
    changed: changed,
    movingYao: movingYao,
    movingYaoCi: main.lines[movingYao - 1],
    ti: mainTY.ti,
    yong: mainTY.yong,
    interTi: interTY.ti,
    interYong: interTY.yong,
    changedTi: changedTY.ti,
    changedYong: changedTY.yong,
    mainRelation: mainRel,
    tiWangShuai: ws,
    monthBranch: monthBranch,
    verdict: verdict,
    stages: stages,
  );
}

/// 地支五行（月建旺衰基准）。
const _kZhiWuxing = {
  '子': '水', '丑': '土', '寅': '木', '卯': '木', '辰': '土', '巳': '火',
  '午': '火', '未': '土', '申': '金', '酉': '金', '戌': '土', '亥': '水',
};

MeihuaStage _stageOf(String name, Hexagram hex, Trigram ti, Trigram yong) {
  final tiWx = wuxingOfXiantian(ti.xiantian);
  final yongWx = wuxingOfXiantian(yong.xiantian);
  final rel = tiYongRelation(tiWx, yongWx);
  return MeihuaStage(name, hex.name, rel,
      '${ti.name}($tiWx) 为体、${yong.name}($yongWx) 为用 → ${rel.label}');
}

String _verdictOf(TiYongRelation rel, WangShuai ws) {
  final q = switch (ws) {
    WangShuai.wang || WangShuai.xiang => '体卦${ws.label}，主事有力',
    WangShuai.xiu => '体卦休，力平常',
    WangShuai.qiu => '体卦囚，力受制',
    WangShuai.si => '体卦死，力最弱',
  };
  return '${rel.verdict}（$q）';
}

/// 时间起卦（年月日时起卦法）。
///
/// [yearZhiIndex] 年支序（子=1…亥=12）；[month]/[day] 农历月日；
/// [hourZhiIndex] 时支序（子=1…亥=12）。
MeihuaChart computeMeihuaByTime({
  required int yearZhiIndex,
  required int lunarMonth,
  required int lunarDay,
  required int hourZhiIndex,
}) {
  _checkRange(yearZhiIndex, 'yearZhiIndex', 1, 12);
  _checkRange(hourZhiIndex, 'hourZhiIndex', 1, 12);
  _checkRange(lunarDay, 'lunarDay', 1, 30);
  final sum = yearZhiIndex + lunarMonth + lunarDay;
  final sumWithHour = sum + hourZhiIndex;
  final upper = _mod8(sum);
  final lower = _mod8(sumWithHour);
  final moving = _mod6(sumWithHour);
  return _build(
    method: MeihuaMethod.time,
    upperXiantian: upper,
    lowerXiantian: lower,
    movingYao: moving,
    lunarMonth: lunarMonth,
    trace: [
      '年支序 $yearZhiIndex + 农历 $lunarMonth 月 $lunarDay 日 = $sum',
      '上卦 = $sum % 8 = ${sum % 8} → 归正为 $upper',
      '下卦 = ($sum + 时支序 $hourZhiIndex) % 8 = ${sumWithHour % 8} → 归正为 $lower',
      '动爻 = ($sum + $hourZhiIndex) % 6 = ${sumWithHour % 6} → 归正为 $moving',
    ],
  );
}

/// 数字起卦：报两个数，第一数定上卦、第二数定下卦、两数之和定动爻。
MeihuaChart computeMeihuaByNumber({
  required int first,
  required int second,
  required int lunarMonth,
}) {
  _checkRange(first, 'first', 1, 1 << 31);
  _checkRange(second, 'second', 1, 1 << 31);
  final upper = _mod8(first);
  final lower = _mod8(second);
  final moving = _mod6(first + second);
  return _build(
    method: MeihuaMethod.number,
    upperXiantian: upper,
    lowerXiantian: lower,
    movingYao: moving,
    lunarMonth: lunarMonth,
    trace: [
      '第一数 $first → 上卦 = $first % 8 = ${first % 8} → 归正为 $upper',
      '第二数 $second → 下卦 = $second % 8 = ${second % 8} → 归正为 $lower',
      '动爻 = ($first + $second) % 6 = ${(first + second) % 6} → 归正为 $moving',
    ],
  );
}

/// 随机起卦（上卦 1-8、下卦 1-8、动爻 1-6 各随机取一）。
MeihuaChart computeMeihuaByRandom({
  required int lunarMonth,
  Random? rng,
}) {
  final r = rng ?? Random();
  final upper = r.nextInt(8) + 1;
  final lower = r.nextInt(8) + 1;
  final moving = r.nextInt(6) + 1;
  return _build(
    method: MeihuaMethod.random,
    upperXiantian: upper,
    lowerXiantian: lower,
    movingYao: moving,
    lunarMonth: lunarMonth,
    trace: [
      '随机上卦 = $upper',
      '随机下卦 = $lower',
      '随机动爻 = $moving',
    ],
  );
}

void _checkRange(int v, String name, int min, int max) {
  if (v < min || v > max) {
    throw ArgumentError.value(v, name, '须在 $min-$max 之间');
  }
}
