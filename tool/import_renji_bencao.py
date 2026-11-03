# -*- coding: utf-8 -*-
"""把《人纪·神农本草经》讲稿切成讲稿阅读库的篇文件 + 药材提及索引。

用法：
    python tool/import_renji_bencao.py "D:/nhx/人纪-神农本草经-倪海厦.txt"

源文件（UTF-8，约 59.6 万字）结构：
  - `## 倪海厦传记`（跳过，非讲稿内容）/ `## 自序` / `## 第一章 前言`
  - `## 第二章 药性总义参考《本草备要》`：31 个 `### ` 小节
  - `## 壹 上经`(128 `####`) / `## 贰 中经`(92) / `## 叁 下经`(85)
      药目标题形态：`序号、药名[拼音]（注文）`，含少量脏标题
  - `## 第三章 增补《神农本草经》不足部分`：前 28 个 `####` 是药目（`名——注释`），
      其后序号从「一」重新开始的是药性理论/五行文本（非药目）

处理：
  1. 按药目粒度切篇（每味药一篇，2026-11-01 用户定）；序言/药性总义、药性理论/五行
     各并一篇总论；
  2. 清洗脏标题：序号/拼音注（[niè]、bare pinyin zhú/míng…）/「百度百科」垃圾/
     标题内嵌【本经原文】与 `—` 后注释（拆回正文不丢内容）/ 定点修脏（粉钖淘宝、
     雀瓮（蝉蜕）——2026-11-01 核查定案雀瓮≠蝉蜕，展示层不传播）；
  3. 删除全部 B 站链接与时间戳标记（复用针灸版 purge，含防御版 URL 正则）；
  4. 输出 `assets/bencao_lecture/NNN_标题.md`（篇名 = `上经·丹砂` 等）；
  5. 生成 `lib/data/bencao_lecture_data.dart`；
  6. 生成 `assets/bencao_lecture/herb_index.json`：
       { "药库正名": [{"s": 篇seq, "n": 提及次数}], "_excluded": [] }
     —— herbs 详情页「讲义讲解」数据源。计数用 herbs.json 的 name 主名+括号内别名
     （<2 字别名丢弃，否则如「斑蟊（猫）」的「猫」会满篇误计）。

⚠️ 讲义内容增删后必须重跑本脚本 + tool/build_classic_search_index.py。
"""

import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "bencao_lecture")
DART_OUT = os.path.join(ROOT, "lib", "data", "bencao_lecture_data.dart")
DEFAULT_SRC = "D:/nhx/人纪-神农本草经-倪海厦.txt"
HERBS_JSON = os.path.join(ROOT, "assets", "data", "herbs.json")

# B 站链接：[（时间戳）](url)，源文件瑕疵混杂（URL 尾粘全角 `）` 等）。
_LINK = re.compile(r"\[（[^）\]]*）?\]\s*[(（]https?://[^)\s（）]*[）)]?")

_CN = "一二三四五六七八九十百○〇零"

# 定点修脏（清洗规则还原不了的，逐条定点改）。
DIRT_TITLE_FIXES = {
    "粉钖淘宝": "粉钖",
    # 整理者把「蝉蜕」误注为雀瓮别名；2026-11-01 互联网核查定案：
    # 雀瓮=天浆子（黄刺蛾茧）≠蝉蜕（蝉蜕出自本经蚱蝉条）。展示层不传播该错误。
    "雀瓮（蝉蜕）": "雀瓮",
}

INTRO_TITLES = {
    "自序": "总论·自序",
    "第一章": "总论·前言",
    "第二章": "总论·药性总义",
}
THEORY_TITLE = "总论·药性理论与五行"


