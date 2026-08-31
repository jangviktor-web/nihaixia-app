# 汉唐中医 App 更新日志（Changelog）

> **维护约定**：本文件为项目根目录的官方变更记录。**每次发布 / 打包更新项目，必须在此追加对应版本条目**（版本号 + 变更要点 + 验证结果 + 发布信息）。
>
> **版本号规则**：以 `pubspec.yaml` 的 `version: X.Y.Z+N` 为单一来源。**对外展示版本号采用 `1.10.1` / `1.10.2` / `1.10.3` … 格式，每次发布自增第三位（patch）**；内部 `build` 号 `+N` 同时自增以作为 Android `versionCode`（必须单调递增）。Android `build.gradle.kts` 引用 `flutter.versionCode/versionName` 自动跟随，无需手改。
>
> **App 内更新日志**：每次发布须同步更新 `assets/data/changelog.json`（结构化条目：version/date/title/changes），它同时驱动「关于」页的更新日志展示与「更新后弹窗」。本 CHANGELOG.md 为项目根目录的人类可读备份。
>
> **验证基线**：全量 `flutter test` 182/182 通过；`flutter analyze` 0 新增 error；APK 经 `aapt2`（D:/sdk/build-tools/36.0.0/aapt2.exe）校验 `versionCode`/`versionName`。
>
> **发布方式**：推送 `v*` tag 即由 **GitHub Actions** 自动编译并发布四个 APK 到同名 Release（配置见 `.github/workflows/build-apk.yml`，全程约 6 分钟），无需手动打包上传。如需国内加速分发，可另用 CloudStudio 部署下载页（`deploy_vXXXX/index.html` + APK）。

---

## [Unreleased] — 紫微斗数排盘：运势总结 + 健康提醒解读层

**一句话**：排盘后自动生成整体运势、十年大运逐限、单流年运势叙述，并基于流年疾厄宫推算健康提醒（默认未来 30 年，可展开终身）；全部为离线规则模板，结果标注为民俗文化参考、非医疗诊断。

**① 新增：运势总结解读层**（`lib/services/ziwei_interpretation.dart`，纯逻辑可测）
- `summarizeOverall` 整体运势：综合命宫主星 + 生年四化（禄/权/科/忌落宫领域）生成叙述。
- `summarizeDecades` 十年大运：十二大限逐条评语（主星 + 煞星扰动提示）。
- `summarizeFlowYear` 流年运势：选中流年时展示流年命宫主星 + 流年疾厄宫 + 身体留意部位。
- `analyzeHealthWatch` 健康提醒：遍历年份，取流年疾厄宫（命宫+5）命中信号——本局煞星随过宫触发 / 流擎羊·流陀罗 / 流年化忌（化忌表按流年天干推算），命中即列「年份·虚岁 / 身体部位 / 信号 / 来源」。

**② 新增：排盘界面「运势总结」卡片区**
- 整体运势 / 十年大运 / 流年运势（选流年才显示）/ 健康提醒 四卡。
- 健康提醒每条带「民俗文化参考·非医疗诊断·如有不适请就医」免责；默认未来 30 年，按钮展开终身（出生→百岁）。
- 宫位→身体部位采用通用紫微口径，化忌星属十四主星时附倪师《天纪》星性注脚（仅引用既有资料，不编造原话）。

**验证**
- 新增 `test/ziwei_interpretation_test.dart` 冒烟测试（真实命盘 男 1990-06-15 子时）。
- 改动仅追加，未动既有排盘渲染逻辑（`_calculate`/`_buildPalaceGrid`/`_showPalaceDetail`）。

**状态**：本地 commit `b3de746`，未发布、未 push，待版本号 bump 后并入正式版本条目。

---

## [1.11.9+20] - 2026-08-29 — L1 辨证开方增强：患者口语语料接入（修复症状词关联不到方剂）

**一句话**：基于新获得的人纪治症公式语料（伤寒113方 + 金匮125方口语化表述），为「答题辨证开方」补齐「患者会怎么说」可视化 + 匹配增强，修复用户勾选现代症状词字面打不中古文条文、导致方剂/医案关联 0 结果的历史 Bug。

