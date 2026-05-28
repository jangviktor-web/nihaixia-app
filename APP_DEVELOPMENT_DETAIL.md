# 汉唐中医 App 开发详细文档

> 最后更新：2026-05-26
> 当前版本：v1.2.0+1 (pubspec) / v1.0.4 (APK)
> 总计：23个 Dart 源文件，5个 JSON 数据文件，257条穴位处方+31条透针透穴+379个穴位详情+271个方剂+440味本草

---

## 1. 项目结构

```
nihaisha_app/
├── android/                          # Android 平台文件
├── assets/
│   ├── SKILL.md                      # 倪海厦 skill 描述文件 (~831 KB)
│   └── data/
│       ├── acupoints.json            # 379 个穴位详情
│       ├── acupuncture.json          # 257 条穴位处方 + 31 条透针透穴
│       ├── formulas.json             # 271 个方剂
│       ├── herbs.json                # 440 味本草
│       └── prescriptions.json        # 54 条系统处方（10分类，已合并到acupuncture.json）
├── lib/
│   ├── main.dart                     # App 入口
│   ├── data/                         # 数据层（5个文件）
│   │   ├── acupoint_repository.dart
│   │   ├── acupuncture_repository.dart
│   │   ├── database_helper.dart
│   │   ├── formula_repository.dart
│   │   └── herb_repository.dart
│   ├── engine/                       # 诊断引擎（2个文件）
│   │   ├── diagnostic_engine.dart
│   │   └── diagnostic_rules.dart
│   ├── models/                       # 数据模型（6个文件）
│   │   ├── acupoint_detail.dart
│   │   ├── acupuncture.dart
│   │   ├── bookmark.dart
│   │   ├── diagnosis.dart
│   │   ├── formula.dart
│   │   └── herb.dart
│   └── screens/                      # UI 界面（9个文件）
│       ├── acupoint_detail_screen.dart
│       ├── acupuncture_screen.dart
│       ├── bookmarks_screen.dart
│       ├── chat_screen.dart
│       ├── formula_detail_screen.dart
│       ├── herb_detail_screen.dart
│       ├── home_screen.dart
│       ├── knowledge_screen.dart
│       └── meridian_detail_screen.dart
├── scripts/                          # 20个 Python 数据处理脚本
├── test/
│   └── widget_test.dart
├── tools/
│   └── parse_herbs.py
├── pubspec.yaml
├── pubspec.lock
├── analysis_options.yaml
└── README.md
```

---

## 2. 依赖配置 (pubspec.yaml)

- **App 名称:** `nihaisha_app`
- **描述:** 汉唐中医 - 倪海厦六经辨证中医诊断助手
- **版本:** `1.2.0+1`
- **publish_to:** `'none'`
- **SDK 约束:** `^3.12.0`

### 依赖包

| 包名 | 版本 | 用途 |
|------|------|------|
| flutter (SDK) | -- | Flutter 框架 |
| cupertino_icons | ^1.0.8 | iOS 风格图标 |
| flutter_markdown | ^0.7.0 | Markdown 渲染 |
| sqflite | ^2.4.2 | SQLite 本地数据库 |
| path_provider | ^2.1.5 | 文件路径获取 |
| path | ^1.9.1 | 路径操作 |

### 注册资产

1. `assets/SKILL.md`
2. `assets/data/formulas.json`
3. `assets/data/herbs.json`
4. `assets/data/acupuncture.json`
5. `assets/data/acupoints.json`
6. `assets/data/prescriptions.json`（已合并到 acupuncture.json，但资产声明保留）

---

## 3. 所有 Dart 源文件

### 数据层 (`lib/data/`)

