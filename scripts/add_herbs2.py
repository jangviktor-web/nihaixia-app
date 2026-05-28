#!/usr/bin/env python3
"""补充用户提供的礜石/五色石脂/鹿茸/蜈蚣/虾蟆等药物数据"""
import json

HERBS_JSON = r"D:\360Downloads\nihaisha_app\assets\data\herbs.json"

# 需要新增的药物
NEW_HERBS = [
    {
        "name": "五色石脂",
        "original": "青石、赤石、黄石、白石、黑石脂等，味甘平。主黄疸，泄利，肠澼脓血，阴蚀，下血赤白，邪气，痈肿，疽痔，恶疮，头疡，疥瘙。久服补髓益气，肥健，不饥，轻身延年。五石脂，各随五色补五脏。生山谷中。",
        "action": "五石脂为涩剂，收敛固涩、止血止泻、生肌敛疮。各随五色补五脏。",
        "nature_category": "平",
        "flavor": "甘",
        "meridians": ["脾", "胃", "大肠"],
        "category": "收涩药",
        "clinical_notes": "五石脂统称石脂，质地滑腻如脂，善收敛固涩、止血、止泻、生肌。核心主治：久泻久痢、大便脓血、脱肛、崩漏、带下、痔疮出血、溃疡不敛。配伍：常配禹余粮治虚寒久痢、滑脱不禁，如赤石脂禹余粮汤。经方：乌头赤石脂丸（治心痛彻背、背痛彻心，寒凝心脉）；桃花汤（赤石脂+干姜+粳米，治少阴病下利脓血）。各随五色补五脏：青入肝、赤入心、黄入脾、白入肺、黑入肾，收敛兼补，涩而不滞。禁忌：湿热泻痢初起、里急后重、实热崩带者禁用。",
        "dosage": "三钱至五钱。",
        "contraindication": "湿热泻痢初起、里急后重、实热崩带者禁用（涩则闭门留寇）。",
        "herb_comparisons": ["赤石脂禹余粮汤：二药同属涩剂，治虚寒久痢滑脱。", "青入肝、赤入心、黄入脾、白入肺、黑入肾，五色分补五脏。"]
    },
    {
        "name": "青石脂",
        "original": "五色石脂之一，色青，味甘平。各随五色补五脏。",
        "action": "青石脂入肝，养肝胆气，明目，主黄疸、目疾、惊痫。",
        "nature_category": "平",
        "flavor": "甘",
        "meridians": ["肝", "胆"],
        "category": "收涩药",
        "clinical_notes": "青石脂色青入肝，养肝胆气、明目。主治黄疸、目疾、惊痫。属五色石脂之一，收敛固涩兼养肝。",
        "dosage": "三钱至五钱。",
        "contraindication": "实热证禁用。",
        "herb_comparisons": ["青石脂入肝，赤石脂入心，黄石脂入脾，白石脂入肺，黑石脂入肾。"]
    },
    {
        "name": "黄石脂",
        "original": "五色石脂之一，色黄，味甘平。各随五色补五脏。",
        "action": "黄石脂入脾，养脾气、除黄疸、止泻痢、厚肠胃。",
        "nature_category": "平",
        "flavor": "甘",
        "meridians": ["脾", "胃"],
        "category": "收涩药",
        "clinical_notes": "黄石脂色黄入脾，养脾气、除黄疸、止泻痢、厚肠胃。属五色石脂之一，收敛固涩兼补脾。",
        "dosage": "三钱至五钱。",
        "contraindication": "实热证禁用。",
        "herb_comparisons": ["黄石脂入脾，与赤石脂配伍可兼顾心脾。"]
    },
    {
        "name": "白石脂",
        "original": "五色石脂之一，色白，味甘平。各随五色补五脏。",
        "action": "白石脂入肺，敛肺气、止久咳、固肠、治痔漏、脱肛。",
        "nature_category": "平",
        "flavor": "甘",
        "meridians": ["肺", "大肠"],
        "category": "收涩药",
        "clinical_notes": "白石脂色白入肺，敛肺气、止久咳、固肠。主治痔漏、脱肛、久咳不止。属五色石脂之一，收敛固涩兼敛肺。",
        "dosage": "三钱至五钱。",
        "contraindication": "实热证禁用。",
        "herb_comparisons": ["白石脂入肺，与禹余粮配伍治脱肛。"]
    },
    {
        "name": "黑石脂",
        "original": "五色石脂之一，色黑，味甘平。各随五色补五脏。",
        "action": "黑石脂入肾，养肾气、强阴、主阴蚀、带下、腰膝冷。",
        "nature_category": "平",
        "flavor": "甘",
        "meridians": ["肾"],
        "category": "收涩药",
        "clinical_notes": "黑石脂色黑入肾，养肾气、强阴。主治阴蚀、带下、腰膝冷。属五色石脂之一，收敛固涩兼补肾。",
        "dosage": "三钱至五钱。",
        "contraindication": "实热证禁用。",
        "herb_comparisons": ["黑石脂入肾，与赤石脂配伍可兼顾心肾。"]
    },
    {
        "name": "鹿茸",
        "original": "味甘温。主漏下恶血，寒热，惊痫，益气强志，生齿不老。角，主恶创痈肿，逐邪恶气，留血在阴中。",
        "action": "鹿茸为补督脉要药，大补真阳、生精充髓、强筋健骨。",
        "nature_category": "温",
        "flavor": "甘咸",
        "meridians": ["肾", "肝", "督脉"],
        "category": "补阳药",
        "clinical_notes": "鹿茸甘咸温，大补督脉、补真阳、生精充髓、强筋健骨。治老人精衰、腰膝无力、阳痿滑精、眩晕、妇人崩漏带下。督脉为一身阳气之本，鹿茸补督最强；任脉用龟板。脑瘤、督阳不足、脊椎病常用。阴虚火旺、血逆火逆者禁用。经方中鹿茸多入丸散，不入汤剂。",
        "dosage": "五分至一钱，研末冲服或入丸散。",
        "contraindication": "阴虚火旺、血逆火逆者禁用。外感发热忌用。",
        "herb_comparisons": ["鹿茸补督脉（阳），龟板补任脉（阴），阴阳对药。", "鹿茸壮阳力最强，淫羊藿、巴戟天力较缓。"]
    },
    {
        "name": "蜈蚣",
        "original": "味辛温。主鬼注蛊毒，啖诸蛇虫鱼毒，杀鬼物老精，温虐，去三虫。生川谷。",
        "action": "蜈蚣为祛风攻坚要药，祛风散结、解毒镇惊。",
        "nature_category": "温",
        "flavor": "辛",
        "meridians": ["肝"],
        "category": "息风止痉药",
        "clinical_notes": "蜈蚣辛温有毒，祛风、散结、解毒、攻坚、镇惊。治蛇虫咬伤、破伤风、小儿惊痫、癫痫、淋巴肿块、肝癌硬块。攻坚力强但伤血，须配补血药（如当归、熟地）。剂量1-3g（1钱），不可多服；孕妇禁用。蜈蚣畏蟾蜍（湿土胜燥金），可解蜈蚣毒。",
        "dosage": "一至三条（1-3g），研末冲服。",
        "contraindication": "有毒，孕妇禁用。血虚生风者慎用。",
        "herb_comparisons": ["蜈蚣祛风攻坚力强，全蝎力较缓，二者常相须为用。", "蜈蚣畏蟾蜍，蟾蜍可解蜈蚣毒。"]
    },
    {
        "name": "虾蟆",
        "original": "味辛寒。主邪气，破症坚，血痈肿，阴创。服之不患热病。生池泽。",
        "action": "虾蟆（蟾蜍）为清热解毒要药，破癥散结、消肿止痛。",
        "nature_category": "寒",
        "flavor": "辛",
        "meridians": ["心", "肝", "脾"],
        "category": "清热解毒药",
        "clinical_notes": "虾蟆即蟾蜍，辛寒有毒，清热解毒、消肿止痛、破癥散结。治痈疽恶疮、瘰疬、阴蚀、肿瘤、疳积、小儿痨热。蟾酥（分泌物）强心、止痛、抗癌，外用为主，内服极少量。蜈蚣畏蟾蜍（湿土胜燥金），可解蜈蚣毒。",
        "dosage": "外用适量；蟾酥内服极少量（厘毫级）。",
        "contraindication": "有毒，内服宜极慎。孕妇禁用。",
        "herb_comparisons": ["蟾蜍秉湿土之气，能胜蜈蚣燥金之毒。", "蟾酥强心止痛，外用为主。"]
    },
    {
        "name": "蟪虫",
        "original": "蟪虫疑为虻虫或蟅虫之误。虻虫：味苦微寒，主逐瘀血，破下血积坚癖癥瘕寒热，通利血脉及九窍。",
        "action": "蟪虫（虻虫）为破血逐瘀药，主治经闭癥瘕。",
        "nature_category": "寒",
        "flavor": "苦",
        "meridians": ["肝"],
        "category": "活血化瘀药",
        "clinical_notes": "蟪虫疑为虻虫之误。虻虫苦微寒，破血逐瘀力猛，治经闭、癥瘕、跌打瘀血。体虚忌用。飞虫吸血，入血分攻瘀，性刚猛，专破沉疴瘀血。大黄蟅虫丸中蟅虫与此相近。",
        "dosage": "五分至一钱。",
        "contraindication": "体虚无瘀者忌用。孕妇禁用。",
        "herb_comparisons": ["虻虫破血逐瘀力猛，水蛭力较缓，二者常相须为用。"]
    },
    {
        "name": "牡狗阴茎",
        "original": "味咸平。主伤中，阴痿不起，令强热大，生子，除女子带下十二疾。一名狗精。胆主明目。",
        "action": "牡狗阴茎为补肾壮阳药，主治阳痿宫寒。",
        "nature_category": "平",
        "flavor": "咸",
        "meridians": ["肾", "肝"],
        "category": "补阳药",
        "clinical_notes": "牡狗阴茎咸平，补肾壮阳、强筋、益精、暖宫。治肾虚阳痿、早泄、宫寒不孕、女子带下。现在临床极少用，多以鹿茸、淫羊藿、巴戟天替代。狗性燥烈善走补肾阳；阴茎为至阳之物，专补命门火衰。咸能入肾，温而不燥，壮阳而不伤阴。",
        "dosage": "现少用，入丸散适量。",
        "contraindication": "阴虚火旺者忌用。",
        "herb_comparisons": ["牡狗阴茎现少用，多以鹿茸替代。"]
    },
]

