import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scanpdf/core/theme/app_colors.dart';
import 'package:scanpdf/features/document/domain/entities/document.dart';
import 'package:scanpdf/features/document/presentation/bloc/document_bloc.dart';
import 'package:scanpdf/features/document/presentation/widgets/document_card.dart';
import 'package:scanpdf/shared/widgets/app_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _currentIndex = 0;
  bool _showOnlyFavorites = false;
  String _sortBy = 'updatedAt'; // updatedAt, title, createdAt

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleFavoritesFilter() {
    setState(() {
      _showOnlyFavorites = !_showOnlyFavorites;
    });
    context.read<DocumentBloc>().add(LoadDocumentsEvent(
      favoriteOnly: _showOnlyFavorites,
      sortBy: _sortBy,
    ));
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.access_time, color: AppColors.primary),
              title: const Text('按更新时间排序'),
              trailing: _sortBy == 'updatedAt' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _sortBy = 'updatedAt');
                Navigator.pop(context);
                context.read<DocumentBloc>().add(LoadDocumentsEvent(
                  favoriteOnly: _showOnlyFavorites,
                  sortBy: _sortBy,
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.title, color: AppColors.primary),
              title: const Text('按标题排序'),
              trailing: _sortBy == 'title' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _sortBy = 'title');
                Navigator.pop(context);
                context.read<DocumentBloc>().add(LoadDocumentsEvent(
                  favoriteOnly: _showOnlyFavorites,
                  sortBy: _sortBy,
                ));
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.primary),
              title: const Text('按创建时间排序'),
              trailing: _sortBy == 'createdAt' ? const Icon(Icons.check, color: AppColors.primary) : null,
              onTap: () {
                setState(() => _sortBy = 'createdAt');
                Navigator.pop(context);
                context.read<DocumentBloc>().add(LoadDocumentsEvent(
                  favoriteOnly: _showOnlyFavorites,
                  sortBy: _sortBy,
                ));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ScanPDF',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showOnlyFavorites ? Icons.star : Icons.star_border,
              color: _showOnlyFavorites ? Colors.amber : null,
            ),
            tooltip: _showOnlyFavorites ? '显示全部' : '仅显示收藏',
            onPressed: _toggleFavoritesFilter,
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            tooltip: '排序',
            onPressed: _showSortOptions,
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: () {
              context.read<DocumentBloc>().add(const SyncToCloudEvent());
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索文档...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          context.read<DocumentBloc>().add(const LoadDocumentsEvent());
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  context.read<DocumentBloc>().add(const LoadDocumentsEvent());
                } else {
                  context
                      .read<DocumentBloc>()
                      .add(SearchDocumentsEvent(value));
                }
              },
            ),
          ),

          // Documents List
          Expanded(
            child: BlocBuilder<DocumentBloc, DocumentState>(
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
                        AppButton(
                          text: '重试',
                          onPressed: () {
                            context.read<DocumentBloc>().add(const LoadDocumentsEvent());
                          },
                        ),
                      ],
                    ),
                  );
                }

                if (state is DocumentLoaded) {
                  if (state.documents.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.description_outlined,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '暂无文档',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '点击下方按钮开始扫描',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.documents.length,
                    itemBuilder: (context, index) {
                      final document = state.documents[index];
                      return DocumentCard(
                        document: document,
                        onTap: () {
                          _openDocument(document);
                        },
                        onFavoriteTap: () {
                          context.read<DocumentBloc>().add(
                                ToggleFavoriteEvent(
                                  document.id,
                                  !document.isFavorite,
                                ),
                              );
                        },
                        onDeleteTap: () {
                          _showDeleteDialog(document.id);
                        },
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/camera'),
        icon: const Icon(Icons.camera_alt),
        label: const Text('扫描'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder),
            label: '文档',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: '收藏',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0: // 首页
              setState(() => _showOnlyFavorites = false);
              context.read<DocumentBloc>().add(LoadDocumentsEvent(
                favoriteOnly: false,
                sortBy: _sortBy,
              ));
              break;
            case 1: // 文档
              setState(() => _showOnlyFavorites = false);
              context.read<DocumentBloc>().add(LoadDocumentsEvent(
                favoriteOnly: false,
                sortBy: _sortBy,
              ));
              break;
            case 2: // 收藏
              setState(() => _showOnlyFavorites = true);
              context.read<DocumentBloc>().add(LoadDocumentsEvent(
                favoriteOnly: true,
                sortBy: _sortBy,
              ));
              break;
            case 3: // 我的
              context.push('/settings');
              break;
          }
        },
      ),
    );
  }

  void _openDocument(Document document) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(document.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('页数: ${document.pageCount}'),
            Text('创建时间: ${DateFormat('yyyy-MM-dd HH:mm').format(document.createdAt)}'),
            Text('更新时间: ${DateFormat('yyyy-MM-dd HH:mm').format(document.updatedAt)}'),
            if (document.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('标签:'),
              Wrap(
                spacing: 4,
                children: document.tags.map((tag) => Chip(
                  label: Text(tag),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                )).toList(),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _shareDocument(document);
            },
            child: const Text('分享'),
          ),
        ],
      ),
    );
  }

  void _shareDocument(Document document) async {
    try {
      final pdfPath = '${await getApplicationDocumentsDirectory()}/documents/${document.id}.pdf';
      final file = File(pdfPath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(pdfPath)],
          text: '分享文档: ${document.title}',
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('PDF 文件不存在')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  void _showDeleteDialog(String documentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除文档'),
        content: const Text('确定要删除这个文档吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<DocumentBloc>().add(DeleteDocumentEvent(documentId));
            },
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
