import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/herb.dart';

class HerbRepository {
  static List<Herb> _herbs = [];
  static bool _loaded = false;

  // 方剂组成/别名 → 神农本草经正名（herbs.json 中的 canonical name）。
  // 只收录「本身不是药库条目的异名/炮制品」，避免把已直接命中的药（如桂枝、白芍）
  // 误指到古名而断开其自身的「含此药的方剂」关联。
  static const _canonicalOf = {
    // —— 炮制成分类（组成用炮制品，药库存生品/正名）——
    // 注：炙甘草 已升为药库独立条目（herbs.json），不再归一于甘草；
    //     生甘草仍为甘草之生用别名，保留归一。
    '生甘草': '甘草',
    // 附子 = 生附子 = 大附子（生品，本经「附子」条即生附子，凡不注炮者即生用）；
    // 炮附子 = 炒附子 = 熟附子 = 制附子（火炮/炮制品）。
    // 生附子、炮附子 各为独立药材条目（回阳救逆 vs 固表温阳，不可互代），
    // getByName 精确命中自身；以下只登记「非独立条目的异名写法」。
    '附子': '生附子',
    '大附子': '生附子',
    '炒附子': '炮附子',
    '熟附子': '炮附子',
    '制附子': '炮附子',
    '炮姜': '干姜',
    '生半夏': '半夏',
    '生葛': '葛根',
    '生竹茹': '竹茹',
    '生姜汁': '生姜',
    '生地黄汁': '生地黄',
    '地黄': '干地黄',
    '熟地': '熟地黄',
    '生地': '干地黄',
    '麻仁': '麻子仁',
    // —— 异名/古名 → 正名（键名本身不在药库中）——
    '丹皮': '牡丹',
    '牡丹皮': '牡丹',
    '山药': '署豫',
    '薯蓣': '署豫',
    '怀山': '署豫',
    '橘皮': '陈皮',
    '红枣': '大枣',
    '栝蒌实': '栝楼实',
    '栝蒌根': '天花粉',
    '芎䓖': '川芎',
    '香豉': '豆豉',
    '茵陈蒿': '茵陈',
    '木防己': '防己',
    '硝石': '消石',
    '赤硝': '芒硝',
    '土瓜根': '王瓜',
    '葱白': '葱实',
    '葱': '葱实',
    '戎盐': '青盐',
    '川椒': '蜀椒',
    '柏叶': '柏叶（侧柏叶）',
    '败酱草': '败酱',
    '诃黎勒': '诃黎勒（诃子）',
    '乌扇': '射干',
    '蜂窝': '露蜂房',
    '白鱼': '衣鱼',
    '葵子': '冬葵子',
    '瓜子': '白瓜子',
    '商陆根': '商陆',
    '寒水石': '凝水石',
    '杏子': '杏仁',
    '鹿角胶': '白胶',
    '野菊花': '菊花',
    '朱砂': '丹砂',
    '冬花': '款冬花',
    '生硫磺': '石硫黄',
    '银花': '金银花',
    '川红花': '红花',
    '败龟板': '龟甲',
    '辛夷花': '辛夷',
    '麻油': '胡麻',
    '矾石（明矾）': '矾石',
    '连轺': '连翘',
    '生梓白皮': '梓白皮',
    '葳蕤': '女萎',
    '猪胆汁': '猪胆',
    '乱发': '发髲',
    '冬瓜仁': '白瓜子',
    '虻虫': '蜚虻',
    '食蜜': '石蜜',
    '白蜜': '石蜜',
    '蜜': '石蜜',
    '粉': '粉钖',
    '蒴藋细叶': '蒴翟',
    '桑东南根白皮': '桑根白皮',
    '盐': '卤咸',
    // —— 其余异名/别名（键名本身不在药库）——
    // 注：猪肤已升为药库独立条目（herbs.json，猪肤＝猪皮），不再归一于「猪胆、猪肤」 merged 名；
    //     猪胆汁→猪胆（见上）；猪胆/猪肤各为独立药材条目。
    '红蓝花': '红花',
    '豆黄卷': '大豆黄卷',
    '白蔹': '白敛',
    '诃梨勒': '诃黎勒（诃子）',
    '天麻': '赤箭',
    '茜草': '茜根',
    '荆芥': '假苏',
    '天南星': '虎掌',
    '玉竹': '女萎',
    '桂心': '肉桂',
    '桑寄生': '桑上寄生',
    // —— 同药异名归并（A 组修复：本经名/古名/错别字 → 今用正名）——
    '茈胡': '柴胡',
    '芎穷': '川芎',
    '旋华': '旋覆花',
    '檗木': '黄柏',
    '桑蜱蛸': '桑螵蛸',
    '瓜篓根': '天花粉',
    '白颈蚯蚓': '地龙',
    '雀瓮': '蝉蜕',
    '桃核仁': '桃仁',
    '杏核仁': '杏仁',
    '牙子': '狼牙',
    '青蘘': '胡麻',
    '姑活': '冬葵子',
    '牡桂': '肉桂',
    '菌桂': '肉桂',
    '栝楼根': '天花粉',
  };

