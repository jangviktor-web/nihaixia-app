## 这个 PR 做了什么

<!-- 一两句话说清改了什么、为什么改 -->

## 改动类型

- [ ] 🐞 Bug 修复
- [ ] ✨ 新功能 / 新模块
- [ ] 📜 内容与数据（方剂 / 本草 / 穴位 / 医案 / 经典）
- [ ] 🎨 界面与可读性
- [ ] ⚡ 性能
- [ ] 📄 文档 / CI

## 怎么验证的

<!-- 测试命令、真机机型、截图都可以；涉及界面改动的请贴图 -->

- [ ] `flutter analyze` 无新增 error
- [ ] 相关测试已跑（列出测试文件 / 用例）
- [ ] 真机验证（机型 + Android 版本）

## 自查清单

- [ ] 没有提交 `android/release-key.jks`、`key.properties`、`*.mobileprovision` 等签名文件
- [ ] 没有改 `pubspec.yaml` 的版本号与 `+build` 号
- [ ] 新增/修改图片为 WebP（quality 80，宽度 ≤ 1400px）
- [ ] 涉及辨证路径、检索、筛选逻辑的改动补了测试
- [ ] 新增古籍/讲稿后已重跑 `tool/build_classic_search_index.py`
- [ ] 医疗内容标注了出处，未写疗效承诺

## 关联 Issue

<!-- Closes #123 -->
