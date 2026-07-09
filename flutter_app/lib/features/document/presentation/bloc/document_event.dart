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

  const LoadDocumentsEvent({
    this.favoriteOnly,
    this.sortBy,
    this.ascending = false,
  });

  @override
  List<Object?> get props => [favoriteOnly, sortBy, ascending];
}

class CreateDocumentEvent extends DocumentEvent {
  final Document document;

  const CreateDocumentEvent(this.document);

  @override
  List<Object> get props => [document];
}

class UpdateDocumentEvent extends DocumentEvent {
  final Document document;

  const UpdateDocumentEvent(this.document);

  @override
  List<Object> get props => [document];
}

class DeleteDocumentEvent extends DocumentEvent {
  final String id;

  const DeleteDocumentEvent(this.id);

  @override
  List<Object> get props => [id];
}

class ToggleFavoriteEvent extends DocumentEvent {
  final String id;
  final bool isFavorite;

  const ToggleFavoriteEvent(this.id, this.isFavorite);

  @override
  List<Object> get props => [id, isFavorite];
}

class SearchDocumentsEvent extends DocumentEvent {
  final String query;

  const SearchDocumentsEvent(this.query);

  @override
  List<Object> get props => [query];
}

class SyncToCloudEvent extends DocumentEvent {}
