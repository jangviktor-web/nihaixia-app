import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SettingsRepository extends ChangeNotifier {
  static final SettingsRepository instance = SettingsRepository._init();
  SettingsRepository._init();

  ThemeMode _themeMode = ThemeMode.system;
  double _textScaleFactor = 1.0;
  String _defaultGender = ''; // ''=不设置, 'male', 'female'
  String _diagnosticLevel = 'detailed'; // 'simple' or 'detailed'
  bool _autoCopyPrescription = false;
  bool _loaded = false;

  // ---- 排盘共享设置（紫微 / 八字 同步）----
  bool _useTrueSolarTime = true; // 紫微真太阳时校准（默认开启）
  bool _distinguishZiShiEnabled = false; // 区分早晚子时开关（true=开启：23:00–01:00 按晚子时/早子时精确区分；默认关=子时归自然日）
  bool _fireEarthSame = true; // 长生十二神起长生口径（true=火土同宫，现代子平主流）

  // ---- 最近出生地点（真太阳时校正用，紫微/八字共用；null=未设置）----
  String? _lastCityName;
  double? _lastLng;
  double? _lastLat;

  ThemeMode get themeMode => _themeMode;
  double get textScaleFactor => _textScaleFactor;
  String get defaultGender => _defaultGender;
  String get diagnosticLevel => _diagnosticLevel;
  bool get autoCopyPrescription => _autoCopyPrescription;
  bool get isLoaded => _loaded;
  bool get useTrueSolarTime => _useTrueSolarTime;
  bool get distinguishZiShiEnabled => _distinguishZiShiEnabled;
  bool get fireEarthSame => _fireEarthSame;
  String? get lastCityName => _lastCityName;
  double? get lastLng => _lastLng;
  double? get lastLat => _lastLat;

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('user_settings');
    for (final row in rows) {
      final key = row['key'] as String;
      final value = row['value'] as String;
      switch (key) {
        case 'theme_mode':
          _themeMode = ThemeMode.values.firstWhere(
            (e) => e.name == value,
            orElse: () => ThemeMode.system,
          );
          break;
        case 'text_scale_factor':
          _textScaleFactor = double.tryParse(value) ?? 1.0;
          break;
        case 'default_gender':
          _defaultGender = value;
          break;
        case 'diagnostic_level':
          _diagnosticLevel = value;
          break;
        case 'auto_copy_prescription':
          _autoCopyPrescription = value == 'true';
          break;
        case 'use_true_solar_time':
          _useTrueSolarTime = value == 'true';
          break;
        case 'distinguish_zi_shi_enabled':
          _distinguishZiShiEnabled = value == 'true';
          break;
        case 'fire_earth_same':
          _fireEarthSame = value == 'true';
          break;
        case 'last_city_name':
          _lastCityName = value.isEmpty ? null : value;
          break;
        case 'last_lng':
          _lastLng = double.tryParse(value);
          break;
        case 'last_lat':
          _lastLat = double.tryParse(value);
          break;
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await _save('theme_mode', mode.name);
  }

  Future<void> setTextScaleFactor(double factor) async {
    _textScaleFactor = factor;
    notifyListeners();
    await _save('text_scale_factor', factor.toStringAsFixed(2));
  }

  Future<void> setDefaultGender(String gender) async {
    _defaultGender = gender;
    notifyListeners();
    await _save('default_gender', gender);
  }

  Future<void> setDiagnosticLevel(String level) async {
    _diagnosticLevel = level;
    notifyListeners();
    await _save('diagnostic_level', level);
  }

  Future<void> setAutoCopyPrescription(bool value) async {
    _autoCopyPrescription = value;
    notifyListeners();
    await _save('auto_copy_prescription', value.toString());
  }

  Future<void> setUseTrueSolarTime(bool value) async {
    _useTrueSolarTime = value;
    notifyListeners();
    await _save('use_true_solar_time', value.toString());
  }

  Future<void> setDistinguishZiShiEnabled(bool value) async {
    _distinguishZiShiEnabled = value;
    notifyListeners();
    await _save('distinguish_zi_shi_enabled', value.toString());
  }

  Future<void> setFireEarthSame(bool value) async {
    _fireEarthSame = value;
    notifyListeners();
    await _save('fire_earth_same', value.toString());
  }

  /// 记录最近出生地点（紫微选城市 / 八字选城市时写入，两处共用）。
  Future<void> setLastLocation(String? cityName, double? lng, double? lat) async {
    _lastCityName = (cityName == null || cityName.isEmpty) ? null : cityName;
    _lastLng = lng;
    _lastLat = lat;
    notifyListeners();
    await _save('last_city_name', _lastCityName ?? '');
    await _save('last_lng', (lng ?? 120).toStringAsFixed(4));
    await _save('last_lat', (lat ?? 30).toStringAsFixed(4));
  }

  Future<void> _save(String key, String value) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'user_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
