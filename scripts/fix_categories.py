#!/usr/bin/env python3
"""统一新添加药物的分类，与原有体系对齐"""
import json

HERBS_JSON = r"D:\360Downloads\nihaisha_app\assets\data\herbs.json"

# 需要修正分类的药物 (name → new_category)
FIXES = {
    # 第一批新增药（20味）分类修正
    "飞廉": "祛风湿药",
    "地肤子": "利水渗湿药",
    "杜若": "解表药",
    "石龙刍": "利水渗湿药",
    "白英": "清热药",
    "积雪草": "清热药",
    "莨菪子": "止痛药",
    "青葙子": "清热药",
    "桐叶": "清热药",
    "菟花": "泻下药",
    "牙子": "杀虫药",
    "藿菌": "杀虫药",
    "蒺藜子": "明目药",
    "蓍实": "补益药",
    "大豆黄卷": "利水渗湿药",

    # 第二批补充药（用户数据）分类修正
    "五色石脂": "收涩药",
    "青石脂": "收涩药",
    "黄石脂": "收涩药",
    "白石脂": "收涩药",
    "黑石脂": "收涩药",
    "鹿茸": "补益药",
    "蜈蚣": "动物药",
    "虾蟆": "动物药",
    "蟪虫": "动物药",
    "牡狗阴茎": "补益药",
    "礜石": "矿石药",
    "蟅虫": "动物药",
    "翳螉": "动物药",
    "蚱蝉": "动物药",
}

# 需要补全 flavor/meridians 的药物
FLAVOR_FIX = {
    "礜石": {"flavor": "辛", "meridians": ["肾", "脾"]},
    "蚱蝉": {"flavor": "咸", "meridians": ["肝", "肺"]},
    "翳螉": {"flavor": "辛", "meridians": ["肝", "胃"]},
}

def main():
    with open(HERBS_JSON, 'r', encoding='utf-8') as f:
        data = json.load(f)

    cat_fixed = 0
    flavor_fixed = 0

    for h in data['herbs']:
        name = h['name']
        if name in FIXES and h.get('category') != FIXES[name]:
            h['category'] = FIXES[name]
            cat_fixed += 1
        if name in FLAVOR_FIX:
            for k, v in FLAVOR_FIX[name].items():
                if not h.get(k):
                    h[k] = v
                    flavor_fixed += 1

    with open(HERBS_JSON, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    # 验证分类分布
    from collections import Counter
    cats = Counter(h.get('category', '') for h in data['herbs'])
    lines = [f"Fixed categories: {cat_fixed}, Fixed flavor/meridians: {flavor_fixed}", ""]
    for c, n in cats.most_common():
        lines.append(f"  {c}: {n}")

    with open('_check5.txt', 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    print(f"Fixed {cat_fixed} categories, {flavor_fixed} flavor/meridians")

if __name__ == '__main__':
    main()
