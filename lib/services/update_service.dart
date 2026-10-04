import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show Abi; // Abi 声明在 dart:ffi；本 SDK 的 dart:io 不导出它
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../data/database_helper.dart';

class UpdateInfo {
  final String version;
  final String tagName;
  final String body;
  final String apkDownloadUrl;
  final int apkSize;
  final String? apkSha256;

  /// 备用下载地址（按可信度排序，**不含** [apkDownloadUrl]）：① 本项目的 Gitee
  /// 发行版同包；② 仅当用户开启「更新镜像加速」时，末尾追加第三方代理 ghproxy 的
  /// 同一 GitHub 包。都是**同一个文件**，故沿用同一份体积 / 哈希校验。
  final List<String> extraApkUrls;

  UpdateInfo({
    required this.version,
    required this.tagName,
    required this.body,
    required this.apkDownloadUrl,
    required this.apkSize,
    this.apkSha256,
    this.extraApkUrls = const [],
  });
}

class UpdateService {
  static const _repoOwner = 'jangviktor-web';
  static const _repoName = 'nihaixia-app';
  // 同一份代码在 Gitee 的镜像仓库：CI 发布时会同步 tag 并建同名发行版，
  // 作为国内可达的备用下载源（见 .github/scripts/gitee_release.py）。
  static const _giteeOwner = 'jangviktor';
  static const _giteeRepo = 'nihaixia-app';
  static const _ghDownloadBase =
      'https://github.com/$_repoOwner/$_repoName/releases/download';
  static const _giteeDownloadBase =
      'https://gitee.com/$_giteeOwner/$_giteeRepo/releases/download';

  /// 第三方 GitHub 加速代理前缀（设置里可选开启）。它是**第三方中继**，能看到、
  /// 理论上也能篡改下载内容，故默认不参与，只在用户显式确认风险后才作为**最后**备用源。
  static const _ghProxyPrefix = 'https://ghproxy.net/';

  /// 元数据源 → 该源 Release 资产的下载前缀。
  /// 顺序即优先级：先 GitHub，后 Gitee。两处资产**同名同包**，故备用链接可由
  /// 「前缀 + tag + 资产名」直接推出，无需额外请求。
  static const Map<String, String> _releaseSources = {
    'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest':
        _ghDownloadBase,
    'https://gitee.com/api/v5/repos/$_giteeOwner/$_giteeRepo/releases/latest':
        _giteeDownloadBase,
  };
  static const _ignoredVersionKey = 'ignored_update_version';
  static const _permanentlyIgnoredKey = 'permanently_ignored_versions';
  static const _mirrorEnabledKey = 'update_mirror_enabled';

