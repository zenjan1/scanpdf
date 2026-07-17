import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scanpdf/core/services/update_service.dart';

// Events
abstract class UpdateEvent extends Equatable {
  const UpdateEvent();

  @override
  List<Object?> get props => [];
}

class CheckForUpdate extends UpdateEvent {}

class StartDownload extends UpdateEvent {
  final String downloadUrl;
  const StartDownload(this.downloadUrl);

  @override
  List<Object?> get props => [downloadUrl];
}

class SkipVersion extends UpdateEvent {
  final String version;
  const SkipVersion(this.version);

  @override
  List<Object?> get props => [version];
}

// States
abstract class UpdateState extends Equatable {
  const UpdateState();

  @override
  List<Object?> get props => [];
}

class UpdateIdle extends UpdateState {}

class UpdateChecking extends UpdateState {}

class UpdateAvailable extends UpdateState {
  final VersionInfo versionInfo;
  const UpdateAvailable(this.versionInfo);

  @override
  List<Object?> get props => [versionInfo];
}

class UpdateNotAvailable extends UpdateState {}

class UpdateDownloading extends UpdateState {
  final double progress;
  const UpdateDownloading(this.progress);

  @override
  List<Object?> get props => [progress];
}

class UpdateDownloaded extends UpdateState {
  final String filePath;
  const UpdateDownloaded(this.filePath);

  @override
  List<Object?> get props => [filePath];
}

class UpdateError extends UpdateState {
  final String message;
  const UpdateError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class UpdateBloc extends Bloc<UpdateEvent, UpdateState> {
  final UpdateService _updateService;

  UpdateBloc(this._updateService) : super(UpdateIdle()) {
    on<CheckForUpdate>(_onCheckForUpdate);
    on<StartDownload>(_onStartDownload);
    on<SkipVersion>(_onSkipVersion);
  }

  Future<void> _onCheckForUpdate(
    CheckForUpdate event,
    Emitter<UpdateState> emit,
  ) async {
    emit(UpdateChecking());

    try {
      final versionInfo = await _updateService.checkForUpdate();

      if (versionInfo != null) {
        // 检查是否已跳过此版本
        final isSkipped =
            await _updateService.isVersionSkipped(versionInfo.version);

        if (!isSkipped) {
          emit(UpdateAvailable(versionInfo));
        } else {
          emit(UpdateNotAvailable());
        }
      } else {
        emit(UpdateNotAvailable());
      }
    } catch (e) {
      emit(UpdateError('检查更新失败：$e'));
    }
  }

  Future<void> _onStartDownload(
    StartDownload event,
    Emitter<UpdateState> emit,
  ) async {
    try {
      final filePath = await _updateService.downloadApk(
        event.downloadUrl,
        (received, total) {
          if (total > 0) {
            emit(UpdateDownloading(received / total));
          }
        },
      );

      if (filePath != null) {
        emit(UpdateDownloaded(filePath));
        // 自动安装
        await _updateService.installApk(filePath);
      } else {
        emit(UpdateError('下载失败'));
      }
    } catch (e) {
      emit(UpdateError('下载失败：$e'));
    }
  }

  Future<void> _onSkipVersion(
    SkipVersion event,
    Emitter<UpdateState> emit,
  ) async {
    await _updateService.skipVersion(event.version);
    emit(UpdateNotAvailable());
  }
}
