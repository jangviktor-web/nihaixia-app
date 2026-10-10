/// 子午流注·开穴引擎（纯 Dart，无 flutter 依赖，可独立单测）
///
/// 覆盖三大"按时取穴"流派：
///  - 纳甲法（井荥输经合 + 返本还原 + 合日互用）
///  - 灵龟八法（八脉交会穴，主穴配穴相配）
///  - 飞腾八法（时干查卦取单穴）
///
/// 数据来源：acuherb/ziwu（经典标准查表，逐字搬运自其 index.html 内联 JS）。
/// 口径说明：本文件仅含"开穴推演"算法与经典标准表；倪师人纪专属数据
/// （本穴表、五门十变）保留在屏幕层（ziwuliuzhu_screen.dart），不在此覆盖。
///
/// 干支约定：甲=0 … 癸=9；子=0 … 亥=11。与 ziwu 同源。
library;

import 'package:ziwei_core/ziwei_core.dart' show Gender, Location, RatHourMode;
import 'package:bazi_core/bazi_core.dart' as bazi;

const List<String> _gan = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
const List<String> _zhi = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

int _mod(int a, int n) => ((a % n) + n) % n;

/// 天干名（索引 0-9）
String ganName(int i) => _gan[_mod(i, 10)];

/// 地支名（索引 0-11）
String zhiName(int i) => _zhi[_mod(i, 12)];

// ───────────────────────── 纳甲法 ─────────────────────────

/// 纳甲逐日穴表：10 行（日干）× 6 列（井→荥→输→经→合→纳三焦/包络）
/// 每格 [穴名, 经脉名, 类型]
const List<List<List<String>>> _najiaPoints = [
  [['窍阴', '胆经', '井'], ['前谷', '小肠经', '荥'], ['陷谷', '胃经', '输'], ['阳溪', '大肠经', '经'], ['委中', '膀胱经', '合'], ['液门', '三焦经', '纳三焦']],
  [['大敦', '肝经', '井'], ['少府', '心经', '荥'], ['太白', '脾经', '输'], ['经渠', '肺经', '经'], ['阴谷', '肾经', '合'], ['劳宫', '心包经', '纳包络']],
  [['少泽', '小肠经', '井'], ['内庭', '胃经', '荥'], ['三间', '大肠经', '输'], ['昆仑', '膀胱经', '经'], ['阳陵泉', '胆经', '合'], ['中渚', '三焦经', '纳三焦']],
  [['少冲', '心经', '井'], ['大都', '脾经', '荥'], ['太渊', '肺经', '输'], ['复溜', '肾经', '经'], ['曲泉', '肝经', '合'], ['大陵', '心包经', '纳包络']],
  [['厉兑', '胃经', '井'], ['二间', '大肠经', '荥'], ['束骨', '膀胱经', '输'], ['阳辅', '胆经', '经'], ['小海', '小肠经', '合'], ['支沟', '三焦经', '纳三焦']],
  [['隐白', '脾经', '井'], ['鱼际', '肺经', '荥'], ['太溪', '肾经', '输'], ['中封', '肝经', '经'], ['少海', '心经', '合'], ['间使', '心包经', '纳包络']],
  [['商阳', '大肠经', '井'], ['通谷', '膀胱经', '荥'], ['临泣', '胆经', '输'], ['阳谷', '小肠经', '经'], ['足三里', '胃经', '合'], ['天井', '三焦经', '纳三焦']],
  [['少商', '肺经', '井'], ['然谷', '肾经', '荥'], ['太冲', '肝经', '输'], ['灵道', '心经', '经'], ['阴陵泉', '脾经', '合'], ['曲泽', '心包经', '纳包络']],
  [['至阴', '膀胱经', '井'], ['侠溪', '胆经', '荥'], ['后溪', '小肠经', '输'], ['解溪', '胃经', '经'], ['曲池', '大肠经', '合'], ['关冲', '三焦经', '纳三焦']],
  [['涌泉', '肾经', '井'], ['行间', '肝经', '荥'], ['神门', '心经', '输'], ['商丘', '脾经', '经'], ['尺泽', '肺经', '合'], ['中冲', '心包经', '纳包络']],
];

/// 日干 → 原穴（返本还原用）
const Map<int, String> _ganYuan = {
  0: '丘墟', 1: '太冲', 2: '腕骨', 3: '神门', 4: '冲阳',
  5: '太白', 6: '合谷', 7: '太渊', 8: '京骨', 9: '太溪',
};

/// 纳甲取穴总表：键 "日干,时干,时支" → {point, meridian, type, yuan}
final Map<String, Map<String, String?>> _najiaMap = _buildNajiaMap();

