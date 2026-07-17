import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scanpdf/core/theme/app_theme.dart';
import 'package:scanpdf/core/services/service_locator.dart';
import 'package:scanpdf/core/services/update_service.dart';
import 'package:scanpdf/features/document/presentation/bloc/document_bloc.dart';
import 'package:scanpdf/features/document/presentation/screens/home_screen.dart';
import 'package:scanpdf/features/document/presentation/screens/recycle_bin_screen.dart';
import 'package:scanpdf/features/settings/presentation/screens/settings_screen.dart';
import 'package:scanpdf/features/camera/presentation/screens/camera_screen.dart';
import 'package:scanpdf/features/scanner/presentation/screens/scanner_screen.dart';
import 'package:scanpdf/features/ocr/presentation/screens/ocr_screen.dart';
import 'package:scanpdf/features/update/update_bloc.dart';
import 'package:scanpdf/shared/widgets/update_dialog.dart';
import 'package:go_router/go_router.dart';

class ScanPdfApp extends StatefulWidget {
  const ScanPdfApp({super.key});

  @override
  State<ScanPdfApp> createState() => _ScanPdfAppState();
}

class _ScanPdfAppState extends State<ScanPdfApp> {
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _scheduleUpdateCheck();
  }

  void _scheduleUpdateCheck() {
    // 延迟 3 秒检查更新，避免影响启动速度
    _updateTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        context.read<UpdateBloc>().add(CheckForUpdate());
      }
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DocumentBloc(
            repository: sl(),
          )..add(const LoadDocumentsEvent()),
        ),
        BlocProvider(
          create: (context) => UpdateBloc(sl<UpdateService>()),
        ),
      ],
      child: BlocListener<UpdateBloc, UpdateState>(
        listener: (context, state) {
          if (state is UpdateAvailable) {
            showUpdateDialog(
              context: context,
              versionInfo: state.versionInfo,
              forceUpdate: state.versionInfo.forceUpdate,
              onUpdate: () {
                context.read<UpdateBloc>().add(
                      StartDownload(state.versionInfo.downloadUrl),
                    );
              },
              onSkip: () {
                context.read<UpdateBloc>().add(
                      SkipVersion(state.versionInfo.version),
                    );
              },
            );
          } else if (state is UpdateError) {
            debugPrint('更新检查错误：${state.message}');
          }
        },
        child: MaterialApp.router(
          title: 'ScanPDF - 智能扫描办公',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          routerConfig: _router,
        ),
      ),
    );
  }

  GoRouter get _router => GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/camera',
            builder: (context, state) => const CameraScreen(),
          ),
          GoRoute(
            path: '/scan',
            builder: (context, state) => const ScannerScreen(params: {}),
          ),
          GoRoute(
            path: '/ocr',
            builder: (context, state) =>
                OcrScreen(imagePath: state.extra as String? ?? ''),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/recycle-bin',
            builder: (context, state) => const RecycleBinScreen(),
          ),
        ],
      );
}
