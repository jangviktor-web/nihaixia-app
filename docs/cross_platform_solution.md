# 汉唐中医 App 跨平台（iOS + Android）解决方案

> 设计者：掌中灵（Mobile App Builder）｜基于现有 `nihaisha_app` Flutter 项目
> 目标：一套代码库同时交付 iOS 与 Android，并通过双端应用商店上架

---

## 1. 平台战略（Platform Strategy）

### 目标平台
| 平台 | 最低版本 | 说明 |
|---|---|---|
| **Android** | 6.0（API 23） | 已支持，仅 GitHub APK 分发，尚未上架 Play |
| **iOS** | 13.0+（建议 14+） | **尚未初始化**（项目无 `ios/` 目录） |

### 架构决策：**沿用 Flutter 跨平台，不重写原生**
- 理由：已有成熟代码库（38 个 dart 文件、174 个测试、离线优先数据层）、团队已熟悉 Flutter、TCM 诊断逻辑与平台无关。
- 双端共享率预计 >90%，仅签名/图标/启动屏/少量平台适配需分别处理。
- 不采用 React Native / 原生重写：成本高、收益低、会丢失现有诊断引擎与数据。

---

## 2. 开发方法（Development Approach）

| 维度 | 现状 | 建议 |
|---|---|---|
| 框架 | Flutter 3.x（pubspec SDK `^3.12`） | 保持；升级到最新稳定版以获得 iOS 新特性 |
| 状态管理 | StatefulWidget + `ListenableBuilder`（`SettingsRepository`） | 诊断流程状态建议收敛到单一 `ChangeNotifier`/`Riverpod`，降低 4449 行引擎耦合 |
| 导航 | `HomeScreen` + 多 Tab | 遵循平台规范：iOS 大标题 + 右滑返回；Android 标准 Material 导航 |
| 数据存储 | `sqflite` + 离线 JSON（已离线优先） | **保持**；这是本 App 最大优势，无需联网 |
| 主题 | 已支持 `themeMode` 明/暗 | 保持，并做 iOS 系统字体/安全区适配 |

---

## 3. 平台实现（Platform-Specific Implementation）

### 3.1 iOS（核心缺口）
1. **初始化工程**：在 macOS + Xcode 环境下执行
   ```bash
   flutter create --platforms=ios .
   ```
   生成 `ios/Runner` 工程（Bundle ID 建议 `com.jangviktor.nihaixia`）。
2. **代码签名**（App Store 上架必需）：
   - 注册 Apple Developer Program（$99/年）；
   - 创建 App ID、Distribution 证书、Provisioning Profile；
   - 推荐 **Fastlane Match** 或 **Codemagic** 托管证书，避免团队私钥混乱。
3. **图标 / 启动屏**：复用现有 `docs/images/logo.jpg` 生成 `AppIcon`，配置 LaunchScreen Storyboard。
4. **权限 `Info.plist`**：本 App 纯本地、无相机/定位，仅需 `share_plus` 系统分享；无需申请敏感权限，降低审核摩擦。
5. **遵循 HIG**：SF 字体、安全区（`SafeArea` 已覆盖）、大标题导航、右滑返回手势。

> ⚠️ **iOS 合规红线（关键）**：现有「应用内更新检测（GitHub Releases）」在 iOS 上**会被拒审**（违反 Guideline 2.9 / 5.6，禁止引导用户去 App Store 以外的渠道更新）。必须改为：**iOS 端点击「检查更新」→ 直接跳转 App Store / TestFlight**，不能展示下载按钮或 APK。Android 端可保留 GitHub 检测，或改用 Play In-App Update API。

> ⚠️ **医疗类 App 审核风险**：中医/健康类 App 在 App Store 审核更严，需：
> - 明显的「免责声明」（本软件仅供学习参考，不构成医疗诊断/治疗建议）；
> - 不得声称可替代医生；
> - 可能被要求提供医疗资质或机构背书。上架前务必准备。

### 3.2 Android（已就绪，需 polish）
- 已具备 Gradle Kotlin DSL + `release-key.jks` 签名（良好基础）。
- **上架 Play**：当前仅 GitHub APK 分发，建议补充 Google Play 上架（需 AAB 包、`targetSdk` 提升到 34/35、隐私政策页）。
- 应用内更新：Android 可保留 GitHub 检测，或接入 Play In-App Update。

---

## 4. 性能优化（Performance）

