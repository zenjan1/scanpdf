import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:scanpdf/core/theme/app_colors.dart';
import 'package:scanpdf/features/document/domain/entities/document.dart';
import 'package:scanpdf/features/document/presentation/bloc/document_bloc.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  static const int _autoDeleteDays = 30;

  @override
  void initState() {
    super.initState();
    context.read<DocumentBloc>().add(const LoadRecycleBinEvent());
  }

  int _remainingDays(DateTime deletedAt) {
    final autoDeleteAt = deletedAt.add(const Duration(days: _autoDeleteDays));
    final remaining = autoDeleteAt.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('回收站'),
        actions: [
          BlocBuilder<DocumentBloc, DocumentState>(
            builder: (context, state) {
              if (state is RecycleBinLoaded && state.documents.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: '清空回收站',
                  onPressed: _showEmptyRecycleBinDialog,
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<DocumentBloc, DocumentState>(
        listener: (context, state) {
          if (state is DocumentOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          } else if (state is DocumentError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DocumentLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DocumentError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                  const SizedBox(height: 16),
                  Text('加载失败: ${state.message}'),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      context.read<DocumentBloc>().add(const LoadRecycleBinEvent());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('重试'),
                  ),
                ],
              ),
            );
          }

          if (state is RecycleBinLoaded) {
            if (state.documents.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      '回收站为空',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '删除的文档会在这里保留 $_autoDeleteDays 天',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Info banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.info,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '文档删除后保留 $_autoDeleteDays 天，过期自动清理',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Document list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.documents.length,
                    itemBuilder: (context, index) {
                      final document = state.documents[index];
                      return _RecycleBinItem(
                        document: document,
                        remainingDays: _remainingDays(document.updatedAt),
                        onRestore: () => _showRestoreDialog(document),
                        onDelete: () => _showPermanentDeleteDialog(document),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  void _showRestoreDialog(Document document) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('恢复文档'),
        content: Text('确定要恢复「${document.title}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<DocumentBloc>().add(RestoreDocumentEvent(document.id));
            },
            child: const Text('恢复', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _showPermanentDeleteDialog(Document document) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('永久删除'),
        content: Text('确定要永久删除「${document.title}」吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<DocumentBloc>().add(PermanentDeleteDocumentEvent(document.id));
            },
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showEmptyRecycleBinDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清空回收站'),
        content: const Text('确定要清空回收站吗？所有文档将被永久删除，此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<DocumentBloc>().add(const EmptyRecycleBinEvent());
            },
            child: const Text('清空', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _RecycleBinItem extends StatelessWidget {
  final Document document;
  final int remainingDays;
  final VoidCallback onRestore;
  final VoidCallback onDelete;

  const _RecycleBinItem({
    required this.document,
    required this.remainingDays,
    required this.onRestore,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
    final isExpiringSoon = remainingDays <= 3;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: document.thumbnailPath != null
                  ? Image.file(
                      File(document.thumbnailPath!),
                      width: 56,
                      height: 72,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
            const SizedBox(width: 12),

            // Document info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    document.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        '删除于 ${dateFormat.format(document.updatedAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 13,
                        color: isExpiringSoon ? AppColors.error : Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        remainingDays == 0
                            ? '即将自动清理'
                            : '剩余 $remainingDays 天',
                        style: TextStyle(
                          fontSize: 12,
                          color: isExpiringSoon ? AppColors.error : Colors.grey[600],
                          fontWeight: isExpiringSoon ? FontWeight.w500 : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Action buttons
            Column(
              children: [
                IconButton(
                  icon: const Icon(Icons.restore, color: AppColors.primary),
                  tooltip: '恢复',
                  onPressed: onRestore,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                const SizedBox(height: 4),
                IconButton(
                  icon: const Icon(Icons.delete_forever, color: AppColors.error),
                  tooltip: '永久删除',
                  onPressed: onDelete,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 56,
      height: 72,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.description, size: 24, color: Colors.grey[400]),
    );
  }
}
