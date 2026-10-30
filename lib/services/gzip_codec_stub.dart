/// Web 平台占位：`dart:io` 的 gzip 在 Web 不可用。
///
/// 本应用只发布 Android 包，经典索引解压走 [gzip_codec_io.dart]；
/// 保留本文件是为了在 Web 编译（如 `flutter test --platform chrome` 或
/// 后续 Web 适配）时不因 import dart:io 直接编译失败。
library;

List<int> gunzipBytes(List<int> data) {
  throw UnsupportedError('当前平台不支持 gzip 解压（仅移动端可用）');
}