Map<String, Map<String, String?>> _buildNajiaMap() {
  final map = <String, Map<String, String?>>{};
  const z0 = [10, 9, 8, 7, 6, 5, 4, 3, 2, 11];
  for (int r = 0; r < 10; r++) {
    final startH = _mod(2 * z0[r] - 1, 24);
    for (int i = 0; i < 6; i++) {
      final z = _mod(z0[r] + 2 * i, 12);
      final g = _mod(r + 2 * i, 10);
      final clock = _mod(startH + 4 * i, 24);
      final dayG = (clock >= 23 || clock < startH) ? _mod(r + 1, 10) : r;
      final pt = _najiaPoints[r][i];
      map['$dayG,$g,$z'] = {
        'point': pt[0],
        'meridian': pt[1],
        'type': pt[2],
        'yuan': pt[2] == '输' ? _ganYuan[r] : null,
      };
    }
  }
  return map;
}

/// 纳甲法正开穴。无则返回 null。
Map<String, String?>? najiaOpen(int dayGan, int hourGan, int hourZhi) =>
    _najiaMap['${_mod(dayGan, 10)},${_mod(hourGan, 10)},${_mod(hourZhi, 12)}'];

/// 合日互用：本日此时无正开穴时，取日干+5（合日）之穴。
Map<String, String?>? najiaHeRi(int dayGan, int hourGan, int hourZhi) =>
    _najiaMap['${_mod(dayGan + 5, 10)},${_mod(hourGan, 10)},${_mod(hourZhi, 12)}'];

// ───────────────────────── 灵龟八法 ─────────────────────────

const Map<int, int> _lgDayGan = {0: 10, 1: 9, 3: 8, 4: 7, 2: 7, 5: 10, 6: 9, 8: 8, 9: 7, 7: 7};
const Map<int, int> _lgDayZhi = {0: 7, 1: 10, 2: 8, 3: 8, 4: 10, 5: 7, 6: 7, 7: 10, 8: 9, 9: 9, 10: 10, 11: 7};
const Map<int, int> _lgHourGan = {0: 9, 1: 8, 2: 7, 3: 6, 4: 5, 5: 9, 6: 8, 7: 7, 8: 6, 9: 5};
const Map<int, int> _lgHourZhi = {0: 9, 1: 8, 2: 7, 3: 6, 4: 5, 5: 4, 6: 9, 7: 8, 8: 7, 9: 6, 10: 5, 11: 4};

/// 余数 → [卦, 主穴, 脉]
const Map<int, List<String>> _lgGua = {
  1: ['坎', '申脉', '阳跷'],
  2: ['坤', '照海', '阴跷'],
  3: ['震', '外关', '阳维'],
  4: ['巽', '临泣', '带脉'],
  5: ['坤', '照海', '阴跷'],
  6: ['乾', '公孙', '冲脉'],
  7: ['兑', '后溪', '督脉'],
  8: ['艮', '内关', '阴维'],
  9: ['离', '列缺', '任脉'],
};

/// 主穴 ↔ 配穴（对称）
const Map<String, String> _lgPeidui = {
  '公孙': '内关', '内关': '公孙',
  '后溪': '申脉', '申脉': '后溪',
  '临泣': '外关', '外关': '临泣',
  '列缺': '照海', '照海': '列缺',
};

/// 穴名 → 所属脉（由 _lgGua 推导，等价于 ziwu 的 LG_PEIDUI_MAI）
final Map<String, String> _xueMai = {
  for (final g in _lgGua.values) g[1]: g[2],
};

/// 灵龟八法开穴。
///
/// [dayGan]/[dayZhi] 为日干支（0-9 / 0-11），[hourGan]/[hourZhi] 为时干支。
/// [fiveMode]：'center' 中宫寄坤（余数5→照海，默认）；'gender' 按性别寄（男坤女艮）。
Map<String, dynamic> lingguiOpen(
  int dayGan,
  int dayZhi,
  int hourGan,
  int hourZhi, {
  String fiveMode = 'center',
  String sex = 'male',
}) {
  final dG = _mod(dayGan, 10);
  final dZ = _mod(dayZhi, 12);
  final dayBase = (_lgDayGan[dG] ?? 0) + (_lgDayZhi[dZ] ?? 0);
  final hourBase = (_lgHourGan[_mod(hourGan, 10)] ?? 0) + (_lgHourZhi[_mod(hourZhi, 12)] ?? 0);
  final sum = dayBase + hourBase;
  final yangDay = dG % 2 == 0;
  final div = yangDay ? 9 : 6;
  int rem = sum % div;
  if (rem == 0) rem = div;

  int effectiveRem = rem;
  String note = '';
  if (rem == 5) {
    if (fiveMode == 'gender') {
      if (sex == 'female') {
        effectiveRem = 8;
        note = '余数5：按「女寄艮」处理，取内关。';
      } else {
        effectiveRem = 2;
        note = '余数5：按「男寄坤」处理，取照海。';
      }
    } else {
      effectiveRem = 2;
      note = '余数5：按「中宫寄坤」处理，取照海。';
    }
  }

  final gua = _lgGua[effectiveRem]!;
  final peidui = _lgPeidui[gua[1]]!;
  final peiduiMai = _xueMai[peidui] ?? '';
  final step = '日基数（${_gan[dG]}=${_lgDayGan[dG]} + ${_zhi[dZ]}=${_lgDayZhi[dZ]}）＝$dayBase；'
      '时基数（${_gan[_mod(hourGan, 10)]}=${_lgHourGan[_mod(hourGan, 10)]} + ${_zhi[_mod(hourZhi, 12)]}=${_lgHourZhi[_mod(hourZhi, 12)]}）＝$hourBase；'
      '和＝$sum；${yangDay ? '阳日' : '阴日'} ÷ $div 余 $rem';

  return {
    'dayBase': dayBase,
    'hourBase': hourBase,
    'sum': sum,
    'div': div,
    'rem': rem,
    'effectiveRem': effectiveRem,
    'gua': gua, // [卦, 主穴, 脉]
    'peidui': peidui,
    'peiduiMai': peiduiMai,
    'yangDay': yangDay,
    'note': note,
    'step': step,
  };
}

