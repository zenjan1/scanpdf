# 优秀开源项目研究与优化方案

## 一、参考的优秀开源项目

### 1. OpenScan (https://github.com/ethannguyen/OpenScan)
- **优势**: 轻量级 Android 扫描应用
- **核心技术**: OpenCV 边缘检测 + Tesseract OCR
- **值得借鉴**: 实时预览、自动裁剪算法

### 2. CamScanner 开源替代品 - SimpleScanner
- **优势**: 纯 Dart 实现，跨平台
- **核心技术**: ML Kit OCR + pdf 包
- **值得借鉴**: 批处理、云同步架构

### 3. Adobe Scan 功能参考
- **核心功能**: 智能文档识别、多页扫描、PDF优化
- **值得借鉴**: 文档增强算法、去阴影处理

## 二、当前项目差距分析

### 现有功能
✅ OCR 文字识别 (ML Kit)
✅ PDF 生成和合并
✅ 云同步基础框架
✅ 批量处理队列

### 缺失的关键功能
❌ 实时文档边缘检测
❌ 透视变换矫正
❌ 图像增强（去阴影、对比度调整）
❌ 智能裁剪
❌ 文档质量检测
❌ 离线模式优化

## 三、优化方案

### 3.1 图像预处理优化

#### 方案 A: OpenCV 集成（推荐）
```dart
// 添加依赖
// opencv_dart: ^0.1.0

import 'package:opencv_dart/opencv_dart.dart' as cv;

class ImagePreprocessor {
  // 1. 文档边缘检测
  Future<List<Point>> detectDocumentEdges(Uint8List imageBytes) async {
    final img = cv.Mat.fromImageData(imageBytes);
    final gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY);
    final blurred = cv.GaussianBlur(gray, (5, 5), 0);
    final edges = cv.Canny(blurred, 50, 150);
    
    // 形态学操作
    final kernel = cv.getStructuringElement(cv.MORPH_RECT, (3, 3));
    final dilated = cv.dilate(edges, kernel, iterations: 2);
    
    final contours = cv.findContours(dilated, cv.RETR_EXTERNAL);
    final largest = _findLargestContour(contours);
    
    return _approximatePolygon(largest);
  }
  
  // 2. 透视变换
  Future<Uint8List> perspectiveTransform(
    Uint8List imageBytes,
    List<Point> corners,
  ) async {
    final img = cv.Mat.fromImageData(imageBytes);
    final srcPoints = corners.map((p) => [p.x, p.y]).toList();
    
    // 计算目标尺寸
    final width1 = corners[0].distanceTo(corners[1]);
    final width2 = corners[2].distanceTo(corners[3]);
    final maxWidth = max(width1, width2).toInt();
    
    final height1 = corners[0].distanceTo(corners[3]);
    final height2 = corners[1].distanceTo(corners[2]);
    final maxHeight = max(height1, height2).toInt();
    
    final dstPoints = [
      [0, 0],
      [maxWidth, 0],
      [maxWidth, maxHeight],
      [0, maxHeight],
    ];
    
    final matrix = cv.getPerspectiveTransform(srcPoints, dstPoints);
    final warped = cv.warpPerspective(img, matrix, (maxWidth, maxHeight));
    
    return warped.toImageData();
  }
  
  // 3. 文档增强
  Future<Uint8List> enhanceDocument(Uint8List imageBytes) async {
    final img = cv.Mat.fromImageData(imageBytes);
    final gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY);
    
    // 自适应阈值二值化
    final binary = cv.adaptiveThreshold(
      gray,
      255,
      cv.ADAPTIVE_THRESH_GAUSSIAN_C,
      cv.THRESH_BINARY,
      11,
      2,
    );
    
    // 去噪
    final denoised = cv.GaussianBlur(binary, (3, 3), 0);
    
    return denoised.toImageData();
  }
}
```

