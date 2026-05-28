#!/usr/bin/env python3
"""生成伤寒论全量方剂数据（113方）"""
import json

# 伤寒论方剂数据
# 格式: (id, name, alias, meridian, category, components, indication, contraindication, dosage, explanation, keywords)
SHANGHAN_FORMULAS = [
    # ===== 太阳病篇 =====
    {
        "id": "guizhi_tang", "name": "桂枝汤", "alias": "群方之魁", "meridian": "太阳", "category": "解表剂",
        "components": [
            {"name": "桂枝", "dosage": "三两", "role": "壮心阳，发汗解肌"},
            {"name": "芍药", "dosage": "三两", "role": "敛阴和营"},
            {"name": "生姜", "dosage": "三两", "role": "温胃散寒"},
            {"name": "大枣", "dosage": "十二枚", "role": "补脾生津"},
            {"name": "炙甘草", "dosage": "二两", "role": "调和诸药"}
        ],
        "indication": "太阳中风：发热，汗出，恶风，脉缓。头痛，鼻鸣，干呕。",
        "contraindication": "脉浮紧发热汗不出者不可与。酒客不可与。吐家不可与。",
        "dosage": "水七升，微火煮取三升，去滓，温服一升。啜热稀粥一升余以助药力。温覆令一时许，遍身漐漐微似有汗者益佳。",
        "explanation": "桂枝壮心阳，白芍让静脉回流加速，生姜刺激肠胃，大枣补津液，炙甘草解百毒。五味药调和营卫，为群方之魁。",
        "keywords": ["发热", "汗出", "恶风", "头痛", "中风", "营卫不和"]
    },
    {
        "id": "mahuang_tang", "name": "麻黄汤", "alias": "伤寒第一方", "meridian": "太阳", "category": "解表剂",
        "components": [
            {"name": "麻黄", "dosage": "三两", "role": "开毛孔，发汗解表"},
            {"name": "桂枝", "dosage": "二两", "role": "温经散寒"},
            {"name": "杏仁", "dosage": "七十个", "role": "降肺气平喘"},
            {"name": "炙甘草", "dosage": "一两", "role": "调和诸药"}
        ],
        "indication": "太阳伤寒：或已发热，或未发热，必恶寒，体痛，呕逆，脉阴阳俱紧。",
        "contraindication": "疮家、衄家、亡血家、汗家不可发汗。",
        "dosage": "水九升，先煮麻黄减二升，去上沫，内诸药，煮取二升半，去滓，温服八合。覆取微似汗。",
        "explanation": "麻黄开毛孔，桂枝强心阳，杏仁降肺气，甘草调和。无汗用麻黄，有汗用桂枝。",
        "keywords": ["无汗", "恶寒", "体痛", "伤寒", "骨节疼痛", "脉紧"]
    },
    {
        "id": "guizhi_gegen_tang", "name": "桂枝加葛根汤", "alias": "", "meridian": "太阳", "category": "解表剂",
        "components": [
            {"name": "桂枝", "dosage": "三两"}, {"name": "芍药", "dosage": "三两"},
            {"name": "葛根", "dosage": "四两", "role": "升津液，舒经脉"},
            {"name": "生姜", "dosage": "三两"}, {"name": "大枣", "dosage": "十二枚"}, {"name": "炙甘草", "dosage": "二两"}
        ],
        "indication": "太阳病，项背强几几，汗出恶风。",
        "contraindication": "无汗者不可用。",
        "dosage": "水一斗，先煮葛根减二升，去上沫，内诸药，煮取三升，去滓，温服一升。覆取微似汗。",
        "explanation": "葛根把水提升上来，靠桂枝把水排出去变成汗。葛根重用四两才能到背部。面部中风、口歪眼斜必加葛根。",
        "keywords": ["项背强", "脖子僵硬", "葛根", "面部中风"]
    },
    {
        "id": "guizhi_houpo_xingren_tang", "name": "桂枝加厚朴杏仁汤", "alias": "", "meridian": "太阳", "category": "解表剂",
        "components": [
            {"name": "桂枝", "dosage": "三两"}, {"name": "芍药", "dosage": "三两"}, {"name": "生姜", "dosage": "三两"},
            {"name": "厚朴", "dosage": "二两", "role": "去脾湿，降气"},
            {"name": "杏仁", "dosage": "五十个", "role": "去肺热，化痰"},
            {"name": "大枣", "dosage": "十二枚"}, {"name": "炙甘草", "dosage": "二两"}
        ],
        "indication": "太阳病，下之后，微喘者。喘家作。",
        "contraindication": "无桂枝汤证者不可用。",
        "dosage": "水七升，微火煮取三升，去滓，温服一升。",
        "explanation": "素有喘家，得桂枝汤证，加厚朴去脾湿、杏仁去肺热化痰。有主证兼证同时出现时，以主证为主。",
        "keywords": ["喘", "咳嗽", "气喘", "厚朴", "杏仁"]
    },
    {
        "id": "guizhi_jia_fuzi_tang", "name": "桂枝加附子汤", "alias": "", "meridian": "太阳", "category": "解表剂",
        "components": [
            {"name": "桂枝", "dosage": "三两"}, {"name": "芍药", "dosage": "三两"}, {"name": "生姜", "dosage": "三两"},
            {"name": "大枣", "dosage": "十二枚"}, {"name": "炙甘草", "dosage": "二两"},
            {"name": "炮附子", "dosage": "一枚", "role": "固表阳，止汗"}
        ],
        "indication": "太阳病，发汗，遂漏不止，其人恶风，小便难，四肢微急，难以屈伸者。",
        "contraindication": "无汗出不止者不可用。",
        "dosage": "水七升，微火煮取三升，去滓，温服一升。",
        "explanation": "发汗太过，阳气虚脱，汗漏不止。炮附子固表阳，配桂枝汤调和营卫。汗出恶风+小便难=阳虚液亏。",
        "keywords": ["汗出不止", "恶风", "小便难", "四肢拘急", "附子"]
    },
    {
        "id": "guizhi_qu_shaoyao_jia_shuqi_longgu_muli_tang", "name": "桂枝去芍药加蜀漆龙骨牡蛎救逆汤", "alias": "救逆汤", "meridian": "太阳", "category": "镇惊安神剂",
        "components": [
            {"name": "桂枝", "dosage": "三两"}, {"name": "生姜", "dosage": "三两"}, {"name": "大枣", "dosage": "十二枚"},
            {"name": "蜀漆", "dosage": "三两", "role": "涌吐痰实"},
            {"name": "龙骨", "dosage": "四两", "role": "镇惊潜阳"},
            {"name": "牡蛎", "dosage": "五两", "role": "敛阴潜阳"},
            {"name": "炙甘草", "dosage": "二两"}
        ],
        "indication": "伤寒脉浮，以火灸劫之，亡阳必惊狂，卧起不安者。",
        "contraindication": "非火逆惊狂者不可用。",
        "dosage": "水一斗二升，先煮蜀漆减二升，内诸药，煮取三升，去滓，温服一升。",
        "explanation": "火灸后阳气浮散，心神浮越。去芍药之阴柔，加龙骨牡蛎潜镇心阳，蜀漆涌吐痰实。此为火逆救逆之方。",
        "keywords": ["惊狂", "卧起不安", "火逆", "亡阳", "龙骨", "牡蛎"]
    },
    {
        "id": "guizhi_jia_longgu_muli_tang", "name": "桂枝加龙骨牡蛎汤", "alias": "", "meridian": "太阳", "category": "调和营卫剂",
        "components": [
            {"name": "桂枝", "dosage": "三两"}, {"name": "芍药", "dosage": "三两"}, {"name": "生姜", "dosage": "三两"},
            {"name": "大枣", "dosage": "十二枚"}, {"name": "炙甘草", "dosage": "二两"},
            {"name": "龙骨", "dosage": "二两", "role": "镇惊潜阳"},
            {"name": "牡蛎", "dosage": "二两", "role": "敛阴潜阳"}
        ],
        "indication": "火逆下之，因烧针烦躁者。失精家，少腹弦急，阴头寒，目眩发落。",
        "contraindication": "无烦躁失精者慎用。",
        "dosage": "水七升，煮取三升，去滓，温服一升。",
        "explanation": "桂枝汤调和营卫，加龙骨牡蛎潜阳镇逆。治虚劳失精、目眩发落，脉极虚芤迟。阴阳两虚，虚阳浮越。",
        "keywords": ["烦躁", "失精", "目眩", "发落", "少腹弦急"]
    },
    {
        "id": "shaoyao_gancao_fuzi_tang", "name": "芍药甘草附子汤", "alias": "", "meridian": "太阳", "category": "温经缓急剂",
        "components": [
            {"name": "芍药", "dosage": "三两", "role": "柔肝缓急"},
            {"name": "炙甘草", "dosage": "二两", "role": "甘缓和中"},
            {"name": "炮附子", "dosage": "一枚", "role": "温经散寒"}
        ],
        "indication": "发汗，病不解，反恶寒者，虚故也。",
        "contraindication": "实证恶寒者不可用。",
        "dosage": "水五升，煮取一升五合，去滓，分温三服。",
        "explanation": "发汗后表虚恶寒，芍药甘草缓急止痛，附子温经散寒。此方治汗后阴阳两虚之恶寒。",
        "keywords": ["恶寒", "发汗后", "虚", "脚挛急"]
    },
    {
        "id": "guizhi_qu_guizhi_jia_fuling_baizhu_tang", "name": "桂枝去桂加茯苓白术汤", "alias": "", "meridian": "太阳", "category": "利水渗湿剂",
        "components": [
            {"name": "芍药", "dosage": "三两"}, {"name": "生姜", "dosage": "三两"}, {"name": "茯苓", "dosage": "三两", "role": "利水渗湿"},
            {"name": "白术", "dosage": "三两", "role": "健脾燥湿"},
            {"name": "大枣", "dosage": "十二枚"}, {"name": "炙甘草", "dosage": "二两"}
        ],
        "indication": "服桂枝汤，或下之，仍头项强痛，翕翕发热，无汗，心下满微痛，小便不利者。",
        "contraindication": "有汗恶风者不可去桂。",
        "dosage": "水八升，煮取三升，去滓，温服一升。小便利则愈。",
        "explanation": "头项强痛发热似桂枝证，但无汗+心下满+小便不利=水饮内停。去桂枝之发表，加茯苓白术利水健脾。服后小便利则愈。",
        "keywords": ["心下满", "小便不利", "无汗", "水饮", "茯苓", "白术"]
    },
    {
        "id": "mahuang_xi_xin_fuzi_tang", "name": "麻黄附子细辛汤", "alias": "太少两感第一方", "meridian": "少阴", "category": "助阳解表剂",
        "components": [
            {"name": "麻黄", "dosage": "二两", "role": "发汗解表"},
            {"name": "炮附子", "dosage": "一枚", "role": "温经助阳"},
            {"name": "细辛", "dosage": "二两", "role": "温经散寒，化饮"}
        ],
        "indication": "少阴病，始得之，反发热，脉沉者。",
        "contraindication": "少阴病久、阳气已衰者不可发汗。",
        "dosage": "水一斗，先煮麻黄减二升，去上沫，内诸药，煮取三升，去滓，温服一升，日三服。",
        "explanation": "少阴本不当发热，今反发热=太少两感。麻黄解表寒，附子温里阳，细辛温经化饮。三药合力，表里双解。",
        "keywords": ["少阴病", "发热", "脉沉", "太少两感", "细辛"]
    },
    {
        "id": "mahuang_fuzi_gancao_tang", "name": "麻黄附子甘草汤", "alias": "", "meridian": "少阴", "category": "助阳解表剂",
        "components": [
            {"name": "麻黄", "dosage": "二两", "role": "发汗解表"},
            {"name": "炮附子", "dosage": "一枚", "role": "温经助阳"},
            {"name": "炙甘草", "dosage": "二两", "role": "调和缓中"}
        ],
        "indication": "少阴病，得之二三日，麻黄附子甘草汤微发汗。以二三日无证，故微发汗也。",
        "contraindication": "少阴病得之二三日以上，心中烦不得卧者，不可用此方。",
        "dosage": "水七升，先煮麻黄一两沸，去上沫，内诸药，煮取三升，去滓，温服一升，日三服。",
        "explanation": "少阴病二三日，无里证（无吐利厥逆），故可微发汗。比麻黄附子细辛汤缓和，用甘草代细辛，发汗力减而和中力增。",
        "keywords": ["少阴病", "微发汗", "二三日", "无里证"]
    },
    {
        "id": "mahuang_xingren_shigao_gancao_tang", "name": "麻杏甘石汤", "alias": "麻黄杏仁石膏甘草汤", "meridian": "太阳/肺", "category": "清热平喘剂",
        "components": [
            {"name": "麻黄", "dosage": "四两", "role": "宣肺平喘"},
            {"name": "杏仁", "dosage": "五十个", "role": "降肺气"},
            {"name": "石膏", "dosage": "半斤", "role": "清肺热"},
            {"name": "炙甘草", "dosage": "二两", "role": "调和诸药"}
        ],
        "indication": "发汗后，不可更行桂枝汤。汗出而喘，无大热者。",
        "contraindication": "无汗而喘者不可用（当用麻黄汤）。",
        "dosage": "水七升，先煮麻黄减二升，去上沫，内诸药，煮取二升，去滓，温服一升。",
        "explanation": "汗出而喘=肺热壅盛。石膏清肺热，麻黄宣肺平喘（有石膏制之不至于发汗太过），杏仁降气，甘草调和。无大热=热在里不在表。",
        "keywords": ["汗出", "喘", "肺热", "无大热", "石膏"]
    },
    {
        "id": "guizhi_gancao_tang", "name": "桂枝甘草汤", "alias": "", "meridian": "太阳/心", "category": "温阳定悸剂",
        "components": [
            {"name": "桂枝", "dosage": "四两", "role": "壮心阳"},
            {"name": "炙甘草", "dosage": "二两", "role": "补中缓急"}
        ],
        "indication": "发汗过多，其人叉手自冒心，心下悸，欲得按者。",
        "contraindication": "阴虚火旺者不可用。",
        "dosage": "水三升，煮取一升，去滓，顿服。",
        "explanation": "发汗过多伤心阳，心悸叉手自冒心=虚证喜按。桂枝壮心阳，甘草补中缓急。仅两味药，力专效宏。",
        "keywords": ["心悸", "叉手自冒心", "发汗过多", "心阳虚"]
    },
    {
        "id": "linggui_zhugan_tang", "name": "苓桂术甘汤", "alias": "", "meridian": "太阳/脾", "category": "温阳化饮剂",
        "components": [
            {"name": "茯苓", "dosage": "四两", "role": "利水渗湿"},
            {"name": "桂枝", "dosage": "三两", "role": "温阳化气"},
            {"name": "白术", "dosage": "二两", "role": "健脾燥湿"},
            {"name": "炙甘草", "dosage": "二两", "role": "调和诸药"}
        ],
        "indication": "伤寒，若吐若下后，心下逆满，气上冲胸，起则头眩，脉沉紧。发汗则动经，身为振振摇者。",
        "contraindication": "阴虚津亏者慎用。",
        "dosage": "水六升，煮取三升，去滓，分温三服。",
        "explanation": "吐下后脾阳虚，水饮内停。茯苓利水，桂枝温阳化气，白术健脾燥湿，甘草调和。水饮上冲则头眩，为痰饮病之主方。",
        "keywords": ["心下逆满", "气上冲胸", "头眩", "水饮", "痰饮"]
    },
    {
        "id": "zhizhi_shanghou_zhishi_shipo_tang", "name": "栀子厚朴枳实汤", "alias": "", "meridian": "阳明", "category": "清热除烦剂",
        "components": [
            {"name": "栀子", "dosage": "十四个", "role": "清热除烦"},
            {"name": "厚朴", "dosage": "四两", "role": "行气除满"},
            {"name": "枳实", "dosage": "四枚", "role": "破气消积"}
        ],
        "indication": "伤寒下后，心烦腹满，卧起不安者。",
        "contraindication": "虚寒腹满者不可用。",
        "dosage": "水三升半，煮取一升半，去滓，分二服。温进一服。",
        "explanation": "下后余热留扰胸膈则心烦，气滞于腹则腹满。栀子清胸膈热，厚朴枳实行气除满。心烦+腹满+卧起不安三证并见。",
        "keywords": ["心烦", "腹满", "卧起不安", "下后"]
    },
    {
        "id": "zhizhi_ganjiang_chi_tang", "name": "栀子干姜豉汤", "alias": "", "meridian": "太阳/阳明", "category": "清热温中剂",
        "components": [
            {"name": "栀子", "dosage": "十四个", "role": "清热除烦"},
            {"name": "干姜", "dosage": "二两", "role": "温中散寒"},
            {"name": "豆豉", "dosage": "四合", "role": "宣透郁热"}
        ],
        "indication": "医以丸药大下之，身热不去，微烦者。",
        "contraindication": "无中寒者不可用干姜。",
        "dosage": "水三升半，煮取一升半，去滓，分二服。",
        "explanation": "大下后中焦虚寒（干姜温中），余热上扰胸膈（栀子除烦）。寒热并用之方，上清下温。",
        "keywords": ["身热不去", "微烦", "大下后", "寒热并用"]
    },
    {
        "id": "zhizhi_gancao_chi_tang", "name": "栀子甘草豉汤", "alias": "", "meridian": "太阳", "category": "清热除烦剂",
        "components": [
            {"name": "栀子", "dosage": "十四个", "role": "清热除烦"},
            {"name": "炙甘草", "dosage": "二两", "role": "益气和中"},
            {"name": "豆豉", "dosage": "四合", "role": "宣透郁热"}
        ],
        "indication": "发汗吐下后，虚烦不得眠，若剧者，必反复颠倒，心中懊憹。",
        "contraindication": "无虚烦者不可用。",
        "dosage": "水四升，先煮栀子甘草取二升半，内豉，煮取一升半，去滓，分二服。",
        "explanation": "发汗吐下后余热留扰胸膈，虚烦不得眠。栀子清热除烦，甘草益气和中，豆豉宣透郁热。心中懊憹=烦闷无可奈何。",
        "keywords": ["虚烦", "不得眠", "心中懊憹", "反复颠倒"]
    },
    {
        "id": "zhizhi_chi_tang", "name": "栀子豉汤", "alias": "", "meridian": "太阳/阳明", "category": "清热除烦剂",
        "components": [
            {"name": "栀子", "dosage": "十四个", "role": "清热除烦"},
            {"name": "豆豉", "dosage": "四合", "role": "宣透郁热"}
        ],
        "indication": "发汗吐下后，虚烦不得眠，心中懊憹。发汗若下之，而烦热胸中窒者。",
        "contraindication": "病人旧微溏者不可与。",
        "dosage": "水四升，先煮栀子得二升半，内豉，煮取一升半，去滓，分二服。",
        "explanation": "栀子清心中烦热，豆豉宣透上焦郁热。二药合用，清宣胸膈郁热，为除烦懊之祖方。虚烦=无形之热扰胸膈。",
        "keywords": ["虚烦", "懊憹", "胸中窒", "发汗吐下后"]
    },
    {
        "id": "houpo_shengjiang_banxia_gancao_ren_tang", "name": "厚朴生姜半夏甘草人参汤", "alias": "厚朴人参汤", "meridian": "太阴", "category": "行气除满剂",
        "components": [
            {"name": "厚朴", "dosage": "半斤", "role": "行气除满"},
            {"name": "生姜", "dosage": "半斤", "role": "温胃散寒"},
            {"name": "半夏", "dosage": "半升", "role": "降逆和胃"},
            {"name": "炙甘草", "dosage": "二两", "role": "补中和药"},
            {"name": "人参", "dosage": "一两", "role": "益气补中"}
        ],
        "indication": "发汗后，腹胀满者。",
        "contraindication": "实热腹胀者不可用。",
        "dosage": "水一斗，煮取三升，去滓，温服一升，日三服。",
        "explanation": "发汗后脾虚气滞，腹胀满。厚朴行气除满为主药，半夏生姜降逆和胃，人参甘草补中益气。消补兼施之法。",
        "keywords": ["腹胀满", "发汗后", "脾虚气滞"]
    },
    {
        "id": "xinjia_tang", "name": "新加汤", "alias": "桂枝新加汤", "meridian": "太阳", "category": "补气和营剂",
        "components": [
            {"name": "桂枝", "dosage": "三两"}, {"name": "芍药", "dosage": "四两"},
            {"name": "生姜", "dosage": "四两"}, {"name": "大枣", "dosage": "十二枚"},
            {"name": "炙甘草", "dosage": "二两"},
            {"name": "人参", "dosage": "三两", "role": "益气生津"}
        ],
        "indication": "发汗后，身疼痛，脉沉迟者。",
        "contraindication": "无身痛脉沉迟者不可用。",
        "dosage": "水一斗二升，煮取三升，去滓，温服一升。",
        "explanation": "发汗后气营两伤，身痛（血不足以养筋）+脉沉迟（里虚）。桂枝汤调和营卫，加人参益气生津，加重芍药生姜养血和营。",
        "keywords": ["身疼痛", "脉沉迟", "发汗后", "气营两伤"]
    },
    {
        "id": "gancao_ganjiang_tang", "name": "甘草干姜汤", "alias": "", "meridian": "太阴", "category": "温里剂",
        "components": [
            {"name": "炙甘草", "dosage": "四两", "role": "补中缓急"},
            {"name": "干姜", "dosage": "二两", "role": "温中散寒"}
        ],
        "indication": "伤寒脉浮，自汗出，小便数，心烦，微恶寒，脚挛急。厥逆，咽中干，烦躁，吐逆者。",
        "contraindication": "阴虚火旺者不可用。",
        "dosage": "水三升，煮取一升五合，去滓，分温再服。",
        "explanation": "误治后脾阳虚损，四肢厥冷，咽干烦躁。甘草干姜恢复脾阳，热就会传到肌肉上。为四逆汤之半，急救回阳之轻剂。",
        "keywords": ["厥逆", "咽中干", "烦躁", "吐逆", "脾阳虚"]
    },
    {
        "id": "shaoyao_gancao_tang", "name": "芍药甘草汤", "alias": "去杖汤", "meridian": "太阳/肝", "category": "柔肝缓急剂",
        "components": [
            {"name": "芍药", "dosage": "四两", "role": "柔肝缓急止痛"},
            {"name": "炙甘草", "dosage": "二两", "role": "甘缓和中"}
        ],
        "indication": "脚挛急（芍药甘草附子汤证之轻者）。平人可用治腿抽筋。",
        "contraindication": "无挛急者慎用。",
        "dosage": "水三升，煮取一升五合，去滓，分温再服。",
        "explanation": "芍药酸苦微寒，柔肝养血、缓急止痛；甘草甘温，补中缓急。二药合用，酸甘化阴、缓急止痛。又名去杖汤，服后脚伸可弃杖。倪师平常用芍药一两、甘草二两。",
        "keywords": ["脚挛急", "腿抽筋", "去杖汤", "柔肝"]
    },
    {
        "id": "tiaowei_chengqi_tang", "name": "调胃承气汤", "alias": "", "meridian": "阳明", "category": "缓下剂",
        "components": [
            {"name": "大黄", "dosage": "四两", "role": "攻下热结"},
            {"name": "炙甘草", "dosage": "二两", "role": "缓和药性"},
            {"name": "芒硝", "dosage": "半升", "role": "软坚润燥"}
        ],
        "indication": "阳明病，不吐不下，心烦者。太阳病三日，发汗不解，蒸蒸发热者。伤寒吐后，腹胀满者。",
        "contraindication": "脾胃虚寒者不可用。",
        "dosage": "水三升，煮取一升，去滓，内芒硝，更上火微煮令沸，少少温服之。",
        "explanation": "大黄去实热，芒硝软坚润燥，甘草缓和药性使药力留中。为承气汤中最缓者，取其调和胃气。少少温服=不用峻攻。",
        "keywords": ["心烦", "蒸蒸发热", "腹胀满", "缓下"]
    },
    {
        "id": "xiaochengqi_tang", "name": "小承气汤", "alias": "", "meridian": "阳明", "category": "轻下剂",
        "components": [
            {"name": "大黄", "dosage": "四两", "role": "攻下热结"},
            {"name": "厚朴", "dosage": "二两", "role": "行气除满"},
            {"name": "枳实", "dosage": "三枚", "role": "破气消积"}
        ],
        "indication": "阳明病，谵语发潮热，脉滑而疾者。大便硬者。",
        "contraindication": "气虚津亏者慎用。",
        "dosage": "水四升，煮取一升二合，去滓，分温二服。初服当更衣，不尔者尽饮之。",
        "explanation": "大黄攻下，厚朴行气，枳实破气。三药合力通腑泄热，为承气汤之轻剂。谵语+潮热+脉滑疾=阳明腑实初成。",
        "keywords": ["谵语", "潮热", "大便硬", "脉滑疾"]
    },
    {
        "id": "dachengqi_tang", "name": "大承气汤", "alias": "", "meridian": "阳明", "category": "峻下剂",
        "components": [
            {"name": "大黄", "dosage": "四两", "role": "攻下热结"},
            {"name": "厚朴", "dosage": "半斤", "role": "行气除满"},
            {"name": "枳实", "dosage": "五枚", "role": "破气消积"},
            {"name": "芒硝", "dosage": "三合", "role": "软坚润燥"}
        ],
        "indication": "阳明病，大便硬，腹满痛拒按，潮热谵语，手足濈然汗出。少阴病，口燥咽干，自利清水，色纯青。",
        "contraindication": "脉迟（胃气虚）或阳明病面赤（戴阳）者不可攻。津枯便秘者不可用。",
        "dosage": "水一斗，先煮二物取五升，去滓，内大黄，更煮取二升，去滓，内芒硝，更上微火一两沸，温再服。得下，余勿服。",
        "explanation": "厚朴倍大黄→气药为君，重在行气除满。大黄攻下热结，芒硝软坚润燥，厚朴枳实行气破结。为承气汤之最峻者。倪师：燥屎+痞+满+燥+实五证齐备方可。",
        "keywords": ["大便硬", "腹满痛", "潮热", "谵语", "燥屎", "承气"]
    },
    {
        "id": "taohua_tang", "name": "桃花汤", "alias": "", "meridian": "少阴", "category": "涩肠固脱剂",
        "components": [
            {"name": "赤石脂", "dosage": "一斤", "role": "涩肠固脱"},
            {"name": "干姜", "dosage": "一两", "role": "温中散寒"},
            {"name": "粳米", "dosage": "一升", "role": "养胃和中"}
        ],
        "indication": "少阴病，下利便脓血者。",
        "contraindication": "湿热痢疾初起不可用（涩则留邪）。",
        "dosage": "水七升，煮米令熟，去滓，温服七合，内赤石脂末方寸匕，日三服。若一服愈，余勿服。",
        "explanation": "少阴虚寒下利，大便脓血。赤石脂涩肠止血，干姜温中散寒，粳米养胃。赤石脂末冲服取其涩肠之专力。色如桃花故名。",
        "keywords": ["下利", "便脓血", "少阴", "涩肠"]
    },
    {
        "id": "wumeiwan", "name": "乌梅丸", "alias": "虫剂", "meridian": "厥阴", "category": "寒热并用剂",
        "components": [
            {"name": "乌梅", "dosage": "三百个", "role": "酸涩安蛔"},
            {"name": "细辛", "dosage": "六两", "role": "温脏散寒"},
            {"name": "干姜", "dosage": "十两", "role": "温中散寒"},
            {"name": "黄连", "dosage": "一斤", "role": "清热燥湿"},
            {"name": "当归", "dosage": "四两", "role": "养血和血"},
            {"name": "炮附子", "dosage": "六两", "role": "温脏祛寒"},
            {"name": "蜀椒", "dosage": "四两", "role": "温脏杀虫"},
            {"name": "桂枝", "dosage": "六两", "role": "通阳散寒"},
            {"name": "人参", "dosage": "六两", "role": "益气补中"},
            {"name": "黄柏", "dosage": "六两", "role": "清热燥湿"}
        ],
        "indication": "蛔厥（脏寒蛔上入膈），烦躁吐蚘。久利。寒热错杂证。",
        "contraindication": "纯寒或纯热者不宜。",
        "dosage": "十味异捣筛，合治之。以苦酒渍乌梅一宿，去核蒸之，捣成泥，和药令相得，内臼中，与蜜杵二千下，丸如梧桐子大。先食饮服十丸，日三服，稍加至二十丸。",
        "explanation": "厥阴寒热错杂，蛔虫闻酸则静、得辛则伏、得苦则泄。乌梅酸涩安蛔，连柏苦寒清热，姜附辛热温脏，参归补气养血。寒热并用、酸苦辛甘并投。倪师：不只治蛔厥，一切寒热错杂久利皆可用。",
        "keywords": ["蛔厥", "吐蚘", "久利", "寒热错杂", "厥阴"]
    },
    {
        "id": "dachaihu_tang", "name": "大柴胡汤", "alias": "", "meridian": "少阳/阳明", "category": "和解攻下剂",
        "components": [
            {"name": "柴胡", "dosage": "半斤", "role": "和解少阳"},
            {"name": "黄芩", "dosage": "三两", "role": "清热"},
            {"name": "芍药", "dosage": "三两", "role": "柔肝缓急"},
            {"name": "半夏", "dosage": "半升", "role": "降逆和胃"},
            {"name": "生姜", "dosage": "五两", "role": "和胃止呕"},
            {"name": "枳实", "dosage": "四枚", "role": "破气消积"},
            {"name": "大枣", "dosage": "十二枚"}, {"name": "大黄", "dosage": "二两", "role": "攻下热结"}
        ],
        "indication": "少阳阳明合病：呕不止，心下急，郁郁微烦者。心中痞硬，呕吐而下利者。",
        "contraindication": "纯少阳证（无阳明腑实）者不可用大黄。",
        "dosage": "水一斗二升，煮取六升，去滓，再煎，温服一升，日三服。",
        "explanation": "小柴胡去人参甘草（因有实邪不宜补）+小承气去芒硝（不用峻攻）=和解少阳兼通腑实。心下急+郁郁微烦=少阳阳明并病。",
        "keywords": ["呕不止", "心下急", "郁郁微烦", "少阳阳明"]
    },
    {
        "id": "chaihu_jia_mangxiao_tang", "name": "柴胡加芒硝汤", "alias": "", "meridian": "少阳/阳明", "category": "和解攻下剂",
        "components": [
            {"name": "柴胡", "dosage": "二两十六铢"}, {"name": "黄芩", "dosage": "一两"},
            {"name": "人参", "dosage": "一两"}, {"name": "半夏", "dosage": "五枚"},
            {"name": "炙甘草", "dosage": "一两"}, {"name": "生姜", "dosage": "一两"},
            {"name": "大枣", "dosage": "四枚"},
            {"name": "芒硝", "dosage": "二两", "role": "软坚润燥"}
        ],
        "indication": "伤寒十三日不解，胸胁满而呕，日晡所发潮热，已而微利。此本柴胡证，下之以不得利，今反利者，知医以丸药下之，非其治也。潮热者，实也。",
        "contraindication": "无潮热者不可用芒硝。",
        "dosage": "水四升，煮取二升，去滓，内芒硝，更煮微沸，分温再服。不解更作。",
        "explanation": "柴胡证兼潮热（阳明实热），先误用丸药攻下导致微利。小柴胡汤加芒硝软坚润燥，不用大黄枳实（因已误下正气伤）。和解为主，兼下里实。",
        "keywords": ["胸胁满", "潮热", "微利", "丸药误下"]
    },
    {
        "id": "chaihu_jia_longgu_muli_tang", "name": "柴胡加龙骨牡蛎汤", "alias": "", "meridian": "少阳", "category": "和解潜阳剂",
        "components": [
            {"name": "柴胡", "dosage": "四两"}, {"name": "黄芩", "dosage": "一两半"},
            {"name": "人参", "dosage": "一两半"}, {"name": "半夏", "dosage": "二合半"},
            {"name": "生姜", "dosage": "一两半"}, {"name": "大枣", "dosage": "六枚"},
            {"name": "茯苓", "dosage": "一两半", "role": "利水宁心"},
            {"name": "大黄", "dosage": "二两", "role": "泻热和胃"},
            {"name": "龙骨", "dosage": "一两半", "role": "镇惊安神"},
            {"name": "牡蛎", "dosage": "一两半", "role": "敛阴潜阳"},
            {"name": "铅丹", "dosage": "一两半", "role": "镇惊坠痰"},
            {"name": "桂枝", "dosage": "一两半", "role": "通阳化气"}
        ],
        "indication": "伤寒八九日，下之，胸满烦惊，小便不利，谵语，一身尽重，不可转侧者。",
        "contraindication": "非柴胡证误下者慎用。",
        "dosage": "水八升，煮取四升，内大黄切如棋子，更煮一两沸，去滓，温服一升。",
        "explanation": "误下后少阳之邪弥漫三焦。柴胡和解少阳，龙骨牡蛎铅丹镇惊潜阳，茯苓利水宁心，大黄泻热和胃，桂枝通阳。烦惊谵语=邪扰心神。铅丹现多以磁石或生铁落代替。",
        "keywords": ["胸满烦惊", "谵语", "小便不利", "不可转侧"]
    },
    {
        "id": "chaihu_guizhi_tang", "name": "柴胡桂枝汤", "alias": "", "meridian": "少阳/太阳", "category": "和解表里剂",
        "components": [
            {"name": "桂枝", "dosage": "一两半"}, {"name": "芍药", "dosage": "一两半"},
            {"name": "黄芩", "dosage": "一两半"}, {"name": "人参", "dosage": "一两半"},
            {"name": "炙甘草", "dosage": "一两"}, {"name": "半夏", "dosage": "二合半"},
            {"name": "柴胡", "dosage": "四两"}, {"name": "生姜", "dosage": "一两半"},
            {"name": "大枣", "dosage": "六枚"}
        ],
        "indication": "伤寒六七日，发热，微恶寒，支节烦疼，微呕，心下支结，外证未去者。",
        "contraindication": "纯里证者不可用。",
        "dosage": "水七升，煮取三升，去滓，温服一升。",
        "explanation": "太阳少阳合病。发热恶寒支节烦疼=太阳表证未解；微呕心下支结=少阳证已见。桂枝汤+小柴胡汤各半量，太少双解。",
        "keywords": ["发热", "微恶寒", "微呕", "心下支结", "太少合病"]
    },
    {
        "id": "chaihu_guizhi_ganjiang_tang", "name": "柴胡桂枝干姜汤", "alias": "", "meridian": "少阳/太阴", "category": "和解温里剂",
        "components": [
            {"name": "柴胡", "dosage": "半斤"}, {"name": "桂枝", "dosage": "三两"},
            {"name": "干姜", "dosage": "二两", "role": "温中散寒"},
            {"name": "栝蒌根", "dosage": "四两", "role": "生津止渴"},
            {"name": "黄芩", "dosage": "三两", "role": "清热"},
            {"name": "牡蛎", "dosage": "二两", "role": "软坚散结"},
            {"name": "炙甘草", "dosage": "二两"}
        ],
        "indication": "伤寒五六日，已发汗而复下之，胸胁满微结，小便不利，渴而不呕，但头汗出，往来寒热，心烦者。",
        "contraindication": "无上热下寒者不可用。",
        "dosage": "水一斗二升，煮取六升，去滓，再煎取三升，温服一升，日三服。",
        "explanation": "少阳证+太阴脾寒。胸胁满微结往来寒热=少阳；渴而小便不利=水饮；干姜温脾寒，栝蒌根生津止渴。寒热并用，和解少阳兼温太阴。倪师常用此方治肝胆疾病兼脾虚者。",
        "keywords": ["胸胁满", "往来寒热", "渴而不呕", "但头汗出", "小便不利"]
    },
    {
        "id": "guizhi_tang_jia_fuzi_tang", "name": "桂枝附子汤", "alias": "", "meridian": "太阳/少阴", "category": "温经散寒剂",
        "components": [
            {"name": "桂枝", "dosage": "四两", "role": "温经通阳"},
            {"name": "炮附子", "dosage": "三枚", "role": "温里散寒"},
            {"name": "生姜", "dosage": "三两"}, {"name": "大枣", "dosage": "十二枚"},
            {"name": "炙甘草", "dosage": "二两"}
        ],
        "indication": "伤寒八九日，风湿相搏，身体疼烦，不能自转侧，不呕不渴，脉浮虚而涩者。",
        "contraindication": "有热者不可用。",
        "dosage": "水六升，煮取二升，去滓，分温三服。",
        "explanation": "风湿在表，身体疼烦不能自转侧。桂枝通阳，重用附子三枚温里散寒止痛。不呕不渴=无里热。脉浮虚而涩=风湿在表兼虚。",
        "keywords": ["身体疼烦", "不能自转侧", "风湿", "附子"]
    },
    {
        "id": "gancao_fuzi_tang", "name": "甘草附子汤", "alias": "", "meridian": "太阳/少阴", "category": "温经散寒剂",
        "components": [
            {"name": "炙甘草", "dosage": "二两", "role": "缓急止痛"},
            {"name": "炮附子", "dosage": "二枚", "role": "温里散寒"},
            {"name": "白术", "dosage": "二两", "role": "健脾燥湿"},
            {"name": "桂枝", "dosage": "四两", "role": "温经通阳"}
        ],
        "indication": "风湿相搏，骨节疼烦，掣痛不得屈伸，近之则痛剧，汗出短气，小便不利，恶风不欲去衣，或身微肿者。",
        "contraindication": "无风湿者不可用。",
        "dosage": "水六升，煮取三升，去滓，温服一升，日三服。初服得微汗则解。",
        "explanation": "风湿深入关节，骨节疼烦掣痛不得屈伸。附子温里散寒止痛，桂枝通阳化湿，白术健脾燥湿，甘草缓急。比桂枝附子汤祛风湿力量更强。",
        "keywords": ["骨节疼烦", "掣痛", "不得屈伸", "风湿", "汗出短气"]
    },
    {
        "id": "baizhu_fuzi_tang", "name": "白术附子汤", "alias": "", "meridian": "太阳/太阴", "category": "祛风湿剂",
        "components": [
            {"name": "白术", "dosage": "二两", "role": "健脾燥湿"},
            {"name": "炮附子", "dosage": "一枚半", "role": "温里散寒"},
            {"name": "桂枝", "dosage": "四两", "role": "温经通阳"},
            {"name": "生姜", "dosage": "三两"}, {"name": "大枣", "dosage": "六枚"},
            {"name": "炙甘草", "dosage": "三两"}
        ],
        "indication": "伤寒八九日，风湿相搏，身体疼烦，不能自转侧，不呕不渴，脉浮虚而涩者。",
        "contraindication": "有热者慎用。",
        "dosage": "水六升，煮取二升，去滓，分温三服。一服觉身痹，半日许再服，三服都尽，其人如冒状，勿怪。",
        "explanation": "与桂枝附子汤相比，附子减量、加白术→偏于健脾祛湿。服后身痹、如冒状=药力驱风湿外出之反应，不必惊慌。",
        "keywords": ["身体疼烦", "不能自转侧", "身痹", "如冒状"]
    },
    {
        "id": "xiaochaihu_tang", "name": "小柴胡汤", "alias": "和解第一方", "meridian": "少阳", "category": "和解剂",
        "components": [
            {"name": "柴胡", "dosage": "半斤", "role": "和解少阳"},
            {"name": "黄芩", "dosage": "三两", "role": "清热"},
            {"name": "人参", "dosage": "三两", "role": "益气扶正"},
            {"name": "半夏", "dosage": "半升", "role": "降逆和胃"},
            {"name": "生姜", "dosage": "三两", "role": "和胃止呕"},
            {"name": "大枣", "dosage": "十二枚", "role": "补脾和营"},
            {"name": "炙甘草", "dosage": "三两", "role": "调和诸药"}
        ],
        "indication": "少阳病：口苦，咽干，目眩，往来寒热，胸胁苦满，默默不欲饮食，心烦喜呕。但见一证便是，不必悉具。",
        "contraindication": "阳明里实者不可单用（需加大黄）。阴虚者慎用柴胡劫肝阴。",
        "dosage": "水一斗二升，煮取六升，去滓，再煎取三升，温服一升，日三服。",
        "explanation": "柴胡和解少阳，黄芩清热，半夏生姜降逆止呕，人参甘草大枣补中扶正。和解剂需去滓再煎取其和合之性。倪师：但见一证便是，不必悉具——四大主证有一个即可用。",
        "keywords": ["口苦", "咽干", "目眩", "往来寒热", "胸胁苦满", "喜呕", "少阳"]
    },
    {
        "id": "gegen_tang", "name": "葛根汤", "alias": "", "meridian": "太阳/阳明", "category": "解表剂",
        "components": [
            {"name": "葛根", "dosage": "四两", "role": "升津舒经"},
            {"name": "麻黄", "dosage": "三两", "role": "发汗解表"},
            {"name": "桂枝", "dosage": "二两", "role": "温经散寒"},
            {"name": "生姜", "dosage": "三两"}, {"name": "芍药", "dosage": "二两"},
            {"name": "大枣", "dosage": "十二枚"}, {"name": "炙甘草", "dosage": "二两"}
        ],
        "indication": "太阳病，项背强几几，无汗恶风者。太阳阳明合病自下利者。",
        "contraindication": "有汗者不可用（当用桂枝加葛根汤）。",
        "dosage": "水一斗，先煮麻黄葛根减二升，去白沫，内诸药，煮取三升，去滓，温服一升。覆取微似汗。",
        "explanation": "无汗恶风+项背强几几=太阳表实兼经输不利。葛根升津液舒经脉，麻黄桂枝发汗解表。无汗用葛根汤，有汗用桂枝加葛根汤。",
        "keywords": ["项背强", "无汗", "恶风", "下利", "葛根"]
    },
    {
        "id": "gegen_jia_banxia_tang", "name": "葛根加半夏汤", "alias": "", "meridian": "太阳/阳明", "category": "解表降逆剂",
        "components": [
            {"name": "葛根", "dosage": "四两"}, {"name": "麻黄", "dosage": "三两"}, {"name": "桂枝", "dosage": "二两"},
            {"name": "生姜", "dosage": "三两"}, {"name": "芍药", "dosage": "二两"},
            {"name": "大枣", "dosage": "十二枚"}, {"name": "炙甘草", "dosage": "二两"},
            {"name": "半夏", "dosage": "半升", "role": "降逆止呕"}
        ],
        "indication": "太阳阳明合病，不下利但呕者。",
        "contraindication": "无呕者不用半夏。",
        "dosage": "水一斗，先煮葛根麻黄减二升，去白沫，内诸药，煮取三升，去滓，温服一升。覆取微似汗。",
        "explanation": "葛根汤证兼呕。葛根汤解表止利，加半夏降逆止呕。下利者用葛根汤，呕者加半夏。",
        "keywords": ["呕", "不下利", "太阳阳明合病"]
    },
    {
        "id": "gegen_qinlian_tang", "name": "葛根黄芩黄连汤", "alias": "葛芩连汤", "meridian": "阳明", "category": "清热止利剂",
        "components": [
            {"name": "葛根", "dosage": "半斤", "role": "升清止利"},
            {"name": "黄芩", "dosage": "三两", "role": "清热燥湿"},
            {"name": "黄连", "dosage": "三两", "role": "清热燥湿"},
            {"name": "炙甘草", "dosage": "二两", "role": "调和诸药"}
        ],
        "indication": "太阳病，桂枝证，医反下之，利遂不止，脉促者，表未解也。喘而汗出者。",
        "contraindication": "虚寒下利者不可用。",
        "dosage": "水八升，先煮葛根减二升，内诸药，煮取二升，去滓，分温再服。",
        "explanation": "误下后表热内陷，协热下利。葛根升清止利兼解表，芩连清热燥湿止利。脉促=阳气尚盛，表邪未解。喘而汗出=里热壅盛。倪师：此方治热利（大便臭、肛门灼热）。",
        "keywords": ["下利不止", "脉促", "喘而汗出", "热利", "协热下利"]
    },
    {
        "id": "baihu_tang", "name": "白虎汤", "alias": "", "meridian": "阳明", "category": "清热生津剂",
        "components": [
            {"name": "知母", "dosage": "六两", "role": "清热除烦生津"},
            {"name": "石膏", "dosage": "一斤", "role": "清肺胃热"},
            {"name": "炙甘草", "dosage": "二两", "role": "益气和中"},
            {"name": "粳米", "dosage": "六合", "role": "养胃生津"}
        ],
        "indication": "阳明经证：身热，汗出，口渴，脉洪大。三阳合病，腹满身重，难以转侧，口不仁面垢，谵语遗尿。",
        "contraindication": "脉浮弦而细者不可与。不渴者不可与。汗不出者不可与。",
        "dosage": "水一斗，煮米熟汤成，去滓，温服一升，日三服。",
        "explanation": "石膏清肺胃实热（大热），知母清热除烦生津（大渴），粳米甘草养胃护中。四大证：大热、大汗、大渴、脉洪大。石膏必须重用至少一两以上。",
        "keywords": ["大热", "大汗", "大渴", "脉洪大", "阳明经证"]
    },
    {
        "id": "baihu_jia_renshen_tang", "name": "白虎加人参汤", "alias": "", "meridian": "阳明", "category": "清热生津剂",
        "components": [
            {"name": "知母", "dosage": "六两"}, {"name": "石膏", "dosage": "一斤"},
            {"name": "炙甘草", "dosage": "二两"}, {"name": "粳米", "dosage": "六合"},
            {"name": "人参", "dosage": "三两", "role": "益气生津"}
        ],
        "indication": "白虎汤证兼气阴两伤：口燥渴，舌上干燥，大烦渴不解，脉洪大。汗大出后，大烦渴不解。",
        "contraindication": "无气虚者不必加人参。",
        "dosage": "水一斗，煮米熟汤成，去滓，温服一升，日三服。",
        "explanation": "白虎汤加人参，治阳明热盛气阴两伤。石膏知母清热，人参益气生津。倪师：桂枝汤证转白虎加人参汤证=发汗太过伤津。",
        "keywords": ["大烦渴", "口燥渴", "舌上干燥", "气阴两伤"]
    },
    {
        "id": "zhizhi_shanghou_zhishi_tang", "name": "栀子枳实汤", "alias": "", "meridian": "阳明", "category": "清热除烦剂",
        "components": [
            {"name": "栀子", "dosage": "十四个", "role": "清热除烦"},
            {"name": "枳实", "dosage": "四枚", "role": "破气消积"}
        ],
        "indication": "伤寒，大下后，身热不去，心中结痛者。",
        "contraindication": "虚寒者不可用。",
        "dosage": "水三升半，煮取一升半，去滓，分二服。",
        "explanation": "大下后余热留扰胸膈，心中结痛。栀子清热除烦，枳实破气消结。较栀子豉汤多行气之力。",
        "keywords": ["身热不去", "心中结痛", "大下后"]
    },
    {
        "id": "huangqin_tang", "name": "黄芩汤", "alias": "", "meridian": "少阳/阳明", "category": "清热止利剂",
        "components": [
            {"name": "黄芩", "dosage": "二两", "role": "清热燥湿"},
            {"name": "芍药", "dosage": "二两", "role": "柔肝缓急"},
            {"name": "炙甘草", "dosage": "二两", "role": "调和诸药"},
            {"name": "大枣", "dosage": "十二枚", "role": "补脾和营"}
        ],
        "indication": "太阳与少阳合病，自下利者。",
        "contraindication": "虚寒下利者不可用。",
        "dosage": "水一斗，煮取三升，去滓，温服一升，日再夜一服。",
        "explanation": "太少合病下利，热利。黄芩清少阳阳明之热，芍药缓急止腹痛，甘草大枣和中。为治热利之祖方。",
        "keywords": ["下利", "腹痛", "热利", "太少合病"]
    },
    {
        "id": "huangqin_jia_banxia_shengjiang_tang", "name": "黄芩加半夏生姜汤", "alias": "", "meridian": "少阳/阳明", "category": "清热降逆剂",
        "components": [
            {"name": "黄芩", "dosage": "三两"}, {"name": "芍药", "dosage": "二两"},
            {"name": "炙甘草", "dosage": "二两"}, {"name": "大枣", "dosage": "十二枚"},
            {"name": "半夏", "dosage": "半升", "role": "降逆止呕"},
            {"name": "生姜", "dosage": "三两", "role": "和胃止呕"}
        ],
        "indication": "太阳与少阳合病，自下利者，兼呕。",
        "contraindication": "虚寒下利呕吐者不可用。",
        "dosage": "水一斗，煮取三升，去滓，温服一升，日再夜一服。",
        "explanation": "黄芩汤证兼呕，加半夏生姜降逆止呕。热利兼呕者用此方。",
        "keywords": ["下利", "呕", "热利"]
    },
    {
        "id": "huanglian_tang", "name": "黄连汤", "alias": "", "meridian": "太阳/太阴", "category": "寒热并用剂",
        "components": [
            {"name": "黄连", "dosage": "三两", "role": "清上热"},
            {"name": "炙甘草", "dosage": "三两", "role": "调和诸药"},
            {"name": "干姜", "dosage": "三两", "role": "温下寒"},
            {"name": "桂枝", "dosage": "三两", "role": "通阳散寒"},
            {"name": "人参", "dosage": "二两", "role": "益气补中"},
            {"name": "半夏", "dosage": "半升", "role": "降逆和胃"},
            {"name": "大枣", "dosage": "十二枚"}
        ],
        "indication": "伤寒，胸中有热，胃中有邪气，腹中痛，欲呕吐者。",
        "contraindication": "无上热下寒者不可用。",
        "dosage": "水一斗，煮取六升，去滓，温服，昼三夜二服。",
        "explanation": "上热（胸中有热欲呕吐）+下寒（胃中邪气腹中痛）=寒热分居上下。黄连清上热，干姜温下寒，桂枝通阳，半夏降逆，参枣补中。寒热并用、上下分治。",
        "keywords": ["腹中痛", "欲呕吐", "胸中有热", "上热下寒"]
    },
    {
        "id": "huanglian_ejiao_tang", "name": "黄连阿胶汤", "alias": "", "meridian": "少阴", "category": "滋阴清热剂",
        "components": [
            {"name": "黄连", "dosage": "四两", "role": "清心火"},
            {"name": "黄芩", "dosage": "二两", "role": "清热"},
            {"name": "芍药", "dosage": "二两", "role": "敛阴和营"},
            {"name": "阿胶", "dosage": "三两", "role": "滋阴养血"},
            {"name": "鸡子黄", "dosage": "二枚", "role": "滋阴润燥"}
        ],
        "indication": "少阴病，得之二三日以上，心中烦，不得卧。",
        "contraindication": "阳虚者不可用（此为阴虚火旺之方）。",
        "dosage": "水六升，先煮三物取二升，去滓，内胶烊尽，小冷，内鸡子黄，搅令相得，温服七合，日三服。",
        "explanation": "少阴热化证：心肾阴虚，心火亢盛。黄连黄芩清心火，阿胶鸡子黄芍药滋阴养血。心中烦+不得卧=阴虚火旺，心神不宁。倪师：此方治失眠属阴虚火旺者。鸡子黄须后下搅匀。",
        "keywords": ["心中烦", "不得卧", "少阴", "阴虚火旺", "失眠"]
    },
    {
        "id": "zhigancao_tang", "name": "炙甘草汤", "alias": "复脉汤", "meridian": "太阳/心", "category": "益气养血剂",
        "components": [
            {"name": "炙甘草", "dosage": "四两", "role": "益气复脉"},
            {"name": "生姜", "dosage": "三两"}, {"name": "人参", "dosage": "二两", "role": "益气"},
            {"name": "生地黄", "dosage": "一斤", "role": "滋阴养血"},
            {"name": "桂枝", "dosage": "三两", "role": "通阳"},
            {"name": "阿胶", "dosage": "二两", "role": "滋阴养血"},
            {"name": "麦门冬", "dosage": "半升", "role": "养阴生津"},
            {"name": "麻仁", "dosage": "半升", "role": "润燥"},
            {"name": "大枣", "dosage": "三十枚"}
        ],
        "indication": "伤寒脉结代，心动悸。",
        "contraindication": "痰饮阻滞者慎用。",
        "dosage": "水八升，清酒七升，先煮八味取三升，去滓，内胶烊尽，温服一升，日三服。",
        "explanation": "气血两虚，心脉失养。炙甘草益气复脉为主药，生地阿胶麦冬滋阴养血，桂枝通阳化气。清酒煎煮取其通血脉。脉结代=气血不足，脉来间歇。又名复脉汤。",
        "keywords": ["脉结代", "心动悸", "气血两虚", "复脉"]
    },
    {
        "id": "xiaojianzhong_tang", "name": "小建中汤", "alias": "", "meridian": "太阴", "category": "温中补虚剂",
        "components": [
            {"name": "桂枝", "dosage": "三两"}, {"name": "芍药", "dosage": "六两", "role": "柔肝缓急"},
            {"name": "生姜", "dosage": "三两"}, {"name": "大枣", "dosage": "十二枚"},
            {"name": "炙甘草", "dosage": "二两"},
            {"name": "饴糖", "dosage": "一升", "role": "温中补虚，缓急止痛"}
        ],
        "indication": "伤寒二三日，心中悸而烦者。虚劳里急，腹中痛，梦失精，四肢酸疼，手足烦热，咽干口燥。",
        "contraindication": "实热腹痛者不可用。",
        "dosage": "水七升，煮取三升，去滓，内饴糖，更上微火消解，温服一升，日三服。",
        "explanation": "饴糖为君药，温中补虚、缓急止痛。重用芍药六两柔肝缓急。桂枝汤变方（芍药加重+饴糖）。倪师：此方补脾力量大于桂枝汤，治脾虚腹痛、虚劳里急。",
        "keywords": ["心中悸", "腹中痛", "虚劳", "里急", "饴糖"]
    },
    {
        "id": "ligzhong_tang", "name": "理中汤", "alias": "理中丸", "meridian": "太阴", "category": "温中散寒剂",
        "components": [
            {"name": "人参", "dosage": "三两", "role": "益气补中"},
            {"name": "干姜", "dosage": "三两", "role": "温中散寒"},
            {"name": "白术", "dosage": "三两", "role": "健脾燥湿"},
            {"name": "炙甘草", "dosage": "三两", "role": "调和诸药"}
        ],
        "indication": "太阴病：腹满而吐，食不下，自利益甚，时腹自痛。霍乱头痛发热，身疼痛，寒多不用水者。",
        "contraindication": "湿热下利者不可用。",
        "dosage": "水八升，煮取三升，去滓，温服一升，日三服。丸法：蜜丸如鸡子黄许大，沸汤和丸，日三四，夜二服。腹中未热，益至三四丸。",
        "explanation": "人参补气，干姜温中散寒，白术健脾燥湿，甘草调和。四药温中健脾，为太阴病主方。倪师：上吐下泻+腹痛=理中汤；若四肢厥逆=四逆汤。",
        "keywords": ["腹满", "吐", "食不下", "自利", "太阴", "腹痛"]
    },
    {
        "id": "sini_tang", "name": "四逆汤", "alias": "回阳救逆第一方", "meridian": "少阴", "category": "回阳救逆剂",
        "components": [
            {"name": "生附子", "dosage": "一枚", "role": "回阳救逆"},
            {"name": "干姜", "dosage": "一两半", "role": "温中散寒"},
            {"name": "炙甘草", "dosage": "二两", "role": "缓和药性，护中"}
        ],
        "indication": "少阴病：脉微细，但欲寐，四肢厥逆，下利清谷。误汗亡阳。大汗出，热不去，内拘急，四肢疼，又下利厥逆而恶寒者。",
        "contraindication": "真热假寒者不可用（阳明大热证不可用）。",
        "dosage": "水三升，煮取一升二合，去滓，分温再服。强人可大附子一枚、干姜三两。",
        "explanation": "生附子回阳救逆为君，干姜温中助阳，甘草缓和药性。三药回阳救逆，治少阴寒化证之重者。倪师：生附子+干姜温中回阳力量最强。附子无干姜不热。脉微细+但欲寐+四肢厥逆=四逆汤证。",
        "keywords": ["四肢厥逆", "脉微细", "但欲寐", "下利清谷", "回阳救逆"]
    },
    {
        "id": "sini_jia_renshen_tang", "name": "四逆加人参汤", "alias": "", "meridian": "少阴", "category": "回阳救逆剂",
        "components": [
            {"name": "生附子", "dosage": "一枚"}, {"name": "干姜", "dosage": "一两半"},
            {"name": "炙甘草", "dosage": "二两"},
            {"name": "人参", "dosage": "一两", "role": "益气固脱"}
        ],
        "indication": "霍乱，吐利止而身痛不休者。恶寒脉微而复利，利止亡血也。",
        "contraindication": "无气虚者不必加人参。",
        "dosage": "水三升，煮取一升二合，去滓，分温再服。",
        "explanation": "四逆汤加人参，治阳虚兼气脱。吐利止=中阳已回，身痛不休=表邪未解。利止亡血=津血亏虚，人参益气固脱生津。",
        "keywords": ["吐利", "恶寒", "脉微", "亡血", "气脱"]
    },
    {
        "id": "tongmai_sini_tang", "name": "通脉四逆汤", "alias": "", "meridian": "少阴", "category": "回阳救逆剂",
        "components": [
            {"name": "生附子", "dosage": "大者一枚", "role": "回阳救逆"},
            {"name": "干姜", "dosage": "三两", "role": "温中散寒"},
            {"name": "炙甘草", "dosage": "二两", "role": "调和诸药"}
        ],
        "indication": "少阴病，下利清谷，里寒外热，手足厥逆，脉微欲绝，身反不恶寒，其人面色赤，或腹痛，或干呕，或咽痛，或利止脉不出者。",
        "contraindication": "真热假寒者禁用。",
        "dosage": "水三升，煮取一升二合，去滓，分温再服。其脉即出者愈。面赤者加葱九茎。",
        "explanation": "比四逆汤重用干姜（三两vs一两半），附子用大者。里寒外热=真寒假热，阴盛格阳。面赤=戴阳（虚阳上浮）。重剂回阳，通达内外阳气。",
        "keywords": ["下利清谷", "里寒外热", "脉微欲绝", "面色赤", "戴阳"]
    },
    {
        "id": "tongmai_sini_jia_zhuzhizhi_tang", "name": "通脉四逆加猪胆汁汤", "alias": "", "meridian": "少阴", "category": "回阳救逆剂",
        "components": [
            {"name": "生附子", "dosage": "大者一枚"}, {"name": "干姜", "dosage": "三两"},
            {"name": "炙甘草", "dosage": "二两"},
            {"name": "猪胆汁", "dosage": "半合", "role": "反佐，引阳入阴"}
        ],
        "indication": "吐已下断，汗出而厥，四肢拘急不解，脉微欲绝者。",
        "contraindication": "无格拒者不用猪胆汁。",
        "dosage": "水三升，煮取一升二合，去滓，内猪胆汁，分温再服。无猪胆以羊胆代之。",
        "explanation": "通脉四逆汤证兼阴液大伤。吐下已止但汗出厥逆脉微=阳气将脱。猪胆汁咸寒反佐，引阳药入阴，防格拒。倪师：阴盛格阳严重时用此方。",
        "keywords": ["吐已下断", "汗出而厥", "脉微欲绝", "格拒"]
    },
    {
        "id": "sisi_san", "name": "四逆散", "alias": "", "meridian": "少阳/少阴", "category": "疏肝理气剂",
        "components": [
            {"name": "柴胡", "dosage": "十分", "role": "疏肝解郁"},
            {"name": "芍药", "dosage": "十分", "role": "柔肝缓急"},
            {"name": "枳实", "dosage": "十分", "role": "破气消积"},
            {"name": "炙甘草", "dosage": "十分", "role": "调和诸药"}
        ],
        "indication": "少阴病，四逆（手足不温），或咳，或悸，或小便不利，或腹中痛，或泄利下重者。",
        "contraindication": "阳虚寒厥者不可用（此为气郁所致四逆）。",
        "dosage": "四味各十分，捣筛，白饮和服方寸匕，日三服。咳者加五味子、干姜；悸者加桂枝；小便不利加茯苓；腹中痛加附子；泄利下重加薤白。",
        "explanation": "此方虽名四逆散，实治少阳气郁致厥（阳郁不伸非阳虚）。柴胡疏肝，枳实破气，芍药柔肝，甘草调和。倪师：四逆散+加减法=治肝气郁结之多种变证。",
        "keywords": ["四逆", "手足不温", "腹中痛", "泄利下重", "气郁"]
    },
    {
        "id": "zhenwu_tang", "name": "真武汤", "alias": "", "meridian": "少阴", "category": "温阳利水剂",
        "components": [
            {"name": "茯苓", "dosage": "三两", "role": "利水渗湿"},
            {"name": "芍药", "dosage": "三两", "role": "柔肝利水"},
            {"name": "生姜", "dosage": "三两", "role": "温胃散寒"},
            {"name": "白术", "dosage": "二两", "role": "健脾燥湿"},
            {"name": "炮附子", "dosage": "一枚", "role": "温阳化气"}
        ],
        "indication": "少阴病，二三日不已，至四五日，腹痛，小便不利，四肢沉重疼痛，自下利者，此为有水气。其人或咳，或小便利，或下利，或呕者。",
        "contraindication": "阴虚水热互结者慎用。",
        "dosage": "水八升，煮取三升，去滓，温服七合，日三服。",
        "explanation": "少阴阳虚水泛。附子温阳化气，茯苓白术利水健脾，生姜温散水气，芍药利水缓急。腹痛+小便不利+四肢沉重=阳虚水停。倪师：此方治阳虚水肿、心衰水肿。",
        "keywords": ["小便不利", "四肢沉重", "腹痛", "水气", "阳虚水肿"]
    },
    {
        "id": "fuzi_tang", "name": "附子汤", "alias": "", "meridian": "少阴", "category": "温经散寒剂",
        "components": [
            {"name": "炮附子", "dosage": "二枚", "role": "温经散寒"},
            {"name": "茯苓", "dosage": "三两", "role": "利水渗湿"},
            {"name": "人参", "dosage": "二两", "role": "益气"},
            {"name": "白术", "dosage": "四两", "role": "健脾燥湿"},
            {"name": "芍药", "dosage": "三两", "role": "柔肝缓急"}
        ],
        "indication": "少阴病，得之一二日，口中和，其背恶寒者，当灸之。少阴病，身体痛，手足寒，骨节痛，脉沉者。",
        "contraindication": "阴虚内热者不可用。",
        "dosage": "水八升，煮取三升，去滓，温服一升，日三服。",
        "explanation": "少阴阳虚寒湿。口中和=无热证，背恶寒=阳虚。身体痛+骨节痛+手足寒+脉沉=阳虚寒湿凝滞。重用附子温阳散寒，参术补气健脾，茯苓利水，芍药缓急。",
        "keywords": ["背恶寒", "身体痛", "骨节痛", "手足寒", "脉沉"]
    },
    {
        "id": "wuzhuyu_tang", "name": "吴茱萸汤", "alias": "", "meridian": "厥阴/阳明", "category": "温中降逆剂",
        "components": [
            {"name": "吴茱萸", "dosage": "一升", "role": "温中降逆"},
            {"name": "人参", "dosage": "二两", "role": "益气补中"},
            {"name": "生姜", "dosage": "六两", "role": "和胃止呕"},
            {"name": "大枣", "dosage": "十二枚", "role": "补脾和营"}
        ],
        "indication": "食谷欲呕（阳明病）。少阴病，吐利，手足厥冷，烦躁欲死者。干呕吐涎沫，头痛者。",
        "contraindication": "胃热呕吐者不可用。",
        "dosage": "水七升，煮取二升，去滓，温服七合，日三服。",
        "explanation": "吴茱萸辛热，温中降逆止呕为君。生姜重用六两和胃止呕。人参大枣补中护正。治肝寒犯胃、浊阴上逆之呕吐头痛。倪师：巅顶头痛+干呕吐涎沫=吴茱萸汤。",
        "keywords": ["干呕", "吐涎沫", "头痛", "巅顶痛", "手足厥冷"]
    },
    {
        "id": "linggui_gancao_dazao_tang", "name": "茯苓桂枝甘草大枣汤", "alias": "苓桂甘枣汤", "meridian": "太阳/心", "category": "平冲降逆剂",
        "components": [
            {"name": "茯苓", "dosage": "半斤", "role": "利水宁心"},
            {"name": "桂枝", "dosage": "四两", "role": "平冲降逆"},
            {"name": "炙甘草", "dosage": "二两", "role": "调和诸药"},
            {"name": "大枣", "dosage": "十五枚", "role": "补脾和营"}
        ],
        "indication": "发汗后，其人脐下悸者，欲作奔豚。",
        "contraindication": "无水饮者慎用。",
        "dosage": "甘澜水一斗，先煮茯苓减二升，内诸药，煮取三升，去滓，温服一升，日三服。",
        "explanation": "发汗后心阳虚，水饮上冲欲作奔豚（气从少腹上冲心）。茯苓利水宁心，桂枝平冲降逆，重用茯苓半斤利水为君。甘澜水=搅动千遍之水，取其轻扬不助水邪。",
        "keywords": ["脐下悸", "奔豚", "气上冲", "水饮"]
    },
    {
        "id": "lingui_gancao_tang", "name": "茯苓甘草汤", "alias": "", "meridian": "太阳/心", "category": "利水和中剂",
        "components": [
            {"name": "茯苓", "dosage": "二两", "role": "利水渗湿"},
            {"name": "桂枝", "dosage": "二两", "role": "温阳化气"},
            {"name": "炙甘草", "dosage": "一两", "role": "调和诸药"},
            {"name": "生姜", "dosage": "三两", "role": "温胃散寒"}
        ],
        "indication": "伤寒汗出而渴者，五苓散主之；不渴者，茯苓甘草汤主之。心下悸者。",
        "contraindication": "阴虚者慎用。",
        "dosage": "水二升，煮取一升，去滓，分温三服。",
        "explanation": "水停心下（胃脘）所致心下悸。茯苓利水，桂枝温阳化气，生姜温胃散寒。与五苓散区别：五苓散治水蓄膀胱（渴），此方治水停心下（不渴）。",
        "keywords": ["心下悸", "不渴", "水停心下"]
    },
    {
        "id": "wuling_san", "name": "五苓散", "alias": "", "meridian": "太阳/膀胱", "category": "利水渗湿剂",
        "components": [
            {"name": "猪苓", "dosage": "十八铢", "role": "利水渗湿"},
            {"name": "泽泻", "dosage": "一两六铢", "role": "利水渗湿"},
            {"name": "白术", "dosage": "十八铢", "role": "健脾燥湿"},
            {"name": "茯苓", "dosage": "十八铢", "role": "利水渗湿"},
            {"name": "桂枝", "dosage": "半两", "role": "温阳化气"}
        ],
        "indication": "太阳病，发汗后，大汗出，胃中干，烦躁不得眠，欲得饮水者，少少与之令胃气和则愈。若脉浮，小便不利，微热消渴者。",
        "contraindication": "津液亏损明显者慎用（利水伤阴）。",
        "dosage": "五味捣为散，以白饮和服方寸匕，日三服。多饮暖水，汗出愈。",
        "explanation": "膀胱蓄水证。猪苓泽泻茯苓利水渗湿，白术健脾制水，桂枝温阳化气助水液代谢。散剂取其速效。倪师：渴+小便不利+脉浮=五苓散证。多饮暖水助药力发汗。",
        "keywords": ["消渴", "小便不利", "脉浮", "膀胱蓄水", "水逆"]
    },
    {
        "id": "zhuling_tang", "name": "猪苓汤", "alias": "", "meridian": "少阴/膀胱", "category": "利水渗湿剂",
        "components": [
            {"name": "猪苓", "dosage": "一两", "role": "利水渗湿"},
            {"name": "茯苓", "dosage": "一两", "role": "利水渗湿"},
            {"name": "泽泻", "dosage": "一两", "role": "利水渗湿"},
            {"name": "阿胶", "dosage": "一两", "role": "滋阴养血"},
            {"name": "滑石", "dosage": "一两", "role": "利水通淋"}
        ],
        "indication": "少阴病，下利六七日，咳而呕渴，心烦不得眠者。阳明病，脉浮发热，渴欲饮水，小便不利者。",
        "contraindication": "阳虚水泛者不可用（当用真武汤）。",
        "dosage": "水四升，先煮四味取二升，去滓，内阿胶烊尽，温服七合，日三服。",
        "explanation": "水热互结伤阴。猪苓茯苓泽泻滑石利水清热，阿胶滋阴养血。与五苓散区别：五苓散治寒水（用桂枝），猪苓汤治热水兼阴虚（用阿胶）。利水不伤阴。",
        "keywords": ["小便不利", "心烦不得眠", "渴", "水热互结"]
    },
    {
        "id": "taohua_chengqi_tang", "name": "桃核承气汤", "alias": "", "meridian": "太阳/膀胱", "category": "破血逐瘀剂",
        "components": [
            {"name": "桃仁", "dosage": "五十个", "role": "破血逐瘀"},
            {"name": "大黄", "dosage": "四两", "role": "攻下热结"},
            {"name": "桂枝", "dosage": "二两", "role": "通阳化瘀"},
            {"name": "炙甘草", "dosage": "二两", "role": "调和诸药"},
            {"name": "芒硝", "dosage": "二两", "role": "软坚润燥"}
        ],
        "indication": "太阳病不解，热结膀胱，其人如狂，血自下，下者愈。其外不解者，尚未可攻，当先解其外。外解已，但少腹急结者，乃可攻之。",
        "contraindication": "无瘀血者不可攻。外证未解者先解表。",
        "dosage": "水七升，煮取二升五合，去滓，内芒硝，更上火微沸，下火，先食温服五合，日三服。",
        "explanation": "太阳表邪入里化热，热与血结于下焦。桃仁破血逐瘀，大黄芒硝攻下热结，桂枝通阳化瘀。少腹急结+如狂=膀胱蓄血轻证。先解表后攻里。",
        "keywords": ["少腹急结", "如狂", "蓄血", "膀胱", "血自下"]
    },
    {
        "id": "didang_tang", "name": "抵当汤", "alias": "", "meridian": "太阳/阳明", "category": "破血逐瘀剂",
        "components": [
            {"name": "水蛭", "dosage": "三十个", "role": "破血逐瘀"},
            {"name": "虻虫", "dosage": "三十个", "role": "破血逐瘀"},
            {"name": "桃仁", "dosage": "二十个", "role": "破血逐瘀"},
            {"name": "大黄", "dosage": "三两", "role": "攻下热结"}
        ],
        "indication": "太阳病，六七日，表证仍在，脉微而沉，反不结胸，其人发狂者，以热在下焦，少腹当硬满，小便自利者。",
        "contraindication": "体虚者慎用（破血力猛）。孕妇禁用。",
        "dosage": "水五升，煮取三升，去滓，温服一升。不下更服。",
        "explanation": "蓄血重证。水蛭虻虫为虫类破血药，力猛峻。桃仁大黄助攻瘀。少腹硬满+发狂+小便自利=蓄血成实。比桃核承气汤力量更强。",
        "keywords": ["少腹硬满", "发狂", "蓄血", "脉微而沉"]
    },
    {
        "id": "didang_wan", "name": "抵当丸", "alias": "", "meridian": "太阳", "category": "破血逐瘀剂",
        "components": [
            {"name": "水蛭", "dosage": "二十个"}, {"name": "虻虫", "dosage": "二十个"},
            {"name": "桃仁", "dosage": "二十五个"}, {"name": "大黄", "dosage": "三两"}
        ],
        "indication": "伤寒有热，少腹满，应小便不利，今反利者，为有血也，当下之，不可余药，宜抵当丸。",
        "contraindication": "蓄血重证当用汤剂，丸剂力缓。",
        "dosage": "四味捣分四丸，以水一升煮一丸，取七合服之。晬时当下血，若不下者更服。",
        "explanation": "蓄血缓证。药物同抵当汤但剂量减小，改丸剂缓攻。少腹满+小便自利=有瘀血但程度较轻。丸者缓也。",
        "keywords": ["少腹满", "蓄血", "丸剂"]
    },
    {
        "id": "daxianxiong_tang", "name": "大陷胸汤", "alias": "", "meridian": "太阳/阳明", "category": "峻下逐水剂",
        "components": [
            {"name": "大黄", "dosage": "六两", "role": "攻下热结"},
            {"name": "芒硝", "dosage": "一升", "role": "软坚润燥"},
            {"name": "甘遂", "dosage": "一钱匕", "role": "攻逐水饮"}
        ],
        "indication": "太阳病，脉浮而动数，头痛发热，微盗汗出，而反恶寒者，表未解也。医反下之，动数变迟，膈内拒痛，胃中空虚，客气动膈，短气躁烦，心中懊憹，阳气内陷，心下因硬，则为结胸。",
        "contraindication": "结胸证未成者不可峻攻。体虚者慎用。",
        "dosage": "水六升，先煮大黄取二升，去滓，内芒硝，煮一两沸，内甘遂末，温服一升。得快利，止后服。",
        "explanation": "水热互结于胸膈，心下硬满而痛。大黄芒硝攻下热结，甘遂攻逐水饮。三药合力峻下逐水泄热。服后得快利即止，不可过服。",
        "keywords": ["心下硬满", "膈内拒痛", "结胸", "短气躁烦"]
    },
    {
        "id": "xiaoxianxiong_tang", "name": "小陷胸汤", "alias": "", "meridian": "太阳/肺", "category": "清热化痰剂",
        "components": [
            {"name": "黄连", "dosage": "一两", "role": "清热燥湿"},
            {"name": "半夏", "dosage": "半升", "role": "化痰散结"},
            {"name": "栝蒌实", "dosage": "大者一枚", "role": "清热化痰宽胸"}
        ],
        "indication": "小结胸病，正在心下，按之则痛，脉浮滑者。",
        "contraindication": "寒痰结胸者不可用。",
        "dosage": "水六升，先煮栝蒌取三升，去滓，内诸药，煮取二升，去滓，分温三服。",
        "explanation": "痰热互结于心下（胃脘）。黄连清热，半夏化痰散结，栝蒌清热化痰宽胸。按之则痛=小结胸。与大陷胸汤区别：大陷胸=水热互结（硬满痛不可近），小陷胸=痰热互结（按之则痛）。",
        "keywords": ["心下", "按之则痛", "脉浮滑", "小结胸", "痰热"]
    },
    {
        "id": "jiejing_tang", "name": "结胸灸法", "alias": "", "meridian": "太阳", "category": "外治法",
        "components": [
            {"name": "巴豆", "dosage": "适量", "role": "温通攻逐"}
        ],
        "indication": "结胸证，脉浮大者（不可攻下，攻之则死）。可用灸法。",
        "contraindication": "脉沉紧者当用下法，非灸法所宜。",
        "dosage": "巴豆研末，和面为饼，灸于脐上。",
        "explanation": "结胸证脉浮大=正气尚盛，不可峻攻。灸法温通阳气，缓图之。此为外治法补充。",
        "keywords": ["结胸", "脉浮大", "灸法"]
    },
    {
        "id": "dahuang_lianqie_xiexin_tang", "name": "大黄黄连泻心汤", "alias": "", "meridian": "阳明", "category": "清热泻痞剂",
        "components": [
            {"name": "大黄", "dosage": "二两", "role": "泻热消痞"},
            {"name": "黄连", "dosage": "一两", "role": "清热燥湿"}
        ],
        "indication": "心下痞，按之濡，其脉关上浮者。",
        "contraindication": "虚寒痞满者不可用。",
        "dosage": "以麻沸汤二升渍之，须臾绞去滓，分温再服。",
        "explanation": "热痞——无形邪热壅聚心下。大黄黄连用麻沸汤渍（泡），取其气之轻扬以清上焦热，不取其味之苦降。按之濡=无实邪。脉关上浮=热在中焦。",
        "keywords": ["心下痞", "按之濡", "脉关上浮", "热痞"]
    },
    {
        "id": "fuzi_xiexin_tang", "name": "附子泻心汤", "alias": "", "meridian": "太阳/少阴", "category": "寒热并用剂",
        "components": [
            {"name": "大黄", "dosage": "二两"}, {"name": "黄连", "dosage": "一两"}, {"name": "黄芩", "dosage": "一两"},
            {"name": "炮附子", "dosage": "一枚", "role": "温经固表"}
        ],
        "indication": "心下痞，而复恶寒汗出者。",
        "contraindication": "无表阳虚者不用附子。",
        "dosage": "附子别煮取汁。大黄黄连黄芩以麻沸汤渍之，须臾绞去滓，内附子汁，分温再服。",
        "explanation": "热痞+表阳虚。心下痞=热，恶寒汗出=阳虚。三黄清热消痞（麻沸汤渍取轻扬），附子温阳固表（别煮取汁）。寒热异治，分取其汁合服。",
        "keywords": ["心下痞", "恶寒", "汗出", "寒热并用"]
    },
    {
        "id": "xiepin_tang", "name": "半夏泻心汤", "alias": "", "meridian": "少阳/太阴", "category": "辛开苦降剂",
        "components": [
            {"name": "半夏", "dosage": "半升", "role": "降逆和胃"},
            {"name": "黄芩", "dosage": "三两", "role": "清热"},
            {"name": "干姜", "dosage": "三两", "role": "温中散寒"},
            {"name": "人参", "dosage": "三两", "role": "益气补中"},
            {"name": "黄连", "dosage": "一两", "role": "清热"},
            {"name": "大枣", "dosage": "十二枚"},
            {"name": "炙甘草", "dosage": "三两"}
        ],
        "indication": "伤寒五六日，呕而发热者，柴胡汤证具，而以他药下之，心下满而不痛者，此为痞。",
        "contraindication": "水热互结结胸者不可用（结胸按之痛，痞按之濡）。",
        "dosage": "水一斗，煮取六升，去滓，再煎取三升，温服一升，日三服。",
        "explanation": "误下后寒热错杂痞结心下。半夏干姜辛温开结，黄芩黄连苦寒降热，参枣草补中和药。辛开苦降、寒热并调。倪师：心下痞+呕+肠鸣=半夏泻心汤。",
        "keywords": ["心下痞", "呕", "肠鸣", "寒热错杂", "痞证"]
    },
    {
        "id": "shengjiang_xiexin_tang", "name": "生姜泻心汤", "alias": "", "meridian": "少阳/太阴", "category": "辛开苦降剂",
        "components": [
            {"name": "生姜", "dosage": "四两", "role": "温胃散水"},
            {"name": "半夏", "dosage": "半升"}, {"name": "黄芩", "dosage": "三两"},
            {"name": "干姜", "dosage": "一两"}, {"name": "人参", "dosage": "三两"},
            {"name": "黄连", "dosage": "一两"}, {"name": "大枣", "dosage": "十二枚"},
            {"name": "炙甘草", "dosage": "三两"}
        ],
        "indication": "伤寒汗出解之后，胃中不和，心下痞硬，干噫食臭，胁下有水气，腹中雷鸣下利者。",
        "contraindication": "无水饮食滞者慎用。",
        "dosage": "水一斗，煮取六升，去滓，再煎取三升，温服一升，日三服。",
        "explanation": "半夏泻心汤减干姜量+重用生姜四两→偏于散水和胃。干噫食臭=食滞，胁下有水气+腹中雷鸣=水饮。生姜散水消食，为水饮食滞痞。",
        "keywords": ["心下痞硬", "干噫食臭", "腹中雷鸣", "下利", "水气"]
    },
    {
        "id": "gancao_xiexin_tang", "name": "甘草泻心汤", "alias": "", "meridian": "少阳/太阴", "category": "辛开苦降剂",
        "components": [
            {"name": "炙甘草", "dosage": "四两", "role": "补中和药"},
            {"name": "半夏", "dosage": "半升"}, {"name": "黄芩", "dosage": "三两"},
            {"name": "干姜", "dosage": "三两"}, {"name": "人参", "dosage": "三两"},
            {"name": "黄连", "dosage": "一两"}, {"name": "大枣", "dosage": "十二枚"}
        ],
        "indication": "伤寒中风，医反下之，其人下利日数十行，谷不化，腹中雷鸣，心下痞硬而满，干呕心烦不得安。狐惑病。",
        "contraindication": "纯热无虚者慎用。",
        "dosage": "水一斗，煮取六升，去滓，再煎取三升，温服一升，日三服。",
        "explanation": "半夏泻心汤重用甘草四两→偏于补中缓急。下利日数十行+谷不化=中气大虚。倪师：此方治狐惑病（口腔溃疡+阴部溃疡+眼睛溃疡=白塞氏病）。",
        "keywords": ["下利日数十行", "谷不化", "心下痞硬", "狐惑", "口腔溃疡"]
    },
    {
        "id": "xuanfu_daizhe_shi_tang", "name": "旋覆代赭石汤", "alias": "", "meridian": "阳明/胃", "category": "降逆化痰剂",
        "components": [
            {"name": "旋覆花", "dosage": "三两", "role": "降气消痰"},
            {"name": "代赭石", "dosage": "一两", "role": "重镇降逆"},
            {"name": "半夏", "dosage": "半升", "role": "降逆和胃"},
            {"name": "生姜", "dosage": "五两", "role": "温胃散寒"},
            {"name": "人参", "dosage": "二两", "role": "益气补中"},
            {"name": "大枣", "dosage": "十二枚"},
            {"name": "炙甘草", "dosage": "三两"}
        ],
        "indication": "伤寒发汗，若吐若下，解后，心下痞硬，噫气不除者。",
        "contraindication": "无痰饮者慎用。",
        "dosage": "水一斗，煮取六升，去滓，再煎取三升，温服一升，日三服。",
        "explanation": "误治后胃虚痰阻，气逆不降。旋覆花降气消痰，代赭石重镇降逆，半夏生姜降逆和胃，参枣草补中。心下痞硬+噫气不除=胃虚痰阻气逆。倪师：此方治胃酸反流、嗳气。",
        "keywords": ["心下痞硬", "噫气不除", "嗳气", "胃酸反流"]
    },
    {
        "id": "fuzi_jingmi_tang", "name": "附子粳米汤", "alias": "", "meridian": "太阴", "category": "温中散寒剂",
        "components": [
            {"name": "炮附子", "dosage": "一枚", "role": "温中散寒"},
            {"name": "半夏", "dosage": "半升", "role": "降逆和胃"},
            {"name": "甘草", "dosage": "一两", "role": "调和诸药"},
            {"name": "大枣", "dosage": "十枚"},
            {"name": "粳米", "dosage": "半升", "role": "养胃和中"}
        ],
        "indication": "腹中寒气，雷鸣切痛，胸胁逆满，呕吐。",
        "contraindication": "实热腹痛者不可用。",
        "dosage": "水八升，煮米熟汤成，去滓，温服一升，日三服。",
        "explanation": "脾胃虚寒，寒气攻冲。附子温中散寒，半夏降逆止呕，粳米大枣养胃和中。雷鸣切痛=寒气攻冲肠鸣腹痛。与理中汤区别：此方偏于散寒止痛降逆。",
        "keywords": ["雷鸣切痛", "胸胁逆满", "呕吐", "寒气"]
    },
    {
        "id": "gancao_ganjiang_fuzi_tang", "name": "甘草干姜附子汤", "alias": "干姜附子汤", "meridian": "少阴", "category": "回阳救逆剂",
        "components": [
            {"name": "干姜", "dosage": "一两", "role": "温中散寒"},
            {"name": "生附子", "dosage": "一枚", "role": "回阳救逆"},
        ],
        "indication": "下之后，复发汗，昼日烦躁不得眠，夜而安静，不呕不渴，无表证，脉沉微，身无大热者。",
        "contraindication": "非阳虚者不可用。",
        "dosage": "水三升，煮取一升，去滓，顿服。",
        "explanation": "汗下后阳气大虚。昼日烦躁（虚阳外扰）夜而安静（阳气更虚）。不呕不渴无表证+脉沉微=纯里虚寒。干姜附子单刀直入回阳，顿服取速效。比四逆汤更精简。",
        "keywords": ["昼日烦躁", "夜而安静", "脉沉微", "回阳"]
    },
    {
        "id": "houpo_shengjiang_banxia_gancao_ren_tang2", "name": "厚朴人参汤", "alias": "厚朴生姜半夏甘草人参汤", "meridian": "太阴", "category": "行气除满剂",
        "components": [
            {"name": "厚朴", "dosage": "半斤", "role": "行气除满"},
            {"name": "生姜", "dosage": "半斤", "role": "温胃散寒"},
            {"name": "半夏", "dosage": "半升", "role": "降逆和胃"},
            {"name": "炙甘草", "dosage": "二两", "role": "补中和药"},
            {"name": "人参", "dosage": "一两", "role": "益气补中"}
        ],
        "indication": "发汗后，腹胀满者。",
        "contraindication": "实热腹胀者不可用。",
        "dosage": "水一斗，煮取三升，去滓，温服一升，日三服。",
        "explanation": "发汗后脾虚气滞。厚朴行气除满为主，人参甘草补中，半夏生姜降逆。消补兼施。此条与厚朴生姜半夏甘草人参汤同方异名。",
        "keywords": ["腹胀满", "发汗后", "脾虚气滞"]
    },
]

# 避免重复ID
seen_ids = set()
unique_formulas = []
for f in SHANGHAN_FORMULAS:
    if f['id'] not in seen_ids:
        seen_ids.add(f['id'])
        unique_formulas.append(f)

print(f"Generated {len(unique_formulas)} unique formulas")

with open('_shanghan_formulas.json', 'w', encoding='utf-8') as f:
    json.dump(unique_formulas, f, ensure_ascii=False, indent=2)
print("Saved to _shanghan_formulas.json")