def purge(text: str) -> str:
    """落盘兜底强清理：一切外链 / URL / B 站字样 / 时间戳，一律不留。

    URL 匹配限定字符集（[^\s（）()]+，可选尾全角括号），不能用 \\S+——
    源文件里 URL 与正文同段无空白分隔，\\S+ 会连正文一起删（针灸版 v1.11.29 实测）。
    """
    t = _LINK.sub("", text)
    t = re.sub(r"https?://[^\s（）()]+[）)]?", "", t)
    t = re.sub(r"www\.[^\s（）()]+[）)]?", "", t)
    t = re.sub(r"\d+-\d{2}:\d{2}:\d{2}）?", "", t)
    t = re.sub(r"(?i)\[?\(?(b站|bilibili)\)?\]?", "", t)
    t = re.sub(r"^.*(网址|链接)[:：].*$", "", t, flags=re.M)
    t = re.sub(r"\n{3,}", "\n\n", t)
    return t.strip()


def clean(text: str) -> str:
    """删 B 站链接与时间戳标记，收敛多余空行。"""
    text = _LINK.sub("", text)
    text = re.sub(r"https?://\S+|www\.\S+", "", text)
    text = re.sub(r"\d+-\d{2}:\d{2}:\d{2}）?", "", text)
    text = re.sub(r"^.*(网址|链接)[:：].*$", "", text, flags=re.M)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def cn_to_int(s: str) -> int:
    """中文序号 → int。源文件混用两种风格：
    紧凑式「一四三」=143、「三○○」=300（三品章）；组合式「十」「二十八」（增补章）。"""
    s = s.replace("○", "0").replace("〇", "0").replace("零", "")
    units = {"一": 1, "二": 2, "三": 3, "四": 4, "五": 5, "六": 6,
             "七": 7, "八": 8, "九": 9, "0": 0}
    if not s:
        return 0

    def concat(t: str) -> int:
        if t and all(c in units for c in t):
            return int("".join(str(units[c]) for c in t))
        return 0

    if "十" in s or "百" in s:
        total = 0
        if "百" in s:
            parts = s.split("百")
            total += (units.get(parts[0], 1) if parts[0] else 1) * 100
            s = parts[1] if len(parts) > 1 else ""
        if "十" in s:
            parts = s.split("十")
            total += (units.get(parts[0], 1) if parts[0] else 1) * 10
            total += units.get(parts[1], 0) if len(parts) > 1 and parts[1] else 0
        else:
            total += concat(s)
        return total
    return concat(s)


def clean_title(raw: str):
    """清洗药目标题。返回 (标题, 内嵌正文行 list)。"""
    t = raw.strip()
    t = re.sub(r"^[" + _CN + r"]+、\s*", "", t)  # 序号
    inline = []
    m = re.search(r"【本经原文】", t)
    if m:
        inline.append(t[m.start():])
        t = t[: m.start()]
    else:
        m2 = re.search(r"—", t)
        if m2:  # 赤芝…—味苦平，… / 增补注释 —— xxx
            tail = t[m2.start():].lstrip("—").strip()
            if re.fullmatch(r"（[^（）]+）", tail):
                t += tail  # 「柏叶——（侧柏叶）」别名回填标题
            elif tail:
                inline.append(tail)
            t = t[: m2.start()]
    t = re.sub(r"\[[^\]]*\]", "", t)  # [niè] 拼音注
    t = re.sub(r"[A-Za-zÀ-ž]+", "", t)  # 裸拼音 zhú / yān / míng / chú …
    t = t.replace("百度百科", "")
    t = re.sub(r"\s+", "", t)
    if t in DIRT_TITLE_FIXES:
        t = DIRT_TITLE_FIXES[t]
    return t, inline


def is_herb_title(t: str) -> bool:
    """清洗后像不像药名：短（≤12 字，如「猪胆、猪肤」「青石赤石…黑石脂等」）
    且无句末标点。闲谈/理论标题（如「三○○、三○一，这些什么鬼臼啊…」）都远超长。"""
    return bool(t) and len(t) <= 12 and not re.search(r"[。？！；]", t)


def safe_name(title: str) -> str:
    return re.sub(r'[\\/:*?"<>|（）()\s、，。·]', "", title)[:40]


