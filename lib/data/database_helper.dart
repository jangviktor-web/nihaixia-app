import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/bookmark.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  /// 收藏变更版本号：每次增删收藏自增，供收藏页实时刷新（解决「退出应用才更新」问题）。
  static final ValueNotifier<int> bookmarkVersion = ValueNotifier<int>(0);

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
      version: 5,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  /// 仅供测试：重置已打开的数据库连接（下次访问重新打开）。
  @visibleForTesting
  static void resetForTest() {
    _database = null;
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

    await db.execute('''
      CREATE TABLE medical_case_bookmarks(
        seq INTEGER PRIMARY KEY,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE medical_case_recent(
        seq INTEGER PRIMARY KEY,
        viewed_at TEXT NOT NULL
      )
    ''');

    // 自定义命盘库（首次安装即建表；旧库由 onUpgrade 的 <5 分支补齐）
    await db.execute('''
      CREATE TABLE user_charts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        gender INTEGER NOT NULL,
        solar_iso TEXT NOT NULL,
        lng REAL,
        lat REAL,
        city_name TEXT,
        created_at INTEGER NOT NULL
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
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE medical_case_bookmarks(
          seq INTEGER PRIMARY KEY,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE medical_case_recent(
          seq INTEGER PRIMARY KEY,
          viewed_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      // 自定义命盘库（保存用户排盘生辰，便于随时回看）
      await db.execute('''
        CREATE TABLE user_charts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          gender INTEGER NOT NULL,
          solar_iso TEXT NOT NULL,
          lng REAL,
          lat REAL,
          city_name TEXT,
          created_at INTEGER NOT NULL
        )
      ''');
    }
  }

  Future<int> insertBookmark(Bookmark bookmark) async {
    final db = await database;
    final id = await db.insert('bookmarks', bookmark.toJson()..remove('id'));
    bookmarkVersion.value++;
    return id;
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
    final count = await db.delete('bookmarks', where: 'id = ?', whereArgs: [id]);
    bookmarkVersion.value++;
    return count;
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

  // === 医案收藏（按医案 seq 唯一） ===
  Future<bool> isMedicalCaseBookmarked(int seq) async {
    final db = await database;
    final rows = await db.query(
      'medical_case_bookmarks',
      where: 'seq = ?',
      whereArgs: [seq],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> setMedicalCaseBookmarked(int seq, bool bookmarked) async {
    final db = await database;
    if (bookmarked) {
      await db.insert('medical_case_bookmarks', {
        'seq': seq,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.delete(
        'medical_case_bookmarks',
        where: 'seq = ?',
        whereArgs: [seq],
      );
    }
  }

  Future<List<int>> getBookmarkedMedicalCaseSeqs() async {
    final db = await database;
    final rows = await db.query(
      'medical_case_bookmarks',
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => r['seq'] as int).toList();
  }

  // === 医案最近浏览（按医案 seq 唯一，时间倒序） ===
  Future<void> upsertMedicalCaseRecent(int seq) async {
    final db = await database;
    await db.insert('medical_case_recent', {
      'seq': seq,
      'viewed_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<int>> getRecentMedicalCaseSeqs({int limit = 20}) async {
    final db = await database;
    final rows = await db.query(
      'medical_case_recent',
      orderBy: 'viewed_at DESC',
      limit: limit,
    );
    return rows.map((r) => r['seq'] as int).toList();
  }

  Future<void> clearMedicalCaseRecent() async {
    final db = await database;
    await db.delete('medical_case_recent');
  }
}