**背景**
- 用户获赠倪师《人纪》经方治症公式文档（伤寒113方 v2 / 金匮125方 v3 / 本草导读 v3）与结构化 RAG-Matrix-DB.json。
- 交叉比对：238 首新方 vs App 已有 322 方，真实净新增仅约 20 首——价值不在"新增方剂数量"，而在新字段 `patient_oral`（患者口语大白话）。
- 评估结论：RAG 检索优于训练模型（238 条远不足以微调），口语语料作为检索/展示语料完美契合现有确定性引擎。

**① 新增：患者口语语料可视化**
- 新增 `formula_oral_hints.json`（170 首方口语语料，已转简体），含 `oral`（患者口语长句）、`indicators`（辨证指针）、`treatment`（治法）、`sourceText`（原文条文）。
- 辨证结果页新增「患者会怎么说」卡片（`OralHintCard`），用户可对照"这话像不像我说的"，结果可解释性大幅提升。

**② 增强：方剂相似度匹配叠加口语语料**
- 原 `getSimilarityRanking` 仅做 keywords/indication/name/alias 双向子串字面匹配，现代症状词（如"怕冷""怕风"）字面打不中古文条文 → 得分 0 → 关联不到方剂（即此前"疾病栏/治法栏关联不到医案"的同一根因）。
- 新增 `FormulaMatcher`：在基线匹配上叠加 `oral`/`indicators` 加权命中——`indicators` 权重 0.4、`oral` 权重 0.15，按「、」与句读切分后再匹配，并过滤否定词（"无便秘"不计为"便秘"命中）。

**③ 保障：非劣化不变式**
- 增强分上限 `enhancementCap=0.9` 严格小于 1，数学保证：基线分更高者永远排在前面；语料命中只做"捞回 0 命中方"与"同基线层内重排"，不会改变原有正确排序。

**④ 验证**
- 新增 `test/engine/formula_matcher_test.dart` 7 项全过：数据加载 170 条 / 桂枝汤"特别怕风"现代词 baseline=0 但 enhancement>0（改前打不中、改后能捞回）/ 非劣化不变式。
- `flutter analyze`：L1 新增代码零 error、零 warning（仅历史遗留项）。
- 全量 `flutter test`：195 通过 / 3 失败（3 失败为既有无关模块 minggua / neijing_knowledge / ziwei_reference，与本次零交集）。

**⚠️ 已知问题**
- `lib/data/chinese_convert.dart` 繁简映射表存在缺口（缺 調→调、醬→酱、膠→胶、藶→苈 等），运行时对含这些字的方剂中文匹配会失效；本次以离线补充表规避，源表修复待后续跟进。

---

## [1.11.8+19] - 2026-08-19 — 六经辨证问诊增强（健康人基线 + 寒热真假八维 + 六经公式分型）

**一句话**：基于《命理统一工作台》中医辨证模块（Wsy-prog/tcm-diagnosis-system v3.4，MIT）的对照评估，为 App 问诊补齐 4 项增强——健康人基线判定、寒热真假八维法显式化、六经公式分型速查表、用药铁律展示时机修复。

**背景**
- 用户提供《命理统一工作台.html》，要求评估其「十问诊断」能否提升 App 六经辨证问诊。
- 评估结论：App 引擎深度远超该 HTML（方剂路由 257 方 vs 89、鉴别树 22 族、证据闸、脉舌矛盾、寒热真假引擎均已存在），真正缺失的是 4 个增量点。经用户确认全部实施。

**① 新增：健康人基线判定**
- 倪师六条健康基线：一觉到天亮 / 晨起排便 / 小便淡黄 / 手脚温 / 有胃口 / 精神好。
- `DiagnosticEngine.healthyBaselineOk`：十问信号全部正常 → `true`；问诊直接给出正面反馈「你是正常人」+ 六条逐条 + 养生建议，**不进入异常辨证**。
- `chat_screen._afterTenQuestions` 集成：基线达标 → `_showHealthyBaselineResult()` 早退。

**③ 新增：寒热真假八维法（选填，显式化）**
- 9 条显式线索（面红如妆 / 渴饮即消 / 渴不欲饮喜热饮 / 小便清长 / 小便短赤 / 胸腹久按不蒸手 / 胸腹久按蒸热 / 大便稀溏无灼热 / 大便硬结灼热），十问后可选填、可多选、可跳过。
- `DiagnosticEngine.answerZhenJia(key, label)` 写入 `_answers['zhenjia_*']`；`_detectTrueFalseHeatCold` 扩展读取，强化真寒假热/真热假寒检出（原为脉舌矛盾隐式推断）。