| 指标 | 目标 | 当前风险与对策 |
|---|---|---|
| 冷启动 | < 3s | ⚠️ `main.dart` 启动时**同步加载 4 个 JSON**（formulas 377KB + herbs 480KB + acupoints 482KB + acupuncture 72KB ≈ 1.3MB）并全量解析 → 易白屏。对策：改为 `compute()` isolate 异步解析 + 按需懒加载（如进入方剂页才解析 formulas）。 |
| 内存 | < 100MB | JSON 全量驻留可控；诊断引擎状态机注意及时释放。 |
| 包体积 | APK 52MB（iOS 相近） | 已用 R8 缩减 + 资源压缩；可进一步按需加载数据或拆分。 |
| 离线 | 100% 可用 | 已实现，保持；可加 SQLite 查询索引优化。 |

**最高优先级性能改造**：把启动时的「全量 JSON 同步 load」改为「异步 + 懒加载」，这是目前最影响双端首屏体验的点。

---

## 5. 平台集成（Platform Integrations）

| 能力 | 现状 | 建议 |
|---|---|---|
| 认证 | 无（离线） | 可选：用 `local_auth` 加 Face ID / 指纹锁定「收藏」 |
| 推送 | 无 | 离线 App 价值有限，可暂缓；如需更新通知用 Firebase/APNs |
| 崩溃/分析 | 无 | **强烈建议**加 `sentry_flutter` 或 Firebase Crashlytics，统一双端监控，目标 crash-free > 99.5% |
| 分享 | `share_plus` 已集成 | 保持 |
| 应用内更新 | GitHub 检测（Android OK） | iOS 改为跳 App Store（见 §3.1 红线） |

---

## 6. CI/CD（DevOps）

当前**无任何 CI**。建议：

- **GitHub Actions**（或 Flutter 友好的 **Codemagic**）：
  - `PR`：运行 `flutter analyze` + `flutter test`（174 测试门禁）；
  - `tag/release`：自动构建 **Android AAB**（签名）+ **iOS IPA**（自动签名）→ 上传 GitHub Releases / TestFlight / Play Internal Track。
- **修复版本漂移**：`pubspec.yaml` 当前 `1.5.0+1`，但本地 APK 已到 `v1.9.0`。发版前必须统一版本号并与 git tag 对齐，否则商店显示错误版本。
- 清理遗留文件：`docs/diagnostic_engine_optimization_report.md`（修复已完成但未删除）。

---

## 7. 架构健康（Maintainability）

- **引擎是 4449 行单文件**（`diagnostic_engine.dart`）：后续加证型/调规则难维护。建议按六经拆分或抽离规则/数据层；目标测试覆盖率 95%。
- 双端共用逻辑应放进 `lib/engine` + `lib/models`，平台差异仅限制在 `ios/` / `android/` / 少量 `Platform.isIOS` 分支。

---

## 8. 实施路线图（Action Plan）

| 阶段 | 任务 | 依赖 |
|---|---|---|
| **P0 准备** | 准备 macOS + Xcode 环境；安装 Flutter 最新稳定版；统一版本号 | 一台 Mac（iOS 必须） |
| **P1 iOS 初始化** | `flutter create --platforms=ios .`；配置 Bundle ID / 图标 / 启动屏 / 签名 | P0 |
| **P2 适配与合规** | iOS「应用内更新」改为跳 App Store；加免责声明；HIG 适配；启动 JSON 懒加载 | P1 |
| **P3 CI/CD** | GitHub Actions/Codemagic 双端流水线 + 测试门禁 | P1 |
| **P4 上架** | TestFlight 内测 → App Store；Play Console 上架（AAB + 隐私政策） | P2/P3 |
| **P5 增强** | Crashlytics 监控；引擎重构；性能调优 | P4 |

---

## 9. 关键风险清单（必须重视）

1. 🔴 **iOS 应用内更新违规** → 改跳 App Store，否则拒审。
2. 🔴 **医疗类 App 资质/免责** → 准备免责声明与可能的资质说明。
3. 🟠 **启动性能** → 1.3MB JSON 同步解析，需异步/懒加载。
4. 🟠 **版本漂移** → pubspec 1.5.0 vs APK 1.9.0，发版前对齐。
5. 🟡 **引擎单体过大** → 影响长期可维护性。
6. 🟡 **无 CI** → 双端发版靠手动，易出错。

---

**掌中灵 / Mobile App Builder**
设计日期：2026-08-15
原则：一套 Flutter 代码覆盖双端，把工程化、合规、性能三件事做扎实。
