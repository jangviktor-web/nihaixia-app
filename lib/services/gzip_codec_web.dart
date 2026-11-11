/// Web 平台的 gzip 解压：浏览器原生 `DecompressionStream`，无 dart:io 依赖。
///
/// 经典检索索引（`assets/guji/classic_index.json.gz`，3MB 压 → 约 30MB 文本）
/// 必须能在浏览器里解开，否则搜索页与问倪师 AI 的原文召回全部为空。
///
/// 实现走 `dart:js_interop` 调原生 API，不引第三方 wasm 解压包：索引只在启动后
/// 解一次，原生实现比 Dart 侧的 JS 解压库更快、也不额外增加产物体积。
/// Chrome 80+ / Safari 16.4+ 支持 `DecompressionStream('gzip')`；不支持的浏览器
/// 会抛错，由调用方按「索引加载失败」降级（搜索不可用），不影响其它功能。
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

@JS('DecompressionStream')
extension type _DecompressionStream._(JSObject _) implements JSObject {
  external _DecompressionStream(String format);
  external _ReadableStream get readable;
  external _WritableStream get writable;
}

@JS('Response')
extension type _Response._(JSObject _) implements JSObject {
  external _Response(JSObject bodyStream);
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

extension type _ReadableStream._(JSObject _) implements JSObject {}

extension type _WritableStream._(JSObject _) implements JSObject {}

extension type _Writer._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> write(JSAny chunk);
  external JSPromise<JSAny?> close();
  external void releaseLock();
}

extension on _WritableStream {
  external _Writer getWriter();
}

List<int> gunzipBytes(List<int> data) {
  throw UnsupportedError('Web 上 gzip 只能异步解压，请用 gunzipBytesAsync');
}

Future<List<int>> gunzipBytesAsync(List<int> data) async {
  final decompressor = _DecompressionStream('gzip');
  final writer = decompressor.writable.getWriter();
  // 先把解压后的流交给 Response，再喂数据 —— 顺序反过来在 Safari 上会卡住
  // （可写端背压等着有人读）。
  final bytesFuture = _Response(decompressor.readable).arrayBuffer().toDart;
  try {
    await writer.write(Uint8List.fromList(data).toJS).toDart;
    await writer.close().toDart;
  } finally {
    writer.releaseLock();
  }
  final buffer = await bytesFuture;
  return buffer.toDart.asUint8List();
}
