import 'package:scanpdf/core/services/database_service.dart';
import 'package:scanpdf/features/document/domain/entities/document.dart';
import 'package:scanpdf/features/document/data/datasources/document_local_datasource.dart';

class DocumentLocalDatasourceImpl implements DocumentLocalDatasource {
  final DatabaseService database;

  DocumentLocalDatasourceImpl({required this.database});

  @override
  Future<void> insertDocument(Document document) async {
    await database.insertDocument(document);
  }

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

  @override
  Future<List<Document>> searchDocuments(String query) async {
    return await database.searchDocuments(query);
  }

  @override
  Future<void> restoreDocument(String id) async {
    await database.restoreDocument(id);
  }

  @override
  Future<void> emptyRecycleBin() async {
    await database.emptyRecycleBin();
  }

  @override
  Future<List<Document>> getRecycleBinDocuments() async {
    return await database.getRecycleBinDocuments();
  }

  @override
  Future<void> permanentDeleteDocument(String id) async {
    await database.permanentDeleteDocument(id);
  }
}
