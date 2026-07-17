import 'package:flutter/material.dart';
import 'package:scanpdf/core/services/update_service.dart';

/// 更新提示对话框
class UpdateDialog extends StatefulWidget {
  final VersionInfo versionInfo;
  final bool forceUpdate;
  final VoidCallback onUpdate;
  final VoidCallback? onSkip;
  final VoidCallback? onCancel;

  const UpdateDialog({
    super.key,
    required this.versionInfo,
    this.forceUpdate = false,
    required this.onUpdate,
    this.onSkip,
    this.onCancel,
  });

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _downloadStatus = '';

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _downloadStatus = '正在下载...';
    });

    final updateService = UpdateService();
    final filePath = await updateService.downloadApk(
      widget.versionInfo.downloadUrl,
      (received, total) {
        if (total > 0) {
          setState(() {
            _downloadProgress = received / total;
            _downloadStatus =
                '下载中 ${(_downloadProgress * 100).toStringAsFixed(0)}%';
          });
        }
      },
    );

    if (filePath != null) {
      setState(() {
        _downloadStatus = '下载完成，准备安装';
      });

      // 安装 APK
      await updateService.installApk(filePath);
    } else {
      setState(() {
        _isDownloading = false;
        _downloadStatus = '下载失败';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('下载失败，请检查网络连接')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.forceUpdate,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题
              Row(
                children: [
                  Icon(
                    Icons.system_update,
                    size: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '发现新版本',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 版本信息
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('新版本：'),
                        Text(
                          widget.versionInfo.version,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (widget.versionInfo.apkSize != null)
                          Text(
                            widget.versionInfo.apkSize!,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 更新日志
              if (widget.versionInfo.changelog.isNotEmpty) ...[
                Text(
                  '更新内容：',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Text(
                      widget.versionInfo.changelog,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 下载进度
              if (_isDownloading) ...[
                LinearProgressIndicator(
                  value: _downloadProgress > 0 ? _downloadProgress : null,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Text(
                  _downloadStatus,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
              ],

              // 按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!widget.forceUpdate && widget.onSkip != null) ...[
                    TextButton(
                      onPressed: _isDownloading ? null : widget.onSkip,
                      child: const Text('跳过此版本'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (!widget.forceUpdate) ...[
                    TextButton(
                      onPressed: _isDownloading ? null : widget.onCancel,
                      child: const Text('稍后更新'),
                    ),
                    const SizedBox(width: 8),
                  ],
                  ElevatedButton(
                    onPressed: _isDownloading ? null : _startDownload,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(_isDownloading ? '下载中...' : '立即更新'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 显示更新对话框
Future<void> showUpdateDialog({
  required BuildContext context,
  required VersionInfo versionInfo,
  bool forceUpdate = false,
  required VoidCallback onUpdate,
  VoidCallback? onSkip,
  VoidCallback? onCancel,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: !forceUpdate,
    builder: (context) => UpdateDialog(
      versionInfo: versionInfo,
      forceUpdate: forceUpdate,
      onUpdate: onUpdate,
      onSkip: onSkip,
      onCancel: onCancel,
    ),
  );
}
