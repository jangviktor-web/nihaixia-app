# -*- coding: utf-8 -*-
"""三语 README 统一更新：截图区 / 下载区版本 / 新功能使用说明 / 更新日志"""
import io

SCREEN = {
'README.md': '''<div align="center">

**v1.11.34 天纪讲义改版 · 双排盘接入问倪师AI**

![v1.11.34 天纪讲义](docs/images/screenshot_v1134_tianji_lectures.webp)

</div>

从左到右：① **天纪讲义分类页** —— 9 篇按「天纪总纲 / 紫微斗数 / 相术·命相同参 / 地脉道·堪舆」分组，点进篇内是带搜索的小节目录。 ② **疾厄宫·身相部位图** —— 原本显示 HTML 代码的盘面换成清晰配图，标注肩胸胁足与膀胱·子宫、卵巢·妇科。 ③ **易中圣人·八卦类象盘** —— 先天八卦环形配图，八个卦位与类象一目了然。

<div align="center">

![v1.11.34 紫微/八字排盘接入问倪师AI](docs/images/screenshot_v1134_ai_interpretation.webp)

</div>

上排从左到右：① **紫微斗数排盘** —— 填生辰后点右上角对话图标（红圈处）即可带盘面去问倪师AI。 ② **问倪师AI·解读入口** —— 已带好「请按倪师天纪的论断思路解读这个紫微命盘…」提示词。 ③ **解读报告** —— 按「命宫格局 → 四化落宫 → 大限重点」展开，表格逐项拆解。
下排从左到右：④ **八字排盘** —— 同样点右上角对话图标带盘面去解读。 ⑤ **命局总览表** —— 八字、性别、五行局、命宫/身主、当前大限一览。 ⑥ **未来十年趋势** —— 分「事业转折 / 人际与下属 / 财运波动」三段，底部标注 AI 生成、非倪师原话。

''',
'README.zh-Hant.md': '''<div align="center">

**v1.11.34 天紀講義改版 · 雙排盤接入問倪師AI**

![v1.11.34 天紀講義](docs/images/screenshot_v1134_tianji_lectures.webp)

</div>

從左到右：① **天紀講義分類頁** —— 9 篇按「天紀總綱 / 紫微斗數 / 相術·命相同參 / 地脈道·堪輿」分組，點進篇內是附搜尋的小節目錄。 ② **疾厄宮·身相部位圖** —— 原本顯示 HTML 程式碼的盤面換成清晰配圖，標註肩胸脅足與膀胱·子宮、卵巢·婦科。 ③ **易中聖人·八卦類象盤** —— 先天八卦環形配圖，八個卦位與類象一目瞭然。

<div align="center">

![v1.11.34 紫微/八字排盤接入問倪師AI](docs/images/screenshot_v1134_ai_interpretation.webp)

</div>

上排從左到右：① **紫微斗數排盤** —— 填生辰後點右上角對話圖示（紅圈處）即可帶盤面去問倪師AI。 ② **問倪師AI·解讀入口** —— 已帶好「請按倪師天紀的論斷思路解讀這個紫微命盤…」提示詞。 ③ **解讀報告** —— 按「命宮格局 → 四化落宮 → 大限重點」展開，表格逐項拆解。
下排從左到右：④ **八字排盤** —— 同樣點右上角對話圖示帶盤面去解讀。 ⑤ **命局總覽表** —— 八字、性別、五行局、命宮/身主、當前大限一覽。 ⑥ **未來十年趨勢** —— 分「事業轉折 / 人際與下屬 / 財運波動」三段，底部標註 AI 生成、非倪師原話。

''',
'README.en.md': '''<div align="center">

**v1.11.34 Tianji lectures redesigned · Zi Wei and BaZi charts feed into Ask-Ni-Hai-Xia AI**

![v1.11.34 Tianji lectures](docs/images/screenshot_v1134_tianji_lectures.webp)

</div>

Left to right: 1) **Tianji lecture index** - 9 works grouped under "Tianji Essentials / Zi Wei Dou Shu / Physiognomy / Feng Shui"; tap a work for its searchable section list. 2) **Affliction palace body map** - the former raw HTML diagram is now a clean illustration labelling shoulders, chest, flanks, feet and lower-abdominal organs. 3) **Bagua correspondences** - a circular diagram of the eight trigrams and their associations.

<div align="center">

![v1.11.34 Zi Wei and BaZi charts into AI](docs/images/screenshot_v1134_ai_interpretation.webp)

</div>

Top row: 1) **Zi Wei chart** - enter birth data, then tap the chat icon (circled) to send the chart to Ask-Ni-Hai-Xia AI. 2) **AI prompt** - pre-filled with "Interpret this Zi Wei chart using Master Ni's Tianji reasoning". 3) **Interpretation** - structured as "Life Palace pattern, Four Transformations, current Decade" with detail tables.
Bottom row: 4) **BaZi chart** - same chat icon sends the chart for interpretation. 5) **Chart summary** - BaZi, gender, Five-Element group, life and body palaces and current decade at a glance. 6) **Ten-year outlook** - career turn, relationships and financial swings, with a footer noting AI-generated content, not Master Ni's words.

'''
}

