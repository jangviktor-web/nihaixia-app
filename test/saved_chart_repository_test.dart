import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:nihaisha_app/data/saved_chart_repository.dart';
import 'package:nihaisha_app/data/database_helper.dart';

/// 命盘库仓储往返测试（sqflite_common_ffi 在桌面 test runner 上可用）。
void main() {
  setUpAll(() {
    // flutter test 的桌面 runner 需要 ffi 版的 sqflite 工厂。
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    // 重置已缓存的数据库连接，确保每次都重新打开（版本 5 含 user_charts 表）。
    DatabaseHelper.resetForTest();
  });

  test('insert → getAll → delete 往返', () async {
    final inserted = await SavedChartRepository.insert(SavedChart(
      name: '测试命盘 1990-06-15 男',
      isMale: true,
      solarIso: DateTime(1990, 6, 15, 0, 0).toIso8601String(),
      lng: 116.41,
      lat: 39.9,
      cityName: '北京市（北京市）',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    expect(inserted, greaterThan(0), reason: 'insert 应返回自增主键');

    final all = await SavedChartRepository.getAll();
    expect(all, isNotEmpty);
    final got = all.firstWhere((c) => c.id == inserted);
    expect(got.name, '测试命盘 1990-06-15 男');
    expect(got.isMale, isTrue);
    expect(got.lng, 116.41);
    expect(got.lat, 39.9);
    expect(got.cityName, '北京市（北京市）');
    // 默认按 created_at 倒序，最新插入应在最前
    expect(all.first.id, inserted);

    final deleted = await SavedChartRepository.delete(inserted);
    expect(deleted, 1);
    final after = await SavedChartRepository.getAll();
    expect(after.any((c) => c.id == inserted), isFalse);
  });

  test('getAll 倒序：后插入的在前', () async {
    final t = DateTime.now().millisecondsSinceEpoch;
    final a = await SavedChartRepository.insert(SavedChart(
      name: 'A',
      isMale: true,
      solarIso: DateTime(1980, 1, 1, 0, 0).toIso8601String(),
      createdAt: t,
    ));
    final b = await SavedChartRepository.insert(SavedChart(
      name: 'B',
      isMale: false,
      solarIso: DateTime(1990, 1, 1, 0, 0).toIso8601String(),
      createdAt: t + 1000,
    ));
    final all = await SavedChartRepository.getAll();
    expect(all.firstWhere((c) => c.id == b).name, 'B');
    expect(all.firstWhere((c) => c.id == a).name, 'A');
    // 清理
    await SavedChartRepository.delete(a);
    await SavedChartRepository.delete(b);
  });
}
