import 'package:scanpdf/core/services/network_service.dart';
import 'package:scanpdf/features/document/domain/entities/document.dart';
import 'package:scanpdf/features/document/data/datasources/document_remote_datasource.dart';

class DocumentRemoteDatasourceImpl implements DocumentRemoteDatasource {
  final NetworkService networkService;

  DocumentRemoteDatasourceImpl({required this.networkService});

  @override
  Future<Map<String, dynamic>> getDocuments({
    int page = 1,
    int pageSize = 20,
    bool? favoriteOnly,
    String? sortBy,
    String? tags,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
    };
    if (favoriteOnly != null) queryParams['is_favorite'] = favoriteOnly;
    if (sortBy != null) queryParams['sort_by'] = sortBy;
    if (tags != null) queryParams['tags'] = tags;

    final response = await networkService.get(
      '/documents',
      queryParameters: queryParams,
    );
    return response.data;
  }

  @override
  Future<Document> getDocument(String id) async {
    final response = await networkService.get('/documents/$id');
    return Document.fromMap(response.data['data']);
  }

  @override
  Future<Document> createDocument(Document document) async {
    final response = await networkService.post(
      '/documents',
      data: document.toMap(),
    );
    return Document.fromMap(response.data['data']);
  }

  @override
  Future<Document> updateDocument(Document document) async {
    final response = await networkService.put(
      '/documents/${document.id}',
      data: document.toMap(),
    );
    return Document.fromMap(response.data['data']);
  }

  @override
  Future<void> deleteDocument(String id) async {
    await networkService.delete('/documents/$id');
  }

  @override
  Future<void> batchDeleteDocuments(List<String> ids) async {
    await networkService.post(
      '/documents/batch/delete',
      data: {'document_ids': ids},
    );
  }

  @override
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    await networkService.post(
      '/documents/batch/favorite',
      data: {
        'document_ids': [id],
        'is_favorite': isFavorite,
      },
    );
  }

  @override
  Future<List<Document>> searchDocuments(String query) async {
    final response = await networkService.get(
      '/documents/search/$query',
    );
    final data = response.data;
    final docs = data['data'] as List? ?? [];
    return docs.map((d) => Document.fromMap(d as Map<String, dynamic>)).toList();
  }

  @override
  Future<void> restoreDocument(String id) async {
    await networkService.post('/documents/$id/restore');
  }

  @override
  Future<void> emptyRecycleBin() async {
    await networkService.delete('/recycle-bin/empty');
  }

  @override
  Future<Map<String, dynamic>> getRecycleBin({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await networkService.get(
      '/recycle-bin',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    return response.data;
  }

  @override
  Future<List<Map<String, dynamic>>> getTags() async {
    final response = await networkService.get('/tags/list');
    final data = response.data['data'] as List? ?? [];
    return data.cast<Map<String, dynamic>>();
  }
}
