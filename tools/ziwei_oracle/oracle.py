"""iztro-py 引擎交叉验证 oracle（dev 工具，不参与 App 构建）。

用途
----
为若干已知出生数据，用 iztro-py（纯 Python 紫微斗数实现，0.5.0）排盘，
产出「参考基准」ziwei_reference.json，用于核对本 App 使用 Dart 引擎
ziwei_core 排出的字段是否一致 —— 即 L1「引擎准确性」的客观验证。

同时做一项独立校验：把本 App 解释层的「流年化忌天干表」
（lib/services/ziwei_interpretation.dart 的 _huaJiByStem）与 iztro 引擎
真实排出的「流年四化忌星」逐干比对，用引擎而非网页来源证明该表正确。

口径差异（比对时必须注意）
--------------------------
1. iztro by_solar 默认 fix_leap=True；本 App 测试用 useTrueSolarTime=false。
   命宫主星/四化/五行局不受真太阳时影响，八字时柱可能受影响。
2. 流年比对必须取「立春之后」的日期（脚本内取年中 6/15），
   否则 iztro 会返回上一个农历年的流年，与本 App 按公历年计算的结果错位。

运行
----
    python tools/ziwei_oracle/oracle.py
"""

import json
from pathlib import Path

import iztro_py as iz

OUT = Path(__file__).with_name("ziwei_reference.json")

# (公历生日, time_index, 性别)  time_index: 0=早子时(00-01) … 11=亥时(21-23), 12=晚子时(23-24)
SAMPLES = [
    ("1990-06-15", 0, "男"),
    ("1985-03-10", 6, "女"),
    ("2000-11-25", 4, "男"),
    ("1976-08-08", 8, "女"),
]

# 覆盖 2025–2034 共 10 年，恰好遍历十天干（乙丙丁戊己庚辛壬癸甲），
# 使化忌表校验能覆盖全部 10 干而不仅是 5 个。
FLOW_YEARS = list(range(2025, 2035))

# 本 App 解释层的流年化忌表（与 ziwei_interpretation.dart _huaJiByStem 一致）
HUAJI_BY_STEM = {
    "甲": "太阳",
    "乙": "太阴",
    "丙": "廉贞",
    "丁": "巨门",
    "戊": "天机",
    "己": "文曲",
    "庚": "天同",
    "辛": "文昌",
    "壬": "武曲",
    "癸": "贪狼",
}

STEM_EN2ZH = {
    "jiaHeavenly": "甲", "yiHeavenly": "乙", "bingHeavenly": "丙",
    "dingHeavenly": "丁", "wuHeavenly": "戊", "jiHeavenly": "己",
    "gengHeavenly": "庚", "xinHeavenly": "辛", "renHeavenly": "壬",
    "guiHeavenly": "癸",
}

# 化忌候选星的 iztro 枚举 -> 中文（仅覆盖会化忌的 10 颗）
# 地支枚举 -> (中文, 索引)。索引 0=子 … 11=亥，
# 与本 App ziwei_engine.dart 中 palaces 的物理地支索引口径一致。
BRANCH_EN2ZH_IDX = {
    "ziEarthly": ("子", 0), "chouEarthly": ("丑", 1), "yinEarthly": ("寅", 2),
    "maoEarthly": ("卯", 3), "chenEarthly": ("辰", 4), "siEarthly": ("巳", 5),
    "wuEarthly": ("午", 6), "weiEarthly": ("未", 7), "shenEarthly": ("申", 8),
    "youEarthly": ("酉", 9), "xuEarthly": ("戌", 10), "haiEarthly": ("亥", 11),
}

STAR_EN2ZH = {
    "taiyangMaj": "太阳", "taiyinMaj": "太阴", "lianzhenMaj": "廉贞",
    "jumenMaj": "巨门", "tianjiMaj": "天机", "wenquMin": "文曲",
    "tiantongMaj": "天同", "wenchangMin": "文昌", "wuquMaj": "武曲",
    "tanlangMaj": "贪狼",
}


def star_brief(s):
    return {
        "name": s.translate_name(),
        "brightness": getattr(s, "brightness", None),
        "mutagen": getattr(s, "mutagen", None),
    }


