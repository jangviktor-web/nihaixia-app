/// 原生文件能力（Android / iOS / 桌面实现）。
///
/// 本文件**故意** import `dart:ffi` 与 `dart:io`——这两个库在 Web 平台不存在。
/// 消费方（`update_service.dart` / `app_dialogs.dart`）通过条件导入选择本文件或
/// [native_files_stub.dart]，从而让同一份业务代码在 Web 上也能编译。
///
/// 这里只放"必须碰本地文件系统 / 原生 ABI"的能力，业务逻辑留在消费方。
library;

import 'dart:async';
import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show Abi;

import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// 本机 Android ABI 对应的**分架构** APK 资产名。
///
/// 非 Android 平台（桌面 / 测试 / Web 存根）返回 null，调用方据此回落到通用包。
String? androidAbiAssetName() {
  try {
    final abi = Abi.current();
    if (abi == Abi.androidArm64) return 'app-arm64-v8a-release.apk';
    if (abi == Abi.androidArm) return 'app-armeabi-v7a-release.apk';
    if (abi == Abi.androidX64) return 'app-x86_64-release.apk';
    return null;
  } catch (_) {
    return null; // 非 Android 平台没有 android ABI
  }
}

/// 下载 APK 到临时目录并做体积 / SHA-256 校验，返回**文件路径**；失败返回 null。
///
/// 从 `update_service.dart` 的 `_tryDownload` 原样迁出，逻辑未改：
/// - 15s 未收到首字节判定该镜像过慢
/// - 体积不符 / 哈希不符即删除文件并返回 null（杜绝投毒安装）
Future<String?> downloadAndVerifyApk({
  required String url,
  required void Function(double progress) onProgress,
  required int expectedSize,
  required String? expectedSha256,
}) async {
  final client = http.Client();
  try {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/nihaisha_update.apk';
    final file = File(filePath);
    if (await file.exists()) await file.delete();

    final request = http.Request('GET', Uri.parse(url));
    final response = await client.send(request).timeout(
      const Duration(minutes: 5),
    );
    if (response.statusCode != 200) {
      debugPrintSafe('下载失败[HTTP ${response.statusCode}]: $url');
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
        debugPrintSafe('镜像首字节超时，切换: $url');
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
        if (totalBytes > 0) {
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
        debugPrintSafe('APK 体积校验不符：期望 $expectedSize，实际 $actual，已丢弃');
        await file.delete();
        return null;
      }
    }
    if (expectedSha256 != null) {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes).toString().toLowerCase();
      if (digest != expectedSha256.toLowerCase()) {
        debugPrintSafe('APK SHA-256 校验不符，已丢弃');
        await file.delete();
        return null;
      }
    }
    return filePath;
  } catch (e) {
    debugPrintSafe('下载APK失败[$url]: $e');
    return null;
  } finally {
    client.close();
  }
}

/// 清空临时目录，返回清理掉的字节数。
Future<int> clearTempCacheBytes() async {
  final tempDir = await getTemporaryDirectory();
  int totalSize = 0;
  if (await tempDir.exists()) {
    final files = tempDir.listSync(recursive: true);
    for (final file in files) {
      if (file is File) totalSize += await file.length();
    }
    for (final file in files) {
      try {
        if (file is File) await file.delete();
      } catch (_) {}
    }
  }
  return totalSize;
}

/// 不依赖 flutter 的 debugPrint，避免本文件反向依赖 Flutter SDK 的 foundation。
void debugPrintSafe(String message) {
  // ignore: avoid_print
  print(message);
}
