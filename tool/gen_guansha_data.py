# -*- coding: utf-8 -*-
"""生成 lib/data/guansha_data.dart。

读取《小儿关煞大全（36关+72煞扩展54条·核对版）.json》，
- 文本字段（名称/别名/口诀/犯者忌/化解/图示/类别/严重程度）原样转录自 JSON；
- GuanshaRule 归一化表由本脚本手工定义（见 RULES_36 / RULES_EXT），emit 成 Dart 字面量。

查法归一化为 8 种 rule kind（在任务给定的 7 种基础上，新增 monthZhiShiZhi
以覆盖「按月支（单支/月份）查时支」且非四季口径的关煞，如百日关/血刃关/四柱关等）：
  yearZhiShiZhi          年支集合 -> 时支列表
  monthZhiShiZhiSeason   春/夏/秋/冬 -> 时支列表
  monthZhiShiZhi         单月支 -> 时支列表（覆盖特定月份/月支组）
  ganShiZhi              干集合 -> 时支列表（日干或年干，视作「或」）
  nayinShiZhi            纳音五行 -> 时支列表（年柱纳音五行）
  sanHeJu                三合局 group -> target（时支须等于 target）
  tongziComposite        童子关五条件（满足任一即犯）
  duoEComposite          多厄关（纳音五行 + 农历月序，分男女）

版本分歧处理：只采用口诀/四季版主查法；聚宝楼简化版、李宪章版、月支版等并列
变体一律不收录（如阎王关、浴盆关、夜啼关、五鬼关、短命关、天吊关、水火关等）。
"""

import json
import os

SRC = r"D:/Users/jangviktor/Download/小儿关煞大全（36关+72煞扩展54条·核对版）.json"
OUT = os.path.join(os.path.dirname(__file__), "..", "lib", "data", "guansha_data.dart")

# ---------------------------------------------------------------------------
# 归一化规则表（手工定义）
# ---------------------------------------------------------------------------

