import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:scanpdf/core/theme/app_colors.dart';
import 'package:scanpdf/features/document/domain/entities/document.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final VoidCallback? onDeleteTap;

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
    this.onFavoriteTap,
    this.onDeleteTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: document.thumbnailPath != null
                    ? Image.file(
                        _imageFile(),
                        width: 72,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholder();
                        },
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),

              // Document Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.description_outlined,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          '${document.pageCount} 页',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(document.updatedAt),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Tags
                    if (document.tags.isNotEmpty)
                      Wrap(
                        spacing: 4,
                        children: document.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),

              // Actions
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      document.isFavorite
                          ? Icons.star
                          : Icons.star_border,
                      color: document.isFavorite
                          ? AppColors.warning
                          : Colors.grey[400],
                    ),
                    onPressed: onFavoriteTap,
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  const SizedBox(height: 4),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: Colors.grey[400]),
                    onSelected: (value) {
                      switch (value) {
                        case 'delete':
                          onDeleteTap?.call();
                          break;
                        case 'share':
                          // TODO: Share document
                          break;
                        case 'rename':
                          // TODO: Rename document
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('重命名'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share, size: 20),
                            SizedBox(width: 8),
                            Text('分享'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('删除', style: TextStyle(color: AppColors.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  File _imageFile() => File(document.thumbnailPath!);

  Widget _buildPlaceholder() {
    return Container(
      width: 72,
      height: 96,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.description,
        size: 32,
        color: Colors.grey[400],
      ),
    );
  }
}
