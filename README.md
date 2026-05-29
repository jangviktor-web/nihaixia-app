<div align="center">

🏥 **汉唐中医**

**基于倪海厦六经辨证体系的中医诊断助手**

离线可用 · 完全免费 · 开箱即用

[![Release](https://img.shields.io/github/v/release/jangviktor-web/nihaixia-app?style=for-the-badge&color=green&label=📥%20Download)](https://github.com/jangviktor-web/nihaixia-app/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-6.0+-3DDC84?style=for-the-badge&logo=android&logoColor=white)]()
[![License](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)
[![Stars](https://img.shields.io/github/stars/jangviktor-web/nihaixia-app?style=for-the-badge&color=yellow)](https://github.com/jangviktor-web/nihaixia-app/stargazers)

<br/>

**[🌐 落地页](https://jangviktor-web.github.io/nihaixia-app/)** · **[📥 下载 APK](https://github.com/jangviktor-web/nihaixia-app/releases/latest)** · **[📖 文档](#-技术架构)** · **[🗺️ Roadmap](#️-roadmap)**

</div>

---

## 📷 截图

<div align="center">

| 问诊引导 | 辨证结果 | 处方详情 |
|:---:|:---:|:---:|
| 智能问诊流程 | 六经辨证 + 置信度 | 组成·剂量·煎服法 |
| *选择症状* | *自动判断六经* | *完整处方+加减* |

| 方剂速查 | 药物速查 | 诊断历史 |
|:---:|:---:|:---:|
| 271首经方 | 345味中药 | 六经传变趋势 |
| *搜索+筛选* | *分类/性味/归经* | *可视化追踪* |

</div>

> 截图待补充 — 构建APK后运行截图

---

## ✨ 功能特性

| 功能 | 说明 | 数据规模 |
|:---|:---|:---:|
| 🩺 **六经辨证诊断** | 智能问诊引导，自动判断太阳/阳明/少阳/太阴/少阴/厥阴 | 6经 |
| 📋 **完整处方生成** | 自动显示组成、剂量、煎服法、禁忌，推荐经方加减 | 23条规则 |
| 🔍 **鉴别诊断** | 自动对比相似证型的关键区别，辅助精准辨证 | 26对 |
| 📚 **方剂速查** | 支持搜索、六经筛选、分类筛选，离线查阅 | 271首 |
| 🌿 **药物速查** | 支持搜索、分类/性味/归经三筛选 | 345味 |
| 📈 **诊断历史趋势** | 六经传变可视化，自动检测"由表入里"/"由里出表" | — |
| ⏰ **子午流注取穴** | 输入时间自动推算开穴 | 361穴 |
| 🔧 **经方剂量换算** | 古代度量衡（两/升/铢）→ 现代克数 | — |

---

## 📱 下载安装

```bash
# 方式一：直接下载 APK
# 前往 Releases 页面下载最新版
https://github.com/jangviktor-web/nihaixia-app/releases/latest

# 方式二：从源码构建
git clone https://github.com/jangviktor-web/nihaixia-app.git
cd nihaixia-app
flutter pub get
flutter build apk --release
```

> 支持 Android 6.0+，APK 约 52MB，无需联网，无需注册。

---

## 🏗️ 技术架构

```
lib/
├── engine/                          # 诊断引擎
│   ├── diagnostic_engine.dart       #   六经辨证状态机
│   └── diagnostic_rules.dart        #   诊断规则（合病·鉴别·加减）
├── models/                          # 数据模型
│   ├── diagnosis.dart               #   诊断结果 + 处方 + 加减
│   ├── formula.dart                 #   方剂模型
│   └── herb.dart                    #   药物模型
├── data/                            # 数据层
│   ├── formula_repository.dart      #   方剂仓库（4级匹配策略）
│   ├── herb_repository.dart         #   药物仓库
│   └── database_helper.dart         #   SQLite 持久化
├── screens/                         # UI 界面
│   ├── chat_screen.dart             #   对话式诊断
│   ├── knowledge_screen.dart        #   方剂/药物速查
│   ├── diagnosis_history_screen.dart#   诊断历史趋势
│   └── tools_screen.dart            #   实用工具集
└── assets/data/                     # 离线数据
    ├── formulas.json                #   271首方剂
    ├── herbs.json                   #   345味药物
    └── acupoints.json               #   穴位数据
```

<details>
<summary><b>🔧 核心技术栈</b></summary>

| 层级 | 技术 | 用途 |
|:---|:---|:---|
| UI | Flutter + Material Design 3 | 跨平台界面 |
| 状态 | Stateful Widget | 轻量状态管理 |
| 存储 | SQLite (sqflite) | 本地数据持久化 |
| 数据 | 离线 JSON | 方剂/药物/穴位 |
| 引擎 | 自研 DiagnosticEngine | 六经辨证状态机 |

</details>

<details>
<summary><b>📐 诊断引擎设计</b></summary>

**4级方剂匹配策略：**
1. 精确匹配 `name`
2. 别名匹配 `alias`
3. 斜杠分割匹配（如"小柴胡汤/大柴胡汤"取第一个）
4. 子串匹配（如"桂枝加厚朴杏仁汤"匹配"桂枝汤"）

**合病检测：** 6经评分 → 精确条件匹配 → 方剂覆盖
**鉴别诊断：** 经 + 证型关键词 + 问诊答案 → 26对鉴别

</details>

---

## 📖 六经辨证体系

<div align="center">

| 经 | 主证 | 主方 | 要点 |
|:---:|:---|:---|:---|
| ☀️ **太阳** | 脉浮、头项强痛、恶寒 | 桂枝汤 / 麻黄汤 | 表证第一关 |
| 🔥 **阳明** | 但热不寒、胃家实 | 白虎汤 / 承气汤 | 阳明无死证 |
| 🌅 **少阳** | 口苦咽干目眩、往来寒热 | 小柴胡汤 | 半表半里，但见一证便是 |
| 🌙 **太阴** | 腹满吐利、食不下 | 理中汤 / 四逆汤 | 脾虚寒湿 |
| 🌑 **少阴** | 脉微细、但欲寐 | 四逆汤 / 真武汤 | 心肾阳虚，急温之 |
| ☯️ **厥阴** | 消渴、气上撞心、寒热错杂 | 乌梅丸 / 当归四逆汤 | 阴之尽，寒热并结 |

</div>

---

## 🗺️ Roadmap

- [x] 六经辨证智能诊断
- [x] 完整处方生成（组成+剂量+煎服法+禁忌）
- [x] 经方加减法（23条规则）
- [x] 合病扩展（14种覆盖）
- [x] 鉴别诊断扩展（26对场景）
- [x] 诊断历史趋势图（六经传变可视化）
- [x] 方剂/药物速查增强（搜索+筛选）
- [x] 子午流注取穴计算器
- [x] 经方剂量换算器
- [ ] 舌诊 AI 辅助（TFLite 本地模型）
- [ ] 脉诊辅助（脉象分类）
- [ ] 方剂对比功能
- [ ] 导出 PDF 诊断报告

---

## 📚 参考资料

| 来源 | 内容 |
|:---|:---|
| 倪海厦《人纪》 | 伤寒论、金匮要略、黄帝内经、针灸大成、神农本草经 |
| 张仲景《伤寒论》 | 六经辨证体系 |
| 张仲景《金匮要略》 | 杂病辨证 |
| 《神农本草经》 | 药物性味归经（345种） |

---

## 🤝 Contributing

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'feat: add amazing feature'`)
4. 推送分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

---

## 📄 License

[MIT License](LICENSE) © 2026 jangviktor-web

---

<div align="center">

> 「中医很简单，就是阴阳气血。你搞懂了，一通百通。」—— 倪海厦

**⭐ 如果这个项目对你有帮助，请给个 Star！**

</div>
