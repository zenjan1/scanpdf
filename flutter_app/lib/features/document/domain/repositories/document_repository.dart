import 'package:scanpdf/features/document/domain/entities/document.dart';
import 'package:scanpdf/features/document/domain/entities/tag_info.dart';

abstract class DocumentRepository {
  /// 获取文档列表（支持分页、排序、过滤）
  Future<Map<String, dynamic>> getAllDocuments({
    bool? favoriteOnly,
    String? sortBy,
    bool ascending = false,
    int page = 1,
    int pageSize = 20,
  });

  /// 创建文档
  Future<void> createDocument(Document document);

  /// 更新文档
  Future<void> updateDocument(Document document);

  /// 删除文档（软删除，移入回收站）
  Future<void> deleteDocument(String id);

  /// 批量删除文档
  Future<void> batchDeleteDocuments(List<String> ids);

  /// 切换收藏状态
  Future<void> toggleFavorite(String id, bool isFavorite);

  /// 批量切换收藏状态
  Future<void> batchToggleFavorite(List<String> ids, bool isFavorite);

  /// 搜索文档
  Future<List<Document>> searchDocuments(String query);

  /// 同步到云端
  Future<void> syncToCloud();

  /// 从回收站恢复文档
  Future<void> restoreDocument(String id);

  /// 清空回收站
  Future<void> emptyRecycleBin();

  /// 获取回收站文档
  Future<Map<String, dynamic>> getRecycleBin({
    int page = 1,
    int pageSize = 20,
  });

  /// 永久删除文档
  Future<void> permanentDeleteDocument(String id);

  /// 获取所有标签
  Future<List<TagInfo>> getAllTags();
}
