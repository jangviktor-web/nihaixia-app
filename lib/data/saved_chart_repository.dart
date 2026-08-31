import 'database_helper.dart';

/// 自定义命盘库中的一条命盘。
///
/// 仅保存排盘所需的生辰与地点信息（含城市名/经纬度），回看时交由
/// [ZiweiChartScreen] 重新排盘，避免持久化整张命盘导致数据膨胀与失准。
class SavedChart {
  final int? id;
  final String name;
  final bool isMale;
  final String solarIso; // 公历出生时间 ISO8601（含时辰小时）
  final double? lng; // 出生地经度（东经）
  final double? lat; // 出生地纬度（北纬）
  final String? cityName; // 出生城市展示名（用于回看时回填）
  final int createdAt; // 毫秒时间戳

  const SavedChart({
    this.id,
    required this.name,
    required this.isMale,
    required this.solarIso,
    this.lng,
    this.lat,
    this.cityName,
    required this.createdAt,
  });

  Map<String, Object?> toRow() => {
        if (id != null) 'id': id,
        'name': name,
        'gender': isMale ? 1 : 0,
        'solar_iso': solarIso,
        'lng': lng,
        'lat': lat,
        'city_name': cityName,
        'created_at': createdAt,
      };

  factory SavedChart.fromRow(Map<String, Object?> row) => SavedChart(
        id: row['id'] as int?,
        name: row['name'] as String,
        isMale: (row['gender'] as int) == 1,
        solarIso: row['solar_iso'] as String,
        lng: (row['lng'] as num?)?.toDouble(),
        lat: (row['lat'] as num?)?.toDouble(),
        cityName: row['city_name'] as String?,
        createdAt: row['created_at'] as int,
      );
}

/// 命盘库仓储：封装 user_charts 表的增删查。
class SavedChartRepository {
  SavedChartRepository._();

  /// 插入一条命盘，返回自增主键。
  static Future<int> insert(SavedChart chart) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('user_charts', chart.toRow());
  }

  /// 列出全部命盘，按 created_at 倒序（最新在前）。
  static Future<List<SavedChart>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'user_charts',
      orderBy: 'created_at DESC',
    );
    return rows.map(SavedChart.fromRow).toList();
  }

  /// 按主键删除一条命盘。
  static Future<int> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    return db.delete('user_charts', where: 'id = ?', whereArgs: [id]);
  }
}
