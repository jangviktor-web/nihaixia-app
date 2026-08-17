/// 四柱命卦引擎（倪师《天纪·四柱命卦》）。
///
/// 算法依据《八字的排列方法》讲义，并经原文示例校准：
///   甲子 丁卯 庚申 庚辰（阳男）→ 先天卦 天风姤（已校准）
/// - 天干数：甲6 乙2 丙8 丁7 戊1 己9 庚3 辛4 壬6 癸2
/// - 地支河图数：子1,6 丑5,10 寅3,8 卯3,8 辰5,10 巳2,7 午1,6 未5,10 申4,9 酉4,9 戌5,10 亥1,6
/// - 阳数=干支各数中奇数之和；阴数=偶数之和
/// - 上卦数=阳数−25（超25）；下卦数=阴数−30（超30）→ 洛书卦数
/// - 洛书数：1坎 2坤 3震 4巽 5中 6乾 7兑 8艮 9离
/// - 阳男阴女 天数(上卦数)在上；阴男阳女 地数在上
/// - 后天卦：按讲义「天旋地转反过来」= 先天卦上下卦互换（3.水雷屯:3 解读）
///
/// 注意：值年卦依赖皇极经世查条表，讲义未含完整算法，本引擎不自动计算。
/// 结果属传统文化参考，非医疗建议。
library;

import '../data/yijing_data.dart';
import 'yijing_engine.dart';
import 'package:ziwei_core/ziwei_core.dart';

/// 六十甲子纳音名（每两组一音，共 30 组，序按 甲子1..癸亥60）。
const List<String> _nayinNames = [
  '海中金', '炉中火', '大林木', '路旁土', '剑锋金', '山头火', '涧下水', '城头土', '白蜡金', '杨柳木',
  '泉中水', '屋上土', '霹雳火', '松柏木', '长流水', '沙中金', '山下火', '平地木', '壁上土', '金箔金',
  '覆灯火', '天河水', '大驿土', '钗钏金', '桑柘木', '大溪水', '沙中土', '天上火', '石榴木', '大海水',
];

/// 六十甲子纳音（如 甲子→海中金）。非法干支返回空串。
String nayinOf(String gan, String zhi) {
  const gans = '甲乙丙丁戊己庚辛壬癸';
  const zhis = '子丑寅卯辰巳午未申酉戌亥';
  final g = gans.indexOf(gan);
  final z = zhis.indexOf(zhi);
  if (g < 0 || z < 0) return '';
  final seq = (g * 6 - z * 5 + 60) % 60; // 0-based 甲子序
  return _nayinNames[seq ~/ 2];
}

/// 十神中文名表。
const Map<String, String> _shiShenCn = {
  'biJian': '比肩',
  'jieCai': '劫财',
  'shiShen': '食神',
  'shangGuan': '伤官',
  'pianCai': '偏财',
  'zhengCai': '正财',
  'qiSha': '七杀',
  'zhengGuan': '正官',
  'pianYin': '偏印',
  'zhengYin': '正印',
};

/// 天干相对日主的十神（如 日主庚、见甲 → 偏财）。
String shiShenOf(String dayGan, String gan) {
  final dm = TianGan.values.where((g) => g.label == dayGan).firstOrNull;
  final tg = TianGan.values.where((g) => g.label == gan).firstOrNull;
  if (dm == null || tg == null) return '';
  return _shiShenCn[Relationship.getShiShen(dm, tg).name] ?? '';
}

const Map<String, int> _ganNumber = {
  '甲': 6,
  '乙': 2,
  '丙': 8,
  '丁': 7,
  '戊': 1,
  '己': 9,
  '庚': 3,
  '辛': 4,
  '壬': 6,
  '癸': 2,
};

const Map<String, List<int>> _zhiNumber = {
  '子': [1, 6],
  '丑': [5, 10],
  '寅': [3, 8],
  '卯': [3, 8],
  '辰': [5, 10],
  '巳': [2, 7],
  '午': [1, 6],
  '未': [5, 10],
  '申': [4, 9],
  '酉': [4, 9],
  '戌': [5, 10],
  '亥': [1, 6],
};

/// 洛书卦数 → 卦名
const Map<int, String> _luoshuTrigram = {
  1: '坎',
  2: '坤',
  3: '震',
  4: '巽',
  5: '中',
  6: '乾',
  7: '兑',
  8: '艮',
  9: '离',
};

