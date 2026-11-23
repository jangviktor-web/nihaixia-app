# -*- coding: utf-8 -*-
"""名称归一：formulas.json(314) vs 规则表(171)，输出准确的无规则方清单。

判定顺序：同名 → alias 字段 → 异体字归一 → 人工异名表 → 剂型后缀（仅提示，算缺口）。
另把「倪师经验方/后世方」单列——它们不该有六经问诊规则。
"""
import io, json, re, sys
from collections import Counter

sys.stdout.reconfigure(encoding='utf-8')

src = io.open('lib/engine/formula_rules.dart', encoding='utf-8').read()
RULE = [n for n in re.findall(r"name: '([^']+)'", src)]
RULE_N = {n for n in RULE}

# 异体字（蟅/蛰/䗪、耆/芪 等）
VARIANT = [('蟅', '䗪'), ('蛰', '䗪'), ('耆', '芪'), ('黄蓍', '黄芪'),
           ('慧苡', '薏苡'), ('栝篓', '栝蒌'), ('杏子', '杏仁')]

def norm(x):
    x = x.strip().replace('（', '(').replace('）', ')')
    x = re.sub(r'\(.*?\)', '', x)
    for a, b in VARIANT:
        x = x.replace(a, b)
    return x

# 人工确认的「同方异名」（库里的名字 → 规则表里的名字）
MANUAL = {
    '桂枝加芍药生姜各一两人参三两新加汤': '桂枝新加汤',
    '大黄牡丹皮汤': '大黄牡丹汤',
    '蜜煎方': '蜜煎导猪胆汁导',
    '茯苓桂枝甘草大枣汤': '苓桂枣甘汤',
    '苓桂甘枣汤': '苓桂枣甘汤',
    '甘草干姜茯苓白术汤': '甘姜苓术汤',
    '土瓜根方': '土瓜根散',
    '旋覆代赭石汤': '旋覆代赭汤',
    '麻杏甘石汤': '麻杏石甘汤',
    '葛根黄芩黄连汤': '葛根芩连汤',
    '栀子干姜豉汤': '栀子干姜汤',
    '蒲灰散': '蒲灰散滑石白鱼散茯苓戎盐汤',
    '滑石白鱼散': '蒲灰散滑石白鱼散茯苓戎盐汤',
    '茯苓戎盐汤': '蒲灰散滑石白鱼散茯苓戎盐汤',
}

# 明确「不同方」，不许被剂型后缀误并
DISTINCT = {'猪苓散', '文蛤汤', '矾石丸', '矾石汤', '附子散'}

# 倪师经验方 / 后世方（不该有六经问诊规则）
# 名字带「方」但确属仲景原文方，不算经验方
TRADITIONAL = {'猪胆汁方', '百合洗方', '雄黄熏方', '甘草汤', '桔梗汤',
               '半夏散及汤', '苦酒汤'}

def is_empirical(name, category=''):
    # formulas.json 自己标了「倪海厦经验方」的一律算（术附汤等不带「方」字，
    # 光看名字会漏判成仲景原文方）。
    if category == '倪海厦经验方':
        return True
    if name in TRADITIONAL:
        return False
    if re.search(r'(经验方|标准方|外敷|外洗|排水|消肿|治疗方|分消)', name):
        return True
    if name.endswith('方'):
        return True
    return name in {
        '仙方活命饮', '五味消毒饮', '犀角地黄汤', '补阳还五汤', '桃红四物汤',
        '四神汤', '七厘散', '阳和汤', '复元活血汤', '利膈汤', '苇茎汤',
        '鸡矢白散', '烧裈散',
    }

# 非方剂条目（灸法等外治操作），不算方
NOT_FORMULA = {'结胸灸法', '小青龙汤加减'}

# 外用/外治方：不在十问辨证范围内，不做问诊规则（仍留在方剂库供查阅）
# 依据各自原文的给药途径：熏、洗、摩、扑粉、坐药、导法、外敷
EXTERNAL = {
    '猪胆汁方',    # 233 大猪胆汁「皆可为导」——谷道给药
    '百合洗方',    # 064 百合病变渴，「外洗」从表补
    '雄黄熏方',    # 068 蚀于肛者，雄黄熏之
    '苦参汤',      # 068 蚀于下部，苦参汤洗之
    '矾石汤',      # 091 治脚气冲心，外洗
    '矾石丸',      # 436 下白物，坐药
    '麝香矾石散',  # 矾石类，鼻嗅/外用
    '头风摩散',    # 084 头风，外摩
    '温粉',        # 038 大青龙后「温粉扑之」，止汗外扑
    '黄连粉',      # 386 浸淫疮，外扑（方阙）
    '干姜附子粉',  # 倪师外用：磨粉敷在小儿足烂疮旁边（同名汤是伤寒 61，另一回事）
    '附子散',      # 捣罗为散，入绵中如装袜，外敷小儿足烂疮
}

