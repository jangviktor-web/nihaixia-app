#!/usr/bin/env python3
"""Parse 09_zhenjiu_bencao.md into structured herbs.json"""
import re
import json

INPUT = r"D:\CW\Data\Skills\nihaisha-perspective\modules\09_zhenjiu_bencao.md"
OUTPUT = r"D:\360Downloads\nihaisha_app\assets\data\herbs.json"

# Section names that map to our fields
SECTION_MAP = {
    "原文": "original",
    "性味": "nature",
    "主治": "action",
    "容川": "rongchuan",
    "倪注": "ni_note",
    "用量": "dosage",
    "禁忌": "contraindication",
}

# Headers to skip (not herbs)
SKIP_HEADERS = {
    "药性总义（倪海厦批注版）", "上经（127种）", "中经（101种）", "下经（117种）",
    "人纪·针灸教程", "人纪·神农本草经", "推荐书目", "汉唐中医诊疗",
    "倪海厦临床常用51味关键药物",
    # 非草药文本段落
    "天行健，君子以自强不息；地势坤，君子以厚德载物。",
    "古典必读（七大经典）：", "近代优良中医书籍：", "倪师推荐英文书籍：",
    "中医理论基础：", "乳癌形成机制：", "更年期妇女须知：",
    "乳癌七大高危因素：", "核心观点：", "便秘与五脏皆有关：",
    "健康标准：", "健康小宝贝的七大标准：", "扁桃腺发炎简便方：",
    "高血压药物：", "血糖过高：", "胆固醇过高：",
    "维他命与钙片：", "阿斯匹林：", "女性荷尔蒙：",
    "抗生素副作用：", "长寿村启示（中国长江卢沟村）：",
    "日常保养方案：", "核心论点：", "中医瘀血理论（驳斥阿斯匹林）：",
    "心脏病预防六法：", "正统中医观点：", "成因：",
    "预防四法：", "药性论：", "教学方式：",
    "南派vs北派核心区别：", "收徒面相八不收：", "倪师教感冒的效率对比：",
}


