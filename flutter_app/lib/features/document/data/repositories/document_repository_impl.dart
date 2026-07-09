import 'package:scanpdf/core/services/network_service.dart';
import 'package:scanpdf/features/document/data/datasources/document_local_datasource.dart';
import 'package:scanpdf/features/document/data/datasources/document_remote_datasource.dart';
import 'package:scanpdf/features/document/domain/entities/document.dart';
import 'package:scanpdf/features/document/domain/repositories/document_repository.dart';

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
  Future<List<Document>> getAllDocuments({
    bool? favoriteOnly,
    String? sortBy,
    bool ascending = false,
  }) async {
    try {
      return await localDatasource.getAllDocuments(
        favoriteOnly: favoriteOnly,
        sortBy: sortBy,
        ascending: ascending,
      );
    } catch (e) {
      throw Exception('Failed to get documents: $e');
    }
  }

  @override
  Future<List<Document>> searchDocuments(String query) async {
    try {
      return await localDatasource.searchDocuments(query);
    } catch (e) {
      throw Exception('Failed to search documents: $e');
    }
  }

  @override
  Future<void> createDocument(Document document) async {
    try {
      await localDatasource.insertDocument(document);
    } catch (e) {
      throw Exception('Failed to create document: $e');
    }
  }

  @override
  Future<void> updateDocument(Document document) async {
    try {
      await localDatasource.updateDocument(document);
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    try {
      await localDatasource.deleteDocument(id);
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }

  @override
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    try {
      await localDatasource.toggleFavorite(id, isFavorite);
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }

  @override
  Future<void> syncToCloud() async {
    try {
      // Fetch remote documents
      final remoteDocs = await remoteDatasource.fetchDocuments();

      // Get local documents
      final localDocs = await localDatasource.getAllDocuments();

      // Sync logic: compare and update
      for (final remoteDoc in remoteDocs) {
        final localDoc = localDocs.firstWhere(
          (doc) => doc.id == remoteDoc.id,
          orElse: () => Document(
            id: '',
            title: '',
            createdAt: DateTime(1970),
            updatedAt: DateTime(1970),
            pageCount: 0,
            tags: const [],
            filePath: '',
          ),
        );

        if (localDoc.id.isEmpty) {
          // New remote document, add to local
          await localDatasource.insertDocument(remoteDoc);
        } else if (remoteDoc.updatedAt.isAfter(localDoc.updatedAt)) {
          // Remote is newer, update local
          await localDatasource.updateDocument(remoteDoc);
        } else if (localDoc.updatedAt.isAfter(remoteDoc.updatedAt)) {
          // Local is newer, update remote
          await remoteDatasource.updateDocument(localDoc);
        }
      }

      // Upload new local documents that don't exist remotely
      for (final localDoc in localDocs) {
        if (!remoteDocs.any((doc) => doc.id == localDoc.id)) {
          await remoteDatasource.uploadDocument(localDoc);
        }
      }
    } catch (e) {
      throw Exception('Failed to sync: $e');
    }
  }
}
