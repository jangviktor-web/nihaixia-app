"""为缺失id的方剂添加拼音id"""
import json

NAME_TO_PINYIN = {
    "抵挡汤": "didangtang",
    "大黄蛰虫丸": "dahuangzhechongwan",
    "阳和汤": "yanghetang",
    "仙方活命饮": "xianfanghuomingyin",
    "五味消毒饮": "wuweixiaoduyin",
    "复元活血汤": "fuyuanhuoxuetang",
    "七厘散": "qilisan",
    "犀角地黄汤": "xijiaodihuangtang",
    "黄连粉": "huanglianfen",
    "桃红四物汤": "taohongsiwutang",
    "补阳还五汤": "buyanghuanwutang",
    "乳癌经验方第一方": "ruaijinyanfangdiyifang",
    "乳癌经验方第二方": "ruaijinyanfangdierfang",
    "乳癌末期移转方": "ruaimoqiyizhuanfang",
    "乳癌消肿方": "ruaixiaozhongfang",
    "肝癌标准方": "ganaibiaozhunfang",
    "肺癌方": "feiaifang",
    "血癌炙甘草汤方": "xueaizhigancaotangfang",
    "血癌寒热并结方": "xueairehanbingjiefang",
    "小儿血癌方": "xiaoerxueaifang",
    "脑瘤治疗方": "naoliuzhiliaofang",
    "红斑性狼疮标准方": "hongbanxinglangchuangbiaozhunfang",
    "红斑性狼疮清肝方": "hongbanxinglangchuangqingganfang",
    "尿毒症标准方": "niaoduzhengbiaozhunfang",
    "渐冻症方": "jiandongzhengfang",
    "心绞痛方": "xinjiaotongfang",
    "肝硬化腹水分消汤": "ganyinghuafushuifenxiaotang",
    "子宫肌瘤不孕方": "zigongjiliubuyunfang",
    "肺炎肺脓疡方": "feiyanfeinongyangfang",
    "鲤鱼汤排水方": "liyutangpaishuifang",
    "术附汤": "shufutang",
}

with open('assets/data/formulas.json', 'r', encoding='utf-8') as f:
    data = json.load(f)

formulas = data['formulas']
fixed = 0
for f in formulas:
    if 'id' not in f or not f['id']:
        name = f['name']
        pinyin = NAME_TO_PINYIN.get(name)
        if pinyin:
            f['id'] = pinyin
            fixed += 1
            print(f"Fixed: {name} -> {pinyin}")
        else:
            f['id'] = name
            fixed += 1
            print(f"Fixed (fallback): {name}")

with open('assets/data/formulas.json', 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print(f"\nFixed {fixed} formulas. Total: {len(formulas)}")

# verify no duplicates
ids = [f['id'] for f in formulas]
dupes = [x for x in ids if ids.count(x) > 1]
if dupes:
    print(f"WARNING: Duplicate ids: {set(dupes)}")
else:
    print("No duplicate ids.")
