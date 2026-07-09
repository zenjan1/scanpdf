import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scanpdf/features/document/domain/entities/document.dart';
import 'package:scanpdf/features/document/domain/repositories/document_repository.dart';

part 'document_event.dart';
part 'document_state.dart';

class DocumentBloc extends Bloc<DocumentEvent, DocumentState> {
  final DocumentRepository repository;

  DocumentBloc({required this.repository}) : super(DocumentInitial()) {
    on<LoadDocumentsEvent>(_onLoadDocuments);
    on<CreateDocumentEvent>(_onCreateDocument);
    on<UpdateDocumentEvent>(_onUpdateDocument);
    on<DeleteDocumentEvent>(_onDeleteDocument);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<SearchDocumentsEvent>(_onSearchDocuments);
    on<SyncToCloudEvent>(_onSyncToCloud);
  }

  Future<void> _onLoadDocuments(
    LoadDocumentsEvent event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentLoading());
    try {
      final documents = await repository.getAllDocuments(
        favoriteOnly: event.favoriteOnly,
        sortBy: event.sortBy,
        ascending: event.ascending,
      );
      emit(DocumentLoaded(documents: documents));
    } catch (e) {
      emit(DocumentError(message: e.toString()));
    }
  }

  Future<void> _onCreateDocument(
    CreateDocumentEvent event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await repository.createDocument(event.document);
      add(LoadDocumentsEvent());
    } catch (e) {
      emit(DocumentError(message: e.toString()));
    }
  }

  Future<void> _onUpdateDocument(
    UpdateDocumentEvent event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await repository.updateDocument(event.document);
      add(LoadDocumentsEvent());
    } catch (e) {
      emit(DocumentError(message: e.toString()));
    }
  }

  Future<void> _onDeleteDocument(
    DeleteDocumentEvent event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await repository.deleteDocument(event.id);
      add(LoadDocumentsEvent());
    } catch (e) {
      emit(DocumentError(message: e.toString()));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavoriteEvent event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await repository.toggleFavorite(event.id, event.isFavorite);
      add(LoadDocumentsEvent());
    } catch (e) {
      emit(DocumentError(message: e.toString()));
    }
  }

  Future<void> _onSearchDocuments(
    SearchDocumentsEvent event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentLoading());
    try {
      final documents = await repository.searchDocuments(event.query);
      emit(DocumentLoaded(documents: documents));
    } catch (e) {
      emit(DocumentError(message: e.toString()));
    }
  }

  Future<void> _onSyncToCloud(
    SyncToCloudEvent event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await repository.syncToCloud();
      add(LoadDocumentsEvent());
    } catch (e) {
      emit(DocumentError(message: e.toString()));
    }
  }
}
