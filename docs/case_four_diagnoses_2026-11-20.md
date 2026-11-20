# 医案四诊拆分（2026-11-20）

把「患者口述 / 面诊 / 脉诊」从病机列里拆出来，统一成结构化格式。

## 为什么拆

原表第 5 列叫「中医病因分析（关键病机）」，实际塞着两类完全不同的东西：

- **235 行**整条是 `【主诉】…【问诊】…【脉诊】…【望诊】…`（2026-11-19 回填时把三诊拼进去的）
- **592 行**是纯病机短句（「肝功能未恢复」「乳癌已破口」）

后果：详情页「中医病机」一栏对前 235 行显示成四诊流水账；`llm_service` 只取这列前 40 字当病机，四诊信息全部丢失——而四诊恰恰是「望闻问切」能力的原料。

## 格式规格

新增第 13 列「四诊记录」（加在**末尾**，前 12 列下标全部不变）：

```
【主诉】… 【问诊】… 【望诊】… 【脉诊】…
```

- 顺序固定「主诉 → 问诊 → 望诊 → 脉诊」（望在脉前，合「望闻问切」）
- 段间单空格，不换行（保证一行一记录）
- 源讲义缺哪一段就跳过哪一段，**不补空标签**
- 正文自带的 `【】` 一律转义为 `〔〕`（见下文「坑」）

详情页把这一串拆成四个独立栏：**患者主诉 / 患者口述（问诊）/ 患者面诊（望诊）/ 患者脉诊**，空段自动跳过。

## 覆盖

| 段 | 有内容的行 | 占比（1448 行） |
|---|---|---|
| 主诉 | 822 | 56.8% |
| 问诊 | 789 | 54.5% |
| 望诊 | 697 | 48.1% |
| 脉诊 | 612 | 42.3% |
| **四诊至少一段** | **827** | **57.1%** |

剩下 **621 行四诊列为空**——它们是没有 `<md:N>` 标记的蒸馏稿（「肝功能未恢复」「乳癌已破口」这种两三字病机），源讲义里根本没有对应记录，不是抽取失败。其中 5.5% 的病因分析里提到过「脉」「舌」字样，但都是病机叙述的一部分，拆不出来。

文件：931,943 → **1,220,891 字节**（+288,948，即 827 条四诊正文）。

## 代码触点（13 列是一次结构变更，全部已改）

| 位置 | 改动 |
|---|---|
| `tool/split_case_four_diagnoses.py` | 新增：一次性拆分脚本，带 dry-run / `--apply` / 自检 |
| `tool/fill_medical_cases_from_md.py` | `COLS=13`；`md_to_row` 把四诊写第 13 列、病因分析留空；新增 `scrub_brackets()` |
| `tool/audit_case_integrity.py` | `COLS=13`；空列率统计加「四诊记录」 |
| `tool/audit_duplicate_cases.py` | `COLS=13` |
| `tool/normalize_case_format.py` | 行切分 `len(c)!=15`；列循环 `range(1,14)` |
| `lib/data/medical_case_data.dart` | `MedicalCase.fourDiagnoses` 字段；解析 `13` 列；`_searchNorm` 纳入四诊；`toShareText` 加「四诊」节 |
| `lib/screens/medical_case_detail_screen.dart` | 加 `four(label)` 局部函数 + 四个展示栏 |
| `lib/services/llm_service.dart` | 新增 `_clipFour()` 按段截断；医案块插入「四诊：」字段 |
| `test/medical_case_extract_test.dart` | 新增「四诊列：标签白名单 + 顺序固定」回归测试 |

## 三个坑

1. **正文自带 `【】` 会截断解析。** 源讲义里有 `体内积【水】`、`吃【interferon】`、`Tarceva【Target drug】`、`【瘀血】`、`【不是肺有问题。】`，共 7 处。按 `【标签】([^【]*)` 取段时会在第一个 `【` 处提前收尾，问诊内容被切掉一半。已在 `scrub_brackets()` 里统一转成 `〔〕`——文本保留、强调保留、不再撞标签。新增回归测试会拦住复发。

2. **`<md:N>` 幂等指纹不能碰，新增行必须走同一套列布局。** `md_to_row` 若只改数据不改 `COLS`，`fill` 重跑时会拼出 12 列的行，被体检的「列数不是 13」抓住。改完必须跑一次 `fill` dry-run 确认「回填 0 / 新增 0 / 跳过 891」。

3. **`llm_case_accuracy_test` 的 P3 病机可达率会假跌。** 它用 `c.mechanism` 抽片段判可达，四诊搬走后那 235 行 mechanism 变空、`bits` 恒为空 → 必然计未命中，实测从 94% 掉到 81%。已改为分母只算 `mech.trim().length >= 4` 的样本（`p3n`），修正后 94%（分母 51）。这是口径问题，不是检索退化。

## 验证

- `flutter analyze`：改动的 4 个 dart 文件无问题
- `flutter test`：`medical_case_extract`(5) / `medical_case_insights`(2) / `medical_case_filter_bar`(1) / `medical_case_list_golden`(1) / `llm_case_accuracy`(2) 全绿
- `python tool/audit_case_integrity.py`：`EXIT=0`，13 列对齐、序号/日期/标记全绿、串行 0 项
- `python tool/fill_medical_cases_from_md.py`：回填 0 / 复核 0 / 新增 0 / 跳过 891 / 医案下独有 0
- 回滚：`.workbuddy/backup/20261120_case_md/cases_table.md.before-fourdx`
