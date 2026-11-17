#!/usr/bin/env python3
"""把天纪讲义里的 HTML <table> 转成 Markdown 管道表。

背景：转录资料里用 HTML 表格画盘面布局（地支脏腑盘 / 先天八卦盘 / 身体部位图），
flutter_markdown 不渲染内嵌 HTML → 用户直接看到原始代码（2026-11-17 用户反馈）。

转换规则：
  - rowspan/colspan 展开成二维网格：主格保留文本，被覆盖格留空
  - 单元格内多个 <p> 用「·」连接（Markdown 表格单元格不能换行）
  - 校验：转换前后「全部单元格文本集合」必须一致，否则该表放弃并报错

用法：
    python tool/html_table_to_md.py            # dry-run
    python tool/html_table_to_md.py --apply    # 写入
"""

import os
import re
import sys
from html.parser import HTMLParser

FILES = [
    os.path.join(os.path.dirname(__file__), "..", "assets", "tianji",
                 "2_紫微斗数十二宫.md"),
    os.path.join(os.path.dirname(__file__), "..", "assets", "tianji",
                 "3_星曜详解.md"),
]

TABLE_RE = re.compile(r"<table>.*?</table>", re.S)
TAG_RE = re.compile(r"<[^>]+>")


class TableParser(HTMLParser):
    """解析单个 <table>：收集 tr 行、每行 td/th 的 (文本, rowspan, colspan)。"""

    def __init__(self):
        super().__init__()
        self.rows = []          # [[(text, rowspan, colspan), ...], ...]
        self._row = None
        self._cell = None       # (buf, rowspan, colspan)

    def handle_starttag(self, tag, attrs):
        a = dict(attrs)
        if tag == "tr":
            self._row = []
        elif tag in ("td", "th") and self._row is not None:
            self._cell = [[], int(a.get("rowspan", 1)), int(a.get("colspan", 1))]
        elif tag == "p" and self._cell is not None:
            if self._cell[0]:
                self._cell[0].append("·")  # 段落间用 · 连接

    def handle_endtag(self, tag):
        if tag == "tr" and self._row is not None:
            if self._row:
                self.rows.append(self._row)
            self._row = None
        elif tag in ("td", "th") and self._cell is not None:
            text = "".join(self._cell[0]).strip()
            self._row.append((text, self._cell[1], self._cell[2]))
            self._cell = None

    def handle_data(self, data):
        if self._cell is not None:
            self._cell[0].append(data.strip())


def expand_grid(rows):
    """rowspan/colspan 展开：主格占位，被覆盖格为空串。返回 text[r][c] 网格。

    行数不能按「各行最大 rowspan 之和」预计算（会把跨两行的中宫算成多一行），
    用全局占用坐标法放置，最后按实际占用的最大行号收尾，纯空行裁掉。
    """
    n_c = max(sum(cs for _, _, cs in row) for row in rows)
    occupied = set()
    grid = {}
    for r, row in enumerate(rows):
        c = 0
        for text, rs, cs in row:
            while (r, c) in occupied:
                c += 1
            for dr in range(rs):
                for dc in range(cs):
                    occupied.add((r + dr, c + dc))
                    if dr == 0 and dc == 0 and text:
                        grid[(r, c)] = text
            c += cs
    n_r = max([len(rows)] + [k[0] + 1 for k in occupied])
    out = [[grid.get((r, c), "") for c in range(n_c)] for r in range(n_r)]
    # 裁全空行与全空列
    out = [row for row in out if any(row)]
    if not out:
        return out
    keep = [c for c in range(n_c) if any(row[c] for row in out)]
    return [[row[c] for c in keep] for row in out]


def cells_text(rows):
    return sorted(t for row in rows for t, _, _ in row if t)


def md_table(rows):
    grid = expand_grid(rows)
    head, *body = grid
    lines = ["| " + " | ".join(head) + " |",
             "| " + " | ".join("---" for _ in head) + " |"]
    for row in body:
        lines.append("| " + " | ".join(row) + " |")
    return "\n".join(lines)


def convert(text):
    out = []
    last = 0
    checked = 0
    for m in TABLE_RE.finditer(text):
        p = TableParser()
        p.feed(m.group(0))
        p.close()
        before = cells_text(p.rows)
        md = md_table(p.rows)
        # 校验：Markdown 表里提取的单元格文本与解析结果一致（注意剥两侧空格）
        after = sorted(
            c.strip() for line in md.split("\n") if not set(line) <= set("|- ")
            for c in line.strip().strip("|").split("|") if c.strip())
        if before != after:
            raise SystemExit(f"✗ 表格校验失败（内容不一致）：{before[:4]}…")
        out.append(text[last:m.start()])
        out.append(md)
        last = m.end()
        checked += 1
    out.append(text[last:])
    return "".join(out), checked


def main():
    apply = "--apply" in sys.argv
    for path in FILES:
        raw = open(path, encoding="utf-8").read()
        new, n = convert(raw)
        print(f"{os.path.basename(path)}: 转换 {n} 个表格"
              f"{'  [已写入]' if apply else '  (dry-run)'}")
        if apply:
            open(path, "w", encoding="utf-8", newline="\n").write(new)


if __name__ == "__main__":
    main()
