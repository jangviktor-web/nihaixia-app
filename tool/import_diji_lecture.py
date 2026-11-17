#!/usr/bin/env python3
"""把《倪師地紀8篇全.md》导入为天纪讲义的第 10 篇（assets/tianji/13_地纪游记.md）。

内容：倪师「地纪之旅」实地游记——按日期记录走访西安 / 华山 / 汉中 / 武当山 /
桂林阳朔等地的风水地理见闻，与现有「地脉道」理论讲义互补（理论 + 实地）。

处理：
  1. OpenCC t2s 转简体（App 资产规范：存简体，阅读时再转繁）
  2. 层级归一：原文 h1/h2 混用 → 统一为 `####`（分组），日期行前插 `#####`（子节）
     与星曜详解「北斗星系 → 紫微星」的两级结构一致
  3. 节标题手工拟定（日期 + 当日主题），18 条映射见 DATE_TITLES
  4. 明显 OCR 误录修正（只收形近字铁证：Ⅰ/丨 是罗马数字与竖线，非「一」）

依赖：pip install opencc-python-reimplemented

⚠️ 源文件变动后重跑：python tool/import_diji_lecture.py
"""

import os
import re
import sys

from opencc import OpenCC

SRC = "D:/nhx/倪海厦/地纪/倪師地紀8篇全.md"
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "tianji",
                   "13_地纪游记.md")

# 明显 OCR 误录。只收形近字铁证（Ⅰ=罗马数字 I、丨=竖线 U+4E28），
# 与天纪字幕的 FIXUPS 同原则：拿不准的不动。
OCR_FIXES = [
    ("Ⅰ代名将", "一代名将"),
    ("华山丨游", "华山一游"),
]

# 日期 → 当日主题。标题是内容摘要（人工拟定，与讲义「人工核过」标准一致）。
DATE_TITLES = {
    "12/07": "出发寻访经方家",
    "12/10": "九华山礼地藏菩萨",
    "12/15": "成都四大药市",
    "12/16": "青城山道教圣地",
    "12/18": "再访峨眉山",
    "6/11": "西安小雁塔与大雁塔",
    "6/12": "骊山明圣宫",
    "6/13": "旧长安城汉宫遗址",
    "6/14": "咸阳博物馆与霍去病墓",
    "6/15": "秦二世胡亥墓",
    "6/16": "初登华山遇雨",
    "6/17": "黄帝陵败兴而归",
    "6/18": "唐太宗昭陵",
    "6/19": "穿越秦岭赴汉中",
    "6/20": "汉中圣水寺汉桂",
    "6/21": "汉武帝茂陵",
    "6/22": "陕西历史博物馆",
    "6/23": "再登华山",
}

DATE = re.compile(r"^(\d{1,2}/\d{1,2})")

# 编者注（非倪师原文，必须用 blockquote 且明确标注）。12/07 原文的「XX」是
# 倪师本人刻意保密的药名，汉唐网站流传原文同样保留 XX；但《唐本草》对紫参
# 「皮紫黑，肉红白，肉浅皮深」的记载与本文「外皮黑色、中间鲜红」的饮片外观
# 吻合，经方紫参汤 / 泽漆汤即用此药，倪师在《金匮》讲课中曾误以为失传。
# 补注信息来源：汉唐地纪系列原文 + 2026-11-17 联网核查（多源一致）。
EDITOR_NOTES = {
    "12/10": """
> 编者注：上一节（12/07）原文中的「XX」为倪师本人刻意保密的药名（原文写明
> 「我必须将之保密，否则一旦公开，药价必将水涨船高」），汉唐网站流传原文
> 同样保留 XX，此处不作替换。据《唐本草》紫参「皮紫黑，肉红白，肉浅皮深」
> 的记载与文中「外皮黑色、中间鲜红」的饮片外观对照，此药即**紫参**
> （一名拳参，《神农本草经》一名牡蒙）。经方紫参汤（紫参半斤、甘草三两，
> 《金匮》治「下利肺痛」）与泽漆汤（紫参五两）所用即此药；倪师在《金匮要略》
> 讲课中曾误以为紫参已失传，此行于亳州药市寻得。本注为整理者所加，非倪师原文。
""",
}


def main():
    raw = open(SRC, encoding="utf-8").read()
    text = OpenCC("t2s").convert(raw)

    fixed_total = 0
    for wrong, right in OCR_FIXES:
        n = text.count(wrong)
        if n:
            text = text.replace(wrong, right)
            fixed_total += n
            print(f"  [ocr] {wrong} → {right}（{n} 处）")

    out = ["## 地纪游记"]
    uncovered = []
    for line in text.split("\n"):
        t = line.strip()
        if re.match(r"^#{1,6}\s", t) and not DATE.match(t):
            # h1/h2 → h4 分组（忽略原编号，篇标题由 we 重写）
            name = re.sub(r"^#{1,6}\s*", "", t)
            if name == "地纪日志" or name in ("塞内与塞外", "武当山", "桂林阳朔行"):
                out.append(f"#### {name}")
            elif name == "陕西之旅":
                out.append("#### 陕西之旅")
            # 其余标题（如正文里夹杂的 # 行）丢弃，避免层级混乱
            continue
        m = DATE.match(t)
        if m and m.group(1) in DATE_TITLES:
            out.append(f"##### {m.group(1)} {DATE_TITLES[m.group(1)]}")
        elif m:
            uncovered.append(t[:30])
        out.append(line)  # 原文行保留（标题行已在上面 continue）

    if uncovered:
        raise SystemExit("✗ 存在未拟定标题的日期条目，请补 DATE_TITLES：" +
                         "; ".join(uncovered))

    body = "\n".join(out)
    body = re.sub(r"\n{3,}", "\n\n", body)  # 压多余空行
    # 编者注插到对应节的标题之前（挂在下一节的标题上，即上一节的末尾）
    for anchor, note in EDITOR_NOTES.items():
        pat = re.compile(rf"^##### {re.escape(anchor)}\s", re.M)
        if not pat.search(body):
            raise SystemExit(f"✗ 编者注锚点「{anchor}」未找到")
        body = pat.sub(lambda m: note.strip("\n") + "\n\n" + m.group(0), body, count=1)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    open(OUT, "w", encoding="utf-8", newline="\n").write(body)
    print(f"[OK] 写入 {os.path.relpath(OUT, os.path.dirname(__file__) + '/..')}  "
          f"{len(body)} 字  OCR 修正 {fixed_total} 处")


if __name__ == "__main__":
    main()
