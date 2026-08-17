/// 八字详批引擎：神煞 / 格局 / 日主强弱 / 五行分布 / 用神忌神。
///
/// 算法移植自开源项目 tianji（MIT）`web/js/bazi.js`，数据忠于传统命理。
/// 纯 Dart，无 Flutter 依赖。
library;

import 'minggua_engine.dart' show shiShenOf;

/// 八字详批结果。
class BaZiAnalysis {
  final String dayMaster; // 日主（如 庚）
  final String pattern; // 格局（如 七杀格）
  final String patternDesc; // 格局说明
  final String strengthLevel; // 极旺/身强/中和/身弱/极弱
  final double strengthScore; // 强弱评分
  final List<String> strengthFactors; // 得令/得地/得势 明细
  final List<({String name, String pillar, String pos})> shensha; // 神煞
  final List<({String element, double score, String status})> fiveElements; // 五行
  final List<String> favorable; // 用神（如 火(官杀)）
  final List<String> unfavorable; // 忌神
  final String suggestion; // 用神建议文案

  const BaZiAnalysis({
    required this.dayMaster,
    required this.pattern,
    required this.patternDesc,
    required this.strengthLevel,
    required this.strengthScore,
    required this.strengthFactors,
    required this.shensha,
    required this.fiveElements,
    required this.favorable,
    required this.unfavorable,
    required this.suggestion,
  });
}

// ---- 基础索引 ----
const String _ganChars = '甲乙丙丁戊己庚辛壬癸';
const String _zhiChars = '子丑寅卯辰巳午未申酉戌亥';
const List<String> _elementNames = ['木', '火', '土', '金', '水'];

int _ganIdx(String g) => _ganChars.indexOf(g);
int _zhiIdx(String z) => _zhiChars.indexOf(z);

/// 天干五行索引（0木1火2土3金4水）。
int _ganElement(int ganIdx) => ganIdx ~/ 2;

/// 五行相生：木→火→土→金→水→木。
int _elementProduce(int el) => (el + 1) % 5;
/// 五行相克：木→土→水→火→金→木。
int _elementConquer(int el) => (el + 2) % 5;

/// 十二地支藏干（本气/中气/余气，天干索引 0-9）。
const Map<int, List<int>> _hiddenStems = {
  0: [9], // 子:癸
  1: [5, 9, 7], // 丑:己癸辛
  2: [0, 2, 4], // 寅:甲丙戊
  3: [1], // 卯:乙
  4: [4, 1, 9], // 辰:戊乙癸
  5: [2, 4, 6], // 巳:丙戊庚
  6: [3, 5], // 午:丁己
  7: [5, 3, 1], // 未:己丁乙
  8: [6, 8, 4], // 申:庚壬戊
  9: [7], // 酉:辛
  10: [4, 7, 3], // 戌:戊辛丁
  11: [8, 0], // 亥:壬甲
};

// ---- 神煞表（tianji bazi.js）----

/// 天乙贵人：日干 → 地支列表（0=子..11=亥）。
const Map<int, List<int>> _tianyiGuiren = {
  0: [1, 7], // 甲戊庚 牛羊(丑未)
  4: [1, 7],
  6: [1, 7],
  1: [0, 8], // 乙己 鼠猴(子申)
  5: [0, 8],
  2: [11, 9], // 丙丁 猪鸡(亥酉)
  3: [11, 9],
  8: [3, 5], // 壬癸 兔蛇(卯巳)
  9: [3, 5],
  7: [6, 2], // 六辛 马虎(午寅)
};

/// 文昌贵人：日干 → 地支。
const List<int> _wenChang = [5, 6, 8, 9, 8, 9, 11, 0, 2, 3];

/// 禄神：日干 → 地支。
const List<int> _luShen = [2, 3, 5, 6, 5, 6, 8, 9, 11, 0];

/// 羊刃：禄神前一位。
const List<int> _yangRen = [3, 4, 6, 7, 6, 7, 9, 10, 0, 1];

/// 三合局（每局三个地支索引）。
const List<List<int>> _sanHeGroups = [
  [8, 0, 4], // 申子辰
  [11, 3, 7], // 亥卯未
  [2, 6, 10], // 寅午戌
  [5, 9, 1], // 巳酉丑
];
const List<int> _yiMa = [2, 5, 8, 11]; // 驿马
const List<int> _taoHua = [9, 0, 3, 6]; // 桃花
const List<int> _huaGai = [4, 7, 10, 1]; // 华盖
const List<int> _jiangXing = [0, 3, 6, 9]; // 将星

