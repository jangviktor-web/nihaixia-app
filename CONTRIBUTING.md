# 贡献指南（Contributing）

感谢你愿意一起完善汉唐中医。这个项目的目标是把倪海厦《人纪》体系里的辨证思路做成**可离线、可核对、可复现**的工具，所以「有出处」比「看起来对」更重要。

## 先聊，再动手

- 提 Bug / 需求前先搜一下 [Issues](https://github.com/jangviktor-web/nihaixia-app/issues)，避免重复。
- 较大的改动（新模块、数据结构调整、UI 大改）请先开 Issue 说明思路，确认方向后再写代码，省得白做。
- 纯内容纠错（错别字、方剂组成、穴位定位）也欢迎，直接提 Issue 并附出处即可。

## 开发环境

- Flutter 3.47 / Dart 3.13（`flutter --version` 对得上即可，3.x 一般都能跑）
- Android SDK 36、NDK 28.2（只构建 Android 包时需要）
- Windows 上如果 `%TEMP%` 指向不存在的盘，先设 `TEMP`/`TMP` 到有效目录，否则 `pub get` 会报符号链接错误。

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release   # 需要 APK 时才跑，约 5-10 分钟
```

## 提交前必须做的

1. `flutter analyze` **0 error**（warning 尽量清掉，历史遗留的可以不动）。
2. 改动涉及辨证路径、检索、筛选、渲染布局的，**补测试或更新现有测试**；修复 Bug 时最好先写一个能复现的用例。
3. 跑一遍相关测试文件；有条件就跑全量 `flutter test`。仓库有两个历史基线失败（`quality_score_bc_test`、`ziwei_bench_test`），不算你引入的回归。
4. 不要改 `pubspec.yaml` 的版本号与 `+build` 号——版本由维护者在发版时统一处理。
5. 图片统一用 **WebP（quality 80）**，宽度不超过 1400px；截图放 `docs/images/`，正文用相对路径引用。

## 代码约定

- 遵循 [Effective Dart](https://dart.dev/effective-dart) 与仓库的 `flutter_lints`；分层保持现状：`lib/screens`（页面）、`lib/widgets`（组件）、`lib/data`（数据与仓库）、`lib/services`（服务）、`lib/engine`（辨证引擎）。
- 颜色走 `AppColors` / `ColorScheme` 语义色，字号走 `AppType` / `AppTextScale`，不要在页面里写裸色值和魔法字号。
- `RichText` 不继承 `DefaultTextStyle`，凡是用 `RichText`/`TextSpan` 的地方都要显式给颜色，否则浅色模式下会变成近白色。
- 长列表用 `ListView.builder`；过滤结果按条件缓存，别在 `build` 里全表扫描。
- 注释只写「为什么」，不写「是什么」。

## 内容与数据

- 方剂、本草、穴位、医案的数据文件在 `assets/data/` 与 `assets/` 下，改动时请保持字段结构不变；数值必须能追溯到《人纪》原文或国标（如耳穴 GB/T 13734-2008）。
- 经典原文只收**公版**古籍；引用现代出版物、他人整理本时请先确认授权。
- 不写"包治""根治"一类承诺；涉及医疗的页面保留免责声明。
- 新增古籍或讲稿后，记得重跑 `tool/build_classic_search_index.py` 重建检索索引，否则全局搜索搜不到新内容。

## 提交信息与 PR

- 提交信息用 Conventional Commits：`feat:` / `fix:` / `docs:` / `ci:` / `refactor:` / `test:`，一句话说清「为什么」。
- PR 请从自己的 fork 开分支，**不要**带 `android/release-key.jks`、`key.properties`、`*.mobileprovision` 等签名相关文件。
- PR 描述里写清楚：改了什么、为什么改、怎么验证的（测试 / 截图 / 真机机型）。
- 提交即表示同意以 [Apache-2.0](LICENSE) 协议授权你的贡献；合并后会在提交记录里保留你的署名。

## 关于医疗内容

本项目是**学习与辅助工具**，不替代面诊与处方。内容讨论以经典原文与倪师讲稿为准；有学术分歧时并列呈现、标明出处，不冒充唯一正解。