/// 洛书卦名 → kTrigrams 下标
const Map<String, int> _trigramIndex = {
  '坎': 5,
  '坤': 7,
  '震': 3,
  '巽': 4,
  '乾': 0,
  '兑': 1,
  '艮': 6,
  '离': 2,
};

const Set<String> _yangGan = {'甲', '丙', '戊', '庚', '壬'};

/// 四柱命卦计算结果。
class MingGuaResult {
  final String baziYear; // 年柱干支（如 甲子）
  final String baziMonth;
  final String baziDay;
  final String baziTime;
  final int yangNumber; // 阳数（天数）
  final int yinNumber; // 阴数（地数）
  final int upperNumber; // 上卦数（洛书）
  final int lowerNumber; // 下卦数（洛书）
  final Hexagram xianTian; // 先天卦（前半生）
  final Hexagram houTian; // 后天卦（后半生，上下互换解读）

  const MingGuaResult({
    required this.baziYear,
    required this.baziMonth,
    required this.baziDay,
    required this.baziTime,
    required this.yangNumber,
    required this.yinNumber,
    required this.upperNumber,
    required this.lowerNumber,
    required this.xianTian,
    required this.houTian,
  });

  String get baziFull => '$baziYear $baziMonth $baziDay $baziTime';
}

class MingGuaEngine {
  MingGuaEngine._();

  /// 以四柱干支（单字）计算先天/后天卦。
  /// [male]：性别；任一柱干支非法或洛书数为「中」时返回 null。
  static MingGuaResult? compute({
    required String yearGan,
    required String yearZhi,
    required String monthGan,
    required String monthZhi,
    required String dayGan,
    required String dayZhi,
    required String timeGan,
    required String timeZhi,
    required bool male,
  }) {
    final gans = [yearGan, monthGan, dayGan, timeGan];
    final zhis = [yearZhi, monthZhi, dayZhi, timeZhi];
    if (gans.any((g) => !_ganNumber.containsKey(g)) ||
        zhis.any((z) => !_zhiNumber.containsKey(z))) {
      return null;
    }

    // 干支各数取奇/偶分计
    var yang = 0, yin = 0;
    for (var i = 0; i < 4; i++) {
      final gn = _ganNumber[gans[i]]!;
      if (gn.isOdd) {
        yang += gn;
      } else {
        yin += gn;
      }
      for (final n in _zhiNumber[zhis[i]]!) {
        if (n.isOdd) {
          yang += n;
        } else {
          yin += n;
        }
      }
    }

    final upperN = _collapse(yang > 25 ? yang - 25 : yang);
    final lowerN = _collapse(yin > 30 ? yin - 30 : yin);
    final upperT = _luoshuTrigram[upperN];
    final lowerT = _luoshuTrigram[lowerN];
    if (upperT == null || lowerT == null || upperT == '中' || lowerT == '中') {
      return null; // 五入中宫/卦数无效（0），无法成卦
    }

    // 天数(上卦数)在上 <=> 阳干年 与 男 同真
    final daysUp = _yangGan.contains(yearGan) == male;
    final xianUpper = daysUp ? upperT : lowerT;
    final xianLower = daysUp ? lowerT : upperT;
    // 后天卦：天旋地转反过来 = 先天卦上下互换
    final houUpper = xianLower;
    final houLower = xianUpper;

    final xian = _byTrigrams(xianUpper, xianLower);
    final hou = _byTrigrams(houUpper, houLower);
    if (xian == null || hou == null) return null;

    return MingGuaResult(
      baziYear: '$yearGan$yearZhi',
      baziMonth: '$monthGan$monthZhi',
      baziDay: '$dayGan$dayZhi',
      baziTime: '$timeGan$timeZhi',
      yangNumber: yang,
      yinNumber: yin,
      upperNumber: upperN,
      lowerNumber: lowerN,
      xianTian: xian,
      houTian: hou,
    );
  }

  /// 「遇10统统不用」取数：从右起取最后一个非零数字（10→1, 20→2, 30→3, 13→3, 6→6）；0→无效。
  static int _collapse(int n) {
    if (n <= 0) return 0;
    final s = n.toString();
    for (var i = s.length - 1; i >= 0; i--) {
      final d = s.codeUnitAt(i) - 0x30;
      if (d != 0) return d;
    }
    return 0;
  }

  static Hexagram? _byTrigrams(String upperName, String lowerName) {
    final u = _trigramIndex[upperName];
    final l = _trigramIndex[lowerName];
    if (u == null || l == null) return null;
    return YiJingEngine.byUpperLower(u, l);
  }
}
