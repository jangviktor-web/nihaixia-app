// 问倪师AI 对话持久化回归：建会话 / 追加轮次 / 裁剪上限 / 重命名 / 删除 / 清空。
// 运行：flutter test test/llm_chat_persistence_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/database_helper.dart';
import 'package:nihaisha_app/data/llm_chat_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    // 独立 DB 文件：全量并发跑时不与其它测试的共享库互相锁/清库
    DatabaseHelper.testDbName = 'llm_chat_test.db';
    DatabaseHelper.resetForTest();
    await LlmChatRepository.clearAll();
  });

  test('会话与轮次：建 → 追加 → 读回 → 改名 → 删除 → 清空', () async {
    // 建两个会话（列表按活跃时间倒序）
    final s1 = await LlmChatRepository.createSession('带状疱疹怎么治');
    final s2 = await LlmChatRepository.createSession('失眠针灸取穴');

    var list = await LlmChatRepository.listSessions();
    expect(list.map((s) => s.id), [s2, s1], reason: '最近活跃的会话排最前');

    // 追加轮次（含医案 seq）
    expect(
      await LlmChatRepository.appendTurn(s2,
          question: '失眠扎什么穴？',
          answer: '神门、安眠…',
          caseSeqs: [42, 299]),
      isTrue,
    );
    await LlmChatRepository.appendTurn(s2,
        question: '白天犯困呢？', answer: ' … ');

    final turns = await LlmChatRepository.loadTurns(s2);
    expect(turns.length, 2);
    expect(turns[0].question, '失眠扎什么穴？');
    expect(turns[0].caseSeqs, [42, 299], reason: 'meta 里的医案指针要能读回');
    expect(turns[1].question, '白天犯困呢？');

    // 轮次只属于自己的会话
    expect(await LlmChatRepository.loadTurns(s1), isEmpty);

    // 改名
    await LlmChatRepository.renameSession(s2, '失眠专题');
    list = await LlmChatRepository.listSessions();
    expect(list.firstWhere((s) => s.id == s2).title, '失眠专题');

    // 删除会话连带轮次
    await LlmChatRepository.deleteSession(s1);
    list = await LlmChatRepository.listSessions();
    expect(list.map((s) => s.id), [s2]);
    expect(await LlmChatRepository.loadTurns(s1), isEmpty);

    // 清空全部
    await LlmChatRepository.clearAll();
    expect(await LlmChatRepository.listSessions(), isEmpty);
    expect(await LlmChatRepository.loadTurns(s2), isEmpty);
  });

  test('单会话轮次上限：超过 50 轮裁掉最旧', () async {
    final s = await LlmChatRepository.createSession('长会话');
    for (var i = 1; i <= LlmChatRepository.maxTurnsPerSession + 5; i++) {
      await LlmChatRepository.appendTurn(s, question: 'Q$i', answer: 'A$i');
    }
    final turns = await LlmChatRepository.loadTurns(s);
    expect(turns.length, LlmChatRepository.maxTurnsPerSession);
    // 裁掉的是最旧的：第一轮应是 Q6（前 5 轮被裁）
    expect(turns.first.question, 'Q6');
    expect(turns.last.question, 'Q${LlmChatRepository.maxTurnsPerSession + 5}');
    await LlmChatRepository.deleteSession(s);
  });

  test('meta 空串 / 脏数据读回为空列表，不抛异常', () async {
    expect(LlmChatRepository.jsonEncodeSeqs(const []), '');
    expect(LlmChatRepository.jsonEncodeSeqs([8, 42]), '[8,42]');
    // 手工塞脏 meta 再读回
    final s = await LlmChatRepository.createSession('脏数据');
    final db = await DatabaseHelper.instance.database;
    await db.insert('llm_turns', {
      'session_id': s,
      'question': 'q',
      'answer': 'a',
      'meta': 'not-json',
      'created_at': DateTime.now().toIso8601String(),
    });
    final turns = await LlmChatRepository.loadTurns(s);
    expect(turns.single.caseSeqs, isEmpty);
    await LlmChatRepository.deleteSession(s);
  });
}