# 需要更新已有药物的内容
UPDATE_HERBS = {
    "礜石": {
        "clinical_notes": "礜石辛热大毒，类似砒石但偏热痹寒积。主寒凝冷积、顽固风湿痹痛、关节变形、阴疽冷疮、久不愈合。能蚀死肌、消坚癖、破寒痰；外用治恶疮、瘘管、腐肉。剧毒！内服必须严格炮制、限量（几分），久煎或配蜂蜜减毒。经方：五石乌头丸用礜石，治沉寒痼冷、关节剧痛。",
        "historical_notes": "【唐荣川】礜石辛热燥烈，毒而善走，专破沉寒锢冷、阴邪死肌。与砒石同类：砒石偏劫痰截疟，礜石偏温经蚀痹、消坚癖。治鼠瘘、蚀疮、死肌，是寒痰瘀血凝结，毒深而肌死；非大热不足以破冰散寒。",
        "herb_comparisons": ["礜石与砒石同类，砒石偏劫痰截疟，礜石偏温经蚀痹。", "五石乌头丸用礜石，治沉寒痼冷。"]
    },
    "赤石脂": {
        "clinical_notes": "赤石脂甘平涩剂，收敛固涩、止血止泻、生肌敛疮。色赤入心，养心气、涩肠止血。主治久痢、崩漏、带下、疮口不敛。经方：赤石脂禹余粮汤治虚寒久痢滑脱不禁；乌头赤石脂丸治心痛彻背、背痛彻心；桃花汤（赤石脂+干姜+粳米）治少阴病下利脓血。配禹余粮增强涩肠固脱之力。",
        "historical_notes": "【唐荣川】赤石脂味甘质涩，性平而敛，属土性金石，专入脾胃兼五脏。主泄利肠澼脓血，湿浊下注、肠滑不固、气血不收；石脂涩肠固脱、渗湿和血。痈肿疽痔恶疮，湿毒浸淫、溃烂不敛；石脂收湿生肌、解毒敛疮，为外用收口要药。",
        "herb_comparisons": ["赤石脂配禹余粮，治虚寒久痢滑脱。", "桃花汤：赤石脂+干姜+粳米，治少阴下利脓血。"]
    },
    "蟅虫": {
        "clinical_notes": "蟅虫即土鳖虫、地鳖虫，咸寒，破血逐瘀、续筋接骨、消癥散结。治瘀血闭经、产后瘀阻、癥瘕痞块、跌打骨折、瘀血肿痛。经方：大黄蟅虫丸治五劳虚极、干血痨、肌肤甲错。孕妇禁用；体虚者配益气养血药。",
        "historical_notes": "【唐荣川】蟅虫生于下湿土壤、得幽暗之气，性阴、善入血分。咸能软坚、寒能清热，破血而不伤新血，逐瘀而能生新，为瘀血要药。",
        "herb_comparisons": ["蟅虫破血逐瘀，配大黄攻下瘀血。", "大黄蟅虫丸：治五劳虚极、干血痨。"]
    },
    "翳螉": {
        "clinical_notes": "翳螉即土蜂，清热解毒、消肿、治疮疡、丹毒、蛇伤。外用为主。蜂类秉火气，能解毒消肿、散风热，治热毒疮痈。",
        "historical_notes": "【唐荣川】蜂类秉火气，能解毒消肿、散风热，治热毒疮痈。",
        "herb_comparisons": ["翳螉清热解毒外用，与蟾蜍功用相近。"]
    },
    "蚱蝉": {
        "clinical_notes": "蚱蝉即鸣蝉，咸寒，清热、息风、镇惊、安神、止痒。治小儿惊风、夜啼、癫痫、发热、风疹、皮肤瘙痒。蝉蜕（壳）功效更强，散风热、明目退翳、治咽痛音哑。蝉感秋金之气，性凉，能清肝胆风热、息风止痉。",
        "historical_notes": "【唐荣川】蝉感秋金之气，性凉，能清肝胆风热、息风止痉。咸寒入肝，平肝阳、息肝风、定惊痫、除寒热，小儿热盛惊风最宜。",
        "herb_comparisons": ["蚱蝉清热息风，蝉蜕散风热明目退翳，壳比虫力更强。"]
    },
}

def main():
    with open(HERBS_JSON, 'r', encoding='utf-8') as f:
        data = json.load(f)

    existing_names = {h['name'] for h in data['herbs']}
    added = 0
    updated = 0

    # 1. 更新已有药物
    for name, fields in UPDATE_HERBS.items():
        for h in data['herbs']:
            if h['name'] == name:
                for k, v in fields.items():
                    if v and (k not in h or not h[k] or (isinstance(h[k], str) and len(v) > len(h[k]))):
                        h[k] = v
                        updated += 1
                break

    # 2. 添加新药物
    for herb in NEW_HERBS:
        if herb['name'] not in existing_names:
            data['herbs'].append(herb)
            added += 1
        else:
            # 已存在则更新
            for h in data['herbs']:
                if h['name'] == herb['name']:
                    for k, v in herb.items():
                        if k == 'name':
                            continue
                        if v and (k not in h or not h[k] or (isinstance(h[k], str) and len(v) > len(h[k]))):
                            h[k] = v
                            updated += 1
                    break

    data['total'] = len(data['herbs'])

    with open(HERBS_JSON, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

    print(f"Added: {added}, Updated: {updated}, Total: {data['total']}")

if __name__ == '__main__':
    main()
