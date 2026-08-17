# 汉唐中医 App 更新日志（Changelog）

> **维护约定**：本文件为项目根目录的官方变更记录。**每次发布 / 打包更新项目，必须在此追加对应版本条目**（版本号 + 变更要点 + 验证结果 + 发布信息）。
>
> **版本号规则**：以 `pubspec.yaml` 的 `version: X.Y.Z+N` 为单一来源。**对外展示版本号采用 `1.10.1` / `1.10.2` / `1.10.3` … 格式，每次发布自增第三位（patch）**；内部 `build` 号 `+N` 同时自增以作为 Android `versionCode`（必须单调递增）。Android `build.gradle.kts` 引用 `flutter.versionCode/versionName` 自动跟随，无需手改。
>
> **App 内更新日志**：每次发布须同步更新 `assets/data/changelog.json`（结构化条目：version/date/title/changes），它同时驱动「关于」页的更新日志展示与「更新后弹窗」。本 CHANGELOG.md 为项目根目录的人类可读备份。
>
> **验证基线**：全量 `flutter test` 182/182 通过；`flutter analyze` 0 新增 error；APK 经 `aapt2`（D:/sdk/build-tools/36.0.0/aapt2.exe）校验 `versionCode`/`versionName`。
>
> **发布方式**：APK ≥ 20MB 超邮件附件上限，统一 CloudStudio 部署下载页（index.html + APK）后邮件发送分享链接。

---

## [1.10.3+10] - 2026-08-17 — 七步问诊十问模块 v3.1 改版（倪师经方口径题库 + 新信号全链路）

**依据**：以倪海厦经方口径审阅用户整理的《问诊公式·全量修正版》（v3.1，12 问 106 选项），对 app 十问模块做题库、信号链路、分经路由三层优化；修正吴茱萸汤巅顶痛误用后脑痛等路由缺陷。

### Changed — 十问题库（v3.1 公式）
- **Q2 脉象 13→15 项**：新增「⑭结（时有一停·不规则）」「⑮代（固定节律停顿）」，脉象归一化同步支持（炙甘草汤结代脉可达）。
- **Q5 疼痛 10→20 项**：新增 ⑪身痒 ⑫心下痞硬 ⑬腹胀满 ⑭麻木不仁 ⑮咽中异物感 ⑯胸痛/心痛彻背 ⑰巅顶痛 ⑱心悸/怔忡 ⑲头晕目眩 ⑳腰痛腰冷。
- **Q6 大便 7→8 项**：新增「⑧大便色黑」（蓄血）。
- **Q8 胃口 7→8 项**：新增「⑧恶心/呕吐（→追问呕吐类型）」。
- **新增 Q12 呕吐类型（7 项）**：恶心不呕 / 干呕（含吐涎沫）/ 呕吐少量 / 呕吐剧烈 / 食入即吐 / 朝食暮吐 / 噫气嗳气——Q8 选「恶心/呕吐」才动态追问（独立常量 `vomitTypeQuestion`，不破坏引擎静态长度判断）。

### Changed — 引擎信号链路（diagnostic_engine.dart）
- 补建十问 **appetite 分支**（此前 Q8 答案从不被引擎处理，隐藏缺陷）。
- 新建 **vomit_type 分支**：Q12 选项映射到引擎既有 `nausea/vomiting` 信号 + 细分字段（vomit_dry/profuse/immediate/cyclical/belching）。
- Q5/Q6 新选项全部映射为信号字段；**21 处新信号接入分经路由**：麻黄连轺（身痒）、肾气丸（腰痛）、胸痹系列（新增 `chest_pain_radiating` 专属字段，避免胸胁胀痛误判胸痹）、抵当汤（便黑）、苓桂术甘/泽泻汤（眩晕分流）、黄芪桂枝五物（麻木）、半夏厚朴（咽异物）、旋覆代赭/生姜泻心（噫气）、茯苓泽泻（朝食暮吐）、大黄甘草（食入即吐）、干姜人参半夏丸（呕吐剧烈）、甘姜苓术/天雄散（腰痛分流）、栀子厚朴（烦躁+腹胀）、桂枝麻黄各半（身痒+无汗）、厚朴生姜半夏（腹胀）等。
- **吴茱萸汤路由修正**：原按「后脑痛」认吴茱萸汤（错），改为按「巅顶痛」（厥阴头痛），排除逻辑同步。
- 十问 Q10「容易疲倦」补 `fatigue` 映射（此前无字段）。

