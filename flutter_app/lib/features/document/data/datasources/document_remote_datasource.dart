import 'package:scanpdf/features/document/domain/entities/document.dart';

abstract class DocumentRemoteDatasource {
  /// 获取文档列表（分页）
  Future<Map<String, dynamic>> getDocuments({
    int page = 1,
    int pageSize = 20,
    bool? favoriteOnly,
    String? sortBy,
    String? tags,
  });

  /// 获取文档详情
  Future<Document> getDocument(String id);

  /// 创建文档
  Future<Document> createDocument(Document document);

  /// 更新文档
  Future<Document> updateDocument(Document document);

  /// 删除文档
  Future<void> deleteDocument(String id);

  /// 批量删除文档
  Future<void> batchDeleteDocuments(List<String> ids);

  /// 切换收藏状态
  Future<void> toggleFavorite(String id, bool isFavorite);

  /// 搜索文档
  Future<List<Document>> searchDocuments(String query);

  /// 恢复文档
  Future<void> restoreDocument(String id);

  /// 清空回收站
  Future<void> emptyRecycleBin();

  /// 获取回收站
  Future<Map<String, dynamic>> getRecycleBin({
    int page = 1,
    int pageSize = 20,
  });

  /// 获取标签列表
  Future<List<Map<String, dynamic>>> getTags();
}
