import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

class OcrFailure extends Failure {
  const OcrFailure(super.message);
}

class CameraFailure extends Failure {
  const CameraFailure(super.message);
}

class PdfFailure extends Failure {
  const PdfFailure(super.message);
}
