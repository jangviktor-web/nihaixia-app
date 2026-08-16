import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data/settings_repository.dart';
import '../data/changelog_repository.dart';
import '../services/update_service.dart';

// ==================== 设置对话框 ====================
// 从 chat_screen.dart 抽离（P2-4）：外观/诊断/数据管理/关于/更新 设置弹窗。

void showSettingsDialog(
  BuildContext context, {
  required VoidCallback onClearHistory,
  required VoidCallback onExportBookmarks,
}) {
  final settings = SettingsRepository.instance;
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('设置'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // === 外观设置 ===
              const Text('外观', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('暗黑模式', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('跟随系统')),
                  ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (s) => settings.setThemeMode(s.first),
              ),
              const SizedBox(height: 16),
              const Text('字体大小', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('小', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Slider(
                      value: settings.textScaleFactor,
                      min: 0.8,
                      max: 1.5,
                      divisions: 14,
                      label: '${(settings.textScaleFactor * 100).round()}%',
                      onChanged: (v) => settings.setTextScaleFactor(v),
                    ),
                  ),
                  const Text('大', style: TextStyle(fontSize: 18)),
                ],
              ),

              const Divider(height: 24),

              // === 诊断设置 ===
              const Text('诊断', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('默认性别'),
                subtitle: Text(settings.defaultGender.isEmpty
                    ? '未设置（每次询问）'
                    : settings.defaultGender == 'male' ? '男' : '女'),
                contentPadding: EdgeInsets.zero,
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: '', label: Text('不设置')),
                    ButtonSegment(value: 'male', label: Text('男')),
                    ButtonSegment(value: 'female', label: Text('女')),
                  ],
                  selected: {settings.defaultGender},
                  onSelectionChanged: (s) => settings.setDefaultGender(s.first),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.format_list_numbered),
                title: const Text('诊断详细度'),
                subtitle: Text(settings.diagnosticLevel == 'simple' ? '简单模式' : '详细模式'),
                contentPadding: EdgeInsets.zero,
                trailing: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'simple', label: Text('简单')),
                    ButtonSegment(value: 'detailed', label: Text('详细')),
                  ],
                  selected: {settings.diagnosticLevel},
                  onSelectionChanged: (s) => settings.setDiagnosticLevel(s.first),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.copy),
                title: const Text('诊断后自动复制处方'),
                subtitle: const Text('诊断完成后自动将处方复制到剪贴板'),
                value: settings.autoCopyPrescription,
                onChanged: (v) => settings.setAutoCopyPrescription(v),
                contentPadding: EdgeInsets.zero,
              ),

              const Divider(height: 24),

              // === 数据管理 ===
              const Text('数据管理', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.history, color: Colors.orange),
                title: const Text('清除诊断历史'),
                subtitle: const Text('删除所有诊断记录'),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(context);
                  onClearHistory();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bookmark, color: Colors.green),
                title: const Text('导出收藏'),
                subtitle: const Text('将收藏导出为文本'),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(context);
                  onExportBookmarks();
                },
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services, color: Colors.blue),
                title: const Text('清理缓存'),
                subtitle: const Text('清理临时文件释放空间'),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(context);
                  clearAppCache(context);
                },
              ),

              const Divider(height: 24),

              // === 关于 ===
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('关于'),
                subtitle: const Text('版本信息与致谢'),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(context);
                  showAboutPage(context);
                },
              ),
              const Divider(height: 24),

              // === 更新 ===
              ListTile(
                leading: const Icon(Icons.system_update),
                title: const Text('检测更新'),
                subtitle: const Text('检查是否有新版本'),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  Navigator.pop(context);
                  checkForUpdate(context);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}

// ==================== 清理缓存 ====================

Future<void> clearAppCache(BuildContext context) async {
  try {
    final tempDir = await getTemporaryDirectory();
    int totalSize = 0;
    if (await tempDir.exists()) {
      final files = tempDir.listSync(recursive: true);
      for (final file in files) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
      for (final file in files) {
        try {
          if (file is File) await file.delete();
        } catch (_) {}
      }
    }
    if (context.mounted) {
      final sizeMB = (totalSize / 1024 / 1024).toStringAsFixed(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已清理 ${sizeMB}MB 缓存')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('清理缓存失败：$e')),
      );
    }
  }
}