def parse(src: str):
    """返回 [(篇名, 正文行list)]，保持原文顺序。理论文本集中成独立总论篇。"""
    lines = src.split("\n")
    sections = []  # [[篇名, [lines]]]
    theory = []  # 增补章尾部的药性理论/五行
    chapter = None
    cur_title = None
    cur_body = []
    zengbu_num = 0
    zengbu_theory = False

    def flush():
        nonlocal cur_title, cur_body
        if cur_title is not None:
            sections.append([cur_title, cur_body])
            cur_title, cur_body = None, []

    for ln in lines:
        m2 = re.match(r"^## (.+)$", ln)
        m3 = re.match(r"^### (.+)$", ln)
        m4 = re.match(r"^#### (.+)$", ln)
        if m2:
            flush()
            chapter = m2.group(1).strip()
            zengbu_num, zengbu_theory = 0, False
            for k, v in INTRO_TITLES.items():
                if chapter.startswith(k):
                    cur_title, cur_body = v, []
                    break
            continue
        if chapter is None or "传记" in chapter:
            continue
        if m3 and cur_title is not None and cur_title.startswith("总论·"):
            cur_body.append("#### " + m3.group(1).strip())
            continue
        if m4:
            title, inline = clean_title(m4.group(1))
            if chapter.startswith("第三章"):
                mnum = re.match(r"^[" + _CN + r"]+、", m4.group(1).strip())
                if mnum:
                    n = cn_to_int(mnum.group(0).rstrip("、"))
                    if n <= zengbu_num:
                        zengbu_theory = True  # 序号从「一」重新开始 ⇒ 理论文本
                    zengbu_num = max(zengbu_num, n)
            is_theory = (chapter.startswith("第三章") and zengbu_theory) or not is_herb_title(title)
            if is_theory:
                flush()
                # 增补章理论 → 独立总论篇；三品章内闲谈 → 并入上一药目篇尾
                if chapter.startswith("第三章") and zengbu_theory:
                    theory.append("#### " + m4.group(1).strip())
                elif sections:
                    sections[-1][1].append("#### " + m4.group(1).strip())
                continue
            flush()
            prefix = ("上经" if chapter.startswith("壹")
                      else "中经" if chapter.startswith("贰")
                      else "下经" if chapter.startswith("叁")
                      else "增补" if chapter.startswith("第三章") else chapter[:4])
            cur_title = f"{prefix}·{title}"
            cur_body = list(inline)
            continue
        if cur_title is not None:
            cur_body.append(ln)
        elif sections and ln.strip():
            sections[-1][1].append(ln)  # 篇间闲文挂上一药目篇尾
    flush()
    if theory:
        sections.append([THEORY_TITLE, theory])
    return sections


def herb_forms():
    """herbs.json 每味药的匹配形态：主名 + 括号别名（又名/即 前缀剥离，<2 字丢弃）。"""
    data = json.load(io.open(HERBS_JSON, encoding="utf-8"))
    out = []
    for h in data["herbs"]:
        name = h["name"]
        forms = []
        for inner in re.findall(r"（([^（）]+)）", name):
            inner = re.sub(r"^(又名|即|也叫|俗称)", "", inner).strip()
            if len(inner) >= 2:
                forms.append(inner)
        main = name.split("（")[0].strip()
        if main:
            forms.append(main)
        out.append({"name": name, "forms": forms})
    return out


def herb_index(bodies):
    """扫全部篇正文，统计药材名出现次数（key = herbs.json 的完整 name）。

    # ponytail: set(form) 去重后逐词 str.count（秒级）；别名归属以
    # herbs.json 括号注为准，重复归属（如 杏核仁（杏仁） 与独立条目 杏仁）
    # 各自计数，消费端按列表展示无歧义。
    """
    idx = {}
    for h in herb_forms():
        per = {}
        for seq, body in enumerate(bodies):
            c = sum(body.count(f) for f in set(h["forms"]))
            if c:
                per[seq] = c
        if per:
            idx[h["name"]] = sorted(
                ({"s": s, "n": n} for s, n in per.items()),
                key=lambda x: -x["n"],
            )
    return {"_excluded": [], **idx}


