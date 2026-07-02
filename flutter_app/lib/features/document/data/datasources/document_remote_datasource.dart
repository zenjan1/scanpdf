import 'package:dio/dio.dart';
import 'package:scanpdf/core/services/network_service.dart';
import 'package:scanpdf/features/document/domain/entities/document.dart';

abstract class DocumentRemoteDatasource {
  Future<List<Document>> fetchDocuments();
  Future<void> uploadDocument(Document document);
  Future<void> updateDocument(Document document);
  Future<void> deleteDocument(String id);
}

class DocumentRemoteDatasourceImpl implements DocumentRemoteDatasource {
  final NetworkService networkService;

  DocumentRemoteDatasourceImpl({required this.networkService});

  @override
  Future<List<Document>> fetchDocuments() async {
    try {
      final response = await networkService.get('/documents');
      final List<dynamic> data = response.data['data'];
      return data.map((json) => Document.fromMap(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch documents: $e');
    }
  }

  @override
  Future<void> uploadDocument(Document document) async {
    try {
      final formData = FormData.fromMap(document.toMap());
      await networkService.post('/documents', data: formData);
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  @override
  Future<void> updateDocument(Document document) async {
    try {
      await networkService.put('/documents/${document.id}', data: document.toMap());
    } catch (e) {
      throw Exception('Failed to update document: $e');
    }
  }

  @override
  Future<void> deleteDocument(String id) async {
    try {
      await networkService.delete('/documents/$id');
    } catch (e) {
      throw Exception('Failed to delete document: $e');
    }
  }
}
