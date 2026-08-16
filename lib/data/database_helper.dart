import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/bookmark.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('nihaisha.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bookmarks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        category TEXT NOT NULL,
        source TEXT NOT NULL,
        folder_id INTEGER DEFAULT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE chat_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        text TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE search_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        query TEXT NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bookmark_folders(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT DEFAULT 'folder',
        sort_order INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE diagnosis_history(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meridian TEXT,
        pattern TEXT,
        formula TEXT,
        confidence REAL,
        answers TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE user_settings(
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE search_history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          query TEXT NOT NULL,
          timestamp TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      // bookmarks 表增加 folder_id 字段
      await db.execute('ALTER TABLE bookmarks ADD COLUMN folder_id INTEGER DEFAULT NULL');
      await db.execute('''
        CREATE TABLE bookmark_folders(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          icon TEXT DEFAULT 'folder',
          sort_order INTEGER DEFAULT 0,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE diagnosis_history(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          meridian TEXT,
          pattern TEXT,
          formula TEXT,
          confidence REAL,
          answers TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE user_settings(
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
  }

  Future<int> insertBookmark(Bookmark bookmark) async {
    final db = await database;
    return await db.insert('bookmarks', bookmark.toJson()..remove('id'));
  }

  Future<List<Bookmark>> getAllBookmarks() async {
    final db = await database;
    final result = await db.query('bookmarks', orderBy: 'created_at DESC');
    return result.map((json) => Bookmark.fromJson(json)).toList();
  }

  Future<List<Bookmark>> getBookmarksByCategory(String category) async {
    final db = await database;
    final result = await db.query(
      'bookmarks',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'created_at DESC',
    );
    return result.map((json) => Bookmark.fromJson(json)).toList();
  }

  Future<int> deleteBookmark(int id) async {
    final db = await database;
    return await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
  }

  Future<bool> isBookmarked(String title) async {
    final db = await database;
    final result = await db.query(
      'bookmarks',
      where: 'title = ?',
      whereArgs: [title],
    );
    return result.isNotEmpty;
  }

  Future<void> saveChatMessage(String text, bool isUser) async {
    final db = await database;
    await db.insert('chat_history', {
      'text': text,
      'is_user': isUser ? 1 : 0,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> clearChatHistory() async {
    final db = await database;
    await db.delete('chat_history');
  }

  // === 收藏文件夹 ===
  Future<int> insertFolder(String name) async {
    final db = await database;
    return await db.insert('bookmark_folders', {
      'name': name,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getAllFolders() async {
    final db = await database;
    return await db.query('bookmark_folders', orderBy: 'sort_order ASC');
  }

  Future<int> deleteFolder(int id) async {
    final db = await database;
    // 将该文件夹下的收藏的 folder_id 置空
    await db.update('bookmarks', {'folder_id': null},
        where: 'folder_id = ?', whereArgs: [id]);
    return await db.delete('bookmark_folders', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> moveBookmarkToFolder(int bookmarkId, int? folderId) async {
    final db = await database;
    await db.update('bookmarks', {'folder_id': folderId},
        where: 'id = ?', whereArgs: [bookmarkId]);
  }

  Future<List<Map<String, dynamic>>> getBookmarksWithFolder() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT b.*, f.name as folder_name
      FROM bookmarks b
      LEFT JOIN bookmark_folders f ON b.folder_id = f.id
      ORDER BY b.created_at DESC
    ''');
  }

  // === 诊断历史 ===
  Future<int> saveDiagnosisHistory(String? meridian, String? pattern,
      String? formula, double? confidence, String? answers) async {
    final db = await database;
    return await db.insert('diagnosis_history', {
      'meridian': meridian,
      'pattern': pattern,
      'formula': formula,
      'confidence': confidence,
      'answers': answers,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getDiagnosisHistory({int limit = 50}) async {
    final db = await database;
    return await db.query('diagnosis_history',
        orderBy: 'created_at DESC', limit: limit);
  }

  Future<void> clearDiagnosisHistory() async {
    final db = await database;
    await db.delete('diagnosis_history');
  }

  // === 通用键值设置（user_settings 表，key 主键） ===
  Future<String?> getSetting(String key) async {
    final db = await database;
    final rows = await db.query('user_settings',
        where: 'key = ?', whereArgs: [key]);
    if (rows.isNotEmpty) return rows.first['value'] as String;
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(
      'user_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // === 收藏导出 ===
  Future<List<Map<String, dynamic>>> exportBookmarks() async {
    final db = await database;
    final bookmarks = await db.query('bookmarks', orderBy: 'created_at DESC');
    final folders = await db.query('bookmark_folders', orderBy: 'sort_order ASC');
    return [
      {'folders': folders, 'bookmarks': bookmarks},
    ];
  }
}