| 文件 | 说明 |
|------|------|
| `acupoint_repository.dart` | 加载 acupoints.json；提供 getAll、findByName、search、getMeridians、getByMeridian、count |
| `acupuncture_repository.dart` | 加载 acupuncture.json；提供 getAll、getEntries、getByCategory、getCategories、getPenetrations、search、searchPenetrations |
| `database_helper.dart` | 单例 SQLite；创建 bookmarks 和 chat_history 表；CRUD 操作 |
| `formula_repository.dart` | 加载 formulas.json；提供 getAll、getById、getByName、search、getByMeridian、getByCategory、getCategories |
| `herb_repository.dart` | 加载 herbs.json；提供 getAll、getByCategory、search、getByName（含别名映射+模糊匹配）、getCategories、getNatureCategories、getByNature |

### 诊断引擎 (`lib/engine/`)

| 文件 | 说明 |
|------|------|
| `diagnostic_engine.dart` | 有状态诊断引擎，实现多步骤聊天诊断流程：主诉 → 温度模式 → 十问 → 经络定位 → 追问 → 结果 |
| `diagnostic_rules.dart` | 全部静态诊断数据：25种主诉、5种温度模式、10个问题（倪海厦十问）、各经络追问、六经详情（症状/方剂/传变/经典原文/倪注）、快速诊断映射 |

### 数据模型 (`lib/models/`)

| 文件 | 说明 |
|------|------|
| `acupoint_detail.dart` | `AcupointDetail` — 穴位完整参考数据 |
| `acupuncture.dart` | 四个模型：`Acupoint`、`AcupointEntry`、`AcupunctureCategory`、`PenetrationEntry` |
| `bookmark.dart` | `Bookmark` — SQLite 收藏条目 |
| `diagnosis.dart` | `DiagnosisResult` + `DiagnosticStage` 枚举 |
| `formula.dart` | `Formula` + `FormulaComponent` |
| `herb.dart` | `Herb` |

### UI 界面 (`lib/screens/`)

| 文件 | 说明 |
|------|------|
| `acupoint_detail_screen.dart` | 穴位详情页 |
| `acupuncture_screen.dart` | 针灸浏览（3个子Tab） |
| `bookmarks_screen.dart` | 收藏管理 |
| `chat_screen.dart` | 对话式诊断界面 |
| `formula_detail_screen.dart` | 方剂详情页 |
| `herb_detail_screen.dart` | 本草详情页 |
| `home_screen.dart` | 主页底部导航 |
| `knowledge_screen.dart` | 知识库（5个Tab） |
| `meridian_detail_screen.dart` | 经络详情页 |

---

## 4. JSON 数据文件详情

### 4.1 formulas.json — 271 个方剂

```json
{
  "formulas": [
    {
      "id": "001",
      "name": "桂枝汤",
      "alias": "阳旦汤",
      "meridian": "太阳",
      "category": "解表",
      "components": [
        {"name": "桂枝", "dosage": "三两", "role": "君"},
        ...
      ],
      "indication": "...",
      "contraindication": "...",
      "dosage": "...",
      "preparation": "...",
      "explanation": "...",
      "keywords": [...]
    }
  ]
}
```

### 4.2 herbs.json — 440 味本草

```json
{
  "herbs": [
    {
      "name": "牡桂",
      "original": "味辛温...",
      "nature": "温",
      "action": "补元阳...",
      "rongchuan": "...",
      "niNote": "...",
      "dosage": "...",
      "contraindication": "...",
      "clinicalNotes": "...",
      "historicalNotes": "...",
      "herbComparisons": [...],
      "natureCategory": "温",
      "flavor": "辛",
      "meridians": ["心", "肝"],
      "category": "解表药"
    }
  ]
}
```

### 4.3 acupuncture.json — 257 条穴位处方 + 31 条透针透穴

