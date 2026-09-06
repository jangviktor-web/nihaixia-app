/// 小儿关煞判定引擎。
///
/// 输入复用项目既有八字引擎 [computeBaZiPaipan] 产出的 [BaZiPaipan]，
/// 提取四柱地支 / 天干 / 年柱纳音五行后，按归一化 [GuanshaRuleKind] 逐条判定
/// 儿童生辰犯哪些关煞，并按「重关 > 中关 > 轻关」排序返回。
///
/// 内容属传统民俗文化参考，非医学或命理定论。
library;

import 'package:nihaisha_app/services/bazi_service.dart'
    show BaZiPaipan, nayinOfPillar;
import 'package:nihaisha_app/data/guansha_data.dart'
    show GuanshaEntry, GuanshaRule, GuanshaRuleKind, kGuanshaEntries, kExtShaEntries;

/// 单条命中结果。
class GuanshaHit {
  final GuanshaEntry entry;
  final String reason; // 判定原因（可读说明）
  const GuanshaHit({required this.entry, required this.reason});
}

/// 月支 → 季节。
const Map<String, String> _zhiToSeason = {
  '寅': '春', '卯': '春', '辰': '春',
  '巳': '夏', '午': '夏', '未': '夏',
  '申': '秋', '酉': '秋', '戌': '秋',
  '亥': '冬', '子': '冬', '丑': '冬',
};

/// 月支 → 农历月序（寅=1 … 丑=12），用于多厄关按出生月份判定。
const Map<String, int> _zhiToMonthIndex = {
  '寅': 1, '卯': 2, '辰': 3, '巳': 4, '午': 5, '未': 6,
  '申': 7, '酉': 8, '戌': 9, '亥': 10, '子': 11, '丑': 12,
};

/// 取年柱纳音五行（如「金箔金」→「金」）。
String _nayinElement(String yearPillar) {
  final n = nayinOfPillar(yearPillar);
  return n.isNotEmpty ? n[n.length - 1] : '';
}

int _severityRank(String severity) => switch (severity) {
      '重关' => 0,
      '中关' => 1,
      '轻关' => 2,
      _ => 3,
    };

/// 判定单个关煞是否命中，命中时返回可读原因，否则返回 null。
String? _matchOne(GuanshaEntry e, _Ctx c) {
  final r = e.rule;
  switch (r.kind) {
    case GuanshaRuleKind.yearZhiShiZhi:
      for (final key in r.table.keys) {
        if (key.contains(c.yearZhi) && r.table[key]!.contains(c.timeZhi)) {
          return '年支「${c.yearZhi}」属「$key」组，时支「${c.timeZhi}」犯（该组忌时支 ${r.table[key]!.join('、')}）';
        }
      }
      return null;
    case GuanshaRuleKind.monthZhiShiZhiSeason:
      final list = r.table[c.monthSeason];
      if (list != null && list.contains(c.timeZhi)) {
        return '月支「${c.monthZhi}」属${c.monthSeason}，时支「${c.timeZhi}」犯（${c.monthSeason}季忌时支 ${list.join('、')}）';
      }
      return null;
    case GuanshaRuleKind.monthZhiShiZhi:
      final list = r.table[c.monthZhi];
      if (list != null && list.contains(c.timeZhi)) {
        return '月支「${c.monthZhi}」逢时支「${c.timeZhi}」犯（该月支忌时支 ${list.join('、')}）';
      }
      return null;
    case GuanshaRuleKind.ganShiZhi:
      for (final key in r.table.keys) {
        if ((key.contains(c.dayGan) || key.contains(c.yearGan)) &&
            r.table[key]!.contains(c.timeZhi)) {
          final which = key.contains(c.dayGan) ? '日干${c.dayGan}' : '年干${c.yearGan}';
          return '$which属「$key」组，时支「${c.timeZhi}」犯（该组忌时支 ${r.table[key]!.join('、')}）';
        }
      }
      return null;
    case GuanshaRuleKind.nayinShiZhi:
      for (final key in r.table.keys) {
        if (key.contains(c.yearNayinEl) && r.table[key]!.contains(c.timeZhi)) {
          return '年柱纳音${c.yearNayinEl}命，时支「${c.timeZhi}」犯（${c.yearNayinEl}命忌时支 ${r.table[key]!.join('、')}）';
        }
      }
      return null;
    case GuanshaRuleKind.sanHeJu:
      // 依据数据集核对版「查询示例」金标准：时支临该三合局煞位即犯。
      // 注：数据集原文有「时支或其余三支」之泛述，但同版查询示例明确
      // 壬寅/辛亥/壬申/乙巳 仅犯 {将军箭,和尚关,撞命关,断肠关}，
      // 劫煞/咸池等 32 种均不犯——故以时支为判定基准，避免月支亥误中劫煞。
      for (final key in r.table.keys) {
        final basisOk = key.contains(c.yearZhi) ||
            (r.useDayZhi && key.contains(c.dayZhi));
        if (basisOk && r.table[key]!.contains(c.timeZhi)) {
          return '${c.yearZhi}支入「$key」三合局，时支「${c.timeZhi}」临该局煞位';
        }
      }
      return null;
    case GuanshaRuleKind.tongziComposite:
      final conds = r.tongzi ?? [];
      for (var i = 0; i < conds.length; i++) {
        final cond = conds[i];
        final seasonOk =
            cond.seasonIn == null || cond.seasonIn!.contains(c.monthSeason);
        final nayinOk =
            cond.nayinIn == null || cond.nayinIn!.contains(c.yearNayinEl);
        final zhiOk =
            cond.zhiIn.contains(c.dayZhi) || cond.zhiIn.contains(c.timeZhi);
        if (seasonOk && nayinOk && zhiOk) {
          final trigger = cond.seasonIn != null
              ? '${cond.seasonIn!.join('/')}月令'
              : (cond.nayinIn != null ? '${cond.nayinIn!.join('/')}命纳音' : '');
          return '童子关：满足第${i + 1}条件（${trigger.isNotEmpty ? '$trigger，' : ''}日/时支见${cond.zhiIn.join('、')}）';
        }
      }
      return null;
    case GuanshaRuleKind.duoEComposite:
      final genderKey = c.isMale ? '男' : '女';
      final map = r.duoE?[genderKey];
      if (map == null) return null;
      final monthIdx = _zhiToMonthIndex[c.monthZhi];
      final list = map[c.yearNayinEl];
      if (monthIdx != null && list != null && list.contains(monthIdx)) {
        final gender = c.isMale ? '男' : '女';
        return '多厄关：$gender命${c.yearNayinEl}命，生于农历$monthIdx月犯（该命月序忌 ${list.join('、')}）';
      }
      return null;
  }
}

