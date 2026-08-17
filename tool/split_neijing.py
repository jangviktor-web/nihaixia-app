# -*- coding: utf-8 -*-
"""拆分《人纪·黄帝内经》文稿为 81 篇 + 前言 assets/neijing/*.md"""
import re, os

SRC = 'D:/Desktop/人纪-黄帝内经-倪海厦（原视频文稿）.md'
OUT = 'assets/neijing'
os.makedirs(OUT, exist_ok=True)

t = open(SRC, encoding='utf-8', newline='').read().replace('\r\n', '\n')
lines = t.split('\n')

FMT = re.compile(r'^## 第([一二三四五六七八九十百]+)篇\s*(\S+)')
CN = {'一':1,'二':2,'三':3,'四':4,'五':5,'六':6,'七':7,'八':8,'九':9,'十':10,
      '十一':11,'十二':12,'十三':13,'十四':14,'十五':15,'十六':16,'十七':17,
      '十八':18,'十九':19,'二十':20,'二十一':21,'二十二':22,'二十三':23,'二十四':24,
      '二十五':25,'二十六':26,'二十七':27,'二十八':28,'二十九':29,'三十':30,
      '三十一':31,'三十二':32,'三十三':33,'三十四':34,'三十五':35,'三十六':36,
      '三十七':37,'三十八':38,'三十九':39,'四十':40,'四十一':41,'四十二':42,
      '四十三':43,'四十四':44,'四十五':45,'四十六':46,'四十七':47,'四十八':48,
      '四十九':49,'五十':50,'五十一':51,'五十二':52,'五十三':53,'五十四':54,
      '五十五':55,'五十六':56,'五十七':57,'五十八':58,'五十九':59,'六十':60,
      '六十一':61,'六十二':62,'六十三':63,'六十四':64,'六十五':65,'六十六':66,
      '六十七':67,'六十八':68,'六十九':69,'七十':70,'七十一':71,'七十二':72,
      '七十三':73,'七十四':74,'七十五':75,'七十六':76,'七十七':77,'七十八':78,
      '七十九':79,'八十':80,'八十一':81}

docs = []
cur = None
for ln in lines:
    m = FMT.match(ln)
    if m:
        seq = CN.get(m.group(1), 99)
        name = m.group(2).strip()
        if any(d[0] == seq for d in docs):
            cur = next(d for d in docs if d[0] == seq)
            cur[2].append('')
            cur[2].append('## （补录）' + ln[3:])
            continue
        cur = [seq, name, ['# 第%s篇 %s' % (m.group(1), name), '']]
        docs.append(cur)
        continue
    if ln.startswith('## 前言'):
        cur = [0, '前言', ['# 前言', '']]
        docs.append(cur)
        continue
    if ln.startswith('## 第') and ('，' in ln or '。' in ln):
        ln = ln[3:]
    if cur is not None:
        cur[2].append(ln)


def clean(ls):
    out = []
    blank = 0
    for l in ls:
        s = l.rstrip()
        if not s.strip():
            blank += 1
            if blank > 1:
                continue
        else:
            blank = 0
        out.append(s)
    return '\n'.join(out).strip() + '\n'


idx = []
for seq, name, ls in sorted(docs, key=lambda d: d[0]):
    fname = '00_前言.md' if seq == 0 else '%02d_%s.md' % (seq, name)
    for ch in '/\\:*?"<>|':
        fname = fname.replace(ch, '_')
    body = clean(ls)
    with open(os.path.join(OUT, fname), 'w', encoding='utf-8', newline='\n') as f:
        f.write(body)
    idx.append({'seq': seq, 'name': name, 'file': fname, 'chars': len(body)})

print('篇数:', len(idx))
for d in idx[:5]:
    print(' ', d)
print('  ...')
for d in idx[-3:]:
    print(' ', d)
total = sum(d['chars'] for d in idx)
print('总字符:', total)
fn = [d['file'] for d in idx]
assert len(fn) == len(set(fn)), '文件名重复!'
print('文件名唯一 OK')