```json
{
  "acupuncture": {
    "categories": [
      {
        "id": "01",
        "name": "心·心血管",
        "entries": [
          {
            "id": 1,
            "symptom": "冠心病",
            "aliases": [],
            "acupoints": [
              {"name": "关元", "method": null},
              {"name": "巨阙", "method": null}
            ],
            "notes": "",
            "medicalCase": "",
            "source": "nihaisha"
          }
        ]
      }
    ]
  },
  "penetration": [
    {
      "id": 1,
      "name": "中府透云门",
      "indications": ["咳嗽", "气喘", "哮喘", "肺癌"],
      "source": "倪海厦透针，再配穴孔最、公孙、内关以加强效果",
      "clinicalInsight": "",
      "medicalCase": ""
    }
  ]
}
```

**14个分类及条目数：**

| 分类 | 条目数 |
|------|--------|
| 心·心血管 | 7 |
| 肝胆·消化 | 23 |
| 肺·呼吸 | 10 |
| 肾·泌尿 | 15 |
| 妇科 | 30 |
| 神志·神经 | 14 |
| 伤痛·骨科 | 53 |
| 头面·五官 | 55 |
| 皮肤 | 18 |
| 代谢·内分泌 | 7 |
| 急救 | 13 |
| 疑难杂症 | 4 |
| 生活·保健 | 5 |
| 儿科 | 3 |

**source 字段说明：**
- `nihaisha` — 倪海厦临床经验处方（橙色标签显示）
- `system` — 系统处方（蓝色标签显示）

### 4.4 acupoints.json — 379 个穴位详情

```json
{
  "acupoints": [
    {
      "name": "中府",
      "meridian": "手太阴肺经",
      "attribute": "募穴",
      "description": "...",
      "location": "...",
      "needling": "...",
      "moxibustion": "...",
      "contraindication": "...",
      "clinicalNotes": "..."
    }
  ]
}
```

### 4.5 prescriptions.json — 54 条系统处方（已合并）

此文件已合并到 `acupuncture.json` 中（source='system'），Dart 代码不再直接使用此文件，但 pubspec.yaml 中的资产声明保留。

---

## 5. 数据模型详情

### 5.1 Herb — 本草

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `name` | `String` | required | 药名 |
| `original` | `String?` | null | 本经原文 |
| `nature` | `String?` | null | 性味 |
| `action` | `String?` | null | 功效 |
| `rongchuan` | `String?` | null | 容川注解 |
| `niNote` | `String?` | null | 倪海厦注 |
| `dosage` | `String?` | null | 用量 |
| `contraindication` | `String?` | null | 禁忌 |
| `clinicalNotes` | `String?` | null | 临床心得 |
| `historicalNotes` | `String?` | null | 历史典故 |
| `herbComparisons` | `List<String>` | `[]` | 药物对比 |
| `natureCategory` | `String` | `'平'` | 四气分类（寒/凉/平/温/热） |
| `flavor` | `String` | `''` | 五味 |
| `meridians` | `List<String>` | `[]` | 归经 |
| `category` | `String` | `'其他'` | 药物分类 |

**计算属性：**
- `natureEmoji` → 根据 natureCategory 返回温度 emoji
- `hasDetailedInfo` → 是否有详细信息

### 5.2 Formula — 方剂

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `id` | `String` | required | ID |
| `name` | `String` | required | 方名 |
| `alias` | `String` | `''` | 别名 |
| `meridian` | `String` | required | 所属经络 |
| `category` | `String` | required | 分类 |
| `components` | `List<FormulaComponent>` | required | 组成药物 |
| `indication` | `String` | required | 主治 |
| `contraindication` | `String` | `''` | 禁忌 |
| `dosage` | `String` | `''` | 用量 |
| `preparation` | `String` | `''` | 煎服法 |
| `explanation` | `String` | `''` | 倪海厦解读 |
| `keywords` | `List<String>` | `[]` | 关键词 |

**FormulaComponent 子对象：**
- `name` (String) — 药名
- `dosage` (String) — 用量
- `role` (String) — 角色（君/臣/佐/使）

### 5.3 Acupuncture — 针灸相关

