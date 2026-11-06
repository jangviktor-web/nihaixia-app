# 汉唐中医接入大模型 API · 可行设计方案

> 设计原则（ponytail）：**不建 RAG 框架、不建向量库、不做 Agent 编排、不做端侧模型、不复制第二份语料。**
> 一句话方案：**已有的全文检索 + 已打包的倪师人格资产 + 一次 HTTP POST**，用户自填 key，默认关闭。

---

## 一、先看清已经有什么（决定方案能做到多懒）

| 已有资产 | 位置 | 直接拿来做什么 |
|---|---|---|
| 倪海厦表达规则 / 决策启发式 / 诚实边界 | `assets/llm/persona.md`（约 10 KB，由 WorkBuddy skill 一次性抽取） | **system prompt** |
| 项目内旧快照 `assets/SKILL.md` 850 KB | 已打进 APK、代码从未读取 | **不再作为 prompt 来源**；从 pubspec 移除注册，APK 净减约 840 KB |
| 经典全文检索（1728 条，自带繁简归一） | `ClassicSearchService.search(query)` | 检索上下文，**不用新建索引** |
| 命中资产路径集合 | `ClassicSearchService.matchAssets(query)` | 详情页「问倪师」时定位当前条文 |
| `http: ^1.2.0` | pubspec 已装（`update_service.dart` 在用） | POST，不新增依赖 |
| `flutter_markdown: ^0.7.0` | pubspec 已装 | 渲染回答（表格 / 条文卡） |
| `SettingsRepository`（sqflite） | `lib/data/settings_repository.dart` | 存开关 / baseURL / key |
| `settings_screen.dart` | `lib/screens/` | 加 3 个设置项 |
| `traditional_display.dart` | `lib/data/` | 繁体提问归一 |
| `assets/SKILL.md` 已在 pubspec 注册 | `pubspec.yaml` | 改成 `assets/llm/persona.md`（换一行，省 840 KB） |

**关键事实：`assets/SKILL.md` 已被打进 APK 850 KB，但代码里从未读取过**（全仓 `lib/` grep 无命中），且是 2026-05-23 的冻结快照。结论：别激活它，从 pubspec 移除注册，APK 净减约 840 KB。

### 用哪份 skill：**WorkBuddy 安装的 `nihaixia` 是唯一来源**

两份不是新旧程度差异，是**代差**：

| 维度 | 项目内 `assets/SKILL.md` | WorkBuddy `~/.workbuddy/skills/nihaixia/` |
|---|---|---|
| 版本 | 2026-05-23 冻结快照 | v2.3.1，持续维护（CHANGELOG 到 11-01） |
| 体积 / 结构 | 850 KB，规则与全文语料混在一个文件 | SKILL.md 133 KB 纯规则，语料拆到 modules/cases |
| 内经 | 18 篇 | **72 篇** |
| 医案 | 849 例 | **1257 全量结构化 + 243 分类叙事** |
| 本草 | 345 种 | **374 种** |
| 临床速查 | 无 | **六经辨证诊断公式 8 个 + 流程图 + 脉舌速查 + 合病并病 + 真寒假热鉴别 + 七步走** |
| 表达规则 | 旧版「禁止表格/编号」 | **v2.3.1 折中格式**：口语为主体 + 每答至少一个表格/加粗重点 + 八查 + 方剂出条文卡（经 3 次独立盲测） |

**决定性理由**：CHANGELOG 明确记录，旧版「禁止表格」导致回答退化成整段口语、重点难找，被用户实测吐槽后才重构成折中版。拿 5 月那份去接 API，等于把已经修过的 bug 重新引入。

**落地方式（一次性，不接 CI、不实时同步）**：从 WorkBuddy skill 抽三段规则写成静态文件，提交进仓库。