**④ 新增：六经公式分型速查表**
- 新增 `lib/engine/meridian_formula_types.dart`：6 经 × 分型（太阳：中风/伤寒/温病；阳明：经热/腑热；少阳：主证；太阴：脾虚；少阴：寒化/热化；厥阴：寒热错杂/血虚寒厥），各含 核心症状/脉象/治法/代表方/辨证要点。
- 诊断结果详细模式：按主证经渲染「六经公式分型」速查（提纲 + 分型表 + 辨证要点）。

**② 修复：用药铁律展示时机**
- 用药铁律（7 大禁忌 + 5 大误治急救）与汗法禁忌原本只在「详细模式」渲染——安全信息不应被模式开关隐藏，已上移至简单/详细模式均展示（顺带清理 `emergencyTreatment != null` 恒真 warning）。

**验证**
- `dart analyze lib`：0 error（36 条既有 info lint）。
- 新增 `test/questionnaire_enhancement_test.dart` 5 项全过：基线 true/false ×2、真寒假热触发（少阴证 + 面红如妆/小便清长 → 真寒假热）、无异常不触发、分型数据完整性（6 经 ≥9 分型）。
- 全量 `flutter test`：**191 通过 / 3 失败**（3 失败为既有无关模块 minggua/neijing_knowledge/ziwei_reference，与本次零交集）。

**版本**：1.11.7+18 → 1.11.8+19（versionCode 19）。

---

## [1.11.7+18] - 2026-08-19 — 修复医案库「治法」chip 筛选 0 结果

**一句话**：V1.11.6 治法栏点击后显示"共 0 / 1113 例 / 无匹配医案"。根因是 **FormulaRepository 与 screen `_load` 的 race** + **chip 简/繁与 formulaNames 字面不一致**。三件套修复（幂等 load + screen 显式 await + 双侧归一 contains）彻底消除。

**根因诊断**
- 端到端 widget 测试（`tester.tap(find.text('桂枝汤'))`）断言 `filterMedicalCases` 直接调用返 28 正确 → **filter 函数无 bug**。
- test 里手动 `await FormulaRepository.load()` 一切正常；不手动 await（依赖 screen 内部）也能通过 → 真机上 **0 一定是 race**：
  - `extractFormulaNames` 内部用 `FormulaRepository.getAll().map((f) => f.name)` 作 candidates。
  - `MedicalCase.formulaNames` 是 `late final`，**首次访问时被全局 `_formulaNameCache` 永久缓存**。
  - 若 screen `_computeCategories` 首次遍历访问 `c.formulaNames` 时 `FormulaRepository` 仍空 → `candidates` 为空 → `extractKnownNames` 立即返 `const []` 并被永久缓存为 `[]` → `c.formulaNames` 永远为 `[]` → freqF 错算 + filter 全空。
- 即使 race 解除，`filterMedicalCases` 的 `c.formulaNames.contains(formula)` 是**精确字面**比较——若 chip 简/繁与 formulaNames 存字不同（极端字体差异）也会 0 结果。

**修复（3 件套）**
1. `lib/data/formula_repository.dart` — `load()` 改为幂等（`if (_formulas != null) return;`），避免重解析并防止 race 写入。
2. `lib/screens/medical_case_library_screen.dart` — `_load()` 显式 `await FormulaRepository.load(); await HerbRepository.load();`（**不依赖 main 启动时是否 await，双保险**）。
3. `lib/data/medical_case_data.dart` — 新增 `_containsName(names, value)` 私有助手：双侧 `toSimplified` 繁简归一后比较，替换 formula/disease 分支的精确 `contains`。

**验证**
- `dart analyze` 0 error。
- `flutter test test/medical_case_filter_bar_test.dart` 通过（端到端 tap：桂枝汤→28、糖尿病→38，并 baseline=1113/1113）。
- `flutter test test/medical_case_list_golden_test.dart` 通过。

---

## [1.11.6+17] - 2026-08-19 — 医案列表卡片新增西医病名徽标

**一句话**：医案列表卡片新增**西医病名徽标**（最多 3 个，超出折叠为 +N），让「疾病栏」筛出的医案在卡片上即可看到病名命中关系。

