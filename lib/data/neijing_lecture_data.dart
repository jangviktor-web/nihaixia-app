/// 《人纪·黄帝内经》阅读库索引（拆分自倪师内经讲稿书面整理版）。
/// 72 篇正文 + 前言；原文第 25、66-74 篇原稿未收录，不强补。
library;

class NeiJingLecture {
  final int seq; // 0=前言, 1-81=篇序
  final String name;
  final String asset;

  const NeiJingLecture({
    required this.seq,
    required this.name,
    required this.asset,
  });
}

const List<NeiJingLecture> kNeiJingLectures = [
  NeiJingLecture(seq: 0, name: '前言', asset: 'assets/neijing/00_前言.md'),
  NeiJingLecture(seq: 1, name: '上古天真论', asset: 'assets/neijing/01_上古天真论.md'),
  NeiJingLecture(seq: 2, name: '四气调神大论', asset: 'assets/neijing/02_四气调神大论.md'),
  NeiJingLecture(seq: 3, name: '生气通天论', asset: 'assets/neijing/03_生气通天论.md'),
  NeiJingLecture(seq: 4, name: '金匮真言论', asset: 'assets/neijing/04_金匮真言论.md'),
  NeiJingLecture(seq: 5, name: '阴阳应象大论', asset: 'assets/neijing/05_阴阳应象大论.md'),
  NeiJingLecture(seq: 6, name: '阴阳离合论', asset: 'assets/neijing/06_阴阳离合论.md'),
  NeiJingLecture(seq: 7, name: '阴阳别论', asset: 'assets/neijing/07_阴阳别论.md'),
  NeiJingLecture(seq: 8, name: '灵兰秘典论', asset: 'assets/neijing/08_灵兰秘典论.md'),
  NeiJingLecture(seq: 9, name: '六节藏象论', asset: 'assets/neijing/09_六节藏象论.md'),
  NeiJingLecture(seq: 10, name: '五脏生成', asset: 'assets/neijing/10_五脏生成.md'),
  NeiJingLecture(seq: 11, name: '五藏别论', asset: 'assets/neijing/11_五藏别论.md'),
  NeiJingLecture(seq: 12, name: '异法方宜论', asset: 'assets/neijing/12_异法方宜论.md'),
  NeiJingLecture(seq: 13, name: '移精变气论', asset: 'assets/neijing/13_移精变气论.md'),
  NeiJingLecture(seq: 14, name: '汤液醪醴论', asset: 'assets/neijing/14_汤液醪醴论.md'),
  NeiJingLecture(seq: 15, name: '玉版论要', asset: 'assets/neijing/15_玉版论要.md'),
  NeiJingLecture(seq: 16, name: '诊要经终论', asset: 'assets/neijing/16_诊要经终论.md'),
  NeiJingLecture(seq: 17, name: '脉要精微论', asset: 'assets/neijing/17_脉要精微论.md'),
  NeiJingLecture(seq: 18, name: '平人气象论', asset: 'assets/neijing/18_平人气象论.md'),
  NeiJingLecture(seq: 19, name: '玉机真藏论', asset: 'assets/neijing/19_玉机真藏论.md'),
  NeiJingLecture(seq: 20, name: '三部九候论', asset: 'assets/neijing/20_三部九候论.md'),
  NeiJingLecture(seq: 21, name: '经脉别论', asset: 'assets/neijing/21_经脉别论.md'),
  NeiJingLecture(seq: 22, name: '藏气法时论', asset: 'assets/neijing/22_藏气法时论.md'),
  NeiJingLecture(seq: 23, name: '宣明五气篇', asset: 'assets/neijing/23_宣明五气篇.md'),
  NeiJingLecture(seq: 24, name: '血气形志论', asset: 'assets/neijing/24_血气形志论.md'),
  NeiJingLecture(seq: 26, name: '八正神明论', asset: 'assets/neijing/26_八正神明论.md'),
  NeiJingLecture(seq: 27, name: '离合真邪论', asset: 'assets/neijing/27_离合真邪论.md'),
  NeiJingLecture(seq: 28, name: '通评虚实论', asset: 'assets/neijing/28_通评虚实论.md'),
  NeiJingLecture(seq: 29, name: '太阴阳明论', asset: 'assets/neijing/29_太阴阳明论.md'),
  NeiJingLecture(seq: 30, name: '阳明脉解', asset: 'assets/neijing/30_阳明脉解.md'),
  NeiJingLecture(seq: 31, name: '热论', asset: 'assets/neijing/31_热论.md'),
  NeiJingLecture(seq: 32, name: '刺热论', asset: 'assets/neijing/32_刺热论.md'),
  NeiJingLecture(seq: 33, name: '评热病论', asset: 'assets/neijing/33_评热病论.md'),
  NeiJingLecture(seq: 34, name: '逆调论', asset: 'assets/neijing/34_逆调论.md'),
  NeiJingLecture(seq: 35, name: '疟论', asset: 'assets/neijing/35_疟论.md'),
  NeiJingLecture(seq: 36, name: '刺疟', asset: 'assets/neijing/36_刺疟.md'),
  NeiJingLecture(seq: 37, name: '气厥论', asset: 'assets/neijing/37_气厥论.md'),
  NeiJingLecture(seq: 38, name: '欬[kài]论', asset: 'assets/neijing/38_欬[kài]论.md'),
  NeiJingLecture(seq: 39, name: '举痛论', asset: 'assets/neijing/39_举痛论.md'),
  NeiJingLecture(seq: 40, name: '腹中论', asset: 'assets/neijing/40_腹中论.md'),
  NeiJingLecture(seq: 41, name: '刺腰痛论', asset: 'assets/neijing/41_刺腰痛论.md'),
  NeiJingLecture(seq: 42, name: '风论', asset: 'assets/neijing/42_风论.md'),
  NeiJingLecture(seq: 43, name: '痹论', asset: 'assets/neijing/43_痹论.md'),
  NeiJingLecture(seq: 44, name: '痿论', asset: 'assets/neijing/44_痿论.md'),
  NeiJingLecture(seq: 45, name: '厥论', asset: 'assets/neijing/45_厥论.md'),
  NeiJingLecture(seq: 46, name: '病能（态）', asset: 'assets/neijing/46_病能（态）.md'),
  NeiJingLecture(seq: 47, name: '奇病论', asset: 'assets/neijing/47_奇病论.md'),
  NeiJingLecture(seq: 48, name: '大奇论', asset: 'assets/neijing/48_大奇论.md'),
  NeiJingLecture(seq: 49, name: '脉解', asset: 'assets/neijing/49_脉解.md'),
  NeiJingLecture(seq: 50, name: '刺要论', asset: 'assets/neijing/50_刺要论.md'),
  NeiJingLecture(seq: 51, name: '刺齐论', asset: 'assets/neijing/51_刺齐论.md'),
  NeiJingLecture(seq: 52, name: '刺禁论', asset: 'assets/neijing/52_刺禁论.md'),
  NeiJingLecture(seq: 53, name: '刺志论', asset: 'assets/neijing/53_刺志论.md'),
  NeiJingLecture(seq: 54, name: '针解', asset: 'assets/neijing/54_针解.md'),
  NeiJingLecture(seq: 55, name: '长刺节论', asset: 'assets/neijing/55_长刺节论.md'),
  NeiJingLecture(seq: 56, name: '皮部论', asset: 'assets/neijing/56_皮部论.md'),
  NeiJingLecture(seq: 57, name: '经络论', asset: 'assets/neijing/57_经络论.md'),
  NeiJingLecture(seq: 58, name: '气穴论', asset: 'assets/neijing/58_气穴论.md'),
  NeiJingLecture(seq: 59, name: '气腑论', asset: 'assets/neijing/59_气腑论.md'),
  NeiJingLecture(seq: 60, name: '骨空论', asset: 'assets/neijing/60_骨空论.md'),
  NeiJingLecture(seq: 61, name: '水热穴论', asset: 'assets/neijing/61_水热穴论.md'),
  NeiJingLecture(seq: 62, name: '调经论', asset: 'assets/neijing/62_调经论.md'),
  NeiJingLecture(seq: 63, name: '缪刺论', asset: 'assets/neijing/63_缪刺论.md'),
  NeiJingLecture(seq: 64, name: '四时刺逆从论', asset: 'assets/neijing/64_四时刺逆从论.md'),
  NeiJingLecture(seq: 65, name: '标本病传论', asset: 'assets/neijing/65_标本病传论.md'),
  NeiJingLecture(seq: 72, name: '刺法论', asset: 'assets/neijing/72_刺法论.md'),
  NeiJingLecture(seq: 75, name: '着至教论篇', asset: 'assets/neijing/75_着至教论篇.md'),
  NeiJingLecture(seq: 76, name: '示从容论', asset: 'assets/neijing/76_示从容论.md'),
  NeiJingLecture(seq: 77, name: '疏五过论', asset: 'assets/neijing/77_疏五过论.md'),
  NeiJingLecture(seq: 78, name: '征四失论', asset: 'assets/neijing/78_征四失论.md'),
  NeiJingLecture(seq: 79, name: '阴阳类论', asset: 'assets/neijing/79_阴阳类论.md'),
  NeiJingLecture(seq: 80, name: '方盛衰论', asset: 'assets/neijing/80_方盛衰论.md'),
  NeiJingLecture(seq: 81, name: '解经微论', asset: 'assets/neijing/81_解经微论.md'),
];

/// 按篇序取资源路径；不存在返回 null。
String? neijingAsset(int seq) {
  for (final l in kNeiJingLectures) {
    if (l.seq == seq) return l.asset;
  }
  return null;
}