# 36 关煞
RULES_36 = {
    "将军箭": {"kind": "monthZhiShiZhiSeason", "table": {
        "春": ["酉", "戌", "辰"], "夏": ["未", "卯", "子"],
        "秋": ["寅", "午", "丑"], "冬": ["亥", "申", "巳"]}},
    "阎王关": {"kind": "monthZhiShiZhiSeason", "table": {
        "春": ["丑", "未"], "夏": ["辰", "戌"],
        "秋": ["子", "午"], "冬": ["寅", "卯"]}},  # 口诀四季版；跳过聚宝楼简化版
    "取命关": {"kind": "ganShiZhi", "table": {
        "甲乙丙丁": ["申", "子", "辰"], "戊己庚": ["亥", "卯", "未"],
        "辛壬癸": ["寅", "午", "戌"]}},
    "深水关": {"kind": "monthZhiShiZhiSeason", "table": {
        "春": ["寅", "申"], "夏": ["未"], "秋": ["酉"], "冬": ["丑"]}},
    "百日关": {"kind": "monthZhiShiZhi", "table": {
        "寅": ["辰", "戌", "丑", "未"], "申": ["辰", "戌", "丑", "未"],
        "巳": ["辰", "戌", "丑", "未"], "亥": ["辰", "戌", "丑", "未"],
        "子": ["寅", "申", "巳", "亥"], "午": ["寅", "申", "巳", "亥"],
        "卯": ["寅", "申", "巳", "亥"], "酉": ["寅", "申", "巳", "亥"],
        "辰": ["子", "午", "卯", "酉"], "戌": ["子", "午", "卯", "酉"],
        "丑": ["子", "午", "卯", "酉"], "未": ["子", "午", "卯", "酉"]}},
    "血刃关": {"kind": "monthZhiShiZhi", "table": {
        "寅": ["丑"], "卯": ["未"], "辰": ["寅"], "巳": ["申"], "午": ["卯"],
        "未": ["酉"], "申": ["辰"], "酉": ["戌"], "戌": ["巳"], "亥": ["亥"],
        "子": ["午"], "丑": ["子"]}},
    "短命关": {"kind": "yearZhiShiZhi", "table": {
        "寅午戌": ["辰"], "巳酉丑": ["寅"], "申子辰": ["巳"], "亥卯未": ["未"]}},
    "千日关": {"kind": "ganShiZhi", "table": {
        "甲乙": ["午", "辰"], "丙丁": ["申", "酉"], "戊己": ["巳"],
        "庚辛": ["寅", "卯"], "壬癸": ["丑", "亥"]}},
    "落井关": {"kind": "ganShiZhi", "table": {
        "甲己": ["巳"], "乙庚": ["子"], "丙辛": ["申"], "丁壬": ["戌"], "戊癸": ["卯"]}},
    "天狗关": {"kind": "yearZhiShiZhi", "table": {
        "子": ["戌"], "丑": ["亥"], "寅": ["子"], "卯": ["丑"], "辰": ["寅"],
        "巳": ["卯"], "午": ["辰"], "未": ["巳"], "申": ["午"], "酉": ["未"],
        "戌": ["申"], "亥": ["酉"]}},
    "撞命关": {"kind": "yearZhiShiZhi", "table": {
        "子": ["巳"], "丑": ["未"], "寅": ["巳"], "卯": ["子"], "辰": ["午"],
        "巳": ["午"], "午": ["丑"], "未": ["丑"], "申": ["午"], "酉": ["酉"],
        "戌": ["未"], "亥": ["亥"]}},
    "埋儿关": {"kind": "yearZhiShiZhi", "table": {
        "子午卯酉": ["丑"], "寅申巳亥": ["申"], "辰戌丑未": ["卯"]}},
    "白虎关": {"kind": "nayinShiZhi", "table": {
        "火": ["子"], "金": ["卯"], "水土": ["午"], "木": ["酉"]}},
    "铁蛇关": {"kind": "nayinShiZhi", "table": {
        "金": ["戌", "亥"], "火": ["未", "申"], "木": ["辰", "巳"],
        "水土": ["丑", "寅"]}},
    "直难关": {"kind": "monthZhiShiZhi", "table": {
        "寅": ["午"], "卯": ["午"], "辰": ["未"], "巳": ["未"], "午": ["卯", "戌"],
        "未": ["卯", "戌"], "申": ["巳", "申"], "酉": ["巳", "申"], "戌": ["寅", "卯"],
        "亥": ["寅", "卯"], "子": ["辰", "酉"], "丑": ["辰", "酉"]}},
    "童子关": {"kind": "tongziComposite", "tongzi": [
        {"seasonIn": ["春", "秋"], "zhiIn": ["寅", "子"]},
        {"seasonIn": ["夏", "冬"], "zhiIn": ["卯", "未", "辰"]},
        {"nayinIn": ["金", "木"], "zhiIn": ["午", "卯"]},
        {"nayinIn": ["水", "火"], "zhiIn": ["酉", "戌"]},
        {"nayinIn": ["土"], "zhiIn": ["辰", "巳"]}]},
    "汤火关": {"kind": "yearZhiShiZhi", "table": {
        "子午卯酉": ["午"], "寅申巳亥": ["寅"], "辰戌丑未": ["未"]}},
    "夜啼关": {"kind": "yearZhiShiZhi", "table": {
        "子午卯酉": ["未"], "寅申巳亥": ["寅"], "辰戌丑未": ["酉"]}},  # 年支版；跳过月支版
    "五鬼关": {"kind": "yearZhiShiZhi", "table": {
        "子": ["辰"], "丑": ["卯"], "寅": ["寅"], "卯": ["丑"], "辰": ["子"],
        "巳": ["亥"], "午": ["戌"], "未": ["申"], "申": ["酉"], "酉": ["未"],
        "戌": ["午"], "亥": ["巳"]}},  # 年支逐年版；跳过通胜年柱干支版
    "鬼门关": {"kind": "yearZhiShiZhi", "table": {
        "子丑寅": ["酉", "午", "未"], "卯辰巳": ["申", "戌", "亥"],
        "午未申": ["丑", "寅", "卯"], "酉戌亥": ["子", "辰", "巳"]}},
    "和尚关": {"kind": "yearZhiShiZhi", "table": {
        "子午卯酉": ["辰", "戌", "丑", "未"], "辰戌丑未": ["子", "午", "卯", "酉"],
        "寅申巳亥": ["寅", "申", "巳", "亥"]}},
    "天吊关": {"kind": "yearZhiShiZhi", "table": {
        "寅午戌": ["辰"]}},  # 李宪章寅午戌辰时版
    "雷公关": {"kind": "ganShiZhi", "table": {
        "甲乙": ["丑", "午"], "丙丁": ["申"], "戊己": ["戌"],
        "庚辛": ["寅"], "壬癸": ["亥", "丑"]}},
    "鸡飞关": {"kind": "ganShiZhi", "table": {
        "甲己": ["巳", "酉", "丑"], "庚辛": ["亥", "卯", "未"],
        "壬癸": ["寅", "午", "戌"], "乙丙丁戊": ["子"]}},
    "断肠关": {"kind": "ganShiZhi", "table": {
        "甲乙": ["午", "未"], "丙丁": ["酉", "戌"], "庚辛": ["子", "丑"],
        "壬癸": ["辰", "巳"], "戊己": ["寅", "卯"]}},
    "四季关": {"kind": "monthZhiShiZhiSeason", "table": {
        "春": ["巳", "丑"], "夏": ["申", "辰"], "秋": ["亥", "未"], "冬": ["寅", "卯"]}},
    "四柱关": {"kind": "monthZhiShiZhi", "table": {
        "寅": ["巳", "亥"], "申": ["巳", "亥"], "卯": ["辰", "戌"], "酉": ["辰", "戌"],
        "辰": ["卯", "酉"], "戌": ["卯", "酉"], "巳": ["寅", "申"], "亥": ["寅", "申"],
        "午": ["丑", "未"], "子": ["丑", "未"], "未": ["子", "午"], "丑": ["子", "午"]}},
    "金锁关": {"kind": "monthZhiShiZhi", "table": {
        "寅": ["申"], "申": ["申"], "卯": ["酉"], "酉": ["酉"], "辰": ["戌"], "戌": ["戌"],
        "巳": ["亥"], "亥": ["亥"], "午": ["子"], "子": ["子"], "未": ["丑"], "丑": ["丑"]}},
    "无情关": {"kind": "monthZhiShiZhiSeason", "table": {
        "春": ["寅", "酉", "子"], "夏": ["戌", "亥", "巳"],
        "秋": ["申", "丑"], "冬": ["子", "午"]}},
    "断桥关": {"kind": "monthZhiShiZhi", "table": {
        "寅": ["寅"], "卯": ["卯"], "辰": ["申"], "巳": ["丑"], "午": ["戌"], "未": ["酉"],
        "申": ["辰"], "酉": ["巳"], "戌": ["午"], "亥": ["未"], "子": ["亥"], "丑": ["子"]}},
    "急脚关": {"kind": "monthZhiShiZhiSeason", "table": {
        "春": ["亥", "子"], "夏": ["卯", "未"], "秋": ["寅", "戌"], "冬": ["辰", "戌"]}},
    "浴盆关": {"kind": "monthZhiShiZhiSeason", "table": {
        "春": ["辰"], "夏": ["未"], "秋": ["戌"], "冬": ["丑"]}},  # 四季版；跳过李宪章版
    "水火关": {"kind": "monthZhiShiZhiSeason", "table": {
        "春": ["未", "戌"], "夏": ["丑", "辰"], "秋": ["丑", "戌"], "冬": ["辰", "未"]}},
    "咸池关": {"kind": "sanHeJu", "table": {
        "申子辰": ["酉"], "寅午戌": ["卯"], "巳酉丑": ["午"], "亥卯未": ["子"]}},
    "劫煞关": {"kind": "sanHeJu", "useDayZhi": False, "table": {
        "申子辰": ["巳"], "寅午戌": ["亥"], "巳酉丑": ["寅"], "亥卯未": ["申"]}},
    "多厄关": {"kind": "duoEComposite", "duoE": {
        "男": {"金": [5, 6], "木": [1, 2], "水": [8, 9], "火": [11, 12], "土": [1, 4]},
        "女": {"金": [8, 9], "木": [11, 12], "水": [2, 3], "火": [5, 6], "土": [1, 4]}}},
}