**背景**
- 用户反馈：点「疾病栏」某个病名（如 糖尿病 / 高血壓）后，列表卡片只显示中医诊断（"腸癰"等），看不到命中的西医病名（藏在 `western` 长句中），误以为没关联到医案。
- 经临时断言逐 chip 验证：`filterMedicalCases` 与各 chip 频次完全一致（乳癌 112 / 肺癌 82 / 肝癌 63 / 失眠 40 / 糖尿病 38 / 心臟病 37 …），筛选逻辑无问题，是**卡片层缺病名佐证**。

**改动**
- `lib/widgets/medical_case_list_card.dart` 新增 `_diseaseBadges()`：用 `Wrap` 布局展示 `c.diseaseNames`（最多 3 个，次要容器色半透明圆角标签，10.5pt），超出折叠为 +N。
- 位置：插入在患者行下方、`方·药` 行上方。

**验证**
- `dart analyze` 0 error。
- `flutter test test/medical_case_list_golden_test.dart` 重新生成 golden png 覆盖新布局（`test/medical_case_list_light.png`）。
- `flutter test test/medical_case_filter_bar_test.dart` 通过。

---

## [1.11.5+16] - 2026-08-19 — 修复医案库「治法/疾病」筛选栏不显示

**一句话**：V1.11.4 新增的「治法」「疾病」两栏由后台异步预热链计算，部分时机下未完成即刷新，导致页面只显示「年份」「视图」。改为 **`_load()` 内同步计算分类**，确保首帧即有完整筛选行。

**修复内容**
- 分类频次由异步 `_warmCaches()`（分块 `Future(step)` 递归 + 完成后 `setState`）改为 **`_load()` 内同步 `_computeCategories()`**，遍历 1113 例累计方剂名/病名频次后立即写入 `_formulas`/`_diseases`，`FutureBuilder` 首帧即渲染四行筛选。
- 访问 `c.formulaNames` / `c.diseaseNames` 同时填充全局 memo 缓存，**详情秒开不受影响**（V1.11.2 优化保留）。
- 代价：首次进医案库的加载圈多转约 1–3 秒（一次性的索引建立），换取筛选栏 100% 显示。

**回归保障**
- 新增 `test/medical_case_filter_bar_test.dart`：断言「年份/治法/疾病/视图」四行 + 方剂 chips（四逆汤/桂枝汤/其他治法）+ 疾病 chips（乳癌/肺癌/其他疾病）全部渲染。
- 测试环境注记：需在 `runAsync` 内预激活 `rootBundle`（cases_table + FormulaRepository）+ 初始化 `sqflite_common_ffi` 的 `databaseFactoryFfi`，否则测试绑定不驱动 IO。

**验证**：`dart analyze` 0 error；`flutter test test/medical_case_filter_bar_test.dart` 全过。

---

## [1.11.4+15] - 2026-08-19 — 医案库筛选增强：治法栏按经方方剂名、新增疾病栏按西医病名

**一句话**：医案库筛选栏重构——「治法栏」不再按生硬的「中医治疗方法」字段分类，改为按医案内实际出现的**经方方剂名**分类（频次取前 12 + 「其他治法」占位）；并**新增「疾病栏」**，按西医病名（合并抽取 diagnosis + western 字段）分类，未明确西医病名者归入「其他疾病」。

### Added — 医案库筛选
- **治法栏改按方剂名**：`medical_case_library_screen.dart` 后台预热阶段累计 `MedicalCase.formulaNames` 频次，取出现频次最高的前 12 个经方方剂名作为 chip（如四逆汤/桂枝汤/当归四逆汤…）；无方剂名医案归入「其他治法」占位 chip。替代原按 `method`（中医治疗方法）字段的分类（原分类过于稀疏、不可读）。
- **新增疾病栏**：`medical_case_library_screen.dart` 同时累计 `MedicalCase.diseaseNames` 频次，取前 12 个西医病名作为 chip（如乳癌/肺癌/肝癌/糖尿病/心臟病…）；未抽出任何西医病名医案归入「其他疾病」占位 chip。
- **西医病名词典**：新增 `lib/data/disease_repository.dart`（约 150 个正名 + 简体别名归一，如乳腺癌→乳癌、前列腺癌→攝護腺癌），复用 `extractKnownNames` 抽取引擎，从 `diagnosis` 与 `western` 两字段合并抽取西医病名。
- **筛选维度扩展**：`filterMedicalCases` 新增 `formula` / `disease` 两个筛选维度（含 `其他治法` / `其他疾病` 哨兵值），列表筛选与断言复用同一函数；`MedicalCaseFilterBar` 相应增加「疾病」行并改造「治法」行为。

