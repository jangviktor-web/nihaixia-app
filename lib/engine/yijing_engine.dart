/// 易经六十四卦起卦/解卦引擎（纯 Dart，无 Flutter 依赖）
///
/// 起卦方法：
/// - [castByTime]  时间起卦（梅花易数）：年支序 + 月 + 日 → 上卦；+ 时辰 → 下卦；
///                 总和 → 动爻。注意：使用公历月日（简化，传统用农历）。
/// - [castByNumbers] 数字起卦：两数 mod 8 → 上下卦，两数和 mod 6 → 动爻。
/// - [castManual]  手动选卦：直接选上卦/下卦先天数 + 动爻。
///
/// 解卦输出：本卦、动爻爻辞、变卦（动爻变）、互卦（2/3/4 爻为下、3/4/5 爻为上）。
library;

import '../data/yijing_data.dart';

class CastResult {
  final Hexagram primary; // 本卦
  final int moving; // 主断动爻 1-6；0 表示六爻皆静（多动爻时取首动爻）
  final List<int> movingLines; // 全部动爻位置（1-6 升序）；空 = 静卦
  final Hexagram? changed; // 变卦（有动爻时，全部动爻翻转）
  final Hexagram? nuclear; // 互卦
  final String method; // 起卦法描述

  const CastResult({
    required this.primary,
    required this.moving,
    required this.method,
    this.changed,
    this.nuclear,
    this.movingLines = const [],
  });

  String get primarySymbol => YiJingEngine.symbol(primary.seq);
  String? get changedSymbol => changed == null ? null : YiJingEngine.symbol(changed!.seq);
  String? get nuclearSymbol => nuclear == null ? null : YiJingEngine.symbol(nuclear!.seq);

  /// 本卦六爻（下→上，1=阳 0=阴）
  List<int> get primaryLines => YiJingEngine.linesOf(primary);

  /// 主断动爻爻题（如 初九 / 六五）
  String get movingTitle => moving == 0
      ? '静卦（六爻皆静）'
      : YiJingEngine.lineTitle(moving, primaryLines[moving - 1] == 1);

  /// 全部动爻爻题（多动爻展示用；静卦返回 ['静卦（六爻皆静）']）
  List<String> get movingTitles => movingLines.isEmpty
      ? ['静卦（六爻皆静）']
      : [
          for (final p in movingLines)
            YiJingEngine.lineTitle(p, primaryLines[p - 1] == 1),
        ];

  /// 主断动爻爻辞（静卦则强调卦辞）
  String get movingText => moving == 0 ? primary.judgement : primary.lines[moving - 1];

  /// 全部动爻爻辞（多动爻展示用；静卦返回卦辞）
  List<String> get movingTexts => movingLines.isEmpty
      ? [primary.judgement]
      : [for (final p in movingLines) primary.lines[p - 1]];
}

class YiJingEngine {
  YiJingEngine._();

  static final Map<int, Hexagram> _bySeq = {
    for (final h in kHexagrams) h.seq: h,
  };

  static final Map<String, Hexagram> _byUpperLower = {
    for (final h in kHexagrams) '${h.upper}:${h.lower}': h,
  };

  static final Map<String, int> _trigramLineMap = {
    for (var i = 0; i < kTrigrams.length; i++) kTrigrams[i].lines.join(''): i,
  };

  /// 卦符 Unicode（King Wen 序一一对应 U+4DC0..U+4DFF）
  static String symbol(int seq) => String.fromCharCode(0x4DC0 + seq - 1);

  static Hexagram? bySeq(int seq) => _bySeq[seq];

  static Hexagram? byUpperLower(int upper, int lower) => _byUpperLower['$upper:$lower'];

  /// 某卦六爻（下→上）
  static List<int> linesOf(Hexagram h) =>
      [...kTrigrams[h.lower].lines, ...kTrigrams[h.upper].lines];

  /// 爻题：初九/九二/六二/九五/上六（初、上两位位置在前，其余九/六在前）
  static String lineTitle(int pos, bool yang) {
    const posNames = ['初', '二', '三', '四', '五', '上'];
    final value = yang ? '九' : '六';
    if (pos == 1) return '初$value';
    if (pos == 6) return '上$value';
    return '$value${posNames[pos - 1]}';
  }

  /// 手动起卦
  /// [upperXiantian]/[lowerXiantian]：先天数 1-8；[moving]：动爻 0-6（0=静卦）
  static CastResult castManual(int upperXiantian, int lowerXiantian, int moving) {
    assert(upperXiantian >= 1 && upperXiantian <= 8);
    assert(lowerXiantian >= 1 && lowerXiantian <= 8);
    assert(moving >= 0 && moving <= 6);
    final upper = upperXiantian - 1;
    final lower = lowerXiantian - 1;
    final cast = _build(upper, lower, moving);
    return CastResult(
      primary: cast.$1,
      moving: moving,
      changed: cast.$2,
      nuclear: cast.$3,
      method: '手动选卦：上${kTrigrams[upper].name}下${kTrigrams[lower].name}'
          '${moving == 0 ? '，静卦' : '，$moving爻动'}',
    );
  }