// ==================== 关于 ====================

Future<void> showAboutPage(BuildContext context) async {
  final info = await PackageInfo.fromPlatform();
  await ChangelogRepository.load();
  if (!context.mounted) return;

  final entries = ChangelogRepository.getAll();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('关于'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Icon(Icons.local_hospital, size: 64,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  const Text('汉唐中医', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('v${info.version}', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text('六经辨证诊断助手', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('基于倪海厦老师《伤寒论》六经辨证体系，'
                '通过七步问诊提供中医辨证建议。', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            const Text('功能特色', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('• 六经辨证智能诊断\n'
                '• 舌诊脉诊参考\n'
                '• 经方方剂库\n'
                '• 医案收藏与分享\n'
                '• 辅助诊断公式验证'),
            const SizedBox(height: 16),
            const Text('更新日志', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (entries.isEmpty)
              Text('暂无更新记录', style: TextStyle(color: Colors.grey[600], fontSize: 13))
            else
              ...entries.map((e) => _buildChangelogEntry(e)).toList(),
            const SizedBox(height: 16),
            const Text('致谢', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('倪海厦老师 · 经方医学传承\n'
                '仲景先师 · 伤寒论原典',
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Center(
              child: Text('© 2024-2026 汉唐中医',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}

/// 关于页中的单条更新日志卡片（最新版本高亮）。
Widget _buildChangelogEntry(ChangelogEntry e) {
  final isLatest = ChangelogRepository.latest == e;
  return Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: isLatest ? Colors.blue.shade50 : Colors.grey.shade50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isLatest ? Colors.blue.shade200 : Colors.grey.shade200,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('v${e.version}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text(e.date,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            if (isLatest) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('最新',
                    style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ],
          ],
        ),
        if (e.title.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(e.title,
              style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        ],
        const SizedBox(height: 6),
        ...e.changes.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('• $c',
                  style: const TextStyle(fontSize: 13, height: 1.4)),
            )),
      ],
    ),
  );
}

// ==================== 检测更新 ====================

Future<void> checkForUpdate(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => const AlertDialog(
      content: Row(
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('正在检查更新...'),
        ],
      ),
    ),
  );

  final updateInfo = await UpdateService.checkForUpdate();
  if (!context.mounted) return;
  Navigator.pop(context);

  if (updateInfo == null) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已是最新版本')),
    );
    return;
  }

  showUpdateDialog(context, updateInfo);
}

void showUpdateDialog(BuildContext context, UpdateInfo info) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('发现新版本 v${info.version}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('更新说明：', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(info.body),
            const SizedBox(height: 12),
            Text(
              '大小：${(info.apkSize / 1024 / 1024).toStringAsFixed(1)} MB',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            await UpdateService.ignoreVersion(info.version);
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('忽略此版本'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            downloadAndInstall(context, info);
          },
          child: const Text('下载更新'),
        ),
      ],
    ),
  );
}

Future<void> downloadAndInstall(BuildContext context, UpdateInfo info) async {
  double progress = 0;
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (c) => StatefulBuilder(
      builder: (context, setDialogState) {
        UpdateService.downloadApk(info.apkDownloadUrl, (p) {
          setDialogState(() => progress = p);
        }).then((file) {
          if (context.mounted) Navigator.pop(context);
          if (file != null) {
            installApk(file, context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('下载失败，请稍后重试')),
            );
          }
        });
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('正在下载更新...'),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: progress > 0 ? progress : null),
              const SizedBox(height: 8),
              Text('${(progress * 100).toStringAsFixed(0)}%'),
            ],
          ),
        );
      },
    ),
  );
}

Future<void> installApk(dynamic file, BuildContext context) async {
  try {
    await SystemChannels.platform.invokeMethod('SystemNavigator.open', {
      'action': 'install',
      'filePath': file.path,
    });
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('安装失败：$e')),
    );
  }
}