```bash
S=~/.workbuddy/skills/nihaixia/SKILL.md
mkdir -p assets/llm
{ sed -n '1,35p' "$S";       # 表达速查卡：折中格式 / 八查 / 口语开场  6.1 KB
  sed -n '1359,1402p' "$S";  # 决策启发式                              1.9 KB
  sed -n '1570,1600p' "$S";  # 诚实边界                                2.3 KB
} > assets/llm/persona.md
```

约 10.3 KB。`pubspec.yaml` 把 `- assets/SKILL.md` 换成 `- assets/llm/persona.md`（旧文件留着但不打包）。

**三处必须适配**（skill 是写给 WorkBuddy agent 的，不是写给 App 的）：

1. 删掉「加载 modules/XX」「输出模块路径行号」——App 里没有这些文件，模型会试图去加载不存在的东西
2. 「禁止 WebSearch/Fetch」改写成「只依据下方讲义片段，不得引用外部知识」——App 本来就不给模型联网
3. 「安全话术只走文末固定免责框」保留——正好对应 App 固定渲染的免责框

**「结合 skill」= 两层**：
- **人格层**（真正值钱的）：表达速查卡 + 决策启发式「先辨六经再选方 / 阳气不足先扶阳 / 经典原方最可靠」 + 诚实边界
- **知识层**：走 App 自带语料 + 现有检索，**不打包 modules 4.5 MB / cases 1.5 MB**（内容与伤寒 394、金匮 433、本草讲稿 335、医案 1257、经典索引 1728 高度重叠，再打一份就是第二套语料加第二套索引）

> skill 里那条「讲义没写就明说不知道，绝不编造」的硬约束是方案成立的关键：写进 system prompt，再只喂本地检索片段，模型就不会自由发挥。

---

## 二、数据流

```
用户提问
  → normalizeQuery()                    （繁体输入也能命中，复用现有）
  → ClassicSearchService.search(q)      （1728 条，取前 5 条）
  → 取 hit.snippet，每条截断 400 字，总预算 2000 字
  → 首次提问时读 assets/llm/persona.md 并缓存      （10.3 KB，只加载一次）
  → 拼 messages
  → http.post(baseURL + /chat/completions, stream:false)
  → choices[0].message.content
  → flutter_markdown 渲染
  → 底部固定免责框（App 渲染，不交给模型）
```

### 核心代码骨架（`lib/services/llm_service.dart`）

```dart
// ponytail: 单轮、非流式、无历史、无重试队列；够用就不加。
class LlmService {
  static String? _persona;

  static Future<String> _loadPersona() async {
    if (_persona != null) return _persona!;
    // 构建期从 WorkBuddy skill 一次性抽取的静态规则，不再读 850 KB 旧快照
    return _persona = await rootBundle.loadString('assets/llm/persona.md');
  }

  static Future<String> ask(String question, LlmConfig cfg) async {
    final result = await ClassicSearchService.search(question);
    final buf = StringBuffer();
    for (final hit in result.hits.take(5)) {
      final s = hit.snippet;
      buf.writeln('【${hit.sourceLabel}·${hit.title}】');
      buf.writeln(s.length > 400 ? s.substring(0, 400) : s);
      if (buf.length > 2000) break;   // ponytail: 硬截断，别做 token 计算器
    }

    final system = '''
${await _loadPersona()}

你是「讲义问答助手」，严格按以上倪师视角与工作流回答。
铁律：只依据下方【讲义片段】作答；片段未涉及就明确说「讲义里没有涉及这个话题，我不能替倪师乱讲」，绝不编造、不引用外部知识。
涉及具体方剂时附出处条文。不要写「建议就医」等安全话术——免责框由应用统一渲染。
''';

    final res = await http.post(
      Uri.parse('${cfg.baseUrl}/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${cfg.apiKey}',
      },
      body: jsonEncode({
        'model': cfg.model,
        'stream': false,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': '【讲义片段】\n$buf\n\n【提问】\n$question'},
        ],
      }),
    ).timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      throw LlmException('HTTP ${res.statusCode}: ${_safeMessage(res.body)}');
    }
    final body = utf8.decode(res.bodyBytes);
    return jsonDecode(body)['choices'][0]['message']['content'] as String;
  }
}
```