  /// 数字起卦：两数（任意非负整数）
  static CastResult castByNumbers(int a, int b) {
    final upperNum = a % 8 == 0 ? 8 : a % 8;
    final lowerNum = b % 8 == 0 ? 8 : b % 8;
    final moving = (a + b) % 6 == 0 ? 6 : (a + b) % 6;
    final upper = upperNum - 1;
    final lower = lowerNum - 1;
    final cast = _build(upper, lower, moving);
    return CastResult(
      primary: cast.$1,
      moving: moving,
      changed: cast.$2,
      nuclear: cast.$3,
      method: '数字起卦：$a、$b → 上${kTrigrams[upper].name}下${kTrigrams[lower].name}，$moving爻动',
    );
  }

  /// 时间起卦（梅花易数；年支序 + 公历月日 + 时辰）
  static CastResult castByTime(DateTime t) {
    final yearBranch = ((t.year - 4) % 12) + 1; // 子1..亥12
    final shichen = ((t.hour + 1) ~/ 2) % 12 + 1; // 子时1..亥时12
    final upperNum = (yearBranch + t.month + t.day) % 8;
    final lowerNum = (yearBranch + t.month + t.day + shichen) % 8;
    final moving = (yearBranch + t.month + t.day + shichen) % 6;
    final upper = (upperNum == 0 ? 8 : upperNum) - 1;
    final lower = (lowerNum == 0 ? 8 : lowerNum) - 1;
    final mv = moving == 0 ? 6 : moving;
    final cast = _build(upper, lower, mv);
    return CastResult(
      primary: cast.$1,
      moving: mv,
      changed: cast.$2,
      nuclear: cast.$3,
      method: '时间起卦：${t.year}年${t.month}月${t.day}日'
          '${t.hour.toString().padLeft(2, '0')}时 → '
          '上${kTrigrams[upper].name}下${kTrigrams[lower].name}，$mv爻动',
    );
  }

  /// 六爻铜钱摇卦（三枚铜钱 × 6 次，自初爻至上爻）
  ///
  /// [coins]：6 个值，自初爻至上爻，每个为 6/7/8/9：
  /// - 9 老阳（三正）动爻、7 少阳（二正一反）静爻
  /// - 8 少阴（一正二反）静爻、6 老阴（三反）动爻
  ///
  /// 变卦 = 本卦所有动爻（6/9）翻转；互卦 = 2/3/4 爻为下、3/4/5 爻为上。
  static CastResult castByCoins(List<int> coins) {
    assert(coins.length == 6, '摇卦需 6 爻结果');
    final valid = coins.every((c) => c == 6 || c == 7 || c == 8 || c == 9);
    assert(valid, '爻值必须为 6/7/8/9');

    // 阴阳（1=阳 0=阴）：7/9 为阳，6/8 为阴
    final lowerLines = coins.sublist(0, 3).map((c) => (c == 7 || c == 9) ? 1 : 0).toList();
    final upperLines = coins.sublist(3, 6).map((c) => (c == 7 || c == 9) ? 1 : 0).toList();
    final lower = _trigramLineMap[lowerLines.join('')]!;
    final upper = _trigramLineMap[upperLines.join('')]!;

    // 动爻（6/9 位置，1-6）
    final movingLines = <int>[
      for (var i = 0; i < 6; i++)
        if (coins[i] == 6 || coins[i] == 9) i + 1,
    ];

    final cast = _buildMulti(upper, lower, movingLines);
    return CastResult(
      primary: cast.$1,
      moving: movingLines.isEmpty ? 0 : movingLines.first,
      movingLines: movingLines,
      changed: cast.$2,
      nuclear: cast.$3,
      method: '铜钱摇卦：${movingLines.isEmpty ? '六爻皆静' : '${movingLines.length}爻动'
          '（${movingLines.map((p) => '第$p爻').join('、')}）'}',
    );
  }

  /// 由上下卦 + 单动爻组装解卦结果（本卦 / 变卦 / 互卦）
  static (Hexagram, Hexagram?, Hexagram?) _build(int upper, int lower, int moving) {
    return _buildMulti(upper, lower, moving == 0 ? const [] : [moving]);
  }

  /// 由上下卦 + 动爻列表组装解卦结果（本卦 / 变卦 / 互卦）
  ///
  /// 变卦：所有动爻位置翻转；互卦：2/3/4 爻为下卦，3/4/5 爻为上卦。
  static (Hexagram, Hexagram?, Hexagram?) _buildMulti(
    int upper,
    int lower,
    List<int> movingLines,
  ) {
    final primary = byUpperLower(upper, lower)!;
    Hexagram? changed;
    if (movingLines.isNotEmpty) {
      final lines = linesOf(primary);
      for (final p in movingLines) {
        lines[p - 1] = lines[p - 1] == 1 ? 0 : 1; // 动爻翻转
      }
      final newLower = _trigramLineMap[lines.sublist(0, 3).join('')]!;
      final newUpper = _trigramLineMap[lines.sublist(3, 6).join('')]!;
      changed = byUpperLower(newUpper, newLower);
    }
    // 互卦：2/3/4 爻为下卦，3/4/5 爻为上卦
    final lines = linesOf(primary);
    final nLower = _trigramLineMap[lines.sublist(1, 4).join('')]!;
    final nUpper = _trigramLineMap[lines.sublist(2, 5).join('')]!;
    final nuclear = byUpperLower(nUpper, nLower);
    return (primary, changed, nuclear);
  }
}
