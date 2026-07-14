import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:scanpdf/core/theme/app_theme.dart';
import 'package:scanpdf/core/services/service_locator.dart';
import 'package:scanpdf/features/document/presentation/bloc/document_bloc.dart';
import 'package:scanpdf/features/document/presentation/screens/home_screen.dart';
import 'package:scanpdf/features/document/presentation/screens/recycle_bin_screen.dart';
import 'package:scanpdf/features/settings/presentation/screens/settings_screen.dart';
import 'package:scanpdf/features/camera/presentation/screens/camera_screen.dart';
import 'package:scanpdf/features/scanner/presentation/screens/scanner_screen.dart';
import 'package:scanpdf/features/ocr/presentation/screens/ocr_screen.dart';
import 'package:go_router/go_router.dart';

class ScanPdfApp extends StatelessWidget {
  const ScanPdfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DocumentBloc(
            repository: sl(),
          )..add(const LoadDocumentsEvent()),
        ),
      ],
      child: MaterialApp.router(
        title: 'ScanPDF - 智能扫描办公',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: _router,
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
        builder: (context, state) => OcrScreen(imagePath: state.extra as String? ?? ''),
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