**Acupoint（穴位）：**
- `name` (String) — 穴位名
- `method` (String?) — 操作方式（null/灸/放血/对侧等）

**AcupointEntry（穴位处方条目）：**
- `id` (int) — 编号
- `symptom` (String) — 症状/病症名
- `aliases` (List<String>) — 别名
- `acupoints` (List<Acupoint>) — 穴位列表
- `notes` (String) — 备注
- `medicalCase` (String) — 医案
- `source` (String) — 来源（'nihaisha' 或 'system'）

**计算属性：**
- `acupointsText` → 穴位名文本（含操作方式）
- `hasCase` → 是否有医案
- `sourceLabel` → 显示用来源标签

**AcupunctureCategory（针灸分类）：**
- `id` (String) — 分类 ID
- `name` (String) — 分类名
- `entries` (List<AcupointEntry>) — 分类内条目

**PenetrationEntry（透针透穴条目）：**
- `id` (int) — 编号
- `name` (String) — 透穴名（如"中府透云门"）
- `indications` (List<String>) — 适应症
- `source` (String) — 来源
- `clinicalInsight` (String) — 临证心悟
- `medicalCase` (String) — 医案

### 5.4 AcupointDetail — 穴位详情

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `name` | `String` | required | 穴位名 |
| `meridian` | `String` | `''` | 所属经络 |
| `attribute` | `String` | `''` | 穴性（如"募穴"） |
| `description` | `String` | `''` | 描述 |
| `location` | `String` | `''` | 定位 |
| `needling` | `String` | `''` | 针法 |
| `moxibustion` | `String` | `''` | 灸法 |
| `contraindication` | `String` | `''` | 禁忌 |
| `clinicalNotes` | `String` | `''` | 临床心得 |

### 5.5 DiagnosisResult — 诊断结果

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `meridian` | `String` | required | 所属经络 |
| `pattern` | `String` | required | 证型 |
| `patternDetail` | `String` | `''` | 证型详情 |
| `formula` | `String` | required | 推荐方剂 |
| `explanation` | `String` | `''` | 解释说明 |
| `confidence` | `double` | `1.0` | 置信度 |
| `matchedSymptoms` | `List<String>` | `[]` | 匹配症状 |
| `followUpQuestions` | `List<String>` | `[]` | 追问问题 |
| `combinedMeridian` | `String?` | null | 合病经络 |

**DiagnosticStage 枚举值：**
`chiefComplaint` → `temperaturePattern` → `tenQuestions` → `meridianLocation` → `formulaConfirmation` → `result`

### 5.6 Bookmark — 收藏

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `id` | `int?` | null | 自增主键 |
| `title` | `String` | required | 标题 |
| `content` | `String` | required | 内容 |
| `category` | `String` | required | 分类 |
| `source` | `String` | required | 来源 |
| `createdAt` | `DateTime` | `DateTime.now()` | 创建时间 |

---

## 6. 仓库类方法签名

### 6.1 HerbRepository

| 方法 | 签名 | 说明 |
|------|------|------|
| `load()` | `static Future<void> load()` | 加载 herbs.json |
| `getAll()` | `static List<Herb> getAll()` | 返回全部本草 |
| `getByCategory()` | `static List<Herb> getByCategory(String category)` | 按分类筛选 |
| `search()` | `static List<Herb> search(String query)` | 搜索 name/action/nature/original/flavor/category/meridians |
| `getByName()` | `static Herb? getByName(String name)` | 直接匹配 → 别名映射 → 模糊匹配 |
| `getCategories()` | `static List<String> getCategories()` | 返回分类列表 |
| `getNatureCategories()` | `static List<String> getNatureCategories()` | 返回 ['全部','寒','凉','平','温','热'] |
| `getByNature()` | `static List<Herb> getByNature(String nature)` | 按四气筛选 |

**别名映射：** 内置 18 组现代药名→经典药名映射（如 '桂枝'→'牡桂'）

