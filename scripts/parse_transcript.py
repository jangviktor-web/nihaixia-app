#!/usr/bin/env python3
"""从神农本草经视频文稿中提取临床口述、历代医家注释、药物比较"""
import re
import json
import sys

TRANSCRIPT = r"D:\nhx\倪海厦\人纪-3-神农本草经\神农本草-视频同步文稿.md"
HERBS_JSON = r"D:\360Downloads\nihaisha_app\assets\data\herbs.json"

# 中文数字转换
CN_NUM = {'零':0,'一':1,'二':2,'三':3,'四':4,'五':5,'六':6,'七':7,'八':8,'九':9,
           '十':10,'十一':11,'十二':12,'十三':13,'十四':14,'十五':15,'十六':16,
           '十七':17,'十八':18,'十九':19,'二十':20,'二一':21,'二二':22,'二三':23,
           '二四':24,'二五':25,'二六':26,'二七':27,'二八':28,'二九':29,'三十':30,
           '三一':31,'三二':32,'三三':33,'三四':34,'三五':35,'三六':36,'三七':37,
           '三八':38,'三九':39,'四十':40,'四一':41,'四二':42,'四三':43,'四四':44,
           '四五':45,'四六':46,'四七':47,'四八':48,'四九':49,'五十':50,
           '五一':51,'五二':52,'五三':53,'五四':54,'五五':55,'五六':56,'五七':57,
           '五八':58,'五九':59,'六十':60,'六一':61,'六二':62,'六三':63,'六四':64,
           '六五':65,'六六':66,'六七':67,'六八':68,'六九':69,'七十':70,
           '七一':71,'七二':72,'七三':73,'七四':74,'七五':75,'七六':76,'七七':77,
           '七八':78,'七九':79,'八十':80,'八一':81,'八二':82,'八三':83,'八四':84,
           '八五':85,'八六':86,'八七':87,'八八':88,'八九':89,'九十':90,
           '九一':91,'九二':92,'九三':93,'九四':94,'九五':95,'九六':96,'九七':97,
           '九八':98,'九九':99,'一百':100}

# 文稿中的章节标题正则 - 支持中文数字和特殊符号
HERB_HEADER = re.compile(
    r'^#{2,5}\s*[♢♦☐▲△►●◆◇○□■▶★☆]\s*(\d+|[一二三四五六七八九十百]+)、\s*(.+?)$'
)

# 结构化段落标记
SECTION_MARKERS = [
    '本经原文', '性味', '主治', '别录', '大明', '好古', '甄权', '日华',
    '唐容川', '徐灵胎', '药征', '刘元素', '仲醇', '毅民', '崔毅民',
    '禁忌', '附注', '炮制', '产地', '气味', '归经'
]

# 需要提取的医家注释（按名称匹配）
COMMENTATOR_NAMES = {
    '别录': '别录', '大明': '大明', '好古': '好古', '甄权': '甄权',
    '日华': '日华', '唐容川': '唐容川', '徐灵胎': '徐灵胎', '药征': '药征',
    '刘元素': '刘元素', '仲醇': '仲醇', '毅民': '毅民', '崔毅民': '崔毅民',
    '东洞吉益': '药征', '本草纲目': '本草纲目', '本草备要': '本草备要',
    '千金要方': '千金要方', '胎庐药录': '胎庐药录',
}

SECTION_PAT = re.compile(r'【(' + '|'.join(SECTION_MARKERS) + r')】')
COMMENTATOR_PAT = re.compile(r'[' + ''.join(COMMENTATOR_NAMES.keys()) + r']')

def load_transcript(path):
    with open(path, 'r', encoding='utf-8') as f:
        return f.read()

def load_herbs(path):
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)

def parse_herb_entries(text):
    """解析文稿，提取每个药的条目"""
    lines = text.split('\n')
    entries = []
    current_entry = None

    for i, line in enumerate(lines):
        m = HERB_HEADER.match(line.strip())
        if m:
            num_str = m.group(1)
            # 转换中文数字
            if num_str.isdigit():
                num = int(num_str)
            else:
                num = CN_NUM.get(num_str, 0)

            if current_entry:
                current_entry['end_line'] = i
                entries.append(current_entry)
            current_entry = {
                'number': num,
                'name': m.group(2).strip(),
                'start_line': i,
                'end_line': None,
                'sections': {},      # {section_name: content}
                'raw_text': [],
                'commentators': {},   # {author: content}
            }
        elif current_entry:
            current_entry['raw_text'].append(line)

    if current_entry:
        current_entry['end_line'] = len(lines)
        entries.append(current_entry)

    return entries