/// 天德：月支 → 应见天干字。
const Map<int, String> _tianDe = {
  2: '丁', 3: '申', 4: '壬', 5: '辛', 6: '亥', 7: '甲',
  8: '癸', 9: '寅', 10: '丙', 11: '乙', 0: '巳', 1: '庚',
};

/// 月德：月支 → 应见天干字。
const Map<int, String> _yueDe = {
  2: '丙', 3: '甲', 4: '壬', 5: '庚', 6: '丙', 7: '甲',
  8: '壬', 9: '庚', 10: '丙', 11: '甲', 0: '壬', 1: '庚',
};

/// 找地支所属三合局索引。
int _sanHeGroup(int branchIdx) {
  for (var i = 0; i < _sanHeGroups.length; i++) {
    if (_sanHeGroups[i].contains(branchIdx)) return i;
  }
  return 0;
}

/// 月令对日主五行的支持分（tianji MONTH_SUPPORT）。
const List<List<int>> _monthSupport = [
  [2, -1, -1, 1, 3], // 子（0）
  [-1, -1, 2, 1, 1], // 丑
  [3, 2, -1, -1, 1], // 寅
  [3, 2, -1, -1, 1], // 卯
  [1, 1, 2, 0, -1], // 辰
  [1, 3, 2, -1, -1], // 巳
  [1, 3, 2, -1, -1], // 午
  [-1, 1, 2, 1, -1], // 未
  [-1, -1, 1, 3, 2], // 申
  [-1, -1, 1, 3, 2], // 酉
  [-1, 0, 2, 1, -1], // 戌
  [2, -1, -1, 1, 3], // 亥
];