### 6.2 FormulaRepository

| 方法 | 签名 | 说明 |
|------|------|------|
| `load()` | `static Future<void> load()` | 加载 formulas.json |
| `getAll()` | `static List<Formula> getAll()` | 返回全部方剂 |
| `getById()` | `static Formula? getById(String id)` | 按 ID 精确查找 |
| `getByName()` | `static Formula? getByName(String name)` | 双向包含匹配 |
| `search()` | `static List<Formula> search(String query)` | 搜索 name/indication/keywords/components |
| `getByMeridian()` | `static List<Formula> getByMeridian(String meridian)` | 按经络筛选 |
| `getByCategory()` | `static List<Formula> getByCategory(String category)` | 按分类筛选 |
| `getCategories()` | `static List<String> getCategories()` | 返回分类列表 |

### 6.3 AcupunctureRepository

| 方法 | 签名 | 说明 |
|------|------|------|
| `load()` | `static Future<void> load()` | 加载 acupuncture.json（含穴位处方+透针透穴） |
| `getAll()` | `static List<AcupunctureCategory> getAll()` | 返回全部分类 |
| `getEntries()` | `static List<AcupointEntry> getEntries()` | 展平所有条目 |
| `getByCategory()` | `static List<AcupointEntry> getByCategory(String categoryName)` | 按分类筛选 |
| `getCategories()` | `static List<String> getCategories()` | 返回分类名列表 |
| `getPenetrations()` | `static List<PenetrationEntry> getPenetrations()` | 返回全部透针透穴 |
| `search()` | `static List<AcupointEntry> search(String query)` | 搜索 symptom/aliases/acupoints.name |
| `searchPenetrations()` | `static List<PenetrationEntry> searchPenetrations(String query)` | 搜索透穴名/适应症 |

### 6.4 AcupointRepository

| 方法 | 签名 | 说明 |
|------|------|------|
| `load()` | `static Future<void> load()` | 加载 acupoints.json |
| `getAll()` | `static List<AcupointDetail> getAll()` | 返回全部穴位 |
| `findByName()` | `static AcupointDetail? findByName(String name)` | 精确匹配 + 去"穴"后缀重试 |
| `search()` | `static List<AcupointDetail> search(String query)` | 搜索 name/meridian/description/location/clinicalNotes |
| `getMeridians()` | `static List<String> getMeridians()` | 返回去重排序经络名 |
| `getByMeridian()` | `static List<AcupointDetail> getByMeridian(String meridian)` | 按经络筛选 |
| `count` | `static int get count` | 穴位总数 |

### 6.5 DatabaseHelper

**SQLite 数据库：** `nihaisha.db`

**表结构：**
- `bookmarks`: id (INTEGER PK AUTOINCREMENT), title, content, category, source, created_at
- `chat_history`: id (INTEGER PK AUTOINCREMENT), text, is_user (INTEGER), timestamp

| 方法 | 签名 | 说明 |
|------|------|------|
| `database` | `Future<Database> get database` | 懒初始化数据库 |
| `insertBookmark()` | `Future<int> insertBookmark(Bookmark bookmark)` | 插入收藏 |
| `getAllBookmarks()` | `Future<List<Bookmark>> getAllBookmarks()` | 按创建时间倒序返回全部收藏 |
| `getBookmarksByCategory()` | `Future<List<Bookmark>> getBookmarksByCategory(String category)` | 按分类筛选收藏 |
| `deleteBookmark()` | `Future<int> deleteBookmark(int id)` | 按 ID 删除 |
| `isBookmarked()` | `Future<bool> isBookmarked(String title)` | 检查是否已收藏 |
| `saveChatMessage()` | `Future<void> saveChatMessage(String text, bool isUser)` | 保存聊天消息 |
| `clearChatHistory()` | `Future<void> clearChatHistory()` | 清空聊天记录 |

**注意：** `saveChatMessage` 和 `clearChatHistory` 已定义但当前代码中未被调用。

