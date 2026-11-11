# 专项 Backlog（既有历史问题，不阻塞 v1.11.19 上线）

> 创建：2026-09-10
> 说明：以下两项测试失败为 **v1.11.19 之前的既有问题**，与本版本改动（内经结构化条目检索 / 深色模式对比度 / 早晚子时×真太阳时校正）无关，不纳入本次修复范围，待后续专项处理。

## 1. `quality_score_bc` — 功能 B 流日命宫 oracle 维度不达标

- **失败点**：`test/quality_score_bc_test.dart` → `功能 B（流月/流日）质量评分 ≥ 90`，关键 oracle 维度
  **B2 流日命宫与引擎 oracle 一致：7.9 分 (5/63)**，要求 ≥ 95。
- **根因**：功能 B（流日）的命宫计算与引擎 oracle 参考集不一致，质量评分门禁未达阈值。
  属功能 B 自身质量问题，**与八字/紫微引擎本次改动无关**。
- **处置**：专项排查流日命宫算法，对齐 oracle；不阻塞本次上线。
  - 🔴 **2026-11-09 复核纠正**：上述判断有误 —— 实测 12 个月样本，
    `fd.mingIndex == engDay.index` 与 `fd.mingIndex == od.index` 均 **12/12 一致**，
    流日命宫算法没问题。失败来自 `quality_score_bc.dart:154` 的干支断言：
    它拿「黄历日干（sxwnl）」去比「斗数流日干（五鼠遁）」，两者本就差一位，
    仅当干恰好相同时命中（约 1/12，实测 1/12）。修法为一行：把
    `dayGz.gan.label` 换成 `engDay.ganzhi.gan.label`，改后 B2 应为 100 分。
    待实施，本文件 §1 的「排查算法」结论作废。
- **关联文件**：`lib/.../flow_day`（流日命宫）、`test/quality_score_bc.dart`（评分口径）。

## 2. `ziwei_bench` — 跨引擎精度比对 30/32

- **失败点**：`test/ziwei_bench_test.dart` → `MingLi-Bench cross-engine comparison`，
  `major 30/32`、`sihua 30/32`、`bazi 29/32`，断言要求 32/32。
- **根因**：与 iztro 参考集的流派约定差（测试文件头已注明 known convention diff）：
  - case_9 [中国]：日柱/时柱差（辛亥→庚戌 / 戊子→丙子），子时边界口径。
  - case_28 [singapore]：日柱/时柱差，真太阳时/地理口径。
  - case_31 [中国]：年柱 立春(本引擎) vs 春节(iztro)。
- **处置**：专项评估——在比对中显式豁免已知约定差（如 case_9/28/31），或将断言从 32 放宽到 30 并补充约定差说明；不阻塞本次上线。
- **关联文件**：`test/data/fortune_api_results.json`（参考集）、`lib/services/ziwei_engine.dart`。

---

## 3. 命理口径可切换（立春 / 春节换年）— 已评估，暂不实施

> 登记：2026-11-09。评估结论如下，**待产品判断后决定是否实施**，当前不动代码。

### 需求

让用户可选八字的换年基准（立春 / 春节）。现状写死立春。

### 现状与工作量

- **已存在 3 个口径开关**（真太阳时 / 早晚子时 / 长生十二神），架构骨架已有，不是从零。
- **唯一缺口是换年基准**：`bazi_core-0.6.7` 内部写死立春
  （`lib/src/models/fortune_table.dart:268 getSpecificJieQi(year, 21)`），无公开参数。
- 年柱是派生链起点：年柱 → 年柱十神 → 大运顺逆 → 起运岁数 → 流年标签 → 生肖。
  **只改年柱显示而不重算大运 = 产生看似正确实则错误的命盘**，不可取。
- 可行路径只有 fork/patch 上游（4–6 人日）或自研四柱核心（20+ 人日）。
  fork 方案还有长期成本：每次上游升级要 rebase。
- 调用面：`computeBaZiPaipan`/`computeBaZiFortune` 共 8 处，分布在 5 个屏
  （八字排盘 / 称骨 / 观砂 / 梅花 / 寿生债）。

### 数据支撑

- ✅ 参考集够硬：`test/data/fortune_api_results.json` 32 例，来源 MingLi-Bench（MIT），
  由 **iztro 预排**（数据内 copyright 字段可查证），含四柱/农历/生肖/紫微六项，可追溯。
- ✅ `case_31`（1988-02-15 台湾）是现成的黄金样本：立春 2/4、春节 2/17，
  iztro 给 `丁卯`（春节换年）＋农历「一九八七年腊月廿八」，两字段自洽；
  本引擎给 `戊辰`（立春）。
