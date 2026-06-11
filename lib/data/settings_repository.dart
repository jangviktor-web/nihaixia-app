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

  ThemeMode get themeMode => _themeMode;
  double get textScaleFactor => _textScaleFactor;
  String get defaultGender => _defaultGender;
  String get diagnosticLevel => _diagnosticLevel;
  bool get autoCopyPrescription => _autoCopyPrescription;
  bool get isLoaded => _loaded;

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

  Future<void> _save(String key, String value) async {
    final db = await DatabaseHelper.instance.database;
    await db.insert(
      'user_settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
