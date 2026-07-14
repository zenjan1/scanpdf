part of 'document_bloc.dart';

abstract class DocumentEvent extends Equatable {
  const DocumentEvent();

  @override
  List<Object?> get props => [];
}

class LoadDocumentsEvent extends DocumentEvent {
  final bool? favoriteOnly;
  final String? sortBy;
  final bool ascending;
  final int page;
  final int pageSize;

  const LoadDocumentsEvent({
    this.favoriteOnly,
    this.sortBy,
    this.ascending = false,
    this.page = 1,
    this.pageSize = 20,
  });

  @override
  List<Object?> get props => [favoriteOnly, sortBy, ascending, page, pageSize];
}

class CreateDocumentEvent extends DocumentEvent {
  final Document document;

  const CreateDocumentEvent(this.document);

  @override
  List<Object?> get props => [document];
}

class UpdateDocumentEvent extends DocumentEvent {
  final Document document;

  const UpdateDocumentEvent(this.document);

  @override
  List<Object?> get props => [document];
}

class DeleteDocumentEvent extends DocumentEvent {
  final String id;

  const DeleteDocumentEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class BatchDeleteDocumentsEvent extends DocumentEvent {
  final List<String> ids;

  const BatchDeleteDocumentsEvent(this.ids);

  @override
  List<Object?> get props => [ids];
}

class ToggleFavoriteEvent extends DocumentEvent {
  final String id;
  final bool isFavorite;

  const ToggleFavoriteEvent(this.id, this.isFavorite);

  @override
  List<Object?> get props => [id, isFavorite];
}

class SearchDocumentsEvent extends DocumentEvent {
  final String query;

  const SearchDocumentsEvent(this.query);

  @override
  List<Object?> get props => [query];
}

class SyncToCloudEvent extends DocumentEvent {
  const SyncToCloudEvent();
}

class RestoreDocumentEvent extends DocumentEvent {
  final String id;

  const RestoreDocumentEvent(this.id);

  @override
  List<Object?> get props => [id];
}

class EmptyRecycleBinEvent extends DocumentEvent {
  const EmptyRecycleBinEvent();
}

class LoadRecycleBinEvent extends DocumentEvent {
  const LoadRecycleBinEvent();
}

class LoadTagsEvent extends DocumentEvent {
  const LoadTagsEvent();
}
