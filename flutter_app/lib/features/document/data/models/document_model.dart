import 'package:scanpdf/features/document/domain/entities/document.dart';

class DocumentModel extends Document {
  const DocumentModel({
    required super.id,
    required super.title,
    required super.createdAt,
    required super.updatedAt,
    required super.pageCount,
    required super.tags,
    required super.filePath,
    super.thumbnailPath,
    super.isFavorite,
    super.isDeleted,
    super.cloudId,
    super.syncStatus,
  });

  factory DocumentModel.fromEntity(Document document) {
    return DocumentModel(
      id: document.id,
      title: document.title,
      createdAt: document.createdAt,
      updatedAt: document.updatedAt,
      pageCount: document.pageCount,
      tags: document.tags,
      filePath: document.filePath,
      thumbnailPath: document.thumbnailPath,
      isFavorite: document.isFavorite,
      isDeleted: document.isDeleted,
      cloudId: document.cloudId,
      syncStatus: document.syncStatus,
    );
  }

  Document toEntity() {
    return Document(
      id: id,
      title: title,
      createdAt: createdAt,
      updatedAt: updatedAt,
      pageCount: pageCount,
      tags: tags,
      filePath: filePath,
      thumbnailPath: thumbnailPath,
      isFavorite: isFavorite,
      isDeleted: isDeleted,
      cloudId: cloudId,
      syncStatus: syncStatus,
    );
  }
}
