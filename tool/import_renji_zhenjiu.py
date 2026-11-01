# -*- coding: utf-8 -*-
"""把《人纪·针灸》书面整理稿切成讲稿阅读库的篇文件 + 穴位提及索引。

用法：
    python tool/import_renji_zhenjiu.py "D:/nhx/人纪-针灸-倪海厦.txt"

源文件（UTF-8，约 41.7 万字）结构：
  - 大章：`## 第X章 …`（6 个），小节：`### `（39 个，其中第六章 4 个）
  - 第六章「治症系列」正文无 ### 分隔，条目标题形态 =
      `标题文字[（N-HH:MM:SS）](https://www.bilibili.com/...)正文…`（同段，链接夹中间）
  - 全文 323 个 B 站时间戳链接（URL 尾部常粘全角 `）`，是源文件转换瑕疵）

处理：
  1. ### 切篇（#### 并入所属篇正文，保留 #### 标题）；
  2. 第六章按「行首短标题(<=22字) + [（时间戳）](url)」切治症篇；
  3. 删除全部 B 站链接与时间戳标记；
  4. 输出 `assets/zhenjiu_lecture/NN_标题.md`（NN 全局递增，篇名 = `第X章·小节名`）；
  5. 生成 `lib/data/zhenjiu_lecture_data.dart`（照 neijing_lecture_data.dart 模式）；
  6. 生成 `assets/zhenjiu_lecture/acupoint_index.json`：
       { "穴位名": [{"s": 篇seq, "n": 提及次数}], "_excluded": [...] }
     —— 详情页「讲义讲解」与讲稿自动链接共用同一排除名单（单一来源）。

⚠️ 讲义内容增删后必须重跑本脚本 + tool/build_classic_search_index.py。
"""

import io
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT_DIR = os.path.join(ROOT, "assets", "zhenjiu_lecture")
DART_OUT = os.path.join(ROOT, "lib", "data", "zhenjiu_lecture_data.dart")
DEFAULT_SRC = "D:/nhx/人纪-针灸-倪海厦.txt"
ACUPOINT_JSON = os.path.join(ROOT, "assets", "data", "acupoints.json")

# B 站链接：[（时间戳）](url)——源文件瑕疵混杂：URL 尾部常粘全角 `）`、外层圆括号半/全角混用、
# 括号前可能带空格。全部兼容。链接后正文可能同段续写。
_LINK = re.compile(r"\[（[^）\]]*）?\]\s*[(（]https?://[^)\s（）]*[）)]?")
# 第六章治症条目标题行：行首短标题 + 完整链接（标题与正文同段）。
# 注意必须吃掉整个 URL，否则 URL 残段会被当正文留在篇里。
_CH6_TITLE = re.compile(
    r"^([^#\[\]\n]{1,22}?)\s*\[（[^）\]]*）?\]\s*[(（]https?://[^)\s（）]*[）)]?"
)

# ⛔ 排除名单（单一来源，写入 index 的 _excluded，详情页索引与自动链接共用）：
#   太阳  —— 讲稿里「太阳病」「足太阳膀胱经」泛滥，全是误链
#   光明  —— 形容词撞名
#   子宫  —— 解剖语误链；本库已验证只放 3 字形态「子宫穴」（kShortNameLinkForm 同判例）
_EXCLUDED = ["太阳", "光明", "子宫"]
# 子宫的特殊形态：只按 3 字「子宫穴」匹配。
_FORCE_FORM = {"子宫": "子宫穴"}