### 验证
- `dart analyze lib`：**0 error**。
- 分布经临时断言验证：治法栏 top12 方剂（四逆汤35/桂枝汤28/当归四逆汤27/射干麻黄汤22/小建中汤22…），疾病栏 top12 病名（乳癌112/肺癌82/肝癌63/失眠40/糖尿病38/心臟病37/血癌34/便秘34/胰臟癌29/腦瘤25/高血壓22/水腫20）；其他治法=776、其他疾病=608（符合「未出现/未明确者归入其他」的预期）。
- `versionName=1.11.4 / versionCode=15`。

---

## [1.11.3+14] - 2026-08-19 — 医案列表白字热修（浅色模式下文字不可读）

**一句话**：修复医案库列表卡片在浅色模式下文字变成白色的致命可读性问题——根因是 `RichText` 未显式设置颜色、不继承 `DefaultTextStyle`，回退为白色；现全部文字显式绑定 `onSurface` / `onSurfaceVariant`，并新增 golden 回归测试防止复发。

### Fixed — 医案库文字颜色
- **列表卡片白字**：`lib/widgets/medical_case_list_card.dart` 标题/诊断/患者/方剂/疗效全部改用显式颜色：标题用 `colorScheme.onSurface`，次要信息用 `onSurfaceVariant`，方药徽标保持 `primary`；不再依赖 `RichText` 的 `DefaultTextStyle` 继承。
- **详情页方剂组成白字**：`lib/widgets/formula_rich_text.dart` 非链接正文同样显式设置 `onSurface`，避免同一根因导致详情页方剂字段在浅色模式下不可读。
- **回归测试**：新增 `test/medical_case_list_golden_test.dart`，渲染 3 条列表卡片并 golden 截图比对；修复前 golden 为白字，修复后 golden 为深色可读文字。

### 验证
- `dart analyze lib`：**0 error**（37 条既有 lint 无新增）。
- Golden 回归：`test/medical_case_list_golden_test.dart` **PASS**（修复前后对比明确）。
- `versionName=1.11.3 / versionCode=14`。

---

## [1.11.2+13] - 2026-08-19 — 医案详情首屏卡顿根治（后台预热 + 异步相关医案）

**一句话**：针对「打开倪师医案详情偶发 ~1s 卡顿」的残留优化——列表加载后后台分块预热方剂/药材索引缓存，详情「相关医案」改为首帧后异步计算，首屏立即可见、不再因全量扫描索引而冻结主线程。

### Changed — 性能（医案模块残留优化）
- **后台预热索引缓存**：`medical_case_library_screen.dart` 新增 `_warmCaches()`，列表解析完成后逐块（60 例/块）触发 `MedicalCase.formulaNames` / `herbNames` 的全局记忆缓存填充，每块间让出事件循环一帧；用户滚动浏览期间静默完成，打开任意详情时相关医案计算命中缓存为近零耗时。
- **详情相关医案异步化**：`medical_case_detail_screen.dart` 移除 `build` 内同步的 `late final _relatedCache = findRelatedCases(...)`，改为 `initState` 后 `_loadRelated()` 异步计算并 `setState` 填充；首屏先渲染正文，`_relatedReady` 就绪后插入相关医案区，彻底消除首屏卡顿。
- 全局记忆缓存（`_formulaNameCache` / `_herbNameCache`）复用机制不变，洞察页 `compute()` 隔离计算路径保留。

### 验证
- `dart analyze lib`：**0 error**（既有 lint info 未新增）。
- `versionName=1.11.2 / versionCode=13`。

---

## [1.11.1+12] - 2026-08-19 — 交互体验修复 · 图标规范（P0-1）· 设计 Token 与深色模式

**一句话**：基于三方专家（前端 / 设计师 / QA）UI 交互审计整改的修复版——底部导航保状态、App 内更新安装修复、命理日期校验、聊天返回栈修复、全站 emoji 图标根治为 Material Icons、39 个语义 Token 落地、深色模式全面修复。

