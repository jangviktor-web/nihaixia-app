<div align="center">

<img width="120" src="docs/images/logo.jpg" alt="汉唐中医 Logo">

# 汉唐中医 · 倪海厦六经辨证中医诊断助手

**一款离线优先、完全免费的中医经方学习与辅助诊断 App，忠实还原倪海厦人纪体系**

离线可用 · 数据全本地 · 无需注册 · 开箱即用

[![Release](https://img.shields.io/github/v/release/jangviktor-web/nihaixia-app?style=for-the-badge&color=green&label=📥%20Download)](https://github.com/jangviktor-web/nihaixia-app/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-6.0+-3DDC84?style=for-the-badge&logo=android&logoColor=white)]()
[![License](https://img.shields.io/badge/License-Apache%202.0-blue?style=for-the-badge)](LICENSE)
[![Stars](https://img.shields.io/github/stars/jangviktor-web/nihaixia-app?style=for-the-badge&color=yellow)](https://github.com/jangviktor-web/nihaixia-app/stargazers)

<br/>

**[📥 下载 APK](#-下载安装)** · **[📖 快速上手](#-快速上手)** · **[🏗️ 技术架构](#️-技术架构)** · **[🗺️ Roadmap](#️-roadmap)** · **[🤝 贡献指南](#️-贡献指南)** · **[📄 开源许可](#-开源许可)**

</div>

---

## 📖 项目简介

> 「中医很简单，就是阴阳气血。你搞懂了，一通百通。」—— 倪海厦

**汉唐中医** 是一款以倪海厦《人纪》系列（伤寒论、金匮要略、黄帝内经、针灸大成、神农本草经）为理论根基的中医经方辅助工具。它将经典六经辨证体系工程化，帮助你：

- **循证辨证**：以六经为纲，叠加《金匮》证候族鉴别，引导式问诊自动推导证型与主方；
- **即查即用**：方剂、本草、穴位、针灸处方、医案、经典著作全部离线收录，随时随地检索；
- **有据可查**：1257 例倪师医案与方剂双向联动，辨证思路可回溯；
- **素养提升**：黄帝内经知识卡、紫微/易经/四柱等民俗文化工具，构建完整传统文化视野。

### 核心价值主张

| 维度 | 说明 |
|:---|:---|
| 🔒 **离线优先** | 所有知识库打包进 App，无网络也能用，隐私数据不出本机 |
| 📚 **经典还原** | 严格遵循倪师"生附子、炮附子不可取代"等口径，附子按体系拆分，方剂组成零死链 |
| 🧠 **引擎驱动** | 自研六经辨证状态机 + 双轨鉴别树，257 首方剂可达，诊断逻辑可验证 |
| 🆓 **完全免费** | MIT/Apache 双友好协议，无广告、无内购、无追踪 |
| 🧪 **测试守护** | 关键辨证路径与筛选逻辑均有回归测试，修复即写测试，防止复发 |

---

## ✨ 核心功能与特性亮点

| 功能 | 说明 | 数据规模 |
|:---|:---|:---:|
| 🩺 **六经辨证诊断** | 智能问诊引导，自动判断太阳/阳明/少阳/太阴/少阴/厥阴，并支持合病并病 | 6 经 |
| 📋 **完整处方生成** | 自动显示组成、剂量、煎服法、禁忌，推荐经方加减 | 23 条规则 |
| 🔍 **鉴别诊断** | 自动对比相似证型的关键区别，辅助精准辨证 | 26 对 |
| 📚 **方剂速查** | 搜索 + 六经筛选 + 分类筛选，离线查阅 | 322 首 |
| 🌿 **药物速查** | 搜索 + 分类/性味/归经三筛选，覆盖《神农本草经》全量，附子按倪师体系拆分生/炮两条 | 465 味 |
| 📍 **针灸穴位速查** | 十四经脉 + 经外奇穴，含定位/针刺/灸法/禁忌/临床心悟，穴位↔处方双向关联 | 408 穴 |
| 💉 **穴位处方·透针** | 14 类针灸处方（257 条）+ 31 条透针透穴，组成穴可点按跳转 | 14 类 |
| ⏰ **子午流注取穴** | 输入时间自动推算开穴 | 361 穴 |
| 🔧 **经方剂量换算** | 古代度量衡（两/升/铢）→ 现代克数 | — |
| 📖 **黄帝内经** | 脏象 12 卡 + 望诊（五色/眼诊）+ 脉诊（平人/死脉）+ 73 篇阅读库 + 全文搜索 | 73 篇 |
| 📚 **倪师医案库** | 1257 例检索 + 闭门课重症临床模块，医案 ↔ 方剂双向联动 | 1257 例 |
| 🎲 **六爻铜钱摇卦** | 三枚铜钱逐爻摇卦，多动爻自动变卦 | 民俗参考 |
| 📜 **易经六十四卦** | 时间/数字/手选起卦，解本卦·动爻·变卦·互卦，集成人间道 64 卦讲课文稿 | 64 卦 |
| ☯️ **四柱命卦** | 先天/后天卦推算（天地数法），附倪师四柱命卦讲义库 | 64 卦 |
| 🔮 **紫微斗数排盘** | 十二宫/主星/四化/大限/流年盘可视化，杂星全中文，支持真太阳时+经度 | 115 星 |
| 📊 **八字详批** | 神煞/格局/日主强弱/五行分布/用神忌神，一键详批 | 民俗参考 |
| 🔔 **应用内更新** | 设置中一键检测 GitHub 新版本，支持下载安装 | — |
| ⚙️ **诊断设置** | 默认性别/诊断详细度/自动复制处方，个性化问诊体验 | 3 项 |
| 💾 **数据管理** | 清除历史/导出收藏/清理缓存，本地数据完全掌控 | — |

> **特别说明**：紫微斗数、易经、四柱、六爻等模块为**中国传统民俗文化参考**，非医疗诊断用途，与经方医疗模块在界面与文案上清晰分隔。

---

## 📱 下载安装

> **汉唐中医 nihaixia-app**
> 完全离线｜无需联网｜无需注册｜Android 6.0+
> 通用版 APK 约 63MB，arm64-v8a APK 约 24MB

### 📥 方式一：下载预编译 APK（V1.11.8）

| 安装包 | 大小 | 适用说明 |
|---|---|---|
| 通用版 `app-release.apk` | 63MB | 全 CPU 架构，绝大多数安卓设备直接选这个 |
| arm64-v8a `app-arm64-v8a-release.apk` | 24MB | 新款 64 位安卓手机，体积更小 |
| armeabi-v7a `app-armeabi-v7a-release.apk` | 21MB | 老旧 32 位安卓设备 |
| x86_64 `app-x86_64-release.apk` | 25MB | 安卓虚拟机、模拟器使用 |

👉 前往 [GitHub Releases](https://github.com/jangviktor-web/nihaixia-app/releases/latest) 下载对应架构的安装包。

> **V1.11.8 更新要点**：六经辨证问诊四项增强——健康人基线判定、寒热真假八维法、六经公式分型速查、用药铁律展示时机修复（含历史版本的全部筛选与渲染修复）。完整更新记录见 [CHANGELOG.md](CHANGELOG.md)。

### 🔨 方式二：本地从源码构建

需预先配置好 Flutter 开发环境（见[快速上手](#-快速上手)）。

```bash
git clone https://github.com/jangviktor-web/nihaixia-app.git
cd nihaixia-app
flutter pub get
flutter build apk --release
```

构建产物位于 `build/app/outputs/flutter-apk/`。如需分架构构建：

```bash
flutter build apk --release --target-platform android-arm64      # arm64-v8a
flutter build apk --release --target-platform android-arm        # armeabi-v7a
flutter build apk --release --target-platform android-x64        # x86_64
```

---

## 🚀 快速上手

### 环境要求

| 依赖 | 版本要求 | 说明 |
|:---|:---|:---|
| Flutter SDK | ≥ 3.12.0 | 项目 `pubspec.yaml` 指定 |
| Dart SDK | ≥ 3.12.0 | 随 Flutter 一同安装 |
| Android SDK | API 21+（Android 6.0） | 最低运行版本；编译用最新 `compileSdk` |
| 操作系统 | Windows / macOS / Linux | 用于开发构建 |
| 设备/模拟器 | Android 6.0+ | 真机或模拟器运行 |

### 安装步骤

1. **安装 Flutter**：参考 [Flutter 官方安装指南](https://docs.flutter.dev/get-started/install)，并运行 `flutter doctor` 确认环境就绪。
2. **克隆仓库**：
   ```bash
   git clone https://github.com/jangviktor-web/nihaixia-app.git
   cd nihaixia-app
   ```
3. **安装依赖**：
   ```bash
   flutter pub get
   ```
4. **（可选）配置签名**：将发布签名密钥信息填入 `android/key.properties`（参考 `android/key.properties.template`）。调试构建无需此步。

### 运行方法

```bash
# 连接设备或启动模拟器后，以调试模式运行
flutter run

# 运行测试套件
flutter test

# 静态分析
flutter analyze
```

---

## ⚙️ 详细配置选项说明

### 1. 应用内诊断设置（用户侧）

在 App「设置」中可调整：

| 选项 | 说明 |
|:---|:---|
| 默认性别 | 预设男/女/不设置，问诊时自动跳过性别选择 |
| 诊断详细度 | 简单模式（六经/证型/方剂/组成）或详细模式（完整处方、鉴别诊断、脉舌矛盾、用药铁律、汗法禁忌、传经预警、调护建议） |
| 自动复制处方 | 诊断完成时自动复制处方到剪贴板，便于抓药 |
| 暗黑模式 | 跟随系统或手动切换，六经六色与状态色自动适配亮/暗档 |
| 字体大小 | 调整阅读字号 |

### 2. 工程配置（开发者侧）

| 文件 | 作用 |
|:---|:---|
| `pubspec.yaml` | 依赖与资源清单，版本号 `X.Y.Z+N` 的单一来源（`+N` 即 Android `versionCode`） |
| `android/gradle.properties` | Gradle 堆内存等构建参数（Windows 上已设为 `-Xmx1024M` + `org.gradle.daemon=false` 以规避 OOM） |
| `android/key.properties` | 发布签名配置（不入库，参考 template） |
| `assets/data/changelog.json` | 结构化更新日志，驱动「关于」页与更新弹窗 |
| `lib/theme/app_colors.dart` | 39 个语义色 Token（品牌棕/暖调中性/状态色/六经六色），全站硬编码颜色清零 |

**版本号规则**：对外展示采用 `1.11.8` 格式，每次发布自增第三位（patch）；内部 `build` 号 `+N` 单调递增作为 `versionCode`。

---

## 🗂️ 项目目录结构

```
lib/
├── engine/                          # 引擎层（辨证/命理核心逻辑）
│   ├── diagnostic_engine.dart       #   六经辨证状态机
│   ├── diagnostic_rules.dart        #   诊断规则（合病·鉴别·加减）
│   ├── rule_engine.dart             #   规则引擎（双轨鉴别树）
│   ├── formula_rules.dart           #   方剂规则（113 方鉴别）
│   ├── meridian_formula_types.dart  #   六经公式分型（6 经 × 分型）
│   ├── yijing_engine.dart           #   易经六十四卦起卦引擎
│   ├── minggua_engine.dart          #   四柱命卦（先天/后天卦）引擎
│   └── bazi_analysis.dart           #   八字详批（神煞/格局/强弱/用神忌神）
├── models/                          # 数据模型
│   ├── diagnosis.dart               #   诊断结果 + 处方 + 加减
│   ├── formula.dart                 #   方剂模型
│   └── herb.dart                    #   药物模型
├── data/                            # 数据层（仓库 + 离线数据源）
│   ├── formula_repository.dart      #   方剂仓库（4 级匹配策略，幂等加载）
│   ├── herb_repository.dart         #   药物仓库（别名归一）
│   ├── acupoint_repository.dart     #   穴位仓库
│   ├── acupuncture_repository.dart  #   针灸处方仓库
│   ├── disease_repository.dart      #   西医病名词典（约 150 正名 + 简繁别名）
│   ├── medical_case_data.dart       #   倪师医案库（1257 例）
│   ├── neijing_data.dart            #   黄帝内经知识卡
│   ├── yijing_data.dart             #   易经六十四卦数据
│   ├── minggua_data.dart            #   四柱命卦讲义数据
│   ├── changelog_repository.dart    #   更新日志仓库
│   ├── settings_repository.dart     #   设置仓库
│   └── database_helper.dart         #   SQLite 持久化
├── services/                        # 第三方引擎封装 / 服务
│   ├── ziwei_engine.dart            #   紫微斗数排盘引擎封装（ziwei_core）
│   ├── update_service.dart          #   GitHub 版本更新检测
│   └── whats_new_service.dart       #   更新弹窗服务
├── theme/                           # 设计系统
│   └── app_colors.dart              #   39 个语义色 Token
├── widgets/                         # 可复用组件
│   ├── medical_case_list_card.dart  #   医案卡片（含西医病名徽标）
│   └── meridian_icons.dart          #   六经图标统一收敛
├── screens/                         # UI 界面
│   ├── chat_screen.dart             #   对话式诊断
│   ├── knowledge_screen.dart        #   方剂/药物/针灸/内经速查
│   ├── medical_case_library_screen.dart # 医案库（四行筛选）
│   ├── tools_screen.dart            #   实用工具集
│   ├── neijing_*_screen.dart        #   黄帝内经（知识卡/阅读库/搜索）
│   ├── yijing_*_screen.dart         #   易经/四柱命卦
│   ├── ziwei_*_screen.dart          #   紫微斗数排盘/案例
│   └── ...                          #   本草/针灸/子午流注/剂量换算等
└── assets/
    ├── data/                        #   离线 JSON（方剂/药物/穴位/针灸/医案/更新日志）
    ├── yijing/                      #   人间道 64 卦讲课文稿
    ├── yijing_minggua/              #   四柱命卦讲义
    ├── ziwei/                       #   天纪紫微案例 + 十二宫详解
    └── neijing/                     #   黄帝内经阅读库（73 篇）
```

---

## 🏗️ 技术架构

### 核心技术栈

| 层级 | 技术 | 用途 |
|:---|:---|:---|
| UI | Flutter + Material Design 3 | 跨平台界面，六经六色语义化主题 |
| 语言 | Dart 3.x | 强类型，空安全 |
| 状态管理 | StatefulWidget / IndexedStack | 轻量状态管理，Tab 切页保状态 |
| 存储 | SQLite (sqflite) | 本地数据持久化 |
| 数据 | 离线 JSON 资源 | 方剂/药物/穴位/医案/经典著作 |
| 引擎 | 自研 DiagnosticEngine | 六经辨证状态机 + 双轨鉴别树 |
| 命理 | ziwei_core (Dart) | 紫微斗数排盘（纯离线，MIT） |

### 诊断引擎设计

**4 级方剂匹配策略：**
1. 精确匹配 `name`
2. 别名匹配 `alias`
3. 斜杠分割匹配（如"小柴胡汤/大柴胡汤"取第一个）
4. 子串匹配（如"桂枝加厚朴杏仁汤"匹配"桂枝汤"）

**合病检测：** 6 经评分 → 精确条件匹配 → 方剂覆盖
**鉴别诊断：** 经 + 证型关键词 + 问诊答案 → 26 对鉴别
**六经公式分型：** 主证经 → 分型表（太阳：中风/伤寒/温病；阳明：经热/腑热；少阴：寒化/热化；厥阴：寒热错杂/血虚寒厥…），含脉象/治法/代表方/辨证要点。

---

## 📜 六经辨证体系

<div align="center">

| 经 | 主证 | 主方 | 要点 |
|:---:|:---|:---|:---|
| **太阳** | 脉浮、头项强痛、恶寒 | 桂枝汤 / 麻黄汤 | 表证第一关 |
| **阳明** | 但热不寒、胃家实 | 白虎汤 / 承气汤 | 阳明无死证 |
| **少阳** | 口苦咽干目眩、往来寒热 | 小柴胡汤 | 半表半里，但见一证便是 |
| **太阴** | 腹满吐利、食不下 | 理中汤 / 四逆汤 | 脾虚寒湿 |
| **少阴** | 脉微细、但欲寐 | 四逆汤 / 真武汤 | 心肾阳虚，急温之 |
| **厥阴** | 消渴、气上撞心、寒热错杂 | 乌梅丸 / 当归四逆汤 | 阴之尽，寒热并结 |

</div>

---

## 🗺️ Roadmap

- [x] 六经辨证智能诊断
- [x] 完整处方生成（组成+剂量+煎服法+禁忌）
- [x] 经方加减法（23 条规则）
- [x] 合病扩展（14 种覆盖）
- [x] 鉴别诊断扩展（26 对场景）
- [x] 诊断历史趋势图（六经传变可视化）
- [x] 方剂/药物/穴位速查增强（搜索+筛选）
- [x] 子午流注取穴计算器
- [x] 经方剂量换算器
- [x] 应用内更新检测（GitHub Releases）
- [x] 黄帝内经模块（脏象/望诊/脉诊 + 73 篇阅读库 + 全文搜索）
- [x] 附子生炮拆分（生附子/炮附子独立条目，组成引用零死链）
- [x] 倪师医案库 1257 例检索 + 闭门课重症临床模块
- [x] 七步问诊十问模块 v3.1（脉象/疼痛/呕吐类型追问）
- [x] 健康人基线判定 + 寒热真假八维法 + 六经公式分型（V1.11.8）
- [ ] 舌诊 AI 辅助（TFLite 本地模型）
- [ ] 脉诊辅助（脉象分类）
- [ ] 方剂对比功能
- [ ] 导出 PDF 诊断报告

---

## ❓ 常见问题解答（FAQ）

**Q1：App 需要联网吗？**
不需要。所有知识库（方剂、本草、穴位、医案、经典著作）均打包在本地，离线可用。仅"应用内检测更新"功能需要联网访问 GitHub。

**Q2：我的诊断数据安全吗？**
诊断历史、收藏等数据全部存储于本机 SQLite，不上传任何服务器，隐私不出设备。

**Q3：应该下载哪个 APK？**
绝大多数现代手机选 **arm64-v8a**（24MB，体积最小）；拿不准就选 **通用版**（63MB，兼容所有架构）；老旧 32 位设备选 armeabi-v7a；模拟器选 x86_64。

**Q4：紫微/易经/四柱模块是医疗功能吗？**
不是。这些模块为**中国传统民俗文化参考**，与经方医疗模块在界面与文案上明确分隔，不构成任何医疗诊断或建议。

**Q5：附子为什么分"生附子"和"炮附子"？**
遵循倪海厦"生附子是生附子、炮附子是炮附子，不能取代"的严谨口径，App 将其拆分为独立条目，方剂组成 1663 处引用全部精确解析，避免误用。

**Q6：医案库"治法/疾病"筛选是怎么分类的？**
治法栏按医案内实际出现的**经方方剂名**分类（取高频前 12）；疾病栏按**西医病名**分类（经约 150 个正名词典简繁归一抽取）。筛选逻辑均经回归测试守护。

**Q7：如何参与贡献？**
欢迎提交 Issue 与 Pull Request。详见[贡献指南](#️-贡献指南)。

---

## 🤝 贡献指南

感谢你关注汉唐中医！我们欢迎所有形式的高质量贡献。

### 行为准则

请保持友善、专业、就事论事。讨论聚焦经典还原与工程质量，尊重倪海厦学术体系的准确性。

### 代码规范

- 遵循 [Dart Style Guide](https://dart.dev/effective-dart/style) 与 `flutter_lints`；
- 提交前务必运行 `flutter analyze` 与 `flutter test`，确保 **0 error**；
- 关键辨证路径、筛选逻辑、渲染布局的改动**必须**补充/更新回归测试；
- UI 功能图标统一使用 **Material Icons**（唯一例外：八卦符 ☰☱☲☳☴☵☶☷ 为《周易》语义符号，予以保留）；
- 颜色一律通过 `lib/theme/app_colors.dart` 的语义 Token（`context.colors`）引用，禁止硬编码；
- 版本号规则：以 `pubspec.yaml` 的 `version: X.Y.Z+N` 为单一来源，每次发布自增 patch 与 build 号。

### 提交流程

1. Fork 本仓库；
2. 创建特性分支：`git checkout -b feature/amazing-feature`；
3. 提交更改（遵循 Conventional Commits）：`git commit -m 'feat: add amazing feature'`；
4. 推送分支：`git push origin feature/amazing-feature`；
5. 创建 Pull Request，并在描述中说明：改动内容、测试结果、对相关辨证/数据的影响。

### 提交信息规范（Conventional Commits）

| 前缀 | 含义 |
|:---|:---|
| `feat:` | 新功能 |
| `fix:` | 缺陷修复 |
| `docs:` | 文档变更 |
| `refactor:` | 重构（无功能变化） |
| `test:` | 测试相关 |
| `chore:` | 构建/工具链 |

---

## 📄 开源许可

本项目以 **Apache License 2.0** 发布。

- 许可证全文见 [LICENSE](LICENSE)；
- 你可以自由使用、修改、分发本软件，包括商业用途，但须保留版权声明与许可声明，并遵循 Apache 2.0 的条款（含变更说明、通告文件等要求）。

© 2026 jangviktor-web

---

## 📚 参考资料

| 来源 | 内容 |
|:---|:---|
| 倪海厦《人纪》 | 伤寒论、金匮要略、黄帝内经、针灸大成、神农本草经 |
| 张仲景《伤寒论》 | 六经辨证体系 |
| 张仲景《金匮要略》 | 杂病辨证 |
| 《神农本草经》 | 药物性味归经（448 种） |

---

## ⚠️ 免责声明

本 App 为中医经方**学习与辅助参考工具**，所有辨证结果、方剂建议均不可替代执业医师的诊断与治疗。用药请遵医嘱，急重症请立即就医。命理相关模块为民俗文化参考，与医疗无关。

---

## 🌟 Star History

[![RepoStars](https://repostars.dev/api/embed?repo=jangviktor-web%2Fnihaixia-app&theme=grape)](https://repostars.dev/?repos=jangviktor-web%2Fnihaixia-app&theme=grape)

---

<div align="center">

**⭐ 如果这个项目对你有帮助，请给个 Star！**

</div>
