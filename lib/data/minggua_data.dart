/// 倪师《天纪·四柱命卦》讲义索引（由天纪原文自动生成，勿手改）。
///
/// 0=八字的排列方法（算法源），1-64=各卦先天/后天/值年卦批解，65=批卦补充。
/// 资源文件：assets/yijing_minggua/*.md（已剔除图片引用行，正文逐字保留）。
class MingGuaEntry {
  final int seq; // 0(排法) / 1-64(卦) / 65(补充)
  final String title;
  final String asset;
  final String kind; // overview / hex / supplement
  const MingGuaEntry({
    required this.seq,
    required this.title,
    required this.asset,
    required this.kind,
  });
}

const List<MingGuaEntry> kMingGuaEntries = [
  MingGuaEntry(
    seq: 0,
    title: '八字排列方法（四柱命卦算法）',
    asset: 'assets/yijing_minggua/0.八字的排列方法.md',
    kind: 'overview',
  ),
  MingGuaEntry(
    seq: 1,
    title: '乾为天',
    asset: 'assets/yijing_minggua/1.乾为天.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 2,
    title: '坤为地',
    asset: 'assets/yijing_minggua/2.坤为地.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 3,
    title: '水雷屯',
    asset: 'assets/yijing_minggua/3.水雷屯.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 4,
    title: '山水蒙',
    asset: 'assets/yijing_minggua/4.山水蒙.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 5,
    title: '水天需',
    asset: 'assets/yijing_minggua/5.水天需.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 6,
    title: '天水讼',
    asset: 'assets/yijing_minggua/6.天水讼.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 7,
    title: '地水师',
    asset: 'assets/yijing_minggua/7.地水师.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 8,
    title: '水地比',
    asset: 'assets/yijing_minggua/8.水地比.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 9,
    title: '风天小畜',
    asset: 'assets/yijing_minggua/9.风天小畜.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 10,
    title: '天泽履',
    asset: 'assets/yijing_minggua/10.天泽履.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 11,
    title: '地天泰',
    asset: 'assets/yijing_minggua/11.地天泰.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 12,
    title: '天地否',
    asset: 'assets/yijing_minggua/12.天地否.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 13,
    title: '天火同人',
    asset: 'assets/yijing_minggua/13.天火同人.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 14,
    title: '火天大有',
    asset: 'assets/yijing_minggua/14.火天大有.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 15,
    title: '地山谦',
    asset: 'assets/yijing_minggua/15.地山谦.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 16,
    title: '雷地豫',
    asset: 'assets/yijing_minggua/16.雷地豫.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 17,
    title: '泽雷随',
    asset: 'assets/yijing_minggua/17.泽雷随.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 18,
    title: '山风蛊',
    asset: 'assets/yijing_minggua/18.山风蛊.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 19,
    title: '地泽临',
    asset: 'assets/yijing_minggua/19.地泽临.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 20,
    title: '风地观',
    asset: 'assets/yijing_minggua/20.风地观.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 21,
    title: '火雷噬嗑',
    asset: 'assets/yijing_minggua/21.火雷噬嗑.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 22,
    title: '山火贲',
    asset: 'assets/yijing_minggua/22.山火贲.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 23,
    title: '山地剥',
    asset: 'assets/yijing_minggua/23.山地剥.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 24,
    title: '地雷复',
    asset: 'assets/yijing_minggua/24.地雷复.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 25,
    title: '天雷无妄',
    asset: 'assets/yijing_minggua/25.天雷无妄.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 26,
    title: '山天大畜',
    asset: 'assets/yijing_minggua/26.山天大畜.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 27,
    title: '山雷颐',
    asset: 'assets/yijing_minggua/27.山雷颐.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 28,
    title: '泽风大过',
    asset: 'assets/yijing_minggua/28.泽风大过.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 29,
    title: '坎为水',
    asset: 'assets/yijing_minggua/29.坎为水.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 30,
    title: '离为火',
    asset: 'assets/yijing_minggua/30.离为火.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 31,
    title: '泽山咸',
    asset: 'assets/yijing_minggua/31.泽山咸.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 32,
    title: '雷风恒',
    asset: 'assets/yijing_minggua/32.雷风恒.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 33,
    title: '天山遯',
    asset: 'assets/yijing_minggua/33.天山遯.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 34,
    title: '雷天大壮',
    asset: 'assets/yijing_minggua/34.雷天大壮.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 35,
    title: '火地晋',
    asset: 'assets/yijing_minggua/35.火地晋.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 36,
    title: '地火明夷',
    asset: 'assets/yijing_minggua/36.地火明夷.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 37,
    title: '风火家人',
    asset: 'assets/yijing_minggua/37.风火家人.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 38,
    title: '火泽睽',
    asset: 'assets/yijing_minggua/38.火泽睽.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 39,
    title: '水山蹇',
    asset: 'assets/yijing_minggua/39.水山蹇.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 40,
    title: '雷水解',
    asset: 'assets/yijing_minggua/40.雷水解.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 41,
    title: '山泽损',
    asset: 'assets/yijing_minggua/41.山泽损.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 42,
    title: '风雷益',
    asset: 'assets/yijing_minggua/42.风雷益.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 43,
    title: '泽天夬',
    asset: 'assets/yijing_minggua/43.泽天夬.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 44,
    title: '天风姤',
    asset: 'assets/yijing_minggua/44.天风姤.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 45,
    title: '泽地萃',
    asset: 'assets/yijing_minggua/45.泽地萃.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 46,
    title: '地风升',
    asset: 'assets/yijing_minggua/46.地风升.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 47,
    title: '泽水困',
    asset: 'assets/yijing_minggua/47.泽水困.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 48,
    title: '水风井',
    asset: 'assets/yijing_minggua/48.水风井.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 49,
    title: '泽火革',
    asset: 'assets/yijing_minggua/49.泽火革.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 50,
    title: '火风鼎',
    asset: 'assets/yijing_minggua/50.火风鼎.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 51,
    title: '震为雷',
    asset: 'assets/yijing_minggua/51.震为雷.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 52,
    title: '艮为山',
    asset: 'assets/yijing_minggua/52.艮为山.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 53,
    title: '风山渐',
    asset: 'assets/yijing_minggua/53.风山渐.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 54,
    title: '雷泽归妹',
    asset: 'assets/yijing_minggua/54.雷泽归妹.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 55,
    title: '雷火丰',
    asset: 'assets/yijing_minggua/55.雷火丰.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 56,
    title: '火山旅',
    asset: 'assets/yijing_minggua/56.火山旅.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 57,
    title: '巽为风',
    asset: 'assets/yijing_minggua/57.巽为风.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 58,
    title: '兑为泽',
    asset: 'assets/yijing_minggua/58.兑为泽.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 59,
    title: '风水涣',
    asset: 'assets/yijing_minggua/59.风水涣.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 60,
    title: '水泽节',
    asset: 'assets/yijing_minggua/60.水泽节.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 61,
    title: '风泽中孚',
    asset: 'assets/yijing_minggua/61.风泽中孚.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 62,
    title: '雷山小过',
    asset: 'assets/yijing_minggua/62.雷山小过.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 63,
    title: '水火既济',
    asset: 'assets/yijing_minggua/63.水火既济.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 64,
    title: '火水未济',
    asset: 'assets/yijing_minggua/64.火水未济.md',
    kind: 'hex',
  ),
  MingGuaEntry(
    seq: 65,
    title: '批卦补充',
    asset: 'assets/yijing_minggua/65.批卦补充.md',
    kind: 'supplement',
  ),
];

/// 按卦序取四柱命卦讲义资源路径；仅卦条目(1-64)，非卦条目(0/65)返回 null。
String? mingGuaLectureAsset(int seq) {
  for (final e in kMingGuaEntries) {
    if (e.seq == seq && e.kind == 'hex') return e.asset;
  }
  return null;
}