def extract_sections(entry):
    """从原始文本中提取结构化段落"""
    raw = '\n'.join(entry['raw_text'])

    # 提取【本经原文】
    m = re.search(r'【本经原文】(.+?)(?=【|$)', raw, re.DOTALL)
    if m:
        entry['sections']['本经原文'] = m.group(1).strip()[:500]

    # 提取各医家注释
    for name in COMMENTATOR_NAMES:
        # 匹配【名称】或[名称]格式
        pat = re.compile(r'[【\[]' + re.escape(name) + r'[】\]](.+?)(?=[【\[]|$)', re.DOTALL)
        m = pat.search(raw)
        if m:
            content = m.group(1).strip()
            if len(content) > 10:  # 过滤太短的
                entry['commentators'][name] = content[:400]

def extract_clinical_notes(entry, raw_lines):
    """提取临床口述内容（非结构化段落之间的叙述文本）"""
    raw = '\n'.join(raw_lines)

    # 去掉所有结构化段落
    cleaned = raw
    for pat in [
        r'【本经原文】.*?(?=【|$)',
        r'【性味】.*?(?=【|$)',
        r'【主治】.*?(?=【|$)',
        r'[【\[]别录[】\]].*?(?=[【\[]|$)',
        r'[【\[]大明[】\]].*?(?=[【\[]|$)',
        r'[【\[]好古[】\]].*?(?=[【\[]|$)',
        r'[【\[]甄权[】\]].*?(?=[【\[]|$)',
        r'[【\[]日华[】\]].*?(?=[【\[]|$)',
        r'[【\[]唐容川[】\]].*?(?=[【\[]|$)',
        r'[【\[]徐灵胎[】\]].*?(?=[【\[]|$)',
        r'[【\[]药征[】\]].*?(?=[【\[]|$)',
        r'[【\[]刘元素[】\]].*?(?=[【\[]|$)',
        r'[【\[]仲醇[】\]].*?(?=[【\[]|$)',
        r'[【\[]禁忌[】\]].*?(?=[【\[]|$)',
        r'[【\[]附注[】\]].*?(?=[【\[]|$)',
        r'#####?\s*\d+、.*',
        r'#{2,5}\s*[♢♦]\s*\d+、.*',
    ]:
        cleaned = re.sub(pat, '', cleaned, flags=re.DOTALL)

    # 清理多余空白
    cleaned = re.sub(r'\n{3,}', '\n\n', cleaned)
    cleaned = cleaned.strip()

    # 提取有用的口述内容（去掉过短的）
    if len(cleaned) > 50:
        # 截断到500字符
        if len(cleaned) > 500:
            # 在句号处截断
            cut = cleaned[:500]
            last_period = max(cut.rfind('。'), cut.rfind('！'), cut.rfind('？'))
            if last_period > 200:
                cleaned = cut[:last_period + 1]
            else:
                cleaned = cut + '……'
    else:
        cleaned = ''

    return cleaned

def extract_herb_comparisons(entry, raw_lines):
    """提取药物比较信息"""
    raw = '\n'.join(raw_lines)
    comparisons = []

    # 常见比较模式
    patterns = [
        r'(.{2,4})和(.{2,4})', r'(.{2,4})跟(.{2,4})', r'(.{2,4})与(.{2,4})',
        r'(.{2,4})比(.{2,4})', r'(.{2,4})不同于(.{2,4})',
        r'(.{2,4})、(.{2,4})', r'(.{2,4})兼有(.{2,4})',
    ]

    # 提取"X比Y"或"X跟Y不一样"这类比较句
    compare_sents = re.findall(
        r'([^。！？]*(?:比|跟|与|不同于|不一样|更|较)[^。！？]*[。！？])',
        raw
    )

    for sent in compare_sents[:3]:  # 最多3个
        if 20 < len(sent) < 150:
            comparisons.append(sent.strip())

    return comparisons