### Fixed — 交互缺陷（第一批 P0，对应审计阻断项）
- **底部导航保状态**：`home_screen.dart:67` `body: _screens[_currentIndex]` → `IndexedStack`，问诊 / 搜索 / 工具页 State 常驻，切 Tab 不再丢进度。
- **App 内更新安装修复**：`app_dialogs.dart:464` 移除幻觉平台方法 `SystemNavigator.open`，改用 `open_filex`（pubspec 新增 `open_filex ^4.7.0`）触发系统安装器；已核验 `REQUEST_INSTALL_PACKAGES` 权限 + FileProvider + `cache-path` 覆盖下载目录。原功能必然安装失败，本次修复。
- **命理日期校验**：`ziwei_chart_screen.dart:56-68` 与 `minggua_calculator_screen.dart:121-134` 新增 `_daysInMonth`（含闰年 `(y%4==0&&y%100!=0)||y%400==0`）+ `_clampDay` 钳制；日下拉按年月动态生成（2 月不再出现 30/31 日），杜绝 AstroDateTime 静默平移错盘。
- **聊天「返回上一步」修复**：`chat_screen.dart:31-42` `_StepSnapshot` 新增 `options` 字段，`_saveSnapshot` / `_goBack` 同步保存恢复选项；十问 / 追问选项 onTap 前均入快照（`:301/:346`），每一步可回退且选项不残留。
- **六经详情死按钮**：`meridian_detail_screen.dart:35` 「六经辨证」IconButton `onPressed: () {}` → `Navigator.push(ChatScreen())`。
- **剂量换算崩溃封堵**：`dosage_converter_screen.dart:79` `!input.isFinite` 守卫，粘贴 `NaN` / `1e309` 不再抛 `UnsupportedError`，统一显示 `—`。

### Changed — 图标规范（P0-1 根治）
- 全站 128 处功能 emoji → Material Icons：问诊按钮（📝→`Icons.edit_note`、⏭️→`Icons.skip_next`、🔄→`Icons.restart_alt`、📤→`Icons.share` 等）加 leading 图标；问诊 Q1-Q12 前缀 emoji 删除，改「1-12」数字徽标（`chat_screen.dart:1033-1047` 22px 圆底 primary + 白数字）。
- 六经图标统一收敛到 `lib/widgets/meridian_icons.dart` 单文件：太阳 `wb_sunny` / 阳明 `local_fire_department` / 少阳 `wb_twilight` / 太阴 `bedtime` / 少阴 `nightlight` / 厥阴 `balance`，knowledge 列表 / 历史头像 / 经络详情共用。
- 数据源清理：`diagnostic_rules.dart:1680-1750` 删除 6 处 `emoji` 数据字段；`models/diagnosis.dart` 删除 `meridianEmoji` getter；`diagnostic_engine.dart` 问诊题面 / 警告前缀 emoji 全删。
- 豁免：`yijing_data.dart` 八卦符（☰☱☲☳☴☵☶☷）为《周易》语义符号非图标，保留并在 README 声明。

### Changed — 设计 Token 与深色模式（P0-3 根治）
- 新增 `lib/theme/app_colors.dart`：`ThemeExtension<AppColors>` **39 个语义 Token**（主色系 #8B4513 品牌棕 / 暖调中性系 / 状态系 danger-warning-success-info 各含 container / 六经 6 色各含 light+dark），`main.dart:41/:49` light/dark 双套挂载。
- 硬编码颜色全量收敛：`withOpacity` 46 处 = 0、`Colors.*.shade(50/100/200)` = 0、`Color(0x` 在 screens/widgets = 0（字面量仅存于 token 文件）；组件统一经 `context.colors` 读取。
- **深色模式修复**：六经 / 状态色深色档自动切换亮 shade，三屏抽查无死白块、无低对比。
- 字号收敛 19 种 → 6 级：`{10,12,14,16,20,28,48}`（displaySymbol 48 仅卦象内容符号）；紫微盘分级（宫名 / 主星 caption12、吉煞杂曜 micro10 + 省略号 + 宫格详情兜底），8px 不可读小字消除。

