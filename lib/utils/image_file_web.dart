/// 长图落盘/落浏览器的平台实现（Web）。
///
/// 浏览器没有可写的本地文件系统：`savePngToDisk` 改为触发一次下载，
/// 返回的「路径」是下载文件名（页面提示用）；系统分享面板在桌面浏览器上
/// 普遍不可用，调用方统一走下载。
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

/// Web 恒为 true：`ChartExportPage` 据此把「保存 / 分享」都落到浏览器下载。
bool get needsBrowserDownload => true;

/// Web 无临时目录，返回文件名本身（调用方只用它做提示文案）。
Future<String> writeTempPng(Uint8List bytes, String filename) async => filename;

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external _Blob(JSArray<JSAny> parts, JSObject options);
}

@JS('URL')
extension type _Url._(JSObject _) implements JSObject {
  external static String createObjectURL(_Blob blob);
  external static void revokeObjectURL(String url);
}

@JS('document')
external _Document get _document;

extension type _Document._(JSObject _) implements JSObject {
  external _AnchorElement createElement(String tag);
}

extension type _AnchorElement._(JSObject _) implements JSObject {
  external set href(String url);
  external set download(String name);
  external void click();
}

/// 触发浏览器下载，返回文件名。
Future<String> savePngToDisk(Uint8List bytes, String filename) async {
  final blob = _Blob(
    <JSAny>[bytes.toJS].toJS,
    {'type': 'image/png'}.jsify()! as JSObject,
  );
  final url = _Url.createObjectURL(blob);
  try {
    final anchor = _document.createElement('a');
    anchor.href = url;
    anchor.download = filename;
    anchor.click();
  } finally {
    _Url.revokeObjectURL(url);
  }
  return filename;
}
