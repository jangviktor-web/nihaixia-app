/// 既不认 io 也不认 js_interop 的平台占位（实际构建里不会命中）。
///
/// 真正生效的两个实现是 [gzip_codec_io.dart]（移动端/桌面）与
/// [gzip_codec_web.dart]（浏览器）。
library;

List<int> gunzipBytes(List<int> data) {
  throw UnsupportedError('当前平台不支持 gzip 解压');
}

Future<List<int>> gunzipBytesAsync(List<int> data) async => gunzipBytes(data);
