import 'package:flutter/material.dart';

import '../data/settings_repository.dart';
import '../services/update_service.dart';
import 'app_dialogs.dart';

/// 独立设置页：集中所有「模块级可自定义」设置，并与各排盘页内的开关双向同步。
/// 紫微 / 八字 的「晚子时」「长生十二神口径」读取同一份共享设置，保证全局一致。
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _settings = SettingsRepository.instance;
  bool _mirrorEnabled = true;

  @override
  void initState() {
    super.initState();
    UpdateService.isMirrorEnabled().then((v) {
      if (mounted) setState(() => _mirrorEnabled = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      // 监听共享设置变化，开关即时刷新（无需退出重进）。
      body: ListenableBuilder(
        listenable: _settings,
        builder: (context, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle('外观'),
            _themeModeTile(),
            _fontScaleTile(),
            const Divider(height: 24),
            _sectionTitle('诊断'),
            _genderTile(cs),
            _diagnosticLevelTile(cs),
            _autoCopyTile(cs),
            const Divider(height: 24),
            _sectionTitle('紫微斗数排盘'),
            _trueSolarTile(cs),
            _lateZiTile(cs, isBazi: false),
            _twelveStageTile(cs),
            const Divider(height: 24),
            _sectionTitle('八字排盘'),
            _lateZiTile(cs, isBazi: true),
            _twelveStageTile(cs),
            const Divider(height: 24),
            _sectionTitle('数据管理'),
            _clearHistoryTile(cs),
            _exportTile(cs),
            _clearCacheTile(cs),
            const Divider(height: 24),
            _aboutTile(cs),
            const Divider(height: 24),
            _sectionTitle('更新'),
            _mirrorToggleTile(cs),
            _updateTile(cs),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      );

  Widget _themeModeTile() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('暗黑模式', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('跟随系统')),
              ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
              ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
            ],
            selected: {_settings.themeMode},
            onSelectionChanged: (s) => _settings.setThemeMode(s.first),
          ),
        ],
      );

  Widget _fontScaleTile() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('字体大小', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('小', style: TextStyle(fontSize: 12)),
              Expanded(
                child: Slider(
                  value: _settings.textScaleFactor,
                  min: 0.8,
                  max: 1.5,
                  divisions: 14,
                  label: '${(_settings.textScaleFactor * 100).round()}%',
                  onChanged: (v) => _settings.setTextScaleFactor(v),
                ),
              ),
              const Text('大', style: TextStyle(fontSize: 16)),
            ],
          ),
        ],
      );

  Widget _genderTile(ColorScheme cs) => ListTile(
        leading: const Icon(Icons.person),
        title: const Text('默认性别'),
        subtitle: Text(_settings.defaultGender.isEmpty
            ? '未设置（每次询问）'
            : _settings.defaultGender == 'male'
                ? '男'
                : '女'),
        contentPadding: EdgeInsets.zero,
        trailing: SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: '', label: Text('不设置')),
            ButtonSegment(value: 'male', label: Text('男')),
            ButtonSegment(value: 'female', label: Text('女')),
          ],
          selected: {_settings.defaultGender},
          onSelectionChanged: (s) => _settings.setDefaultGender(s.first),
        ),
      );

  Widget _diagnosticLevelTile(ColorScheme cs) => ListTile(
        leading: const Icon(Icons.format_list_numbered),
        title: const Text('诊断详细度'),
        subtitle:
            Text(_settings.diagnosticLevel == 'simple' ? '简单模式' : '详细模式'),
        contentPadding: EdgeInsets.zero,
        trailing: SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'simple', label: Text('简单')),
            ButtonSegment(value: 'detailed', label: Text('详细')),
          ],
          selected: {_settings.diagnosticLevel},
          onSelectionChanged: (s) => _settings.setDiagnosticLevel(s.first),
        ),
      );

  Widget _autoCopyTile(ColorScheme cs) => SwitchListTile(
        secondary: const Icon(Icons.copy),
        title: const Text('诊断后自动复制处方'),
        subtitle: const Text('诊断完成后自动将处方复制到剪贴板'),
        value: _settings.autoCopyPrescription,
        onChanged: (v) => _settings.setAutoCopyPrescription(v),
        contentPadding: EdgeInsets.zero,
      );

  Widget _trueSolarTile(ColorScheme cs) => SwitchListTile(
        secondary: const Icon(Icons.wb_sunny_outlined),
        title: const Text('真太阳时校准'),
        subtitle: const Text('按出生地经度校正平太阳时时差'),
        value: _settings.useTrueSolarTime,
        onChanged: (v) => _settings.setUseTrueSolarTime(v),
        contentPadding: EdgeInsets.zero,
      );

  // 区分早晚子时的共享开关：八字 / 紫微共用，单一开关、默认关闭。
  Widget _lateZiTile(ColorScheme cs, {required bool isBazi}) => SwitchListTile(
        secondary: const Icon(Icons.nights_stay_outlined),
        title: const Text('区分早晚子时'),
        subtitle: const Text(
            '默认关闭：子时归自然日（日柱当天）。开启后由出生时刻自动判定'
            '晚子时（23:00–24:00，日柱当天、时柱次日）或早子时（00:00–01:00，日柱次日）'),
        value: _settings.distinguishZiShiEnabled,
        onChanged: (v) => _settings.setDistinguishZiShiEnabled(v),
        contentPadding: EdgeInsets.zero,
      );

  Widget _twelveStageTile(ColorScheme cs) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('长生十二神 · 起长生口径',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, label: Text('火土同宫')),
              ButtonSegment(value: false, label: Text('水土同宫')),
            ],
            selected: {_settings.fireEarthSame},
            onSelectionChanged: (s) => _settings.setFireEarthSame(s.first),
          ),
        ],
      );

  Widget _clearHistoryTile(ColorScheme cs) => ListTile(
        leading: Icon(Icons.history, color: cs.error),
        title: const Text('清除诊断历史'),
        subtitle: const Text('删除所有诊断记录'),
        contentPadding: EdgeInsets.zero,
        onTap: () => confirmClearHistory(context),
      );

  Widget _exportTile(ColorScheme cs) => ListTile(
        leading: Icon(Icons.bookmark, color: cs.tertiary),
        title: const Text('导出收藏'),
        subtitle: const Text('将收藏导出为文本'),
        contentPadding: EdgeInsets.zero,
        onTap: () => exportBookmarks(context),
      );

  Widget _clearCacheTile(ColorScheme cs) => ListTile(
        leading: Icon(Icons.cleaning_services, color: cs.secondary),
        title: const Text('清理缓存'),
        subtitle: const Text('清理临时文件释放空间'),
        contentPadding: EdgeInsets.zero,
        onTap: () => clearAppCache(context),
      );

  Widget _aboutTile(ColorScheme cs) => ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('关于'),
        subtitle: const Text('版本信息与致谢'),
        contentPadding: EdgeInsets.zero,
        onTap: () => showAboutPage(context),
      );

  Widget _updateTile(ColorScheme cs) => ListTile(
        leading: const Icon(Icons.system_update),
        title: const Text('检测更新'),
        subtitle: const Text('检查是否有新版本'),
        contentPadding: EdgeInsets.zero,
        onTap: () => checkForUpdate(context),
      );

  Widget _mirrorToggleTile(ColorScheme cs) => SwitchListTile(
        secondary: const Icon(Icons.cloud_download_outlined),
        title: const Text('更新镜像加速'),
        subtitle: const Text('GitHub 访问慢时自动切换 ghproxy 镜像'),
        value: _mirrorEnabled,
        onChanged: (v) async {
          setState(() => _mirrorEnabled = v);
          await UpdateService.setMirrorEnabled(v);
        },
        contentPadding: EdgeInsets.zero,
      );
}
