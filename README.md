# 🏥 汉唐中医 - 倪海厦六经辨证诊断助手

> 基于倪海厦《伤寒论》《金匮要略》教学体系的中医诊断助手，离线可用，完全免费。

[![Release](https://img.shields.io/github/v/release/jangviktor-web/nihaisha-app?label=下载APK)](https://github.com/jangviktor-web/nihaisha-app/releases/latest)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android-lightgrey)]()

**🌐 落地页**: https://jangviktor-web.github.io/nihaisha-app/

---

## ✨ 功能特性

### 🩺 六经辨证智能诊断
通过问诊引导，自动判断太阳/阳明/少阳/太阴/少阴/厥阴六经归属，给出辨证结果、方剂推荐和置信度。

### 📋 完整处方生成
诊断后自动显示方剂组成、剂量、煎服法、禁忌，并根据兼证推荐23条经方加减变化。

### 🔍 鉴别诊断
26对鉴别场景（小柴胡vs大柴胡、四逆vs通脉四逆、麻附细辛vs麻附甘草等），自动对比相似证型的关键区别。

### 📚 方剂药物速查
- **271首经典方剂**：支持搜索、六经筛选、分类筛选
- **345味中药**：支持搜索、分类/性味/归经三筛选
- 完整的方剂详情（组成、剂量、适应证、禁忌）

### 📈 诊断历史趋势
六经传变可视化，自动检测"由表入里"或"由里出表"趋势，追踪健康变化。

### ⏰ 子午流注取穴
输入时间自动推算开穴，辅助针灸取穴决策。

### 🔧 实用工具
- 经方剂量换算器（古代度量衡 → 现代克数）
- 诊断历史趋势图
- 子午流注取穴计算器

---

## 📊 数据规模

| 类别 | 数量 | 说明 |
|------|------|------|
| 方剂 | 271首 | 伤寒论 + 金匮要略 + 倪海厦经验方 |
| 药物 | 345味 | 神农本草经上中下三品 |
| 合病 | 14种 | 太阳+阳明、太阳+少阳、三阳并病等 |
| 鉴别诊断 | 26对 | 覆盖六经主要证型鉴别 |
| 加减法规则 | 23条 | 桂枝汤、小柴胡汤、真武汤等方族 |
| 经络穴位 | 361穴 | 十二正经 + 任督二脉 |

---

## 📱 下载安装

前往 [Releases](https://github.com/jangviktor-web/nihaisha-app/releases/latest) 页面下载最新 APK：

```
nihaisha-v1.3.0-diagnosis-enhanced.apk (51.8MB)
```

支持 Android 6.0+，无需联网，无需注册。

---

## 🏗️ 技术架构

```
lib/
├── engine/           # 诊断引擎
│   ├── diagnostic_engine.dart    # 六经辨证状态机
│   └── diagnostic_rules.dart     # 诊断规则数据
├── models/           # 数据模型
│   ├── diagnosis.dart            # 诊断结果 + 处方模型
│   ├── formula.dart              # 方剂模型
│   └── herb.dart                 # 药物模型
├── data/             # 数据层
│   ├── formula_repository.dart   # 方剂仓库（4级匹配）
│   ├── herb_repository.dart      # 药物仓库
│   └── database_helper.dart      # SQLite 数据库
├── screens/          # 界面
│   ├── chat_screen.dart          # 对话式诊断界面
│   ├── knowledge_screen.dart     # 方剂/药物速查
│   ├── diagnosis_history_screen.dart # 诊断历史趋势
│   └── tools_screen.dart         # 实用工具
└── assets/           # 离线数据
    └── data/
        ├── formulas.json         # 271首方剂数据
        ├── herbs.json            # 345味药物数据
        └── acupoints.json        # 穴位数据
```

**核心技术栈：**
- **Flutter** + **Dart** — 跨平台 UI
- **SQLite** (sqflite) — 本地数据持久化
- **离线优先** — 所有数据本地存储，无需联网
- **Material Design 3** — 现代化 UI 设计

---

## 📖 六经辨证体系

| 经 | 主证 | 主方 | 要点 |
|---|---|---|---|
| ☀️ **太阳** | 脉浮、头项强痛、恶寒 | 桂枝汤 / 麻黄汤 | 表证第一关 |
| 🔥 **阳明** | 但热不寒、胃家实 | 白虎汤 / 承气汤 | 阳明无死证 |
| 🌅 **少阳** | 口苦咽干目眩、往来寒热 | 小柴胡汤 | 半表半里，但见一证便是 |
| 🌙 **太阴** | 腹满吐利、食不下 | 理中汤 / 四逆汤 | 脾虚寒湿 |
| 🌑 **少阴** | 脉微细、但欲寐 | 四逆汤 / 真武汤 | 心肾阳虚，急温之 |
| ☯️ **厥阴** | 消渴、气上撞心、寒热错杂 | 乌梅丸 / 当归四逆汤 | 阴之尽，寒热并结 |

---

## 🔧 开发构建

```bash
# 环境要求
# Flutter 3.x, Dart 3.x, Android SDK

# 获取依赖
flutter pub get

# 调试运行
flutter run

# 构建 Release APK
flutter build apk --release
```

---

## 📚 参考资料

- 倪海厦《人纪》系列 — 伤寒论、金匮要略、黄帝内经、针灸大成、神农本草经
- 张仲景《伤寒论》— 六经辨证体系
- 张仲景《金匮要略》— 杂病辨证
- 《神农本草经》— 药物性味归经

---

## 📄 License

MIT License

---

> 「中医很简单，就是阴阳气血。你搞懂了，一通百通。」—— 倪海厦
