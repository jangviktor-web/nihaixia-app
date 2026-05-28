"""补充倪海厦老师自创方/经验方 - 基于skill整理"""
import json

with open('assets/data/formulas.json','r',encoding='utf-8') as f:
    data = json.load(f)
formulas = data['formulas']
names = set(f['name'] for f in formulas)

NIHAISHA_FORMULAS = [
    # === 乳癌专方 ===
    {
        "name": "乳癌经验方第一方",
        "alias": "",
        "meridian": "少阳",
        "category": "倪海厦经验方",
        "components": [
            {"name": "柴胡", "dosage": "三钱", "role": "疏肝理气"},
            {"name": "黄芩", "dosage": "三钱", "role": "清热"},
            {"name": "瓦楞子", "dosage": "五钱", "role": "攻坚消乳房硬块"},
            {"name": "川芎", "dosage": "三钱", "role": "活血行气"},
            {"name": "丹皮", "dosage": "三钱", "role": "活血化瘀"},
            {"name": "三七", "dosage": "三钱", "role": "散瘀定痛"},
            {"name": "续断", "dosage": "三钱", "role": "续筋骨收敛伤口"},
            {"name": "炮附子", "dosage": "五钱", "role": "温阳散寒"},
            {"name": "阳起石", "dosage": "三钱", "role": "温肾壮阳"},
            {"name": "白芍", "dosage": "五钱", "role": "养血柔肝"},
            {"name": "枳实", "dosage": "三钱", "role": "行气消积"},
            {"name": "乳香", "dosage": "三钱", "role": "活血止痛"},
            {"name": "炒麦芽", "dosage": "五钱", "role": "退奶消乳腺肿块"},
            {"name": "郁金", "dosage": "五钱", "role": "疏肝解郁"},
            {"name": "当归", "dosage": "二钱", "role": "养血活血"},
            {"name": "牡蛎", "dosage": "一两", "role": "软坚散结"},
            {"name": "龙胆草", "dosage": "三钱", "role": "清肝胆湿热"}
        ],
        "indication": "乳癌或乳房中有硬块，尚未溃烂破出时使用。",
        "contraindication": "非乳癌硬块不宜",
        "dosage": "九碗水煮成三碗，早晚餐前各一碗",
        "explanation": "倪海厦乳癌经验方。主要观念在行气、破瘀、用咸味攻坚、开气去郁，令三焦气机流畅。瓦楞子攻坚消乳房硬块，牡蛎软坚散结，炒麦芽退奶消乳腺肿块。加减：体力差足冷加熟地三钱，经期加桂枝三钱。",
        "keywords": ["乳癌", "乳房硬块", "未溃烂", "倪海厦经验方"]
    },
    {
        "name": "乳癌经验方第二方",
        "alias": "",
        "meridian": "少阳",
        "category": "倪海厦经验方",
        "components": [
            {"name": "柴胡", "dosage": "三钱", "role": "疏肝理气"},
            {"name": "紫根", "dosage": "五钱", "role": "活血化瘀攻坚"},
            {"name": "龙骨", "dosage": "五钱", "role": "收敛镇惊"},
            {"name": "牡蛎", "dosage": "一两", "role": "软坚散结"},
            {"name": "白术", "dosage": "五钱", "role": "健脾燥湿"},
            {"name": "炮附子", "dosage": "五钱", "role": "温阳散寒"},
            {"name": "黄芩", "dosage": "三钱", "role": "清热"},
            {"name": "黄连", "dosage": "三钱", "role": "清热解毒"}
        ],
        "indication": "乳癌已经溃决破口，有恶臭，出黑臭水时使用。",
        "contraindication": "非溃烂期乳癌不宜",
        "dosage": "九碗水煮成三碗，早晚餐前各一碗",
        "explanation": "倪海厦乳癌经验方（溃烂期）。紫根（紫根牡蛎汤）对乳癌最好用，攻坚用。龙骨牡蛎收敛镇惊，白术健脾去湿。末期气血两虚时用八珍汤加减，以强固胃气、增加命门火为主。",
        "keywords": ["乳癌", "溃烂", "恶臭", "黑臭水", "倪海厦经验方"]
    },
    {
        "name": "乳癌末期移转方",
        "alias": "",
        "meridian": "少阳",
        "category": "倪海厦经验方",
        "components": [
            {"name": "柴胡", "dosage": "三钱", "role": "疏肝理气"},
            {"name": "防己", "dosage": "三钱", "role": "利水消肿"},
            {"name": "黄芩", "dosage": "三钱", "role": "清热"},
            {"name": "郁金", "dosage": "五钱", "role": "疏肝解郁"},
            {"name": "龙胆草", "dosage": "三钱", "role": "清肝胆湿热"},
            {"name": "黄连", "dosage": "两钱", "role": "清热解毒"},
            {"name": "白芍", "dosage": "五钱", "role": "养血柔肝"},
            {"name": "阿胶", "dosage": "三钱", "role": "补血止血"},
            {"name": "瓦楞子", "dosage": "五钱", "role": "攻坚消乳房硬块"},
            {"name": "牡蛎", "dosage": "一两", "role": "软坚散结"},
            {"name": "紫根", "dosage": "三钱", "role": "活血化瘀攻坚"},
            {"name": "酸枣仁", "dosage": "三钱", "role": "安神"},
            {"name": "知母", "dosage": "五钱", "role": "清热滋阴"},
            {"name": "川芎", "dosage": "三钱", "role": "活血行气"},
            {"name": "炮附子", "dosage": "三钱", "role": "温阳散寒"},
            {"name": "细辛", "dosage": "两钱", "role": "散寒止痛"},
            {"name": "半夏", "dosage": "三钱", "role": "化痰降逆"}
        ],
        "indication": "乳癌第四期，移转肝癌、肺癌、喉癌（乳癌移转多处）。",
        "contraindication": "非乳癌移转不宜",
        "dosage": "九碗水煮成三碗，早晚餐前各一碗",
        "explanation": "倪海厦乳癌末期移转方。瓦楞子着重在乳房（长得像乳房），牡蛎比较全身性。紫根（紫根牡蛎汤）对乳癌最好用。移转性的癌症抓头抓尾，乳癌和肝癌同时治。乳癌移转肝癌比较好治（由外入内），原发肝癌比较难治。",
        "keywords": ["乳癌末期", "移转", "肝癌", "肺癌", "倪海厦经验方"]
    },
    {
        "name": "乳癌消肿方",
        "alias": "石膏退奶方",
        "meridian": "阳明",
        "category": "倪海厦经验方",
        "components": [
            {"name": "石膏", "dosage": "六两", "role": "大寒清热逼奶水"},
            {"name": "知母", "dosage": "五钱", "role": "清热滋阴"},
            {"name": "天花粉", "dosage": "三钱", "role": "清热生津"},
            {"name": "麦门冬", "dosage": "三钱", "role": "养阴润肺"},
            {"name": "炒麦芽", "dosage": "五钱", "role": "退奶消乳腺肿块"},
            {"name": "当归", "dosage": "二钱", "role": "养血活血"},
            {"name": "川芎", "dosage": "三钱", "role": "活血行气"},
            {"name": "生地", "dosage": "二钱", "role": "清热凉血"},
            {"name": "白芍", "dosage": "三钱", "role": "养血柔肝"},
            {"name": "牡蛎", "dosage": "一两", "role": "软坚散结"},
            {"name": "龙骨", "dosage": "五钱", "role": "收敛"},
            {"name": "防己", "dosage": "五钱", "role": "利水消肿"},
            {"name": "瓦楞子", "dosage": "五钱", "role": "攻坚消乳房硬块"},
            {"name": "茯苓", "dosage": "五钱", "role": "利水渗湿"}
        ],
        "indication": "左乳房乳头下硬块，乳头凹陷。退奶消乳腺肿块。",
        "contraindication": "非乳房硬块不宜",
        "dosage": "水煎服",
        "explanation": "倪海厦乳癌消肿方。石膏6两大剂寒凉下沉，阳明经，逼奶水出来。四物汤补血活血，炒麦芽退奶消乳腺肿块。牡蛎+瓦楞子攻坚软坚消硬块，防己+茯苓排三焦水湿。疗效：第三天硬块从钢铁变棉花，一周后完全消失。",
        "keywords": ["乳癌", "乳房硬块", "退奶", "石膏大剂", "倪海厦经验方"]
    },
    # === 肝癌专方 ===
    {
        "name": "肝癌标准方",
        "alias": "",
        "meridian": "少阳",
        "category": "倪海厦经验方",
        "components": [
            {"name": "柴胡", "dosage": "三钱", "role": "疏肝理气"},
            {"name": "黄芩", "dosage": "三钱", "role": "清热"},
            {"name": "半夏", "dosage": "三钱", "role": "化痰降逆"},
            {"name": "党参", "dosage": "三钱", "role": "补气健脾"},
            {"name": "甘草", "dosage": "三钱", "role": "调和诸药"},
            {"name": "生姜", "dosage": "三片", "role": "散寒止呕"},
            {"name": "大枣", "dosage": "十枚", "role": "补脾和胃"},
            {"name": "郁金", "dosage": "五钱", "role": "疏肝解郁"},
            {"name": "龙胆草", "dosage": "三钱", "role": "清肝胆湿热"},
            {"name": "川芎", "dosage": "三钱", "role": "活血行气"},
            {"name": "丹皮", "dosage": "三钱", "role": "活血化瘀"},
            {"name": "白芍", "dosage": "五钱", "role": "养血柔肝"},
            {"name": "苍术", "dosage": "三钱", "role": "健脾燥湿"},
            {"name": "泽泻", "dosage": "五钱", "role": "利水渗湿"},
            {"name": "白术", "dosage": "三钱", "role": "健脾燥湿"},
            {"name": "茯苓", "dosage": "五钱", "role": "利水渗湿"},
            {"name": "茵陈", "dosage": "三钱", "role": "清利湿热退黄"},
            {"name": "补骨脂", "dosage": "三钱", "role": "温肾壮阳"},
            {"name": "熟地", "dosage": "三钱", "role": "滋阴补血"},
            {"name": "阳起石", "dosage": "三钱", "role": "温肾壮阳"},
            {"name": "续断", "dosage": "三钱", "role": "补肝肾"},
            {"name": "三七", "dosage": "三钱", "role": "散瘀定痛"},
            {"name": "炮附子", "dosage": "三钱", "role": "温阳散寒"},
            {"name": "桂枝", "dosage": "五钱", "role": "温经通阳"}
        ],
        "indication": "肝癌（西医未碰过），B肝转肝癌。",
        "contraindication": "非肝癌不宜",
        "dosage": "水煎服",
        "explanation": "倪海厦肝癌标准方。柴胡、黄芩、郁金、龙胆草是最常用的疏肝清肝组合。茜草+炙鳖甲为攻肝癌主力（B肝病毒指数快速下降）。苍术、泽泻、白术、茯苓甘淡渗利，实脾预防腹水。治肝必先治大肠（保持大便通畅）。平时煮四神汤当点心（淡味渗利预防腹水）。",
        "keywords": ["肝癌", "B肝", "疏肝", "预防腹水", "倪海厦经验方"]
    },
    # === 肺癌专方 ===
    {
        "name": "肺癌方",
        "alias": "桔梗甘草汤核心方",
        "meridian": "太阴",
        "category": "倪海厦经验方",
        "components": [
            {"name": "桔梗", "dosage": "一两", "role": "排脓祛痰"},
            {"name": "炙甘草", "dosage": "三钱", "role": "调和诸药"},
            {"name": "生半夏", "dosage": "四钱", "role": "化痰降逆排至高之水"},
            {"name": "干姜", "dosage": "两钱", "role": "温肺化饮"},
            {"name": "皂荚", "dosage": "三钱", "role": "祛顽痰"},
            {"name": "红枣", "dosage": "十枚", "role": "补脾和胃"},
            {"name": "射干", "dosage": "三钱", "role": "清热利咽"},
            {"name": "紫菀", "dosage": "三钱", "role": "润肺化痰"},
            {"name": "冬花", "dosage": "三钱", "role": "润肺止咳"},
            {"name": "麻黄", "dosage": "三钱", "role": "宣肺平喘"},
            {"name": "紫根", "dosage": "三钱", "role": "活血化瘀攻坚"}
        ],
        "indication": "肺癌第三至第四期，白泡沫痰，寒湿在肺。",
        "contraindication": "非肺癌寒湿型不宜",
        "dosage": "水煎服",
        "explanation": "倪海厦肺癌方。白泡沫痰用桔梗甘草汤（经方中唯一治白色泡沫痰的方）。紫参没有了，用紫根+丹皮桃仁+紫菀冬花+射干桔梗甘草来取代。治肺要治肝（郁金）。没有被西医碰过的肺癌，一定可以治好。",
        "keywords": ["肺癌", "白泡沫痰", "寒湿", "桔梗甘草汤", "倪海厦经验方"]
    },
    # === 血癌专方 ===
    {
        "name": "血癌炙甘草汤方",
        "alias": "",
        "meridian": "少阴",
        "category": "倪海厦经验方",
        "components": [
            {"name": "炙甘草", "dosage": "一两", "role": "大补心血"},
            {"name": "生姜", "dosage": "两片", "role": "散寒"},
            {"name": "大枣", "dosage": "十枚", "role": "补脾和胃"},
            {"name": "桂枝", "dosage": "五钱", "role": "温经通阳"},
            {"name": "麻子仁", "dosage": "三钱", "role": "润肠"},
            {"name": "熟地", "dosage": "两钱", "role": "滋阴补血"},
            {"name": "党参", "dosage": "三钱", "role": "补气"},
            {"name": "阿胶", "dosage": "三钱", "role": "补心血"},
            {"name": "当归", "dosage": "二钱", "role": "养血活血"},
            {"name": "白术", "dosage": "三钱", "role": "健脾"},
            {"name": "茯苓", "dosage": "三钱", "role": "利水"},
            {"name": "炮附子", "dosage": "四钱", "role": "固表阳止汗"},
            {"name": "龙骨", "dosage": "三钱", "role": "收敛"},
            {"name": "牡蛎", "dosage": "八钱", "role": "敛表阳止盗汗"}
        ],
        "indication": "血癌，脉结代（跳三四下停一下），盗汗24小时不止。",
        "contraindication": "非血癌不宜",
        "dosage": "水煎服",
        "explanation": "倪海厦血癌方。炙甘草一两重用为主力+阿胶补心血回心脏。炮附子+龙骨+牡蛎敛表阳止盗汗。失眠加生蛋黄（成黄连阿胶汤）。疗效：吃药当天晚上即可入睡，一周后WB从39降至28。",
        "keywords": ["血癌", "脉结代", "盗汗", "炙甘草重用", "倪海厦经验方"]
    },
    {
        "name": "血癌寒热并结方",
        "alias": "乳癌血癌淋巴癌同治方",
        "meridian": "厥阴",
        "category": "倪海厦经验方",
        "components": [
            {"name": "生附子", "dosage": "两钱", "role": "强心阳起阳"},
            {"name": "干姜", "dosage": "两钱", "role": "温中散寒"},
            {"name": "炙甘草", "dosage": "五钱", "role": "补中缓急"},
            {"name": "桂枝", "dosage": "三钱", "role": "温经通阳"},
            {"name": "白芍", "dosage": "三钱", "role": "养血柔肝"},
            {"name": "大黄", "dosage": "两钱", "role": "攻下瘀热"},
            {"name": "黄芩", "dosage": "三钱", "role": "清热"},
            {"name": "黄柏", "dosage": "三钱", "role": "清下焦热"},
            {"name": "黄连", "dosage": "两钱", "role": "清热解毒"},
            {"name": "防己", "dosage": "五钱", "role": "利水消肿"},
            {"name": "瓦楞子", "dosage": "五钱", "role": "攻坚消乳房硬块"},
            {"name": "牡蛎", "dosage": "八钱", "role": "软坚散结"},
            {"name": "紫根", "dosage": "三钱", "role": "活血化瘀攻坚"},
            {"name": "茯苓", "dosage": "五钱", "role": "利水渗湿"},
            {"name": "阿胶", "dosage": "三钱", "role": "补血止血"}
        ],
        "indication": "乳癌移转淋巴癌+血癌，寒热并结（上热下寒）。",
        "contraindication": "非寒热并结不宜",
        "dosage": "水煎服",
        "explanation": "倪海厦寒热并结方。生附子+干姜+炙甘草=四逆汤底（起阳治脚冰冷）。防己+茯苓=防己茯苓汤排三焦多余水。瓦楞子+牡蛎针对乳癌和淋巴癌硬块。紫根开过刀后使用（活血化瘀）。肿瘤治疗铁则：必须保持手脚温热。",
        "keywords": ["血癌", "乳癌", "淋巴癌", "寒热并结", "上热下寒", "倪海厦经验方"]
    },
    {
        "name": "小儿血癌方",
        "alias": "小建中汤加附子",
        "meridian": "太阴",
        "category": "倪海厦经验方",
        "components": [
            {"name": "桂枝", "dosage": "三钱", "role": "温经通阳"},
            {"name": "白芍", "dosage": "六钱", "role": "养血柔肝"},
            {"name": "生姜", "dosage": "两片", "role": "散寒"},
            {"name": "大枣", "dosage": "十枚", "role": "补脾和胃"},
            {"name": "炙甘草", "dosage": "三钱", "role": "补中"},
            {"name": "饴糖", "dosage": "一两", "role": "补脾缓急"},
            {"name": "生附子", "dosage": "一钱", "role": "强心阳"}
        ],
        "indication": "小儿麻痹疫苗引发的小儿血癌（5-6岁）。",
        "contraindication": "非小儿血癌不宜",
        "dosage": "水煎服",
        "explanation": "倪海厦小儿血癌方。小建中汤+生附子一钱。必须用生附子（非炮附子），恢复心脏阳气。小儿附子一钱即足。",
        "keywords": ["小儿血癌", "疫苗后遗症", "小建中汤", "生附子", "倪海厦经验方"]
    },
    # === 脑瘤专方 ===
    {
        "name": "脑瘤治疗方",
        "alias": "生附子生硫磺生半夏三主药",
        "meridian": "少阴",
        "category": "倪海厦经验方",
        "components": [
            {"name": "生附子", "dosage": "五钱", "role": "强心阳起阳"},
            {"name": "生硫磺", "dosage": "三钱", "role": "强命门火气化水湿达脑部"},
            {"name": "生半夏", "dosage": "三钱", "role": "排至高之水脑积水"},
            {"name": "黄精", "dosage": "三钱", "role": "补脾润肺"},
            {"name": "阳起石", "dosage": "三钱", "role": "温肾壮阳"},
            {"name": "柴胡", "dosage": "三钱", "role": "疏肝理气"},
            {"name": "郁金", "dosage": "五钱", "role": "疏肝解郁"},
            {"name": "熟地", "dosage": "三钱", "role": "滋阴补血"},
            {"name": "补骨脂", "dosage": "三钱", "role": "温肾壮阳"},
            {"name": "防己", "dosage": "三钱", "role": "利水消肿"},
            {"name": "桂枝", "dosage": "五钱", "role": "温经通阳"},
            {"name": "炙甘草", "dosage": "五钱", "role": "补中缓急"},
            {"name": "白芍", "dosage": "五钱", "role": "养血柔肝"},
            {"name": "乌药", "dosage": "三钱", "role": "行气散寒"},
            {"name": "菟丝子", "dosage": "三钱", "role": "补肾固精"},
            {"name": "茵陈", "dosage": "三钱", "role": "清利湿热"},
            {"name": "龙胆草", "dosage": "三钱", "role": "清肝胆湿热"},
            {"name": "川芎", "dosage": "三钱", "role": "活血行气"},
            {"name": "生姜", "dosage": "两片", "role": "散寒"},
            {"name": "大枣", "dosage": "十枚", "role": "补脾和胃"}
        ],
        "indication": "脑瘤，脑积水，脑部肿瘤。",
        "contraindication": "非脑瘤不宜",
        "dosage": "水煎服",
        "explanation": "倪海厦脑瘤三主药方。生附子一定要配生硫磺才能彻底清除脑部肿瘤。生硫磺性轻飘如麻黄，可升达头部。最高安全剂量：生附子6钱+生硫磺5钱（煮1小时以上）。单用生附子手不会热；必须配桂枝手才会温热。",
        "keywords": ["脑瘤", "脑积水", "生附子", "生硫磺", "倪海厦经验方"]
    },
    # === 红斑性狼疮专方 ===
    {
        "name": "红斑性狼疮标准方",
        "alias": "石膏大剂型",
        "meridian": "厥阴",
        "category": "倪海厦经验方",
        "components": [
            {"name": "生附子", "dosage": "五钱", "role": "强心阳起阳"},
            {"name": "细辛", "dosage": "两钱", "role": "散寒止痛"},
            {"name": "石膏", "dosage": "六两", "role": "大寒清热降上热"},
            {"name": "知母", "dosage": "五钱", "role": "清热滋阴"},
            {"name": "防己", "dosage": "五钱", "role": "利水消肿"},
            {"name": "茯苓", "dosage": "五钱", "role": "利水渗湿"},
            {"name": "泽泻", "dosage": "六钱", "role": "利水渗湿"},
            {"name": "黄精", "dosage": "三钱", "role": "补脾润肺"},
            {"name": "桑螵蛸", "dosage": "三钱", "role": "补肾固精（女）"},
            {"name": "炙甘草", "dosage": "五钱", "role": "补中缓急"},
            {"name": "柴胡", "dosage": "三钱", "role": "疏肝理气"},
            {"name": "郁金", "dosage": "五钱", "role": "疏肝解郁"},
            {"name": "龙胆草", "dosage": "三钱", "role": "清肝胆湿热"},
            {"name": "瓦楞子", "dosage": "五钱", "role": "攻坚消硬块"},
            {"name": "阳起石", "dosage": "三钱", "role": "温肾壮阳"}
        ],
        "indication": "红斑性狼疮，真寒假热，上热下寒。",
        "contraindication": "非红斑性狼疮不宜",
        "dosage": "水煎服",
        "explanation": "倪海厦红斑性狼疮标准方。生附子+大剂石膏并用：起阳同时降上热，两力协同把奶水导回正道。防己+茯苓排三焦水肿。红斑性狼疮=奶水逆流入心→第五椎压痛。关节痛无需专门治关节：奶水排出后关节压力去，痛自消。",
        "keywords": ["红斑性狼疮", "真寒假热", "上热下寒", "石膏大剂", "倪海厦经验方"]
    },
    {
        "name": "红斑性狼疮清肝方",
        "alias": "",
        "meridian": "少阳",
        "category": "倪海厦经验方",
        "components": [
            {"name": "柴胡", "dosage": "三钱", "role": "疏肝理气"},
            {"name": "黄芩", "dosage": "三钱", "role": "清热"},
            {"name": "郁金", "dosage": "五钱", "role": "疏肝解郁"},
            {"name": "龙胆草", "dosage": "三钱", "role": "清肝胆湿热"},
            {"name": "茵陈", "dosage": "三钱", "role": "清利湿热退黄"},
            {"name": "栀子", "dosage": "三钱", "role": "清热泻火"},
            {"name": "怀山", "dosage": "五钱", "role": "补脾固肾"},
            {"name": "薏苡仁", "dosage": "三钱", "role": "健脾渗湿"},
            {"name": "芡实", "dosage": "三钱", "role": "固肾涩精"},
            {"name": "连翘", "dosage": "三钱", "role": "清热解毒"},
            {"name": "银花", "dosage": "两钱", "role": "清热解毒"},
            {"name": "蝉蜕", "dosage": "五分", "role": "疏风透疹"},
            {"name": "蛇蜕", "dosage": "五分", "role": "祛风通络"},
            {"name": "酸枣仁", "dosage": "三钱", "role": "安神"},
            {"name": "丹皮", "dosage": "三钱", "role": "活血化瘀"},
            {"name": "白芍", "dosage": "五钱", "role": "养血柔肝"}
        ],
        "indication": "红斑性狼疮初期，全身性红疹，肝损伤严重。",
        "contraindication": "非红斑性狼疮初期不宜",
        "dosage": "水煎服",
        "explanation": "倪海厦红斑性狼疮清肝方。甘淡渗利（怀山、薏苡仁、芡实）为阳性药，预防肝病后腹水。蝉蜕+蛇蜕治疗全身性蜕皮。酸枣仁治肝损伤失眠。",
        "keywords": ["红斑性狼疮", "初期", "清肝", "全身红疹", "倪海厦经验方"]
    },
    # === 尿毒症专方 ===
    {
        "name": "尿毒症标准方",
        "alias": "当归四逆汤加减",
        "meridian": "少阴",
        "category": "倪海厦经验方",
        "components": [
            {"name": "桂枝", "dosage": "四钱", "role": "温经通阳"},
            {"name": "白芍", "dosage": "四钱", "role": "养血柔肝"},
            {"name": "炙甘草", "dosage": "三钱", "role": "补中缓急"},
            {"name": "生姜", "dosage": "两片", "role": "散寒"},
            {"name": "红枣", "dosage": "十个", "role": "补脾和胃"},
            {"name": "生附子", "dosage": "三钱", "role": "强心阳"},
            {"name": "干姜", "dosage": "两钱", "role": "温中散寒"},
            {"name": "白术", "dosage": "三钱", "role": "健脾燥湿"},
            {"name": "茯苓", "dosage": "五钱", "role": "利水渗湿"},
            {"name": "木通", "dosage": "三钱", "role": "通利血脉"},
            {"name": "当归", "dosage": "三钱", "role": "养血活血"},
            {"name": "细辛", "dosage": "三钱", "role": "散寒止痛"},
            {"name": "炮附子", "dosage": "三钱", "role": "固肾阳"}
        ],
        "indication": "尿毒症，手脚冰冷，便秘，小便黄，里寒湿证。",
        "contraindication": "非尿毒症不宜",
        "dosage": "水煎服",
        "explanation": "倪海厦尿毒症标准方。尿毒症三主药：炮附子+生附子+黄连（缺一不可）。炮附子→固肾阳；生附子→强心阳；黄连→解尿毒。治肾必先治心。停药时机=大便成条状。前面完全在恢复心阳，最后才加黄连黄芩解尿毒。",
        "keywords": ["尿毒症", "肾衰竭", "当归四逆汤", "治肾先治心", "倪海厦经验方"]
    },
    # === 渐冻症专方 ===
    {
        "name": "渐冻症方",
        "alias": "茯苓四逆汤加减",
        "meridian": "少阴",
        "category": "倪海厦经验方",
        "components": [
            {"name": "生附子", "dosage": "三钱", "role": "强心阳起阳"},
            {"name": "干姜", "dosage": "两钱", "role": "温中散寒"},
            {"name": "炙甘草", "dosage": "三钱", "role": "补中缓急"},
            {"name": "茯苓", "dosage": "五钱", "role": "利水渗湿"},
            {"name": "白术", "dosage": "三钱", "role": "健脾燥湿"},
            {"name": "牛膝", "dosage": "三钱", "role": "活血通经引药下行"},
            {"name": "桂枝", "dosage": "四钱", "role": "温经通阳"},
            {"name": "白芍", "dosage": "四钱", "role": "养血柔肝"},
            {"name": "当归", "dosage": "两钱", "role": "养血活血"},
            {"name": "细辛", "dosage": "两钱", "role": "散寒止痛"},
            {"name": "补骨脂", "dosage": "三钱", "role": "温肾壮阳"},
            {"name": "泽泻", "dosage": "四钱", "role": "利水渗湿"}
        ],
        "indication": "渐冻症（ALS），手脚冰冷，里寒重症，极度倦怠。",
        "contraindication": "非渐冻症不宜",
        "dosage": "水煎服",
        "explanation": "倪海厦渐冻症方。动作逐渐慢下来=寒，不会用生附子不会好。炮附子是炮附子，生附子是生附子，不能用炮附子取代生附子。疗效：吃药当天就一觉到天亮。",
        "keywords": ["渐冻症", "ALS", "茯苓四逆汤", "生附子", "倪海厦经验方"]
    },
    # === 心脏病专方 ===
    {
        "name": "心绞痛方",
        "alias": "汉唐77号汤剂版",
        "meridian": "少阴",
        "category": "倪海厦经验方",
        "components": [
            {"name": "川芎", "dosage": "三钱", "role": "活血行气"},
            {"name": "丹皮", "dosage": "三钱", "role": "活血化瘀"},
            {"name": "桃仁", "dosage": "三钱", "role": "破血逐瘀"},
            {"name": "川红花", "dosage": "一钱", "role": "活血化瘀治心正中剧痛"},
            {"name": "栝蒌实", "dosage": "五钱", "role": "宽胸散结"},
            {"name": "薤白", "dosage": "三钱", "role": "通阳散结"},
            {"name": "桂枝", "dosage": "四钱", "role": "温经通阳"},
            {"name": "地龙", "dosage": "三钱", "role": "通经活络"},
            {"name": "当归", "dosage": "三钱", "role": "养血活血"},
            {"name": "牛膝", "dosage": "三钱", "role": "活血引药下行"},
            {"name": "木通", "dosage": "三钱", "role": "通利血脉"},
            {"name": "白芍", "dosage": "一两", "role": "养血柔肝止脚痛"},
            {"name": "枳实", "dosage": "三钱", "role": "行气消积"},
            {"name": "黄连", "dosage": "两钱", "role": "清热"},
            {"name": "黄芩", "dosage": "三钱", "role": "清热"},
            {"name": "细辛", "dosage": "两钱", "role": "散寒止痛"},
            {"name": "炮附子", "dosage": "两钱", "role": "温阳散寒"}
        ],
        "indication": "心绞痛，动脉血管堵塞严重，持续刺痛。",
        "contraindication": "非心绞痛不宜",
        "dosage": "水煎服",
        "explanation": "倪海厦心绞痛方（汉唐77号汤剂版）。血管问题三种必备药：川芎、丹皮、桃仁（三胞胎一组）。红花治心正中剧痛（川红花味厚入心）。地龙（蚯蚓）到处钻，全身血脉都通。活血化瘀去不掉时用动物性药（地龙）。用活血化瘀药一定要加补血药（当归），否则血虚。闷痛=心气不行；刺痛=血管堵到，需要活血化瘀。",
        "keywords": ["心绞痛", "动脉堵塞", "活血化瘀", "地龙", "倪海厦经验方"]
    },
    # === 肝硬化腹水专方 ===
    {
        "name": "肝硬化腹水分消汤",
        "alias": "",
        "meridian": "太阴",
        "category": "倪海厦经验方",
        "components": [
            {"name": "泽泻", "dosage": "四钱", "role": "利水渗湿"},
            {"name": "猪苓", "dosage": "四钱", "role": "利水渗湿"},
            {"name": "茯苓", "dosage": "五钱", "role": "利水渗湿"},
            {"name": "半夏", "dosage": "三钱", "role": "化痰降逆"},
            {"name": "陈皮", "dosage": "四钱", "role": "理气健脾"},
            {"name": "厚朴", "dosage": "四钱", "role": "行气消胀"},
            {"name": "苍术", "dosage": "五钱", "role": "健脾燥湿"},
            {"name": "白术", "dosage": "五钱", "role": "健脾燥湿"},
            {"name": "枳实", "dosage": "三钱", "role": "行气消积"},
            {"name": "大腹皮", "dosage": "三钱", "role": "行气利水"},
            {"name": "砂仁", "dosage": "三钱", "role": "化湿行气"},
            {"name": "木香", "dosage": "三钱", "role": "行气止痛"},
            {"name": "干姜", "dosage": "三钱", "role": "温中散寒"},
            {"name": "生姜", "dosage": "两片", "role": "散寒"},
            {"name": "薏苡仁", "dosage": "四钱", "role": "健脾渗湿"},
            {"name": "黄精", "dosage": "三钱", "role": "补脾润肺"},
            {"name": "熟地", "dosage": "三钱", "role": "滋阴补血"},
            {"name": "补骨脂", "dosage": "三钱", "role": "温肾壮阳"},
            {"name": "败龟板", "dosage": "三钱", "role": "滋阴潜阳"},
            {"name": "阳起石", "dosage": "三钱", "role": "温肾壮阳"},
            {"name": "当归", "dosage": "两钱", "role": "养血活血"}
        ],
        "indication": "肝硬化腹水，实证腹水。",
        "contraindication": "非肝硬化腹水不宜",
        "dosage": "水煎服",
        "explanation": "倪海厦肝硬化腹水分消汤。分消汤用在实证腹水。甘淡渗利（陈皮、白术、枳实、大腹皮、薏苡仁、茯苓）为阳性药。黄精补脾脏，有运化之功。腹胀很厉害用厚朴行气。胃苓汤（粉剂）对排腹水也有帮助。",
        "keywords": ["肝硬化", "腹水", "分消汤", "实证腹水", "倪海厦经验方"]
    },
    # === 子宫肌瘤/助孕专方 ===
    {
        "name": "子宫肌瘤不孕方",
        "alias": "当归四逆汤加吴茱萸生姜",
        "meridian": "厥阴",
        "category": "倪海厦经验方",
        "components": [
            {"name": "炮附子", "dosage": "五钱", "role": "温阳散寒"},
            {"name": "桂枝", "dosage": "三钱", "role": "温经通阳"},
            {"name": "白芍", "dosage": "六钱", "role": "养血柔肝"},
            {"name": "生姜", "dosage": "两片", "role": "散寒"},
            {"name": "干姜", "dosage": "三钱", "role": "温中散寒"},
            {"name": "吴茱萸", "dosage": "三钱", "role": "温中降逆散寒"},
            {"name": "柴胡", "dosage": "三钱", "role": "疏肝理气"},
            {"name": "郁金", "dosage": "三钱", "role": "疏肝解郁"},
            {"name": "当归", "dosage": "三钱", "role": "养血活血"},
            {"name": "熟地", "dosage": "三钱", "role": "滋阴补血"},
            {"name": "艾叶", "dosage": "三钱", "role": "暖宫止血"},
            {"name": "生附子", "dosage": "三钱棉布包", "role": "强心阳"},
            {"name": "续断", "dosage": "三钱", "role": "补肝肾"},
            {"name": "辛夷花", "dosage": "三钱", "role": "通鼻窍"},
            {"name": "水菖蒲", "dosage": "三钱", "role": "化湿开窍"},
            {"name": "蜀椒", "dosage": "两钱", "role": "温中散寒"},
            {"name": "丹皮", "dosage": "三钱", "role": "活血化瘀"},
            {"name": "桃仁", "dosage": "三钱", "role": "破血逐瘀"}
        ],
        "indication": "子宫肌瘤多次开刀后，手脚冰冷，血虚，不孕。",
        "contraindication": "非子宫肌瘤不孕不宜",
        "dosage": "水煎服",
        "explanation": "倪海厦子宫肌瘤不孕方。生附子和炮附子一起用=下焦寒湿很盛时才用。当归四逆汤+吴茱萸生姜汤=胃口不好恶心。疗效：吃一个半月就怀孕。怀孕后：前20周吃当归散，后20周吃白术散（补小孩）。",
        "keywords": ["子宫肌瘤", "不孕", "当归四逆汤", "吴茱萸", "倪海厦经验方"]
    },
    # === 肺炎/肺脓疡专方 ===
    {
        "name": "肺炎肺脓疡方",
        "alias": "苇茎汤加大承气汤",
        "meridian": "阳明",
        "category": "倪海厦经验方",
        "components": [
            {"name": "苇茎", "dosage": "六钱", "role": "清肺排脓"},
            {"name": "薏苡仁", "dosage": "五钱", "role": "健脾渗湿排脓"},
            {"name": "丹皮", "dosage": "三钱", "role": "活血化瘀"},
            {"name": "桃仁", "dosage": "三钱", "role": "破血逐瘀"},
            {"name": "栝蒌实", "dosage": "五钱", "role": "宽胸散结"},
            {"name": "桔梗", "dosage": "五钱", "role": "排脓祛痰"},
            {"name": "甘草", "dosage": "三钱", "role": "调和诸药"},
            {"name": "厚朴", "dosage": "两钱", "role": "行气消胀"},
            {"name": "枳实", "dosage": "两钱", "role": "行气消积"},
            {"name": "大黄", "dosage": "三钱", "role": "攻下热结"},
            {"name": "芒硝", "dosage": "三钱生用冲服", "role": "软坚泻下"}
        ],
        "indication": "肺炎化脓（肺脓疡），白泡沫痰，便秘五天，高热。",
        "contraindication": "非肺脓疡不宜",
        "dosage": "水煎服",
        "explanation": "倪海厦肺炎肺脓疡方。治疗肺炎首重大便，一定要让病人排便顺利。大承气汤解发高烧：大便一通，大部分脓咳出来，烧就退了。苇茎汤+桔梗甘草汤（排脓汤）+大承气汤三合一。",
        "keywords": ["肺炎", "肺脓疡", "苇茎汤", "大承气汤", "倪海厦经验方"]
    },
    # === 其他经验方 ===
    {
        "name": "鲤鱼汤排水方",
        "alias": "",
        "meridian": "太阴",
        "category": "倪海厦经验方",
        "components": [
            {"name": "赤小豆", "dosage": "一两", "role": "利水消肿"},
            {"name": "黄芪", "dosage": "五钱", "role": "补气利水"},
            {"name": "薏苡仁", "dosage": "一两", "role": "健脾渗湿"},
            {"name": "芡实", "dosage": "一两", "role": "固肾涩精"},
            {"name": "莲子", "dosage": "一两", "role": "补脾止泻"},
            {"name": "鲤鱼", "dosage": "一条", "role": "高蛋白排水"}
        ],
        "indication": "腹水排水，鲤鱼=白蛋白含量很高。",
        "contraindication": "非腹水不宜",
        "dosage": "与鲤鱼同煮汤服",
        "explanation": "倪海厦鲤鱼汤排水方。鲤鱼白蛋白含量很高，配合赤小豆黄芪薏苡仁芡实莲子同煮，利水消肿同时补充营养。",
        "keywords": ["腹水", "排水", "鲤鱼", "高蛋白", "倪海厦经验方"]
    },
    {
        "name": "术附汤",
        "alias": "",
        "meridian": "少阴",
        "category": "倪海厦经验方",
        "components": [
            {"name": "炮附子", "dosage": "五钱", "role": "温阳散寒排脓"},
            {"name": "白术", "dosage": "五钱", "role": "健脾燥湿排脓"}
        ],
        "indication": "乳房周围黑色脓肿期排脓，末期乳癌伤口有臭味。",
        "contraindication": "非排脓期不宜",
        "dosage": "水煎服",
        "explanation": "倪海厦术附汤排脓方。排脓未尽不可收口（黑色→红色→粉红色，才换收敛药）。炮附子温阳排脓，白术健脾去湿排脓。",
        "keywords": ["排脓", "乳癌", "伤口", "术附汤", "倪海厦经验方"]
    },
]

added = 0
for f in NIHAISHA_FORMULAS:
    name = f["name"]
    if name in names:
        print(f"SKIP (already exists): {name}")
        continue
    formulas.append(f)
    names.add(name)
    added += 1
    print(f"Added: {name}")

output = {"total": len(formulas), "formulas": formulas}
with open("assets/data/formulas.json", "w", encoding="utf-8") as fp:
    json.dump(output, fp, ensure_ascii=False, indent=2)

print(f"\nAdded {added} nihaisha formulas. Total now: {len(formulas)}")
