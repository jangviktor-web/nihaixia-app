import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../data/database_helper.dart';
import '../data/changelog_repository.dart';

/// App 更新后弹窗「本次更新了什么」。
///
/// 机制：用 user_settings 表记录 `last_seen_version`（上次查看的版本）。
/// 每次启动比对当前已安装版本：
///   - 为空（首次安装）：记录当前版本，不弹窗；
///   - 与当前版本相同：已看过，不弹窗；
///   - 不同（发生了更新）：弹出该版本的更新日志，并把记录更新为当前版本。
class WhatsNewService {
  static const _lastSeenKey = 'last_seen_version';

  /// 在 App 首页 initState 后调用（需 context 已挂载）。
  static Future<void> checkAndShow(BuildContext context) async {
    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version;
      final lastSeen = await DatabaseHelper.instance.getSetting(_lastSeenKey);

      if (lastSeen == current) return; // 已看过本次版本，不重复弹窗

      // 首次安装（last_seen 为空）或版本更新（last_seen 不同）：
      // 弹出「本次更新了什么」，随后记录为已查看，避免重复弹出。
      if (!context.mounted) return;
      final entry = ChangelogRepository.getForVersion(current) ??
          ChangelogRepository.latest;
      _showDialog(context, current, entry);

      // 无论用户是否关闭弹窗，都更新为已查看，避免重复弹出
      await DatabaseHelper.instance.setSetting(_lastSeenKey, current);
    } catch (e) {
      debugPrint('WhatsNew 检查失败: $e');
    }
  }

  static void _showDialog(
      BuildContext context, String version, ChangelogEntry? entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.new_releases, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text('更新到 v$version')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (entry?.title.isNotEmpty ?? false) ...[
                Text(entry!.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 10),
              ],
              if (entry != null)
                ...entry.changes.map((c) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ',
                              style: TextStyle(height: 1.4)),
                          Expanded(
                            child: Text(c,
                                style: const TextStyle(height: 1.4)),
                          ),
                        ],
                      ),
                    ))
              else
                const Text('本次更新包含若干优化与修复，感谢您的使用。'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}