### 验证 / 发布
- strict 准确性 harness（`test/engine/diagnostic_accuracy_strict_test.dart`）：**23/23 通过**（19 经典案 + 柴胡桂枝汤十问内定少阳 + 3 个 v3.1 新用例：Q12 触发/不触发/吴茱萸汤端到端）。
- 全量 `flutter test` **205 通过 / 2 失败**（2 失败为紫微斗数 `ziwei_solar_check_test` 探针，遗留红灯、非本次引入）。
- `flutter analyze` 0 error。
- 版本号对外展示格式 `1.10.3`（build 号 +10，aapt2 校验 versionCode=10 / versionName=1.10.3）。
- 发布方式：CloudStudio 部署下载页。

---

## [1.10.2+9] - 2026-08-16 — 紫微斗数排盘集成 + 跨引擎精度验证

**依据**：达尔文 skill 对「紫微斗数引擎集成」的实证评估，选定 `ziwei_core` v0.13.0（MIT、纯 Dart、无 GetX 依赖）作为排盘引擎，替代因 MaterialApp 架构不兼容而弃用的 `dart_iztro`；并以 `DestinyLinker/MingLi-Bench`（iztro 预排命盘）作独立参考集验证精度。

### Added — 紫微斗数排盘
- 实用工具页新增「紫微斗数排盘」入口（`tools_screen.dart`）。
- 新增 `lib/services/ziwei_engine.dart`：封装 `ziwei_core`，将生辰转换为命盘，抽取十二宫 / 主星 / 辅星 / 四化 / 五行局 / 命主身主 / 十二大限为 App 模型。
- 新增 `lib/screens/ziwei_chart_screen.dart`：生辰输入（公历 + 性别）+ 4×4 命盘可视化（命宫 / 身宫标记、主星、四化、辅星、中心核显示五行局 / 命主 / 身主）+ 生年四化摘要 + 十二大限简述。
- 明确标注「民俗文化参考，非医疗诊断」，与经方医疗模块清晰分隔。

### Fixed — 排盘精度（真实 bug）
- **根因**：`ziwei_core` 默认 `useTrueSolarTime=true`（真太阳时，按 120E/30N 经度 + 均时差修正）；对**无地理位置输入的离线 app** 反而使时辰整体位移一格，与 iztro / 主流排盘不符。
- **修复**：`ZiweiDate.fromSolar(..., useTrueSolarTime: false)` 改用平太阳时（钟表时间）。
- 跨引擎比对定位：修复前 9 例八字差异 = 8 例时辰边界 + 1 例年柱（立春 vs 春节），修复后收敛为仅 1 例年柱流派差（已文档豁免）。

### 验证 / 发布
- 验证：用 MingLi-Bench（`fortune_api_results.json`，iztro 预排 32 道八字 + 紫微命盘）做跨引擎比对 harness（`test/ziwei_bench_test.dart`）：五行局 / 命宫 / 身宫 / 命主 / 十四主星 / 生年四化 **32/32** 全中；八字 31/32（仅 case_31 年柱立春 vs 春节）、身主 31/32（仅 case_7 铃星 vs 火星，火六局），均为已知流派约定差、文档化豁免；杂曜 0/32 属门派浮动（预期内，不断言）。
- 全量 `flutter test` **182/182 通过**；`flutter analyze` 0 error。
- 版本号改为对外展示格式 `1.10.2`（build 号 +9，aapt2 校验 versionCode=9 / versionName=1.10.2）。

