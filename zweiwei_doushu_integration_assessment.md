# 紫微斗数排盘集成可行性评估（达尔文实证评估）

> **评估对象**：`spyfree/iztro-py`（紫微斗数 Python 库）能否集成进 `nihaisha_app`（Flutter/Dart），使 App 支持紫微斗数排盘。
> **方法**：实抽 GitHub / PyPI 源码与依赖清单 + 源码二次核验；对标 Flutter 运行模型；人在回路（评估不改代码，决策权归用户）。
> **日期**：2026-08-16

---

## 一、实证事实（已查，非推测）

### 1. iztro-py 是什么、能做什么
- 纯 Python 紫微斗数（Zi Wei Dou Shu）库，**MIT License**，当前 `v0.5.0`，`requires-python >=3.8`。
- API 形态（GitHub README 实测示例）：
  - `from iztro_py import astro`
  - `chart = astro.by_solar('2000-8-16', 6, '男')` —— 阳历 + 时辰 + 性别排盘
  - 返回 astrolabe 对象：`get_soul_palace()`（命宫）、`major_stars`（主星+亮度庙旺利陷）、`star('ziweiMaj')`（查特定星曜所在宫）、`surrounded_palaces()`（三方四正）
  - 支持 `by_lunar`（农历排盘）、`horoscope()`（大限 / 流年 / 流月 / 流日 / 流时）
  - 六语言输出（zh-CN / zh-TW / en / ja / ko / vi），用 Pydantic 模型封装
- **能力覆盖**：十二宫、主星（十四正曜 + 亮度）、四化飞星、三方四正、流运 —— 即一个完整紫微斗数命盘所需的全部数据。

### 2. 依赖（读 `pyproject.toml` 实证 —— ⚠️ README 表格写"仅标准库"是误导）
runtime dependencies 实测为：
- `pydantic>=2.0.0`
- `python-dateutil>=2.8.0`
- `lunarcalendar>=0.0.9`
- `lunar_python>=1.4.0`   ← 农历 / 闰月 / 节气核心，排盘必须

→ **并非"仅标准库"**，含 4 个第三方硬依赖；其中 `lunar_python` / `lunarcalendar` 承担农历、节气、闰月计算，是排盘准确性的命脉。

### 3. 代码规模（读 GitHub tree 实证）
- `src/` 内 **40 个 `.py`**（34 个实质逻辑），排盘引擎主体约 **24 个文件**：
  - `astro/`（9 文件：astro.py / palace / horoscope / star functional / surpalaces …）
  - `star/`（7 文件：major / minor / adjective / decorative / mutagen / location）
  - `utils/calendar.py`（18KB，农历/节气/公历换算，最大单文件）
  - `data/`（天干地支 / 亮度 / 常量）
- 即一个 **约 2000–3500 行、自包含的传统排盘算法引擎**（安星诀、十二宫排布、四化飞星）。

---

## 二、根本矛盾（对标 Flutter 运行模型）

- **nihaisha_app 是 Flutter / Dart，移动端（Android）没有 Python 运行时。**
- iztro-py 是 Python 库 + 4 个第三方依赖（含农历引擎）。**不能直接 `import` 进 Flutter。**
- 因此「能不能进 app」= 选哪条**集成路径**，而非「能不能用」。

---

## 三、集成路径对比（不靠猜，基于事实）

| 路径 | 做法 | 可行性 | 代价 | 与 app 定位 | 推荐 |
|:---|:---|:---:|:---:|:---:|:---:|
| **A. Dart 移植** | 用 Dart 重写 iztro 排盘引擎（参考 iztro 官方 TS 版更顺手），农历用 Dart `lunar` 包替代 `lunar_python` | 高 | 中（~2000–3500 行 + 准确性验证） | ✅ 纯离线、包体不膨胀、与现有 Dart 架构一致 | ⭐ **推荐** |
| B. 内嵌 Python | `python_ffi` / `dartpython` 打包 Python 解释器 + iztro-py + 4 依赖进 APK | 中 | 高（APK +30~50MB、生命周期对接复杂） | ❌ 当前 APK 54MB「无需联网」定位被翻倍突破 | 不推荐 |
| C. 服务端 API | 后端跑 iztro-py，App 调 REST 接口 | 高 | 中（需运维后端） | ❌ 违背「离线可用 · 无需注册」核心定位 | 不推荐 |
| D. JS 桥接 | 用 iztro JS 版 + `flutter_js` / webview 跑 | 中 | 高 | ❌ 复杂度高、移动端 JS 性能/体积问题 | 不推荐 |

→ **结论：技术上完全能做；最干净是路径 A（Dart 移植成独立工具模块）。**

---

## 四、与 app 定位契合度（需用户拍板）

- 汉唐中医 app 定位：倪海厦六经辨证**中医诊断**助手。
- 紫微斗数 = 命理学，**不是中医诊断**。混进诊断流程概念分裂。
- 但可文化衔接：倪师本人重「生辰命理」；中医有「五运六气 / 子午流注」时间医学传统。建议作为 app 内**独立工具模块**（与现有「子午流注取穴」「经方剂量换算」并列于 `tools_screen.dart`），并明确标注「民俗文化参考，非医疗诊断」。
- 这样既不破坏中医诊断主线，又满足「App 可用紫微斗数排盘」的诉求。

---

## 五、未确认项（达尔文：不靠猜，显式标注）

1. **准确性基准**：移植后须用同生辰对照权威排盘工具（如 ziwei.pub）做回归验证 —— 农历 / 节气边界（闰月、节气交接时刻）是排盘错漏高发区，错盘 = 误导。
2. **`lunar_python` 是否含原生 C 扩展**：影响路径 B 可行性，但路径 A 用 Dart `lunar` 包替代、不相关。
3. **Dart `lunar` 包 License**：移植代码须保留 iztro MIT 版权声明；所选 Dart 农历依赖需查许可兼容（MIT/Apache 为宜）。
4. **用户是否接受「独立工具」定位**：还是希望更深整合进诊断。

---

## 六、🔴 CHECKPOINT · 待你决策（人在回路）

本报告仅评估，**未改动 app 任何代码**。请选择：

- **A（推荐）**：Dart 移植 iztro 排盘引擎 → 新增「紫微斗数排盘」工具模块 → 升 `v1.10.2`。我规划任务、建分支、移植 + 准确性回归测试。
- **B / C / D**：进一步讨论取舍。
- **不做**：放弃（认为定位冲突）。
