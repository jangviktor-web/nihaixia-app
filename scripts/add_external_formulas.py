"""补充外用方剂 - 基于倪海厦skill整理"""
import json

with open('assets/data/formulas.json','r',encoding='utf-8') as f:
    data = json.load(f)
formulas = data['formulas']
names = set(f['name'] for f in formulas)

EXTERNAL_FORMULAS = [
    {
        "name": "麝香矾石散",
        "alias": "",
        "meridian": "杂病",
        "category": "金疮药",
        "components": [
            {"name": "麝香", "dosage": "一份", "role": "芳香开窍、无孔不入"},
            {"name": "矾石", "dosage": "五十份（枯矾更佳）", "role": "干燥除湿、改变环境"}
        ],
        "indication": "鼻窦炎（脓鼻涕）、中耳炎（耳朵化脓）、鼻息肉、脑瘤引起的脑部积水、喉痹（吞咽困难）、耳道化脓。",
        "contraindication": "孕妇禁用（麝香走窜）",
        "dosage": "研成细粉，用喷剂喷入鼻腔或耳道",
        "explanation": "倪海厦经验外用方。麝香无孔不入，能到达任何犄角旮旯；矾石是干燥剂，能改变环境使病毒无法生存。喷入后会打喷嚏，将粘液挤出。不需要开刀，中医通过改变环境来治病。矾石最好用天然的，炮制后变成枯矾效果更好。",
        "keywords": ["鼻窦炎", "中耳炎", "鼻息肉", "外用喷剂", "麝香矾石散"]
    },
    {
        "name": "附子散",
        "alias": "",
        "meridian": "少阴",
        "category": "金疮药",
        "components": [
            {"name": "附子", "dosage": "二枚", "role": "温阳散寒"},
            {"name": "干姜", "dosage": "二两", "role": "温中散寒"}
        ],
        "indication": "小儿足烂疮，阴证疮疡。",
        "contraindication": "阳证疮疡不宜",
        "dosage": "捣罗为散，入绵中如装袜，外敷患处",
        "explanation": "倪海厦经验外用方。用干姜和附子磨成粉后，敷在小孩脚疮旁边，内服用当归四逆汤。此为阴证疮疡外敷法。",
        "keywords": ["小儿足烂疮", "阴证疮疡", "外敷散剂"]
    },
    {
        "name": "硫磺大黄麻油外敷方",
        "alias": "烫伤第一方",
        "meridian": "杂病",
        "category": "金疮药",
        "components": [
            {"name": "硫磺", "dosage": "适量", "role": "外用寒凉、解毒"},
            {"name": "大黄", "dosage": "适量", "role": "清热泻火"},
            {"name": "麻油", "dosage": "适量", "role": "调和润肤"}
        ],
        "indication": "烫伤第一方，皮肤红肿，皮肤炎症。起水泡者加菖蒲。",
        "contraindication": "非烫伤不宜",
        "dosage": "调成糊状外敷患处",
        "explanation": "倪海厦经验外用方。硫磺本身外用时非常寒凉，中医把硫磺、大黄、麻油配在一起外敷。西医把硫磺跟膏药一起用变成硫磺膏。如果起水泡要加菖蒲在里面。",
        "keywords": ["烫伤", "皮肤红肿", "外敷", "硫磺"]
    },
    {
        "name": "三黄泻心汤外敷方",
        "alias": "",
        "meridian": "阳明",
        "category": "金疮药",
        "components": [
            {"name": "黄芩", "dosage": "适量", "role": "清热燥湿"},
            {"name": "黄连", "dosage": "适量", "role": "清热解毒"},
            {"name": "大黄", "dosage": "适量", "role": "清热泻火"},
            {"name": "白术", "dosage": "适量", "role": "健脾燥湿"}
        ],
        "indication": "皮肤痒、癣症、皮肤病。在皮肤长癣的地方点刺放血后外涂。",
        "contraindication": "非湿热皮肤病不宜",
        "dosage": "煎汤浓缩或打粉调膏外涂",
        "explanation": "倪海厦经验外用方。三黄泻心汤加白术外用治皮肤病。在皮肤长癣的地方点刺放血后，涂上三黄泻心汤加白术粉作为外敷药粉。",
        "keywords": ["皮肤痒", "癣症", "皮肤病", "外敷"]
    },
    {
        "name": "知母黄连外敷方",
        "alias": "",
        "meridian": "阳明",
        "category": "金疮药",
        "components": [
            {"name": "知母", "dosage": "等分", "role": "除湿"},
            {"name": "黄连", "dosage": "等分", "role": "解毒去热"},
            {"name": "血竭", "dosage": "少许（可加）", "role": "收敛伤口"}
        ],
        "indication": "伤口感染、湿热疮疡、腐烂肌肉。",
        "contraindication": "非湿热疮疡不宜",
        "dosage": "打粉外敷",
        "explanation": "倪海厦经验外用方。知母能够除湿，黄连能解毒去热，血竭能收敛伤口，腐烂的肌肉能够重生。有伤口一定有湿，知母除湿，黄连解毒去热，血竭收敛伤口。",
        "keywords": ["伤口感染", "疮疡", "腐烂肌肉", "外敷"]
    },
    {
        "name": "干姜附子粉",
        "alias": "",
        "meridian": "少阴",
        "category": "金疮药",
        "components": [
            {"name": "干姜", "dosage": "等分", "role": "温中散寒"},
            {"name": "附子", "dosage": "等分", "role": "温阳散寒"}
        ],
        "indication": "小儿足烂疮、阴证疮疡（唇青面黑、四肢厥逆）。",
        "contraindication": "阳证疮疡不宜",
        "dosage": "磨粉敷在疮旁",
        "explanation": "倪海厦经验外用方。这是治疗阴证疮疡的外敷方。干姜附子温阳散寒，改变局部寒湿环境。",
        "keywords": ["阴证疮疡", "小儿足烂疮", "外敷"]
    },
    {
        "name": "川芎外敷方",
        "alias": "",
        "meridian": "厥阴",
        "category": "金疮药",
        "components": [
            {"name": "川芎", "dosage": "单味适量", "role": "活血行气、消肿"}
        ],
        "indication": "关节肿大、骨肿、跌打损伤。",
        "contraindication": "阴虚火旺者不宜",
        "dosage": "单味打粉外敷",
        "explanation": "倪海厦经验外用方。单味川芎粉外敷可以消除骨肿。川芎活血行气，外用消肿散结。",
        "keywords": ["关节肿大", "骨肿", "跌打损伤", "外敷"]
    },
    {
        "name": "狼牙草外洗方",
        "alias": "",
        "meridian": "厥阴",
        "category": "金疮药",
        "components": [
            {"name": "狼牙草", "dosage": "五钱", "role": "杀虫止痒"}
        ],
        "indication": "白带、阴部湿痒。",
        "contraindication": "外洗不可内服",
        "dosage": "四碗水煮成半碗，棉布浸湿后敷于患处或坐浴",
        "explanation": "倪海厦经验外洗方。这是专门治疗妇科阴部瘙痒的外洗方。狼牙草杀虫止痒，外洗不可内服。",
        "keywords": ["白带", "阴部湿痒", "外洗", "妇科"]
    },
    {
        "name": "矾石汤",
        "alias": "矾石泡脚方",
        "meridian": "杂病",
        "category": "金疮药",
        "components": [
            {"name": "矾石（明矾）", "dosage": "二两", "role": "收敛湿气、去湿解毒"}
        ],
        "indication": "香港脚、糖尿病足溃烂、脚气、脚部湿气重。",
        "contraindication": "非湿气不宜",
        "dosage": "用浆水（自来水）煮过，煎三五沸，滚了以后化掉就可以停火，把脚浸泡下去",
        "explanation": "倪海厦经验外用方。矾石能够收敛湿气，专门去湿解毒。矾石汤可以改变脚部环境，使病毒无法生存。配合内服桂枝芍药知母汤效果更好。",
        "keywords": ["香港脚", "糖尿病足", "脚气", "泡脚", "外洗"]
    },
    {
        "name": "温粉",
        "alias": "",
        "meridian": "太阳",
        "category": "金疮药",
        "components": [
            {"name": "龙骨", "dosage": "适量", "role": "收敛固涩"},
            {"name": "牡蛎", "dosage": "适量", "role": "收敛固涩"},
            {"name": "黄芪", "dosage": "适量", "role": "益气固表"}
        ],
        "indication": "大青龙汤发汗后汗出过多，用来止汗的外用粉剂。",
        "contraindication": "无汗不宜",
        "dosage": "研粉，扑于皮肤表面",
        "explanation": "倪海厦经验外用方。大青龙汤服用后如果汗出过多，用温粉扑之止汗。龙骨牡蛎收敛，黄芪益气固表。",
        "keywords": ["汗出过多", "止汗", "外用粉剂", "大青龙救逆"]
    },
]