def match_herb_name(transcript_name, json_herbs):
    """匹配文稿药名到JSON药名"""
    # 直接匹配
    for h in json_herbs:
        if h['name'] == transcript_name:
            return h['name']

    # 常见别名映射 (文稿名 → JSON古名)
    alias_map = {
        # 金石类
        '硝石': '消石', '朴硝': '朴消', '石胆': '石胆（又名胆矾）',
        '石膏': '石膏', '赤石脂': '赤石脂', '禹余粮': '禹余粮',
        '礜石': '礜石', '礐石': '礜石',
        '青石脂': '青石脂', '黄石脂': '黄石脂', '白石脂': '白石脂', '黑石脂': '黑石脂',
        '青石赤石黄石白石黑石': '五色石脂',
        # 草木类
        '芎穷': '芎穷', '川芎': '芎穷',
        '黄芪': '黄耆', '黄耆': '黄耆',
        '茜草': '茜根', '茜根': '茜根',
        '旋覆花': '旋华', '旋覆花': '旋复花',
        '薇街': '薇衔', '薇衔': '薇衔',
        '青囊': '青蘘', '青蘘': '青蘘',
        '別羈': '別羁', '別羁': '別羁',
        '发髪': '发髲', '发髲': '发髲',
        '藁本': '槀本', '槀本': '槀本',
        '草薢': '萆薢', '萆薢': '萆薢',
        '女苑': '女菀', '女菀': '女菀',
        '积雪草': '积雪草',
        '莨菪子': '莨菪',
        '青葙子': '青葙',
        '桐叶': '桐叶',
        '大豆黄卷': '大豆黄卷',
        '水苏': '水斳',
        '灶心土': '伏龙肝',
        '芜花': '荛花', '荛花': '荛花',
        '楝实': '楝实',
        '蒴翟细叶': '蒴翟',
        '蚱蝉': '蚱蝉',
        '蟅虫': '蟅虫',
        # 动物类
        '桑螵蛸': '桑蜱蛸', '桑蜱蛸': '桑蜱蛸',
        '蜈蚣': '蜈蚣',
        '羧羊角': '羖羊角', '羖羊角': '羖羊角',
        '鹿茸': '鹿茸',
        '牡狗阴茎': '牡狗阴茎',
        '蟪虫': '蟪虫',
        '虾蟆': '虾蟆',
        '翳蟜': '翳螉', '翳螉': '翳螉',
        '鳖甲': '鳖甲',
        '龟甲': '龟甲',
        # 其他
        '白英': '白英',
        '蒲黄': '蒲黄',
        '飞廉': '飞廉',
        '地肤子': '地肤',
        '杜若': '杜若',
        '石龙刍': '石龙刍',
        '石蜜': '石蜜',
        '海藻': '海藻',
        '蓬蘖': '蓬蘽', '蓬蘽': '蓬蘽', '覆盆子': '蓬蘽',
        '女菀': '女菀',
        '矿石': '礐石',
        '冬灰': '冬灰',
        '藿菌': '藿菌',
        '菟花': '菟花',
        '牙子': '牙子',
        '漫疏': '溲疏', '溲疏': '溲疏',
        '水面': '水萍',
        '饴糖': '胶饴', '胶饴': '胶饴',
        '著实': '著实',
        '析蓂子': '析蓂',
        '青石赤石黄石白石黑石': '五石脂',
        # 直接匹配（文稿名=JSON名）
        '蒲黄': '蒲黄', '飞廉': '飞廉', '地肤子': '地肤子',
        '杜若': '杜若', '石龙刍': '石龙刍', '白英': '白英',
        '积雪草': '积雪草', '莨菪子': '莨菪子', '青葙子': '青葙子',
        '桐叶': '桐叶', '蒺藜子': '蒺藜子', '大豆黄卷': '大豆黄卷',
        '蓍实': '蓍实', '水萍': '水萍',
        '人参': '人参', '甘草': '甘草', '白术': '白术',
        '茯苓': '茯苓', '当归': '当归', '芍药': '芍药',
        '麻黄': '麻黄', '桂枝': '牡桂', '细辛': '细辛',
        '柴胡': '茈胡', '半夏': '半夏', '大黄': '大黄',
        '黄连': '黄连', '黄芩': '黄芩', '附子': '附子',
        '干姜': '干姜', '生姜': '生姜',
        '葛根': '葛根', '升麻': '升麻',
        '知母': '知母', '石膏': '石膏',
        '芒硝': '朴消', '厚朴': '厚朴',
        '枳实': '枳实', '栀子': '栀子',
        '杏仁': '杏核仁', '桃仁': '桃核仁',
        '桔梗': '桔梗', '贝母': '贝母',
        '百合': '百合', '麦冬': '麦门冬',
        '天冬': '天门冬', '沙参': '沙参',
        '石斛': '石斛', '枸杞': '枸杞',
        '杜仲': '杜仲', '牛膝': '牛膝',
        '续断': '续断', '巴戟天': '巴戟天',
        '淫羊藿': '淫羊藿', '菟丝子': '菟丝子',
        '五味子': '五味子', '山茱萸': '山茱萸',
        '吴茱萸': '吴茱萸', '乌梅': '梅实',
        '龙骨': '龙骨', '牡蛎': '牡蛎',
        '远志': '远志', '酸枣仁': '酸枣',
        '菖蒲': '昌蒲', '防风': '防风',
        '独活': '独活', '羌活': '羌活',
        '白芷': '白芷', '细辛': '细辛',
        '辛夷': '辛夷', '藁本': '槀本',
        '蔓荆子': '蔓荆实', '秦艽': '秦艽',
        '木香': '木香', '香附': '莎草根',
        '陈皮': '橘柚', '青皮': '橘柚',
        '苍术': '苍术', '白豆蔻': '白豆蔻',
        '砂仁': '缩砂密', '藿香': '藿香',
        '佩兰': '兰草',
        '紫苏': '紫苏', '荆芥': '假苏',
        '薄荷': '薄荷', '牛蒡子': '恶实',
        '蝉蜕': '蚱蝉', '桑叶': '桑根白皮',
        '菊花': '鞠华', '夏枯草': '夏枯草',
        '决明子': '决明子', '谷精草': '谷精草',
        '密蒙花': '密蒙花',
        '黄柏': '檗木', '龙胆': '龙胆',
        '苦参': '苦参', '白鲜皮': '白鲜皮',
        '秦皮': '秦皮',
        '金银花': '忍冬', '连翘': '连翘',
        '蒲公英': '蒲公英', '紫花地丁': '紫花地丁',
        '鱼腥草': '鱼腥草', '败酱': '败酱',
        '射干': '射干', '山豆根': '山豆根',
        '白头翁': '白头翁', '马齿苋': '马齿苋',
        '鸦胆子': '鸦胆子', '红藤': '红藤',
        '丹皮': '牡丹', '赤芍': '芍药',
        '紫草': '紫草', '地榆': '地榆',
        '白茅根': '茅根', '大小蓟': '大小蓟',
        '地骨皮': '枸杞',
        '艾叶': '艾叶', '炮姜': '干姜',
        '三七': '三七', '茜草': '茜根',
        '蒲黄': '蒲黄', '仙鹤草': '仙鹤草',
        '白及': '白及', '棕榈炭': '棕榈',
        '血余炭': '发髲',
        '川芎': '芎穷', '延胡索': '延胡索',
        '郁金': '郁金', '姜黄': '姜黄',
        '莪术': '蓬莪', '三棱': '荆三棱',
        '丹参': '丹参', '益母草': '充蔚子',
        '鸡血藤': '鸡血藤', '王不留行': '王不留行',
        '月季花': '月季花', '凌霄花': '紫葳',
        '土鳖虫': '廑虫', '水蛭': '水蛭',
        '虻虫': '蜚虻', '斑蝥': '斑蟊',
        '穿山甲': '鲮鲤甲',
        '半夏': '半夏', '天南星': '虎掌',
        '白附子': '白附子', '芥子': '白芥子',
        '旋覆花': '旋复花', '白前': '白前',
        '桔梗': '桔梗', '前胡': '前胡',
        '瓜蒌': '瓜篓根', '川贝母': '贝母',
        '浙贝母': '贝母', '竹茹': '竹叶',
        '天竺黄': '天竺黄', '竹沥': '竹沥',
        '昆布': '昆布', '海蛤': '海蛤',
        '杏仁': '杏核仁', '紫苏子': '苏子',
        '百部': '百部', '紫菀': '紫苑',
        '款冬花': '款冬花', '枇杷叶': '枇杷叶',
        '桑白皮': '桑根白皮', '葶苈子': '葶苈',
        '马兜铃': '马兜铃', '白果': '银杏',
        '胖大海': '胖大海', '洋金花': '曼陀罗',
        '朱砂': '丹砂', '磁石': '慈石',
        '龙骨': '龙骨', '琥珀': '琥珀',
        '酸枣仁': '酸枣', '柏子仁': '柏实',
        '远志': '远志', '合欢皮': '合欢',
        '石菖蒲': '昌蒲',
        '麝香': '麝香', '冰片': '龙脑',
        '苏合香': '苏合香', '安息香': '安息香',
        '石决明': '石决明', '牡蛎': '牡蛎',
        '代赭石': '代赭', '钩藤': '钩藤',
        '天麻': '赤箭', '全蝎': '全蝎',
        '蜈蚣': '蜈蚣', '地龙': '白颈蚯蚓',
        '僵蚕': '白僵蚕',
        '羚羊角': '羚羊角', '牛黄': '牛黄',
        '珍珠': '真珠',
        '人参': '人参', '西洋参': '西洋参',
        '党参': '党参', '太子参': '太子参',
        '黄芪': '黄耆', '白术': '白术',
        '山药': '署豫', '扁豆': '扁豆',
        '甘草': '甘草', '大枣': '大枣',
        '鹿茸': '鹿茸', '鹿角胶': '白胶',
        '紫河车': '紫河车', '冬虫夏草': '冬虫夏草',
        '肉苁蓉': '肉松容', '巴戟天': '巴戟天',
        '淫羊藿': '淫羊藿', '仙茅': '仙茅',
        '杜仲': '杜仲', '续断': '续断',
        '菟丝子': '菟丝子', '沙苑子': '蒺藜',
        '补骨脂': '补骨脂', '益智仁': '益智',
        '海狗肾': '腽肭脐',
        '当归': '当归', '熟地黄': '熟地黄',
        '白芍': '芍药', '阿胶': '阿胶',
        '何首乌': '何首乌', '龙眼肉': '龙眼',
        '北沙参': '沙参', '南沙参': '沙参',
        '麦冬': '麦门冬', '天冬': '天门冬',
        '玉竹': '女萎', '石斛': '石斛',
        '黄精': '黄精', '枸杞子': '枸杞',
        '墨旱莲': '鳢肠', '女贞子': '女贞实',
        '龟甲': '龟甲', '鳖甲': '鳖甲',
    }

    if transcript_name in alias_map:
        target = alias_map[transcript_name]
        for h in json_herbs:
            if h['name'] == target:
                return h['name']

    return None

