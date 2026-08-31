import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/update_service.dart';

class UpdateDialog extends StatefulWidget {
  final UpdateInfo updateInfo;

  const UpdateDialog({super.key, required this.updateInfo});

  /// 显示更新对话框，返回用户操作结果
  static Future<UpdateAction?> show(BuildContext context, UpdateInfo info) {
    return showModalBottomSheet<UpdateAction>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => UpdateDialog(updateInfo: info),
    );
  }

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  double _downloadProgress = 0;
  bool _isDownloading = false;
  String? _downloadError;

  String get _formattedSize {
    final kb = widget.updateInfo.apkSize / 1024;
    if (kb > 1024) {
      return '${(kb / 1024).toStringAsFixed(1)} MB';
    }
    return '${kb.toStringAsFixed(0)} KB';
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _downloadError = null;
    });

    final file = await UpdateService.downloadApk(
      widget.updateInfo.apkDownloadUrl,
      (progress) {
        if (mounted) setState(() => _downloadProgress = progress);
      },
    );

    if (!mounted) return;

    if (file != null) {
      // 安装APK
      try {
        // 使用 MethodChannel 调用 Android 安装
        const channel = MethodChannel('com.nihaisha.app/install');
        await channel.invokeMethod('installApk', {'path': file.path});
      } on PlatformException catch (e) {
        // 如果没有原生安装通道，提示用户手动安装
        setState(() {
          _isDownloading = false;
          _downloadError = '下载完成，但无法自动安装: ${e.message}\n文件已保存到: ${file.path}';
        });
      }
    } else {
      setState(() {
        _isDownloading = false;
        _downloadError = '下载失败，请检查网络后重试';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.system_update,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '发现新版本',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'v${widget.updateInfo.version}  ($_formattedSize)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 更新说明
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.updateInfo.body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          if (_downloadError != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _downloadError!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),
          ],

          const SizedBox(height: 20),

          // 下载进度
          if (_isDownloading) ...[
            LinearProgressIndicator(
              value: _downloadProgress,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              '下载中... ${(_downloadProgress * 100).toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],

          // 按钮
          if (!_isDownloading) ...[
            // 立即更新
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  await _startDownload();
                },
                icon: const Icon(Icons.download),
                label: const Text('立即更新'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // 忽略
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(UpdateAction.ignore);
                    },
                    child: const Text('忽略此版本'),
                  ),
                ),
                // 永久忽略
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(UpdateAction.permanentlyIgnore);
                    },
                    child: const Text('永久忽略'),
                  ),
                ),
              ],
            ),
          ],
          if (_isDownloading) ...[
            // 下载中只能取消
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('取消'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum UpdateAction {
  ignore,
  permanentlyIgnore,
}