data = json.load(io.open('assets/data/formulas.json', encoding='utf-8'))
formulas = data['formulas']

exact, by_alias, by_manual, suspect, gap = [], [], [], [], []
for f in formulas:
    name = f['name']
    al = [a.strip() for a in re.split(r'[,，]', f.get('alias') or '') if a.strip()]
    if name in RULE_N or norm(name) in RULE_N:
        exact.append(name)
        continue
    hit = next((a for a in al if a in RULE_N or norm(a) in RULE_N), None)
    if hit:
        by_alias.append((name, hit))
        continue
    if name in MANUAL:
        by_manual.append((name, MANUAL[name]))
        continue
    base = re.sub(r'(汤|散|丸|饮|煎|方)$', '', norm(name))
    s = next((r for r in RULE if re.sub(r'(汤|散|丸|饮|煎|方)$', '', norm(r)) == base), None)
    if s and name not in DISTINCT:
        suspect.append((name, s))
        continue
    if name in NOT_FORMULA:
        continue
    gap.append(f)

# 库内重复：剂型后缀相同、且去掉后缀后字符完全相同（只差字序）
# 注意「四逆散/四逆汤」「猪苓汤/猪苓散」是不同方，后缀不同不算重复。
sig = {}
for f in formulas:
    n = norm(f['name'])
    m = re.search(r'(汤|散|丸|饮|煎|方)$', n)
    sfx = m.group(1) if m else ''
    body = n[:m.start()] if m else n
    sig.setdefault((sfx, tuple(sorted(body))), []).append(f['name'])
dups = [v for v in sig.values() if len(v) > 1 and len(v[0]) == len(v[1])]


print('=' * 62)
print(f'formulas.json {len(formulas)} 首 | 规则表 {len(RULE)} 条 / {len(RULE_N)} 个名')
print(f'  同名/异体命中      {len(exact)}')
print(f'  alias 字段命中     {len(by_alias)}')
print(f'  人工异名表命中     {len(by_manual)}')
print(f'  剂型后缀疑似同方   {len(suspect)}（已排除 {len(DISTINCT)} 个明确不同方）')
print(f'  >>> 剩余无规则     {len(gap)}')
emp = [f for f in gap if is_empirical(f['name'], f.get('category', ''))]
ext = [f for f in gap if not is_empirical(f['name'], f.get('category', '')) and f['name'] in EXTERNAL]
zz = [f for f in gap if not is_empirical(f['name'], f.get('category', '')) and f['name'] not in EXTERNAL]
print(f'     其中 倪师经验方/后世方 {len(emp)}')
print(f'     其中 仲景原文方 {len(zz) + len(ext)}（待补规则 {len(zz)} / 外用不补 {len(ext)}）')
print(f'  库内重复（同方多名）{len(dups)} 组')
print('=' * 62)

print('\n【alias 命中】')
for a, b in by_alias:
    print(f'  {a} -> {b}')
print('\n【人工异名表命中】')
for a, b in by_manual:
    print(f'  {a} -> {b}')
print('\n【剂型后缀疑似同方，需确认】')
for a, b in suspect:
    print(f'  {a} ~= {b}')
print('\n【库内重复】')
for v in dups:
    print(f'  {v}')

print(f'\n【仲景原文方 · 待补问诊规则 {len(zz)} 首】')
by_mer = {}
for f in zz:
    by_mer.setdefault(f.get('meridian') or '未分类', []).append(f['name'])
for m in sorted(by_mer, key=lambda x: -len(by_mer[x])):
    print(f'\n-- {m}（{len(by_mer[m])}）')
    print('  ' + '、'.join(by_mer[m]))

print(f'\n【外用/外治方 · 不补问诊规则 {len(ext)} 首】')
for f in ext:
    print(f'  {f["name"]}（{f.get("meridian") or ""}）')

print(f'\n【倪师经验方/后世方 {len(emp)} 首】')
print('  ' + '、'.join(f['name'] for f in emp))


def _row(f, kind):
    return '\t'.join([f['name'], kind, str(f.get('meridian') or ''),
                      str(f.get('category') or ''),
                      str(f.get('indication') or '').replace('\t', ' ')[:80]]) + '\n'


with io.open('tool/gap_no_rule.tsv', 'w', encoding='utf-8', newline='') as fp:
    fp.write('name\tkind\tmeridian\tcategory\tindication\n')
    for f in zz:
        fp.write(_row(f, '仲景待补规则'))
    for f in ext:
        fp.write(_row(f, '外用不补'))
    for f in emp:
        fp.write(_row(f, '经验/后世方'))
print('\n已写 tool/gap_no_rule.tsv')