- ❌ **立春口径没有外部 oracle**（32 例全是 iztro 口径），自比对不构成验证。
- ❌ 换年边界样本仅 `case_31` 一个，需补每年 2/3–2/20 的边界集（≥12 条），
 期望值须由农历库 + 节气库双路径独立推导，不得用被测引擎生成。
- ❌ 无集中《口径规范》文档：开关清单、默认值、依据出处只散落在代码注释里。

### 若实施：验收基准

1. 春节模式：`case_31` 年柱 `戊辰` → `丁卯`，其余 31 例四柱不变（数据源 iztro 参考集）。
2. 立春模式：32 例与 `bazi_core` 原生输出逐字一致（锁基线快照，仅防回退）。
3. 派生链：大运顺逆（阳男阴女顺排）必须在 `case_31` 上人工核对；生肖跟随年柱变化。
4. `ziwei_bench_test`：春节模式下 major/sihua/bazi 均 32/32；立春模式维持 30/32
   但把 3 例列入 `knownConventionDiff` 显式豁免（附参考值与理由）。

### 建议

**优先做「统一口径 + 显式豁免」（1–2 小时），而不是做开关（4–6 人日）。**
用户真实痛点是「为什么我和别人排出来不一样」，统一默认值比提供开关更能解决。

### 前置项（做开关之前必须先修）

- `useTrueSolarTime` 默认值不统一：`ziwei_engine.dart:426` 为 `true`、
  `ziwei_engine.dart:657` 为 `false`、页面读设置为 `true`，而 `ziwei_bench_test`
  头部注释称「已改为 false 与 iztro 一致」。同一代码库两套默认值，会污染任何口径实验。

---

## 4. pub.dev / GitHub 调研结论 — 暂时不做，下次再说

> 登记：2026-11-09。用户明确指令「暂时不做先记住 下次再说」。**当前不动代码、不动 `pubspec.yaml`**。检索快照日期均为 2026-11-09。

| # | 事项 | 结论与成本 | 主要风险 / 触发条件 |
|---|---|---|---|
| 4.1 | `flutter_markdown` → `flutter_markdown_plus` 迁移 | 现用 `pubspec.yaml:15` 的 `flutter_markdown: ^0.7.0` 已 discontinued（Flutter 团队 2025-02 停用、2025-05 标记），即 `flutter pub get` 报「1 package is discontinued」的来源。接续包 `flutter_markdown_plus` 1.0.12（verified publisher foresightmobile.com，BSD-3，仍在维护），`Markdown` / `MarkdownBody` / `MarkdownStyleSheet` / `onTapLink` / `selectable` 兼容。成本：pubspec 1 行 + 3 处 import（`llm_ask_screen.dart` / `markdown_doc_screen.dart` / `ziwei_doc_screen.dart`）= 4 行 | 资产 grep 无 inline HTML（plus 不支持）→ 零风险；`sizedImageBuilder` 是否保留待实装验证。**依赖迁移与 LLM 功能改动必须分两个 commit**，不在脏工作树里混做 |
| 4.2 | `flutter_opencc_plus` 0.1.4 评估 | 2026-10-05 发布（34 天前），Apache-2.0，0 likes / 155 pts / 697 downloads。同步 `ZhConverter`、流式 `ZhTransformer`、`convertAll` 批量、16 个 OpenCC 1.4.1 配置、`fromConfigName()` 自定义配置；对应「异步闪烁」与「术语白名单」两个障碍 | 🔴 首次构建由 build hook 从 GitHub Release 下载预编译 `.so`（SHA-256 + 持久缓存），与本项目 GitHub 网络反转叠加；0.1.4 早期、原生插件单测不可覆盖。**结论：不换引擎**，方案 A 的同步缓存用现有 `_cache` 扩展即可。仅当确实需要自定义词典时重新评估 |
| 4.3 | 全 App 简繁体可切换 | 已有完整可行性方案（三档 A/B/C）。推荐 **方案 A**：设置页全局开关 + 同步缓存 `tr()` + 内容层全覆盖 + 判定/显示双轨，UI 骨架保持简体。约 30 文件、每处 1–3 行；不引 ARB、不动 `main.dart`、不动索引 | 四个坑：显示串 ≠ 数据键（正名不转）、判定必须用简体（`chat_screen.dart:22` 高危关键词）、异步闪烁、一对多字误转（丑/干/后/耆/蟅）。验收：887 passed / 2 failed 基线不退化 + href 往返 + 繁体搜索命中 |
| 4.4 | `flutter_secure_storage` | 唯一值得考虑的安全改进：LLM API Key 现明文存 SQLite（PRIVACY.md 已写明风险） | 需加平台配置；无实证痛点，等用户定 |

