"""合并所有方剂数据到 formulas.json"""
import json

def load_formulas(path):
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    if isinstance(data, dict) and 'formulas' in data:
        return data['formulas']
    return data

existing = load_formulas('assets/data/formulas.json')
shanghan = load_formulas('_shanghan_formulas.json')
jingui = load_formulas('_jingui_formulas.json')

# 按名称去重，保留字段最丰富的版本
all_by_name = {}

def pick_best(a, b):
    """选字段更多的版本"""
    score_a = sum(1 for v in a.values() if v and v != '' and v != [] and v != {})
    score_b = sum(1 for v in b.values() if v and v != '' and v != [] and v != {})
    return a if score_a >= score_b else b

for f in existing:
    name = f['name']
    if name not in all_by_name or pick_best(all_by_name[name], f) == f:
        all_by_name[name] = f

for f in shanghan:
    name = f['name']
    if name in all_by_name:
        all_by_name[name] = pick_best(all_by_name[name], f)
    else:
        all_by_name[name] = f

for f in jingui:
    name = f['name']
    if name in all_by_name:
        all_by_name[name] = pick_best(all_by_name[name], f)
    else:
        all_by_name[name] = f

# 分类统计
shanghan_names = set(f['name'] for f in shanghan)
jingui_names = set(f['name'] for f in jingui)

only_sh = [n for n in all_by_name if n in shanghan_names and n not in jingui_names and n not in set(f['name'] for f in existing)]
only_jg = [n for n in all_by_name if n in jingui_names and n not in shanghan_names and n not in set(f['name'] for f in existing)]
both = [n for n in all_by_name if n in shanghan_names and n in jingui_names]
only_existing = [n for n in all_by_name if n not in shanghan_names and n not in jingui_names]

result = sorted(all_by_name.values(), key=lambda f: f['name'])
output = {'total': len(result), 'formulas': result}

with open('assets/data/formulas.json', 'w', encoding='utf-8') as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print(f"合并完成: {len(result)} 个方剂")
print(f"  仅伤寒论: {len(only_sh)}")
print(f"  仅金匮要略: {len(only_jg)}")
print(f"  两者共有: {len(both)}")
print(f"  原有独立: {len(only_existing)}")

# 按类别统计
cats = {}
for f in result:
    c = f.get('category', '未分类')
    cats[c] = cats.get(c, 0) + 1
print("\n类别分布:")
for c in sorted(cats.keys()):
    print(f"  {c}: {cats[c]}")
