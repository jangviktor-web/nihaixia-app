import json, re

doc = open("zhenjiu_doc.md", encoding="utf-8", errors="ignore").read()
lines = doc.splitlines()

# Build per-point doc body chunks: text between a heading that names the point and the next heading.
def norm(s): return s.strip().rstrip("穴").strip()
def clean(t):
    t = re.sub(r"\[[^\]]*\]", "", t)                 # link text
    t = re.sub(r"\(https?://[^)]*\)", "", t)         # url
    t = re.sub(r"（[^）]*[0-9][^）]*）", "", t)       # timestamp paren
    t = re.sub(r"[【】]", "", t)
    t = re.sub(r"\s+", "", t)
    return t

# collect headings with their line index
heads = []
for i, l in enumerate(lines):
    s = l.strip()
    if s.startswith("#### ") or s.startswith("##### "):
        heads.append((i, s))

# For each heading, the body is lines[hi+1 : next_head_line]
chunks_by_point = {}
for idx, (hi, htxt) in enumerate(heads):
    nxt = heads[idx+1][0] if idx+1 < len(heads) else len(lines)
    body = "".join(lines[hi+1:nxt])
    body = clean(body)
    # extract candidate point names from heading
    hc = clean(htxt)
    hc = re.sub(r"^#+?\s*\d+\.?\s*", "", hc)
    for part in re.split(r"[。、，,和 与—－\-:：·\t]", hc):
        p = part.strip().strip("①②③④⑤⑥⑦⑧⑨").strip()
        for cut in ["之", "—", "－", "-"]:
            if cut in p: p = p.split(cut)[-1]
        p = p.strip().rstrip("穴").strip()
        if 2 <= len(p) <= 4 and p not in ("奇穴",):
            chunks_by_point.setdefault(p, []).append(body)

# field extractors
NOISE = ["典故", "祖师爷", "扁鹊", "因为", "为什么", "话说", "举例", "故事"]

def first_sentence(chunk, maxlen=120):
    # take leading non-empty run, cut at 。 or period
    chunk = chunk.strip()
    m = re.split(r"[。！？]", chunk)
    for seg in m:
        seg = seg.strip()
        if len(seg) >= 6 and not any(b in seg for b in NOISE):
            return seg[:maxlen]
    return ""

def kw_sentence(chunk, kws):
    for seg in re.split(r"[。！？]", chunk):
        if any(k in seg for k in kws) and not any(b in seg for b in NOISE):
            return seg.strip()[:120]
    return ""

d = json.load(open("assets/data/acupoints.json", encoding="utf-8"))
aps = d["acupoints"]

# pre-clear any field containing noise tokens so they get re-extracted cleanly
for a in aps:
    for k in ["description", "needling", "moxibustion", "contraindication"]:
        if any(b in str(a.get(k, "")) for b in NOISE):
            a[k] = ""

filled_desc = filled_need = filled_mox = filled_con = 0
for a in aps:
    nm = norm(a["name"])
    chunks = chunks_by_point.get(nm, [])
    if not chunks:
        # try raw name
        chunks = chunks_by_point.get(a["name"], [])
    if not chunks:
        continue
    text = "".join(chunks)

    # description: fill only if currently short
    if len(str(a.get("description", "")).strip()) < 40:
        s = first_sentence(text)
        if s and len(s) >= 8:
            a["description"] = s
            filled_desc += 1

    # needling
    if not str(a.get("needling", "")).strip():
        s = kw_sentence(text, ["针", "刺", "斜刺", "直刺", "沿皮", "平刺"])
        if s:
            a["needling"] = s
            filled_need += 1

    # moxibustion
    if not str(a.get("moxibustion", "")).strip():
        s = kw_sentence(text, ["灸", "壮", "艾"])
        if s:
            a["moxibustion"] = s
            filled_mox += 1

    # contraindication
    if not str(a.get("contraindication", "")).strip():
        s = kw_sentence(text, ["禁", "慎", "不可", "孕妇", "出血", "动脉", "延髓"])
        if s:
            a["contraindication"] = s
            filled_con += 1

json.dump(d, open("assets/data/acupoints.json", "w", encoding="utf-8"), ensure_ascii=False, indent=2)

# report coverage
n = len(aps)
def rate(k): 
    nonempty = sum(1 for a in aps if str(a.get(k, "")).strip())
    return nonempty, 100*nonempty/n
for k in ["description", "needling", "moxibustion", "contraindication", "location", "clinicalNotes"]:
    c, p = rate(k)
    print(f"{k:14s}: {c}/{n} ({p:.0f}%)  [this pass +{filled_desc if k=='description' else filled_need if k=='needling' else filled_mox if k=='moxibustion' else filled_con if k=='contraindication' else 0} new]")
print("\nthis-pass fills -> desc:%d needling:%d moxibustion:%d contraindication:%d" % (filled_desc, filled_need, filled_mox, filled_con))
