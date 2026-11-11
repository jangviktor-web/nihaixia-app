/// 数据库初始化存根（IO 平台：Android / iOS / 桌面 / 单测）。
///
/// Web 走 [database_factory_web.dart]，那里要 `databaseFactoryFfiWeb` 并把
/// SQLite 的 WASM/Worker 资源挂到页面上；IO 平台不需要任何初始化，
/// 保持 `sqflite` 默认工厂即可，因此本文件是空的。
library;

void initDatabaseFactory() {}