/// 八字详批：神煞 / 格局 / 日主强弱 / 五行 / 用神忌神。
///
/// - [gans] 4 天干（年/月/日/时，如 庚/丙/戊/壬）
/// - [zhis] 4 地支（年/月/日/时，如 午/子/辰/申）
BaZiAnalysis analyzeBaZi({
  required List<String> gans,
  required List<String> zhis,
}) {
  assert(gans.length == 4 && zhis.length == 4);
  final ganIdx = gans.map(_ganIdx).toList();
  final zhiIdx = zhis.map(_zhiIdx).toList();
  final dm = ganIdx[2]; // 日主
  final dmEl = _ganElement(dm);

  // ---- 神煞 ----
  final shensha = <({String name, String pillar, String pos})>[];
  const pillarNames = ['年', '月', '日', '时'];
  void addShensha(String name, int pillar, String pos) {
    shensha.add((name: name, pillar: pillarNames[pillar], pos: pos));
  }

  // 天乙贵人（日干 → 查四支）
  for (final b in _tianyiGuiren[dm] ?? const <int>[]) {
    for (var i = 0; i < 4; i++) {
      if (zhiIdx[i] == b) addShensha('天乙贵人', i, _zhiChars[b]);
    }
  }
  // 文昌贵人（日干）
  for (var i = 0; i < 4; i++) {
    if (zhiIdx[i] == _wenChang[dm]) {
      addShensha('文昌贵人', i, _zhiChars[_wenChang[dm]]);
    }
  }
  // 驿马（日支三合）
  final yiMaTarget = _yiMa[_sanHeGroup(zhiIdx[2])];
  for (var i = 0; i < 4; i++) {
    if (zhiIdx[i] == yiMaTarget) addShensha('驿马', i, _zhiChars[yiMaTarget]);
  }
  // 桃花（日支三合）
  final taoHuaTarget = _taoHua[_sanHeGroup(zhiIdx[2])];
  for (var i = 0; i < 4; i++) {
    if (zhiIdx[i] == taoHuaTarget) addShensha('桃花', i, _zhiChars[taoHuaTarget]);
  }
  // 华盖（日支三合）
  final huaGaiTarget = _huaGai[_sanHeGroup(zhiIdx[2])];
  for (var i = 0; i < 4; i++) {
    if (zhiIdx[i] == huaGaiTarget) addShensha('华盖', i, _zhiChars[huaGaiTarget]);
  }
  // 将星（年支三合）
  final jiangTarget = _jiangXing[_sanHeGroup(zhiIdx[0])];
  for (var i = 0; i < 4; i++) {
    if (zhiIdx[i] == jiangTarget) addShensha('将星', i, _zhiChars[jiangTarget]);
  }
  // 天德（月支 → 查四干）
  final tdStem = _tianDe[zhiIdx[1]];
  if (tdStem != null) {
    for (var i = 0; i < 4; i++) {
      if (gans[i] == tdStem) addShensha('天德', i, tdStem);
    }
  }
  // 月德（月支 → 查四干）
  final ydStem = _yueDe[zhiIdx[1]];
  if (ydStem != null) {
    for (var i = 0; i < 4; i++) {
      if (gans[i] == ydStem) addShensha('月德', i, ydStem);
    }
  }
  // 禄神（日干）
  for (var i = 0; i < 4; i++) {
    if (zhiIdx[i] == _luShen[dm]) addShensha('禄神', i, _zhiChars[_luShen[dm]]);
  }
  // 羊刃（日干）
  for (var i = 0; i < 4; i++) {
    if (zhiIdx[i] == _yangRen[dm]) addShensha('羊刃', i, _zhiChars[_yangRen[dm]]);
  }

  // ---- 格局（月支藏干透干 + 建禄/羊刃）----
  final monthBranch = zhiIdx[1];
  String pattern;
  String patternDesc;
  if (monthBranch == _luShen[dm]) {
    pattern = '建禄格';
    patternDesc = '月支为日主之禄，自身力量强，喜财官泄秀。';
  } else if (monthBranch == _yangRen[dm]) {
    pattern = '羊刃格';
    patternDesc = '月支为日主之羊刃，性格刚强，宜官杀制刃。';
  } else {
    final hidden = _hiddenStems[monthBranch] ?? const <int>[];
    // 透干优先
    var patternStem = -1;
    final otherStems = [ganIdx[0], ganIdx[1], ganIdx[3]];
    for (final h in hidden) {
      if (h == dm) continue;
      if (otherStems.contains(h)) {
        patternStem = h;
        break;
      }
    }
    // 藏干兜底（主气非日主取主气，否则取次气）
    if (patternStem < 0 && hidden.isNotEmpty) {
      patternStem = hidden[0];
      if (patternStem == dm && hidden.length > 1) patternStem = hidden[1];
    }
    if (patternStem < 0) {
      pattern = '杂气格';
      patternDesc = '格局不纯，需综合分析。';
    } else {
      final tenGod = shiShenOf(_ganChars[dm], _ganChars[patternStem]);
      pattern = '$tenGod格';
      const descs = {
        '比肩格': '月令比肩当权，自立自强，宜官杀财星调候。',
        '劫财格': '月令劫财旺盛，争夺之象，宜官杀制之。',
        '食神格': '食神制杀，秀气流通，文雅有才华。',
        '伤官格': '伤官见官，是非纷争；伤官生财则富。',
        '偏财格': '偏财格主慷慨大方，善于理财。',
        '正财格': '正财格主勤俭持家，稳健守成。',
        '七杀格': '七杀格主威严果断，宜食神制杀。',
        '正官格': '正官格主端正守礼，利于仕途。',
        '偏印格': '偏印格主聪慧多思，但易犹豫不决。',
        '正印格': '正印格主仁厚好学，文昌之命。',
      };
      patternDesc = descs[pattern] ?? '格局以$tenGod为用，需结合全局分析。';
    }
  }

  // ---- 日主强弱（得令 + 得地 + 得势）----
  var score = 0.0;
  final factors = <String>[];
  // 得令
  final monthScore = _monthSupport[monthBranch][dmEl];
  score += monthScore;
  if (monthScore > 0) {
    factors.add('得令：${_zhiChars[monthBranch]}月生${_elementNames[dmEl]} (+$monthScore)');
  } else if (monthScore < 0) {
    factors.add('失令：${_zhiChars[monthBranch]}月克${_elementNames[dmEl]} ($monthScore)');
  }
  // 得地（年支/日支/时支藏干）
  const branchChecks = [0, 2, 3]; // 年支、日支、时支
  const branchLabels = ['年支', '日支', '时支'];
  for (var bi = 0; bi < 3; bi++) {
    final hidden = _hiddenStems[zhiIdx[branchChecks[bi]]] ?? const <int>[];
    for (final hs in hidden) {
      final hsEl = _ganElement(hs);
      if (hsEl == dmEl) {
        score += 0.5;
        factors.add('得地：${branchLabels[bi]}${_zhiChars[zhiIdx[branchChecks[bi]]]}藏'
            '${_ganChars[hs]}(${_elementNames[dmEl]}) (+0.5)');
      } else if (_elementProduce(hsEl) == dmEl) {
        score += 0.3;
        factors.add('得地：${branchLabels[bi]}藏干生日主 (+0.3)');
      }
    }
  }
  // 得势（年干/月干/时干）
  const stemChecks = [0, 1, 3];
  const stemLabels = ['年干', '月干', '时干'];
  for (var si = 0; si < 3; si++) {
    final sEl = _ganElement(ganIdx[stemChecks[si]]);
    if (sEl == dmEl) {
      score += 1.0;
      factors.add('得势：${stemLabels[si]}${gans[stemChecks[si]]}比劫 (+1.0)');
    } else if (_elementProduce(sEl) == dmEl) {
      score += 0.7;
      factors.add('得势：${stemLabels[si]}${gans[stemChecks[si]]}生日主 (+0.7)');
    }
  }
  String level;
  if (score >= 6) {
    level = '极旺';
  } else if (score >= 3) {
    level = '身强';
  } else if (score >= 1) {
    level = '中和';
  } else if (score >= -1) {
    level = '身弱';
  } else {
    level = '极弱';
  }

  // ---- 五行分布（天干 1.0 + 地支藏干加权 1.0/0.6/0.4）----
  final elScores = List<double>.filled(5, 0);
  for (var i = 0; i < 4; i++) {
    elScores[_ganElement(ganIdx[i])] += 1.0;
  }
  const weights = [1.0, 0.6, 0.4];
  for (var i = 0; i < 4; i++) {
    final hidden = _hiddenStems[zhiIdx[i]] ?? const <int>[];
    for (var h = 0; h < hidden.length; h++) {
      final w = h < weights.length ? weights[h] : 0.3;
      elScores[_ganElement(hidden[h])] += w;
    }
  }
  final total = elScores.fold<double>(0, (a, b) => a + b);
  final fiveElements = <({String element, double score, String status})>[
    for (var i = 0; i < 5; i++)
      (
        element: _elementNames[i],
        score: elScores[i],
        status: total > 0
            ? (elScores[i] >= total * 0.3
                ? '旺'
                : elScores[i] >= total * 0.15
                    ? '中'
                    : elScores[i] > 0
                        ? '弱'
                        : '缺')
            : '缺',
      ),
  ];

  // ---- 用神/忌神（身强克泄耗，身弱生扶）----
  var producerIdx = -1;
  for (var i = 0; i < 5; i++) {
    if (_elementProduce(i) == dmEl) {
      producerIdx = i;
      break;
    }
  }
  final childIdx = _elementProduce(dmEl); // 食伤（我生）
  final wealthIdx = _elementConquer(dmEl); // 财（我克）
  var officerIdx = -1;
  for (var j = 0; j < 5; j++) {
    if (_elementConquer(j) == dmEl) {
      officerIdx = j;
      break;
    }
  }
  final isStrong = score >= 1.5;
  final favorable = <String>[];
  final unfavorable = <String>[];
  if (isStrong) {
    if (officerIdx >= 0) favorable.add('${_elementNames[officerIdx]}(官杀)');
    if (childIdx >= 0) favorable.add('${_elementNames[childIdx]}(食伤)');
    if (wealthIdx >= 0) favorable.add('${_elementNames[wealthIdx]}(财)');
    if (producerIdx >= 0) unfavorable.add('${_elementNames[producerIdx]}(印)');
    unfavorable.add('${_elementNames[dmEl]}(比劫)');
  } else {
    if (producerIdx >= 0) favorable.add('${_elementNames[producerIdx]}(印)');
    favorable.add('${_elementNames[dmEl]}(比劫)');
    if (officerIdx >= 0) unfavorable.add('${_elementNames[officerIdx]}(官杀)');
    if (childIdx >= 0) unfavorable.add('${_elementNames[childIdx]}(食伤)');
    if (wealthIdx >= 0) unfavorable.add('${_elementNames[wealthIdx]}(财)');
  }

  return BaZiAnalysis(
    dayMaster: _ganChars[dm],
    pattern: pattern,
    patternDesc: patternDesc,
    strengthLevel: level,
    strengthScore: score,
    strengthFactors: factors,
    shensha: shensha,
    fiveElements: fiveElements,
    favorable: favorable,
    unfavorable: unfavorable,
    suggestion: isStrong
        ? '日主偏强，宜用${favorable.join('、')}克泄耗之。'
        : '日主偏弱，宜用${favorable.join('、')}生扶助之。',
  );
}