  /// 获取当前应用版本号
  static Future<String> getCurrentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// 是否启用第三方 GitHub 加速代理（ghproxy）。**默认关闭**：它是第三方中继，
  /// 可看到 / 理论上可篡改传输内容，必须由用户在设置里显式开启并确认风险告知。
  static Future<bool> isMirrorEnabled() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('user_settings',
          where: "key = ?", whereArgs: [_mirrorEnabledKey]);
      if (rows.isEmpty) return false;
      return (rows.first['value'] as String) == 'true';
    } catch (_) {
      return false;
    }
  }

  /// 设置是否启用镜像加速
  static Future<void> setMirrorEnabled(bool enabled) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'user_settings',
      {'key': _mirrorEnabledKey, 'value': enabled ? 'true' : 'false'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 检查是否有新版本（自动尝试主源 + 镜像源）
  static Future<UpdateInfo?> checkForUpdate() async {
    try {
      final currentVersion = await getCurrentVersion();
      Map<String, dynamic>? releaseData;
      String fallbackBase = ''; // 未命中源（备用源）的下载前缀
      for (final source in _releaseSources.entries) {
        try {
          final response = await http.get(Uri.parse(source.key)).timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('网络超时'),
          );
          if (response.statusCode == 200) {
            releaseData = json.decode(response.body) as Map<String, dynamic>;
            fallbackBase = _releaseSources.values
                .firstWhere((b) => b != source.value, orElse: () => '');
            break;
          }
        } catch (e) {
          debugPrint('更新源不可用，尝试下一源: ${source.key} -> $e');
        }
      }
      if (releaseData == null) return null;

      final tagName = releaseData['tag_name'] ?? '';
      final remoteVersion = tagName.replaceFirst('v', '');

      if (!_isNewerVersion(remoteVersion, currentVersion)) return null;
      if (await _isIgnored(remoteVersion)) return null;

      final bodyText = releaseData['body'] as String? ?? '暂无更新说明';

      // 按**资产名**精确选包。不能取「第一个 .apk」：4 个包内容不同，且 GitHub 与
      // Gitee 的资产返回顺序不一定一致 —— 取错包会让 32 位机装上 arm64 包（安装失败），
      // 也会让下面按名匹配的 SHA-256 校验配错、把正常下载判为非法。
      final assets = releaseData['assets'] as List<dynamic>? ?? [];
      final byName = <String, Map<String, dynamic>>{};
      for (final a in assets) {
        final m = (a as Map).cast<String, dynamic>();
        final n = (m['name'] ?? '') as String;
        if (n.endsWith('.apk')) byName[n] = m;
      }
      final apkAssetName = pickApkAssetName(byName.keys.toList());
      if (apkAssetName == null) return null;
      final chosen = byName[apkAssetName]!;

      final apkUrl = (chosen['browser_download_url'] ?? '') as String;
      if (apkUrl.isEmpty) return null;
      // Gitee 不返回 size，缺失时为 0（此时只剩 SHA-256 校验）
      final apkSize = (chosen['size'] as num?)?.toInt() ?? 0;

      // 该资产的 SHA-256（CI 写进正文，形如 `<hex>  <文件名>`）；没有则只做体积校验。
      final apkSha256 = parseAssetHashes(bodyText)[apkAssetName.toLowerCase()];

      // 备用下载源（按可信度排序）：① 未命中的那个官方源（Gitee / GitHub 同包）；
      // ② 只有用户开启「更新镜像加速」时才追加第三方代理 ghproxy 的同一 GitHub 包。
      final extras = <String>[];
      if (fallbackBase.isNotEmpty && apkAssetName.isNotEmpty) {
        extras.add('$fallbackBase/$tagName/$apkAssetName');
      }
      if (apkAssetName.isNotEmpty && await isMirrorEnabled()) {
        extras.add('$_ghProxyPrefix$_ghDownloadBase/$tagName/$apkAssetName');
      }

      return UpdateInfo(
        version: remoteVersion,
        tagName: tagName,
        body: bodyText,
        apkDownloadUrl: apkUrl,
        apkSize: apkSize,
        apkSha256: apkSha256,
        extraApkUrls: extras,
      );
    } catch (e) {
      debugPrint('检查更新失败: $e');
      return null;
    }
  }

  /// 期望下载的资产名，按适配度排序：本机 ABI 对应的**分架构包** → **通用包**兜底。
  /// 分架构包约为通用包的一半（28MB vs 68MB），移动网络下差别明显。
  static List<String> preferredApkAssetNames() {
    String? abiName;
    try {
      final abi = Abi.current();
      if (abi == Abi.androidArm64) {
        abiName = 'app-arm64-v8a-release.apk';
      } else if (abi == Abi.androidArm) {
        abiName = 'app-armeabi-v7a-release.apk';
      } else if (abi == Abi.androidX64) {
        abiName = 'app-x86_64-release.apk';
      }
    } catch (_) {
      abiName = null; // 非 Android 平台（桌面 / 测试）没有 android ABI
    }
    return [
      ?abiName, // 非 Android 平台为 null，自动省略
      'app-release.apk',
    ];
  }

  /// 从 release 里实际可用的资产名中挑一个：优先 [preferredApkAssetNames]；
  /// 都不在（老版本可能只传了一个包）则退回第一个 .apk；一个 .apk 都没有则 null。
  static String? pickApkAssetName(List<String> availableNames) {
    final apks = availableNames.where((n) => n.endsWith('.apk')).toList();
    if (apks.isEmpty) return null;
    for (final want in preferredApkAssetNames()) {
      if (apks.contains(want)) return want;
    }
    return apks.first;
  }

  /// 解析 Release 正文里的「资产名 → SHA-256」表（CI 写入格式：每行 `<hex>  <文件名>`）。
  /// 只认「哈希 + 文件名」成对的写法：老式「单个 `SHA256: <hex>`」不知指哪个包，有歧义，不采用。
  static Map<String, String> parseAssetHashes(String body) {
    final map = <String, String>{};
    for (final m in RegExp(r'([0-9a-fA-F]{64})\s+(\S+\.apk)').allMatches(body)) {
      map[m.group(2)!.toLowerCase()] = m.group(1)!.toLowerCase();
    }
    return map;
  }

  /// 比较版本号，判断remote是否比current新
  static bool _isNewerVersion(String remote, String current) {
    final remoteParts = remote.split('.').map(int.tryParse).toList();
    final currentParts = current.split('.').map(int.tryParse).toList();

    for (var i = 0; i < 3; i++) {
      final r = (i < remoteParts.length) ? (remoteParts[i] ?? 0) : 0;
      final c = (i < currentParts.length) ? (currentParts[i] ?? 0) : 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }

  /// 检查版本是否已被忽略
  static Future<bool> _isIgnored(String version) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('user_settings',
        where: "key = ?", whereArgs: [_permanentlyIgnoredKey]);
    if (rows.isNotEmpty) {
      final ignored = (rows.first['value'] as String).split(',');
      if (ignored.contains(version)) return true;
    }

    final ignoreRow = await db.query('user_settings',
        where: "key = ?", whereArgs: [_ignoredVersionKey]);
    if (ignoreRow.isNotEmpty && ignoreRow.first['value'] == version) {
      return true;
    }

    return false;
  }

  /// 忽略当前版本（下次还会提醒）
  static Future<void> ignoreVersion(String version) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'user_settings',
      {'key': _ignoredVersionKey, 'value': version},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 永久忽略版本
  static Future<void> permanentlyIgnoreVersion(String version) async {
    final db = await DatabaseHelper.instance.database;
    // 读取现有永久忽略列表
    final rows = await db.query('user_settings',
        where: "key = ?", whereArgs: [_permanentlyIgnoredKey]);
    List<String> ignored = [];
    if (rows.isNotEmpty) {
      final val = rows.first['value'] as String;
      if (val.isNotEmpty) ignored = val.split(',');
    }
    if (!ignored.contains(version)) ignored.add(version);

    await db.insert(
      'user_settings',
      {'key': _permanentlyIgnoredKey, 'value': ignored.join(',')},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// 下载APK文件。
  /// 安全约束：仅允许本项目官方资产主机（GitHub 主源 + Gitee 镜像备用源），
  /// 禁用任何其他第三方镜像；下载完成后若提供 expectedSize / expectedSha256
  /// 则分别校验体积与哈希，不符即丢弃，杜绝投毒安装。
  ///
  /// [extraApkUrls] 为备用源（按可信度排序）。主源失败 —— 主机不受信任、连接失败、
  /// 非 200 或首字节超时 —— 时按顺序逐个尝试，每个候选都按同一份校验标准核对。
  static Future<File?> downloadApk(
    String url,
    void Function(double progress)? onProgress, {
    int expectedSize = 0,
    String? expectedSha256,
    List<String> extraApkUrls = const [],
  }) async {
    // 第三方代理是否放行，由设置开关统一裁决（调用方无需知情）。
    final allowMirror = await isMirrorEnabled();
    final seen = <String>{};
    for (final candidate in <String>[url, ...extraApkUrls]) {
      if (candidate.isEmpty || !seen.add(candidate)) continue;
      if (!isTrustedDownloadHost(candidate, allowMirror: allowMirror)) {
        debugPrint('跳过非受信任下载源: $candidate');
        continue;
      }
      final f = await _tryDownload(candidate, onProgress,
          expectedSize: expectedSize, expectedSha256: expectedSha256);
      if (f != null) return f;
      debugPrint('下载源失败，尝试下一个: $candidate');
    }
    return null;
  }

  /// 是否属于受信任的下载主机：本项目 GitHub / Gitee 官方资产主机，杜绝第三方投毒。
  /// [allowMirror] 为真时才额外放行第三方加速代理 ghproxy.net —— 对应设置里那个
  /// 需要用户确认风险告知才打开的开关。
  /// Gitee 下载会 302 到 foruda.gitee.com，http 包默认自动跟随重定向，无需额外处理。
  static bool isTrustedDownloadHost(String url, {bool allowMirror = false}) {
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
      return false;
    }
    final host = uri.host;
    return host == 'github.com' ||
        host == 'objects.githubusercontent.com' ||
        host.endsWith('.githubusercontent.com') ||
        host == 'gitee.com' ||
        host == 'foruda.gitee.com' ||
        (allowMirror && host == 'ghproxy.net');
  }

  /// 单个下载源尝试：15s 内未收到首字节判定该镜像过慢，返回 null 交由上层切换
  static Future<File?> _tryDownload(
    String url,
    void Function(double progress)? onProgress, {
    int expectedSize = 0,
    String? expectedSha256,
  }) async {
    final client = http.Client();
    File? file;
    try {
      final dir = await getTemporaryDirectory();
      final filePath = '${dir.path}/nihaisha_update.apk';
      file = File(filePath);
      if (await file.exists()) await file.delete();

      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request).timeout(
        const Duration(minutes: 5),
      );
      if (response.statusCode != 200) {
        debugPrint('下载失败[HTTP ${response.statusCode}]: $url');
        return null;
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;
      final sink = file.openWrite();

      final firstByteCompleter = Completer<void>();
      late StreamSubscription<List<int>> subscription;
      Timer? firstByteTimer;
      var firstByteArrived = false;

      firstByteTimer = Timer(const Duration(seconds: 15), () {
        if (!firstByteArrived) {
          debugPrint('镜像首字节超时，切换: $url');
          firstByteCompleter.completeError(Exception('first_byte_timeout'));
        }
      });

      subscription = response.stream.listen(
        (chunk) {
          if (!firstByteArrived) {
            firstByteArrived = true;
            firstByteTimer?.cancel();
          }
          sink.add(chunk);
          receivedBytes += chunk.length;
          if (totalBytes > 0 && onProgress != null) {
            onProgress(receivedBytes / totalBytes);
          }
        },
        onError: (e, _) => firstByteCompleter.completeError(e),
        onDone: () => firstByteCompleter.complete(),
        cancelOnError: true,
      );

      try {
        await firstByteCompleter.future;
      } catch (e) {
        firstByteTimer.cancel();
        await subscription.cancel();
        await sink.close();
        return null;
      }
      await sink.flush();
      await sink.close();
      if (expectedSize > 0) {
        final actual = await file.length();
        if (actual != expectedSize) {
          debugPrint('APK 体积校验不符：期望 $expectedSize，实际 $actual，已丢弃');
          await file.delete();
          return null;
        }
      }
      if (expectedSha256 != null) {
        final bytes = await file.readAsBytes();
        final digest = sha256.convert(bytes).toString().toLowerCase();
        if (digest != expectedSha256.toLowerCase()) {
          debugPrint('APK SHA-256 校验不符：期望 $expectedSha256，实际 $digest，已丢弃');
          await file.delete();
          return null;
        }
      }
      return file;
    } catch (e) {
      debugPrint('下载APK失败[$url]: $e');
      return null;
    } finally {
      client.close();
    }
  }
}
