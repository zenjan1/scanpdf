import 'package:scanpdf/features/document/domain/entities/document.dart';

abstract class DocumentLocalDatasource {
  /// 插入文档
  Future<void> insertDocument(Document document);

  /// 获取所有文档
  Future<List<Document>> getAllDocuments({
    bool? favoriteOnly,
    String? sortBy,
    bool ascending = false,
  });

  /// 更新文档
  Future<void> updateDocument(Document document);

  /// 删除文档（软删除）
  Future<void> deleteDocument(String id);

  /// 切换收藏状态
  Future<void> toggleFavorite(String id, bool isFavorite);

  /// 搜索文档
  Future<List<Document>> searchDocuments(String query);

  /// 恢复文档
  Future<void> restoreDocument(String id);

  /// 清空回收站
  Future<void> emptyRecycleBin();

  /// 获取回收站文档
  Future<List<Document>> getRecycleBinDocuments();

  /// 永久删除文档
  Future<void> permanentDeleteDocument(String id);
}