---

## 7. 界面结构详情

### 7.1 HomeScreen — 主页底部导航

底部 NavigationBar 共 3 个导航项：

| 索引 | 标签 | 图标 | 跳转 |
|------|------|------|------|
| 0 | 辨证 | chat_bubble | ChatScreen |
| 1 | 知识库 | menu_book | KnowledgeScreen |
| 2 | 收藏 | bookmark | BookmarksScreen |

### 7.2 ChatScreen — 对话式诊断

- AppBar 标题："六经辨证" + 刷新按钮
- 驱动 DiagnosticEngine 进行多步骤对话诊断
- 流程：主诉选择 → 温度模式 → 十问 → 追问 → 结果展示
- 结果显示：经络、证型、推荐方剂、组成、说明
- 支持收藏诊断结果

**内部辅助类：** `_ChatBubble`（聊天气泡）、`_ChatOption`（选项按钮）

### 7.3 KnowledgeScreen — 知识库

AppBar 标题："知识库"，共 **5 个 Tab**：

| Tab | 标签 | 组件 | 说明 |
|-----|------|------|------|
| 0 | 六经 | `_MeridianTab` | 6条经络（太阳/阳明/少阳/太阴/少阴/厥阴）展开卡片，含症状/方剂/跳转详情 |
| 1 | 方剂 | `_FormulaTab` | 可过滤方剂列表（7个经络筛选 + 18个分类筛选）+ 计数显示 |
| 2 | 本草 | `_HerbTab` | 可过滤本草列表（分类筛选 + 四气/经络筛选）+ 计数显示 |
| 3 | 针灸 | `AcupunctureScreen` | 3个子Tab（见下文） |
| 4 | 搜索 | `_SearchTab` | 跨域搜索（2个子Tab） |

**_SearchTab 内部子Tab：**

| 子Tab | 标签 | 搜索范围 |
|-------|------|----------|
| 0 | 方剂·本草 | 方剂 + 本草（联合搜索） |
| 1 | 针灸 | 穴位处方 + 穴位详情 |

### 7.4 AcupunctureScreen — 针灸浏览

共 **3 个 Tab**：

| Tab | 标签 | 说明 |
|-----|------|------|
| 0 | 穴位处方 | 14个分类过滤 + 搜索；可展开卡片：症状名 + 穴位列表（可点击跳转穴位详情）+ 来源标签（倪海厦经验=橙色 / 系统配方=蓝色）+ 医案 |
| 1 | 透针透穴 | 搜索；可展开卡片：透穴名 + 穴位chip（可点击跳转详情）+ 适应症 + 来源 + 临证心悟 + 医案 |
| 2 | 穴位讲解 | 379个穴位浏览；经络过滤 + 搜索；点击跳转 AcupointDetailScreen |

**透穴名解析逻辑：** "中府透云门" → 提取 ["中府", "云门"]，分别生成可点击的穴位 chip

### 7.5 BookmarksScreen — 收藏

- AppBar 标题："收藏"
- 水平滚动过滤芯片（按收藏分类筛选）
- 支持删除确认弹窗和详情弹窗
- 空状态引导文案

### 7.6 FormulaDetailScreen — 方剂详情

- 标题卡片（方名、别名、经络标签、分类标签）
- 组成药物列表（每个药名可点击跳转本草详情）
- 主治、禁忌、用量/煎服法
- 倪海厦解读
- AppBar 支持收藏切换

### 7.7 HerbDetailScreen — 本草详情

- 标题卡片（药名、分类、五味、归经）
- 完整信息：性味、功效、本经原文、倪注、容川注、用量、禁忌（警告样式）、临床心得（高亮样式）、历史典故
- 药物对比
- 关联方剂（反向查询所有含此药的方剂）
- AppBar 支持收藏切换 + 性味 emoji

### 7.8 AcupointDetailScreen — 穴位详情