  static Future<void> load() async {
    if (_loaded) return;
    final data = await rootBundle.loadString('assets/data/herbs.json');
    final map = json.decode(data) as Map<String, dynamic>;
    final list = map['herbs'] as List<dynamic>;
    _herbs = list.map((e) => Herb.fromJson(e as Map<String, dynamic>)).toList();
    _loaded = true;
  }

  /// 将方剂组成名/别名归一到药库正名；若无需归一则返回原名。
  static String canonicalOf(String name) => _canonicalOf[name] ?? name;

  /// 药材别名/炮制品名（_canonicalOf 键集合），供医案药材索引候选使用。
  /// 例：炙甘草、生甘草、炮姜、山药、丹皮……本身不是药库条目的写法。
  static List<String> get aliasNames => _canonicalOf.keys.toList();

  static List<Herb> getAll() => List.unmodifiable(_herbs);

  static List<Herb> getByCategory(String category) {
    if (category == '全部') return getAll();
    return _herbs.where((h) => h.category == category).toList();
  }

  /// 药材是否命中查询词，**含异名归一**。
  ///
  /// 这是全项目药材检索的唯一入口 —— 页面禁止再自行写 `h.name.contains(...)`。
  /// 背景：`_canonicalOf` 是异名的唯一来源，若各页面自己拼字符串匹配，新增/调整
  /// 异名映射时页面不会同步，就会出现「异名搜不到」（如 茈胡 搜不到 柴胡）。
  /// 历史上 knowledge_screen 与 search_tab 各自复制了一份匹配逻辑且都漏了归一，
  /// 导致 103 个异名中 74 / 87 个失效。修复方式是收敛到本方法，而非各处打补丁。
  static bool matchesQuery(Herb h, String query) {
    if (query.isEmpty) return false;
    final q = query.toLowerCase();
    final cq = canonicalOf(query).toLowerCase();
    return h.name.toLowerCase().contains(q) ||
        h.name.toLowerCase().contains(cq) ||
        (h.action ?? '').toLowerCase().contains(q) ||
        (h.nature ?? '').toLowerCase().contains(q) ||
        (h.original ?? '').toLowerCase().contains(q) ||
        h.flavor.toLowerCase().contains(q) ||
        h.category.toLowerCase().contains(q) ||
        h.meridians.any((m) => m.toLowerCase().contains(q));
  }

  static List<Herb> search(String query) {
    if (query.isEmpty) return [];
    return _herbs.where((h) => matchesQuery(h, query)).toList();
  }

  /// 只做「正名精确命中 + 别名归一」，不做模糊兜底。
  /// 用于「这个词到底是不是一味药」的判定（如闭门课标签既可能是方剂也可能是单味药，
  /// 模糊兜底会把「柴胡」误判成含柴胡的方剂）。
  static Herb? getExactByName(String name) {
    for (final h in _herbs) {
      if (h.name == name) return h;
    }
    final mapped = _canonicalOf[name];
    if (mapped != null) {
      for (final h in _herbs) {
        if (h.name == mapped) return h;
      }
    }
    return null;
  }

  static Herb? getByName(String name) {
    // 先直接匹配 + 别名归一
    final exact = getExactByName(name);
    if (exact != null) return exact;
    // 模糊匹配
    for (final h in _herbs) {
      if (h.name.contains(name) || name.contains(h.name)) {
        return h;
      }
    }
    return null;
  }

  static List<String> getCategories() {
    final cats = _herbs.map((h) => h.category).toSet().toList();
    cats.sort();
    return ['全部', ...cats];
  }

  static List<String> getNatureCategories() {
    return ['全部', '寒', '凉', '平', '温', '热'];
  }

  static List<Herb> getByNature(String nature) {
    if (nature == '全部') return getAll();
    return _herbs.where((h) => h.natureCategory == nature).toList();
  }
}
