"""批量补充缺失方剂（87个）"""
import json

def load_formulas(path):
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data['formulas'] if isinstance(data, dict) else data

existing = load_formulas('assets/data/formulas.json')
existing_names = set(f['name'] for f in existing)

# ===== 新增方剂数据 =====
NEW_FORMULAS = [
    # === 伤寒论 ===
    {
        "name": "麻子仁丸",
        "alias": "脾约麻仁丸",
        "meridian": "阳明",
        "category": "攻下剂",
        "components": [
            {"name": "麻子仁", "dosage": "二升", "role": "润肠通便"},
            {"name": "芍药", "dosage": "半斤", "role": "缓急止痛"},
            {"name": "枳实", "dosage": "半斤", "role": "行气除满"},
            {"name": "大黄", "dosage": "一斤", "role": "泻热通便"},
            {"name": "厚朴", "dosage": "一尺", "role": "行气除满"},
            {"name": "杏仁", "dosage": "一升", "role": "润肠通便"}
        ],
        "indication": "趺阳脉浮而涩，浮则胃气强，涩则小便数，浮涩相搏，大便则硬，其脾为约，麻子仁丸主之。",
        "contraindication": "非脾约证不宜使用",
        "dosage": "蜜丸，如梧桐子大，每服十丸，日三服，渐加，以知为度",
        "explanation": "脾约证，胃热肠燥，津液不足，大便秘结。麻仁润肠，大黄泻热，枳实厚朴行气，芍药缓急，杏仁润肠。蜜丸缓下。",
        "keywords": ["便秘", "脾约", "胃热", "肠燥", "润肠"]
    },
    {
        "name": "白头翁汤",
        "alias": "",
        "meridian": "阳明/厥阴",
        "category": "清热止利剂",
        "components": [
            {"name": "白头翁", "dosage": "二两", "role": "清热解毒凉血"},
            {"name": "黄连", "dosage": "三两", "role": "清热燥湿"},
            {"name": "黄柏", "dosage": "三两", "role": "清热燥湿"},
            {"name": "秦皮", "dosage": "三两", "role": "清热燥湿"}
        ],
        "indication": "热利下重者，白头翁汤主之。",
        "contraindication": "虚寒下利禁用",
        "dosage": "以水七升，煮取二升，去滓，温服一升，不愈更服一升",
        "explanation": "热毒痢疾，湿热蕴结大肠。白头翁清热凉血解毒，黄连黄柏清热燥湿，秦皮清热止痢。四药合用，清热解毒、凉血止痢。",
        "keywords": ["痢疾", "热利", "下重", "脓血", "里急后重"]
    },
    {
        "name": "十枣汤",
        "alias": "",
        "meridian": "太阳/阳明",
        "category": "攻逐水饮剂",
        "components": [
            {"name": "芫花", "dosage": "熬", "role": "逐水"},
            {"name": "甘遂", "dosage": "一钱匕", "role": "攻逐水饮"},
            {"name": "大戟", "dosage": "一钱匕", "role": "攻逐水饮"}
        ],
        "indication": "太阳中风，下利呕逆，表解者，乃可攻之。其人漐漐汗出，发作有时，头痛，心下痞硬满，引胁下痛，干呕短气，汗出不恶寒者，此表解里未和也，十枣汤主之。",
        "contraindication": "体虚者慎用，孕妇禁用",
        "dosage": "三药等分为末，强人服一钱匕，羸人服半钱，温服之，平旦服。不下者，明日更加半钱。得快下利后，糜粥自养",
        "explanation": "悬饮证，水饮停聚胸胁。芫花、甘遂、大戟三药峻逐水饮，大枣煎汤送服以护胃气。此方攻逐力猛，中病即止。",
        "keywords": ["悬饮", "胸水", "腹水", "水肿", "攻逐"]
    },
    {
        "name": "瓜蒂散",
        "alias": "",
        "meridian": "太阳/阳明",
        "category": "涌吐剂",
        "components": [
            {"name": "瓜蒂", "dosage": "一分熬黄", "role": "涌吐痰食"},
            {"name": "赤小豆", "dosage": "一分", "role": "利水除烦"}
        ],
        "indication": "病如桂枝证，头不痛，项不强，寸脉微浮，胸中痞硬，气上冲喉咽，不得息者，此为胸有寒也，当吐之，宜瓜蒂散。",
        "contraindication": "诸亡血虚家，不可与服",
        "dosage": "捣为散，取一钱匕，以香豉一合，用热汤七合，煮作稀糜，去滓取汁，和散，温顿服之。不吐者，少少加，得快吐乃止",
        "explanation": "痰食壅塞胸膈证。瓜蒂涌吐痰食，赤小豆利水除烦。此为涌吐法代表方，使用需谨慎。",
        "keywords": ["涌吐", "痰食", "胸痞", "气冲"]
    },
    {
        "name": "大陷胸丸",
        "alias": "",
        "meridian": "太阳/阳明",
        "category": "攻逐水饮剂",
        "components": [
            {"name": "大黄", "dosage": "半斤", "role": "泻热通便"},
            {"name": "芒硝", "dosage": "半升", "role": "软坚散结"},
            {"name": "甘遂", "dosage": "一钱匕", "role": "攻逐水饮"},
            {"name": "葶苈子", "dosage": "半升熬", "role": "泻肺行水"},
            {"name": "杏仁", "dosage": "半升去皮尖", "role": "宣肺降气"}
        ],
        "indication": "结胸者，项亦强，如柔痉状，下之则和，宜大陷胸丸。",
        "contraindication": "体虚者慎用",
        "dosage": "上四味，捣筛二味，内杏仁、芒硝，合研如脂，和散，取如弹丸一枚，别捣甘遂末一钱匕，白蜜二合，水二升，煮取一升，温顿服之，一宿乃下",
        "explanation": "结胸证偏上者。大黄芒硝泻热散结，甘遂攻逐水饮，葶苈子泻肺行水，杏仁宣肺。丸剂缓攻，药力较汤剂缓和。",
        "keywords": ["结胸", "项强", "柔痉", "攻逐"]
    },
    {
        "name": "三物小白散",
        "alias": "白散",
        "meridian": "太阳",
        "category": "温寒逐饮剂",
        "components": [
            {"name": "桔梗", "dosage": "三分", "role": "宣肺排脓"},
            {"name": "巴豆", "dosage": "一分去皮心熬黑研如脂", "role": "温下寒实"},
            {"name": "贝母", "dosage": "三分", "role": "清热化痰"}
        ],
        "indication": "寒实结胸，无热证者，三物小白散主之。",
        "contraindication": "热实结胸禁用",
        "dosage": "上三味为散，内巴豆，更于臼中杵之，以白饮和服。强人半钱匕，羸者减之。病在膈上必吐，在膈下必利，不利进热粥一杯，利过不止，进冷粥一杯",
        "explanation": "寒实结胸证。巴豆温下寒实，桔梗宣肺排脓，贝母化痰。此为温下方，与大陷胸汤（热实结胸）相对。",
        "keywords": ["寒实结胸", "温下", "巴豆"]
    },
    {
        "name": "禹余粮丸",
        "alias": "",
        "meridian": "太阳",
        "category": "涩肠固脱剂",
        "components": [
            {"name": "禹余粮", "dosage": "四两", "role": "涩肠止泻"},
            {"name": "人参", "dosage": "三两", "role": "补气固脱"},
            {"name": "附子", "dosage": "二枚炮", "role": "温阳固脱"}
        ],
        "indication": "汗家重发汗，必恍惚心乱，小便已阴疼，与禹余粮丸。",
        "contraindication": "实证不宜",
        "dosage": "丸剂，每服适量",
        "explanation": "误治后津液大伤，阳气欲脱。禹余粮涩肠固脱，人参补气，附子温阳。此方原书阙载，后人补之。",
        "keywords": ["涩肠", "固脱", "汗后"]
    },
    {
        "name": "桂枝二麻黄一汤",
        "alias": "",
        "meridian": "太阳",
        "category": "解表剂",
        "components": [
            {"name": "桂枝", "dosage": "一两十七铢", "role": "解肌发表"},
            {"name": "芍药", "dosage": "一两六铢", "role": "调和营卫"},
            {"name": "麻黄", "dosage": "十六铢", "role": "发汗解表"},
            {"name": "生姜", "dosage": "一两六铢", "role": "散寒止呕"},
            {"name": "杏仁", "dosage": "二十六个", "role": "宣肺平喘"},
            {"name": "甘草", "dosage": "一两二铢", "role": "调和诸药"},
            {"name": "大枣", "dosage": "五枚", "role": "补脾和胃"}
        ],
        "indication": "服桂枝汤，大汗出，脉洪大者，与桂枝汤如前法。若形似疟，日再发者，汗出必解，宜桂枝二麻黄一汤。",
        "contraindication": "无表证不宜",
        "dosage": "以水五升，先煮麻黄一二沸，去上沫，内诸药，煮取二升，去滓，温服一升，日再服",
        "explanation": "桂枝汤证兼轻度表寒，大汗后邪气未尽。桂枝用量多于麻黄，以桂枝汤为主，微发其汗。",
        "keywords": ["大汗", "似疟", "表证未解"]
    },
    {
        "name": "桂枝二越婢一汤",
        "alias": "",
        "meridian": "太阳",
        "category": "解表清里剂",
        "components": [
            {"name": "桂枝", "dosage": "十八铢", "role": "解肌发表"},
            {"name": "芍药", "dosage": "十八铢", "role": "调和营卫"},
            {"name": "麻黄", "dosage": "十八铢", "role": "发汗解表"},
            {"name": "甘草", "dosage": "十八铢", "role": "调和诸药"},
            {"name": "大枣", "dosage": "四枚", "role": "补脾和胃"},
            {"name": "生姜", "dosage": "一两二铢", "role": "散寒止呕"},
            {"name": "石膏", "dosage": "二十四铢", "role": "清热除烦"}
        ],
        "indication": "太阳病，发热恶寒，热多寒少，脉微弱者，此无阳也，不可发汗，宜桂枝二越婢一汤。",
        "contraindication": "脉微弱、汗出、恶风者不可服",
        "dosage": "以水五升，煮麻黄一二沸，去上沫，内诸药，煮取二升，去滓，温服一升",
        "explanation": "表寒里热轻证。桂枝汤解表，越婢汤清里热。石膏清热除烦，用量轻，表里双解。",
        "keywords": ["发热恶寒", "热多寒少", "表寒里热"]
    },
    {
        "name": "栀子生姜豉汤",
        "alias": "",
        "meridian": "阳明",
        "category": "清热除烦剂",
        "components": [
            {"name": "栀子", "dosage": "十四个", "role": "清热除烦"},
            {"name": "生姜", "dosage": "五两", "role": "散寒止呕"},
            {"name": "香豉", "dosage": "四合", "role": "宣透郁热"}
        ],
        "indication": "发汗吐下后，虚烦不得眠，若剧者，必反复颠倒，心中懊憹，栀子豉汤主之；若呕者，栀子生姜豉汤主之。",
        "contraindication": "旧微溏者不宜服",
        "dosage": "以水四升，先煮栀子、生姜，取二升半，内豉，煮取一升半，去滓，分二服，温进一服，得吐者，止后服",
        "explanation": "栀子豉汤证兼呕。栀子清热除烦，生姜散寒止呕，香豉宣透郁热。",
        "keywords": ["虚烦", "呕吐", "懊憹"]
    },
    {
        "name": "禹余粮丸",
        "alias": "",
        "meridian": "太阳",
        "category": "涩肠固脱剂",
        "components": [
            {"name": "禹余粮", "dosage": "四两", "role": "涩肠止泻"},
            {"name": "人参", "dosage": "三两", "role": "补气固脱"},
            {"name": "附子", "dosage": "二枚炮", "role": "温阳固脱"}
        ],
        "indication": "汗家重发汗，必恍惚心乱，小便已阴疼，与禹余粮丸。",
        "contraindication": "实证不宜",
        "dosage": "丸剂",
        "explanation": "误治后津液大伤，阳气欲脱。禹余粮涩肠固脱，人参补气，附子温阳。",
        "keywords": ["涩肠", "固脱", "汗后"]
    },
    # 注意：禹余粮丸已出现两次，去重后保留一个
    {
        "name": "当归四逆加吴茱萸生姜汤",
        "alias": "当归四逆加萸姜汤",
        "meridian": "厥阴",
        "category": "温经散寒剂",
        "components": [
            {"name": "当归", "dosage": "三两", "role": "养血活血"},
            {"name": "芍药", "dosage": "三两", "role": "柔肝缓急"},
            {"name": "桂枝", "dosage": "三两", "role": "温经散寒"},
            {"name": "细辛", "dosage": "三两", "role": "散寒通脉"},
            {"name": "甘草", "dosage": "二两炙", "role": "调和诸药"},
            {"name": "大枣", "dosage": "二十五枚", "role": "补脾和胃"},
            {"name": "通草", "dosage": "二两", "role": "通利血脉"},
            {"name": "吴茱萸", "dosage": "二升", "role": "温中散寒"},
            {"name": "生姜", "dosage": "半斤", "role": "散寒止呕"}
        ],
        "indication": "内有久寒者，当归四逆加吴茱萸生姜汤主之。",
        "contraindication": "热证不宜",
        "dosage": "以水六升，清酒六升和，煮取五升，去滓，温分五服",
        "explanation": "当归四逆汤证兼内有久寒（肝胃虚寒）。加吴茱萸温肝胃之寒，生姜散寒止呕。清酒和水同煮以活血通脉。",
        "keywords": ["久寒", "厥阴", "寒疝", "腹痛"]
    },
    {
        "name": "厚朴七物汤",
        "alias": "",
        "meridian": "阳明/太阳",
        "category": "表里双解剂",
        "components": [
            {"name": "厚朴", "dosage": "半斤", "role": "行气除满"},
            {"name": "甘草", "dosage": "三两", "role": "调和诸药"},
            {"name": "大黄", "dosage": "三两", "role": "泻热通便"},
            {"name": "枳实", "dosage": "五枚", "role": "行气消痞"},
            {"name": "桂枝", "dosage": "二两", "role": "解表散寒"},
            {"name": "大枣", "dosage": "十枚", "role": "补脾和胃"},
            {"name": "生姜", "dosage": "五两", "role": "散寒止呕"}
        ],
        "indication": "病腹满，发热十日，脉浮而数，饮食如故，厚朴七物汤主之。",
        "contraindication": "里实不明显者不宜",
        "dosage": "以水一斗，煮取四升，温服八合，日三服。呕者加半夏五合，下利去大黄，寒多者加生姜至半斤",
        "explanation": "表里双解方。厚朴枳实大黄行气泻热通便（里证），桂枝生姜大枣解表散寒（表证）。腹满发热，表里同病。",
        "keywords": ["腹满", "发热", "表里双解", "饮食如故"]
    },
    {
        "name": "大建中汤",
        "alias": "",
        "meridian": "太阴",
        "category": "温中补虚剂",
        "components": [
            {"name": "蜀椒", "dosage": "二合去汗", "role": "温中散寒"},
            {"name": "干姜", "dosage": "四两", "role": "温中散寒"},
            {"name": "人参", "dosage": "二两", "role": "补气健脾"},
            {"name": "饴糖", "dosage": "一升", "role": "缓急止痛"}
        ],
        "indication": "心胸中大寒痛，呕不能饮食，腹中寒，上冲皮起，出见有头足，上下痛而不可触近，大建中汤主之。",
        "contraindication": "热证不宜",
        "dosage": "以水四升，煮取二升，去滓，内饴糖，微火煮取一升半，分温再服，如一炊顷，可饮粥二升，后更服，当一日食糜，温覆之",
        "explanation": "中阳虚衰，阴寒内盛。蜀椒干姜温中散寒，人参补气，饴糖缓急止痛。此方温中之力强于理中汤。",
        "keywords": ["腹痛", "呕", "寒疝", "虚寒"]
    },
    {
        "name": "赤丸",
        "alias": "",
        "meridian": "太阴/少阴",
        "category": "温里剂",
        "components": [
            {"name": "茯苓", "dosage": "四两", "role": "利水渗湿"},
            {"name": "半夏", "dosage": "四两", "role": "燥湿化痰"},
            {"name": "乌头", "dosage": "二两炮", "role": "温里散寒"},
            {"name": "细辛", "dosage": "一两", "role": "散寒止痛"}
        ],
        "indication": "寒气厥逆，赤丸主之。",
        "contraindication": "热证禁用",
        "dosage": "上四味，末之，内真朱为色，炼蜜丸如麻子大，先食酒饮下三丸，日再夜一服，不知，稍增之，以知为度",
        "explanation": "阴寒内盛，阳气不达四末。乌头细辛温里散寒，茯苓半夏化饮降逆。真朱（朱砂）为衣镇心安神。",
        "keywords": ["厥逆", "寒气", "腹痛"]
    },
    {
        "name": "当归生姜羊肉汤",
        "alias": "",
        "meridian": "厥阴/太阴",
        "category": "温经补血剂",
        "components": [
            {"name": "当归", "dosage": "三两", "role": "养血活血"},
            {"name": "生姜", "dosage": "五两", "role": "散寒止呕"},
            {"name": "羊肉", "dosage": "一斤", "role": "温中补虚"}
        ],
        "indication": "寒疝腹中痛，及胁痛里急者，当归生姜羊肉汤主之。",
        "contraindication": "热证不宜",
        "dosage": "以水八升，煮取三升，温服七合，日三服。若寒多者加生姜成一斤，痛多而呕者加橘皮二两、白术一两",
        "explanation": "血虚寒疝。当归养血活血，生姜散寒，羊肉温中补虚。此为食疗方，药食同源。",
        "keywords": ["寒疝", "腹痛", "血虚", "食疗"]
    },
    {
        "name": "乌头桂枝汤",
        "alias": "",
        "meridian": "厥阴/太阳",
        "category": "温里解表剂",
        "components": [
            {"name": "乌头", "dosage": "五枚", "role": "温里散寒"},
            {"name": "桂枝", "dosage": "三两", "role": "解表散寒"},
            {"name": "芍药", "dosage": "三两", "role": "柔肝缓急"},
            {"name": "甘草", "dosage": "二两炙", "role": "调和诸药"},
            {"name": "大枣", "dosage": "十二枚", "role": "补脾和胃"},
            {"name": "生姜", "dosage": "三两", "role": "散寒止呕"}
        ],
        "indication": "寒疝腹中痛，逆冷，手足不仁，若身疼痛，灸刺诸药不能治，抵当乌头桂枝汤主之。",
        "contraindication": "热证禁用",
        "dosage": "乌头以蜜二斤，煎减半，去滓，以桂枝汤五合解之，得一升后，初服二合，不知，即服三合，又不知，复加至五合。其知者，如醉状，得吐者，为中病",
        "explanation": "寒疝兼表证。乌头温里散寒止痛，桂枝汤解表散寒。蜜煎乌头以减毒性。",
        "keywords": ["寒疝", "表里双解", "手足不仁"]
    },
    {
        "name": "旋覆花汤",
        "alias": "",
        "meridian": "肝/胃",
        "category": "降气化痰剂",
        "components": [
            {"name": "旋覆花", "dosage": "三两", "role": "降气化痰"},
            {"name": "葱", "dosage": "十四茎", "role": "通阳散结"},
            {"name": "新绛", "dosage": "少许", "role": "活血通络"}
        ],
        "indication": "肝着，其人常欲蹈其胸上，先未苦时，但欲饮热，旋覆花汤主之。",
        "contraindication": "气虚下陷者不宜",
        "dosage": "以水三升，煮取一升，顿服",
        "explanation": "肝着证，肝气郁结，血脉瘀滞。旋覆花降气化痰，葱通阳散结，新绛活血通络。",
        "keywords": ["肝着", "胸闷", "气郁"]
    },
    {
        "name": "甘姜苓术汤",
        "alias": "肾着汤",
        "meridian": "太阴/肾",
        "category": "温阳利水剂",
        "components": [
            {"name": "甘草", "dosage": "二两", "role": "调和诸药"},
            {"name": "干姜", "dosage": "四两", "role": "温中散寒"},
            {"name": "茯苓", "dosage": "四两", "role": "利水渗湿"},
            {"name": "白术", "dosage": "二两", "role": "健脾燥湿"}
        ],
        "indication": "肾着之病，其人身体重，腰中冷，如坐水中，形如水状，反不渴，小便自利，饮食如故，病属下焦，身劳汗出，衣里冷湿，久久得之，腰以下冷痛，腹重如带五千钱，甘姜苓术汤主之。",
        "contraindication": "湿热腰痛不宜",
        "dosage": "以水五升，煮取三升，分温三服",
        "explanation": "肾着证，寒湿痹着腰部。干姜温中散寒，茯苓白术利水健脾，甘草调和。此方重在温脾散寒湿。",
        "keywords": ["肾着", "腰冷", "寒湿", "身重"]
    },
    {
        "name": "木防己汤",
        "alias": "",
        "meridian": "太阳/太阴",
        "category": "利水化饮剂",
        "components": [
            {"name": "木防己", "dosage": "三两", "role": "利水消肿"},
            {"name": "石膏", "dosage": "十二枚鸡子大", "role": "清热除烦"},
            {"name": "桂枝", "dosage": "二两", "role": "温阳化饮"},
            {"name": "人参", "dosage": "四两", "role": "补气扶正"}
        ],
        "indication": "膈间支饮，其人喘满，心下痞坚，面色黧黑，其脉沉紧，得之数十日，医吐下之不愈，木防己汤主之。",
        "contraindication": "水饮化热不明显者不宜",
        "dosage": "以水六升，煮取二升，分温再服",
        "explanation": "膈间支饮，饮邪化热。防己利水，石膏清热，桂枝温阳化饮，人参扶正。虚实错杂之证。",
        "keywords": ["支饮", "喘满", "心下痞坚"]
    },
    {
        "name": "木防己去石膏加茯苓芒硝汤",
        "alias": "",
        "meridian": "太阳/太阴",
        "category": "利水化饮剂",
        "components": [
            {"name": "木防己", "dosage": "三两", "role": "利水消肿"},
            {"name": "桂枝", "dosage": "二两", "role": "温阳化饮"},
            {"name": "人参", "dosage": "四两", "role": "补气扶正"},
            {"name": "芒硝", "dosage": "三合", "role": "软坚散结"},
            {"name": "茯苓", "dosage": "四两", "role": "利水渗湿"}
        ],
        "indication": "木防己汤证，虚者即愈，实者三日复发，复与不愈者，宜木防己去石膏加茯苓芒硝汤。",
        "contraindication": "无水饮结聚者不宜",
        "dosage": "以水六升，煮取二升，去滓，内芒硝，再微煎，分温再服，微利则愈",
        "explanation": "木防己汤证水饮结实者。去石膏之清热，加茯苓利水、芒硝软坚散结，攻逐水饮之力更强。",
        "keywords": ["支饮", "结实", "攻逐"]
    },
    {
        "name": "泽泻汤",
        "alias": "",
        "meridian": "太阴",
        "category": "利水渗湿剂",
        "components": [
            {"name": "泽泻", "dosage": "五两", "role": "利水渗湿"},
            {"name": "白术", "dosage": "二两", "role": "健脾燥湿"}
        ],
        "indication": "心下有支饮，其人苦冒眩，泽泻汤主之。",
        "contraindication": "肾虚眩晕不宜",
        "dosage": "以水二升，煮取一升，分温再服",
        "explanation": "支饮冒眩证。泽泻利水渗湿，白术健脾燥湿。二药合用，引水下行，眩晕自止。",
        "keywords": ["冒眩", "支饮", "头晕"]
    },
    {
        "name": "厚朴大黄汤",
        "alias": "",
        "meridian": "阳明",
        "category": "攻下剂",
        "components": [
            {"name": "厚朴", "dosage": "一尺", "role": "行气除满"},
            {"name": "大黄", "dosage": "六两", "role": "泻热通便"},
            {"name": "枳实", "dosage": "四枚", "role": "行气消痞"}
        ],
        "indication": "支饮胸满者，厚朴大黄汤主之。",
        "contraindication": "体虚者慎用",
        "dosage": "以水五升，煮取二升，分温再服",
        "explanation": "支饮兼阳明腑实。厚朴行气除满，大黄泻热通便，枳实消痞。此方与小承气汤药同量异。",
        "keywords": ["支饮", "胸满", "便秘"]
    },
    {
        "name": "苓甘五味姜辛汤",
        "alias": "",
        "meridian": "太阴/肺",
        "category": "温阳化饮剂",
        "components": [
            {"name": "茯苓", "dosage": "四两", "role": "利水渗湿"},
            {"name": "甘草", "dosage": "三两", "role": "调和诸药"},
            {"name": "五味子", "dosage": "半升", "role": "敛肺止咳"},
            {"name": "干姜", "dosage": "三两", "role": "温肺化饮"},
            {"name": "细辛", "dosage": "三两", "role": "散寒化饮"}
        ],
        "indication": "咳满即止，而更复渴，冲气复发者，以细辛、干姜为热药也，服之当遂渴，而渴反止者，为支饮也。支饮者法当冒，冒者必呕，呕者复内半夏以去其水。",
        "contraindication": "痰热咳嗽不宜",
        "dosage": "以水八升，煮取三升，去滓，温服半升，日三服",
        "explanation": "寒饮伏肺，咳嗽痰稀。干姜细辛温肺化饮，五味子敛肺止咳，茯苓利水，甘草调和。温化寒饮代表方。",
        "keywords": ["寒饮", "咳嗽", "痰稀", "温肺"]
    },
    {
        "name": "苓甘五味姜辛半夏汤",
        "alias": "",
        "meridian": "太阴/肺",
        "category": "温阳化饮剂",
        "components": [
            {"name": "茯苓", "dosage": "四两", "role": "利水渗湿"},
            {"name": "甘草", "dosage": "三两", "role": "调和诸药"},
            {"name": "五味子", "dosage": "半升", "role": "敛肺止咳"},
            {"name": "干姜", "dosage": "三两", "role": "温肺化饮"},
            {"name": "细辛", "dosage": "三两", "role": "散寒化饮"},
            {"name": "半夏", "dosage": "半升", "role": "燥湿化痰"}
        ],
        "indication": "苓甘五味姜辛汤证兼呕者。",
        "contraindication": "痰热不宜",
        "dosage": "以水八升，煮取三升，去滓，温服半升，日三服",
        "explanation": "寒饮咳喘兼呕。在苓甘五味姜辛汤基础上加半夏燥湿化痰、降逆止呕。",
        "keywords": ["寒饮", "咳嗽", "呕吐"]
    },
    {
        "name": "苓甘五味加姜辛半夏杏仁汤",
        "alias": "",
        "meridian": "太阴/肺",
        "category": "温阳化饮剂",
        "components": [
            {"name": "茯苓", "dosage": "四两", "role": "利水渗湿"},
            {"name": "甘草", "dosage": "三两", "role": "调和诸药"},
            {"name": "五味子", "dosage": "半升", "role": "敛肺止咳"},
            {"name": "干姜", "dosage": "三两", "role": "温肺化饮"},
            {"name": "细辛", "dosage": "三两", "role": "散寒化饮"},
            {"name": "半夏", "dosage": "半升", "role": "燥湿化痰"},
            {"name": "杏仁", "dosage": "半升", "role": "宣肺降气"}
        ],
        "indication": "苓甘五味姜辛半夏汤证兼形肿者。",
        "contraindication": "痰热不宜",
        "dosage": "以水一斗，煮取三升，去滓，温服半升，日三服",
        "explanation": "寒饮咳喘兼面目浮肿。加杏仁宣肺降气利水。",
        "keywords": ["寒饮", "咳喘", "浮肿"]
    },
    {
        "name": "苓甘五味加姜辛夏杏大黄汤",
        "alias": "",
        "meridian": "太阴/阳明",
        "category": "温阳化饮泻热剂",
        "components": [
            {"name": "茯苓", "dosage": "四两", "role": "利水渗湿"},
            {"name": "甘草", "dosage": "三两", "role": "调和诸药"},
            {"name": "五味子", "dosage": "半升", "role": "敛肺止咳"},
            {"name": "干姜", "dosage": "三两", "role": "温肺化饮"},
            {"name": "细辛", "dosage": "三两", "role": "散寒化饮"},
            {"name": "半夏", "dosage": "半升", "role": "燥湿化痰"},
            {"name": "杏仁", "dosage": "半升", "role": "宣肺降气"},
            {"name": "大黄", "dosage": "三两", "role": "泻热通便"}
        ],
        "indication": "苓甘五味加姜辛半夏杏仁汤证兼面热如醉者。",
        "contraindication": "无胃热者不宜",
        "dosage": "以水一斗，煮取三升，去滓，温服半升，日三服",
        "explanation": "寒饮咳喘兼胃热上冲面赤。加大黄泻胃热。寒热并用之法。",
        "keywords": ["寒饮", "胃热", "面赤"]
    },
    {
        "name": "栝蒌瞿麦丸",
        "alias": "",
        "meridian": "太阳/肾",
        "category": "利水渗湿剂",
        "components": [
            {"name": "栝蒌根", "dosage": "二两", "role": "生津止渴"},
            {"name": "瞿麦", "dosage": "一两", "role": "利水通淋"},
            {"name": "附子", "dosage": "一枚炮", "role": "温阳化气"},
            {"name": "薯蓣", "dosage": "三两", "role": "补脾益肾"},
            {"name": "茯苓", "dosage": "三两", "role": "利水渗湿"}
        ],
        "indication": "小便不利者，有水气，其人苦渴，栝蒌瞿麦丸主之。",
        "contraindication": "湿热淋证不宜",
        "dosage": "上五味，末之，炼蜜丸如梧子大，饮服二丸，日三服，不知，增至七八丸，以小便利，腹中温为知",
        "explanation": "肾阳不足，水气不化。附子温阳化气，茯苓瞿麦利水，栝蒌根生津止渴，薯蓣补脾益肾。标本兼顾。",
        "keywords": ["小便不利", "水气", "口渴"]
    },
    {
        "name": "滑石白鱼散",
        "alias": "",
        "meridian": "太阳/膀胱",
        "category": "利水通淋剂",
        "components": [
            {"name": "滑石", "dosage": "二分", "role": "利水通淋"},
            {"name": "白鱼", "dosage": "二分", "role": "利水消瘀"},
            {"name": "乱发", "dosage": "二分烧", "role": "消瘀利水"}
        ],
        "indication": "小便不利，蒲灰散主之；滑石白鱼散、茯苓戎盐汤并主之。",
        "contraindication": "气虚者不宜",
        "dosage": "上三味，杵为散，饮服方寸匕，日三服",
        "explanation": "膀胱湿热，小便不利。滑石利水通淋，白鱼利水消瘀，乱发烧灰消瘀止血。",
        "keywords": ["小便不利", "淋证", "膀胱"]
    },
    {
        "name": "茯苓戎盐汤",
        "alias": "",
        "meridian": "太阴/膀胱",
        "category": "利水渗湿剂",
        "components": [
            {"name": "茯苓", "dosage": "半斤", "role": "利水渗湿"},
            {"name": "白术", "dosage": "二两", "role": "健脾燥湿"},
            {"name": "戎盐", "dosage": "弹丸大一枚", "role": "利水润下"}
        ],
        "indication": "小便不利，蒲灰散主之；滑石白鱼散、茯苓戎盐汤并主之。",
        "contraindication": "阴虚者不宜",
        "dosage": "以水六升，煮取三升，分温三服",
        "explanation": "脾虚湿盛，小便不利。茯苓白术健脾利水，戎盐（青盐）利水润下。",
        "keywords": ["小便不利", "脾虚", "湿盛"]
    },
    {
        "name": "越婢加术汤",
        "alias": "",
        "meridian": "太阴/肺",
        "category": "发汗利水剂",
        "components": [
            {"name": "麻黄", "dosage": "六两", "role": "发汗利水"},
            {"name": "石膏", "dosage": "半斤", "role": "清热除烦"},
            {"name": "生姜", "dosage": "三两", "role": "散寒止呕"},
            {"name": "大枣", "dosage": "十五枚", "role": "补脾和胃"},
            {"name": "甘草", "dosage": "二两", "role": "调和诸药"},
            {"name": "白术", "dosage": "四两", "role": "健脾燥湿"}
        ],
        "indication": "里水，越婢加术汤主之，甘草麻黄汤亦主之。",
        "contraindication": "虚证不宜",
        "dosage": "以水七升，先煮麻黄，去上沫，内诸药，煮取三升，分温三服",
        "explanation": "风水夹热，水湿内停。越婢汤发汗利水清热，加白术健脾燥湿。",
        "keywords": ["风水", "水肿", "发热"]
    },
    {
        "name": "麻黄附子汤",
        "alias": "",
        "meridian": "少阴/太阳",
        "category": "温阳利水剂",
        "components": [
            {"name": "麻黄", "dosage": "三两", "role": "发汗利水"},
            {"name": "甘草", "dosage": "二两", "role": "调和诸药"},
            {"name": "附子", "dosage": "一枚炮", "role": "温阳化气"}
        ],
        "indication": "水之为病，其脉沉小，属少阴；浮者为风，无水虚胀者，为气。水，发其汗即已。脉沉者宜麻黄附子汤；浮者宜杏子汤。",
        "contraindication": "风水实证不宜",
        "dosage": "以水七升，先煮麻黄，去上沫，内诸药，煮取二升半，温服八合，日三服",
        "explanation": "少阴水气，阳虚水泛。麻黄发汗利水，附子温阳化气，甘草调和。",
        "keywords": ["水气", "少阴", "脉沉", "水肿"]
    },
    {
        "name": "黄芪芍药桂枝苦酒汤",
        "alias": "耆芍桂酒汤",
        "meridian": "太阳/太阴",
        "category": "益气固表剂",
        "components": [
            {"name": "黄芪", "dosage": "五两", "role": "益气固表"},
            {"name": "芍药", "dosage": "三两", "role": "柔肝缓急"},
            {"name": "桂枝", "dosage": "三两", "role": "调和营卫"}
        ],
        "indication": "黄汗之病，身体肿，发热，汗出而渴，状如风水，汗沾衣，色正黄如药汁，脉自沉，何从得之？师曰：以汗出入水中浴，水从汗孔入得之，宜芪芍桂酒汤主之。",
        "contraindication": "湿热黄汗不宜",
        "dosage": "以苦酒一升，水七升，相和，煮取三升，温服一升，当心烦，服至六七日乃解。若心烦不止者，以苦酒阻故也",
        "explanation": "黄汗证，营卫不和，水湿内停。黄芪益气固表，芍药和营，桂枝调和营卫。苦酒（醋）收敛止汗。",
        "keywords": ["黄汗", "水肿", "出汗"]
    },
    {
        "name": "桂枝加黄芪汤",
        "alias": "",
        "meridian": "太阳",
        "category": "解表固表剂",
        "components": [
            {"name": "桂枝", "dosage": "三两", "role": "解肌发表"},
            {"name": "芍药", "dosage": "三两", "role": "调和营卫"},
            {"name": "甘草", "dosage": "二两", "role": "调和诸药"},
            {"name": "生姜", "dosage": "三两", "role": "散寒止呕"},
            {"name": "大枣", "dosage": "十二枚", "role": "补脾和胃"},
            {"name": "黄芪", "dosage": "二两", "role": "益气固表"}
        ],
        "indication": "黄汗之病，两胫自冷；假令发热，此属历节。食已汗出，又身常暮盗汗出者，此劳气也，若汗出已，反发热者，久久其身必甲错，发热不止者，必生恶疮。若身重，汗出已辄轻者，久久必身瞤，瞤即胸中痛，又从腰以上必汗出，下无汗，腰髋弛痛，如有物在皮中状，剧者不能食，身疼重，烦躁，小便不利，此为黄汗，桂枝加黄芪汤主之。",
        "contraindication": "湿热证不宜",
        "dosage": "以水一斗，煮取三升，温服一升，须臾饮热稀粥一升余，以助药力，温服取微汗，若不汗，更服",
        "explanation": "黄汗证营卫不和。桂枝汤调和营卫，加黄芪益气固表止汗。",
        "keywords": ["黄汗", "盗汗", "营卫不和"]
    },
    {
        "name": "枳术汤",
        "alias": "",
        "meridian": "太阴",
        "category": "行气健脾剂",
        "components": [
            {"name": "枳实", "dosage": "七枚", "role": "行气消痞"},
            {"name": "白术", "dosage": "二两", "role": "健脾燥湿"}
        ],
        "indication": "心下坚，大如盘，边如旋盘，水饮所作，枳术汤主之。",
        "contraindication": "气虚明显者不宜",
        "dosage": "以水五升，煮取三升，分温三服，腹中软即当散也",
        "explanation": "气滞水停，心下痞坚。枳实行气消痞，白术健脾燥湿。气行则水行。",
        "keywords": ["心下坚", "水饮", "气滞"]
    },
    {
        "name": "硝石矾石散",
        "alias": "",
        "meridian": "太阴/肝",
        "category": "逐瘀化湿剂",
        "components": [
            {"name": "硝石", "dosage": "等分", "role": "活血化瘀"},
            {"name": "矾石", "dosage": "等分", "role": "燥湿化痰"}
        ],
        "indication": "黄家日晡所发热，而反恶寒，此为女劳得之，膀胱急，少腹满，身尽黄，额上黑，足下热，因作黑疸，其腹胀如水状，大便必黑，时溏，此女劳之病，非水也。腹满者难治。硝石矾石散主之。",
        "contraindication": "非女劳疸不宜",
        "dosage": "上二味，为散，以大麦粥汁和服方寸匕，日三服。病随大小便去，小便正黄，大便正黑，是候也",
        "explanation": "女劳疸，瘀血湿热内蕴。硝石活血化瘀，矾石燥湿化痰。大麦粥护胃。",
        "keywords": ["女劳疸", "黑疸", "瘀血"]
    },
    {
        "name": "大黄硝石汤",
        "alias": "",
        "meridian": "阳明/太阴",
        "category": "攻下清热剂",
        "components": [
            {"name": "大黄", "dosage": "四两", "role": "泻热通便"},
            {"name": "黄柏", "dosage": "四两", "role": "清热燥湿"},
            {"name": "硝石", "dosage": "四两", "role": "软坚散结"},
            {"name": "栀子", "dosage": "十五枚", "role": "清热利湿"}
        ],
        "indication": "黄疸腹满，小便不利而赤，自汗出，此为表和里实，当下之，宜大黄硝石汤。",
        "contraindication": "表证未解者不宜",
        "dosage": "以水六升，煮取二升，去滓，内硝石，更煮取一升，顿服",
        "explanation": "黄疸里实热证。大黄硝石泻热通便，黄柏栀子清热利湿。表和里实，可攻下。",
        "keywords": ["黄疸", "腹满", "里实"]
    },
    {
        "name": "猪膏髪煎",
        "alias": "",
        "meridian": "阳明",
        "category": "润燥通便剂",
        "components": [
            {"name": "猪膏", "dosage": "半斤", "role": "润肠通便"},
            {"name": "乱发", "dosage": "如鸡子大三团", "role": "消瘀利水"}
        ],
        "indication": "诸黄，猪膏发煎主之。",
        "contraindication": "脾虚便溏者不宜",
        "dosage": "上二味，和膏中煎之，发消药成，分再服，病从小便出",
        "explanation": "燥结发黄证。猪膏润燥通便，乱发消瘀利水。此为润下方。",
        "keywords": ["黄疸", "燥结", "润肠"]
    },
    {
        "name": "赤豆当归散",
        "alias": "",
        "meridian": "厥阴/肝",
        "category": "清热利湿剂",
        "components": [
            {"name": "赤小豆", "dosage": "三升浸令芽出曝干", "role": "清热利湿"},
            {"name": "当归", "dosage": "三两", "role": "养血活血"}
        ],
        "indication": "病者脉数，无热，微烦，默默但欲卧，汗出，初得之三四日，目赤如鸠眼；七八日，目四眦黑。若能食者，脓已成也，赤豆当归散主之。",
        "contraindication": "无湿热者不宜",
        "dosage": "上二味，杵为散，浆水服方寸匕，日三服",
        "explanation": "狐惑病酿脓期，湿热蕴结。赤小豆清热利湿排脓，当归养血活血。",
        "keywords": ["狐惑", "目赤", "脓成"]
    },
    {
        "name": "半夏干姜散",
        "alias": "",
        "meridian": "太阴/胃",
        "category": "温中降逆剂",
        "components": [
            {"name": "半夏", "dosage": "等分", "role": "燥湿降逆"},
            {"name": "干姜", "dosage": "等分", "role": "温中散寒"}
        ],
        "indication": "干呕吐逆，吐涎沫，半夏干姜散主之。",
        "contraindication": "胃热呕吐不宜",
        "dosage": "上二味，杵为散，取方寸匕，浆水一升半，煎取七合，顿服之",
        "explanation": "脾胃虚寒，胃气上逆。半夏降逆止呕，干姜温中散寒。",
        "keywords": ["干呕", "吐涎沫", "胃寒"]
    },
    {
        "name": "生姜半夏汤",
        "alias": "",
        "meridian": "太阴/胃",
        "category": "散寒止呕剂",
        "components": [
            {"name": "半夏", "dosage": "半升", "role": "燥湿降逆"},
            {"name": "生姜汁", "dosage": "一升", "role": "散寒止呕"}
        ],
        "indication": "病人胸中似喘不喘，似呕不呕，似哕不哕，彻心中愦愦然无奈者，生姜半夏汤主之。",
        "contraindication": "热证不宜",
        "dosage": "以水三升，煮半夏取二升，内生姜汁，煮取一升半，小冷，分四服，日三夜一服，呕止，停后服",
        "explanation": "寒饮停胃，气机不畅。半夏降逆，生姜散寒化饮。小冷服以防格拒。",
        "keywords": ["似喘不喘", "似呕不呕", "寒饮"]
    },
    {
        "name": "橘皮汤",
        "alias": "",
        "meridian": "太阴/胃",
        "category": "理气和胃剂",
        "components": [
            {"name": "橘皮", "dosage": "四两", "role": "理气和胃"},
            {"name": "生姜", "dosage": "半斤", "role": "散寒止呕"}
        ],
        "indication": "干呕哕，若手足厥者，橘皮汤主之。",
        "contraindication": "气虚者不宜久服",
        "dosage": "以水七升，煮取三升，温服一升，下咽即愈",
        "explanation": "胃寒气逆，干呕哕。橘皮理气和胃，生姜散寒止呕。",
        "keywords": ["干呕", "哕", "手足厥"]
    },
    {
        "name": "橘皮竹茹汤",
        "alias": "",
        "meridian": "太阴/胃",
        "category": "降逆止呕剂",
        "components": [
            {"name": "橘皮", "dosage": "二升", "role": "理气和胃"},
            {"name": "竹茹", "dosage": "二升", "role": "清热止呕"},
            {"name": "大枣", "dosage": "三十枚", "role": "补脾和胃"},
            {"name": "生姜", "dosage": "半斤", "role": "散寒止呕"},
            {"name": "人参", "dosage": "一两", "role": "补气扶正"},
            {"name": "甘草", "dosage": "五两", "role": "调和诸药"}
        ],
        "indication": "哕逆者，橘皮竹茹汤主之。",
        "contraindication": "实热呃逆不宜",
        "dosage": "以水一斗，煮取三升，温服一合，日三服",
        "explanation": "胃虚有热，气逆不降。橘皮理气，竹茹清热止呕，人参补气，姜枣调和脾胃。",
        "keywords": ["哕逆", "胃虚", "热呃"]
    },
    {
        "name": "文蛤汤",
        "alias": "",
        "meridian": "阳明/太阳",
        "category": "清热利湿剂",
        "components": [
            {"name": "文蛤", "dosage": "五两", "role": "清热化痰"},
            {"name": "麻黄", "dosage": "三两", "role": "发汗解表"},
            {"name": "甘草", "dosage": "三两", "role": "调和诸药"},
            {"name": "生姜", "dosage": "三两", "role": "散寒止呕"},
            {"name": "石膏", "dosage": "五两", "role": "清热除烦"},
            {"name": "大枣", "dosage": "十二枚", "role": "补脾和胃"},
            {"name": "杏仁", "dosage": "五十个", "role": "宣肺降气"}
        ],
        "indication": "吐后渴欲得水而贪饮者，文蛤汤主之。兼主微风，脉紧头痛。",
        "contraindication": "无表热者不宜",
        "dosage": "以水六升，煮取二升，温服一升，汗出即愈",
        "explanation": "表寒里热，吐后津伤。文蛤清热化痰，麻黄石膏解表清里，杏仁宣肺。",
        "keywords": ["吐后", "渴", "表寒里热"]
    },
    {
        "name": "茯苓泽泻汤",
        "alias": "",
        "meridian": "太阴",
        "category": "利水化饮剂",
        "components": [
            {"name": "茯苓", "dosage": "半斤", "role": "利水渗湿"},
            {"name": "泽泻", "dosage": "四两", "role": "利水渗湿"},
            {"name": "甘草", "dosage": "二两", "role": "调和诸药"},
            {"name": "桂枝", "dosage": "二两", "role": "温阳化饮"},
            {"name": "白术", "dosage": "三两", "role": "健脾燥湿"},
            {"name": "生姜", "dosage": "四两", "role": "散寒止呕"}
        ],
        "indication": "胃反，吐而渴欲饮水者，茯苓泽泻汤主之。",
        "contraindication": "阴虚不宜",
        "dosage": "以水一斗，煮取三升，内泽泻，再煮取二升半，温服八合，日三服",
        "explanation": "水饮停胃，呕吐口渴。茯苓泽泻利水，白术健脾，桂枝温阳化饮，生姜止呕。",
        "keywords": ["胃反", "呕吐", "口渴", "水饮"]
    },
    {
        "name": "王不留行散",
        "alias": "",
        "meridian": "厥阴/肝",
        "category": "活血化瘀剂",
        "components": [
            {"name": "王不留行", "dosage": "八月八日采十分", "role": "活血通经"},
            {"name": "蒴藋细叶", "dosage": "七月七日采十分", "role": "祛风活血"},
            {"name": "桑东南根白皮", "dosage": "三月三日采十分", "role": "利水消肿"},
            {"name": "甘草", "dosage": "十八分", "role": "调和诸药"},
            {"name": "黄芩", "dosage": "二分", "role": "清热凉血"},
            {"name": "川椒", "dosage": "三分", "role": "温中散寒"},
            {"name": "干姜", "dosage": "二分", "role": "温中散寒"},
            {"name": "芍药", "dosage": "二分", "role": "柔肝缓急"},
            {"name": "厚朴", "dosage": "二分", "role": "行气除满"}
        ],
        "indication": "病金疮，王不留行散主之。",
        "contraindication": "无瘀血者不宜",
        "dosage": "上九味，桑根皮以上三味烧灰存性，勿令灰过，各别杵筛，合治之为散，服方寸匕。小疮即粉之，大疮但服之，产后亦可服",
        "explanation": "金疮（刀伤）证。王不留行活血止血，桑白皮收敛止血，黄芩清热，干姜川椒温中。外敷内服皆可。",
        "keywords": ["金疮", "刀伤", "外伤"]
    },
    {
        "name": "鸡矢白散",
        "alias": "",
        "meridian": "厥阴",
        "category": "利水除湿剂",
        "components": [
            {"name": "鸡矢白", "dosage": "一合", "role": "利水泄热"}
        ],
        "indication": "转筋之为病，其人臂脚直，脉上下行，微弦，转筋入腹者，鸡矢白散主之。",
        "contraindication": "无湿热者不宜",
        "dosage": "上一味，取方寸匕，以水六合，和，温服",
        "explanation": "转筋（腓肠肌痉挛），湿热伤阴。鸡矢白利水泄热，通利经脉。",
        "keywords": ["转筋", "痉挛", "湿热"]
    },
    {
        "name": "蜘蛛散",
        "alias": "",
        "meridian": "厥阴",
        "category": "温经理气剂",
        "components": [
            {"name": "蜘蛛", "dosage": "十四枚熬焦", "role": "通利气机"},
            {"name": "桂枝", "dosage": "半两", "role": "温经散寒"}
        ],
        "indication": "阴狐疝气者，偏有大小，时时上下，蜘蛛散主之。",
        "contraindication": "无寒凝气滞者不宜",
        "dosage": "上二味，为散，取方寸匕，饮和服，日再服，蜜丸亦可",
        "explanation": "狐疝，寒凝气滞。蜘蛛通利气机，桂枝温经散寒。",
        "keywords": ["狐疝", "疝气", "寒凝"]
    },
    {
        "name": "甘草粉蜜汤",
        "alias": "",
        "meridian": "太阴/胃",
        "category": "安蛔止痛剂",
        "components": [
            {"name": "甘草", "dosage": "二两", "role": "缓急止痛"},
            {"name": "粉", "dosage": "一两", "role": "杀虫"},
            {"name": "蜜", "dosage": "四两", "role": "安蛔止痛"}
        ],
        "indication": "蛔虫之为病，令人吐涎，心痛，发作有时，毒药不止，甘草粉蜜汤主之。",
        "contraindication": "无蛔虫者不宜",
        "dosage": "上三味，以水三升，先煮甘草取二升，去滓，内粉、蜜，搅令和，煎如薄粥，温服一升，差即止",
        "explanation": "蛔虫腹痛，毒药不止。甘草缓急，粉（铅粉或米粉）杀虫，蜜安蛔止痛。此为安蛔缓痛之法。",
        "keywords": ["蛔虫", "腹痛", "吐涎"]
    },
    {
        "name": "桂枝茯苓丸",
        "alias": "夺命丹",
        "meridian": "太阴/肝",
        "category": "活血化瘀剂",
        "components": [
            {"name": "桂枝", "dosage": "三两", "role": "温经活血"},
            {"name": "茯苓", "dosage": "三两", "role": "利水渗湿"},
            {"name": "丹皮", "dosage": "三两", "role": "清热凉血"},
            {"name": "桃仁", "dosage": "三两", "role": "活血化瘀"},
            {"name": "芍药", "dosage": "三两", "role": "柔肝缓急"}
        ],
        "indication": "妇人宿有症病，经断未及三月，而得漏下不止，胎动在脐上者，为症痼害。所以血不止者，其症不去故也，当下其症，桂枝茯苓丸主之。",
        "contraindication": "无瘀血者不宜，孕妇慎用",
        "dosage": "上五味，末之，炼蜜和丸，如兔屎大，每日食前服一丸，不知，加至三丸",
        "explanation": "瘀血内停，症瘕积聚。桂枝温经活血，桃仁丹皮活血化瘀，茯苓利水，芍药柔肝。缓消症积。",
        "keywords": ["症瘕", "瘀血", "月经不调", "胎动"]
    },
    {
        "name": "干姜人参半夏丸",
        "alias": "",
        "meridian": "太阴/胃",
        "category": "温中止呕剂",
        "components": [
            {"name": "干姜", "dosage": "一两", "role": "温中散寒"},
            {"name": "人参", "dosage": "一两", "role": "补气健脾"},
            {"name": "半夏", "dosage": "二两", "role": "燥湿降逆"}
        ],
        "indication": "妊娠呕吐不止，干姜人参半夏丸主之。",
        "contraindication": "胃热呕吐不宜",
        "dosage": "上三味，末之，以生姜汁糊为丸，如梧子大，饮服十丸，日三服",
        "explanation": "脾胃虚寒，妊娠恶阻。干姜温中，人参补气，半夏降逆止呕。生姜汁为丸增强止呕之力。",
        "keywords": ["妊娠", "呕吐", "恶阻"]
    },
    {
        "name": "当归贝母苦参丸",
        "alias": "",
        "meridian": "太阴/膀胱",
        "category": "利水清热剂",
        "components": [
            {"name": "当归", "dosage": "四两", "role": "养血活血"},
            {"name": "贝母", "dosage": "四两", "role": "清热化痰"},
            {"name": "苦参", "dosage": "四两", "role": "清热利湿"}
        ],
        "indication": "妊娠，小便难，饮食如故，当归贝母苦参丸主之。",
        "contraindication": "虚寒者不宜",
        "dosage": "上三味，末之，炼蜜丸如小豆大，饮服三丸，加至十丸",
        "explanation": "妊娠血虚膀胱湿热，小便难。当归养血，贝母清热化痰，苦参清热利湿。",
        "keywords": ["妊娠", "小便难", "湿热"]
    },
    {
        "name": "葵子茯苓散",
        "alias": "",
        "meridian": "太阴/膀胱",
        "category": "利水渗湿剂",
        "components": [
            {"name": "葵子", "dosage": "一斤", "role": "利水通淋"},
            {"name": "茯苓", "dosage": "三两", "role": "利水渗湿"}
        ],
        "indication": "妊娠有水气，身重，小便不利，洒淅恶寒，起即头眩，葵子茯苓散主之。",
        "contraindication": "阴虚者不宜",
        "dosage": "上二味，杵为散，饮服方寸匕，日三服，小便利则愈",
        "explanation": "妊娠水气，小便不利。葵子利水通淋，茯苓利水渗湿。",
        "keywords": ["妊娠", "水肿", "小便不利"]
    },
    {
        "name": "白术散",
        "alias": "",
        "meridian": "太阴",
        "category": "健脾安胎剂",
        "components": [
            {"name": "白术", "dosage": "四分", "role": "健脾安胎"},
            {"name": "川芎", "dosage": "四分", "role": "活血行气"},
            {"name": "蜀椒", "dosage": "三分去汗", "role": "温中散寒"},
            {"name": "牡蛎", "dosage": "二分", "role": "潜阳固涩"}
        ],
        "indication": "妊娠养胎，白术散主之。",
        "contraindication": "阴虚血热者不宜",
        "dosage": "上四味，杵为散，酒服一钱匕，日三服，夜一服。但苦痛，加芍药；心下毒痛，倍加川芎；心烦吐痛，不能食饮，加细辛一两、半夏大者二十枚",
        "explanation": "脾虚寒湿，胎动不安。白术健脾安胎，川芎活血，蜀椒温中，牡蛎固涩。",
        "keywords": ["妊娠", "养胎", "脾虚"]
    },
    {
        "name": "下瘀血汤",
        "alias": "",
        "meridian": "厥阴/肝",
        "category": "活血逐瘀剂",
        "components": [
            {"name": "大黄", "dosage": "二两", "role": "泻热逐瘀"},
            {"name": "桃仁", "dosage": "二十枚", "role": "活血化瘀"},
            {"name": "蟅虫", "dosage": "二十枚熬去足", "role": "破血逐瘀"}
        ],
        "indication": "产后腹痛，法当以枳实芍药散，假令不愈者，此为腹中有干血着脐下，宜下瘀血汤主之。亦主经水不利。",
        "contraindication": "体虚者慎用",
        "dosage": "上三味，末之，炼蜜和为四丸，以酒一升，煎一丸，取八合，顿服之，新血下如豚肝",
        "explanation": "产后瘀血内停，腹痛不减。大黄逐瘀泻热，桃仁活血，蟅虫破血逐瘀。蜜丸缓攻。",
        "keywords": ["产后", "腹痛", "瘀血"]
    },
    {
        "name": "竹叶汤",
        "alias": "",
        "meridian": "太阳/阳明",
        "category": "解表清热剂",
        "components": [
            {"name": "竹叶", "dosage": "一把", "role": "清热除烦"},
            {"name": "葛根", "dosage": "三两", "role": "解肌发表"},
            {"name": "防风", "dosage": "一两", "role": "祛风解表"},
            {"name": "桔梗", "dosage": "一两", "role": "宣肺排脓"},
            {"name": "桂枝", "dosage": "一两", "role": "解肌发表"},
            {"name": "人参", "dosage": "一两", "role": "补气扶正"},
            {"name": "甘草", "dosage": "一两", "role": "调和诸药"},
            {"name": "生姜", "dosage": "一两", "role": "散寒止呕"},
            {"name": "大枣", "dosage": "十五枚", "role": "补脾和胃"}
        ],
        "indication": "产后中风，发热，面正赤，喘而头痛，竹叶汤主之。",
        "contraindication": "无表证者不宜",
        "dosage": "以水一斗，煮取二升半，分温三服，温覆使汗出。颈项强，用大附子一枚，破之如豆大，煎药扬去沫；呕者，加半夏半升洗",
        "explanation": "产后中风，正虚邪实。竹叶葛根清热，防风桂枝解表，人参扶正。攻补兼施。",
        "keywords": ["产后", "中风", "发热", "喘"]
    },
    {
        "name": "竹皮大丸",
        "alias": "",
        "meridian": "阳明/胃",
        "category": "清热降逆剂",
        "components": [
            {"name": "生竹茹", "dosage": "二分", "role": "清热止呕"},
            {"name": "石膏", "dosage": "二分", "role": "清热除烦"},
            {"name": "桂枝", "dosage": "一分", "role": "调和营卫"},
            {"name": "甘草", "dosage": "七分", "role": "调和诸药"},
            {"name": "白薇", "dosage": "一分", "role": "清热凉血"}
        ],
        "indication": "妇人乳中虚，烦乱呕逆，安中益气，竹皮大丸主之。",
        "contraindication": "虚寒者不宜",
        "dosage": "上五味，末之，枣肉和丸弹子大，以饮服一丸，日三夜二服。有热倍白薇，烦喘者加柏实一分",
        "explanation": "产后哺乳期，胃虚有热，烦乱呕逆。竹茹石膏清胃热，白薇清虚热，桂枝甘草调和。枣肉为丸养胃。",
        "keywords": ["产后", "烦乱", "呕逆", "哺乳"]
    },
    {
        "name": "半夏厚朴汤",
        "alias": "四七汤",
        "meridian": "太阴/肺",
        "category": "行气化痰剂",
        "components": [
            {"name": "半夏", "dosage": "一升", "role": "燥湿化痰"},
            {"name": "厚朴", "dosage": "三两", "role": "行气除满"},
            {"name": "茯苓", "dosage": "四两", "role": "利水渗湿"},
            {"name": "生姜", "dosage": "五两", "role": "散寒止呕"},
            {"name": "紫苏叶", "dosage": "二两", "role": "行气解郁"}
        ],
        "indication": "妇人咽中如有炙脔，半夏厚朴汤主之。",
        "contraindication": "阴虚者不宜",
        "dosage": "以水七升，煮取四升，分温四服，日三夜一服",
        "explanation": "痰气郁结，梅核气。半夏化痰散结，厚朴行气，茯苓利水，生姜散寒，苏叶理气解郁。此为治疗梅核气名方。",
        "keywords": ["梅核气", "咽中炙脔", "痰气", "郁证"]
    },
    {
        "name": "土瓜根散",
        "alias": "",
        "meridian": "厥阴/肝",
        "category": "活血化瘀剂",
        "components": [
            {"name": "土瓜根", "dosage": "三两", "role": "活血化瘀"},
            {"name": "芍药", "dosage": "三两", "role": "柔肝缓急"},
            {"name": "桂枝", "dosage": "三两", "role": "温经活血"},
            {"name": "蟅虫", "dosage": "三两", "role": "破血逐瘀"}
        ],
        "indication": "带下经水不利，少腹满痛，经一月再见者，土瓜根散主之。",
        "contraindication": "血虚者不宜",
        "dosage": "上四味，杵为散，酒服方寸匕，日三服",
        "explanation": "瘀血内阻，月经不调。土瓜根活血化瘀，桂枝温经，蟅虫破血，芍药缓急。",
        "keywords": ["月经不调", "少腹痛", "瘀血"]
    },
    {
        "name": "胶姜汤",
        "alias": "",
        "meridian": "太阴/肝",
        "category": "温经补血剂",
        "components": [
            {"name": "阿胶", "dosage": "三两", "role": "补血止血"},
            {"name": "干姜", "dosage": "三两", "role": "温中散寒"}
        ],
        "indication": "妇人陷经，漏下黑不解，胶姜汤主之。",
        "contraindication": "血热者不宜",
        "dosage": "以水三升，煮取一升，去滓，内阿胶烊化，温服",
        "explanation": "虚寒漏下，经血色黑。阿胶补血止血，干姜温中散寒。此方原书阙载，后人补之。",
        "keywords": ["漏下", "月经", "虚寒"]
    },
    {
        "name": "矾石丸",
        "alias": "",
        "meridian": "太阴",
        "category": "燥湿止带剂",
        "components": [
            {"name": "矾石", "dosage": "三分烧", "role": "燥湿止带"},
            {"name": "杏仁", "dosage": "一分", "role": "宣肺利水"}
        ],
        "indication": "妇人经水闭不利，脏坚癖不止，中有干血，下白物，矾石丸主之。",
        "contraindication": "阴虚者不宜",
        "dosage": "上二味，末之，炼蜜和丸枣核大，内脏中，剧者再内之",
        "explanation": "湿热带下，干血内着。矾石燥湿止带，杏仁宣肺利水。外用丸剂纳阴中。",
        "keywords": ["带下", "湿热", "外用"]
    },
    {
        "name": "枳实栀子豉汤",
        "alias": "",
        "meridian": "阳明",
        "category": "清热除烦剂",
        "components": [
            {"name": "枳实", "dosage": "三枚炙", "role": "行气消痞"},
            {"name": "栀子", "dosage": "十四个", "role": "清热除烦"},
            {"name": "香豉", "dosage": "一升", "role": "宣透郁热"}
        ],
        "indication": "大病差后，劳复者，枳实栀子豉汤主之。",
        "contraindication": "无热者不宜",
        "dosage": "以清浆水七升，空煮取四升，内枳实、栀子，煮取二升，下豉，更煮五六沸，去滓，温分再服，覆令微似汗",
        "explanation": "大病初愈，因劳而复发热。枳实行气消痞，栀子清热除烦，香豉宣透。清浆水（酸浆水）养胃。",
        "keywords": ["劳复", "大病差后", "发热"]
    },
    {
        "name": "牡蛎泽泻散",
        "alias": "",
        "meridian": "少阴/太阳",
        "category": "利水潜阳剂",
        "components": [
            {"name": "牡蛎", "dosage": "熬", "role": "潜阳散结"},
            {"name": "泽泻", "dosage": "", "role": "利水渗湿"},
            {"name": "蜀漆", "dosage": "洗去腥", "role": "涤痰截疟"},
            {"name": "葶苈子", "dosage": "熬", "role": "泻肺行水"},
            {"name": "商陆根", "dosage": "熬", "role": "利水消肿"},
            {"name": "海藻", "dosage": "洗去咸", "role": "软坚散结"},
            {"name": "栝蒌根", "dosage": "", "role": "生津止渴"}
        ],
        "indication": "大病差后，从腰以下有水气者，牡蛎泽泻散主之。",
        "contraindication": "脾肾阳虚者不宜",
        "dosage": "上七味，异捣，下筛为散，更于臼中治之，白饮和服方寸匕，日三服，小便利，止后服",
        "explanation": "大病后下焦水气。牡蛎潜阳散结，泽泻葶苈子商陆利水，海藻软坚，栝蒌根生津。",
        "keywords": ["水肿", "大病差后", "下焦"]
    },
    {
        "name": "竹叶石膏汤",
        "alias": "",
        "meridian": "阳明",
        "category": "清热生津剂",
        "components": [
            {"name": "竹叶", "dosage": "二把", "role": "清热除烦"},
            {"name": "石膏", "dosage": "一斤", "role": "清热生津"},
            {"name": "半夏", "dosage": "半升", "role": "降逆止呕"},
            {"name": "麦门冬", "dosage": "一升", "role": "养阴生津"},
            {"name": "人参", "dosage": "二两", "role": "补气生津"},
            {"name": "甘草", "dosage": "二两炙", "role": "调和诸药"},
            {"name": "粳米", "dosage": "半升", "role": "益胃生津"}
        ],
        "indication": "伤寒解后，虚羸少气，气逆欲吐，竹叶石膏汤主之。",
        "contraindication": "实热者不宜",
        "dosage": "以水一斗，煮取六升，去滓，内粳米，煮米熟汤成，去米，温服一升，日三服",
        "explanation": "伤寒后期，余热未清，气阴两伤。竹叶石膏清余热，半夏降逆，麦冬人参养阴益气，粳米护胃。",
        "keywords": ["伤寒解后", "虚羸", "气阴两伤"]
    },
    {
        "name": "百合知母汤",
        "alias": "",
        "meridian": "太阴/肺",
        "category": "滋阴清热剂",
        "components": [
            {"name": "百合", "dosage": "七枚", "role": "润肺清心"},
            {"name": "知母", "dosage": "三两", "role": "清热养阴"}
        ],
        "indication": "发汗后，百合病不解者，百合知母汤主之。",
        "contraindication": "风寒咳嗽不宜",
        "dosage": "先以水洗百合，渍一宿，当白沫出，去其水，更以泉水二升，煎取一升，去滓，别以泉水二升煎知母，取一升，去滓，后合和，煎取一升五合，分温再服",
        "explanation": "百合病误汗后伤阴。百合润肺清心，知母清热养阴。泉水煎药取其清热之性。",
        "keywords": ["百合病", "误汗", "阴虚"]
    },
    {
        "name": "百合滑石代赭汤",
        "alias": "",
        "meridian": "太阴/肺",
        "category": "滋阴利湿剂",
        "components": [
            {"name": "百合", "dosage": "七枚", "role": "润肺清心"},
            {"name": "滑石", "dosage": "三两", "role": "利水通淋"},
            {"name": "代赭石", "dosage": "弹丸大一枚", "role": "降逆和胃"}
        ],
        "indication": "百合病下之后者，百合滑石代赭汤主之。",
        "contraindication": "虚寒者不宜",
        "dosage": "先以水洗百合，渍一宿，当白沫出，去其水，更以泉水二升，煎取一升，去滓，别以泉水二升煎滑石、代赭，取一升，去滓，后合和，煎取一升五合，分温再服",
        "explanation": "百合病误下后。百合养阴，滑石利水，代赭石降逆。误下伤中，需降逆利水。",
        "keywords": ["百合病", "误下", "降逆"]
    },
    {
        "name": "栝蒌牡蛎散",
        "alias": "",
        "meridian": "太阴/肺",
        "category": "生津止渴剂",
        "components": [
            {"name": "栝蒌根", "dosage": "等分", "role": "生津止渴"},
            {"name": "牡蛎", "dosage": "熬等分", "role": "潜阳散结"}
        ],
        "indication": "百合病变渴者，栝蒌牡蛎散主之。",
        "contraindication": "无阴虚者不宜",
        "dosage": "上为细末，饮服方寸匕，日三服",
        "explanation": "百合病口渴。栝蒌根生津止渴，牡蛎潜阳散结。阴虚火旺之渴。",
        "keywords": ["百合病", "口渴", "生津"]
    },
    {
        "name": "百合滑石散",
        "alias": "",
        "meridian": "太阴/肺",
        "category": "滋阴利湿剂",
        "components": [
            {"name": "百合", "dosage": "一两炙", "role": "润肺清心"},
            {"name": "滑石", "dosage": "二两", "role": "利水通淋"}
        ],
        "indication": "百合病变发热者，百合滑石散主之。",
        "contraindication": "无湿热者不宜",
        "dosage": "上为散，饮服方寸匕，日三服，当微利者止服，热则除",
        "explanation": "百合病发热。百合润肺清心，滑石利水清热。微利即止，防过伤阴。",
        "keywords": ["百合病", "发热", "利湿"]
    },
    {
        "name": "蜀漆散",
        "alias": "",
        "meridian": "少阳/太阳",
        "category": "涤痰截疟剂",
        "components": [
            {"name": "蜀漆", "dosage": "洗去腥", "role": "涤痰截疟"},
            {"name": "云母", "dosage": "烧二日夜", "role": "镇静安神"},
            {"name": "龙骨", "dosage": "等分", "role": "潜阳安神"}
        ],
        "indication": "疟多寒者，名曰牝疟，蜀漆散主之。",
        "contraindication": "体虚者慎用",
        "dosage": "上三味，杵为散，未发前以浆水服半钱。温疟加蜀漆半分，临发时服一钱匕",
        "explanation": "牝疟，痰湿内伏，阳气被遏。蜀漆涤痰截疟，云母龙骨镇静。浆水送服以助药力。",
        "keywords": ["疟疾", "牝疟", "多寒"]
    },
    {
        "name": "防己地黄汤",
        "alias": "",
        "meridian": "厥阴/肝",
        "category": "养血祛风剂",
        "components": [
            {"name": "防己", "dosage": "一钱", "role": "祛风利湿"},
            {"name": "桂枝", "dosage": "三钱", "role": "温经通络"},
            {"name": "防风", "dosage": "三钱", "role": "祛风解表"},
            {"name": "甘草", "dosage": "一钱", "role": "调和诸药"},
            {"name": "生地黄", "dosage": "二斤", "role": "清热凉血"}
        ],
        "indication": "病如狂状，妄行，独语不休，无寒热，其脉浮，防己地黄汤主之。",
        "contraindication": "无血虚者不宜",
        "dosage": "上四味，以酒一杯，渍之一宿，绞取汁，生地黄二斤，㕮咀，蒸之如斗米饭久，以铜器盛其汁，更绞地黄汁，和分再服",
        "explanation": "血虚风动，如狂妄行。重用生地养血凉血，防己防风祛风，桂枝通络，甘草调和。",
        "keywords": ["如狂", "妄行", "血虚", "风动"]
    },
    {
        "name": "侯氏黑散",
        "alias": "",
        "meridian": "厥阴/肝",
        "category": "祛风养血剂",
        "components": [
            {"name": "菊花", "dosage": "四十分", "role": "清肝散风"},
            {"name": "白术", "dosage": "十分", "role": "健脾燥湿"},
            {"name": "细辛", "dosage": "三分", "role": "散寒止痛"},
            {"name": "牡蛎", "dosage": "三分", "role": "潜阳散结"},
            {"name": "防风", "dosage": "十分", "role": "祛风解表"},
            {"name": "桔梗", "dosage": "八分", "role": "宣肺排脓"},
            {"name": "黄芩", "dosage": "五分", "role": "清热燥湿"},
            {"name": "人参", "dosage": "三分", "role": "补气扶正"},
            {"name": "矾石", "dosage": "三分", "role": "燥湿化痰"},
            {"name": "黄芩", "dosage": "五分", "role": "清热燥湿"},
            {"name": "川芎", "dosage": "三分", "role": "活血行气"},
            {"name": "桂枝", "dosage": "三分", "role": "温经通络"},
            {"name": "干姜", "dosage": "三分", "role": "温中散寒"},
            {"name": "茯苓", "dosage": "三分", "role": "利水渗湿"},
            {"name": "当归", "dosage": "三分", "role": "养血活血"}
        ],
        "indication": "大风四肢烦重，心中恶寒不足者，侯氏黑散主之。",
        "contraindication": "阴虚火旺者不宜",
        "dosage": "上十四味，杵为散，酒服方寸匕，日一服，初服二十日，温酒调服，禁一切鱼肉大蒜，常宜冷食，六十日止，即药积在腹中不下也。热食即下矣，冷食自能助药力",
        "explanation": "大风，风邪入中经络。菊花防风祛风，人参白术茯苓健脾，当归川芎养血活血，桂枝细辛温经，黄芩清热，矾石化痰。此为扶正祛风之方。",
        "keywords": ["中风", "大风", "四肢烦重"]
    },
    {
        "name": "风引汤",
        "alias": "",
        "meridian": "厥阴/肝",
        "category": "镇惊息风剂",
        "components": [
            {"name": "大黄", "dosage": "四两", "role": "泻热通便"},
            {"name": "干姜", "dosage": "四两", "role": "温中散寒"},
            {"name": "龙骨", "dosage": "四两", "role": "潜阳安神"},
            {"name": "桂枝", "dosage": "三两", "role": "温经通络"},
            {"name": "甘草", "dosage": "三两", "role": "调和诸药"},
            {"name": "牡蛎", "dosage": "二两", "role": "潜阳散结"},
            {"name": "寒水石", "dosage": "六两", "role": "清热泻火"},
            {"name": "滑石", "dosage": "六两", "role": "利水通淋"},
            {"name": "赤石脂", "dosage": "六两", "role": "固涩收敛"},
            {"name": "白石脂", "dosage": "六两", "role": "固涩收敛"},
            {"name": "紫石英", "dosage": "六两", "role": "镇心安神"},
            {"name": "石膏", "dosage": "六两", "role": "清热除烦"}
        ],
        "indication": "大人风引，少小惊痫瘛疭，日数十发，医所不疗，除热方，风引汤主之。",
        "contraindication": "虚寒者不宜",
        "dosage": "上十二味，杵，粗筛，以韦囊盛之，取三指撮，井花水三升，煮三沸，温服一升",
        "explanation": "风痫，肝风内动。大量金石药镇潜：龙骨牡蛎石膏寒水石等重镇息风，大黄泻热，桂枝干姜温通。此为重镇息风名方。",
        "keywords": ["惊痫", "瘛疭", "风引", "中风"]
    },
    {
        "name": "头风摩散",
        "alias": "",
        "meridian": "太阳",
        "category": "外用散寒剂",
        "components": [
            {"name": "大附子", "dosage": "一枚炮", "role": "温经散寒"},
            {"name": "盐", "dosage": "等分", "role": "渗透止痛"}
        ],
        "indication": "头风，头风摩散主之。",
        "contraindication": "热证头痛不宜",
        "dosage": "上二味，为散，沐了，以方寸匕，已摩疾上，令药力行",
        "explanation": "头风寒痛，外用方。附子温经散寒止痛，盐渗透引药。洗头后摩于患处。",
        "keywords": ["头风", "头痛", "外用"]
    },
    {
        "name": "千金三黄汤",
        "alias": "",
        "meridian": "太阳/厥阴",
        "category": "祛风清热剂",
        "components": [
            {"name": "麻黄", "dosage": "五分", "role": "发汗解表"},
            {"name": "独活", "dosage": "四分", "role": "祛风除湿"},
            {"name": "细辛", "dosage": "二分", "role": "散寒止痛"},
            {"name": "黄芪", "dosage": "二分", "role": "益气固表"},
            {"name": "黄芩", "dosage": "三分", "role": "清热燥湿"}
        ],
        "indication": "中风手足拘急，百节疼痛，烦热心乱，恶寒，经日不欲饮食，千金三黄汤主之。",
        "contraindication": "阴虚者不宜",
        "dosage": "以水六升，煮取三升，分三服，一服小汗，二服大汗。心热加大黄二分，腹满加枳实一枚，气逆加人参三分，悸加牡蛎三分，渴加栝蒌根三分，先有寒加附子一枚",
        "explanation": "中风，风邪入中经络。麻黄细辛祛风散寒，独活祛风湿，黄芪益气固表，黄芩清里热。",
        "keywords": ["中风", "手足拘急", "百节疼痛"]
    },
    {
        "name": "小续命汤",
        "alias": "",
        "meridian": "太阳/厥阴",
        "category": "祛风扶正剂",
        "components": [
            {"name": "麻黄", "dosage": "一两", "role": "发汗解表"},
            {"name": "桂枝", "dosage": "一两", "role": "温经通络"},
            {"name": "甘草", "dosage": "一两", "role": "调和诸药"},
            {"name": "杏仁", "dosage": "一两", "role": "宣肺降气"},
            {"name": "人参", "dosage": "一两", "role": "补气扶正"},
            {"name": "川芎", "dosage": "一两", "role": "活血行气"},
            {"name": "黄芩", "dosage": "一两", "role": "清热燥湿"},
            {"name": "芍药", "dosage": "一两", "role": "柔肝缓急"},
            {"name": "防风", "dosage": "一两半", "role": "祛风解表"},
            {"name": "防己", "dosage": "一两", "role": "祛风利湿"},
            {"name": "附子", "dosage": "一枚炮", "role": "温阳通络"},
            {"name": "生姜", "dosage": "五两", "role": "散寒止呕"}
        ],
        "indication": "中风卒然不知人，手足拘急，或半身不遂，口眼歪斜，小续命汤主之。",
        "contraindication": "阴虚火旺者不宜",
        "dosage": "以水一斗二升，煮取三升，分温三服",
        "explanation": "中风，正虚邪中。麻桂防风祛风，人参附子扶正温阳，黄芩清里热，川芎芍药养血。此为中风通治方。",
        "keywords": ["中风", "口眼歪斜", "半身不遂"]
    },
    {
        "name": "乌头赤石脂丸",
        "alias": "乌金丸",
        "meridian": "少阴/心",
        "category": "温里止痛剂",
        "components": [
            {"name": "乌头", "dosage": "一分炮", "role": "温里散寒"},
            {"name": "蜀椒", "dosage": "一两", "role": "温中散寒"},
            {"name": "干姜", "dosage": "一两", "role": "温中散寒"},
            {"name": "附子", "dosage": "半两炮", "role": "温阳散寒"},
            {"name": "赤石脂", "dosage": "一两", "role": "固涩收敛"}
        ],
        "indication": "心痛彻背，背痛彻心，乌头赤石脂丸主之。",
        "contraindication": "热证心痛禁用",
        "dosage": "上五味，末之，蜜丸如梧子大，先食服一丸，日三服，不知，稍加服",
        "explanation": "阴寒极盛，心痛彻背。乌头附子干姜蜀椒四药大辛大热散寒止痛，赤石脂固涩。此为温里止痛峻方。",
        "keywords": ["心痛", "胸痹", "阴寒", "彻背"]
    },
    {
        "name": "茯苓杏仁甘草汤",
        "alias": "",
        "meridian": "太阴/肺",
        "category": "宣肺化饮剂",
        "components": [
            {"name": "茯苓", "dosage": "三两", "role": "利水渗湿"},
            {"name": "杏仁", "dosage": "五十个", "role": "宣肺降气"},
            {"name": "甘草", "dosage": "一两", "role": "调和诸药"}
        ],
        "indication": "胸痹，胸中气塞，短气，茯苓杏仁甘草汤主之；橘枳姜汤亦主之。",
        "contraindication": "阴虚者不宜",
        "dosage": "以水一斗，煮取五升，温服一升，日三服，不差，更服",
        "explanation": "胸痹轻证，气塞短气。茯苓利水，杏仁宣肺降气，甘草调和。水饮停胸之轻证。",
        "keywords": ["胸痹", "短气", "气塞"]
    },
    {
        "name": "橘枳生姜汤",
        "alias": "",
        "meridian": "太阴/肺",
        "category": "理气化痰剂",
        "components": [
            {"name": "橘皮", "dosage": "一斤", "role": "理气化痰"},
            {"name": "枳实", "dosage": "三两", "role": "行气消痞"},
            {"name": "生姜", "dosage": "半斤", "role": "散寒化饮"}
        ],
        "indication": "胸痹，胸中气塞，短气，茯苓杏仁甘草汤主之；橘枳姜汤亦主之。",
        "contraindication": "气虚者不宜久服",
        "dosage": "以水五升，煮取二升，分温再服",
        "explanation": "胸痹气塞短气，气滞为主。橘皮理气化痰，枳实行气消痞，生姜散寒化饮。",
        "keywords": ["胸痹", "气塞", "短气"]
    },
    {
        "name": "桂枝生姜枳实汤",
        "alias": "",
        "meridian": "太阴/心",
        "category": "温阳化饮剂",
        "components": [
            {"name": "桂枝", "dosage": "三两", "role": "温阳通络"},
            {"name": "生姜", "dosage": "三两", "role": "散寒化饮"},
            {"name": "枳实", "dosage": "五枚", "role": "行气消痞"}
        ],
        "indication": "心中痞，诸逆，心悬痛，桂枝生姜枳实汤主之。",
        "contraindication": "阴虚者不宜",
        "dosage": "以水六升，煮取三升，分温三服",
        "explanation": "寒饮内停，心痞悬痛。桂枝温阳，生姜散寒化饮，枳实行气消痞。",
        "keywords": ["心痞", "悬痛", "寒饮"]
    },
    {
        "name": "黄芪建中汤",
        "alias": "",
        "meridian": "太阴",
        "category": "温中补虚剂",
        "components": [
            {"name": "黄芪", "dosage": "一两半", "role": "益气固表"},
            {"name": "桂枝", "dosage": "三两", "role": "温经通络"},
            {"name": "芍药", "dosage": "六两", "role": "柔肝缓急"},
            {"name": "生姜", "dosage": "三两", "role": "散寒止呕"},
            {"name": "大枣", "dosage": "十二枚", "role": "补脾和胃"},
            {"name": "甘草", "dosage": "二两炙", "role": "调和诸药"},
            {"name": "饴糖", "dosage": "一升", "role": "缓急止痛"}
        ],
        "indication": "虚劳里急，诸不足，黄芪建中汤主之。",
        "contraindication": "阴虚火旺者不宜",
        "dosage": "以水七升，煮取三升，去滓，内饴糖，更上微火消解，温服一升，日三服",
        "explanation": "虚劳里急，阴阳气血俱虚。小建中汤加黄芪，增强益气固表之力。",
        "keywords": ["虚劳", "里急", "诸不足"]
    },
    {
        "name": "禹余粮丸",
        "alias": "",
        "meridian": "太阳",
        "category": "涩肠固脱剂",
        "components": [
            {"name": "禹余粮", "dosage": "四两", "role": "涩肠止泻"},
            {"name": "人参", "dosage": "三两", "role": "补气固脱"},
            {"name": "附子", "dosage": "二枚炮", "role": "温阳固脱"}
        ],
        "indication": "汗家重发汗，必恍惚心乱，小便已阴疼，与禹余粮丸。",
        "contraindication": "实证不宜",
        "dosage": "丸剂",
        "explanation": "误治后津液大伤。禹余粮涩肠固脱，人参补气，附子温阳。",
        "keywords": ["涩肠", "固脱", "汗后"]
    },
]

# 去重并过滤已存在的
new_only = []
seen_names = set()
for f in NEW_FORMULAS:
    name = f['name']
    if name in seen_names:
        continue
    seen_names.add(name)
    if name not in existing_names:
        new_only.append(f)

print(f"新增方剂: {len(new_only)} 个")
for f in new_only:
    print(f"  {f['name']} ({f['category']})")

# 合并到现有数据
all_formulas = existing + new_only
output = {'total': len(all_formulas), 'formulas': all_formulas}

with open('assets/data/formulas.json', 'w', encoding='utf-8') as f:
    json.dump(output, f, ensure_ascii=False, indent=2)

print(f"\n合并后总计: {len(all_formulas)} 个方剂")
