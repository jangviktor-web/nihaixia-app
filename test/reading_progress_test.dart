// 阅读进度回归：存取往返 / 过小偏移不落库 / 读到末尾清除 / 内容变化按比例换算。
// 运行：flutter test test/reading_progress_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:nihaisha_app/data/database_helper.dart';
import 'package:nihaisha_app/data/reading_progress_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    // 独立 DB 文件名，避免与其它测试共用同一库互相干扰
    DatabaseHelper.testDbName =
        'reading_progress_test_${DateTime.now().microsecondsSinceEpoch}.db';
    DatabaseHelper.resetForTest();
  });

  test('存取往返：同一 docKey 读回相同的偏移与总高', () async {
    await ReadingProgressRepository.save('assets/guji/lingshu.txt', 1200, 8000);
    final p = await ReadingProgressRepository.load('assets/guji/lingshu.txt');
    expect(p, isNotNull);
    expect(p!.offset, 1200);
    expect(p.maxExtent, 8000);

    // 再次保存覆盖旧值，而不是插入新行
    await ReadingProgressRepository.save('assets/guji/lingshu.txt', 2400, 8000);
    final p2 = await ReadingProgressRepository.load('assets/guji/lingshu.txt');
    expect(p2!.offset, 2400);
  });

  test('不同文档互不干扰', () async {
    await ReadingProgressRepository.save('doc-a', 500, 5000);
    await ReadingProgressRepository.save('doc-b', 900, 5000);
    expect((await ReadingProgressRepository.load('doc-a'))!.offset, 500);
    expect((await ReadingProgressRepository.load('doc-b'))!.offset, 900);
    expect(await ReadingProgressRepository.load('doc-c'), isNull);
  });

  test('偏移过小视为没读：不落库，且清掉旧记录', () async {
    await ReadingProgressRepository.save('doc-small', 800, 5000);
    expect(await ReadingProgressRepository.load('doc-small'), isNotNull);

    // 用户手动滚回顶部再退出 → 记录应被清掉，下次从头开始
    await ReadingProgressRepository.save('doc-small', 12, 5000);
    expect(await ReadingProgressRepository.load('doc-small'), isNull);
  });

  test('读到末尾视为读完：清除记录', () async {
    await ReadingProgressRepository.save('doc-end', 4950, 5000);
    expect(await ReadingProgressRepository.load('doc-end'), isNull,
        reason: '距末尾不足阈值应清除，下次从头读');
  });

  test('内容变化时按比例换算偏移', () async {
    // 原文总高 8000、读到 2000（即 25%）
    const p = ReadingProgress(2000, 8000);
    // 内容变长到 16000 → 应落到 4000，保持同一相对位置
    expect(p.resolvedOffset(16000), 4000);
    // 内容变短到 4000 → 应落到 1000
    expect(p.resolvedOffset(4000), 1000);
    // 旧总高缺失时原样返回，不做除法
    expect(const ReadingProgress(300, 0).resolvedOffset(9000), 300);
  });
}