# 18 扩展煞
RULES_EXT = {
    "红艳煞": {"kind": "ganShiZhi", "severity": "轻关", "table": {
        "甲": ["午"], "乙": ["申"], "丙": ["寅"], "丁": ["未"], "戊": ["辰"],
        "己": ["辰"], "庚": ["戌"], "辛": ["酉"], "壬": ["子"], "癸": ["申"]}},
    "流霞煞": {"kind": "ganShiZhi", "severity": "轻关", "table": {
        "甲": ["酉"], "乙": ["戌"], "丙": ["未"], "丁": ["申"], "戊": ["巳"],
        "己": ["午"], "庚": ["辰"], "辛": ["卯"], "壬": ["亥"], "癸": ["寅"]}},
    "急脚煞": {"kind": "ganShiZhi", "severity": "中关", "table": {
        "甲乙": ["申", "酉"], "丙丁": ["亥", "子"], "戊己": ["寅", "卯"],
        "庚辛": ["巳", "午"], "壬癸": ["丑", "未", "辰", "戌"]}},
    "雷公打脑关": {"kind": "ganShiZhi", "severity": "中关", "table": {
        "甲": ["丑"], "乙": ["午"], "丙丁": ["子"], "戊己": ["戌"],
        "庚辛": ["寅"], "壬": ["酉"], "癸": ["亥"]}},
    "车前马后关": {"kind": "ganShiZhi", "severity": "中关", "table": {
        "甲己": ["辰"], "乙庚": ["寅"], "丙辛": ["巳"], "丁壬": ["申"], "戊癸": ["午"]}},
    "基败关": {"kind": "monthZhiShiZhi", "severity": "轻关", "table": {
        "寅": ["未", "戌", "亥"], "卯": ["未", "戌", "亥"], "辰": ["未", "戌", "亥"],
        "巳": ["子", "辰", "巳"], "午": ["子", "辰", "巳"], "未": ["子", "辰", "巳"],
        "申": ["丑", "申", "酉"], "酉": ["丑", "申", "酉"], "戌": ["丑", "申", "酉"],
        "亥": ["寅", "卯", "午"], "子": ["寅", "卯", "午"], "丑": ["寅", "卯", "午"]}},
    "槌门官符煞": {"kind": "monthZhiShiZhi", "severity": "轻关", "table": {
        "寅": ["寅"], "申": ["寅"], "卯": ["子"], "酉": ["子"], "辰": ["戌"], "戌": ["戌"],
        "巳": ["申"], "亥": ["申"], "午": ["午"], "子": ["午"], "未": ["辰"], "丑": ["辰"]}},
    "隔离关": {"kind": "monthZhiShiZhi", "severity": "轻关", "table": {
        "寅": ["亥"], "申": ["亥"], "卯": ["酉"], "酉": ["酉"], "辰": ["未"], "戌": ["未"],
        "巳": ["巳"], "亥": ["巳"], "午": ["卯"], "子": ["卯"], "未": ["午"], "丑": ["午"]}},
    "雷霆煞": {"kind": "monthZhiShiZhi", "severity": "中关", "table": {
        "寅": ["子"], "申": ["子"], "卯": ["寅"], "酉": ["寅"], "辰": ["辰"], "戌": ["辰"],
        "巳": ["午"], "亥": ["午"], "午": ["申"], "子": ["申"], "未": ["戌"], "丑": ["戌"]}},
    "阴锁关": {"kind": "monthZhiShiZhiSeason", "severity": "轻关", "table": {
        "春": ["丑", "巳"], "夏": ["寅", "辰"], "秋": ["亥", "未"], "冬": ["子", "申"]}},
    "离娘关": {"kind": "monthZhiShiZhiSeason", "severity": "轻关", "table": {
        "春": ["丑", "未"], "夏": ["寅", "申"], "秋": ["卯", "酉"], "冬": ["戌", "辰"]}},
    "丧车煞": {"kind": "monthZhiShiZhiSeason", "severity": "中关", "table": {
        "春": ["酉"], "夏": ["子"], "秋": ["午"], "冬": ["未"]}},
    "金锁匙": {"kind": "monthZhiShiZhi", "severity": "轻关", "table": {
        "寅": ["申"], "申": ["申"], "卯": ["酉"], "酉": ["酉"], "辰": ["戌"], "戌": ["戌"],
        "巳": ["亥"], "亥": ["亥"], "午": ["子"], "子": ["子"], "未": ["丑"], "丑": ["丑"]}},
    "蛇咬关": {"kind": "yearZhiShiZhi", "severity": "中关", "table": {
        "子午卯酉": ["巳"]}},  # 年支版（年/日支口径，本归一化仅取年支）
    "缠身官符煞": {"kind": "sanHeJu", "severity": "中关", "table": {
        "申子辰": ["亥"], "寅午戌": ["巳"], "巳酉丑": ["申"], "亥卯未": ["寅"]}},
    "白衣煞": {"kind": "yearZhiShiZhi", "severity": "中关", "table": {
        "寅申巳亥": ["辰"], "子午卯酉": ["未"], "辰戌丑未": ["丑"]}},
    "归忌煞": {"kind": "yearZhiShiZhi", "severity": "轻关", "table": {
        "寅申巳亥": ["丑"], "子午卯酉": ["寅"], "辰戌丑未": ["子"]}},  # 年支版
    "下情关": {"kind": "monthZhiShiZhiSeason", "severity": "轻关", "table": {
        "春": ["寅", "酉", "子"], "夏": ["戌", "亥", "巳"],
        "秋": ["申", "丑"], "冬": ["子", "午"]}},  # 与无情关同查法
}


