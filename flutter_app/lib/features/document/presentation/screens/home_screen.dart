import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:scanpdf/core/theme/app_colors.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: () {
              context.read<DocumentBloc>().add(SyncToCloudEvent());
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
                          context.read<DocumentBloc>().add(LoadDocumentsEvent());
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                if (value.isEmpty) {
                  context.read<DocumentBloc>().add(LoadDocumentsEvent());
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
                            context.read<DocumentBloc>().add(LoadDocumentsEvent());
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
                          // TODO: Navigate to document detail
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
        onTap: (index) {
          // Handle navigation
        },
      ),
    );
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