**共同前置**：`lib/screens/llm_ask_screen.dart` + `test/llm_ask_traditional_toggle_test.dart` 的繁体开关改动仍在工作树未提交；重新评估前先确认其状态。

---

## 5. 舌诊模块 — 已评估，暂时不做，下次再说

> 登记：2026-11-09。用户指令「暂时不做，先暂存 下次再说」。**只调研，未改代码、未改依赖、未 commit / 未 stash**。检索快照 2026-11-09。共同前置同 §4（`llm_ask_screen.dart` 繁体开关仍在工作树未提交）。

### 现状：舌诊能力已在引擎里，缺的只是独立入口

| 已有 | 位置 |
|---|---|
| 舌苔 6 / 舌形 7 / 脉 22 选项 | `diagnostic_rules.dart:830-843` |
| 舌象→经络导向权重表 | `diagnostic_rules.dart:886-` |
| `answerTonguePulse()` 写入 `_answers` + 设布尔标志 | `diagnostic_engine.dart:282-327` |
| 舌苔调经络方向 / 太阴核心 / 绛紫舌→血瘀 | `diagnostic_engine.dart:329-350`、`:694`、`:1210` |
| 脉舌矛盾「以舌为准」（真寒假热 / 真热假寒） | `diagnostic_engine.dart:1142-1175`；展示 `chat_screen.dart:574-577` |
| 7 步流程 Step 3 舌诊弹窗（三组 FilterChip） | `chat_screen.dart:137-260` |
| 自查页有意跳过舌脉 | `symptom_check_screen.dart:67-68` |

🔴 缺失：**0 张舌象图资产、0 个舌诊专用测试、`pubspec.yaml` 无任何相机 / 图像 / ML 依赖**。入口现成：`home_screen.dart:55`（ChatScreen 为 tab）、`tools_screen.dart` 中医区卡片列表。

### 三档方案

- **A（推荐，最小）**：把 `chat_screen.dart:160-260` 的弹窗抽成 `widgets/tongue_pulse_picker.dart`（chat_screen 改为调用）；新建 `screens/tongue_reference_screen.dart`，复用同一 picker + **直接读 `tonguePulseWeights` 把「该舌象偏向哪条经」可视化**；`tools_screen.dart` 加一张卡；新增 1 个测试断言 picker 选项 == 引擎 options 且权重表 key 全覆盖。**3 新文件 + 2 处小改、0 新依赖**，不动 `answerTonguePulse` 签名；不新增任何医学结论。
- **B**：加舌象图谱 —— 需图源 / 授权 + 中医核查，图源未解决前不做。
- **C**：拍照 AI 识别 —— 不建议，理由见下（已更正）。

### 外部调研（按 `flutter-research-first` 工作流执行）

- **pub.dev**：`q=tongue diagnosis` / `q=tongue` / `q=tongue model` → **0 个舌诊或舌象模型包**（命中全是图标库 / RDF schema）。通用 CV 可用：`tflite_flutter 0.12.1`（914 likes / 76.3k downloads）、`flutter_litert 3.10.0`、`flutter_vision 3.0.2`（YOLO 分割）、`google_mlkit_selfie_segmentation 1.0.1`（人像分割，非舌体）。
- **GitHub**：iTongue **TOM**（TinyViT 蒸馏，95.22% mIoU，参数比 teacher 少 96.6%，ESWA 2026；桌面工具 macOS DMG 309.33 MiB / Windows EXE 444.89 MiB，**含 Python 运行时，不是模型大小**）、`TongueSAM`（SAM zero-shot，MIT，权重 `tonguesam.pth` 走百度网盘）、`GanonYou/TongueDetection`（OpenCV HSV，55★）、`langjidong/TongueDiagnosis`（YOLOv5+SAM+ResNet50+LLM，AGPL-3.0，Web）、6719 张标注数据集（20 类病理标签，COCO/TXT/XML）。**全部是 Python / PyTorch / Web，无 Flutter SDK、无 TFLite 权重**。
- **模型体积**（通用 CV 参照值，**非舌诊权重实测**；开源舌诊仓库均未公布移动端权重大小）：YOLOv5s TFLite FP32 29.1 MB → INT8 **7.7 MB**（HuggingFace `anan19990108/yolov5s_tflite`，29,120,476 / 7,702,976 字节 + SHA-256，2026-08-18 校验）；ResNet50 97.44 MB → INT8 **≈24.5 MB**（TensorFlow Model Garden 博客 2022-06）；MobileNetV2 13.36 MB → **3–4 MB**；SAM ViT-B **375 MB**、ViT-L 1.25 GB、ViT-H **2.56 GB**、MobileSAM **39 MB**。
- 🔴 **更正上一轮结论**：「几十 MB 模型」是粗略估计，且把次要成本当成了主要成本。完整管线量化版 ≈ 7.7 + 24.5 ≈ **32 MB**，只做 6 苔 / 7 形分类的轻量模型仅 **3–5 MB**（或 ≈15 MB 小 CNN）；对比本项目 arm64 APK 约 36 MB（当初加 OpenCC 也只 +2.11 MiB），**体积不是障碍**。真正障碍是四条：① 现成权重是 `.pth`，需自行转 TFLite 并验证算子（ViT/TinyViT 尤甚）；② 公开数据集标签体系与本项目 6 苔 / 7 形不对齐，映射须中医核查；③ 拍摄光照 / 白平衡 / 角度标准化（TOM 论文列为首要难点）；④ 收益只是替代 13 个 FilterChip，识别结果仍要喂 `answerTonguePulse()`。**方案 A 推荐不变，但否定 C 的理由改为「格式 / 标签 / 标准化 / 收益」，不再是「模型太大」。**

