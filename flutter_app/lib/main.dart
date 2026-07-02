import 'package:flutter/material.dart';
import 'package:scanpdf/app/app.dart';
import 'package:scanpdf/core/services/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await init();
  runApp(const ScanPdfApp());
}
