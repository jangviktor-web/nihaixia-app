#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成 App 用「古今病名 / 中西医病名」对照索引。

用法：
    D:/Python310/python.exe tool/build_disease_alias_index.py
    D:/Python310/python.exe tool/build_disease_alias_index.py --audit   # 只看候选，不写文件

设计（与 formula_index 同一套纪律）：
- SEEDS 只提供「候选关系」（古名 ↔ 今名/西医名），**note 与出处全部从倪师材料自动截取**，
  不接受手写解释句 —— 保证「从倪师材料整理」不是一句口号。
- 证据门禁：每条种子必须在材料里找到「古名与现代名共现 + 对齐线索词」的原文窗口，
  找不到就丢弃并打印（宁缺勿造）。verify() 在写盘前再复核一遍。
- 同时输出 tool/disease_alias_candidates.tsv：自动发现的对照候选，供人工复核后并入 SEEDS。

材料来源：assets/{shanghan,jingui,neijing,bencao_lecture,zhenjiu_lecture}/*.md
          + assets/medical_cases/cases_table.md（1258 例医案）
"""
import io
import json
import os
import re
import sys
import glob

OUT = 'assets/data/disease_alias_index.json'
CAND = 'tool/disease_alias_candidates.tsv'
LECTURE_DIRS = ['shanghan', 'jingui', 'neijing', 'bencao_lecture', 'zhenjiu_lecture']

# ---------------------------------------------------------------- 材料载入
def load_docs():
    docs = {}
    for d in LECTURE_DIRS:
        for f in sorted(glob.glob(f'assets/{d}/*.md')):
            docs[f.replace('\\', '/')] = io.open(f, encoding='utf-8', errors='ignore').read()
    docs['medical_cases/cases_table.md'] = io.open(
        'assets/medical_cases/cases_table.md', encoding='utf-8', errors='ignore').read()
    return docs

# ---------------------------------------------------------------- 对齐线索
# 「A 就是 B」「西医叫 B」「近似于现代的 B」这类句式才认，避免同段落碰巧共现被误判。
VERB = re.compile(
    r'就是|即|近似于|近似|相当于|类似|等同|等于|叫做|叫|称为|称|所谓的|所谓'
    r'|西医(?:可能)?(?:叫|称|讲|说|认为)|现代|现在|今日|中医(?:就)?(?:叫|称|讲)')
# 同段共现不等于对齐：句子里必须真的出现「对齐」动作词
STRONG = re.compile(r'就是|即|近似于|相当于|类似|等同|等于|叫做|称为|西医(?:可能)?(?:叫|称|讲|说)|中医(?:就)?(?:叫|称|讲)')

SPLIT = re.compile(r'[。！？；\n]')

def clip_sentence(text, lo, hi, ancient, modern):
    """对齐证据：返回 (note 句, 强度)。

    强度 2 = 同一句里古名与现代名共现（最优）；
    强度 1 = 现代名所在句与古名所在句相邻（倪师口语常拆两句讲）。
    note 一律取**原文整句**，不改写、不拼接。
    """
    start = text.rfind('\n', 0, lo)
    start = 0 if start < 0 else start + 1
    end = text.find('\n', hi)
    end = len(text) if end < 0 else end
    para = text[start:end]
    if ancient not in para or modern not in para:
        return ('', 0)
    # 除了句末标点，markdown 列表项（- 开头）也要断句：
    # 讲稿大量内容是「- xxx」逐条列，若不按行切，整段会变成一个超长"句子"，
    # 长度排序失效，note 会挑到无关的长段落。
    sents = [x.strip() for x in re.split(r'(?<=[。！？；])|\n', para) if x.strip()]
    cands = []
    for i, s in enumerate(sents):
        if modern not in s or not STRONG.search(s):
            continue
        same = ancient in s
        near = same or (i > 0 and ancient in sents[i - 1]) or \
               (i + 1 < len(sents) and ancient in sents[i + 1])
        if not near:
            continue
        cands.append((0 if same else 1, len(s), s))
    if not cands:
        return ('', 0)
    cands.sort()
    strength, _, sent = cands[0]
    return (sent, 2 if strength == 0 else 1)

def find_evidence(docs, ancient, moderns):
    """返回 [(file, sentence, modern, level)]：同句/邻句共现 + 含对齐动词才算证据。"""
    out = []
    for name, text in docs.items():
        if ancient not in text:
            continue
        for modern in moderns:
            if modern == ancient or modern not in text:
                continue
            hits_here = 0
            for m in re.finditer(re.escape(modern), text):
                lo, hi = m.start(), m.end()
                # 以 modern 为中心取 ±200 字窗口，窗口内需出现古名
                a = max(0, lo - 200)
                b = min(len(text), hi + 200)
                if ancient not in text[a:b]:
                    continue
                sent, level = clip_sentence(text, a, b, ancient, modern)
                if not sent:
                    continue
                out.append((name, sent, modern, level))
                hits_here += 1
                if hits_here >= 3:
                    break
    # 去重（同文件同句只留一次）
    seen = set()
    uniq = []
    for name, sent, modern, level in out:
        k = (name, sent)
        if k in seen:
            continue
        seen.add(k)
        uniq.append((name, sent, modern, level))
    return uniq

def note_from(sentence, ancient, modern, limit=72):
    """note 直接取原文句：优先以对齐动词为锚，把古名与今名都包进去。

    只做「去掉引用块/markdown 标记」的清理（> - * 」 等），不改写任何字词。
    """
    s = re.sub(r'^[\s>\-*·」』，,、：]+', '', sentence.strip())
    s = re.sub(r'\s+$', '', s)
    if not s:
        return ''
    if len(s) <= limit:
        return s
    # 超长就截古名/今名前后能对上的最短片段
    ia = s.find(ancient)
    im = s.find(modern)
    if ia >= 0 and im >= 0:
        lo = max(0, min(ia, im) - 8)
        hi = min(len(s), max(ia + len(ancient), im + len(modern)) + 24)
        seg = s[lo:hi]
        return seg if len(seg) <= limit else seg[:limit] + '…'
    return s[:limit] + '…'

# ---------------------------------------------------------------- 种子表
# (古名/中医名, [今名/西医名], [别名], kind)
#   kind = 'gujin'  古今病名差异（古书用名 → 今天的病名）
#   kind = 'zhongxi' 中西医叫法（中医证候/概念 → 西医术语）
# ⚠️ 这里只写「候选关系」，能不能进产品由材料证据决定。
SEEDS = [
    # ---- 古今病名（伤寒 / 金匮 / 内经用名 → 今天的病名）----
    ('消渴', ['糖尿病'], ['消瘅'], 'gujin'),
    ('疟病', ['疟疾'], ['疟'], 'gujin'),
    ('历节', ['类风湿性关节炎', '痛风'], ['历节风'], 'gujin'),
    ('百合病', ['神经衰弱症', '厌食症'], [], 'gujin'),
    ('肺痿', ['肺萎缩', '肺纤维化'], [], 'gujin'),
    ('肺痈', ['肺炎', '肺脓疡'], [], 'gujin'),
    ('肠痈', ['盲肠炎', '腹膜炎'], ['阑尾炎'], 'gujin'),
    ('痉', ['脑膜炎', '脑脊髓神经炎'], ['刚痉', '柔痉'], 'gujin'),
    ('暍', ['中暑'], ['中暍'], 'gujin'),
    ('霍乱', ['上吐下泻', '食物中毒'], [], 'gujin'),
    ('寒疝', ['疝气'], [], 'gujin'),
    ('中风', ['脑中风'], [], 'gujin'),
    ('风湿', ['风湿关节炎'], [], 'gujin'),
    ('湿痹', ['关节炎'], ['中湿'], 'gujin'),
    ('水气', ['水肿'], [], 'gujin'),
    ('黄疸', ['肝炎', '急性肝炎', '猛爆性肝炎'], ['黄瘅'], 'gujin'),
    ('蛔虫', ['寄生虫'], ['蛔厥'], 'gujin'),
    ('狐惑', ['寄生虫'], [], 'gujin'),
    ('症瘕', ['肿瘤'], ['瘕聚'], 'gujin'),
    ('藏燥', ['子宫萎缩'], ['脏躁'], 'gujin'),
    ('宿食', ['陈旧的食物'], [], 'gujin'),
    ('带下', ['白带'], [], 'gujin'),
    ('胸痹', ['心脏病', '风湿性心脏病'], ['胸痹缓急'], 'gujin'),
    ('支饮', ['胸水'], [], 'gujin'),
    ('悬饮', ['浆液性肋膜炎'], [], 'gujin'),
    ('痰饮', ['慢性胃病'], ['饮病'], 'gujin'),
    ('肺胀', ['肺气肿'], [], 'gujin'),
    ('转筋', ['抽筋'], [], 'gujin'),
    ('浸淫疮', ['湿疹'], [], 'gujin'),
    ('鼻渊', ['鼻窦炎'], [], 'gujin'),
    ('喉痹', ['咽炎'], [], 'gujin'),
    ('乳痈', ['乳腺炎'], [], 'gujin'),
    ('崩漏', ['子宫出血'], [], 'gujin'),
    ('脾约', ['便秘'], [], 'gujin'),
    ('瘿', ['甲状腺'], [], 'gujin'),
    ('痔', ['痔疮'], [], 'gujin'),
    ('积聚', ['肿瘤'], [], 'gujin'),
    # —— 以下由 tool/disease_alias_candidates.tsv 人工复核后并入（每条都有原文）——
    # 「中医讲乳痈就是乳癌」/「乳痈、乳癌，中医叫做乳岩」
    ('乳痈', ['乳癌'], [], 'gujin'),
    ('乳岩', ['乳癌'], [], 'gujin'),
    # 「中医叫天疱疮，也属浸淫疮」
    ('浸淫疮', ['天疱疮'], [], 'gujin'),
    # 「中医称为瘰历，西医讲的甲状腺功能亢进」
    ('瘰历', ['甲状腺功能亢进'], ['瘰疬'], 'gujin'),
    # 「中医叫脺肉，西医叫做胰脏」
    ('脺肉', ['胰脏'], [], 'zhongxi'),
    # 「喝酒以后吹到风，这个中医称为漏风」（迎风流泪）
    ('漏风', ['流眼泪'], [], 'gujin'),
    # 「阳往上走的症状，西医称为脑充血」
    ('浮阳', ['脑充血'], [], 'zhongxi'),
    # 「宿食阻塞在这个地方，这就中医叫做宿垢」
    ('宿垢', ['宿食'], [], 'gujin'),

    # ---- 中西医叫法（中医证候/概念 → 西医术语）----
    ('心下痞', ['肠胃炎'], ['痞证'], 'zhongxi'),
    ('脉结代', ['心律不整'], ['心动悸'], 'zhongxi'),
    ('温经汤证', ['子宫内膜异位'], [], 'zhongxi'),
    ('心包', ['心囊'], [], 'zhongxi'),
    ('浮阳', ['免疫系统'], [], 'zhongxi'),
    ('孙络', ['微血管'], [], 'zhongxi'),
    ('淋家', ['淋病', '性病'], [], 'zhongxi'),
    ('石淋', ['膀胱结石', '肾结石'], [], 'zhongxi'),
    ('脓血', ['大肠癌', '大肠炎'], ['脓血利'], 'zhongxi'),
    ('晕眩', ['中耳不平衡'], [], 'zhongxi'),
    ('胃寒', ['胃下垂'], [], 'zhongxi'),
    ('痹', ['麻木不仁'], ['血痹', '风痹'], 'zhongxi'),
]

# ---------------------------------------------------------------- 自动发现（留痕）
AUTO = [
    ('西醫叫', re.compile(r'西医(?:可能)?(?:叫|称|讲|说|称为|叫做)(?:它)?[「『"]?([^」』"，。；、\)]{2,14})')),
    ('中醫叫', re.compile(r'中医(?:就)?(?:叫|称|讲|称为|叫做)(?:做)?[「『"]?([^」』"，。；、\)]{2,14})')),
    ('近似於', re.compile(r'(?:近似于|相当于|类似于)[「『"]?(?:现代|现在|今日)?(?:的)?[「『"]?([^」』"，。；、\)]{2,14})')),
    ('就是現在', re.compile(r'就是(?:现在|现代)(?:的)?[「『"]?([^」』"，。；、\)]{2,14})')),
]

def write_candidates(docs):
    rows = {}
    for name, text in docs.items():
        for tag, pat in AUTO:
            for m in pat.finditer(text):
                v = m.group(1).strip()
                if len(v) < 2 or len(v) > 14:
                    continue
                a = max(0, m.start() - 50)
                b = min(len(text), m.end() + 10)
                ctx = text[a:b].replace('\n', ' ').strip()
                rows.setdefault((tag, v), ctx)
    with io.open(CAND, 'w', encoding='utf-8', newline='\n') as f:
        f.write('类型\t命中词\t上下文（供人工复核，勿直接入库）\n')
        for (tag, v), ctx in sorted(rows.items()):
            f.write(f'{tag}\t{v}\t{ctx}\n')
    return len(rows)

# ---------------------------------------------------------------- 主流程
def build(docs):
    entries = []
    dropped = []
    for ancient, moderns, aliases, kind in SEEDS:
        ev = find_evidence(docs, ancient, moderns)
        if not ev:
            dropped.append((ancient, moderns, '材料中找不到对齐原文'))
            continue
        # 门禁：至少一条「古名与现代名同句」的证据；只有邻句证据的要够 2 条，
        # 否则说明只是同段碰巧提到，不是倪师真的对过这两个名。
        strong = [e for e in ev if e[3] == 2]
        if not strong and len(ev) < 2:
            dropped.append((ancient, moderns, '只有 1 条邻句证据，不足以下结论'))
            continue
        # 命中的 modern 去重（只保留真有证据的现代名）
        hit_moderns = []
        for _, _, mo, _ in ev:
            if mo not in hit_moderns:
                hit_moderns.append(mo)
        # note 优先取同句证据里最短的一条（最贴近对齐句式），
        # 并把它所在的文件放在 src 首位，verify 才能逐字节复核。
        pool = strong if strong else ev
        ev_sorted = sorted(pool, key=lambda e: (e[3] != 2, len(e[1])))
        name0, sent0, mo0, _lv = ev_sorted[0]
        srcs = [name0] + sorted({e[0] for e in ev if e[0] != name0})
        entries.append({
            'a': ancient,
            'm': hit_moderns,
            'al': aliases,
            'k': kind,
            'note': note_from(sent0, ancient, mo0).replace('\n', ' '),
            'src': srcs[:3],
            'n': len(ev),
        })
    return entries, dropped


def verify(entries, docs):
    """写盘前复核：note 必须是来源文件里的原文（空白归一后包含），否则拒写。"""
    def norm(s):
        return re.sub(r'\s+', '', s.replace('…', ''))
    bad = []
    seen_ancient = {}
    for e in entries:
        n = norm(e['note'])
        ok = any(s in docs and n and n in norm(docs[s]) for s in e['src'])
        if not ok:
            bad.append((e['a'], 'note 未能在来源中找到原文'))
        for mo in e['m']:
            if not any(mo in docs[s] for s in e['src']):
                bad.append((e['a'], f'现代名「{mo}」不在来源文件中'))
        # 古名撞车会让【病名对照】块出现两条同名，语义还会互相打架，必须合并种子
        if e['a'] in seen_ancient:
            bad.append((e['a'], f"古名重复（另一条现代名 {seen_ancient[e['a']]}），请合并种子"))
        seen_ancient[e['a']] = e['m']
    return bad


def main():
    audit = '--audit' in sys.argv
    docs = load_docs()
    entries, dropped = build(docs)
    bad = verify(entries, docs)

    print(f'材料文件 {len(docs)} 个')
    print(f'种子 {len(SEEDS)} 条 → 有原文证据 {len(entries)} 条 / 丢弃 {len(dropped)} 条')
    for a, m, why in dropped:
        print(f'  [丢弃] {a} → {"/".join(m)}：{why}')
    if bad:
        print('!! verify 失败：')
        for a, why in bad:
            print(f'  {a}：{why}')
        sys.exit(1)

    by_kind = {}
    for e in entries:
        by_kind[e['k']] = by_kind.get(e['k'], 0) + 1
    print('分类：', by_kind)

    n_cand = write_candidates(docs)
    print(f'自动发现候选 {n_cand} 条 → {CAND}（人工复核后再并入 SEEDS）')

    if audit:
        for e in entries[:200]:
            print(f"  {e['a']} → {'/'.join(e['m'])}  [{e['n']}]  {e['note'][:60]}")
        return

    payload = {'_v': 1, 'entries': entries}
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with io.open(OUT, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(payload, f, ensure_ascii=False, separators=(',', ':'))
    size = os.path.getsize(OUT)
    print(f'写入 {OUT}：{len(entries)} 条 / {size} 字节')


if __name__ == '__main__':
    main()