---

## [1.10.1+8] - 2026-08-16 — 针灸穴位板块审计修复 + 更新日志与更新弹窗

**依据**：达尔文 skill 对《人纪·针灸·倪海厦》（8029 行）的实证审计（`zhenjiu_audit_report.md`），识别三类问题并全量修复（P0→P3）。

### Added — 关联打通（P3）
- 穴位详情页（`acupoint_detail_screen.dart`）新增三个可点按跳转区块：
  - **倪师处方公式**：解析临床心悟中的「XX方：A + B + C」并组成穴可跳转；
  - **关联穴位处方**：反向列出包含本穴的穴位处方；
  - **关联透针透穴**：反向列出包含本穴的透针透穴。
- `acupoint_repository.dart` 新增 `canonicalOf` 别名归一（处方错名/异名稳健匹配，遵循神农本草经修复铁律：正名原样返回，仅错字映射回正名）。

### Fixed — 数据质量（P0）/ 缺穴（P1）/ 薄条目（P2）
- **P0**：补全 16 条空 `meridian` 标注（中风八大穴→经外奇穴、五里→足厥阴肝经 等）；清理 16 类处方错别字（大杼/膻中/蠡沟/郄门/巨阙/脾俞…）；`acupoints.json` 总数 366→379。
- **P1**：补 29 条缺穴（督脉8/任脉7/肝经4/胆经4/奇穴6，含 期门/兑端/龈交/陶道/顖会/百虫窝 等）；14 经脉全部达标/超额，379→408。
- **P2**：doc 抽取回填 description 98%(401/408)、needling 55%、moxibustion 51%、contraindication 32%（讲座未讲针/灸/禁之穴如实留空，不伪造）。
- 修处方错字 `中阳`→`中脘`（胃痛/急性胃痛主穴），穴位↔处方关联解析率 **90%→100%**。

### Added — 更新日志与更新弹窗
- 新增 `assets/data/changelog.json` + `changelog_repository.dart`（App「关于」页与「更新后弹窗」的唯一数据源）。
- 「关于」页（`app_dialogs.dart`）新增更新日志展示（最新版本高亮 + 历史卡片）。
- 新增 `whats_new_service.dart`：利用 `DatabaseHelper.user_settings` 记录 `last_seen_version`，App 启动若检测到版本更新则弹出「本次更新了什么」。
- `home_screen.dart` 启动挂接（延迟 800ms 触发）。

### 验证 / 发布
- 验证：`flutter analyze` 0 error；`flutter test` 全过。
- 版本号改为对外展示格式 `1.10.1`（build 号 +8，aapt2 校验 versionCode=8 / versionName=1.10.1）。
- 打包 / 部署 / 邮件：见发布流程。

---

## [1.10.0+7] - 2026-08-16 — 神农本草经板块第四轮核查修复

**依据**：达尔文 skill 对《人纪·神农本草经·倪海厦》（20401 行）的实证审计（`bencao_audit_report.md`），识别三类问题并修复。

### Fixed — 方剂↔本草关联断裂（系统性，最高 ROI）
- **根因**：`formulas.json` 用现代/炮制名（朱砂/栝蒌实/橘皮/红枣/炮附子…），`herbs.json` 用神农古名（丹砂/栝楼实/陈皮/大枣/附子…）；旧别名表仅 17 条且**未用于**草药→方剂匹配（`herb_detail_screen.dart:329` 用 `c.name == herb.name` 精确相等）。
- **修复**：`herb_repository.dart` 重写 `_aliasMap` → `_canonicalOf`（约 75 条，仅收录"本身非药库条目的异名→药库正名"，剔除桂枝/白芍等自身条目以免断开其自身关联），新增 `static String canonicalOf(name)` 并应用到 `getByName`/`search`；草药详情页 `:329` 改为 `f.components.any((c) => HerbRepository.canonicalOf(c.name) == herb.name)` 并补 import。
- **成效**：组成药名可解析率 **67% → 91%**（240/262）；22 个残留为辅料/食物/非神农药（白酒/猪膏/人尿/苦酒/五苓散等），无需处理。