### 验证
- `dart analyze lib`：**0 error**（41 条 info 全为既有 lint）。
- QA 独立复核 `verdict: pass`，blocking 为空：P0-1 UI 层 emoji **0 命中**（仅豁免八卦符 + 注释 ★）、Token 六项机械门禁全过、第一批 6 项修复代码走查闭环、深色模式三屏抽查通过。
- `versionName=1.11.1 / versionCode=12`。

---

## [1.11.0+11] - 2026-08-18 — 黄帝内经模块 + 附子生炮拆分 + 命理三件套（含闭门课重症 / 医案库）

**一句话**：人纪五部（伤寒 / 金匮 / 针灸 / 本草 / 内经）在 App 内**全部就位**；本草附子按倪师体系拆出生附子 / 炮附子两条独立条目；命理工具再补流年盘、六爻摇卦、八字详批三件；医案库 1257 例检索与方剂双向联动。

### Added — 黄帝内经（人纪最后一块拼图）
- `lib/data/neijing_data.dart`：脏象 12 卡（十二官 / 五行 / 华充窍 / 情志 / 相胜 / 通于 / 倪师要点）+ 望诊五色 5 条（缟裹朱 vs 赭…）+ 眼诊 5 区（瞳孔肾 / 二圈脾 / 三圈肝 / 眼白肺 / 内眦心）+ 脉诊（平人标准 / 脉阴阳 / 8 脉象 / 5 死脉）。
- `lib/screens/neijing_knowledge_screen.dart`：三 Tab（脏象 / 望诊 / 脉诊）；`knowledge_screen.dart` TabController 5→6 增「内经」Tab。
- `tool/split_neijing.py` + `assets/neijing/`：2.3MB 内经文稿按篇切分 **73 篇**（前言 + 素问 72 篇；原稿第 25、66-74 篇未收录，忠于原稿不强补），CRLF→LF、重复标题清洗。
- `lib/screens/neijing_library_screen.dart`：73 篇阅读库，篇目 Card → `MarkdownDocScreen`（linkFormulas 方剂联动）。
- `lib/screens/neijing_search_screen.dart`：全文搜索（懒加载，实测 171ms），命中按次数降序 + 上下文片段（前后各 24 字）。

### Added — 命理三件套（民俗文化参考，非医疗诊断）
- **紫微流年盘**：`ziwei_engine.dart` 新增 `calculateFlowYearMark` 自建 8 流曜查表（流禄存 / 流天魁 / 流天钺 / 流文昌 / 流文曲 / 流擎羊 / 流陀罗 / 流天马，数据源自 ziwei_core 0.13.0 default_jsons，MIT）；盘格前加流年选择条（出生年~当前年+10），流年命宫 primary 高亮 + 流曜行；详情弹层加流年徽标与流曜区。流月盘因 ziwei_core 未暴露 plate 级接口，留待升级。
- **六爻铜钱摇卦**：`yijing_engine.dart` 新增 `castByCoins(List<int>)`（6 个 6/7/8/9，3 字=老阳 9 动 / 2 字=少阳 7 / 1 字=少阴 8 / 3 背=老阴 6 动）；`CastResult` 支持多动爻（`movingLines` + 变卦全翻转），摇卦 UI 6 爻位逐爻摇、第 6 次自动进结果页。
- **八字详批**：`lib/engine/bazi_analysis.dart`（独立文件）移植 tianji（MIT）`web/js/bazi.js` —— 10 神煞（天乙贵人 / 文昌 / 驿马 / 桃花 / 华盖 / 将星 / 天德 / 月德 / 禄神 / 羊刃）+ 建禄 / 羊刃 / 十神格局 + 日主强弱（得令 ±3~-1 + 得地藏干 +0.5/+0.3 + 得势透干 +1.0/+0.7，isStrong≥1.5）+ 五行分布权重（天干 1.0 + 藏干 1.0/0.6/0.4）+ 用神忌神（身强克泄耗 / 身弱生扶）；八字卡加详批卡（格局 chips / 神煞 chips / 五行五格 / 用神忌神 + 建议）。

