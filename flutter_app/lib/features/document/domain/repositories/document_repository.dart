import 'package:scanpdf/features/document/domain/entities/document.dart';

abstract class DocumentRepository {
  Future<List<Document>> getAllDocuments();
  Future<List<Document>> searchDocuments(String query);
  Future<void> createDocument(Document document);
  Future<void> updateDocument(Document document);
  Future<void> deleteDocument(String id);
  Future<void> toggleFavorite(String id, bool isFavorite);
  Future<void> syncToCloud();
}