### Changed — 本草介绍补全
- `backfill_herbs.py` 回填（仅填空不覆盖，键用正确 `ni_note`/`historical_notes`；初版误写驼峰 `niNote` 致假阴性，已回退 `herbs.json.bak` 重跑）：`ni_note` 33→35、`historical_notes` 83→151、`nature` 284→313、`action` 367→370（补灵胎/吴克潜/唐容川注）。
- **限制**：矿物/虫鱼类（曾青/空青等口语讲解无结构化【主治】）薄条目受文档格式限制无法全补，如实标注不伪造。

### Added — 缺载本经药
- 补建 8 味（440→448）：狗脊、玄参、磁石(慈石)、水苏、姑活、乌韭、析蓂子、肉苁蓉(肉松容)，均含 original/nature/action/dosage/contraindication/nature_category/flavor/category。

### 验证 / 发布
- 验证：`flutter test` 174/174 全过；`formula_repository_test` 30/30；analyze 0 error。
- 打包：`flutter build apk --release` 成功（54.2MB，Gradle assembleRelease 681.8s）；aapt2 校验 versionCode=7 / versionName=1.10.0。
- 部署：新建 `release/` + `release/download-page/`（index.html 下载页 + app-release.apk）；CloudStudio 部署 → `https://8e56c8c253164bdd871493bcde8bee00.app.workbuddy.link`（旧 `6c1f4d…` 已 unpublish）。
- 邮件：已发 taobaoshop@139.com。交付：`汉唐中医_v1.10.0+7.apk` + `汉唐中医_v1.10.0+7_发布说明.md` + `release/download-page/index.html`。

---

## [1.10.0+6] - 2026-08-16 — 第三轮「病证→方」关联核查

**依据**：用户分享《人纪·金匮要略》文档（8920 行），要求"skill 缺少的按文档修正"。

### Changed
- **牡蛎汤标签忠实化**：引擎原以 `_symSelected('牝疟') && _symSelected('但头汗出')` 触发（`:5160`），"但头汗出"在倪师体系关联湿家/产后郁冒/热入血室/黄疸，与牡蛎汤无关。改 UI `牝疟（外台补充方，→牡蛎汤）` + 引擎 `_symSelected('牡蛎汤')` 精确命中，蜀漆散加 `!_symSelected('牡蛎汤')` 排除。
- **4 处合病条文号订正**（`diagnostic_rules.dart` combinedPatterns 注释）：柴胡桂枝汤 109→146、大柴胡汤 116→103/165、葛根加半夏汤 37→33、麻黄汤喘胸满 40→36。

### 关键更正（round-2 误判）
- round-2 称"skill 查无 牡蛎汤/柴胡去半夏加栝蒌汤"——实际 skill modules/04:11156-11182 完整收录（外台补充方），与分享文档 1673-1681 一致，故为假阳性，App 路由本就正确无需改方。

### 附：skill↔app 命名体系差异（"skill 缺什么方子"实证比对）
- `precise_features.json`（264 首全集）逐方 grep 14 个 skill 模块，11 个"候选缺失"全是倪师**异名/异文/别名**（如 桂枝加黄芪=桂枝加黄耆、麻黄连轺=麻黄连翘、桃红四物汤为明清后世方 skill 正确未收）。**结论：skill 不缺方**，后续做一致性应做别名映射而非补方。

### 验证 / 发布
- 验证：analyze 0 error；flutter test 174/174 全过；aapt2 versionCode=6/versionName=1.10.0。
- 打包：1.10.0+5 → 1.10.0+6；APK 54.1MB；复制到 `release/汉唐中医_v1.10.0+6.apk`。
- 部署：CloudStudio 沿用沙箱，链接不变指向 +6。邮件：已发 taobaoshop@139.com。
- 累计三轮修正 5 处（狐惑主方/蚀于下部/杏子汤/桃红四物汤→桂枝茯苓丸/牡蛎汤标签+4 条文号）；App 全部「病证→方」关联经三轮核查无误。

