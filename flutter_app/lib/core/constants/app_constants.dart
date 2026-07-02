class AppConstants {
  // App Info
  static const String appName = 'ScanPDF';
  static const String appVersion = '1.0.0';
  
  // API Endpoints
  static const String baseUrl = 'https://jp.zenjan.store';
  static const String apiEndpoint = '/api/v1';
  
  // Storage
  static const String databaseName = 'scanpdf.db';
  static const int databaseVersion = 1;
  
  // Image Processing
  static const int maxImageWidth = 2000;
  static const int maxImageHeight = 2000;
  static const int thumbnailSize = 200;
  static const double imageQuality = 0.85;
  
  // PDF Settings
  static const double defaultPdfDpi = 300.0;
  static const double maxPdfDpi = 600.0;
  
  // OCR
  static const List<String> supportedLanguages = [
    'en', 'zh', 'ja', 'ko', 'es', 'fr', 'de', 'ru', 'ar', 'hi'
  ];
  
  // File Formats
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  static const List<String> supportedDocFormats = ['pdf', 'jpg', 'jpeg', 'png'];
  
  // Cache
  static const Duration cacheDuration = Duration(days: 7);
  static const int maxCacheSize = 500 * 1024 * 1024; // 500MB
}
