part of 'document_bloc.dart';

abstract class DocumentState extends Equatable {
  const DocumentState();

  @override
  List<Object?> get props => [];
}

class DocumentInitial extends DocumentState {}

class DocumentLoading extends DocumentState {}

class DocumentLoaded extends DocumentState {
  final List<Document> documents;
  final int total;
  final int page;
  final int pageSize;
  final bool hasMore;

  const DocumentLoaded({
    required this.documents,
    this.total = 0,
    this.page = 1,
    this.pageSize = 20,
    this.hasMore = false,
  });

  @override
  List<Object?> get props => [documents, total, page, pageSize, hasMore];
}

class DocumentError extends DocumentState {
  final String message;

  const DocumentError({required this.message});

  @override
  List<Object?> get props => [message];
}

class TagsLoaded extends DocumentState {
  final List<TagInfo> tags;

  const TagsLoaded({required this.tags});

  @override
  List<Object?> get props => [tags];
}

class RecycleBinLoaded extends DocumentState {
  final List<Document> documents;
  final int total;

  const RecycleBinLoaded({
    required this.documents,
    this.total = 0,
  });

  @override
  List<Object?> get props => [documents, total];
}

class DocumentOperationSuccess extends DocumentState {
  final String message;

  const DocumentOperationSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}