// ───────────────────────── 飞腾八法 ─────────────────────────

/// 时干 → [卦, 穴]
const Map<int, List<String>> _feiteng = {
  0: ['乾', '公孙'], 8: ['乾', '公孙'],
  1: ['坤', '申脉'], 9: ['坤', '申脉'],
  2: ['艮', '内关'], 3: ['兑', '照海'],
  4: ['坎', '临泣'], 5: ['离', '列缺'],
  6: ['震', '外关'], 7: ['巽', '后溪'],
};

/// 飞腾八法：按时干取单穴。无对应时返回 null。
List<String>? feitengOpen(int hourGan) => _feiteng[_mod(hourGan, 10)];

// ───────────────────────── 干支推算 ─────────────────────────

/// ⓪ 干支唯一真相源 = App 八字核心 `bazi_core`（与八字排盘/农历/紫微同口径）。
///
/// ⛔ 禁止再自维护干支锚点！此处曾硬编码「2000-01-01 = 庚辰日」，
/// 而真实为**戊午日**（差 22 天）→ 日干支系统性错误 → 纳甲/灵龟/飞腾全盘算错。
/// 现在统一由 bazi_core 排盘取日柱，口径自动与八字模块对齐。
///
/// ⛔ 子时口径固定为「**23:00 换日**」（`RatHourMode.noSplit`），与参考站
/// acuherb.xyz/ziwu「日以子时（23:00）起算」一致，UI 上不再提供早晚子时开关。
///
/// ⚠️ 这与 App **八字排盘**的晚子时口径（23:00 后日柱归当日、时柱借次日）不同，
/// 是取穴模块的刻意选择：子午流注排十二时辰以子时为一日之始。
/// 若将来要对齐八字口径，改这里一处即可，勿在 UI 层各 Tab 分散判断。
///
/// 真太阳时开启时，由引擎内部保证「先校正真太阳时、再判子时」的顺序。
({int dayGan, int dayZhi}) calcDayGanZhi(
  DateTime dt, {
  double longitude = 120,
  double latitude = 30,
  bool useTrueSolarTime = false,
}) {
  final chart = bazi.BaziChart.createBySolarDate(
    clockTime:
        bazi.AstroDateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute),
    location: Location(longitude, latitude),
    ratHourMode: RatHourMode.noSplit,
    useTrueSolarTime: useTrueSolarTime,
    gender: Gender.male,
  );
  final d = chart.bazi.day;
  return (dayGan: d.gan.index, dayZhi: d.zhi.index);
}

/// 由日干支 + 时间推算时干支索引（子时=0）。
({int hourGan, int hourZhi}) calcHourGanZhi(int dayGan, int hour, int minute) {
  final minutes = hour * 60 + minute;
  int zhi;
  if (minutes >= 1380 || minutes < 60) {
    zhi = 0; // 子 23:00–01:00
  } else if (minutes < 180) {
    zhi = 1;
  } else if (minutes < 300) {
    zhi = 2;
  } else if (minutes < 420) {
    zhi = 3;
  } else if (minutes < 540) {
    zhi = 4;
  } else if (minutes < 660) {
    zhi = 5;
  } else if (minutes < 780) {
    zhi = 6;
  } else if (minutes < 900) {
    zhi = 7;
  } else if (minutes < 1020) {
    zhi = 8;
  } else if (minutes < 1140) {
    zhi = 9;
  } else if (minutes < 1260) {
    zhi = 10;
  } else {
    zhi = 11;
  }
  // 子时起始时干 = 日干×2（甲己日起甲子时 …）
  final ziGan = _mod(dayGan * 2, 10);
  final hourGan = _mod(ziGan + zhi, 10);
  return (hourGan: hourGan, hourZhi: zhi);
}