# ---------------------------------------------------------------------------
# Dart 字面量 emit
# ---------------------------------------------------------------------------

def sq(s: str) -> str:
    """单引号 Dart 字符串字面量。"""
    s = s.replace("\\", "\\\\").replace("'", "\\'")
    return f"'{s}'"


def emit_list(items) -> str:
    return "[" + ", ".join(sq(x) for x in items) + "]"


def emit_set(items) -> str:
    return "{" + ", ".join(sq(x) for x in items) + "}"


def emit_map_str_list(d: dict) -> str:
    parts = []
    for k, v in d.items():
        parts.append(f"{sq(k)}: {emit_list(v)}")
    return "{" + ", ".join(parts) + "}"


def emit_tongzi(conds) -> str:
    parts = []
    for c in conds:
        args = []
        if c.get("seasonIn") is not None:
            args.append(f"seasonIn: {emit_set(c['seasonIn'])}")
        if c.get("nayinIn") is not None:
            args.append(f"nayinIn: {emit_set(c['nayinIn'])}")
        args.append(f"zhiIn: {emit_set(c['zhiIn'])}")
        parts.append(f"TongziCond({', '.join(args)})")
    return "[" + ", ".join(parts) + "]"


def emit_int_list(items) -> str:
    return "[" + ", ".join(str(x) for x in items) + "]"


