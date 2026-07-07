# ScanPDF 多平台构建指南

## 构建环境要求

### Linux 桌面版 ✅ 已支持
**系统要求**: Ubuntu 20.04+ / Debian / Fedora
```bash
# 安装依赖
sudo apt-get install -y clang cmake ninja-build \
  pkg-config libgtk-3-dev liblzma-dev libjsoncpp-dev \
  libfuse2 libblkid-dev

# 构建命令
flutter build linux --release

# 产物位置
build/linux/x64/release/bundle/
```

### Android 版 ✅ 已支持
**系统要求**: 任何系统（需要 Android SDK）
```bash
flutter build apk --release
# 或
flutter build appbundle --release

# 产物位置
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

### macOS 版 ❌ 需要 macOS 系统
**系统要求**: macOS 10.14+ + Xcode 12+
```bash
# 添加 macOS 支持（首次）
flutter create --platforms=macos .

# 构建命令
flutter build macos --release

# 产物位置
build/macos/Build/Products/Release/flutter_app.app
```

### Windows 版 ❌ 需要 Windows 系统
**系统要求**: Windows 10/11 + Visual Studio 2019+
```bash
# 添加 Windows 支持（首次）
flutter create --platforms=windows .

# 构建命令
flutter build windows --release

# 产物位置
build\windows\x64\runner\Release\
```

### 鸿蒙版 (HarmonyOS NEXT) 🔧 需要 DevEco Studio
**系统要求**: 任何系统 + DevEco Studio
```bash
# 1. 安装 DevEco Studio
# 下载地址: https://developer.huawei.com/consumer/cn/deveco-studio/

# 2. 安装工具链
# 在 DevEco Studio 中安装: hvigorw, ohpm, hdc

# 3. 构建命令（在 harmony 目录）
cd flutter_app/harmony
hvigorw assembleHap --mode release

# 产物位置
entry/build/default/outputs/default/entry-default-signed.hap
```

## 当前构建状态

| 平台 | 状态 | 产物大小 | 备注 |
|------|------|----------|------|
| Android APK | ✅ 已构建 | 30.2MB | Release 版本 |
| Linux 桌面 | ✅ 已构建 | 31MB | Release 版本 |
| macOS | ❌ 需 macOS | - | 需要 Mac 系统 |
| Windows | ❌ 需 Windows | - | 需要 Windows + VS |
| 鸿蒙 | ❌ 缺工具链 | - | 需要 DevEco Studio |

## CI/CD 多平台构建建议

### GitHub Actions 示例
```yaml
name: Build Multi-Platform

on:
  push:
    tags:
      - 'v*'

jobs:
  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build apk --release
      - uses: actions/upload-artifact@v3
        with:
          name: android-apk
          path: build/app/outputs/flutter-apk/app-release.apk

  build-linux:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: |
          sudo apt-get install -y clang cmake ninja-build \
            pkg-config libgtk-3-dev liblzma-dev
          flutter build linux --release
      - uses: actions/upload-artifact@v3
        with:
          name: linux-desktop
          path: build/linux/x64/release/bundle/

  build-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build macos --release
      - uses: actions/upload-artifact@v3
        with:
          name: macos-app
          path: build/macos/Build/Products/Release/

  build-windows:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: flutter build windows --release
      - uses: actions/upload-artifact@v3
        with:
          name: windows-app
          path: build\windows\x64\runner\Release\
```

## 快速验证

### Linux 桌面版运行
```bash
cd flutter_app
./build/linux/x64/release/bundle/flutter_app
```

### 打包为 AppImage（可选）
```bash
# 安装 appimagetool
wget https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x appimagetool-x86_64.AppImage

# 打包
./appimagetool-x86_64.AppImage build/linux/x64/release/bundle/
```

### 打包为 Snap（可选）
```bash
# 创建 snapcraft.yaml
snapcraft

# 安装
sudo snap install scanpdf_*.snap --dangerous
```

## 常见问题

### Q: 为什么无法构建 macOS/Windows 版？
A: Flutter 桌面应用不支持交叉编译，必须在对应平台上构建。

### Q: 鸿蒙版需要什么工具？
A: 需要安装 DevEco Studio，其中包含 hvigorw 构建工具、ohpm 包管理器和 hdc 调试工具。

### Q: 可以在 Linux 上构建 Windows 版吗？
A: 不可以，Flutter Windows 版需要 Visual Studio 和 Windows SDK，只能在 Windows 上构建。
