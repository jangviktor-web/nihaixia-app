"""补充外伤/伤科方剂 - 基于倪海厦skill整理"""
import json

with open('assets/data/formulas.json','r',encoding='utf-8') as f:
    data = json.load(f)
formulas = data['formulas']
names = set(f['name'] for f in formulas)

TRAUMA_FORMULAS = [
    {
        "name": "抵挡汤",
        "alias": "",
        "meridian": "太阳",
        "category": "破血逐瘀剂",
        "components": [
            {"name": "水蛭", "dosage": "三十个熬", "role": "破血逐瘀"},
            {"name": "虻虫", "dosage": "三十个去翅足熬", "role": "破血逐瘀"},
            {"name": "桃仁", "dosage": "二十个去皮尖", "role": "活血化瘀"},
            {"name": "大黄", "dosage": "三两酒洗", "role": "攻下瘀热"}
        ],
        "indication": "太阳病，身黄，脉沉结，少腹硬满，小便不利者，为无血也；小便自利，其人如狂者，血证谛也，抵挡汤主之。",
        "contraindication": "体虚无瘀者禁用",
        "dosage": "上四味，以水五升，煮取三升，去滓，温服一升，不下更服",
        "explanation": "比桃核承气汤更重的攻瘀方。水蛭虻虫为虫类破血药，直入血络，攻坚逐瘀。桃仁活血，大黄攻下瘀热。倪师：抵挡汤是攻坚用的，淤血很重的时候用。",
        "keywords": ["瘀血重证", "少腹硬满", "如狂", "身黄", "破血逐瘀"]
    },
    {
        "name": "大黄蛰虫丸",
        "alias": "",
        "meridian": "杂病",
        "category": "活血化瘀剂",
        "components": [
            {"name": "大黄", "dosage": "十分蒸", "role": "攻下瘀热"},
            {"name": "蟅虫", "dosage": "一升", "role": "破血逐瘀"},
            {"name": "水蛭", "dosage": "百枚", "role": "破血逐瘀"},
            {"name": "蛴螬", "dosage": "一升", "role": "破血散结"},
            {"name": "虻虫", "dosage": "一升", "role": "破血逐瘀"},
            {"name": "干漆", "dosage": "一两", "role": "破瘀消积"},
            {"name": "桃仁", "dosage": "一升", "role": "活血化瘀"},
            {"name": "芍药", "dosage": "四两", "role": "养血柔肝"},
            {"name": "地黄", "dosage": "十两", "role": "养血滋阴"},
            {"name": "甘草", "dosage": "三两", "role": "调和诸药"},
            {"name": "黄芩", "dosage": "二两", "role": "清热"},
            {"name": "杏仁", "dosage": "一升", "role": "润燥"}
        ],
        "indication": "五劳虚极，羸瘦腹满，不能饮食，食伤、忧伤、饮伤、房室伤、饥伤、劳伤、经络荣卫气伤，内有干血，肌肤甲错，两目黯黑。缓中补虚，大黄蛰虫丸主之。",
        "contraindication": "孕妇禁用",
        "dosage": "上十二味，末之，炼蜜和丸小豆大，酒饮服五丸，日三服",
        "explanation": "丸药缓性，让药物慢慢进入人体，把已经成为血块的瘀血慢慢化掉。虫类药破瘀力量最强，配合桃仁干漆攻逐瘀血，地黄芍药养血，寓攻于补。倪师：干血劳就是体内干的瘀血日久成劳症，被打伤造成的瘀血也可用此方。",
        "keywords": ["干血劳", "肌肤甲错", "两目黯黑", "瘀血内停", "虫类攻瘀"]
    },
    {
        "name": "阳和汤",
        "alias": "",
        "meridian": "少阴",
        "category": "温阳排脓剂",
        "components": [
            {"name": "熟地", "dosage": "一两", "role": "滋阴补血"},
            {"name": "鹿角胶", "dosage": "三钱", "role": "温阳补精"},
            {"name": "肉桂", "dosage": "三钱生用冲服", "role": "温阳散寒"},
            {"name": "麻黄", "dosage": "三钱", "role": "发散通阳"},
            {"name": "炮姜", "dosage": "三片", "role": "温中散寒"},
            {"name": "白芥子", "dosage": "二钱", "role": "化痰散结"},
            {"name": "甘草", "dosage": "一钱", "role": "调和诸药"}
        ],
        "indication": "痈肿（化脓），脑疽（脑壳里面化脓），阴疽，贴骨疽，鹤膝风。北派最常用的排痈汤。",
        "contraindication": "阳证痈肿、红肿热痛者不宜",
        "dosage": "六碗水煮成两碗，寒重加附子",
        "explanation": "阳和汤治阴疽要方。熟地鹿角胶温补精血，肉桂炮姜温阳散寒，麻黄开腠理让脓有出路，白芥子化痰散结。倪师：阳和汤是北派最常用的排痈汤，脑疽、脑壳里面化脓都可以用。",
        "keywords": ["阴疽", "脑疽", "贴骨疽", "鹤膝风", "排痈"]
    },
    {
        "name": "仙方活命饮",
        "alias": "",
        "meridian": "阳明",
        "category": "清热排脓剂",
        "components": [
            {"name": "金银花", "dosage": "三钱", "role": "清热解毒"},
            {"name": "防风", "dosage": "一钱", "role": "祛风解表"},
            {"name": "白芷", "dosage": "一钱", "role": "排脓消肿"},
            {"name": "当归", "dosage": "二钱", "role": "养血活血"},
            {"name": "陈皮", "dosage": "一钱", "role": "理气"},
            {"name": "贝母", "dosage": "四钱", "role": "化痰散结"},
            {"name": "天花粉", "dosage": "二钱", "role": "清热生津"},
            {"name": "穿山甲", "dosage": "五钱炙", "role": "通经排脓"},
            {"name": "皂角刺", "dosage": "三钱", "role": "消肿排脓"},
            {"name": "乳香", "dosage": "二钱", "role": "活血止痛"},
            {"name": "没药", "dosage": "二钱", "role": "活血止痛"},
            {"name": "赤芍", "dosage": "四钱", "role": "清热凉血"},
            {"name": "甘草", "dosage": "二钱", "role": "调和诸药"}
        ],
        "indication": "痈肿初起，红肿焮痛，身热凛寒，苔薄白或黄，脉数有力。也可用于乳癌硬块、阴部痈肿。",
        "contraindication": "已溃者不宜",
        "dosage": "水煎服，酒一小杯",
        "explanation": "仙方活命饮为疮疡之圣药。金银花清热解毒为主，穿山甲皂角刺通经排脓，乳香没药活血止痛，白芷排脓。倪师：此方可把身上硬块、乳癌硬块逼到皮肤表面变成脓疡后排出来。乳香着重在化脓，没药着重在止痛。",
        "keywords": ["痈肿初起", "红肿热痛", "乳癌", "排脓", "疮疡圣药"]
    },
    {
        "name": "五味消毒饮",
        "alias": "",
        "meridian": "阳明",
        "category": "清热解毒剂",
        "components": [
            {"name": "金银花", "dosage": "三钱", "role": "清热解毒"},
            {"name": "蒲公英", "dosage": "三钱", "role": "清热解毒"},
            {"name": "紫花地丁", "dosage": "三钱", "role": "清热解毒"},
            {"name": "天葵子", "dosage": "二钱", "role": "清热散结"},
            {"name": "野菊花", "dosage": "三钱", "role": "清热解毒"}
        ],
        "indication": "疔疮痈肿，疔毒走黄，局部红肿热痛，各种感染化脓。",
        "contraindication": "阴疽不宜",
        "dosage": "水煎服，黄酒为引，取微汗",
        "explanation": "五味消毒饮为治疔毒要方。五味药皆为清热解毒专药，金银花为疮家圣药，蒲公英治乳痈要药，紫花地丁治疔毒要药。倪师：疔疮很凶险，一定要用大剂清热解毒。",
        "keywords": ["疔疮", "痈肿", "疔毒走黄", "清热解毒", "感染化脓"]
    },
    {
        "name": "复元活血汤",
        "alias": "",
        "meridian": "少阳",
        "category": "活血化瘀剂",
        "components": [
            {"name": "柴胡", "dosage": "五钱", "role": "疏肝理气"},
            {"name": "天花粉", "dosage": "三钱", "role": "清热生津"},
            {"name": "当归", "dosage": "三钱", "role": "养血活血"},
            {"name": "红花", "dosage": "一钱", "role": "活血化瘀"},
            {"name": "穿山甲", "dosage": "二钱炙", "role": "通经散结"},
            {"name": "桃仁", "dosage": "五十个", "role": "破血逐瘀"},
            {"name": "大黄", "dosage": "一两", "role": "攻下瘀热"},
            {"name": "甘草", "dosage": "二钱", "role": "调和诸药"}
        ],
        "indication": "跌打损伤，瘀血留于胁下，痛不可忍。为伤科常用方。",
        "contraindication": "孕妇禁用",
        "dosage": "上八味，除桃仁外，锉如麻豆大，每服一两半，水一盏半，酒半盏，同煎至七分，去滓，食前温服",
        "explanation": "复元活血汤为伤科要方，治跌打损伤瘀血留于胁下。柴胡引药入肝经，桃仁红花破血逐瘀，大黄攻下瘀热，穿山甲通经散结，当归养血。倪师：伤科用小柴胡汤加桃仁红花就是这个思路。",
        "keywords": ["跌打损伤", "瘀血胁痛", "伤科要方", "活血化瘀"]
    },
    {
        "name": "七厘散",
        "alias": "",
        "meridian": "杂病",
        "category": "活血化瘀剂",
        "components": [
            {"name": "血竭", "dosage": "一两", "role": "散瘀定痛"},
            {"name": "红花", "dosage": "一钱半", "role": "活血化瘀"},
            {"name": "乳香", "dosage": "一钱半", "role": "活血止痛"},
            {"name": "没药", "dosage": "一钱半", "role": "活血止痛"},
            {"name": "朱砂", "dosage": "一钱二分", "role": "镇心安神"},
            {"name": "麝香", "dosage": "一分二厘", "role": "开窍通络"},
            {"name": "冰片", "dosage": "一分二厘", "role": "清热止痛"},
            {"name": "珍珠", "dosage": "三分", "role": "收敛生肌"},
            {"name": "儿茶", "dosage": "二钱四分", "role": "收湿敛疮"}
        ],
        "indication": "跌打损伤，骨折筋断，瘀血肿痛，刀伤出血，一切外伤。内服外敷均可。",
        "contraindication": "孕妇禁用",
        "dosage": "上药研极细末，每服七厘（约0.2g），白酒送服。外用白酒调敷患处",
        "explanation": "七厘散为伤科名方，内服外用俱佳。血竭散瘀定痛为君药，乳香没药活血止痛，红花化瘀，麝香冰片开窍通络止痛，儿茶收敛。倪师：伤科用乳香没药可以消炎镇痛止痛，比吗啡好用且无副作用。",
        "keywords": ["跌打损伤", "骨折", "刀伤", "瘀血肿痛", "内服外敷"]
    },
    {
        "name": "犀角地黄汤",
        "alias": "",
        "meridian": "阳明",
        "category": "清热凉血剂",
        "components": [
            {"name": "犀角", "dosage": "一两（现用水牛角代）", "role": "清热凉血"},
            {"name": "地黄", "dosage": "半两", "role": "清热凉血"},
            {"name": "芍药", "dosage": "三分", "role": "养血敛阴"},
            {"name": "牡丹皮", "dosage": "一分", "role": "清热凉血"}
        ],
        "indication": "热入血分，身热谵语，斑色紫黑，吐血衄血，便血尿血，舌绛起刺。外伤后瘀血化热也可用。",
        "contraindication": "阳虚失血者不宜",
        "dosage": "上四味切，以水九升，煮取三升，分三服",
        "explanation": "犀角地黄汤为清热凉血代表方。犀角（水牛角代）清心营之热，地黄凉血养阴，芍药丹皮凉血散瘀。倪师：出血症要分寒热，热证出血用犀角地黄汤或三黄泻心汤，寒证出血用柏叶汤。",
        "keywords": ["热入血分", "吐血衄血", "发斑", "凉血止血"]
    },
    {
        "name": "黄连粉",
        "alias": "",
        "meridian": "阳明",
        "category": "外敷剂",
        "components": [
            {"name": "黄连", "dosage": "一两", "role": "清热解毒消炎"},
            {"name": "薏苡仁", "dosage": "五钱", "role": "收敛皮肤湿"},
            {"name": "白术", "dosage": "五钱", "role": "去肌肉湿"},
            {"name": "冬瓜仁", "dosage": "三钱", "role": "润肺生新皮肤"}
        ],
        "indication": "浸淫疮，皮肤表面的疮，从口流向四肢者可治。皮肤湿烂、火伤。",
        "contraindication": "非湿热疮疡不宜",
        "dosage": "四味药打粉外敷患处",
        "explanation": "黄连粉为外敷疮疡名方。黄连清热消炎镇痛，薏苡仁收敛皮肤之湿，白术去肌肉里面的湿，冬瓜仁润肺生新皮肤。倪师：有伤口一定有湿，知母除湿，黄连解毒去热，血竭收敛伤口。",
        "keywords": ["浸淫疮", "皮肤湿烂", "外敷", "火伤", "消炎"]
    },
    {
        "name": "桃红四物汤",
        "alias": "",
        "meridian": "厥阴",
        "category": "活血化瘀剂",
        "components": [
            {"name": "桃仁", "dosage": "三钱", "role": "破血逐瘀"},
            {"name": "红花", "dosage": "一钱", "role": "活血化瘀"},
            {"name": "当归", "dosage": "三钱", "role": "养血活血"},
            {"name": "川芎", "dosage": "一钱半", "role": "行气活血"},
            {"name": "芍药", "dosage": "三钱", "role": "养血柔肝"},
            {"name": "地黄", "dosage": "三钱", "role": "养血滋阴"}
        ],
        "indication": "血虚兼血瘀证，面色萎黄，胸胁刺痛，月经不调。外伤后瘀血内停、肿痛也可用。",
        "contraindication": "孕妇禁用",
        "dosage": "水煎服",
        "explanation": "桃红四物汤为四物汤加桃仁红花，养血活血并用。四物汤补血调血，桃仁红花破血逐瘀。倪师：四物汤是补血的方子，加桃仁红花就变成活血化瘀的方子，伤科常用。",
        "keywords": ["血虚血瘀", "跌打损伤", "活血化瘀", "四物汤加味"]
    },
    {
        "name": "补阳还五汤",
        "alias": "",
        "meridian": "阳明",
        "category": "补气活血剂",
        "components": [
            {"name": "黄芪", "dosage": "四两", "role": "大补元气"},
            {"name": "当归", "dosage": "二钱", "role": "养血活血"},
            {"name": "赤芍", "dosage": "一钱半", "role": "清热凉血"},
            {"name": "地龙", "dosage": "一钱", "role": "通经活络"},
            {"name": "川芎", "dosage": "一钱", "role": "行气活血"},
            {"name": "红花", "dosage": "一钱", "role": "活血化瘀"},
            {"name": "桃仁", "dosage": "一钱", "role": "破血逐瘀"}
        ],
        "indication": "中风后遗症，半身不遂，口眼歪斜，语言謇涩，口角流涎，小便频数。气虚血瘀所致。",
        "contraindication": "阴虚阳亢者不宜",
        "dosage": "水煎服",
        "explanation": "补阳还五汤为治中风后遗症名方。黄芪大补元气，气旺则血行，配合当归赤芍川芎红花桃仁活血化瘀，地龙通经活络。倪师：中风分经络和脏腑，中经络用补阳还五汤类方，中脏腑要用涤痰汤等。",
        "keywords": ["中风后遗症", "半身不遂", "气虚血瘀", "补气活血"]
    },
]

added = 0
for f in TRAUMA_FORMULAS:
    name = f["name"]
    if name in names:
        print(f"SKIP (already exists): {name}")
        continue
    formulas.append(f)
    names.add(name)
    added += 1
    print(f"Added: {name}")

output = {"total": len(formulas), "formulas": formulas}
with open("assets/data/formulas.json", "w", encoding="utf-8") as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print(f"\nAdded {added} trauma formulas. Total now: {len(formulas)}")