added = 0
for f in EXTERNAL_FORMULAS:
    name = f["name"]
    if name in names:
        print(f"SKIP (already exists): {name}")
        continue
    formulas.append(f)
    names.add(name)
    added += 1
    print(f"Added: {name}")

# 为新增方剂添加拼音id
NAME_TO_PINYIN = {
    "麝香矾石散": "shexiangfanshisan",
    "附子散": "fuzisan",
    "硫磺大黄麻油外敷方": "liuhuangdahuangmayouwaifufang",
    "三黄泻心汤外敷方": "sanhuangxiexintangwaifufang",
    "知母黄连外敷方": "zhimuhuanglianwaifufang",
    "干姜附子粉": "ganjiangfuzifen",
    "川芎外敷方": "chuanxiongwaifufang",
    "狼牙草外洗方": "langyacaowaixifang",
    "矾石汤": "fanshitang",
    "温粉": "wenfen",
}
for f in formulas:
    if f['name'] in NAME_TO_PINYIN and 'id' not in f:
        f['id'] = NAME_TO_PINYIN[f['name']]

output = {"total": len(formulas), "formulas": formulas}
with open("assets/data/formulas.json", "w", encoding="utf-8") as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print(f"\nAdded {added} external formulas. Total now: {len(formulas)}")