def emit_duoe(duoe: dict) -> str:
    parts = []
    for gender, m in duoe.items():
        inner = ", ".join(f"{sq(k)}: {emit_int_list(v)}" for k, v in m.items())
        parts.append(f"{sq(gender)}: {{{inner}}}")
    return "{" + ", ".join(parts) + "}"


def emit_rule(rule: dict) -> str:
    kind = rule["kind"]
    extra = ""
    if rule.get("useDayZhi") is False:
        extra = ", useDayZhi: false"
    if kind == "tongziComposite":
        return f"GuanshaRule(kind: GuanshaRuleKind.{kind}, tongzi: {emit_tongzi(rule['tongzi'])})"
    if kind == "duoEComposite":
        return f"GuanshaRule(kind: GuanshaRuleKind.{kind}, duoE: {emit_duoe(rule['duoE'])})"
    return f"GuanshaRule(kind: GuanshaRuleKind.{kind}, table: {emit_map_str_list(rule['table'])}{extra})"


def emit_entry(d: dict, rule: dict, is_ext: bool) -> str:
    name = d["名称"]
    aliases = [a for a in d.get("别名", []) if a]
    category = d["类别"]
    severity = d.get("严重程度") or rule.get("severity") or "轻关"
    jue = d.get("口诀") or d.get("口诀_星曜版") or d.get("口诀_年支版") or ""
    fan = d.get("犯者忌") or d.get("犯者主") or []
    hua = d.get("化解方法") or []
    tu = d.get("图示说明")
    tu_str = sq(tu) if tu else "null"
    return (
        "  GuanshaEntry(\n"
        f"    name: {sq(name)},\n"
        f"    aliases: {emit_list(aliases)},\n"
        f"    category: {sq(category)},\n"
        f"    severity: {sq(severity)},\n"
        f"    jue: {sq(jue)},\n"
        f"    rule: {emit_rule(rule)},\n"
        f"    fanZheJi: {emit_list(fan)},\n"
        f"    huaJie: {emit_list(hua)},\n"
        f"    tuShi: {tu_str},\n"
        f"    isExt: {'true' if is_ext else 'false'},\n"
        "  ),"
    )