def write_dart(items):
    lines = [
        "/// 《人纪·神农本草经》阅读库索引（由 tool/import_renji_bencao.py 生成，勿手改）。",
        "/// 篇文件 assets/bencao_lecture/NNN_标题.md。",
        "library;",
        "",
        "import 'classic_lecture_data.dart';",
        "",
        "class BenCaoLecture implements LectureIndex {",
        "  @override",
        "  final int seq;",
        "  @override",
        "  final String name;",
        "  @override",
        "  final String asset;",
        "",
        "  const BenCaoLecture({",
        "    required this.seq,",
        "    required this.name,",
        "    required this.asset,",
        "  });",
        "}",
        "",
        "const List<BenCaoLecture> kBenCaoLectures = [",
    ]
    for it in items:
        name = it["name"].replace("'", r"\'")
        lines.append(
            "  BenCaoLecture(seq: %d, name: '%s', asset: '%s'),"
            % (it["seq"], name, it["asset"])
        )
    lines += ["];", ""]
    io.open(DART_OUT, "w", encoding="utf-8", newline="\n").write("\n".join(lines))


def main():
    src_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SRC
    src = io.open(src_path, encoding="utf-8").read()
    os.makedirs(OUT_DIR, exist_ok=True)

    sections = parse(src)
    items = []
    dropped = []
    for title, body in sections:
        md = clean("\n".join(body))
        if len(md) < 20:  # 本经条目正文本来就短（原文明文~50字），只丢近空篇
            dropped.append((title, len(md)))
            continue
        fname = "%03d_%s.md" % (len(items), safe_name(title))
        asset = "assets/bencao_lecture/%s" % fname
        header = "> 倪海厦《人纪·神农本草经》讲稿（书面整理）· 传统文化参考，非医疗建议\n\n"
        io.open(
            os.path.join(OUT_DIR, fname), "w", encoding="utf-8", newline="\n"
        ).write(header + "# %s\n\n%s\n" % (title, md))
        items.append({"seq": len(items), "name": title, "asset": asset})

    write_dart(items)
    # 清孤儿：上一轮遗留旧篇文件一律删除（seq/标题变了文件名就变）
    keep = {os.path.basename(it["asset"]) for it in items} | {"herb_index.json"}
    for f in os.listdir(OUT_DIR):
        if f not in keep:
            os.remove(os.path.join(OUT_DIR, f))
    # 终极兜底：重读盘强清理写回（保证落盘无 B 站链接/URL/时间戳）
    n_fixed = 0
    for it in items:
        p = os.path.join(ROOT, it["asset"])
        t = io.open(p, encoding="utf-8").read()
        t2 = purge(t)
        if t2 != t:
            io.open(p, "w", encoding="utf-8", newline="\n").write(t2)
            n_fixed += 1
    print("兜底清理修正篇数:", n_fixed)

    idx = herb_index(
        [io.open(os.path.join(ROOT, it["asset"]), encoding="utf-8").read()
         for it in items]
    )
    io.open(
        os.path.join(OUT_DIR, "herb_index.json"),
        "w",
        encoding="utf-8",
        newline="\n",
    ).write(json.dumps(idx, ensure_ascii=False, indent=1))

    print("篇数: %d" % len(items))
    print("索引药味数: %d" % (len(idx) - 1))
    if dropped:
        print("丢弃碎篇(%d):" % len(dropped), dropped[:10])
    for it in items[:6]:
        print("  ", it["seq"], it["name"], it["asset"])
    print("  ...")
    for it in items[-4:]:
        print("  ", it["seq"], it["name"])


if __name__ == "__main__":
    main()