def parse_herbs(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    herbs = []
    current_herb = None
    current_section = None
    current_text = []

    def flush_section():
        nonlocal current_section, current_text
        if current_herb and current_section:
            text = " ".join(current_text).strip()
            # Clean up: remove page markers like "倪注神农本草经 V100415.01 12"
            text = re.sub(r'倪注神农本草经\s*V\d+\.\d+\s*\d+', '', text)
            text = re.sub(r'\s+', ' ', text).strip()
            if text:
                current_herb[current_section] = text
        current_section = None
        current_text = []

    def flush_herb():
        nonlocal current_herb
        flush_section()
        if current_herb and current_herb.get("name"):
            herbs.append(current_herb)
        current_herb = None

    for line in lines:
        stripped = line.strip()

        # Match herb name: **Name**
        herb_match = re.match(r'^\*\*(.+?)\*\*\s*$', stripped)
        if herb_match:
            name = herb_match.group(1).strip()
            if name in SKIP_HEADERS or "经（" in name or "目）" in name:
                continue
            flush_herb()
            current_herb = {"name": name}
            continue

        # Match section header: - XXX： or - **XXX**：
        # The source file uses "- 原文：" format (no bold)
        sec_match = re.match(r'^-\s*\*{0,2}(\w+?)\*{0,2}[：:]\s*(.*)', stripped)
        if sec_match and current_herb:
            sec_name = sec_match.group(1).strip()
            rest = sec_match.group(2).strip()
            if sec_name in SECTION_MAP:
                flush_section()
                current_section = SECTION_MAP[sec_name]
                current_text = [rest] if rest else []
            else:
                # Unknown section, skip content
                flush_section()
            continue

        # Match 倪师临床口述
        if "倪师临床口述" in stripped and current_herb:
            flush_section()
            current_section = "clinical_notes"
            current_text = []
            continue

        # Continue current section (accumulate text)
        if current_section and current_herb:
            # Remove leading "- " from continuation lines
            if stripped.startswith("- "):
                stripped = stripped[2:]
            if stripped:
                current_text.append(stripped)

    flush_herb()
    return herbs


def classify_herb(herb):
    """Classify herb based on nature and action text"""
    nature = herb.get("nature", "")
    action = herb.get("action", "")
    name = herb.get("name", "")

    # Nature category (寒/凉/平/温/热)
    nature_cat = "平"
    for token, cat in [("大热", "热"), ("大寒", "寒"), ("热", "温"), ("温", "温"),
                        ("寒", "寒"), ("凉", "凉"), ("平", "平")]:
        if token in nature:
            nature_cat = cat
            break

    # Flavor (辛甘苦酸咸淡)
    flavor = ""
    for f in ["辛", "甘", "苦", "酸", "咸", "淡"]:
        if f in nature:
            flavor += f

    # Meridians
    meridians = []
    meridian_kw = {"肺": "肺", "肝": "肝", "心": "心", "脾": "脾", "肾": "肾",
                   "胃": "胃", "胆": "胆", "大肠": "大肠", "小肠": "小肠",
                   "膀胱": "膀胱", "三焦": "三焦", "心包": "心包"}
    for kw, m in meridian_kw.items():
        if kw in action or kw in name:
            meridians.append(m)

    # Category from action keywords
    cat = "其他"
    cat_kw = [
        # 解表药
        ("解表", "解表药"), ("发表", "解表药"), ("发汗", "解表药"), ("散风", "解表药"),
        ("升阳", "解表药"), ("宣肺", "解表药"), ("通窍", "解表药"), ("开窍", "解表药"),
        ("宣窍", "解表药"), ("鼻渊", "解表药"), ("鼻塞", "解表药"),
        # 清热药
        ("清热", "清热药"), ("泻火", "清热药"), ("凉血", "清热药"), ("解毒", "清热药"),
        ("除烦", "清热药"), ("去热", "清热药"), ("泻实热", "清热药"), ("清虚热", "清热药"),
        ("散结", "清热药"), ("消痈", "清热药"), ("散热毒", "清热药"), ("散毒", "清热药"),
        ("泻肝", "清热药"), ("清火", "清热药"), ("凉肝胆", "清热药"),
        # 补益药
        ("补气", "补益药"), ("补血", "补益药"), ("滋阴", "补益药"), ("养血", "补益药"),
        ("补阳", "补益药"), ("益精", "补益药"), ("大补元气", "补益药"),
        ("强肾", "补益药"), ("益肝", "补益药"), ("补髓", "补益药"),
        ("补中", "补益药"), ("益气", "补益药"), ("补肺", "补益药"), ("补脾", "补益药"),
        ("补腰", "补益药"), ("补命门", "补益药"), ("壮阳", "补益药"),
        ("固精", "补益药"), ("强壮", "补益药"), ("养阴", "补益药"), ("养心", "补益药"),
        ("益智", "补益药"), ("坚筋骨", "补益药"), ("补肝肾", "补益药"),
        ("补涩", "补益药"), ("收敛", "补益药"), ("固涩", "补益药"), ("敛", "补益药"),
        ("安胎", "补益药"), ("生津", "补益药"), ("和解百药", "补益药"),
        # 温里药
        ("温里", "温里药"), ("回阳", "温里药"), ("散寒", "温里药"), ("温中", "温里药"),
        ("暖胃", "温里药"), ("温经", "温里药"), ("温肺", "温里药"),
        # 利水渗湿药
        ("利水", "利水渗湿药"), ("渗湿", "利水渗湿药"), ("化饮", "利水渗湿药"),
        ("去湿", "利水渗湿药"), ("利小便", "利水渗湿药"), ("消肿", "利水渗湿药"),
        ("利尿", "利水渗湿药"), ("排水", "利水渗湿药"), ("行水", "利水渗湿药"),
        ("利二便", "利水渗湿药"), ("通淋", "利水渗湿药"), ("除湿", "利水渗湿药"),
        ("黄疸", "利水渗湿药"), ("下膀胱水", "利水渗湿药"),
        # 化痰止咳药
        ("化痰", "化痰止咳药"), ("止咳", "化痰止咳药"), ("平喘", "化痰止咳药"),
        ("祛痰", "化痰止咳药"), ("降气", "化痰止咳药"), ("下气", "化痰止咳药"),
        ("降痰", "化痰止咳药"), ("祛风散结", "化痰止咳药"),
        # 活血化瘀药
        ("活血", "活血化瘀药"), ("去瘀", "活血化瘀药"), ("逐血", "活血化瘀药"),
        ("通经", "活血化瘀药"), ("破血", "活血化瘀药"), ("行血", "活血化瘀药"),
        ("散血", "活血化瘀药"), ("下瘀", "活血化瘀药"), ("破症瘕", "活血化瘀药"),
        ("化瘀", "活血化瘀药"), ("调经", "活血化瘀药"), ("通血脉", "活血化瘀药"),
        ("续筋骨", "活血化瘀药"), ("折伤瘀血", "活血化瘀药"),
        # 止血药
        ("止血", "止血药"), ("止崩", "止血药"), ("泻血", "止血药"),
        ("崩带", "止血药"), ("下血", "止血药"),
        # 安神药
        ("安神", "安神药"), ("镇静", "安神药"), ("定魂魄", "安神药"),
        ("安心神", "安神药"), ("镇纳浮阳", "安神药"),
        # 理气/消食药
        ("理气", "理气药"), ("行气", "理气药"), ("消食", "消食药"), ("开胃", "消食药"),
        ("健胃", "理气药"), ("荡涤肠胃", "理气药"), ("行滞", "理气药"),
        ("消炎", "理气药"), ("推陈致新", "理气药"),
        # 祛风湿药
        ("祛风", "祛风湿药"), ("痹", "祛风湿药"), ("风湿", "祛风湿药"),
        ("拘急", "祛风湿药"), ("半身不遂", "祛风湿药"),
        # 泻下药
        ("攻下", "泻下药"), ("泻下", "泻下药"), ("峻下", "泻下药"), ("通便", "泻下药"),
        ("滑肠", "泻下药"), ("荡积滞", "泻下药"),
        # 涌吐药
        ("涌吐", "涌吐药"), ("催吐", "涌吐药"), ("以吐取之", "涌吐药"),
        # 杀虫药
        ("杀虫", "杀虫药"), ("驱虫", "杀虫药"), ("辟邪恶", "杀虫药"),
        # 外用药
        ("外用", "外用药"), ("蚀疮", "外用药"), ("生肌", "外用药"),
        ("敷", "外用药"), ("疥癣", "外用药"),
        # 明目药
        ("明目", "明目药"), ("目疾", "明目药"), ("眼病", "明目药"),
        ("退翳", "明目药"), ("障翳", "明目药"), ("青盲", "明目药"),
        # 通乳药
        ("下乳", "通乳药"), ("催乳", "通乳药"), ("乳脉不通", "通乳药"),
        # 痔疮药
        ("五痔", "痔疮药"), ("痔", "痔疮药"),
    ]
    for kw, c in cat_kw:
        if kw in action:
            cat = c
            break

    # Fallback: classify by name patterns for herbs with no action text
    if cat == "其他" and not action:
        name_kw = [
            ("石", "矿石药"), ("英", "矿石药"), ("脂", "动物药"),
            ("角", "动物药"), ("胆", "动物药"), ("皮", "动物药"),
            ("蜕", "动物药"), ("虫", "动物药"), ("虻", "动物药"),
            ("蚕", "动物药"), ("蝉", "动物药"), ("蛇", "动物药"),
            ("鸡", "动物药"), ("雁", "动物药"), ("鱼", "动物药"),
            ("蟹", "动物药"), ("鼠", "动物药"), ("萤", "动物药"),
            ("雀", "动物药"), ("燕", "动物药"), ("猬", "动物药"),
            ("蠊", "动物药"), ("蝥", "动物药"), ("螂", "动物药"),
            ("蛾", "动物药"), ("卵", "动物药"), ("脂", "动物药"),
            ("实", "种子药"), ("子", "种子药"), ("米", "谷物药"),
            ("麦", "谷物药"), ("粟", "谷物药"), ("黍", "谷物药"),
            ("豆", "谷物药"), ("葱", "蔬菜药"),
            ("草", "草药"), ("蒿", "草药"), ("芦", "草药"),
            ("兰", "草药"), ("蒲", "草药"), ("蔻", "草药"),
            ("耳", "草药"), ("椒", "草药"), ("花", "花类药"),
            ("根", "根茎药"), ("皮", "皮类药"),
        ]
        for kw, c in name_kw:
            if kw in name:
                cat = c
                break

    # Specific herb mappings for well-known herbs with missing/unclear action text
    HERB_MAP = {
        "白石英": "矿石药", "曾青": "矿石药", "太一余粮": "矿石药",
        "白青": "矿石药", "扁青": "矿石药", "雌黄": "矿石药",
        "孔公孽": "矿石药", "殷孽": "矿石药", "青琅玕": "矿石药",
        "卤咸": "矿石药", "理石": "矿石药", "长石": "矿石药",
        "阳起石": "矿石药", "云母": "矿石药",
        "赤芝黑芝青芝白芝黄芝紫芝": "补益药",
        "防葵": "利水渗湿药", "营实": "利水渗湿药",
        "白兔藿": "清热药", "别羁": "祛风湿药", "屈草": "草药",
        "淮木": "草药", "蕤核": "明目药", "女菀": "草药",
        "王孙": "清热药", "爵床": "活血化瘀药", "芜荑": "杀虫药",
        "白棘": "草药", "蛴螬": "动物药", "蛞蝓": "动物药",
        "天雄": "温里药", "鸢尾": "解表药", "钩吻": "杀虫药",
        "雚菌": "利水渗湿药", "大戟": "泻下药", "茵芋": "祛风湿药",
        "狼毒": "杀虫药", "鬼臼": "清热药", "羊桃": "利水渗湿药",
        "女青": "清热药", "蔺茹": "活血化瘀药", "鹿藿": "清热药",
        "古南": "草药", "黄环": "利水渗湿药", "溲疏": "利水渗湿药",
        "六畜毛蹄甲": "动物药", "马刀": "动物药",
        "蜣螂": "泻下药", "马陆": "动物药", "衣鱼": "利水渗湿药",
        "腐婢": "清热药", "豆豉": "解表药",
        "蒴翟细叶": "草药", "甘李根白皮": "清热药",
        "乌头": "温里药", "干姜": "温里药", "黄连": "清热药",
        "蠡实": "利水渗湿药", "败酱": "清热药", "白鲜皮": "清热药",
        "旋华": "补益药", "蓬蘽": "补益药", "苋实": "种子药",
        "白瓜子": "种子药", "苦菜": "清热药", "木兰": "解表药",
        "桑上寄生": "补益药", "杜仲": "补益药",
    }
    if cat == "其他" and name in HERB_MAP:
        cat = HERB_MAP[name]

    return {"nature_category": nature_cat, "flavor": flavor,
            "meridians": meridians, "category": cat}


def main():
    herbs = parse_herbs(INPUT)

    for herb in herbs:
        cls = classify_herb(herb)
        herb.update(cls)
        if "clinical_notes" in herb and not herb["clinical_notes"].strip():
            del herb["clinical_notes"]

    output = {
        "total": len(herbs),
        "source": "倪海厦人纪系列神农本草经讲义（154页PDF校勘版+339页视频同步文稿）",
        "herbs": herbs,
    }

    with open(OUTPUT, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)

    # Stats
    cats = {}
    for h in herbs:
        c = h.get("category", "其他")
        cats[c] = cats.get(c, 0) + 1
    with_nature = sum(1 for h in herbs if h.get("nature"))
    with_action = sum(1 for h in herbs if h.get("action"))
    print(f"Total: {len(herbs)} herbs")
    print(f"With nature: {with_nature}, With action: {with_action}")
    print("Categories:")
    for c, n in sorted(cats.items(), key=lambda x: -x[1]):
        print(f"  {c}: {n}")


if __name__ == "__main__":
    main()
