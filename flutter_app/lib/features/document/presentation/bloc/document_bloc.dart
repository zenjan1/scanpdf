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
    on<BatchDeleteDocumentsEvent>(_onBatchDeleteDocuments);
    on<ToggleFavoriteEvent>(_onToggleFavorite);
    on<SearchDocumentsEvent>(_onSearchDocuments);
    on<SyncToCloudEvent>(_onSyncToCloud);
    on<RestoreDocumentEvent>(_onRestoreDocument);
    on<EmptyRecycleBinEvent>(_onEmptyRecycleBin);
    on<LoadRecycleBinEvent>(_onLoadRecycleBin);
    on<LoadTagsEvent>(_onLoadTags);
  }

  Future<void> _onLoadDocuments(
    LoadDocumentsEvent event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentLoading());
    try {
      final result = await repository.getAllDocuments(
        favoriteOnly: event.favoriteOnly,
        sortBy: event.sortBy,
        ascending: event.ascending,
        page: event.page,
        pageSize: event.pageSize,
      );
      emit(DocumentLoaded(
        documents: result['documents'] as List<Document>,
        total: result['total'] as int,
        page: event.page,
        pageSize: event.pageSize,
        hasMore: (event.page * event.pageSize) < (result['total'] as int),
      ));
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
      emit(const DocumentOperationSuccess(message: '文档创建成功'));
      add(const LoadDocumentsEvent());
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
      emit(const DocumentOperationSuccess(message: '文档更新成功'));
      add(const LoadDocumentsEvent());
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
      emit(const DocumentOperationSuccess(message: '文档已移入回收站'));
      add(const LoadDocumentsEvent());
    } catch (e) {
      emit(DocumentError(message: e.toString()));
    }
  }

  Future<void> _onBatchDeleteDocuments(
    BatchDeleteDocumentsEvent event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await repository.batchDeleteDocuments(event.ids);
      emit(DocumentOperationSuccess(message: '已删除 ${event.ids.length} 个文档'));
      add(const LoadDocumentsEvent());
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
      add(const LoadDocumentsEvent());
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
      emit(const DocumentOperationSuccess(message: '同步成功'));
      add(const LoadDocumentsEvent());
    } catch (e) {
      emit(DocumentError(message: e.toString()));
    }
  }

  Future<void> _onRestoreDocument(
    RestoreDocumentEvent event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await repository.restoreDocument(event.id);
      emit(const DocumentOperationSuccess(message: '文档已恢复'));
      add(const LoadRecycleBinEvent());
    } catch (e) {
      emit(DocumentError(message: e.toString()));
    }
  }

  Future<void> _onEmptyRecycleBin(
    EmptyRecycleBinEvent event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      await repository.emptyRecycleBin();
      emit(const DocumentOperationSuccess(message: '回收站已清空'));
      add(const LoadRecycleBinEvent());
    } catch (e) {
      emit(DocumentError(message: e.toString()));
    }
  }

  Future<void> _onLoadRecycleBin(
    LoadRecycleBinEvent event,
    Emitter<DocumentState> emit,
  ) async {
    emit(DocumentLoading());
    try {
      final result = await repository.getRecycleBin();
      emit(RecycleBinLoaded(
        documents: result['documents'] as List<Document>,
        total: result['total'] as int,
      ));
    } catch (e) {
      emit(DocumentError(message: e.toString()));
    }
  }

  Future<void> _onLoadTags(
    LoadTagsEvent event,
    Emitter<DocumentState> emit,
  ) async {
    try {
      final tags = await repository.getAllTags();
      emit(TagsLoaded(tags: tags));
    } catch (e) {
      emit(DocumentError(message: e.toString()));
    }
  }
}