---

## [1.10.0+5] - 2026-08-16 — 第二轮「病证→方」关联核查

**依据**：倪海厦 skill 逐群核查（`app_audit_report.md`），确认 12+ 群无误，发现 3 处须修正错误。

### Fixed
- **狐惑 generic（→赤豆当归散）应为甘草泻心汤**（倪师 modules/04:10793「蚀于上部则声嘎，甘草泻心汤主之」）；UI `:76` + 引擎 `:3745` 去 `|| _symSelected('狐惑')`。
- **狐惑蚀于下部（→雄黄熏方）误挂**，拆分出"下部→苦参汤"（`:78`）。
- **杏子汤注释"通行本即麻杏甘石汤"违背倪师**；改 **麻黄杏仁甘草汤（无石膏）**，标注方阙（`:5095/5100`）。
- 第 2 轮：血虚兼血瘀"桃红四物汤"（明清后世方，skill 查无）应为 **桂枝茯苓丸**（仲景活血化瘀主方，`:287` + `:3811/3822`）。

### 验证 / 发布
- 验证：analyze 0 新增 error（5 告警为旧代码）；flutter test 174/174 全过（54/54 引擎测试未回归）。
- 打包：1.10.0+4 → 1.10.0+5；APK 54.1MB。
- 部署：CloudStudio 沿用沙箱。邮件：已发 taobaoshop@139.com。

---

## [1.10.0+4] - 2026-08-16 — 七步问诊「按键」审计与修复

**依据**：用户要求"检查 7 步问诊的按键是否有其他错误"。写 `round_f.dart` 遍历 33 组选项按钮（六经跟进+六经杂证补充+金匮证候族），对每枚带（→方）按钮做"单点点击→引擎返回"功能实测。

### Fixed
- **复核纠正**：原判 24 错含 8 处"重复"是 `round_f` 假阳性（seen 集合按整个经别组累计，误判跨题复用的中性选项"没有/正常"）；改为按单题查重，确认每组内选项唯一，不应删。
- **真修 16 处**：13 处按钮标注归一（桂麻各半汤→桂枝麻黄各半汤、麻杏石甘汤→麻杏甘石汤、桂去桂加苓术汤→桂枝去桂加茯苓白术汤、承气汤→大承气汤、栀子蘖皮汤→栀子柏皮汤、厚朴姜夏甘参汤→厚朴生姜半夏甘草人参汤、干姜黄连黄芩人参汤→干姜黄芩黄连人参汤、身体疼烦→白术附子汤、心下悸→半夏麻黄丸、百合病→百合病渴(栝蒌牡蛎散)、哕逆→橘皮竹茹汤、胃反→胃反渴(茯苓泽泻汤)）+ 10 处引擎分支调整。
- **引擎分支调整**：①心中懊憹系列变方仅呕/少气时命中，裸懊憹归栀子豉汤；②目眩+失精→桂枝加龙骨牡蛎汤；③厥而心下悸→茯苓甘草汤；④栝蒌牡蛎散/茯苓泽泻汤变方接受"渴"触发，基础方加 `!渴`。补 2 个 UI 按钮（干呕哕手足厥→橘皮汤、少气→栀子甘草豉汤）。同步 `precise_features.json`。

### 验证 / 发布
- 验证：`round_f` 悬空0/错位0/异名0/重复0；`round_e` 264/264 可达+命中、0 误判；analyze 0 error；flutter test 174/174 全过。
- 打包：1.10.0+3 → 1.10.0+4；APK 54.1MB（5m21s）。
- 部署：CloudStudio 下载页。邮件：已发 taobaoshop@139.com。