#### 方案 B: 纯 Dart 实现（轻量级）
```dart
import 'package:image/image.dart' as img;

class SimpleImagePreprocessor {
  // 文档边缘检测（简化版）
  List<Offset> detectEdges(img.Image image) {
    final gray = img.grayscale(image);
    final edges = img.sobel(gray);
    
    // 使用 Harris 角点检测
    final corners = <Offset>[];
    for (var y = 0; y < edges.height; y++) {
      for (var x = 0; x < edges.width; x++) {
        final pixel = edges.getPixel(x, y);
        if (pixel.r > 200) {
          corners.add(Offset(x.toDouble(), y.toDouble()));
        }
      }
    }
    
    return _findCorners(corners, image.width, image.height);
  }
  
  // 对比度增强
  img.Image enhanceContrast(img.Image image, {double factor = 1.5}) {
    return img.adjustColor(image, contrast: factor);
  }
  
  // 去阴影
  img.Image removeShadows(img.Image image) {
    final gray = img.grayscale(image);
    final inverted = img.invert(gray);
    final blurred = img.gaussianBlur(inverted, radius: 20);
    final normalized = img.subtract(image, blurred);
    return img.adjustColor(normalized, contrast: 1.3);
  }
}
```

### 3.2 智能裁剪优化

```dart
class SmartCropper {
  // 基于文档边缘的智能裁剪
  Future<img.Image> smartCrop(img.Image image, List<Offset> corners) async {
    // 计算裁剪区域
    final minX = corners.map((c) => c.dx).reduce(min).toInt();
    final maxX = corners.map((c) => c.dx).reduce(max).toInt();
    final minY = corners.map((c) => c.dy).reduce(min).toInt();
    final maxY = corners.map((c) => c.dy).reduce(max).toInt();
    
    // 添加边距
    final padding = 10;
    final cropX = max(0, minX - padding);
    final cropY = max(0, minY - padding);
    final cropWidth = min(image.width - cropX, (maxX - minX) + padding * 2);
    final cropHeight = min(image.height - cropY, (maxY - minY) + padding * 2);
    
    return img.copyCrop(
      image,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );
  }
  
  // 自动旋转矫正
  Future<img.Image> autoRotate(img.Image image) async {
    // 使用 Hough 变换检测文本行方向
    final gray = img.grayscale(image);
    final edges = img.sobel(gray);
    
    // 检测主方向
    final angle = _detectMainAngle(edges);
    
    if (angle.abs() > 1) {
      return img.copyRotate(image, angle: angle);
    }
    
    return image;
  }
}
```

### 3.3 OCR 优化方案

```dart
class OptimizedOcrService {
  final TextRecognizer _recognizer = TextRecognizer();
  
  // 1. 多语言支持
  Future<OcrResult> recognizeWithLanguage(
    Uint8List imageBytes,
    OcrLanguage language,
  ) async {
    // 根据语言选择合适的识别器
    final recognizer = _getRecognizerForLanguage(language);
    
    // 预处理
    final enhanced = await _preprocessForOcr(imageBytes, language);
    
    // 识别
    final result = await recognizer.processImage(
      InputImage.fromBytes(enhanced),
    );
    
    return _parseResult(result);
  }
  
  // 2. 置信度过滤
  OcrResult _filterByConfidence(RecognizedText text, double threshold) {
    final filteredBlocks = text.blocks
        .where((block) => block.confidence >= threshold)
        .toList();
    
    return OcrResult(
      text: filteredBlocks.map((b) => b.text).join('\n'),
      blocks: filteredBlocks,
      averageConfidence: _calculateAverageConfidence(filteredBlocks),
    );
  }
  
  // 3. 表格识别
  Future<TableData> recognizeTable(Uint8List imageBytes) async {
    final result = await _recognizer.processImage(
      InputImage.fromBytes(imageBytes),
    );
    
    // 分析文本块的行列关系
    final rows = _groupByRows(result.blocks);
    final columns = _groupByColumns(rows);
    
    return TableData(rows: rows, columns: columns);
  }
}
```

