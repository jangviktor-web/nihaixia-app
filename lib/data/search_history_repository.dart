import 'database_helper.dart';

class SearchHistoryRepository {
  static final DatabaseHelper _db = DatabaseHelper.instance;

  static Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;
    final db = await _db.database;
    // 去重：先删除旧的同名记录
    await db.delete('search_history', where: 'query = ?', whereArgs: [query.trim()]);
    // 插入新记录
    await db.insert('search_history', {
      'query': query.trim(),
      'timestamp': DateTime.now().toIso8601String(),
    });
    // 裁剪到50条
    await db.rawDelete('''
      DELETE FROM search_history WHERE id NOT IN (
        SELECT id FROM search_history ORDER BY timestamp DESC LIMIT 50
      )
    ''');
  }

  static Future<List<String>> getRecentSearches({int limit = 20}) async {
    final db = await _db.database;
    final result = await db.query(
      'search_history',
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    return result.map((r) => r['query'] as String).toList();
  }

  static Future<void> deleteSearch(String query) async {
    final db = await _db.database;
    await db.delete('search_history', where: 'query = ?', whereArgs: [query]);
  }

  static Future<void> clearAll() async {
    final db = await _db.database;
    await db.delete('search_history');
  }
}
