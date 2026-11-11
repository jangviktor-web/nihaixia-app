import 'dart:io';

/// 解压 `assets/guji/classic_index.json.gz`（构建期由
/// `tool/build_classic_search_index.py` 生成）。
List<int> gunzipBytes(List<int> data) => gzip.decode(data);

/// 与 Web 实现对齐的异步版本：IO 上同步解压本来就够快，直接包一层。
Future<List<int>> gunzipBytesAsync(List<int> data) async => gunzipBytes(data);