### 3.4 云同步架构优化

```dart
class EnhancedSyncService {
  // 1. 增量同步
  Future<void> incrementalSync() async {
    final localChanges = await _getLocalChanges();
    final remoteChanges = await _getRemoteChanges(since: lastSyncTime);
    
    // 冲突检测
    final conflicts = _detectConflicts(localChanges, remoteChanges);
    
    if (conflicts.isNotEmpty) {
      await _resolveConflicts(conflicts);
    }
    
    // 应用变更
    await _applyRemoteChanges(remoteChanges);
    await _pushLocalChanges(localChanges);
  }
  
  // 2. 离线队列持久化
  Future<void> saveOfflineQueue(List<SyncOperation> operations) async {
    final json = operations.map((op) => op.toJson()).toList();
    await SharedPreferences.getInstance().then((prefs) {
      prefs.setString('offline_queue', jsonEncode(json));
    });
  }
  
  // 3. 断点续传
  Future<void> uploadWithResume(File file, {String? uploadId}) async {
    if (uploadId == null) {
      // 开始新上传
      uploadId = await _initiateUpload(file.length);
    }
    
    final uploadedBytes = await _getUploadedBytes(uploadId);
    final fileToUpload = file.openRead(uploadedBytes);
    
    await _uploadChunk(uploadId, fileToUpload);
  }
}
```

### 3.5 UI/UX 最佳实践

```dart
// 1. 实时预览
class ScanPreviewScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return CameraPreview(
      onFrame: (frame) async {
        // 实时边缘检测
        final edges = await detectEdges(frame);
        
        // 在相机画面上叠加预览
        return Stack(
          children: [
            CameraPreviewImage(frame),
            DocumentOverlay(edges: edges),
          ],
        );
      },
    );
  }
}

// 2. 手势裁剪
class GestureCropper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        // 实时更新裁剪框
        setState(() {
          cropCorners = _updateCorners(details);
        });
      },
      child: CustomPaint(
        painter: CropBoxPainter(corners: cropCorners),
        child: Image.file(imageFile),
      ),
    );
  }
}

// 3. 进度反馈
class ScanProgressIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ScanProgress>(
      stream: scanService.progressStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();
        
        final progress = snapshot.data!;
        return Column(
          children: [
            LinearProgressIndicator(value: progress.value),
            Text(progress.message),
            if (progress.hasError) ErrorDisplay(progress.error),
          ],
        );
      },
    );
  }
}
```

## 四、实施优先级

### Phase 1: 核心功能增强（1-2周）
1. ✅ 添加文档边缘检测
2. ✅ 实现透视变换
3. ✅ 图像增强算法

### Phase 2: OCR 优化（1周）
1. ✅ 多语言支持优化
2. ✅ 置信度过滤
3. ✅ 表格识别

### Phase 3: 云同步完善（1-2周）
1. ✅ 增量同步
2. ✅ 冲突解决
3. ✅ 断点续传

### Phase 4: UI/UX 改进（1周）
1. ✅ 实时预览
2. ✅ 手势裁剪
3. ✅ 进度反馈

## 五、推荐的第三方库

```yaml
dependencies:
  # 图像处理
  opencv_dart: ^0.1.0
  image: ^4.0.17
  
  # OCR
  google_mlkit_text_recognition: ^0.11.0
  
  # 相机
  camera: ^0.10.5+9
  
  # PDF
  pdf: ^3.10.7
  
  # 云同步
  firebase_storage: ^11.6.0
  cloud_firestore: ^4.14.0
  
  # 状态管理
  flutter_bloc: ^8.1.3
  
  # 本地存储
  sqflite: ^2.3.0
  shared_preferences: ^2.2.2
  
  # 网络
  dio: ^5.4.0
  connectivity_plus: ^5.0.2
```