def extract(solar_date, time_index, gender):
    a = iz.by_solar(solar_date, time_index, gender)

    palaces = []
    sihua = []
    for p in a.palaces:
        all_stars = list(p.major_stars) + list(p.minor_stars) + list(p.adjective_stars)
        for s in all_stars:
            if getattr(s, "mutagen", None):
                sihua.append({"star": s.translate_name(), "mutagen": s.mutagen})
        palaces.append({
            "index": p.index,
            "name_zh": p.translate_name(),
            "is_original_palace": p.is_original_palace,
            "is_body_palace": p.is_body_palace,
            "major_stars": [star_brief(s) for s in p.major_stars],
            "decadal_range": list(p.decadal.range) if p.decadal else None,
        })

    flows = {}
    huaji_checks = []
    flow_checks = []
    for y in FLOW_YEARS:
        # 取年中（立春之后），避免流年归属上一个农历年
        h = a.horoscope(f"{y}-06-15", 0)
        yearly = h.yearly
        stems = yearly.heavenly_stem
        flows[str(y)] = {
            "heavenly_stem": stems,
            "earthly_branch": yearly.earthly_branch,
            "palace_index": yearly.index,
            "mutagen_en": list(yearly.mutagen or []),
        }
        # 化忌表独立校验：iztro 的 mutagen 顺序为 [禄, 权, 科, 忌]，取第 4 个
        mut = list(yearly.mutagen or [])
        if len(mut) == 4:
            stem_zh = STEM_EN2ZH.get(stems)
            ji_en = mut[3]
            ji_zh = STAR_EN2ZH.get(ji_en, ji_en)
            expect = HUAJI_BY_STEM.get(stem_zh)
            huaji_checks.append({
                "year": y,
                "stem": stem_zh,
                "iztro_ji_star": ji_zh,
                "app_ji_star": expect,
                "match": ji_zh == expect,
            })

        # 流年命宫地支校验：本 App 公式 ((year+8)%12+12)%12 得地支索引，
        # 与 iztro 实际排出的流年地支逐一对齐。
        bzh, bidx = BRANCH_EN2ZH_IDX.get(yearly.earthly_branch, ("?", -1))
        app_idx = ((y + 8) % 12 + 12) % 12
        flow_checks.append({
            "year": y,
            "iztro_branch": bzh,
            "iztro_branch_index": bidx,
            "app_branch_index": app_idx,
            "match": bidx == app_idx,
        })

    return {
        "solar_date": solar_date,
        "time_index": time_index,
        "gender": gender,
        "chinese_date": a.chinese_date,
        "lunar_date": a.lunar_date,
        "five_elements_class": a.five_elements_class,
        "soul": a.soul,
        "body": a.body,
        "sihua": sihua,
        "palaces": palaces,
        "flow_years": flows,
        "huaji_checks": huaji_checks,
        "flow_checks": flow_checks,
    }


def main():
    data = {"engine": "iztro-py 0.5.0", "language": "zh-CN", "charts": []}
    for sample in SAMPLES:
        data["charts"].append(extract(*sample))

    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"已生成: {OUT}  ({len(data['charts'])} 张盘)\n")

    for c in data["charts"]:
        ming = next((p for p in c["palaces"] if p["is_original_palace"]), None)
        print(f"{c['solar_date']} 时辰idx={c['time_index']} {c['gender']}"
              f"  五行局={c['five_elements_class']}")
        print(f"  八字: {c['chinese_date']}")
        if ming:
            ms = ", ".join(f"{s['name']}({s['brightness'] or '-'})" for s in ming["major_stars"])
            print(f"  命宫({ming['name_zh']}): {ms or '空宫'}")
        print(f"  生年四化: " + ", ".join(f"{x['star']}{x['mutagen']}" for x in c["sihua"]))
        for fy, fv in c["flow_years"].items():
            print(f"  流年{fy}: {STEM_EN2ZH.get(fv['heavenly_stem'], '?')}"
                  f"{fv['earthly_branch']}  命宫index={fv['palace_index']}")
        print()

    print("=== 化忌天干表独立校验（iztro 引擎 vs 本 App 表） ===")
    total = ok = 0
    seen = set()
    for c in data["charts"]:
        for chk in c["huaji_checks"]:
            if chk["stem"] in seen:
                continue
            seen.add(chk["stem"])
            total += 1
            ok += 1 if chk["match"] else 0
            flag = "OK " if chk["match"] else "MISMATCH"
            print(f"  {chk['stem']}干: iztro={chk['iztro_ji_star']:<3} "
                  f"app={chk['app_ji_star']:<3} [{flag}]")
    print(f"  结果: {ok}/{total} 匹配（覆盖 {total} 个天干）")

    print("\n=== 流年命宫地支校验（本 App 公式 vs iztro 排盘） ===")
    fseen = set()
    ftotal = fok = 0
    for c in data["charts"]:
        for chk in c["flow_checks"]:
            if chk["year"] in fseen:
                continue
            fseen.add(chk["year"])
            ftotal += 1
            fok += 1 if chk["match"] else 0
            flag = "OK " if chk["match"] else "MISMATCH"
            print(f"  {chk['year']}: iztro={chk['iztro_branch']}({chk['iztro_branch_index']}) "
                  f"app索引={chk['app_branch_index']} [{flag}]")
    print(f"  结果: {fok}/{ftotal} 匹配")


if __name__ == "__main__":
    main()
