import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

/// 单篇文档的阅读位置。
class ReadingProgress {
  /// 滚动偏移（像素）。
  final double offset;

  /// 记录时内容的总可滚动高度。内容长度变化时用它做等比换算。
  final double maxExtent;

  const ReadingProgress(this.offset, this.maxExtent);

  /// 内容总高从 [maxExtent] 变为 [newMax] 后应恢复到的位置。
  ///
  /// 规则：旧总高有效就等比换算，避免 App 更新导致内容变长/变短后跳到错处；
  /// 旧总高为 0（记录异常）时原样返回。
  double resolvedOffset(double newMax) {
    if (maxExtent <= 0 || newMax <= 0) return offset;
    return offset * newMax / maxExtent;
  }
}

/// 阅读进度存储：记住每篇文档读到哪，重开 App 后回到原处。
///
/// doc_key 约定：有 asset 的用 asset 路径，其余用页面标题（调用方可覆盖）。
class ReadingProgressRepository {
  /// 小于此偏移视为「刚打开、还没读」，不落库。
  static const double kMinOffset = 50;

  /// 距末尾小于此距离视为「已读完」，清除记录，下次从头读。
  static const double kEndThreshold = 100;

  static Future<void> save(
    String docKey,
    double offset,
    double maxExtent,
  ) async {
    if (docKey.isEmpty) return;
    final db = await DatabaseHelper.instance.database;
    if (offset < kMinOffset) {
      // 回到顶部：直接清掉旧记录，避免下次仍跳回旧位置
      await db.delete('reading_progress',
          where: 'doc_key = ?', whereArgs: [docKey]);
      return;
    }
    if (maxExtent > 0 && offset >= maxExtent - kEndThreshold) {
      await db.delete('reading_progress',
          where: 'doc_key = ?', whereArgs: [docKey]);
      return;
    }
    await db.insert(
      'reading_progress',
      {
        'doc_key': docKey,
        'offset': offset,
        'max_extent': maxExtent,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<ReadingProgress?> load(String docKey) async {
    if (docKey.isEmpty) return null;
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'reading_progress',
      where: 'doc_key = ?',
      whereArgs: [docKey],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return ReadingProgress(
      (row['offset'] as num?)?.toDouble() ?? 0,
      (row['max_extent'] as num?)?.toDouble() ?? 0,
    );
  }

  static Future<void> clear(String docKey) async {
    if (docKey.isEmpty) return;
    final db = await DatabaseHelper.instance.database;
    await db.delete('reading_progress',
        where: 'doc_key = ?', whereArgs: [docKey]);
  }
}