/// 内部上下文，避免逐条重复解析四柱。
class _Ctx {
  final String yearZhi;
  final String monthZhi;
  final String dayZhi;
  final String timeZhi;
  final String dayGan;
  final String yearGan;
  final String monthSeason;
  final String yearNayinEl;
  final bool isMale;
  const _Ctx({
    required this.yearZhi,
    required this.monthZhi,
    required this.dayZhi,
    required this.timeZhi,
    required this.dayGan,
    required this.yearGan,
    required this.monthSeason,
    required this.yearNayinEl,
    required this.isMale,
  });
}

/// 测算儿童生辰所犯关煞。
///
/// [p] 为 [computeBaZiPaipan] 产物；[isMale] 性别，用于多厄关分男女判定。
/// 返回按严重程度（重 > 中 > 轻）升序排列的命中列表；未命中返回空列表。
List<GuanshaHit> matchGuansha(BaZiPaipan p, bool isMale) {
  final zhis = p.zhis; // [年支, 月支, 日支, 时支]
  final gans = p.gans; // [年干, 月干, 日干, 时干]
  final ctx = _Ctx(
    yearZhi: zhis[0],
    monthZhi: zhis[1],
    dayZhi: zhis[2],
    timeZhi: zhis[3],
    dayGan: gans[2],
    yearGan: gans[0],
    monthSeason: _zhiToSeason[zhis[1]] ?? '',
    yearNayinEl: _nayinElement(p.bazi.year),
    isMale: isMale,
  );

  final all = [...kGuanshaEntries, ...kExtShaEntries];
  final hits = <GuanshaHit>[];
  for (final e in all) {
    final reason = _matchOne(e, ctx);
    if (reason != null) hits.add(GuanshaHit(entry: e, reason: reason));
  }
  hits.sort((a, b) =>
      _severityRank(a.entry.severity).compareTo(_severityRank(b.entry.severity)));
  return hits;
}

/// 将归一化规则转为可读的「查法」说明，供百科详情展示。
String describeRule(GuanshaRule rule) {
  switch (rule.kind) {
    case GuanshaRuleKind.yearZhiShiZhi:
      final parts = rule.table.entries
          .map((e) => '年支${e.key}逢时支${e.value.join('、')}')
          .join('；');
      return '年支见时支：$parts';
    case GuanshaRuleKind.monthZhiShiZhiSeason:
      final parts = rule.table.entries
          .map((e) => '${e.key}季逢时支${e.value.join('、')}')
          .join('；');
      return '月支（四季）见时支：$parts';
    case GuanshaRuleKind.monthZhiShiZhi:
      final parts = rule.table.entries
          .map((e) => '月支${e.key}逢时支${e.value.join('、')}')
          .join('；');
      return '月支见时支：$parts';
    case GuanshaRuleKind.ganShiZhi:
      final parts = rule.table.entries
          .map((e) => '日干或年干${e.key}逢时支${e.value.join('、')}')
          .join('；');
      return '日干或年干见时支：$parts';
    case GuanshaRuleKind.nayinShiZhi:
      final parts = rule.table.entries
          .map((e) => '年柱纳音${e.key}命逢时支${e.value.join('、')}')
          .join('；');
      return '年柱纳音五行见时支：$parts';
    case GuanshaRuleKind.sanHeJu:
      final basis = rule.useDayZhi ? '年支或日支' : '年支';
      final parts = rule.table.entries
          .map((e) => '${e.key}局见时支${e.value.join('、')}')
          .join('；');
      return '三合局（$basis）见时支：$parts';
    case GuanshaRuleKind.tongziComposite:
      final conds = rule.tongzi ?? [];
      final lines = <String>[];
      for (var i = 0; i < conds.length; i++) {
        final c = conds[i];
        final trigger = c.seasonIn != null
            ? '${c.seasonIn!.join('/')}月令'
            : (c.nayinIn != null ? '${c.nayinIn!.join('/')}命纳音' : '');
        lines.add('条件${i + 1}：$trigger且日/时支见${c.zhiIn.join('、')}');
      }
      return '童子关综合查法（五条件满足任一即犯）：${lines.join('；')}';
    case GuanshaRuleKind.duoEComposite:
      final gender = rule.duoE ?? const {};
      final parts = <String>[];
      for (final g in ['男', '女']) {
        final m = gender[g];
        if (m == null) continue;
        final inner = m.entries
            .map((e) => '${e.key}命农历${e.value.join('、')}月')
            .join('，');
        parts.add('$g：$inner');
      }
      return '多厄关（纳音五行 + 农历月序，分男女）：${parts.join('；')}';
  }
}
