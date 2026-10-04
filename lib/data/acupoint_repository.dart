import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/acupoint_detail.dart';
import 'meridian_order.dart';

class AcupointRepository {
  static List<AcupointDetail> _acupoints = [];
  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final jsonStr = await rootBundle.loadString('assets/data/acupoints.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final list = data['acupoints'] as List<dynamic>? ?? const [];
      _acupoints = list
          .map((e) => AcupointDetail.fromJson(e as Map<String, dynamic>))
          .toList();
      _sortByMeridianOrder();
    } catch (e, st) {
      debugPrint('[AcupointRepository] 加载 acupoints.json 失败，降级为空：$e\n$st');
      _acupoints = const [];
    }
    _loaded = true;
  }

  /// 按「经络循行顺序」重排全表（**稳定排序**）。
  ///
  /// 三级键，依次比较：
  /// 1. 经络顺序 [meridianOrderIndex]（手太阴肺经 → … → 足厥阴肝经 → 督脉 → 任脉 → 经外奇穴）；
  /// 2. 同一经络内部的**国标穴序** [pointOrderIndex]（中府 → 云门 → 天府 → …）；
  /// 3. 原始物理下标 —— [List.sort] **不保证稳定**，必须显式兜底，否则组内次序会随机漂移。
  ///
  /// 表外穴位（督脉 / 任脉 / 经外奇穴 内部，以及八髎穴这类临床组合穴）取
  /// [kUnknownPointOrderIndex]，按第 3 级键退化为「保持原物理顺序」，一条都不丢。
  static void _sortByMeridianOrder() {
    final decorated = <({int meridian, int point, int original})>[
      for (var i = 0; i < _acupoints.length; i++)
        (
          meridian: meridianOrderIndex(_acupoints[i].meridian),
          point: pointOrderIndex(_acupoints[i].meridian, _acupoints[i].name),
          original: i,
        ),
    ];
    decorated.sort((a, b) {
      final byMeridian = a.meridian.compareTo(b.meridian);
      if (byMeridian != 0) return byMeridian;
      final byPoint = a.point.compareTo(b.point);
      if (byPoint != 0) return byPoint;
      return a.original.compareTo(b.original); // 稳定兜底
    });
    _acupoints = [for (final k in decorated) _acupoints[k.original]];
  }

  static List<AcupointDetail> getAll() => _acupoints;

  static AcupointDetail? findByName(String name) {
    // 精确匹配
    for (final a in _acupoints) {
      if (a.name == name) return a;
    }
    // 去掉"穴"后缀再匹配（如"关元"匹配"关元穴"）
    final stripped = name.replaceAll('穴', '');
    for (final a in _acupoints) {
      if (a.name.replaceAll('穴', '') == stripped) return a;
    }
    return null;
  }

  /// 别名/错字归一：将处方或临床心悟里出现的异名、错字映射回本库正名。
  /// 铁律：若 name 已是本库正名（findByName 命中），原样返回，
  /// 以避免误改处方方向A自身的关联（遵循神农本草经修复纪律）。
  static String canonicalOf(String name) {
    if (findByName(name) != null) return name; // 已是正名
    final stripped = name.replaceAll('穴', '');
    if (findByName(stripped) != null) return stripped; // 去后缀即正名
    final canon = _aliasMap[name] ?? _aliasMap[stripped];
    if (canon != null && findByName(canon) != null) return canon;
    return name;
  }

  /// 处方错字 → 正名（仅收录确属错字、且正名已在本库的条目）。
  static const Map<String, String> _aliasMap = {
    '中阳': '中脘', // 「中阳」为「中脘」之误，胃痛/急性胃痛主穴
  };

  /// 会撞普通词的 2 字短名 → 实际参与自动链接的形态（加「穴」后缀变 3 字）。
  ///
  /// 实测依据：库里 `name` 本身就是 2 字的「子宫」，在讲稿里命中 19 处 —— 其中
  /// **17 处是解剖语**（"引起子宫收缩"、"女人子宫卵巢有肿瘤"、"灸百会治子宫下垂"）属误链，
  /// 另 **2 处写的是 3 字「子宫穴」**属正当引用（"倪师：子宫穴在中极旁开三寸"）。
  /// 所以候选表里只放 **3 字形态**：解剖语那 17 处自然匹配不上（原文没有「子宫穴」），
  /// 正当那 2 处照常命中 —— **零正当链接损失**。
  ///
  /// ⚠️ 用 Map 而非 Set：本条目的 `name` 恰是那个 2 字短名，若只做"排除"再回退到
  /// `a.name`，等于把 2 字形态又塞回候选表（曾因此修复失效，由测试抓出）。
  ///
  /// ⛔ 不要往这里加「肾关」「肘尖」这类**本名即 2 字、且讲义里反复引用**的穴位：
  /// "肾关在小腿内侧、阴陵泉下面两寸…它是董氏奇穴里面的要穴"、"灸肘尖百壮，瘰疬自消" ——
  /// 名字没错、错的是语境，这类只能靠中文分词边界解决，禁名字会砸掉真链接。
  static const Map<String, String> kShortNameLinkForm = {
    '子宫': '子宫穴',
  };

  /// 全部穴位名（去掉"穴"后缀），按长度降序，供详情页解析临床心悟中的处方组成。
  static List<String> get allNames => _allNamesCache ??= _buildAllNames();

  static List<String>? _allNamesCache;

  static List<String> _buildAllNames() {
    final set = <String>{};
    for (final a in _acupoints) {
      final stripped = a.name.replaceAll('穴', '');
      // 短名会撞普通词时（见 kShortNameLinkForm），改用不会撞的形态参与匹配。
      set.add(kShortNameLinkForm[stripped] ?? stripped);
    }
    final list = set.toList();
    // 最长优先，避免子串误配；同长度按名称字典序兜底 —— List.sort 不稳定，
    // 不给次键的话并列项的先后会退化成「_acupoints 的插入顺序」，
    // 而 _acupoints 的顺序一变（如按经络重排），贪心扫描就会选错穴位。
    list.sort((a, b) {
      final byLen = b.length.compareTo(a.length);
      return byLen != 0 ? byLen : a.compareTo(b);
    });
    return list;
  }

  static List<AcupointDetail> search(String query) {
    if (query.isEmpty) return _acupoints;
    final q = query.toLowerCase();
    return _acupoints.where((a) {
      if (a.name.toLowerCase().contains(q) ||
          a.meridian.toLowerCase().contains(q) ||
          a.description.toLowerCase().contains(q) ||
          a.location.toLowerCase().contains(q) ||
          a.clinicalNotes.toLowerCase().contains(q)) {
        return true;
      }
      // 次键 meridians：按奇经名搜索也能命中其交会穴（多脉穴忠实出现在所有所属脉，
      // 与 getByMeridian 的分组口径保持一致，不把多脉穴压缩成单脉）。
      final meridians = a.meridians;
      if (meridians != null) {
        for (final m in meridians) {
          if (m.toLowerCase().contains(q)) return true;
        }
      }
      return false;
    }).toList();
  }

  static List<String> getMeridians() {
    final set = <String>{};
    for (final a in _acupoints) {
      if (a.meridian.isNotEmpty) set.add(a.meridian);
      if (a.meridians != null) set.addAll(a.meridians!);
    }
    // 按经络循行顺序排列（表外经络排最后），与 getAll() 的列表顺序保持一致。
    // ⛔ 不用字典序：筛选 chip 的顺序必须和讲解列表一致。
    final list = set.toList()
      ..sort((a, b) {
        final byMeridian = meridianOrderIndex(a).compareTo(meridianOrderIndex(b));
        if (byMeridian != 0) return byMeridian;
        return a.compareTo(b); // 同为表外经络时按名排序，保证结果确定
      });
    return list;
  }

  static List<AcupointDetail> getByMeridian(String meridian) {
    if (meridian == '全部') return _acupoints;
    return _acupoints
        .where((a) =>
            a.meridian == meridian ||
            (a.meridians?.contains(meridian) ?? false))
        .toList();
  }

  static int get count => _acupoints.length;
}
