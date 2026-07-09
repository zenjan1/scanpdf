import 'package:scanpdf/core/services/database_service.dart';
import 'package:scanpdf/features/document/domain/entities/document.dart';

abstract class DocumentLocalDatasource {
  Future<List<Document>> getAllDocuments({
    bool? favoriteOnly,
    String? sortBy,
    bool ascending = false,
  });
  Future<List<Document>> searchDocuments(String query);
  Future<void> insertDocument(Document document);
  Future<void> updateDocument(Document document);
  Future<void> deleteDocument(String id);
  Future<void> toggleFavorite(String id, bool isFavorite);
}

class DocumentLocalDatasourceImpl implements DocumentLocalDatasource {
  final DatabaseService database;

  DocumentLocalDatasourceImpl({required this.database});

  @override
  Future<List<Document>> getAllDocuments({
    bool? favoriteOnly,
    String? sortBy,
    bool ascending = false,
  }) async {
    return await database.getAllDocuments(
      favoriteOnly: favoriteOnly,
      sortBy: sortBy,
      ascending: ascending,
    );
  }

  @override
  Future<List<Document>> searchDocuments(String query) async {
    return await database.searchDocuments(query);
  }

  @override
  Future<void> insertDocument(Document document) async {
    await database.insertDocument(document);
  }

  @override
  Future<void> updateDocument(Document document) async {
    await database.updateDocument(document);
  }

  @override
  Future<void> deleteDocument(String id) async {
    await database.deleteDocument(id);
  }

  @override
  Future<void> toggleFavorite(String id, bool isFavorite) async {
    await database.toggleFavorite(id, isFavorite);
  }
}
