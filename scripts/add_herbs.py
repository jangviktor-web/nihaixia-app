#!/usr/bin/env python3
"""向 herbs.json 添加20味缺失药物"""
import json

HERBS_JSON = r"D:\360Downloads\nihaisha_app\assets\data\herbs.json"

NEW_HERBS = [
    {
        "name": "蒲黄",
        "original": "味甘平无毒，主心腹膀胱寒热，利小便，止血消瘀血，久服轻身益气力延年。",
        "action": "蒲黄为凉血活血要药，主吐衄尿血，利小便。",
        "nature_category": "平",
        "flavor": "甘",
        "meridians": ["肝", "心包"],
        "category": "止血药",
        "clinical_notes": "蒲黄，生用性滑，行血消瘀，炒黑用涩，能止一切血。生用活血，炒黑止血，这两个要分开。倪海厦临床经验，蒲黄配五灵脂，名失笑散，治一切心腹瘀痛。蒲黄滑肠，脾虚无瘀者慎用。",
        "dosage": "一钱至三钱。",
        "contraindication": "生用性滑，孕妇慎服。",
        "herb_comparisons": ["蒲黄配五灵脂名失笑散，治心腹瘀痛。", "蒲黄生用行血消瘀，炒黑止血。"]
    },
    {
        "name": "海藻",
        "original": "味苦咸寒无毒，主瘿瘤结气，散颈下硬核痛，痈肿症瘕坚气，腹中上下雷鸣，下十二水肿。",
        "action": "海藻为软坚散结要药，主瘿瘤瘰疬，利水消肿。",
        "nature_category": "寒",
        "flavor": "苦咸",
        "meridians": ["肝", "胃", "肾"],
        "category": "化痰药",
        "clinical_notes": "海藻，咸能软坚，寒能泻热，故主治瘿瘤。倪海厦经验，海藻配昆布，软坚散结力量倍增。甲状腺肿大、淋巴结核用之。海藻反甘草，十八反之一，但临床有合用者，需谨慎。",
        "dosage": "一钱至三钱。",
        "contraindication": "反甘草。脾胃虚寒者慎用。",
        "herb_comparisons": ["海藻与昆布功用相近，昆布力更强。", "海藻反甘草，十八反之一。"]
    },
    {
        "name": "飞廉",
        "original": "味苦平无毒，主骨节热，胫重酸疼，久服令人身轻。",
        "action": "飞廉为祛风清热药，主风湿痹痛。",
        "nature_category": "平",
        "flavor": "苦",
        "meridians": ["肝"],
        "category": "祛风湿药",
        "clinical_notes": "飞廉，祛风除湿，清热解毒。治风湿痹痛，骨节酸疼，用之有效。倪海厦临床上飞廉多用于风湿关节疼痛。",
        "dosage": "一钱至三钱。",
        "contraindication": "体虚者慎用。",
        "herb_comparisons": ["飞廉祛风之力较缓，不如防风、羌活。"]
    },
    {
        "name": "地肤子",
        "original": "味苦寒无毒，主膀胱热，利小便，补中益精气，久服耳目聪明，轻身耐老。",
        "action": "地肤子为利水清热药，主小便不利，皮肤瘙痒。",
        "nature_category": "寒",
        "flavor": "苦",
        "meridians": ["膀胱", "肾"],
        "category": "利水渗湿药",
        "clinical_notes": "地肤子，清热利水，又能祛风止痒。倪海厦经验，地肤子配白鲜皮，治皮肤湿疹瘙痒。膀胱湿热，小便涩痛，用之有效。",
        "dosage": "一钱至三钱。",
        "contraindication": "肾虚尿频者忌用。",
        "herb_comparisons": ["地肤子清热利水兼祛风止痒。", "地肤子配白鲜皮治皮肤湿疹。"]
    },
    {
        "name": "杜若",
        "original": "味辛微温无毒，主胸胁下逆气，温中风入脑户，头肿痛多涕泪出。",
        "action": "杜若为发散风寒药，主风寒头痛。",
        "nature_category": "温",
        "flavor": "辛",
        "meridians": ["肺"],
        "category": "解表药",
        "clinical_notes": "杜若，发散风寒，温中理气。主治风寒头痛、鼻塞多涕。此药现在少用，多以辛夷、白芷代替。",
        "dosage": "一钱至二钱。",
        "contraindication": "阴虚火旺者忌。",
        "herb_comparisons": ["杜若功用近辛夷，但辛夷更为常用。"]
    },
    {
        "name": "石龙刍",
        "original": "味苦微寒无毒，主心腹邪气，小便不利，淋闭风湿，鬼注恶毒。",
        "action": "石龙刍为利水通淋药，主小便淋闭。",
        "nature_category": "寒",
        "flavor": "苦",
        "meridians": ["膀胱"],
        "category": "利水渗湿药",
        "clinical_notes": "石龙刍，利水通淋，清热解毒。主治小便淋闭，膀胱湿热。此药现名龙须草，临床少用。",
        "dosage": "一钱至三钱。",
        "contraindication": "脾胃虚寒者慎用。",
        "herb_comparisons": ["石龙刍现名龙须草，功用近通草。"]
    },
    {
        "name": "石蜜",
        "original": "味甘平无毒，主心腹邪气，诸惊痫痓，安五脏诸不足，益气补中，止痛解毒，除众病和百药，久服强志轻身，不饥不老。",
        "action": "石蜜为补中润燥药，主脾胃虚弱，润肺止咳。",
        "nature_category": "平",
        "flavor": "甘",
        "meridians": ["脾", "肺", "大肠"],
        "category": "补益药",
        "clinical_notes": "石蜜即蜂蜜，甘平无毒，补中缓急，润肺止咳，通便解毒。倪海厦常用蜂蜜调和诸药，亦可外用润肤。石蜜可解乌头毒，附子中毒时急用蜂蜜解之。",
        "dosage": "一钱至三钱，外用适量。",
        "contraindication": "湿盛脘腹胀满者忌用。",
        "herb_comparisons": ["石蜜即蜂蜜，可解乌头毒。", "石蜜润肺止咳，与饴糖功用相近。"]
    },
    {
        "name": "白英",
        "original": "味甘寒无毒，主寒热疸疔，消渴补中益气，久服轻身延年。",
        "action": "白英为清热利湿药，主黄疸水肿。",
        "nature_category": "寒",
        "flavor": "甘",
        "meridians": ["肝", "胆"],
        "category": "清热药",
        "clinical_notes": "白英，清热解毒，利湿消肿。主治湿热黄疸，水肿淋病。民间用白英治肿瘤，倪海厦认为可作为辅助用药。全草入药。",
        "dosage": "一钱至三钱。",
        "contraindication": "脾胃虚寒者慎用。",
        "herb_comparisons": ["白英清热利湿，近似茵陈蒿之功。"]
    },
    {
        "name": "积雪草",
        "original": "味苦寒无毒，主大热恶疮痈疽，浸淫赤熛皮肤赤，身热。",
        "action": "积雪草为清热解毒药，主痈肿疮毒。",
        "nature_category": "寒",
        "flavor": "苦",
        "meridians": ["肝", "脾", "肾"],
        "category": "清热药",
        "clinical_notes": "积雪草，清热利湿，解毒消肿。主治痈肿疮毒，湿热黄疸。现代研究有促进伤口愈合作用，倪海厦认为可外敷治疮疡。又名落得打、崩大碗。",
        "dosage": "一钱至三钱，外用适量。",
        "contraindication": "脾胃虚寒者慎用。",
        "herb_comparisons": ["积雪草清热解毒，外用治疮疡。"]
    },
    {
        "name": "莨菪子",
        "original": "味苦寒有毒，主齿痛出虫，肉痹拘急，使人健行见鬼，多食令人狂走。",
        "action": "莨菪子为止痛定痫药，主齿痛风湿痹痛。",
        "nature_category": "寒",
        "flavor": "苦",
        "meridians": ["胃", "肝"],
        "category": "止痛药",
        "clinical_notes": "莨菪子又名天仙子，有大毒，含阿托品成分。古方用于止齿痛、定痫。倪海厦强调此药有大毒，不可轻用，内服宜极慎。外用可止牙痛。",
        "dosage": "内服极少量，外用适量。",
        "contraindication": "有大毒，孕妇禁用。内服宜极慎。",
        "herb_comparisons": ["莨菪子有大毒，含阿托品，不可轻用。"]
    },
    {
        "name": "青葙子",
        "original": "味苦微寒无毒，主邪气皮肤中热，风瘙身痒，杀三虫，子名草决明，主唇口青。",
        "action": "青葙子为清肝明目药，主目赤肿痛。",
        "nature_category": "寒",
        "flavor": "苦",
        "meridians": ["肝"],
        "category": "清热药",
        "clinical_notes": "青葙子又名草决明，清肝火，明目退翳。主治目赤肿痛，羞明多泪。倪海厦经验，青葙子配决明子，治肝火目赤。瞳孔散大者忌用，因能扩瞳。",
        "dosage": "一钱至三钱。",
        "contraindication": "瞳孔散大者忌用。",
        "herb_comparisons": ["青葙子又名草决明，与决明子功用相近。", "青葙子能扩瞳，瞳孔散大者忌用。"]
    },
    {
        "name": "桐叶",
        "original": "味苦寒无毒，主恶蚀阴疮，五痔杀三虫。",
        "action": "桐叶为清热解毒药，主痈肿疮毒。",
        "nature_category": "寒",
        "flavor": "苦",
        "meridians": ["肝"],
        "category": "清热药",
        "clinical_notes": "桐叶，清热解毒，消肿止痛。主治痈肿疮毒，恶疮痔漏。桐皮亦入药，名桐皮，主治相同。倪海厦较少单独使用此药。",
        "dosage": "一钱至三钱，外用适量。",
        "contraindication": "脾胃虚寒者慎用。",
        "herb_comparisons": ["桐叶与桐皮功用相近。"]
    },
    {
        "name": "菟花",
        "original": "味苦寒有毒，主伤寒温疟，下十二水，破积聚大坚症瘕，荡涤肠胃中留癖饮食，寒热邪气，利水道。",
        "action": "菟花为峻下逐水药，主水肿胀满。",
        "nature_category": "寒",
        "flavor": "苦",
        "meridians": ["肺", "肾", "大肠"],
        "category": "峻下逐水药",
        "clinical_notes": "菟花有毒，峻下逐水，力量猛烈。主治水肿胀满，痰饮积聚。倪海厦指出此药与芫花同类，但力稍缓。非实证不可用，体虚者禁。",
        "dosage": "五分至一钱。",
        "contraindication": "有毒，体虚者禁用。反甘草。",
        "herb_comparisons": ["菟花与芫花功用相近，力稍缓。", "菟花反甘草。"]
    },
    {
        "name": "牙子",
        "original": "味苦寒有毒，主邪气热气，疥瘙恶疡痔疮，去白虫，一名狼牙。",
        "action": "牙子为杀虫解毒药，主疥癣恶疮。",
        "nature_category": "寒",
        "flavor": "苦",
        "meridians": ["肝"],
        "category": "杀虫药",
        "clinical_notes": "牙子又名狼牙草，杀虫解毒，燥湿止痒。主治疥癣恶疮，痔疮下血。古方用治寸白虫（绦虫）。此药现在少用，多以其他杀虫药代替。",
        "dosage": "一钱至二钱，外用适量。",
        "contraindication": "有毒，内服宜慎。",
        "herb_comparisons": ["牙子又名狼牙草，杀虫止痒。"]
    },
    {
        "name": "藿菌",
        "original": "味咸平无毒，主心痛温中，去长虫白癣蜣虫，蛇螫毒，症瘕诸虫，一名藿芦。",
        "action": "藿菌为杀虫消积药，主虫积腹痛。",
        "nature_category": "平",
        "flavor": "咸",
        "meridians": ["胃", "大肠"],
        "category": "杀虫药",
        "clinical_notes": "藿菌，杀虫消积，主治虫积腹痛，疥癣瘙痒。此药现少用，临床多以使君子、槟榔等代替。",
        "dosage": "一钱至二钱。",
        "contraindication": "体虚者慎用。",
        "herb_comparisons": ["藿菌杀虫，近似使君子、槟榔之功。"]
    },
    {
        "name": "冬灰",
        "original": "味辛微温有毒，主黑子去疣息肉，疽蚀疥瘙。",
        "action": "冬灰为外用去赘药，主疣赘恶疮。",
        "nature_category": "温",
        "flavor": "辛",
        "meridians": [],
        "category": "外用药",
        "clinical_notes": "冬灰即藜灰，烧灰淋汁，外用去疣赘、蚀恶疮。倪海厦指出此为古法外用药，现代少用。辛温有毒，不可内服。",
        "dosage": "外用适量。",
        "contraindication": "有毒，仅可外用，不可内服。",
        "herb_comparisons": ["冬灰为古法外用药，现代少用。"]
    },
    {
        "name": "蒺藜子",
        "original": "味苦温无毒，主恶血破症结积聚，喉痹乳难，久服长肌肉，明目轻身，又名沙苑蒺藜。",
        "action": "蒺藜子为平肝明目药，主头痛眩目赤。",
        "nature_category": "温",
        "flavor": "苦",
        "meridians": ["肝", "肺"],
        "category": "平肝息风药",
        "clinical_notes": "蒺藜子又名白蒺藜、沙苑子，平肝疏肝，明目祛风。主治头痛眩晕，目赤多泪，乳闭不通。倪海厦经验，白蒺藜配菊花、决明子，治肝火目赤。沙苑子则偏于补肾固精。",
        "dosage": "一钱至三钱。",
        "contraindication": "血虚生风者慎用。",
        "herb_comparisons": ["白蒺藜平肝疏肝，沙苑子补肾固精，功用有别。", "蒺藜子配菊花决明子治肝火目赤。"]
    },
    {
        "name": "蓍实",
        "original": "味苦平无毒，主益气充肌肤，明目聪慧先知，久服不饥不老轻身。",
        "action": "蓍实为补益药，主明目益气。",
        "nature_category": "平",
        "flavor": "苦",
        "meridians": ["肝", "肾"],
        "category": "补益药",
        "clinical_notes": "蓍实即蓍草之果实，古称'先知草'，主明目聪慧。此药现代少用，多作为占卜之用而非药用。补益之力较弱。",
        "dosage": "一钱至二钱。",
        "contraindication": "现代少用，无明显禁忌。",
        "herb_comparisons": ["蓍实现代多作占卜用，药用较少。"]
    },
    {
        "name": "大豆黄卷",
        "original": "味甘平无毒，主湿痹筋挛膝痛，五脏胃气结积，益气止毒，润肌肤。",
        "action": "大豆黄卷为清热利湿药，主湿痹拘挛。",
        "nature_category": "平",
        "flavor": "甘",
        "meridians": ["脾", "胃"],
        "category": "利水渗湿药",
        "clinical_notes": "大豆黄卷即发芽大豆，清热利湿，舒筋通络。主治湿痹拘挛，骨节疼痛。倪海厦认为大豆黄卷利水祛湿，作用平和。又有解表之功。",
        "dosage": "二钱至四钱。",
        "contraindication": "无特殊禁忌。",
        "herb_comparisons": ["大豆黄卷即发芽大豆，利水祛湿兼解表。"]
    },
    {
        "name": "水萍",
        "original": "味辛寒无毒，主暴热身痒，下水气胜酒，长须发止消渴，久服轻身。",
        "action": "水萍为发汗利水药，主风水浮肿。",
        "nature_category": "寒",
        "flavor": "辛",
        "meridians": ["肺"],
        "category": "解表药",
        "clinical_notes": "水萍又名浮萍，发汗解表，透疹止痒，利水消肿。主治风热感冒，麻疹不透，风水浮肿，皮肤瘙痒。倪海厦经验，浮萍配蝉蜕透疹，配紫苏发汗。浮萍轻浮上行，走表发汗力强。",
        "dosage": "一钱至二钱。",
        "contraindication": "自汗者忌用。",
        "herb_comparisons": ["浮萍发汗力强，自汗者忌用。", "浮萍配蝉蜕透疹，配紫苏发汗。"]
    }
]

def main():
    with open(HERBS_JSON, 'r', encoding='utf-8') as f:
        data = json.load(f)

    existing = {h['name'] for h in data['herbs']}
    added = 0

    for herb in NEW_HERBS:
        if herb['name'] not in existing:
            data['herbs'].append(herb)
            added += 1
        else:
            print(f"  SKIP (already exists): {herb['name']}")

    data['total'] = len(data['herbs'])

    with open(HERBS_JSON, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Added {added} herbs, total now {data['total']}")

if __name__ == '__main__':
    main()