### 红线与验收

- ⛔ 不新增舌象→证候、舌象→方剂映射（须经倪海厦 skill 核查，禁止凭记忆）；独立页只做规则可视化 + 引导问诊，**不出诊断结论、不推荐方剂**；免责声明沿用现有。
- ⛔ 不动 `answerTonguePulse`、不动 Step 3 在 7 步流程中的位置；新页暂不接繁体（§4.3 已定「下次再说」，保持简体）。
- 验收：定向测试（选项一致性 / 权重表覆盖）、`flutter analyze` 0 issue、全量 **887 passed / 2 failed** 基线不退化、Step 3 写入 `_answers` 无回归。

### 重新评估触发条件

用户提供舌象图源与授权 / 明确要求拍照识别 / 提供已转换好的 TFLite 权重与标签映射表。在此之前不启动 B、C。

---

## 附：本版本相关测试状态（校正于 2026-09-07）

- `ziwei_chart`：lunarText 升级为新干支格式后，测试断言已同步 ✅（Task 1）
- `bazi_core_crosscheck` 23:30：**经核查为既有历史问题（非 v1.11.19 回归）**——
  该用例以 `ratHourMode=false` 走「子时归自然日」plain 路径（our 侧 todayGan → `戊午 壬子`），
  但参考侧 `_bc` 用的是 bazi_core **默认 noSplit**（→ `己未 甲子`），两库口径天然差一天而误报。
  基线 306d135 起即如此（bazi_core 版本同为 `^0.6.7`，plain 路径同为 todayGan）。
  修复方式：将测试参考 `_bc` 显式改为 `RatHourMode.todayGan`，与 app 实际口径
  （八字屏/紫微屏统一 todayGan，见 `ziwei_engine.dart:429` 注释）对齐，使交叉验证真正可比。
  **服务层 `bazi_service.dart` 无改动**（HEAD 即正确，与 Task 2 规格一致：effHour 真太阳时先校正 +
  晚子时当日日柱 + 次日子时）。✅
- 说明：此前「bazi_core_crosscheck 为本次回归」的判断有误，特此更正。本版本（v1.11.19）实际
  引入的回归仅 `ziwei_chart` 一处（lunarText 格式断言），已修复。

---

## 6. Web/桌面端界面适配（issue #7）— 首轮已落地，后续可继续

> 登记：2026-11-11。App 本为安卓手机设计，电脑浏览器打开 Web 版时：
> 底部导航贴在整屏最下、内容拉满 1600px 宽、列表每行只有一条、对话框/弹窗也是手机尺寸。

**本轮做法**（不改变手机端观感）：

- `lib/utils/responsive.dart`：断点 840 / 1000（`isWideViewport` / `useSideNav`）+ `PageBody` 限宽容器 + `computeColumns`。
- 首页：≥1000dp 改用左侧常驻导航（`_SideNav`），窄屏仍走原 `NavigationBar`。
- 知识库：≥840dp 把 7 个 tab 换成左侧竖向 tab 列表，正文限宽 1100；方剂/本草列表宽屏双列。
- 工具页：工具卡按可用宽度摊成 2~3 列（`ZoneSection.columns`）。
- 辨证：气泡最大宽度封顶 720，选项由竖排列表改为自动换行 chips。
- 收藏：列表限宽 1100。

**还没做**（下一轮可捡）：

- 详情页（方剂/本草/医案正文）仍是手机排版，宽屏上每行字偏长。
- 宽屏下的鼠标悬停态、右键菜单、快捷键（如 `/` 聚焦搜索、`Esc` 返回）。
- 弹窗 `AlertDialog` 在桌面端仍偏窄，可考虑 max width 覆盖。
