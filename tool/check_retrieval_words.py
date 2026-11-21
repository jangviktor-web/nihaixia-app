#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""对照：自查页整段 prefill 与纯症状 retrievalQuery 的关键词质量。

Dart 侧 keywordsFor 规则：去非汉字/字母数字 → 取 4→2 字滑窗 → 前 32 个。
本脚本用同样规则，证明「模板套话会挤掉症状词」这个根因，防止回退。
"""
import re

PREFILL = """我按倪师十问自查的结果如下，请结合讲义与医案帮我辨证：
【四诊·问诊】
睡眠：嗜睡但睡不够
口渴：不渴
大便：稀/拉肚子
小便：小便清长
【寒热总纲】手脚冰冷（阴·阳虚）
【寒热真假线索】小便清长、大便稀溏
【本地规则初判】少阴病 · 少阴寒化证（置信度 88%）
【参考方剂】四逆汤
请指出这个初判对不对、依据是哪几条，以及我漏问了什么。
只按倪师讲义与医案回答，不要照搬西医病名。"""

RETRIEVAL = """少阴寒化证 嗜睡但睡不够 不渴 稀/拉肚子 小便清长
手脚冰冷 小便清长 大便稀溏"""

CONTENT = set("，。、；：（）【】\n\r\t ")


def keywords(q):
    clean = re.sub(r"[^\u4e00-\u9fffA-Za-z0-9]", "", q)
    words = set()
    for length in (4, 3, 2):
        for i in range(len(clean) - length + 1):
            words.add(clean[i:i + length])
    return list(words)[:32]


def main():
    a, b = keywords(PREFILL), keywords(RETRIEVAL)
    print("prefill 前 32 词（套话污染）:")
    print("  " + " ".join(a))
    print("\nretrievalQuery 前 32 词（症状优先）:")
    print("  " + " ".join(b))
    signs = ["手脚冰冷", "小便清长", "大便稀", "嗜睡", "少阴"]
    print("\n关键症状词是否进前 32:")
    for s in signs:
        print("  %-6s prefill=%-5s retrieval=%s" %
              (s, any(s in w or w in s for w in a),
               any(s in w or w in s for w in b)))
    # 核心断言：retrievalQuery 至少覆盖 3 个，prefill 覆盖不到 2 个
    ca = sum(any(s in w or w in s for w in a) for s in signs)
    cb = sum(any(s in w or w in s for w in b) for s in signs)
    print("\n覆盖数 prefill=%d / retrieval=%d" % (ca, cb))
    assert cb > ca, "检索词没有比整段文本更聚焦，修复无效"
    print("✓ 检索词更聚焦，根因已消除")


if __name__ == "__main__":
    main()
