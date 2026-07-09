# ScanPDF v1.1.0 Release Notes

## 🚀 New Features

### OCR Enhancement
- Multi-language OCR support (Chinese, English, Japanese, Korean, Hindi)
- Image preprocessing modes (auto, grayscale, high contrast, binarize)
- Real-time OCR progress tracking
- Search functionality within OCR results
- Confidence score display with character/word statistics

### Document Management
- Favorites filtering and sorting
- Sort by update time, title, or creation time
- Improved bottom navigation with dedicated favorites tab

### PDF Operations
- PDF merge functionality
- PDF split functionality
- Searchable PDF generation with OCR text layer

### Authentication
- Real API login integration (JWT token)
- Auto token management with request interceptors
- Automatic logout on 401 unauthorized

## 🐛 Bug Fixes

- Fixed CameraScreen compilation error (AnimatedBuilder → ScaleTransition)
- Fixed OCR service confidence calculation
- Fixed language recognition API usage
- Fixed DocumentEvent type mismatch
- Fixed bcrypt compatibility issue with passlib
- Removed unused imports and fields

## 📦 Build Information

- **Version**: 1.1.0+2
- **Flutter**: 3.24.0
- **Dart**: 3.5.0

### Platforms
- ✅ Android APK (30.3 MB)
- ✅ Linux Desktop (tar.gz)

## 🔧 Technical Improvements

- Database service: SQLite support for testing
- Network service: Automatic authorization header injection
- Security: Replaced passlib with direct bcrypt usage
- Test coverage: 100% test pass rate (5 Flutter + 11 Server tests)

## 📝 Code Quality

- 0 TODOs remaining
- 0 errors, 0 warnings in Flutter analyzer
- All server tests passing