USAGE = {
'README.md': '''> **V1.11.34 天纪讲义改版 · 地纪游记 · 盘面图表化 · 命理AI解读升级 · 阅读进度记忆**（2026-11-18 发布）
>
> **一、天纪讲义：从「一页 166 节」改为三层目录**
> - **怎么用**：首页 →「天纪讲义」→ 先看 9 篇分类卡片（天机道 / 十二宫详解 / 星曜详解 / 手相 / 相术总结 / 六神占断论 / 堪舆风水 / 风水布局 / 八煞黄泉）→ 点进任意篇，出现该篇的小节目录（顶部可搜标题或正文，带序号与一行预览）→ 点某节看正文。
> - **新增第 10 篇《地纪》游记**：倪师实地走访陕西、汉中、武当山、桂林阳朔的日记，21 节按日期切分；在「地纪 · 游记」分组下。
> - **盘面不再是一堆 HTML 代码**：疾厄宫的子午流注钟盘、身相部位图、易中圣人的先天/后天八卦盘与爻象卡，全部换成清晰配图，图内文字仍可被搜索命中。
>
> **二、问倪师AI：命理场景独立口径 + 双排盘入口**
> - **怎么用（紫微）**：工具 → 紫微斗数排盘 → 填生辰 → 点右上角对话图标，盘面自动带入「问倪师AI」，已预填解读提示词。
> - **怎么用（八字）**：工具 → 八字排盘 → 填生辰 → 同样点右上角对话图标。
> - **解读口径**：盘面事实单独成块并标注「本地引擎计算」，不再与讲义原文混在一起；只讲倾向不给定论，不作医疗、投资或法律结论。
> - **检索质量**：命理提问先做多词拆分再按相关度排序（此前搜「八字」会命中 60/99 篇字幕，近乎随机）；整理讲义 188 节与字幕合并去重后一并入库，讲义优先。
> - **当前大限**：紫微解读的盘面摘要补上大限宫位 + 主星 + 干支，模型不再凭空编造大限。
>
> **三、阅读进度记忆**
> - 全 App 16 个阅读入口（天纪、古籍、伤寒、金匮、内经、本草、针灸、医案、紫微命例等）都会记住你读到哪，重开 App 或切换繁体后自动回到原处；读到末尾会视为已读完并清除记录。
>
> 详见 [Release Notes](release_notes/v1.11.34.md)。

''',
'README.zh-Hant.md': '''> **V1.11.34 天紀講義改版 · 地紀遊記 · 盤面圖表化 · 命理AI解讀升級 · 閱讀進度記憶**（2026-11-18 發布）
>
> **一、天紀講義：從「一頁 166 節」改為三層目錄**
> - **怎麼用**：首頁 →「天紀講義」→ 先看 9 篇分類卡片（天機道 / 十二宮詳解 / 星曜詳解 / 手相 / 相術總結 / 六神占斷論 / 堪輿風水 / 風水布局 / 八煞黃泉）→ 點進任一篇，出現該篇的小節目錄（頂端可搜標題或內文，附序號與一行預覽）→ 點某節看正文。
> - **新增第 10 篇《地紀》遊記**：倪師實地走訪陝西、漢中、武當山、桂林陽朔的日記，21 節按日期切分；在「地紀 · 遊記」分組下。
> - **盤面不再是一堆 HTML 程式碼**：疾厄宮的子午流注鐘盤、身相部位圖、易中聖人的先天/後天八卦盤與爻象卡，全數換成清晰配圖，圖內文字仍可被搜尋命中。
>
> **二、問倪師AI：命理場景獨立口徑 + 雙排盤入口**
> - **怎麼用（紫微）**：工具 → 紫微斗數排盤 → 填生辰 → 點右上角對話圖示，盤面自動帶入「問倪師AI」，已預填解讀提示詞。
> - **怎麼用（八字）**：工具 → 八字排盤 → 填生辰 → 同樣點右上角對話圖示。
> - **解讀口徑**：盤面事實單獨成塊並標註「本機引擎計算」，不再與講義原文混在一起；只講傾向不給定論，不作醫療、投資或法律結論。
> - **搜尋品質**：命理提問先做多詞拆分再按相關度排序（此前搜「八字」會命中 60/99 篇字幕，近乎隨機）；整理講義 188 節與字幕合併去重後一併入庫，講義優先。
> - **當前大限**：紫微解讀的盤面摘要補上大限宮位 + 主星 + 干支，模型不再憑空編造大限。
>
> **三、閱讀進度記憶**
> - 全 App 16 個閱讀入口（天紀、古籍、傷寒、金匱、內經、本草、針灸、醫案、紫微命例等）都會記住你讀到哪，重開 App 或切換繁體後自動回到原處；讀到末尾會視為已讀完並清除記錄。
>
> 詳見 [Release Notes](release_notes/v1.11.34.md)。

''',
'README.en.md': '''> **V1.11.34 Tianji redesign, Di Ji travelogue, illustrated charts, upgraded AI metaphysics readings, reading progress** (released 2026-11-18)
>
> **1. Tianji lectures: from a single 166-section list to a three-level index**
> - **How to use**: Home - "Tianji Lectures" - browse 9 grouped works (Tianji Essentials / Zi Wei Dou Shu / Physiognomy / Feng Shui), tap one for its searchable section list (title or full text, numbered with a one-line preview) - tap a section to read.
> - **New 10th work, the Di Ji travelogue**: Master Ni's field notes from Shaanxi, Hanzhong, Wudang Mountain and Guilin/Yangshuo - 21 date-based sections under the "Di Ji / Travelogue" group.
> - **No more raw HTML**: the Affliction-palace body map and the Yi Zhong Sheng Ren Bagua/decade diagrams are now clean illustrations; their text remains searchable.
>
> **2. Ask-Ni-Hai-Xia AI: a separate metaphysics mode plus two chart entry points**
> - **How to use (Zi Wei)**: Tools - Zi Wei chart - enter birth data - tap the chat icon at top right; the chart is attached automatically with a ready-made interpretation prompt.
> - **How to use (BaZi)**: Tools - BaZi chart - enter birth data - same chat icon.
> - **Interpretation policy**: chart facts are shown separately and labelled "computed locally", never mixed with lecture quotations; tendencies only, no certainties, and no medical, investment or legal conclusions.
> - **Retrieval quality**: metaphysics queries are split into terms then ranked by relevance (previously "BaZi" matched 60 of 99 subtitle files); 188 curated lecture sections are merged with subtitles, deduplicated, with lectures preferred.
> - **Current decade**: the chart digest now includes the decade palace, its main star and Heavenly Stem/Branch, so the model no longer has to invent it.
>
> **3. Reading progress**
> - All 16 reading entry points (Tianji, classics, Shang Han Lun, Jin Gui Yao Lue, Nei Jing, materia medica, acupuncture, case studies, Zi Wei examples, etc.) remember where you stopped; reopen the app or switch to Traditional Chinese and you return to the same spot. Reaching the end marks the item as read and clears the record.
>
> See [Release Notes](release_notes/v1.11.34.md).

'''
}