`LlmConfig` 就三个字段：`enabled` / `baseUrl` / `apiKey` / `model`，全部存进现有 `SettingsRepository`。**OpenAI 兼容格式**，换 DeepSeek、通义、OpenRouter、本地 Ollama 只改 baseUrl 和 model，代码不动。

---

## 三、文件清单（最短 diff）

**新增 4 个**

| 文件 | 内容 |
|---|---|
| `assets/llm/persona.md` | 从 WorkBuddy skill 一次性抽取的约 10 KB 规则（含三处适配） |
| `lib/services/llm_service.dart` | persona 加载、prompt 拼装、POST、错误归一 |
| `lib/screens/llm_ask_screen.dart` | 输入框 + 回答区（flutter_markdown）+ 固定免责框 |
| `test/llm_context_test.dart` | 一个断言测试（见第七节） |

**改动 3 处代码**

| 文件 | 改动 |
|---|---|
| `lib/data/settings_repository.dart` | 加 4 个字段（enabled/baseUrl/apiKey/model） |
| `lib/screens/settings_screen.dart` | 加一个「AI 讲义问答」分组，开关 + 3 个输入框 |
| 知识库 tab 或工具页 | 加一个入口，**仅 `enabled == true` 时显示** |

**改动 4 处文案**：`PRIVACY.md` 加一节、三语 `README.md` 头部与功能表各改一句（三份逐行同构，改一需同步三）。

**还要改 1 行**：`pubspec.yaml` 把 `- assets/SKILL.md` 换成 `- assets/llm/persona.md`。

**不需要改**：依赖（全已有）、AndroidManifest（INTERNET 权限已有）、CI workflow、构建脚本、既有语料资产。

---

## 四、Token 预算

| 段 | 体积 | 估算 |
|---|---|---|
| persona（速查卡 + 决策启发式 + 诚实边界） | 10.3 KB ≈ 3,400 汉字 | 约 4–5 K tokens |
| 检索片段（≤5 条 × 400 字） | ≤ 2 KB ≈ 700 汉字 | 约 1 K tokens |
| 铁律 + 提问 | < 0.5 KB | < 0.3 K tokens |
| **合计输入** | **≈ 11 KB** | **约 4–5 K tokens / 次** |

850 KB 全文绝不能整塞（约 28 万汉字，直接爆上下文且费用失控）。

降级路径：若实测费用或延迟偏高，persona 只保留速查卡第 1–20 行 + 诚实边界（约 4 KB），输入降到约 2 K tokens。先跑全量版测效果，不够再砍——但别一开始就做两套配置（YAGNI）。

---

## 五、合规边界（这一步不能懒）

这几条是硬约束，不是可选项：

1. **默认关闭**，用户未配置 key 时入口不出现。App 不内置任何 key、不做代理、不做中转。
2. **只在用户点「提问」时联网**，发送内容 = 提问 + 本地检索片段；**不发送**诊断历史、收藏、命盘、城市、任何本地 DB 数据。
3. **隐私政策**：现版 `PRIVACY.md` 写的是「不收集任何个人数据、唯一联网是检查更新」，接入后前提不成立。必须新增一节说明「可选 AI 问答」的数据流向、由用户自行选择服务端、关闭即零发送。Amazon / 华为 / APKPure 三家填过的隐私政策字段要同步重填。
4. **README 三语**：头部「离线可用 · 数据全本地 · 无需注册」改为「离线优先；AI 问答为可选联网功能，需自行配置」，功能表加一行并标注默认关闭。
5. **免责框由 App 固定渲染**，不交给模型：明确写「AI 生成内容，非倪海厦本人原话，仅供学习参考，不构成诊疗建议」。这也对应 skill 规则里「正文禁止出现安全话术，只走文末固定免责框」。
6. **FOSS 商店影响**：F-Droid / IzzyOnDroid 会标 `NonFreeNet` anti-feature；Accrescent 对依赖专有网络服务更严。若坚持上这些商店，后续需要做成编译期 flavor（AI 构建变体单独分发）。**P0 不做**，先按「默认关闭 + 用户自配端点」把边界划清楚。
7. **API key 明文存本地 SQLite** 是 P0 的取舍。不要写进日志、不要进错误上报、不要随诊断导出。若之后上架商店，再考虑平台 keystore（那是独立改动，不塞进 P0）。