### Changed — 附子生炮拆分（本草，用户要求「生附子、炒附子在本草里分开」）
- `herbs.json`：原「附子」更名为「炮附子」，前插独立「生附子」条目（本经 + 倪师 commentary 拆分：生附子回阳救逆强心阳、大毒需久煎；炮附子固表温肾阳）。库 464→465。
- `herb_repository.dart _canonicalOf`：附子 / 大附子 → **生附子**；炒附子 / 熟附子 / 制附子 → **炮附子**；生附子 / 炮附子各自精确命中。
- `formulas.json` 泛称附子按炮制显名化（不改映射会新增 7 处错跳）：炮 7 处 → 炮附子（含头风摩散「大附子一枚炮」）、生用 2 处 → 生附子（白通汤 / 白通加猪胆汁汤）、同方异名（桂甘姜枣麻辛附子汤）归一。终态：炮附子 37 / 生附子 16 / 泛称 2（附子散 / 干姜附子粉，倪师外用方未注炮制，按「不注炮者即生用」落生附子）。
- 组成引用 **1663 处：EXACT 1468 / CANON 194 / FUZZY 0 / 死链 1**（五苓散本为方剂非药材，合理降级）。

### Added — 闭门课重症临床模块 + 医案库
- 闭门课重症临床模块 + 倪师医案库 **1257 例检索**，医案 ↔ 方剂双向联动；医案数据清洗（达尔文纪律，出处标注）。
- 闭门课标签 chip 死链修复：新增 `HerbRepository.getExactByName()`（只做正名 + 别名，无模糊兜底），chip 改为**先判本草精确命中 → 再查方剂**；15 个标签 8 → 本草 / 7 → 方剂 / **0 死链**（先查方剂会把「柴胡」错跳到含柴胡的方剂，故顺序不可反；已验证药材名与方剂名零精确同名冲突）。

### Changed — 紫微增强
- `ziwei_engine.dart _starLabelMap` 补 **37 个十二神 key 中文名**（博士 12：博士/力士/青龙/小耗/将军/奏书/飞廉/喜神/病符/大耗/伏兵/官府；岁建 12：岁建/晦气/丧门/贯索/官符/小耗/岁破/大耗/龙德/白虎/天德/吊客/病符；将前 12：将星/攀鞍/岁驿/亡神/华盖/劫煞/灾煞/天煞/指背/咸池/月煞/息神），实测 2000-08-16 盘 12 宫 115 星**全中文、0 英文回退**；盘格补杂星行（fontSize 8，childAspectRatio 0.82→0.72）。
- 输入卡加 **真太阳时开关（默认开）+ 经度输入**（留空 = 120E），`_calculate` 校验经度 -180~180。
- `minggua_engine.dart` 新增 `nayinOf(gan,zhi)`（60 甲子公式 `seq=(g*6-z*5+60)%60`，30 组纳音全覆盖）+ `shiShenOf(dayGan,gan)`（复用 bazi_core `Relationship.getShiShen`）。

### Fixed
- **出生日期上限卡死 2025**：`ziwei_chart_screen.dart` 与 `minggua_calculator_screen.dart` 两处 UI 下拉硬编码 `y<=2025`（引擎为寿星历天文算法，支持 3000+ 年）→ 均改 `y <= DateTime.now().year`，每年自动跟随。

### 验证 / 发布
- `dart analyze`：**0 error**（77 条 info 级 lint 为 Flutter SDK 升级后的 `withOpacity` 弃用等提示，非阻断）。
- 新增测试：`test/year_2026_support_test.dart`（2026 排盘 ×2 + 杂星完整性 ×4 + 十神纳音 ×2）+ `test/neijing_knowledge_test.dart` + `test/neijing_library_search_test.dart`（索引 73 条 + 阅读库冒烟 + 全文搜索冒烟），**三组 ALL PASS**（引擎断言 17/17 等，widget 测试按记忆坑模式 runAsync + pump）。
- P0-1 emoji：本次改动 0 emoji（改动文件扫描通过）。
- 版本：pubspec `1.10.3+10` → `1.11.0+11`（提交 6ee2726）；aapt2 校验 **versionCode=11 / versionName=1.11.0**。
- APK：`flutter build apk --release` 成功（62.7MB 通用包 + arm64-v8a 23.3MB 等分架构包，assembleRelease 158.1s）；apksigner verify 通过（CN=HanTang release 证书），可直接真机安装。

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
- 部署：新建 `release/` + `release/download-page/`（index.html 下载页 + app-release.apk）；CloudStudio 部署下载页（分享链接私下提供，不进 GitHub）。
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
