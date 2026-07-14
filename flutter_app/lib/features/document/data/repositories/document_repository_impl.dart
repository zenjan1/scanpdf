import 'package:scanpdf/features/document/domain/entities/document.dart';
import 'package:scanpdf/features/document/domain/repositories/document_repository.dart';
import 'package:scanpdf/features/document/data/datasources/document_local_datasource.dart';
import 'package:scanpdf/features/document/data/datasources/document_remote_datasource.dart';
import 'package:scanpdf/features/document/presentation/bloc/document_state.dart';
import 'package:scanpdf/core/services/network_service.dart';

class DocumentRepositoryImpl implements DocumentRepository {
  final DocumentLocalDatasource localDatasource;
  final DocumentRemoteDatasource remoteDatasource;
  final NetworkService networkService;

  DocumentRepositoryImpl({
    required this.localDatasource,
    required this.remoteDatasource,
    required this.networkService,
  });

  @override
  Future<Map<String, dynamic>> getAllDocuments({
    bool? favoriteOnly,
    String? sortBy,
    bool ascending = false,
    int page = 1,
    int pageSize = 20,
  }) async {
    // 优先从本地获取，保证离线可用
    final documents = await localDatasource.getAllDocuments(
      favoriteOnly: favoriteOnly,
      sortBy: sortBy,
      ascending: ascending,
    );

    // 如果在线且有云端同步，尝试拉取最新
    if (networkService.isOnline) {
      try {
        final remoteDocs = await remoteDatasource.getDocuments(
          page: page,
          pageSize: pageSize,
          favoriteOnly: favoriteOnly,
          sortBy: sortBy,
        );
        // 合并远程文档到本地
        for (final doc in remoteDocs['documents'] ?? []) {
          await localDatasource.insertDocument(doc);
        }
      } catch (e) {
        // 离线时忽略远程错误
      }
    }

    // 重新从本地获取合并后的数据
    final updatedDocs = await localDatasource.getAllDocuments(
      favoriteOnly: favoriteOnly,
      sortBy: sortBy,
      ascending: ascending,
    );

    // 本地分页
    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;
    final paginatedDocs = updatedDocs.sublist(
      startIndex.clamp(0, updatedDocs.length),
      endIndex.clamp(0, updatedDocs.length),
    );

    return {
      'documents': paginatedDocs,
      'total': updatedDocs.length,
    };
  }

  @override
  Future<void> createDocument(Document document) async {
    await localDatasource.insertDocument(document);

    // 如果在线，同步到云端
    if (networkService.isOnline) {
      try {
        await remoteDatasource.createDocument(document);
      } catch (e) {
        // 加入离线队列
        networkService.addToOfflineQueue(
          method: 'POST',
          path: '/documents',
          data: document.toMap(),
        );
      }
    } else {
      networkService.addToOfflineQueue(
        method: 'POST',
        path: '/documents',
        data: document.toMap(),
      );
    }
  }

  @override
  Future<void> updateDocument(Document document) async {
    await localDatasource.updateDocument(document);

    if (networkService.isOnline) {
      try {
        await remoteDatasource.updateDocument(document);
      } catch (e) {
        networkService.addToOfflineQueue(
          method: 'PUT',
          path: '/documents/${document.id}',
          data: document.toMap(),
        );
      }
    } else {
      networkService.addToOfflineQueue(
        method: 'PUT',
        path: '/documents/${document.id}',
        data: document.toMap(),
      );
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    await localDatasource.deleteDocument(id);

    if (networkService.isOnline) {
      try {
        await remoteDatasource.deleteDocument(id);
      } catch (e) {
        networkService.addToOfflineQueue(
          method: 'DELETE',
          path: '/documents/$id',
        );
      }
    } else {
      networkService.addToOfflineQueue(
        method: 'DELETE',
        path: '/documents/$id',
      );
    }
  }

  @override
  Future<void> batchDeleteDocuments(List<String> ids) async {
    for (final id in ids) {
      await localDatasource.deleteDocument(id);
    }

    if (networkService.isOnline) {
      try {
        await remoteDatasource.batchDeleteDocuments(ids);
      } catch (e) {
        networkService.addToOfflineQueue(
          method: 'POST',
          path: '/documents/batch/delete',
          data: {'document_ids': ids},
        );
      }
    } else {
      networkService.addToOfflineQueue(
        method: 'POST',
        path: '/documents/batch/delete',
        data: {'document_ids': ids},
      );
    }
  }

  @override
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    await localDatasource.toggleFavorite(id, isFavorite);

    if (networkService.isOnline) {
      try {
        await remoteDatasource.toggleFavorite(id, isFavorite);
      } catch (e) {
        networkService.addToOfflineQueue(
          method: 'PUT',
          path: '/documents/$id/favorite',
          data: {'is_favorite': isFavorite},
        );
      }
    }
  }

  @override
  Future<List<Document>> searchDocuments(String query) async {
    return await localDatasource.searchDocuments(query);
  }

  @override
  Future<void> syncToCloud() async {
    if (!networkService.isOnline) {
      throw Exception('当前处于离线状态，无法同步');
    }

    // 先同步离线队列
    await networkService.syncOfflineQueue();

    // 拉取远程最新
    final remoteDocs = await remoteDatasource.getDocuments(
      page: 1,
      pageSize: 1000,
    );

    for (final doc in remoteDocs['documents'] ?? []) {
      await localDatasource.insertDocument(doc);
    }
  }

  @override
  Future<void> restoreDocument(String id) async {
    await localDatasource.restoreDocument(id);

    if (networkService.isOnline) {
      try {
        await remoteDatasource.restoreDocument(id);
      } catch (e) {
        networkService.addToOfflineQueue(
          method: 'POST',
          path: '/documents/$id/restore',
        );
      }
    }
  }

  @override
  Future<void> emptyRecycleBin() async {
    await localDatasource.emptyRecycleBin();

    if (networkService.isOnline) {
      try {
        await remoteDatasource.emptyRecycleBin();
      } catch (e) {
        networkService.addToOfflineQueue(
          method: 'DELETE',
          path: '/recycle-bin/empty',
        );
      }
    }
  }

  @override
  Future<Map<String, dynamic>> getRecycleBin({
    int page = 1,
    int pageSize = 20,
  }) async {
    final documents = await localDatasource.getRecycleBinDocuments();
    return {
      'documents': documents,
      'total': documents.length,
    };
  }

  @override
  Future<List<TagInfo>> getAllTags() async {
    final documents = await localDatasource.getAllDocuments();
    final tagCounts = <String, int>{};

    for (final doc in documents) {
      for (final tag in doc.tags) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
    }

    return tagCounts.entries
        .map((e) => TagInfo(name: e.key, count: e.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }
}