def main() -> None:
    with open(SRC, "r", encoding="utf-8") as f:
        data = json.load(f)

    guansha_list = data["关煞列表"]
    ext_list = data["扩展煞_七十二煞体系"]["扩展煞列表"]

    # 按名称索引（确保顺序稳定）
    guansha_by_name = {e["名称"]: e for e in guansha_list}
    ext_by_name = {e["名称"]: e for e in ext_list}

    lines = []
    lines.append("// 由 tool/gen_guansha_data.py 生成，请勿手工编辑。")
    lines.append("// 数据源：《小儿关煞大全（36关+72煞扩展54条·核对版）.json》")
    lines.append("// 内容属传统民俗文化参考，非医学或命理定论；儿童健康请务必咨询正规医疗机构。")
    lines.append("")
    lines.append("/// 关煞查法归一化种类。")
    lines.append("enum GuanshaRuleKind {")
    lines.append("  yearZhiShiZhi,")
    lines.append("  monthZhiShiZhiSeason,")
    lines.append("  monthZhiShiZhi,")
    lines.append("  ganShiZhi,")
    lines.append("  nayinShiZhi,")
    lines.append("  sanHeJu,")
    lines.append("  tongziComposite,")
    lines.append("  duoEComposite,")
    lines.append("}")
    lines.append("")
    lines.append("/// 童子关五条件之一：满足 seasonIn（月份季节）或 nayinIn（年柱纳音五行）时，")
    lines.append("/// 若日支或时支 ∈ [zhiIn] 即犯。各条件独立，满足任一即犯。")
    lines.append("class TongziCond {")
    lines.append("  final Set<String>? seasonIn;")
    lines.append("  final Set<String>? nayinIn;")
    lines.append("  final Set<String> zhiIn;")
    lines.append("  const TongziCond({this.seasonIn, this.nayinIn, required this.zhiIn});")
    lines.append("}")
    lines.append("")
    lines.append("/// 单一关煞的查法归一化规则。")
    lines.append("class GuanshaRule {")
    lines.append("  final GuanshaRuleKind kind;")
    lines.append("  final Map<String, List<String>> table;")
    lines.append("  final List<TongziCond>? tongzi;")
    lines.append("  final Map<String, Map<String, List<int>>>? duoE;")
    lines.append("  final bool useDayZhi;")
    lines.append("  const GuanshaRule({")
    lines.append("    required this.kind,")
    lines.append("    this.table = const {},")
    lines.append("    this.tongzi,")
    lines.append("    this.duoE,")
    lines.append("    this.useDayZhi = true,")
    lines.append("  });")
    lines.append("}")
    lines.append("")
    lines.append("/// 单条关煞/扩展煞条目。")
    lines.append("class GuanshaEntry {")
    lines.append("  final String name;")
    lines.append("  final List<String> aliases;")
    lines.append("  final String category;")
    lines.append("  final String severity; // 重关 / 中关 / 轻关")
    lines.append("  final String jue; // 口诀（部分条目无）")
    lines.append("  final GuanshaRule rule;")
    lines.append("  final List<String> fanZheJi; // 犯者忌")
    lines.append("  final List<String> huaJie; // 化解方法")
    lines.append("  final String? tuShi; // 图示说明（可选）")
    lines.append("  final bool isExt; // 是否扩展煞")
    lines.append("  const GuanshaEntry({")
    lines.append("    required this.name,")
    lines.append("    this.aliases = const [],")
    lines.append("    required this.category,")
    lines.append("    required this.severity,")
    lines.append("    this.jue = '',")
    lines.append("    required this.rule,")
    lines.append("    required this.fanZheJi,")
    lines.append("    required this.huaJie,")
    lines.append("    this.tuShi,")
    lines.append("    required this.isExt,")
    lines.append("  });")
    lines.append("}")
    lines.append("")
    lines.append("const List<GuanshaEntry> kGuanshaEntries = [")
    for name in [e["名称"] for e in guansha_list]:
        lines.append(emit_entry(guansha_by_name[name], RULES_36[name], False))
    lines.append("];")
    lines.append("")
    lines.append("const List<GuanshaEntry> kExtShaEntries = [")
    for name in [e["名称"] for e in ext_list]:
        lines.append(emit_entry(ext_by_name[name], RULES_EXT[name], True))
    lines.append("];")
    lines.append("")
    lines.append("/// 36 关按查法分类（类别枚举）。")
    lines.append("const List<String> kGuanshaCategories = [")
    lines.append("  '年支见时支',")
    lines.append("  '月支见时支',")
    lines.append("  '日干或年干见时支',")
    lines.append("  '年柱纳音五行见时支',")
    lines.append("  '综合查法',")
    lines.append("];")
    lines.append("")
    lines.append("/// 关煞/扩展煞检索：query 为空返回全部；否则按 名称/别名/口诀 逐字段 contains。")
    lines.append("/// 若 category 非 null 再叠加 category 相等过滤。返回新列表，不改原列表。")
    lines.append("List<GuanshaEntry> searchGuansha(String query, [String? category]) {")
    lines.append("  final q = query.trim().toLowerCase();")
    lines.append("  final List<GuanshaEntry> all = [...kGuanshaEntries, ...kExtShaEntries];")
    lines.append("  Iterable<GuanshaEntry> list = all;")
    lines.append("  if (category != null) {")
    lines.append("    list = list.where((e) => e.category == category);")
    lines.append("  }")
    lines.append("  if (q.isEmpty) return list.toList();")
    lines.append("  return list.where((e) =>")
    lines.append("      e.name.toLowerCase().contains(q) ||")
    lines.append("      e.aliases.any((a) => a.toLowerCase().contains(q)) ||")
    lines.append("      e.jue.toLowerCase().contains(q)).toList();")
    lines.append("}")
    lines.append("")

    out_path = os.path.normpath(OUT)
    with open(out_path, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))
    print(f"written: {out_path}")
    print(f"36关: {len(guansha_list)}  扩展煞: {len(ext_list)}")


if __name__ == "__main__":
    main()