def purge(text: str) -> str:
    """落盘兜底强清理：一切外链 / URL / B 站字样 / 时间戳，一律不留。

    ⚠️ URL 匹配必须限定字符集（[^\s（）()]+，即可选尾全角括号），
    不能用 \\S+——源文件里 URL 与正文同段无空白分隔（「…?t=3174）稍后会…」），
    \\S+ 会把 URL 后的整段正文一起删掉（v1.11.29 首包实测，篇 35 只剩 444 字）。
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
    # 兜底：裸 URL（bilibili/toutiao 等一切外链）、残留时间戳（N-HH:MM:SS）、
    # 整理者推广行（「学习整理网址：…」）。用户要求：B 站链接/字样/时间戳一律不留。
    text = re.sub(r"https?://\S+|www\.\S+", "", text)
    text = re.sub(r"\d+-\d{2}:\d{2}:\d{2}）?", "", text)
    text = re.sub(r"^.*(网址|链接)[:：].*$", "", text, flags=re.M)
    text = re.sub(r"\n{3,}", "\n\n", text)
    return text.strip()


def parse(src: str):
    """返回 [(大章名, 篇名, 正文md)]，保持原文顺序。"""
    lines = src.split("\n")
    sections = []  # (章名, 篇名, [lines])
    cur_ch = None
    cur_title = None
    cur_body = []

    def flush():
        if cur_title is not None:
            sections.append((cur_ch or "前言", cur_title, cur_body))

    # 逐行扫描：## 大章 / ### 小节 / 第六章治症标题行 / 其余正文
    for ln in lines:
        m_ch = re.match(r"^## (第.+?章.*)$", ln)
        m_sec = re.match(r"^### (.+)$", ln)
        m_sub = re.match(r"^#### (.+)$", ln)
        m_ch6 = _CH6_TITLE.match(ln) if cur_ch and "第六章" in cur_ch else None
        if m_ch:
            flush()
            cur_ch, cur_title, cur_body = m_ch.group(1).strip(), None, []
        elif m_sec:
            flush()
            cur_title = f"{_chap_tag(cur_ch)}·{_strip_num(m_sec.group(1))}"
            cur_body = []
        elif m_ch6:
            flush()
            cur_title = f"{_chap_tag(cur_ch)}·{m_ch6.group(1).strip('（( ')}"
            # 链接之后的同段正文留在本篇
            rest = ln[_CH6_TITLE.match(ln).end():]
            cur_body = [rest] if rest.strip() else []
        elif cur_title is None:
            continue  # 大章标题与首篇之间的闲文
        else:
            if m_sub:
                cur_body.append("#### " + m_sub.group(1).strip())
            else:
                cur_body.append(ln)
    flush()
    return sections


def _chap_tag(ch: str) -> str:
    """'第一章 针灸的使用时机[（1-00:00:14）](…)' → '第一章'"""
    ch = _LINK.sub("", ch).strip()
    m = re.match(r"(第[一二三四五六七八九十]+章)", ch)
    return m.group(1) if m else ch[:4]


def _strip_num(title: str) -> str:
    """'一、 针灸的使用时机[（1-…）](…)' → 去序号、去链接 → '针灸的使用时机'"""
    title = _LINK.sub("", title).strip()
    return re.sub(r"^[一二三四五六七八九十]+、\s*", "", title).strip()


def safe_name(title: str) -> str:
    """篇名 → 文件名安全串。"""
    return re.sub(r"[\\/:*?\"<>|（）()\s、，。·]", "", title)[:40]


def acupoint_index(bodies):
    """扫全部篇正文，统计穴位名出现次数。"""
    data = json.load(io.open(ACUPOINT_JSON, encoding="utf-8"))
    names = sorted(
        {a["name"].replace("穴", "") for a in data["acupoints"]},
        key=len,
        reverse=True,
    )
    index = {}
    used = [n for n in names if n not in _EXCLUDED and n not in _FORCE_FORM]
    used += list(_FORCE_FORM.values())  # 子宫穴（3 字形态）
    # str.count 逐词统计（C 级实现，秒级；alternation 正则在此量级会慢到分钟级）。
    # 注：长词与短词重叠（腹通谷/通谷）各自独立计数，消费端按列表展示无歧义。
    out = {}
    for name in used:
        per = {}
        for seq, body in enumerate(bodies):
            c = body.count(name)
            if c:
                per[seq] = c
        if per:
            out[name] = sorted(
                ({"s": s, "n": n} for s, n in per.items()),
                key=lambda x: -x["n"],
            )
    return {"_excluded": _EXCLUDED, **out}


def write_dart(items):
    lines = [
        "/// 《人纪·针灸》阅读库索引（由 tool/import_renji_zhenjiu.py 生成，勿手改）。",
        "/// 篇文件 assets/zhenjiu_lecture/NN_标题.md。",
        "library;",
        "",
        "import 'classic_lecture_data.dart';",
        "",
        "class ZhenJiuLecture implements LectureIndex {",
        "  @override",
        "  final int seq;",
        "  @override",
        "  final String name;",
        "  @override",
        "  final String asset;",
        "",
        "  const ZhenJiuLecture({",
        "    required this.seq,",
        "    required this.name,",
        "    required this.asset,",
        "  });",
        "}",
        "",
        "const List<ZhenJiuLecture> kZhenJiuLectures = [",
    ]
    for it in items:
        name = it["name"].replace("'", r"\'")
        lines.append(
            "  ZhenJiuLecture(seq: %d, name: '%s', asset: '%s'),"
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
    for seq, (ch, title, body) in enumerate(sections):
        md = clean("\n".join(body))
        if len(md) < 60:  # 空篇/碎篇丢弃
            continue
        fname = "%02d_%s.md" % (seq, safe_name(title))
        asset = "assets/zhenjiu_lecture/%s" % fname
        header = "> 倪海厦《人纪·针灸》讲稿（书面整理）· 传统文化参考，非医疗建议\n\n"
        io.open(
            os.path.join(OUT_DIR, fname), "w", encoding="utf-8", newline="\n"
        ).write(header + "# %s\n\n%s\n" % (title, md))
        items.append({"seq": len(items), "name": title, "asset": asset})

    write_dart(items)
    # 清孤儿：上一轮遗留的旧篇文件（seq/标题变了文件名就变）一律删除，
    # 否则旧文件混在 assets 里进包，且不在索引/dart 清单内。
    keep = {os.path.basename(it["asset"]) for it in items} | {"acupoint_index.json"}
    for f in os.listdir(OUT_DIR):
        if f not in keep:
            os.remove(os.path.join(OUT_DIR, f))
    # 终极兜底：重新读盘、强清理、写回——无论 parse 阶段哪里漏，
    # 落盘文件必须无 B 站链接 / URL / 时间戳（用户硬要求）。
    n_fixed = 0
    for it in items:
        p = os.path.join(ROOT, it["asset"])
        t = io.open(p, encoding="utf-8").read()
        t2 = purge(t)
        if t2 != t:
            io.open(p, "w", encoding="utf-8", newline="\n").write(t2)
            n_fixed += 1
    print("兜底清理修正篇数:", n_fixed)
    idx = acupoint_index(
        [io.open(os.path.join(ROOT, it["asset"]), encoding="utf-8").read()
         for it in items]
    )
    io.open(
        os.path.join(OUT_DIR, "acupoint_index.json"),
        "w",
        encoding="utf-8",
        newline="\n",
    ).write(json.dumps(idx, ensure_ascii=False, indent=1))

    print("篇数: %d" % len(items))
    print("索引穴位数: %d（排除 %s）" % (len(idx) - 1, _EXCLUDED))
    for it in items[:5]:
        print("  ", it["seq"], it["name"], it["asset"])
    print("  ...")
    for it in items[-3:]:
        print("  ", it["seq"], it["name"])


if __name__ == "__main__":
    main()