---

## 六、分期与明确不做的清单

**P0（最小可用）**：单轮问答。设置页 4 个字段 + 一个问答页 + 复用检索 + 一次 POST。3 新文件 / 3 处代码改动。

**P1（视反馈再加）**：条文卡 / 方剂详情页加「问倪师」按钮，用 `matchAssets()` 把当前条文正文直接塞进上下文，省掉一次检索。

**明确不做**（写到方案里防止 later 手痒）：

- 多轮对话历史 / 会话持久化
- 向量库、embedding、重排序、混合检索
- 流式输出（SSE）—— `stream:false` 够用
- Agent / 工具调用 / function calling
- 端侧模型（包体已 81.6 MB，再加不动）
- 模型管理、用量统计、prompt 模板编辑器
- 服务端代理（会重新引入「收集用户数据」）

每一项都是「以后真被卡住了再加」，不是现在预留的扩展点。不建接口、不建工厂、不建配置体系。

---

## 七、一个可跑的检查

ponytail 要求非平凡逻辑留一个最小断言。新建 `test/llm_context_test.dart`，只测三件事：

```dart
test('persona 非空、不超预算、不含 modules 路径引用', () {
  final p = personaSlice();
  expect(p.length, greaterThan(1000));
  expect(p.length, lessThan(14000));
  expect(p.contains('太阳病篇·条文46-129'), isFalse); // 别把 850KB 正文带进去
  expect(p.contains('modules/'), isFalse);            // App 里没有这些文件
});

test('上下文拼装不超预算且不含本地私有数据', () {
  final prompt = buildContext(hits, question: '桂枝汤证');
  expect(prompt.length, lessThan(2600));
});

test('零命中时仍带「不得编造」铁律', () {
  expect(buildSystem([]), contains('讲义里没有涉及这个话题'));
});
```

不建 fixtures、不建 mock server、不测真实网络。

---

## 八、分支与执行顺序

呼应上一轮结论：

```
1. 提交并推送当前 8 个上架文件（清场，PRIVACY.md 链接生效）
2. 本设计文档留在 master（.md 不进构建、不触发 CI）        ← 现在这步
3. git checkout -b feat/llm-*    ← 动手写代码时才开
4. 合并后立即删分支
```

`v*` tag 直接触发 CI 出 Release，master 上不能留半成品——这是开分支的唯一理由，不是流程规范。

**开工前需要你定的两件事**：
- 默认模型与 baseUrl 用什么（建议先按 OpenAI 兼容格式，测试用你手头有的任意一家）
- 入口放在哪（建议知识库 tab 顶部一个「问倪师」，别新建底部导航项）

---

## 九、一句话总结

WorkBuddy 的 `nihaixia` skill 才是活的规则源，项目里 850 KB 那份是 5 月且从未被读取的旧快照——从 pubspec 拿掉还能省 840 KB。1728 条全文检索、http、markdown 全都现成。**这次要写的只是一个把两者接起来的函数和一个页面**，零新依赖、零新语料。

> 已跳过：向量库 / Agent / 多轮 / 流式 / 端侧模型 / 第二份语料。等实际出现「检索片段不够用」或「响应太慢」的实证，再按那一条单独加。
