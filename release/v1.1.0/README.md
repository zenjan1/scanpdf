# ScanPDF v1.1.0 Release Package

## 📦 Contents

- `scanpdf-v1.1.0-android.apk` - Android 安装包 (29 MB)
- `scanpdf-v1.1.0-linux-x64.tar.gz` - Linux 桌面版 (13 MB)
- `SHA256SUMS.txt` - 文件校验和
- `RELEASE_NOTES.md` - 发布说明

## 🔐 Verify Integrity

```bash
# 验证文件完整性
sha256sum -c SHA256SUMS.txt
```

## 📱 Installation

### Android
1. Transfer APK to your Android device
2. Enable "Install from Unknown Sources" in Settings
3. Open APK file and follow installation prompts

### Linux (x64)
```bash
# 解压
tar -xzf scanpdf-v1.1.0-linux-x64.tar.gz

# 运行
./flutter_app
```

## 🎯 What's New

### Key Features
- ✅ Multi-language OCR (5 languages)
- ✅ Smart image preprocessing
- ✅ Favorites & sorting
- ✅ Real API authentication
- ✅ PDF merge/split operations

### Quality
- 16/16 tests passing
- 0 errors, 0 warnings
- 0 TODOs remaining

## 📊 Build Stats

- **Build Time**: ~4 minutes
- **Flutter**: 3.24.0
- **Dart**: 3.5.0
- **Platforms**: Android, Linux

---

**Release Date**: 2026-07-09  
**Version**: 1.1.0+2  
**Status**: ✅ Ready for Distribution
