/// 数据库初始化（Web 实现）。
///
/// 浏览器里没有原生 SQLite，`sqflite` 的默认工厂不可用。这里换成
/// `databaseFactoryFfiWeb`：SQLite 被编译成 WASM，跑在独立 Worker 里，
/// 对外仍是同一套 sqflite API，业务代码（[DatabaseHelper] 等）零改动。
///
/// ⚠️ 该工厂还需要 `sqflite_sw.js` + `sqlite3.wasm` 放在 `web/` 下
/// （`dart run sqflite_common_ffi_web:setup` 生成，CI 与本地构建前都会跑），
/// 否则打开数据库时会报 Worker 404。
library;

// 从 sqflite_common 取 `databaseFactory` 的 setter：sqflite 只为兼容层
// re-export 了 getter，直接 import 它会拿不到 setter。
import 'package:sqflite_common/sqflite.dart' show databaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void initDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}