- 穴性 chip
- 描述、定位、针法、灸法
- 禁忌（警告样式）
- 临床心得（高亮样式）

### 7.9 MeridianDetailScreen — 经络详情

- 标题卡片（emoji、经络名、性质、脏腑、关键脉象）
- 核心症状 chip
- 欲解时
- 传变规律（来路/去路 可视化卡片）
- 经典原文
- 倪海厦解读
- 关联方剂列表

---

## 8. 启动流程 (main.dart)

`main()` 函数执行顺序：

1. `WidgetsFlutterBinding.ensureInitialized()` — 初始化 Flutter 绑定
2. `FormulaRepository.load()` — 加载 271 个方剂
3. `HerbRepository.load()` — 加载 440 味本草
4. `AcupunctureRepository.load()` — 加载 257 条穴位处方 + 31 条透针透穴
5. `AcupointRepository.load()` — 加载 379 个穴位详情
6. `runApp(const NiHaishaApp())` — 启动应用

**MaterialApp 配置：**
- Title: '汉唐中医'
- debugShowCheckedModeBanner: false
- Theme: Material 3, seedColor = Color(0xFF8B4513)（马鞍棕）
- 支持明暗主题切换
- 首页: HomeScreen

---

## 9. 架构总结

### 核心流程

```
用户打开 App
  → main.dart 加载 4 个 Repository
    → HomeScreen（底部导航3个Tab）
      → ChatScreen（对话诊断）
        → DiagnosticEngine 状态机
          → DiagnosticRules 规则匹配
            → DiagnosisResult（经络/证型/方剂/说明）
      → KnowledgeScreen（知识库5个Tab）
        → 六经浏览 → MeridianDetailScreen
        → 方剂浏览 → FormulaDetailScreen → HerbDetailScreen
        → 本草浏览 → HerbDetailScreen
        → 针灸浏览 → AcupointDetailScreen
        → 跨域搜索
      → BookmarksScreen（收藏管理）
        → DatabaseHelper SQLite 持久化
```

### 设计模式

- **静态仓库模式**：所有 Repository 在启动时一次性加载 JSON 数据到内存，后续查询纯内存操作
- **状态机模式**：DiagnosticEngine 通过 DiagnosticStage 枚举驱动诊断流程
- **离线优先**：零网络请求，所有数据从 bundled assets 加载
- **SQLite 持久化**：仅用于收藏功能和聊天记录（聊天记录功能已实现但未启用）
- **跨域导航**：方剂详情 → 本草详情，穴位处方 → 穴位详情，形成知识网络

### 数据流向

```
JSON 文件 → rootBundle.loadString() → Repository.parse() → 内存列表
                                                              ↓
UI 界面 ← Repository.search/getAll() ← 用户交互（搜索/过滤/点击）
```

---

## 10. APK 打包记录

| 版本 | 文件名 | 日期 | 说明 |
|------|--------|------|------|
| v1.0.4 | 汉唐中医_v1.0.4_针灸分类优化.apk | 2026-05-26 | 针灸14分类+257条处方+合并系统处方 |
| v1.0.3 | 汉唐中医_v1.0.3_穴位关联.apk | 2026-05-26 | 透针透穴穴位关联详情页 |
| v1.0.2 | 汉唐中医_v1.0.2_来源标签.apk | 2026-05-26 | 显示来源标签（倪海厦/系统配方） |
| v1.0.1 | 汉唐中医_v1.0.1_配方合并.apk | 2026-05-26 | 合并针灸处方和配方大全 |
| v1.0.0 | 汉唐中医_v1.0.0_针灸模块.apk | 2026-05-26 | 新增针灸模块 |
| v1.8.0 | 汉唐中医_v1.8.0.apk | 2026-05-25 | 历史版本 |
| v1.9.0 | 汉唐中医_v1.9.0.apk | 2026-05-25 | 历史版本 |
