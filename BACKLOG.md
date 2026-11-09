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
