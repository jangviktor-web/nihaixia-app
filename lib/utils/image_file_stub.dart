/// 长图落盘/落浏览器的平台实现（IO 平台）。
///
/// Web 走 [image_file_web.dart]：浏览器写不了本地文件系统，改为触发下载。
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// IO 平台不写浏览器下载，恒为 false。
const bool needsBrowserDownload = false;

/// 写临时文件，返回路径（供 [ShareXFiles] 使用）。
Future<String> writeTempPng(Uint8List bytes, String filename) async {
  final dir = await getTemporaryDirectory();
  final f = File('${dir.path}/$filename');
  await f.writeAsBytes(bytes, flush: true);
  return f.path;
}

/// 存到 App 外部专属目录（无需存储权限），返回路径。
Future<String> savePngToDisk(Uint8List bytes, String filename) async {
  final dir = await getExternalStorageDirectory() ??
      await getApplicationDocumentsDirectory();
  final f = File('${dir.path}/$filename');
  await f.writeAsBytes(bytes, flush: true);
  return f.path;
}
