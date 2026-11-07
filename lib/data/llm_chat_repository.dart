import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import 'database_helper.dart';

/// 问倪师AI 的对话持久化（多会话）。
///
/// 两张表：`llm_sessions`（会话）+ `llm_turns`（轮次）。ponytail：
/// 轮次只存问答与医案 seq 指针，不存讲义片段正文 —— 片段是"当时检索出来的"，
/// 重算会变，存了反而出现内容与回答不匹配。
class LlmChatSession {
  final int id;
  String title;
  final String createdAt;
  final String updatedAt;

  LlmChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });
}

class LlmChatTurn {
  final int id;
  final int sessionId;
  final String question;
  final String answer;

  /// 该轮命中的医案 seq（供「相关倪师医案」卡片恢复，指向医案库反查）。
  final List<int> caseSeqs;
  final String createdAt;

  LlmChatTurn({
    required this.id,
    required this.sessionId,
    required this.question,
    required this.answer,
    this.caseSeqs = const [],
    required this.createdAt,
  });
}

class LlmChatRepository {
  LlmChatRepository._();

  /// 单会话保留的最多轮次；超出裁掉最旧。
  /// 给模型只带最近 3 轮，存更多只是阅读，50 已是充裕上限。
  static const int maxTurnsPerSession = 50;

  static Future<Database> get _database => DatabaseHelper.instance.database;

  // ---------------- 会话 ----------------

  static Future<List<LlmChatSession>> listSessions() async {
    final db = await _database;
    final rows = await db.query('llm_sessions', orderBy: 'updated_at DESC');
    return [
      for (final r in rows)
        LlmChatSession(
          id: r['id'] as int,
          title: r['title'] as String,
          createdAt: r['created_at'] as String,
          updatedAt: r['updated_at'] as String,
        ),
    ];
  }

  /// 新建会话。返回 id。
  static Future<int> createSession(String title, {String? createdAt}) async {
    final db = await _database;
    final now = createdAt ?? DateTime.now().toIso8601String();
    return db.insert('llm_sessions', {
      'title': title,
      'created_at': now,
      'updated_at': now,
    });
  }

  static Future<void> renameSession(int id, String title) async {
    final db = await _database;
    await db.update(
      'llm_sessions',
      {'title': title},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除会话（连带其全部轮次）。
  static Future<void> deleteSession(int id) async {
    final db = await _database;
    await db.delete('llm_turns', where: 'session_id = ?', whereArgs: [id]);
    await db.delete('llm_sessions', where: 'id = ?', whereArgs: [id]);
  }

  /// 最近活跃的会话（没有则返回 null，调用方懒建）。
  static Future<LlmChatSession?> latestSession() async {
    final list = await listSessions();
    return list.isEmpty ? null : list.first;
  }

  // ---------------- 轮次 ----------------

  static Future<List<LlmChatTurn>> loadTurns(int sessionId) async {
    final db = await _database;
    final rows = await db.query(
      'llm_turns',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id ASC',
    );
    return [
      for (final r in rows)
        LlmChatTurn(
          id: r['id'] as int,
          sessionId: r['session_id'] as int,
          question: r['question'] as String,
          answer: r['answer'] as String,
          caseSeqs: _decodeSeqs(r['meta'] as String? ?? ''),
          createdAt: r['created_at'] as String,
        ),
    ];
  }

  /// 追加一轮并裁剪；写库失败静默（记录是附属功能，不能打断回答展示）。
  /// 返回是否写入成功。
  static Future<bool> appendTurn(
    int sessionId, {
    required String question,
    required String answer,
    List<int> caseSeqs = const [],
  }) async {
    try {
      final db = await _database;
      final now = DateTime.now().toIso8601String();
      await db.insert('llm_turns', {
        'session_id': sessionId,
        'question': question,
        'answer': answer,
        'meta': jsonEncodeSeqs(caseSeqs),
        'created_at': now,
      });
      await db.update(
        'llm_sessions',
        {'updated_at': now},
        where: 'id = ?',
        whereArgs: [sessionId],
      );
      await _trim(sessionId);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _trim(int sessionId) async {
    final db = await _database;
    final rows = await db.query(
      'llm_turns',
      columns: ['id'],
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id DESC',
      limit: 1,
      // offset = max：取「第 max+1 新」的一行作为删除分界（保留恰好 max 条）
      offset: maxTurnsPerSession,
    );
    if (rows.isEmpty) return;
    final cutoff = rows.first['id'] as int;
    await db.delete(
      'llm_turns',
      where: 'session_id = ? AND id <= ?',
      whereArgs: [sessionId, cutoff],
    );
  }

  static Future<void> clearAll() async {
    final db = await _database;
    await db.delete('llm_turns');
    await db.delete('llm_sessions');
  }

  // ---------------- meta 序列化（ponytail：手写，不引 json 序列化器）--------

  static String jsonEncodeSeqs(List<int> seqs) =>
      seqs.isEmpty ? '' : jsonEncode(seqs);

  static List<int> _decodeSeqs(String meta) {
    if (meta.isEmpty) return const [];
    try {
      final body = meta.trim();
      if (!body.startsWith('[') || !body.endsWith(']')) return const [];
      return [
        for (final p in body.substring(1, body.length - 1).split(','))
          if (int.tryParse(p.trim()) != null) int.parse(p.trim()),
      ];
    } catch (_) {
      return const [];
    }
  }
}
