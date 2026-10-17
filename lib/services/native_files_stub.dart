/// 原生文件能力的 **Web 存根**。
///
/// 浏览器没有本地文件系统 / APK 安装 / Android ABI 这些概念，因此：
/// - [androidAbiAssetName] 恒为 null（调用方回落到通用包，但 Web 上根本不会去下 APK）
/// - [downloadAndVerifyApk] 恒为 null（Web 版不做应用内更新，打开即最新版）
/// - [clearTempCacheBytes] 恒为 0（浏览器缓存由用户浏览器自己管）
///
/// 由 `native_files_stub.dart if (dart.library.io) native_files_io.dart` 条件导入选中。
library;

/// Web 上无 Android ABI 概念。
String? androidAbiAssetName() => null;

/// Web 版不支持应用内下载更新，直接返回 null（调用方按"下载失败"处理）。
Future<String?> downloadAndVerifyApk({
  required String url,
  required void Function(double progress) onProgress,
  required int expectedSize,
  required String? expectedSha256,
}) async =>
    null;

/// Web 上无临时目录可清理。
Future<int> clearTempCacheBytes() async => 0;