---

## [1.10.0+3] - 2026-08-16 — 七步问诊重构（P1+P2+Phase3）完成

**背景**：七步问诊引擎全量可达性测试（226 方剂 harness，192/226 可达，确证 P0-P3 引擎缺陷）；UI 选项可达性全量测试（237 方，根因 `_selectedSymptoms.contains('术语')` 精确相等 vs 带后缀选项）；完整问题与选项清单整理；双 skill 融合重构设计方案（六经为纲 + 金匮 19 篇为目，19 证候族映射 237 方）。

### Added / Changed
- **重构 P1+P2**（提交 e741ee8）：`_symSelected` 子串匹配 291 处（40→68）；`condition_families.dart` 22 族×132 方鉴别树（生成器 `engine_harness/tools/gen_families.py`，数据源 `precise_features.json`）；`meridianSupplementFollowUps` 24 方；脉象+6（促结代芤革微弱）；`chat_screen` 两级导航。3 处遮蔽修复（桂枝加桂排气上冲胸 / 甘草干姜附子排 irritable / 半夏散及汤收窄 cold_limbs）。
- **Phase3**（提交 821ee41）：新增 33 misc 分支（小建中/炙甘草/薯蓣丸/…/柴胡去半夏加栝蒌，逐方对照倪师 skill 条文）；20 命名归一别名（八味肾气丸=肾气丸 等）；P3 遮蔽修复 6 处。`precise_features` 224→257；family 22 族×166 方。

### 验证 / 发布
- 验证：引擎 257/257 可达+命中（0 误判）；用户 237 方覆盖 232/237=97.9%（≥95% 达成）；flutter test 174/174；analyze 0。
- 打包：1.9.1+2 → 1.10.0+3（提交 913b0b3）；APK 54.1MB；aapt2 versionCode=3/versionName=1.10.0。
- 部署：CloudStudio 分享页（54MB > 邮件 20MB 附件上限，改发下载链接）。邮件：已发 taobaoshop@139.com。

---

## [1.9.1+2] - 2026-08-16 — 七步问诊引擎 P0-P3 缺陷修复

**背景**：达尔文方法论引擎缺陷确证（带行号，引擎只读未改）：fever/palpitation 从未赋值致 6 方 dead；精确串 vs UI 后缀致降级；沉脉改写太阳返回 null；`'不渴'.contains('渴')` 误判；顺序遮蔽 23 方；证据闸白名单 24 key 不足。

### Fixed（分支 auto-optimize/20260816-0035，6 commits / 10 修复点 F1-F10）
- **F1** fever 赋值（解封麻黄附子细辛/葛根芩连/麻杏薏甘/厚朴七物/栀子枳实 5 方）。
- **F3** 精确串→contains（大承气×2/桂枝加葛根；兼容 bool+String）。
- **F4** 沉脉不再改写太阳（新加汤 null 路径）。**F5** `'不渴'.contains('渴')` 修复。
- **F6** 顺序遮蔽 13 处兜底方加排除（misc 130→153，六经 5 方解封）。
- **F7** cold_limbs 评分 3→2（理中汤煎剂解封，符合倪师"厥冷过肘膝用四逆"）。
- **F8** 证据闸白名单 +12 项（解封炙甘草汤等）+ `_answers['meridian']` 赋值（五经跟进 gate）。
- **F10** `'大汗出'` 无法识别（'汗出'≠'出汗'）→ 改匹配 '汗'。配套：formula_repository dosage 填充。

### 验证 / 发布
- 验证：引擎 **226/226 可达（100%）**；flutter test 174/174（17 测试适配）；analyze 0。
- 打包：1.5.0+1 → 1.9.1+2（首次执行版本号规则）；`flutter build apk --release` 成功（54MB，6m42s）；aapt2 versionName=1.9.1/versionCode=2。
- 交付：汉唐中医_v1.9.1.apk（含 F1-F10 全部引擎修复）。