# 历史日志块还原映射（下载区替换会误伤历史条目）
HISTORY_FIX = {
'README.md': ('> **V1.11.34 穴位详情页体验升级', '> **V1.11.33 穴位详情页体验升级'),
'README.zh-Hant.md': ('> **V1.11.34 穴位詳情頁體驗升級', '> **V1.11.33 穴位詳情頁體驗升級'),
'README.en.md': ('> **V1.11.34 Acupoint detail', '> **V1.11.33 Acupoint detail'),
}
HISTORY_MARK = {
'README.md': '> **V1.11.33 穴位详情页体验升级',
'README.zh-Hant.md': '> **V1.11.33 穴位詳情頁體驗升級',
'README.en.md': '> **V1.11.33 Acupoint detail',
}

for f in ['README.md', 'README.zh-Hant.md', 'README.en.md']:
    s = open(f, encoding='utf-8').read()
    orig_len = len(s)

    # 1. 截图区：插到第一个 <div align="center"> 之前（截图章节内）
    if 'screenshot_v1134_tianji_lectures.webp' not in s:
        anchor = s.find('## 📷 ')
        if anchor < 0:
            anchor = s.find('## 📷 Screenshots')
        div = s.find('<div align="center">', anchor)
        assert div > 0, f + ' 未找到截图区 div'
        s = s[:div] + SCREEN[f] + s[div:]

    # 2. 下载区版本 + 4 按钮 URL
    s = s.replace('V1.11.33', 'V1.11.34')
    s = s.replace('releases/download/v1.11.33/', 'releases/download/v1.11.34/')

    # 3. 还原历史更新日志的版本号
    w, r = HISTORY_FIX[f]
    s = s.replace(w, r)

    # 4. 插入新功能使用说明（到历史日志块之前）
    if USAGE[f][:30] not in s and HISTORY_MARK[f] in s:
        pos = s.find(HISTORY_MARK[f])
        s = s[:pos] + USAGE[f] + s[pos:]

    open(f, 'w', encoding='utf-8', newline='\n').write(s)
    print(f, '已更新', orig_len, '->', len(s))