def main():
    print("Loading transcript...")
    text = load_transcript(TRANSCRIPT)
    print(f"  Loaded {len(text)} chars")

    print("Loading herbs.json...")
    herbs_data = load_herbs(HERBS_JSON)
    json_herbs = herbs_data['herbs']
    print(f"  Loaded {len(json_herbs)} herbs")

    print("Parsing herb entries from transcript...")
    entries = parse_herb_entries(text)
    print(f"  Found {len(entries)} entries")

    # 提取每个条目的内容
    for entry in entries:
        extract_sections(entry)

    # 匹配并更新
    updated_clinical = 0
    updated_historical = 0
    updated_comparisons = 0
    matched = 0
    unmatched = []

    for entry in entries:
        matched_name = match_herb_name(entry['name'], json_herbs)
        if not matched_name:
            unmatched.append(entry['name'])
            continue

        matched += 1
        # 找到JSON中的药
        for h in json_herbs:
            if h['name'] == matched_name:
                # 1. 提取临床口述
                new_clinical = extract_clinical_notes(entry, entry['raw_text'])
                if new_clinical and len(new_clinical) > len(h.get('clinical_notes', '')):
                    h['clinical_notes'] = new_clinical
                    updated_clinical += 1

                # 2. 提取历代医家注释
                if entry['commentators']:
                    hist_parts = []
                    for author, content in entry['commentators'].items():
                        if len(content) > 20:
                            hist_parts.append(f"【{author}】{content}")
                    if hist_parts:
                        new_hist = '\n'.join(hist_parts)
                        if len(new_hist) > len(h.get('historical_notes', '')):
                            h['historical_notes'] = new_hist
                            updated_historical += 1

                # 3. 提取药物比较
                comparisons = extract_herb_comparisons(entry, entry['raw_text'])
                if comparisons:
                    h['herb_comparisons'] = comparisons
                    updated_comparisons += 1

                break

    print(f"\nResults:")
    print(f"  Matched: {matched}/{len(entries)}")
    print(f"  Updated clinical_notes: {updated_clinical}")
    print(f"  Updated historical_notes: {updated_historical}")
    print(f"  Updated herb_comparisons: {updated_comparisons}")
    if unmatched:
        print(f"  Unmatched ({len(unmatched)}): {', '.join(unmatched[:20])}")

    # 保存
    with open(HERBS_JSON, 'w', encoding='utf-8') as f:
        json.dump(herbs_data, f, ensure_ascii=False, indent=2)
    print(f"\nSaved to {HERBS_JSON}")

if __name__ == '__main__':
    main()
