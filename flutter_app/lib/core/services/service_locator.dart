import 'package:get_it/get_it.dart';
import 'package:scanpdf/core/services/database_service.dart';
import 'package:scanpdf/core/services/storage_service.dart';
import 'package:scanpdf/core/services/ocr_service.dart';
import 'package:scanpdf/core/services/image_processing_service.dart';
import 'package:scanpdf/core/services/pdf_service.dart';
import 'package:scanpdf/core/services/network_service.dart';
import 'package:scanpdf/features/document/data/datasources/document_local_datasource.dart';
import 'package:scanpdf/features/document/data/datasources/document_remote_datasource.dart';
import 'package:scanpdf/features/document/data/repositories/document_repository_impl.dart';
import 'package:scanpdf/features/document/domain/repositories/document_repository.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // Core Services
  sl.registerLazySingleton(() => DatabaseService());
  sl.registerLazySingleton(() => StorageService());
  sl.registerLazySingleton(() => OcrService());
  sl.registerLazySingleton(() => ImageProcessingService());
  sl.registerLazySingleton(() => PdfService());
  sl.registerLazySingleton(() => NetworkService());

  // Data Sources
  sl.registerLazySingleton<DocumentLocalDatasource>(
    () => DocumentLocalDatasourceImpl(database: sl()),
  );
  sl.registerLazySingleton<DocumentRemoteDatasource>(
    () => DocumentRemoteDatasourceImpl(networkService: sl()),
  );

  // Repositories
  sl.registerLazySingleton<DocumentRepository>(
    () => DocumentRepositoryImpl(
      localDatasource: sl(),
      remoteDatasource: sl(),
      networkService: sl(),
    ),
  );
}
