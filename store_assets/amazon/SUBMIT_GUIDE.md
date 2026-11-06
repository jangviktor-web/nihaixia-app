# Amazon Appstore 上架指南（汉唐中医 v1.11.31）

> 结论先说：**技术上完全可行，但投入产出比偏低**。Amazon Appstore 的用户主要在 Fire 平板 / Fire TV，中文中医受众极少；且国际开发者必须先完成美国税务访谈。若只为「多一个渠道」，按本文走即可；若图流量，优先级应低于 APKPure / 酷安。

---

## 一、前置条件（必须先做完，否则传不了）

### 1. Amazon Developer 账号

- 入口：<https://developer.amazon.com/> → Sign up
- 免费，只需邮箱 + 姓名地址
- 注册后进入 Developer Console

### 2. 美国税务身份访谈（硬性，免费应用也要求）

官方文档原文：即使组织是非营利免税机构，也仍需完成 Tax Identification Interview。

路径：Developer Console → `My Settings` → `Tax Identity` → 完成 US + CA Tax Interview

中国开发者按以下填：

| 项目         | 填写内容                         |
| ---------- | ---------------------------- |
| 是否美国人      | **否**（Non-US person）         |
| 表格类型       | 个人 → W-8BEN；企业 → W-8BEN-E    |
| 纳税人识别号 TIN | 个人填身份证号，企业填统一社会信用代码          |
| 姓名         | 身份证姓名拼音，须与证件一致               |
| 税收协定       | 中美有税收协定，正确填写部分收入可享 10% 协定预扣率 |
| 签名         | **必须手写签名**，电子章会被拒（IRS 要求）    |

验证通常几分钟出结果，特殊情况 7–10 个工作日。状态显示 `Completed` 才算完成。

> 本应用免费、无内购、无广告，不产生 Amazon 付款，但访谈仍须完成才能上架。



---

## 二、提交路径

Developer Console → `Amazon Appstore` → `Add a new app` → 选 `Android`，然后按顺序填：

1. **General information** — 应用标题、语言、分类
2. **Availability and pricing** — 选 Free，勾选分发国家
3. **Description** — 短描述 / 长描述 / 特性要点 / 关键词
4. **Images and multimedia** — 图标 + 截图
5. **Upload your app file** — 上传 APK
6. **Content rating** — 内容分级问卷
7. Submit for review

审核周期 3–7 个工作日。

---

## 三、素材（已备好，直接用）

| 素材      | 文件                                               | 规格            | 状态 |
| ------- | ------------------------------------------------ | ------------- | -- |
| 小图标     | `store_assets/amazon/icon_114.png`               | 114×114 PNG   | ✅  |
| 大图标     | `store_assets/amazon/icon_512.png`               | 512×512 PNG   | ✅  |
| 截图      | `store_assets/common_1920x1080/` 6 张             | 1920×1080 PNG | ✅  |
| APK     | `store_assets/apkpure/app-arm64-v8a-release.apk` | 36.5MB，arm64  | ✅  |
| APK（通用） | `store_assets/apkpure/app-release.apk`           | 81.6MB，仍在下载   | ⏳  |

**Amazon 截图允许的尺寸仅这几档**：800×480 / 1024×600 / 1280×720 / 1280×800 / 1920×1080 / 1920×1200 / 2560×1600。已按 1920×1080 生成，合规。

数量要求 3–10 张，已备 6 张。

**图标注意**：Amazon 要求 PNG 且建议透明背景；不要自己加圆角或边框。

---

## 四、必填字段（可直接复制）

### 应用标题

```
Hantang TCM · Ni Haixia Classical Formulas
```

### 短描述（Amazon 上限约 1200 字符；Fire TV 只显示前 200，重点前置）

```
An offline-first, completely free study companion for classical Chinese herbal medicine (TCM), faithfully recreating Master Ni Haixia's Renji teaching system. No sign-up, no ads, no tracking — all knowledge is bundled on-device and works without internet. Includes 394 Shang Han Lun chapters, 433 Jin Gui Yao Lue chapters, 322 classical formulas, 465 materia medica entries, 408 acupoints, 1257 case records and 1728 indexed classic entries. One-tap Simplified/Traditional Chinese toggle, full-text search across lecture transcripts and original texts, and a Six-Meridian guided intake that derives the pattern and principal formula.
```

### 长描述（Amazon 上限 4000 字符，纯文本，不支持 HTML）

见 `store_assets/apkpure/listing.md` 的「长描述（English）」一节，直接粘贴。该版本约 2400 字符，未超限。

### 特性要点（3–5 条，每条一行）

```
Offline by design — every knowledge base is bundled; no internet needed after install
394 Shang Han Lun + 433 Jin Gui Yao Lue chapters, readable clause by clause
322 classical formulas and 465 materia medica entries, bidirectionally linked with the classics
Six-Meridian guided intake derives the pattern and the principal formula
Simplified / Traditional Chinese toggle plus full-text search over 1728 classic entries
```

### 关键词

```
TCM, Chinese medicine, Shang Han Lun, classical formulas, materia medica, acupuncture, herbal medicine, Ni Haixia, Six Meridian
```

### 分类

首选 `Books & Reference`（次选 `Health & Fitness`）。  
**建议避开医疗类目**——本应用是学习参考工具，不是诊疗应用，归到参考书更贴合，也避开审核对医疗声明的要求。

### 隐私政策 URL

```
https://github.com/jangviktor-web/nihaixia-app/blob/master/PRIVACY.md
```

（已新建 `PRIVACY.md`，中英双语，需先 push 到 GitHub 才能生效）

### 内容分级问卷

按实填写：无暴力、无色情、无赌博、无用户生成内容、无位置收集 → 应为最低年龄档。

---

## 五、常见驳回原因与规避

| 风险点          | 说明           | 应对                                         |
| ------------ | ------------ | ------------------------------------------ |
| 描述含 HTML     | Amazon 校验会失败 | 全程纯文本，不用任何标签                               |
| 截图尺寸不在白名单    | 直接传不上        | 已按 1920×1080 生成                            |
| 图片扩展名与实际类型不符 | 上传失败         | 全部为真实 PNG                                  |
| 图标含边框/圆角     | 违反设计规范       | 已用原始方形图标                                   |
| 声称医疗诊断       | 可能触发医疗类审核    | 描述只写 study / reference，不写 diagnose / treat |
| 第三方内容版权      | 需自有或已授权      | 内容来自公开古籍与自建数据，README 已注明来源与免责              |

---

## 六、一条必须提醒的风险

本应用包含**紫微斗数、易经、四柱、六爻**模块。Amazon 内容政策对「占卜/算命」类一般不禁（归 Reference / Entertainment），但描述里建议保持现有的措辞——明确标注为 traditional folk-culture reference content，与医学模块严格区分。这一点 README 和 PRIVACY.md 里已经写明，直接沿用即可。

---

## 七、执行顺序建议

1. 先把 `PRIVACY.md` push 到 GitHub（隐私政策 URL 才能访问）
2. 注册 Amazon Developer 账号
3. 完成 Tax Identity 访谈，等状态变 `Completed`
4. 等通用包 `app-release.apk` 下载完（arm64 包通常也能通过，但通用包覆盖 Fire 设备更稳）
5. 按第二节顺序填表提交
