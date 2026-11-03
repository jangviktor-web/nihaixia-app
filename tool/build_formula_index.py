#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""方剂提及预索引生成器。

把 formula_detail_screen.dart 里「见于经典」的运行时全量扫描（833 个条文
资源 × 327 方名正则，每次打开详情页现算）替换为预生成索引：

  assets/data/formula_index.json
  { "_v": 1,
    "四逆汤": { "s": [伤寒条文seq...], "j": [金匮条文seq...],
                "z": [{"s": 针灸讲稿seq, "n": 次数}...],
                "b": [{"s": 本草讲稿seq, "n": 次数}...] }, ... }

判定逻辑 1:1 移植自 Dart `clauseIntroducesFormula`（中间档精度）：
  1) 方证标题（首行且为标题行）即该方；
  2) `>` 引文块（含续行，不含 `#` 小标题）中，方名（最长优先匹配）
     之后紧接「主之」。
弱信号（宜/与/属/可/当）不计入——与现行 App 行为逐位一致。

--selfcheck：重放 test/formula_intro_test.dart 的全部断言（逻辑已从
Dart 迁出，此处成为该判定函数的唯一测试位）。
"""

import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "data", "formula_index.json")

SOURCES = {
    "shanghan": os.path.join(ROOT, "assets", "shanghan"),
    "jingui": os.path.join(ROOT, "assets", "jingui"),
    "zhenjiu": os.path.join(ROOT, "assets", "zhenjiu_lecture"),
    "bencao": os.path.join(ROOT, "assets", "bencao_lecture"),
}

# 与 Dart 同源：`XX主之`——方名后（跳过收尾引号括号）紧接主治标记。
VERSE = re.compile(r"^\s*[」』】\]）)]?\s*主之")
# 收紧判据：`名+主之。`（句末）才算「正式介绍」。
# 倪师讲解用口语（「…四逆汤主之，而茯苓四逆汤不是」），不会以「主之。」收尾；
# 原文引文一律是「…主之。」。故以句末形式为界，可排除讲解段误判。
VERSE_SENT = re.compile(r"^\s*[」』】\]）)]?\s*主之[。；]")


# 语料异写 → app 正名 对照表（2026-11-03 逐条核对语料后手工确定，勿自动生成）。
# 键=app 方剂正名，值=语料/古籍异写。覆盖三类：
#   ① 异体字：耆/芪、复/覆、髪/发、桔/橘、萎/蒌；
#   ② 语料掉字/多字：栝瞿麦丸(漏蒌)、越加术汤(漏婢)、归芍药散(漏当)、
#      猪苓字散(衍字)、大黄虫丸(缺蟅)、白通汤加猪胆汁汤(多汤)；
#   ③ 古今异名：理中丸=理中汤、乌头煎=大乌头煎、大黄牡丹汤=大黄牡丹皮汤、
#      八味肾气丸=肾气丸、麻仁丸=麻子仁丸、百合鸡子汤=百合鸡子黄汤。
# ⛔ 只收「同一条文内该方确实被介绍」的异写；不同方（抵当汤≠抵当丸、
#    薏苡附子散≠附子散、小建中汤≠黄芪建中汤、大陷胸汤≠大陷胸丸、
#    大乌头煎≠乌头煎、大黄牡丹汤≠大黄牡丹皮汤、猪膏髪煎≠猪膏发煎）一律不收。
# ⚠️ 别名值若本身是 app 里的独立方剂条目，禁止登记（会劫持其命中）。
ALIASES = {
    "理中汤": ["理中丸"],
    "旋覆代赭石汤": ["旋复花代赭石汤"],
    "旋覆花汤": ["旋复花汤"],
    "木防己去石膏加茯苓芒硝汤": ["防己汤去石膏加茯苓芒硝汤"],
    "栝蒌瞿麦丸": ["栝瞿麦丸"],
    "栝蒌薤白半夏汤": ["栝萎薤白半夏汤"],
    "橘皮汤": ["桔皮汤"],
    "白通加猪胆汁汤": ["白通汤加猪胆汁汤", "白通汤加猪胆汁"],
    "防己黄芪汤": ["防己黄耆汤"],
    "黄芪建中汤": ["黄耆建中汤"],
    "黄芪桂枝五物汤": ["黄耆桂枝五物汤"],
    "桂枝加黄芪汤": ["桂枝加黄耆汤"],
    "桂枝加龙骨牡蛎汤": ["桂枝龙骨牡蛎汤"],
    "麻子仁丸": ["麻仁丸"],
    "当归生姜羊肉汤": ["归生姜羊肉汤"],
    "当归芍药散": ["归芍药散"],
    "百合鸡子黄汤": ["百合鸡子汤"],
    "猪苓散": ["猪苓字散"],
    "赤豆当归散": ["赤小豆当归散"],
    "大黄蟅虫丸": ["大黄虫丸"],
    "肾气丸": ["八味肾气丸"],
    "越婢加术汤": ["越加术汤"],
    "烧裈散": ["烧棍散"],
    "桂枝去芍药加蜀漆牡蛎龙骨救逆汤": ["芍药加蜀漆牡蛎龙骨救逆汤"],
    "黄芪芍药桂枝苦酒汤": ["芍桂酒汤"],
    "苇茎汤": ["千金苇茎汤"],
    # 2026-11-03 语料既有条文、但方名写法与 app 正名不同（零成本修复，不用补数据）：
    "栀子厚朴汤": ["栀子厚朴枳实汤"],   # 组成一致（栀子14+厚朴4两+枳实4）
    "桂枝加芍药生姜各一两人参三两新加汤": ["新加汤"],
    "蜜煎方": ["蜜煎导"],
    "桂枝去芍药加附子汤": ["桂枝去芍药方中加附子汤", "桂枝汤去芍药方中加附子汤"],

    # 2026-11-03 合并同方重复条目后（原为独立条目，现已并入正名）：
    "蜜煎方": ["蜜煎导方"],
    "苓甘五味加姜辛半夏杏仁汤": ["苓甘五味姜辛夏汤"],
    "苓甘五味姜辛半夏汤": ["苓甘五味姜辛夏杏汤"],
    "苓甘五味加姜辛夏杏大黄汤": ["苓甘五味姜辛夏杏大黄汤"],
    # 2026-11-03 合并同方重复条目后（原为独立条目，现已并入正名）：
    "猪膏发煎": ["猪膏髪煎"],
    "大乌头煎": ["乌头煎"],
    "甘草干姜茯苓白术汤": ["肾着汤", "甘草干姜苓术汤", "干姜苓术汤", "甘姜苓术汤"],
    # 甘姜苓术汤 已并入本条（2026-11-03），此处保留其语料写法以匹配原文
}


# 强制关联（2026-11-03 用户逐条指定）：语料转写时丢了「主之」或改了句式，
# 但该条文确实在介绍此方 → 人工核对语料后强制挂上，避免放宽判定引入口语误挂。
# key=app 正名，value=条文卡文件名（相对 assets/）。
FORCED = {
    "大陷胸丸": ["shanghan/clause_139.md"],       # 「宜『大陷胸丸』。」原文漏「主之」
    "三物小白散": ["shanghan/clause_149.md"],       # 「与『三物小白散』，『陷胸汤』不可服」
    "桂枝加附子汤": ["shanghan/clause_026.md"],     # 「（此为桂枝加附子汤证）」
    "黄芩加半夏生姜汤": ["shanghan/clause_177.md"],  # 「若呕者，黄芩加半夏生姜汤」
    "猪胆汁方": ["shanghan/clause_227.md"],         # 「宜大猪胆汁方」
    "桂枝麻黄各半汤": ["jingui/clause_132.md"],     # 「如果没有恶心，桂枝麻黄各半汤」
    "蜜煎方": ["shanghan/clause_227.md"],            # 条文248「宜蜜煎导而通之」无「主之」
}


def load_formula_names():
    """返回 (app 正名列表, 最长优先交替正则, 写法→正名 反查表)。"""
    d = json.load(io.open(os.path.join(ROOT, "assets", "data", "formulas.json"),
                          encoding="utf-8"))
    fs = d["formulas"] if isinstance(d, dict) else d
    names = [f["name"] for f in fs if f.get("name")]
    # 最长优先交替（Dart/JS 与 Python 均为「最左优先取首个命中分支」，
    # 分支按长度降序 → 等效最长优先）
    names.sort(key=lambda n: -len(n))
    # 异写一并入交替；命中后按反查表归到 app 正名
    forms, back = [], {}
    for n in names:
        forms.append(n)
        back[n] = n
    for canon, alts in ALIASES.items():
        if canon not in names:
            continue
        for a in alts:
            forms.append(a)
            back[a] = canon
    forms.sort(key=lambda s: -len(s))
    return names, re.compile("|".join(re.escape(n) for n in forms)), back


def quote_region(text):
    """`>` 引文块（含紧随的非空续行）；不含 `#` 讲解小标题。逐行同 Dart。"""
    buf, in_bq = [], False
    for ln in text.split("\n"):
        s = ln.strip()
        if s.startswith(">"):
            buf.append(s)
            in_bq = True
        elif in_bq and s and not s.startswith("#"):
            buf.append(s)
        else:
            in_bq = False
    return "\n".join(buf)


def normalize(text):
    """还原讲稿的 [方名] 标注标记（MarkdownDocScreen 的链接写法）。

    讲稿正文把方名写成 [半夏散]及[汤]，方名被括号拆开 → 判定前去掉方括号
    （保留内容），使「[半夏散]及[汤]主之」还原为「半夏散及汤主之」。
    """
    return re.sub(r"\[([^\]]*)\]", lambda m: m.group(1), text)


def file_hits(text, name_re, back):
    """一条条文卡「介绍了哪些方」→ 正名集合（全部判定规则并集）。"""
    canon = lambda s: back.get(s, s)
    txt = normalize(text)
    lines = txt.split(chr(10))
    hits = set()
    # ① 方证标题（首行且为标题行）即该方
    if lines and lines[0].strip().startswith("#"):
        hits |= {canon(x.group(0)) for x in name_re.finditer(lines[0])}
    # ② 原文引文块中「方名 + 主之」
    region = quote_region(txt)
    hits |= {canon(x.group(0)) for x in name_re.finditer(region)
             if VERSE.match(region[x.end():x.end() + 5])}
    # ③ 全文句末「方名 + 主之。」（修复原文被空行截断造成的漏挂）
    body = chr(10).join(ln for ln in lines if not ln.strip().startswith("#"))
    hits |= {canon(x.group(0)) for x in name_re.finditer(body)
             if VERSE_SENT.match(body[x.end():x.end() + 6])}
    # ③′ 原文以引号引出方名（『X』主之，…）——引文块被空行截断时的兜底。
    # 要求方名被引号包裹：原文引用才加引号，倪师讲解口语不加 → 不误判。
    for m in name_re.finditer(body):
        pre = body[max(0, m.start() - 1):m.start()]
        post = body[m.end():m.end() + 8]
        if pre in ("「", "『", "【") and VERSE.match(post):
            hits.add(canon(m.group(0)))
            break
    # ④ 讲稿补录段落标题「#### 方名方 / #### 方名（括注）」= 该条正式列出此方
    for ln in lines:
        s = ln.strip()
        if not s.startswith("#"):
            continue
        # 去括注（（…）【…】《…》）与尾部「方」，得到候选标题
        s2 = re.sub(r"[（(【《][^）)】》]*[）)】》]?", "", s).lstrip("#").strip()
        for cand in (s2, re.sub(r"方$", "", s2)):
            if not cand:
                continue
            for x in name_re.finditer(cand):
                rest = cand.replace(x.group(0), "", 1).strip()
                if rest in ("", "方"):
                    hits.add(canon(x.group(0)))
                    break
                # 以方名开头 + 余下为说明（如「矾石汤 治脚气冲心」）→ 也是介绍该方；
                # 对比/鉴别类标题（「X之别」「X与Y之别」）排除，避免误挂。
                if cand.startswith(x.group(0)) and not re.search(
                        r"之别|区别|辨别|鉴别|不同|相较|对比", rest):
                    hits.add(canon(x.group(0)))
                    break
    return hits


def clause_introduces(text, name_re, name, back=None):
    """某方是否被该条文卡「专门介绍」（供自检与单方查询用）。"""
    b = back if back is not None else {}
    return name in file_hits(text, name_re, b)


def md_files(folder):
    return sorted(f for f in os.listdir(folder) if f.endswith(".md"))


def build_index():
    names, name_re, back = load_formula_names()
    canon = lambda s: back.get(s, s)
    idx = {}

    # 条文源（shanghan/jingui）：每 seq 一文件，seq = 文件名排序序；key 紧凑 s/j/z/b
    for key, short in (("shanghan", "s"), ("jingui", "j")):
        folder = SOURCES[key]
        for seq, fn in enumerate(md_files(folder)):
            text = io.open(os.path.join(folder, fn), encoding="utf-8").read()
            for name in file_hits(text, name_re, back):
                idx.setdefault(name, {}).setdefault(short, []).append(seq)

    # 强制关联（人工核对）：语料转写丢「主之」但确实在介绍此方的条文
    for name, files in FORCED.items():
        if name not in names:
            continue
        for rel in files:
            folder, fn = rel.split("/")
            short = {"shanghan": "s", "jingui": "j"}[folder]
            seqs = md_files(SOURCES[folder])
            if fn not in seqs:
                raise SystemExit(f"FORCED 指向不存在的条文卡: {rel}")
            idx.setdefault(name, {}).setdefault(short, []).append(seqs.index(fn))

    # 讲稿源（zhenjiu/bencao）：提及次数（最大匹配归属，四逆汤不计入茯苓四逆汤）
    for key, short in (("zhenjiu", "z"), ("bencao", "b")):
        folder = SOURCES[key]
        for seq, fn in enumerate(md_files(folder)):
            text = normalize(io.open(os.path.join(folder, fn), encoding="utf-8").read())
            counts = {}
            for m in name_re.finditer(text):
                c = canon(m.group(0))
                counts[c] = counts.get(c, 0) + 1
            for name, n in counts.items():
                idx.setdefault(name, {}).setdefault(short, []).append(
                    {"s": seq, "n": n})

    out = {"_v": 1}
    for name in names:
        if name in idx:
            out[name] = idx[name]
    return out, names


def selfcheck():
    """重放 test/formula_intro_test.dart 的 11 个断言（逻辑迁出后的唯一测试位）。"""
    names = ["桂枝汤", "茯苓四逆汤", "通脉四逆汤", "四逆汤", "白虎加人参汤", "真武汤",
             "柴胡桂枝干姜汤"]
    names.sort(key=lambda n: -len(n))
    re_names = re.compile("|".join(re.escape(n) for n in names))
    ci = lambda t, n: clause_introduces(t, re_names, n)
    cases = [
        ("#### 条文34：四逆汤（救逆第四方）\n", "四逆汤", True),
        ("#### 条文20：桂枝汤禁忌——无汗伤寒禁用\n", "桂枝汤", True),
        ("### 三三七：[少阴病]，脉沉者，急温之，宜[四逆汤]。\n", "四逆汤", True),
        ("### 三六九：大汗，若大下利而厥冷者，「四逆汤」主之。\n", "四逆汤", True),
        ("> 太阳病发汗…真武汤主之。\n", "真武汤", True),
        ("> [少阴病]，脉沉者，急温之，宜[四逆汤]。\n", "四逆汤", False),
        ("> 舌上白苔者，可与「桂枝汤」，上焦得通\n", "桂枝汤", False),
        ("#### 条文74：茯苓四逆汤\n", "四逆汤", False),
        ("### 三八六：汗出而厥者，『通脉四逆汤』主之。\n", "四逆汤", False),
        ("#### 条文74：茯苓四逆汤\n", "茯苓四逆汤", True),
        ("> 服桂枝汤，大汗出后，大烦渴不解，脉洪大者，白虎加人参汤主之。\n", "桂枝汤", False),
        ("> 伤寒脉浮…反与桂枝汤，欲攻其表，此误也。\n", "桂枝汤", False),
        ("#### 条文90：真武汤\n\n> 太阳病发汗…真武汤主之。\n\n#### 与桂枝汤之别\n\n- 此处讲桂枝汤…\n",
         "桂枝汤", False),
        ("#### 条文90：真武汤\n\n> 太阳病发汗…真武汤主之。\n\n#### 与桂枝汤之别\n\n- 此处讲桂枝汤…\n",
         "真武汤", True),
        # ↓ 2026-11-03 新增：原文引文被空行截断（真实 bug 回归）
        ("#### 条文162（一百六十二）\n\n> 一六二：伤寒五六日…渴而不呕，但\n\n"
         "头汗出，往来寒热，心烦者，此为未解也，「柴胡桂枝干姜汤」主之。\n\n"
         "柴胡桂枝干姜汤方柴胡半斤，桂枝三两。\n",
         "柴胡桂枝干姜汤", True),
        # 讲解口语不以「主之。」收尾 → 不算正式介绍
        ("#### 条文90：真武汤\n\n> 太阳病发汗…真武汤主之。\n\n"
         "所以用四逆汤主之，而茯苓四逆汤不是这种情形。\n",
         "四逆汤", False),
    ]
    bad = [(t[:20], n, want, ci(t, n)) for t, n, want in cases if ci(t, n) != want]
    for t, n, want, got in bad:
        print(f"FAIL {n} want={want} got={got} | {t}")
    return not bad


def main():
    if "--selfcheck" in sys.argv:
        ok = selfcheck()
        print("selfcheck:", "PASS" if ok else "FAIL")
        sys.exit(0 if ok else 1)

    idx, names = build_index()
    total_hits = sum(
        len(v.get("s", [])) + len(v.get("j", []))
        + len(v.get("z", [])) + len(v.get("b", []))
        for v in idx.values() if isinstance(v, dict))
    io.open(OUT, "w", encoding="utf-8", newline="\n").write(
        json.dumps(idx, ensure_ascii=False, separators=(",", ":")))
    print(f"方剂总数: {len(names)} / 索引命中方剂数: {len(idx) - 1}")
    print(f"命中条目总数: {total_hits}")
    print(f"大小: {os.path.getsize(OUT) / 1024:.0f} KB -> {OUT}")
    # 抽样
    for probe in ("四逆汤", "桂枝汤", "小柴胡汤"):
        v = idx.get(probe)
        if v:
            print(f"  {probe}: 伤寒{len(v.get('s', []))} 金匮{len(v.get('j', []))} "
                  f"针灸{len(v.get('z', []))} 本草{len(v.get('b', []))}")


if __name__ == "__main__":
    main()
