# 隐私政策 / Privacy Policy

**汉唐中医（nihaixia-app）**
最后更新：2026-11-06 · 版本 1.11.31

---

## 简体中文

### 一句话概括

本应用**不收集任何个人数据**。不需要注册、不需要登录，所有内容都在你的手机本地运行。

### 1. 我们收集什么

**什么都不收集。** 具体而言：

- 不要求注册账号，不收集姓名、手机号、邮箱、身份证号等任何身份信息
- 不申请定位、相机、麦克风、通讯录、短信、通话记录、外部存储等敏感权限
- 不集成任何广告 SDK、统计分析 SDK、崩溃上报 SDK 或用户追踪组件
- 不采集设备标识符（IMEI、MAC、Android ID、广告 ID 等）

### 2. 你的数据存在哪里

你在应用内产生的全部数据——诊断历史、收藏、紫微斗数命盘库、字号与主题等设置——**只保存在本机的 SQLite 数据库中，不会上传到任何服务器**。

卸载应用即彻底删除上述全部数据。应用内「设置 → 数据管理」也提供清空历史、清除缓存的功能。

> 建议：卸载或更换手机前，可在「设置」中导出收藏与诊断历史作为备份。

### 3. 唯一的联网行为

应用**完全离线可用**，仅在以下情形访问网络：

| 场景 | 访问地址 | 发送内容 |
|:---|:---|:---|
| 手动点击「检查更新」 | `api.github.com` 与 `gitee.com` 的公开 Releases 接口 | 仅标准 HTTP 请求，不含任何用户数据或标识 |
| 下载新版本安装包 | 上述平台的 Releases 下载地址 | 同上 |

以上请求只读取「最新版本号与安装包信息」，不携带、不上传任何个人信息。若不主动点击「检查更新」，应用不会产生任何网络请求。

**可选的第三方加速代理**：当用户自行在设置中开启「更新镜像加速」时，安装包下载会经过第三方中继 `ghproxy.net`（该开关**默认关闭**，且开启前会明确告知其中继性质）。该中继仅能看到「下载哪个公开的安装包」，同样接触不到你的个人数据。

### 4. 内容说明与免责

- 本应用是中医经方与传统文化的**学习与参考工具**，不提供医疗服务，任何辨证结果或方剂建议都不能替代执业医师的诊断与治疗
- 紫微斗数、易经、四柱、六爻等模块属于**传统民俗文化参考内容**，与医学无关，不构成任何预测或建议
- 请遵医嘱用药；急症、重症请立即就医

### 5. 儿童隐私

应用不面向儿童定向设计，也不收集任何年龄信息或儿童个人信息。

### 6. 政策变更

本政策如有更新，将随应用版本发布并在本文件与本项目仓库中同步。由于应用不收集联系方式，我们无法主动通知你，建议关注项目仓库的更新。

### 7. 联系方式

- 项目仓库：https://github.com/jangviktor-web/nihaixia-app
- 问题反馈：https://github.com/jangviktor-web/nihaixia-app/issues
- 安全披露：见 [SECURITY.md](SECURITY.md)

---

## English

### Summary

This app **collects no personal data**. There is no sign-up, no login, and everything runs locally on your device.

### 1. What we collect

**Nothing.** Specifically:

- No account registration; no name, phone number, email address, or identity document is ever requested
- No location, camera, microphone, contacts, SMS, call log, or external storage permissions are requested
- No advertising SDK, analytics SDK, crash-reporting SDK, or user-tracking component is integrated
- No device identifiers (IMEI, MAC address, Android ID, advertising ID, etc.) are collected

### 2. Where your data lives

All data you create in the app — diagnosis history, favourites, Zi Wei Dou Shu chart library, font-size and theme settings — is stored **only in the local SQLite database on your device and is never uploaded to any server**.

Uninstalling the app permanently deletes all of it. The in-app "Settings → Data management" also lets you clear history and cache.

> Tip: before uninstalling or switching phones, export your favourites and diagnosis history from "Settings" as a backup.

### 3. The only network activity

The app **works fully offline**. Network access happens only in these cases:

| Scenario | Endpoint | Data sent |
|:---|:---|:---|
| You manually tap "Check for updates" | Public Releases APIs at `api.github.com` and `gitee.com` | A standard HTTP request only — no user data or identifiers |
| Downloading a new release | The Releases download URLs on the same platforms | Same as above |

These requests read only the latest version number and package metadata. They carry no personal information. If you never tap "Check for updates", the app makes no network requests at all.

**Optional third-party acceleration proxy**: if you enable "update mirror acceleration" in Settings, package downloads go through the third-party relay `ghproxy.net`. This switch is **off by default**, and its relaying nature is disclosed before it can be enabled. The relay only sees which public package is being downloaded; it has no access to your personal data.

### 4. Content notice and disclaimer

- This app is a **study and reference tool** for classical Chinese herbal formulas and traditional culture. It does not provide medical services, and no pattern-differentiation result or formula suggestion can replace diagnosis and treatment by a licensed physician.
- The Zi Wei Dou Shu, Yi Jing, Four Pillars, and Six-Yao modules are **traditional folk-culture reference content**, unrelated to medicine, and do not constitute any prediction or advice.
- Follow your doctor's advice when taking medication; seek immediate medical care for acute or severe conditions.

### 5. Children's privacy

The app is not directed at children and collects no age information or children's personal data.

### 6. Policy changes

Updates to this policy ship with app releases and are mirrored in this file and the project repository. Because the app collects no contact details, we cannot notify you directly — watching the repository is recommended.

### 7. Contact

- Repository: https://github.com/jangviktor-web/nihaixia-app
- Issues: https://github.com/jangviktor-web/nihaixia-app/issues
- Security disclosure: see [SECURITY.md](SECURITY.md)
