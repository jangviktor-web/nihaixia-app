import 'dart:io';

/// 解压 `assets/guji/classic_index.json.gz`（构建期由
/// `tool/build_classic_search_index.py` 生成）。
List<int> gunzipBytes(List<int> data) => gzip.decode(data);
