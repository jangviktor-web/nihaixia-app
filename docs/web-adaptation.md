# Web 版适配说明

> 目标：一份代码同时交付 Android / iOS / Windows / Web，Web 版为纯静态站点，
> 无后端、离线可用，扔到任意静态托管即可访问。

## 1. 现在是什么状态

`flutter build web --release` 可在本机构建通过，产物 `build/web` 直接可跑。
已在 Chromium 153 里逐项点过：

| 功能 | 结果 | 依赖 |
|---|---|---|
| 首屏（知识库 / 节气卡 / 六经卡片） | ✅ | — |
| 全局搜索（219 条命中：方剂 10 / 本草 1 / 经典 208） | ✅ | gzip 索引 + SQLite |
| 方剂详情、繁体显示开关 | ✅ | OpenCC Web 实现 |
| 收藏 → 刷新页面仍在 | ✅ | SQLite WASM + Worker |
| 资源加载错误 | 0 个 4xx | — |

## 2. 四个平台差异点（都做了条件导入，业务代码零分叉）

### 2.1 数据库：`sqflite` → `sqflite_common_ffi_web`

浏览器没有原生 SQLite。Web 上把 `databaseFactory` 换成 `databaseFactoryFfiWeb`：
SQLite 编译成 WASM，跑在独立 Worker 里，对外仍是同一套 sqflite API。

- `lib/data/database_factory_stub.dart`（IO，空实现）
- `lib/data/database_factory_web.dart`（切换工厂）
- `DatabaseHelper.database` 首次打开前调 `initDatabaseFactory()`

⚠️ **`web/sqflite_sw.js` + `web/sqlite3.wasm` 是构建前提**。它们由
`dart run sqflite_common_ffi_web:setup` 生成（CI 里已固化为一步），
升级 `sqflite_common_ffi_web` 后要重跑，否则浏览器打开数据库报 Worker 404，
收藏/设置/对话历史全部失效。

### 2.2 gzip：`dart:io` → `DecompressionStream`

经典检索索引 `assets/guji/classic_index.json.gz`（3MB 压 → 30MB 文本）在浏览器里
用原生 `DecompressionStream('gzip')` 解，走 `dart:js_interop`，不引第三方 wasm 解压包。

- `gzip_codec_io.dart` / `gzip_codec_web.dart`
- 统一的 `gunzipBytesAsync()`：IO 侧同步解压包一层 Promise，调用方（`ClassicSearchService`）
  本来就是 `await`，两边共用一条代码路径。

Safari 16.4 / Chrome 80+ 起可用；更老的浏览器上索引加载失败 → 搜索降级不可用，其余功能正常。

### 2.3 长图导出：写文件 → 浏览器下载

`chart_export.dart` 原本直接 `import 'dart:io'`（`File` + `getTemporaryDirectory`），
Web 编译不过。拆成：

- `image_file_stub.dart`：IO 写临时文件 / App 目录（原逻辑）
- `image_file_web.dart`：`Blob` + `URL.createObjectURL` + `<a download>` 触发下载

浏览器没有系统分享面板可用（桌面浏览器普遍不支持 `navigator.share`），
「分享长图」在 Web 上也走下载。

### 2.4 摇一摇 / 应用内更新

- **摇一摇**：浏览器读不到有意义的加速度计事件，`utils/shake_support.dart` 的
  `kShakeSupported`（编译期常量）在 Web 为 false，梅花页把开关置灰并提示
  「当前设备无重力感应，请用下方随机起卦」。
- **应用内更新**：Web 是网页，刷新即最新，也拉不起 APK 安装器。更新弹窗在 Web 上
  只显示「更新说明」，不显示「下载更新」按钮，也没有体积/哈希信息。

## 3. 构建与部署

### 本地

```bash
flutter pub get
dart run sqflite_common_ffi_web:setup      # 生成 web/sqflite_sw.js + web/sqlite3.wasm
flutter build web --release
# 产物在 build/web，可用任意静态服务器验证：
python3 -m http.server 8899 --directory build/web
```

### 子路径部署

站点挂在 `https://example.com/nihaisha/` 这种子路径下时，构建要带 base href：

```bash
flutter build web --release --base-href /nihaisha/
```

### CI

`.github/workflows/build-web.yml`：tag `v*` 或手动触发。

- 产物 `nihaisha-web.zip`（整站），tag 触发时附到同名 Release，否则留在 run 的 Artifacts
- 静态托管就是纯文件服务：站点根目录指向解压后的目录即可，无需 SPA 回退
  （Flutter Web 默认 hash 路由，路径都在 `#` 之后）。

## 4. 体积

`build/web` 约 74MB，大头是：

| 项 | 体积 | 说明 |
|---|---|---|
| `canvaskit/` | ~9MB | Flutter 渲染引擎，可改用 gstatic CDN（见下） |
| `main.dart.js` | 6.4MB | 业务代码 + 全量数据索引 |
| `assets/` | ~57MB | 内经/伤寒/金匮/讲稿/医案等离线文本 |

> canvaskit 可以改走 gstatic CDN 省掉 9MB，但 URL 里要拼精确的引擎版本号，
> 脚本硬编码会随 Flutter 升级失配（白屏），故默认保留随包分发。
> 真要压体积，优先方向是**按需加载古籍文本**（`assets/neijing`、`assets/shanghan`
> 目前全量打包），收益远大于挤 canvaskit。

## 5. 已知不做的事

- **PWA 离线缓存**：Flutter 自带 `flutter_service_worker.js`，但默认不预缓存
  全部 assets。要做「断网可用」需自定义 service worker 清单，未做。
- **桌面浏览器适配**：布局仍是手机竖屏比例（`portrait-primary`），宽屏下两侧留白。
  真要做桌面布局得引入响应式断点，属独立任务。
