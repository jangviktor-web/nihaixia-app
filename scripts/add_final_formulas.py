"""补充最后8个缺失方剂"""
import json

with open('assets/data/formulas.json','r',encoding='utf-8') as f:
    data = json.load(f)
formulas = data['formulas']
names = set(f['name'] for f in formulas)

FINAL_ADDITIONS = [
    {
        "name": "桂枝人参汤",
        "alias": "",
        "meridian": "太阴/太阳",
        "category": "表里双解剂",
        "components": [
            {"name": "桂枝", "dosage": "四两", "role": "解表散寒"},
            {"name": "甘草", "dosage": "四两炙", "role": "调和诸药"},
            {"name": "白术", "dosage": "三两", "role": "健脾燥湿"},
            {"name": "人参", "dosage": "三两", "role": "补气健脾"},
            {"name": "干姜", "dosage": "三两", "role": "温中散寒"}
        ],
        "indication": "太阳病，外证未除，而数下之，遂协热而利，利下不止，心下痞硬，表里不解者，桂枝人参汤主之。",
        "contraindication": "热利不宜",
        "dosage": "以水九升，先煮四味，取五升，内桂，更煮取三升，去滓，温服一升，日再夜一服",
        "explanation": "表里同病，误下后脾阳虚衰。桂枝解表，人参白术干姜温中健脾，甘草调和。理中汤加桂枝。",
        "keywords": ["协热利", "心下痞硬", "表里不解"]
    },
    {
        "name": "赤石脂禹余粮汤",
        "alias": "",
        "meridian": "太阴/阳明",
        "category": "涩肠固脱剂",
        "components": [
            {"name": "赤石脂", "dosage": "一斤碎", "role": "涩肠止泻"},
            {"name": "禹余粮", "dosage": "一斤碎", "role": "涩肠止泻"}
        ],
        "indication": "伤寒服汤药，下利不止，心下痞硬，服泻心汤已，复以他药下之，利不止，医以理中与之，利益甚。理中者，理中焦，此利在下焦，赤石脂禹余粮汤主之。",
        "contraindication": "湿热下利不宜",
        "dosage": "以水六升，煮取二升，去滓，分温三服",
        "explanation": "下焦滑脱，久利不止。赤石脂禹余粮皆为矿物药，质重沉降，涩肠固脱。此为涩法代表方。",
        "keywords": ["久利", "滑脱", "涩肠"]
    },
    {
        "name": "升麻鳖甲汤",
        "alias": "",
        "meridian": "厥阴/阳明",
        "category": "清热解毒剂",
        "components": [
            {"name": "升麻", "dosage": "二两", "role": "清热解毒"},
            {"name": "鳖甲", "dosage": "手指大一片炙", "role": "滋阴散结"},
            {"name": "当归", "dosage": "一两", "role": "养血活血"},
            {"name": "蜀椒", "dosage": "一两去汗", "role": "温中散寒"},
            {"name": "雄黄", "dosage": "半两研", "role": "解毒杀虫"},
            {"name": "甘草", "dosage": "二两", "role": "调和诸药"}
        ],
        "indication": "阳毒之为病，面赤斑斑如锦纹，咽喉痛，唾脓血，五日可治，七日不可治，升麻鳖甲汤主之。阴毒之为病，面目青，身痛如被杖，咽喉痛，五日可治，七日不可治，升麻鳖甲汤去雄黄蜀椒主之。",
        "contraindication": "非毒疫不宜",
        "dosage": "以水四升，煮取一升，顿服之，老小再服取汗",
        "explanation": "阳毒阴毒，疫毒入血。升麻雄黄解毒，鳖甲当归养血，蜀椒温中（阳毒用，阴毒去）。",
        "keywords": ["阳毒", "阴毒", "疫毒", "锦纹"]
    },
    {
        "name": "天雄散",
        "alias": "",
        "meridian": "少阴",
        "category": "温阳固涩剂",
        "components": [
            {"name": "天雄", "dosage": "三两炮", "role": "温阳散寒"},
            {"name": "白术", "dosage": "八两", "role": "健脾燥湿"},
            {"name": "桂枝", "dosage": "六两", "role": "温经通络"},
            {"name": "龙骨", "dosage": "三两", "role": "潜阳固涩"}
        ],
        "indication": "天雄散方：主男子失精，腰膝冷痛。",
        "contraindication": "阴虚火旺者禁用",
        "dosage": "上四味，杵为散，酒服半钱匕，日三服，不知，稍增之",
        "explanation": "阳虚失精，腰膝冷痛。天雄温阳散寒，白术健脾，桂枝温经，龙骨固涩潜阳。",
        "keywords": ["失精", "腰冷", "阳虚"]
    },
    {
        "name": "桂甘姜枣麻辛附子汤",
        "alias": "",
        "meridian": "太阳/少阴",
        "category": "温阳发表剂",
        "components": [
            {"name": "桂枝", "dosage": "三两", "role": "解表散寒"},
            {"name": "甘草", "dosage": "二两", "role": "调和诸药"},
            {"name": "生姜", "dosage": "三两", "role": "散寒止呕"},
            {"name": "大枣", "dosage": "十二枚", "role": "补脾和胃"},
            {"name": "麻黄", "dosage": "二两", "role": "发汗解表"},
            {"name": "细辛", "dosage": "二两", "role": "散寒止痛"},
            {"name": "附子", "dosage": "一枚炮", "role": "温阳散寒"}
        ],
        "indication": "气分，心下坚，大如盘，边如旋杯，水饮所作，桂甘姜枣麻辛附子汤主之。",
        "contraindication": "无阳虚者不宜",
        "dosage": "以水七升，煮取三升，分温三服，当汗出，如虫行皮中，即愈",
        "explanation": "阳虚水停，气分证。麻黄细辛附子温阳发表，桂枝生姜大枣调和营卫。",
        "keywords": ["气分", "心下坚", "水饮"]
    },
    {
        "name": "烧棍散",
        "alias": "",
        "meridian": "厥阴",
        "category": "导浊引邪剂",
        "components": [
            {"name": "妇人中裈", "dosage": "近隐处剪取烧灰", "role": "导浊引邪"}
        ],
        "indication": "伤寒阴阳易之为病，其人身体重，少气，少腹里急，或引阴中拘挛，热上冲胸，头重不欲举，眼中生花，膝胫拘急者，烧棍散主之。",
        "contraindication": "非阴阳易者不宜",
        "dosage": "上一味，以水和，服方寸匕，日三服，小便即利，阴头微肿，此为愈矣",
        "explanation": "阴阳易，伤寒后房事传染。中裈烧灰，取同气相求之意，导浊邪外出。",
        "keywords": ["阴阳易", "房劳", "传染"]
    },
    {
        "name": "杏子汤",
        "alias": "",
        "meridian": "太阴/肺",
        "category": "宣肺利水剂",
        "components": [
            {"name": "杏子", "dosage": "五十个", "role": "宣肺利水"},
            {"name": "麻黄", "dosage": "三两", "role": "发汗利水"},
            {"name": "甘草", "dosage": "二两", "role": "调和诸药"}
        ],
        "indication": "水之为病，其脉沉小，属少阴；浮者为风，无水虚胀者，为气。水，发其汗即已。脉沉者宜麻黄附子汤；浮者宜杏子汤。",
        "contraindication": "无表证者不宜",
        "dosage": "以水七升，先煮麻黄，去上沫，内诸药，煮取二升半，温服八合",
        "explanation": "风水轻证，脉浮。杏子宣肺利水，麻黄发汗，甘草调和。此方原书阙载，后人补之。",
        "keywords": ["风水", "脉浮", "宣肺"]
    },
]

alias_map = {
    "茯苓桂枝白术甘草汤": "苓桂术甘汤",
    "茯苓桂枝甘草大枣汤": "苓桂甘枣汤",
}

added = 0
for f in FINAL_ADDITIONS:
    name = f["name"]
    mapped = alias_map.get(name, name)
    if mapped in names or name in names:
        print(f"SKIP (already exists as alias): {name} -> {mapped}")
        continue
    formulas.append(f)
    names.add(name)
    added += 1
    print(f"Added: {name}")

output = {"total": len(formulas), "formulas": formulas}
with open("assets/data/formulas.json", "w", encoding="utf-8") as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print(f"\nAdded {added} formulas. Total now: {len(formulas)}")
