import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageProcessingService {
  // Edge detection using Canny algorithm
  Future<Uint8List> detectEdges(Uint8List imageData) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Failed to decode image');

      // Convert to grayscale
      final grayscale = img.grayscale(image);
      
      // Apply Gaussian blur
      final blurred = img.gaussianBlur(grayscale, radius: 2);

      // Apply edge detection using Sobel
      final edges = img.sobel(blurred);

      return Uint8List.fromList(img.encodeJpg(edges));
    } catch (e) {
      throw Exception('Edge detection failed: $e');
    }
  }

  // Perspective correction
  Future<Uint8List> correctPerspective(
    Uint8List imageData,
    List<List<double>> corners,
  ) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Failed to decode image');

      // Apply perspective transformation
      final corrected = img.copyCrop(
        image,
        x: corners[0][0].toInt(),
        y: corners[0][1].toInt(),
        width: (corners[1][0] - corners[0][0]).toInt(),
        height: (corners[2][1] - corners[0][1]).toInt(),
      );

      return Uint8List.fromList(img.encodeJpg(corrected));
    } catch (e) {
      throw Exception('Perspective correction failed: $e');
    }
  }

  // Auto-enhance image
  Future<Uint8List> enhanceImage(Uint8List imageData) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Failed to decode image');

      // Increase contrast
      final enhanced = img.adjustColor(
        image,
        contrast: 1.3,
        brightness: 10,
      );

      // Apply color boost for enhancement
      final boosted = img.adjustColor(
        enhanced,
        saturation: 1.2,
      );

      return Uint8List.fromList(img.encodeJpg(boosted, quality: 90));
    } catch (e) {
      throw Exception('Image enhancement failed: $e');
    }
  }

  // Convert to grayscale for document
  Future<Uint8List> convertToGrayscale(Uint8List imageData) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Failed to decode image');

      final grayscale = img.grayscale(image);
      return Uint8List.fromList(img.encodeJpg(grayscale, quality: 90));
    } catch (e) {
      throw Exception('Grayscale conversion failed: $e');
    }
  }

  // Create thumbnail
  Future<Uint8List> createThumbnail(
    Uint8List imageData, {
    int width = 200,
    int height = 200,
  }) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Failed to decode image');

      final thumbnail = img.copyResize(
        image,
        width: width,
        height: height,
        interpolation: img.Interpolation.linear,
      );

      return Uint8List.fromList(img.encodeJpg(thumbnail, quality: 85));
    } catch (e) {
      throw Exception('Thumbnail creation failed: $e');
    }
  }

  // Resize image
  Future<Uint8List> resizeImage(
    Uint8List imageData, {
    int? width,
    int? height,
  }) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Failed to decode image');

      final resized = img.copyResize(
        image,
        width: width,
        height: height,
        interpolation: img.Interpolation.linear,
      );

      return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
    } catch (e) {
      throw Exception('Image resize failed: $e');
    }
  }

  // Auto-crop document
  Future<Uint8List> autoCropDocument(Uint8List imageData) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Failed to decode image');

      // 自动裁剪：移除边缘空白区域
      final cropped = img.trim(image);

      return Uint8List.fromList(img.encodeJpg(cropped, quality: 90));
    } catch (e) {
      throw Exception('Auto-crop failed: $e');
    }
  }

  // ========== 高级图像处理功能 ==========

  /// 检测文档边缘（使用改进的轮廓检测算法）
  Future<List<List<int>>> detectDocumentEdges(Uint8List imageData) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Failed to decode image');

      // 1. 转换为灰度图
      final gray = img.grayscale(image);

      // 2. 高斯模糊降噪
      final blurred = img.gaussianBlur(gray, radius: 2);

      // 3. 使用 Sobel 算子检测边缘
      final edges = img.sobel(blurred);

      // 4. 二值化处理
      final binary = _threshold(edges, 50);

      // 5. 形态学操作（膨胀和腐蚀）
      final dilated = _dilate(binary, 3);
      final eroded = _erode(dilated, 3);

      // 6. 查找轮廓（简化版：查找最外层的矩形边界）
      final corners = _findDocumentCorners(eroded, image.width, image.height);

      return corners;
    } catch (e) {
      throw Exception('Document edge detection failed: $e');
    }
  }

  /// 透视变换（基于四个角点）
  Future<Uint8List> perspectiveTransform(
    Uint8List imageData,
    List<List<int>> corners,
  ) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Failed to decode image');
      if (corners.length != 4) throw Exception('Need exactly 4 corners');

      // 计算目标尺寸
      final width1 = _distance(corners[0], corners[1]);
      final width2 = _distance(corners[2], corners[3]);
      final maxWidth = math.max(width1, width2).toInt();

      final height1 = _distance(corners[0], corners[3]);
      final height2 = _distance(corners[1], corners[2]);
      final maxHeight = math.max(height1, height2).toInt();

      // 创建新的图像
      final result = img.Image(
        width: maxWidth,
        height: maxHeight,
        numChannels: 3,
      );

      // 简单的透视变换实现（使用双线性插值）
      for (var y = 0; y < maxHeight; y++) {
        for (var x = 0; x < maxWidth; x++) {
          // 计算在原图中的对应位置
          final srcX = _perspectiveMapX(x, y, corners, maxWidth, maxHeight);
          final srcY = _perspectiveMapY(x, y, corners, maxWidth, maxHeight);

          // 边界检查
          if (srcX >= 0 && srcX < image.width - 1 && srcY >= 0 && srcY < image.height - 1) {
            // 双线性插值
            final pixelValue = _bilinearInterpolate(image, srcX, srcY);
            result.setPixelRgb(x, y, pixelValue.toDouble(), pixelValue.toDouble(), pixelValue.toDouble());
          }
        }
      }

      return Uint8List.fromList(img.encodeJpg(result, quality: 95));
    } catch (e) {
      throw Exception('Perspective transform failed: $e');
    }
  }

  /// 去除阴影（使用背景减除法）
  Future<Uint8List> removeShadows(Uint8List imageData) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Failed to decode image');

      // 1. 转换为灰度图
      final gray = img.grayscale(image);

      // 2. 使用大半径高斯模糊获取背景
      final background = img.gaussianBlur(gray, radius: 30);

      // 3. 原始图像减去背景
      final normalized = img.Image(
        width: image.width,
        height: image.height,
        numChannels: 1,
      );

      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          final pixelValue = gray.getPixel(x, y).r.toInt();
          final bgValue = background.getPixel(x, y).r.toInt();

          // 归一化：如果背景较暗，说明有阴影
          var normalizedValue = pixelValue;
          if (bgValue < 200) {
            // 应用校正
            normalizedValue = math.min(
              255,
              (pixelValue * 255 / math.max(1, bgValue)).toInt(),
            );
          }

          normalized.setPixel(
            x,
            y,
            img.ColorRgb8(normalizedValue, normalizedValue, normalizedValue),
          );
        }
      }

      // 4. 增强对比度
      final enhanced = img.adjustColor(normalized, contrast: 1.3);

      return Uint8List.fromList(img.encodeJpg(enhanced, quality: 95));
    } catch (e) {
      throw Exception('Shadow removal failed: $e');
    }
  }

  /// 自适应阈值二值化（用于提高 OCR 准确率）
  Future<Uint8List> adaptiveBinarize(Uint8List imageData) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Failed to decode image');

      // 1. 转换为灰度图
      final gray = img.grayscale(image);

      // 2. 自适应阈值处理
      const blockSize = 11; // 必须是奇数
      const c = 2; // 常数

      final binary = img.Image(
        width: image.width,
        height: image.height,
        numChannels: 1,
      );

      for (var y = 0; y < image.height; y++) {
        for (var x = 0; x < image.width; x++) {
          // 计算局部区域的平均值
          var sum = 0;
          var count = 0;

          for (var dy = -blockSize ~/ 2;
              dy <= blockSize ~/ 2;
              dy++) {
            for (var dx = -blockSize ~/ 2;
                dx <= blockSize ~/ 2;
                dx++) {
              final nx = x + dx;
              final ny = y + dy;

              if (nx >= 0 &&
                  nx < image.width &&
                  ny >= 0 &&
                  ny < image.height) {
                sum += gray.getPixel(nx, ny).r.toInt();
                count++;
              }
            }
          }

          final threshold = sum ~/ count - c;
          final pixelValue = gray.getPixel(x, y).r.toInt();

          final newValue = pixelValue > threshold ? 255 : 0;
          binary.setPixel(
            x,
            y,
            img.ColorRgb8(newValue, newValue, newValue),
          );
        }
      }

      return Uint8List.fromList(img.encodeJpg(binary, quality: 95));
    } catch (e) {
      throw Exception('Adaptive binarization failed: $e');
    }
  }

  /// 智能裁剪（基于检测到的文档边缘）
  Future<Uint8List> smartCrop(Uint8List imageData) async {
    try {
      final corners = await detectDocumentEdges(imageData);
      if (corners.isEmpty) {
        // 如果没有检测到边缘，返回自动裁剪结果
        return await autoCropDocument(imageData);
      }

      // 应用透视变换
      return await perspectiveTransform(imageData, corners);
    } catch (e) {
      throw Exception('Smart crop failed: $e');
    }
  }

  /// 自动旋转矫正（检测文本行方向）
  Future<Uint8List> autoRotate(Uint8List imageData) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Failed to decode image');

      // 1. 转换为灰度图
      final gray = img.grayscale(image);

      // 2. 边缘检测
      final edges = img.sobel(gray);

      // 3. 检测主方向角度（简化版：使用霍夫变换的思想）
      final angle = _detectMainAngle(edges);

      // 4. 如果角度超过阈值，则旋转图像
      if (angle.abs() > 1.0) {
        final rotated = img.copyRotate(image, angle: angle);
        return Uint8List.fromList(img.encodeJpg(rotated, quality: 95));
      }

      return Uint8List.fromList(img.encodeJpg(image, quality: 95));
    } catch (e) {
      throw Exception('Auto rotation failed: $e');
    }
  }

  /// 文档质量评估（返回 0-100 的分数）
  Future<int> assessDocumentQuality(Uint8List imageData) async {
    try {
      final image = img.decodeImage(imageData);
      if (image == null) return 0;

      var score = 100;

      // 1. 检查清晰度（使用边缘强度）
      final gray = img.grayscale(image);
      final edges = img.sobel(gray);
      final edgeStrength = _calculateAverageBrightness(edges);

      if (edgeStrength < 20) {
        score -= 30; // 图像过于模糊
      } else if (edgeStrength < 50) {
        score -= 15; // 图像不够清晰
      }

      // 2. 检查亮度
      final brightness = _calculateAverageBrightness(gray);
      if (brightness < 50) {
        score -= 20; // 图像太暗
      } else if (brightness > 230) {
        score -= 20; // 图像太亮
      }

      // 3. 检查对比度
      final contrast = _calculateContrast(gray);
      if (contrast < 30) {
        score -= 20; // 对比度太低
      }

      // 4. 检查噪声水平
      final noiseLevel = _estimateNoise(gray);
      if (noiseLevel > 50) {
        score -= 10; // 噪声过多
      }

      return math.max(0, score);
    } catch (e) {
      return 0;
    }
  }

  // ========== 辅助方法 ==========

  /// 简单的阈值处理
  img.Image _threshold(img.Image image, int threshold) {
    final result = img.Image(
      width: image.width,
      height: image.height,
      numChannels: 1,
    );

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final pixelValue = image.getPixel(x, y).r.toInt();
        final newValue = pixelValue > threshold ? 255 : 0;
        result.setPixel(
          x,
          y,
          img.ColorRgb8(newValue, newValue, newValue),
        );
      }
    }

    return result;
  }

  /// 膨胀操作
  img.Image _dilate(img.Image image, int kernelSize) {
    final result = img.Image(
      width: image.width,
      height: image.height,
      numChannels: 1,
    );

    final half = kernelSize ~/ 2;

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        var maxValue = 0;

        for (var dy = -half; dy <= half; dy++) {
          for (var dx = -half; dx <= half; dx++) {
            final nx = x + dx;
            final ny = y + dy;

            if (nx >= 0 &&
                nx < image.width &&
                ny >= 0 &&
                ny < image.height) {
              maxValue = math.max(maxValue, image.getPixel(nx, ny).r.toInt());
            }
          }
        }

        result.setPixel(
          x,
          y,
          img.ColorRgb8(maxValue, maxValue, maxValue),
        );
      }
    }

    return result;
  }

  /// 腐蚀操作
  img.Image _erode(img.Image image, int kernelSize) {
    final result = img.Image(
      width: image.width,
      height: image.height,
      numChannels: 1,
    );

    final half = kernelSize ~/ 2;

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        var minValue = 255;

        for (var dy = -half; dy <= half; dy++) {
          for (var dx = -half; dx <= half; dx++) {
            final nx = x + dx;
            final ny = y + dy;

            if (nx >= 0 &&
                nx < image.width &&
                ny >= 0 &&
                ny < image.height) {
              minValue = math.min(minValue, image.getPixel(nx, ny).r.toInt());
            }
          }
        }

        result.setPixel(
          x,
          y,
          img.ColorRgb8(minValue, minValue, minValue),
        );
      }
    }

    return result;
  }

  /// 查找文档的四个角点
  List<List<int>> _findDocumentCorners(
    img.Image binary,
    int imageWidth,
    int imageHeight,
  ) {
    // 简化版：查找最外层的白色像素作为角点
    var minX = imageWidth;
    var maxX = 0;
    var minY = imageHeight;
    var maxY = 0;

    for (var y = 0; y < binary.height; y++) {
      for (var x = 0; x < binary.width; x++) {
        if (binary.getPixel(x, y).r > 128) {
          minX = math.min(minX, x);
          maxX = math.max(maxX, x);
          minY = math.min(minY, y);
          maxY = math.max(maxY, y);
        }
      }
    }

    // 如果没有找到任何前景像素，返回整个图像
    if (minX >= maxX || minY >= maxY) {
      return [
        [0, 0],
        [imageWidth, 0],
        [imageWidth, imageHeight],
        [0, imageHeight],
      ];
    }

    // 返回四个角点（顺时针：左上、右上、右下、左下）
    return [
      [minX, minY],
      [maxX, minY],
      [maxX, maxY],
      [minX, maxY],
    ];
  }

  /// 计算两点之间的距离
  double _distance(List<int> p1, List<int> p2) {
    final dx = (p1[0] - p2[0]).toDouble();
    final dy = (p1[1] - p2[1]).toDouble();
    return math.sqrt(dx * dx + dy * dy);
  }

  /// 透视变换 X 坐标映射
  double _perspectiveMapX(
    int x,
    int y,
    List<List<int>> corners,
    int width,
    int height,
  ) {
    // 简化的透视变换（使用双线性插值的近似）
    final u = x / width;
    final v = y / height;

    final x0 = corners[0][0] + (corners[1][0] - corners[0][0]) * u;
    final x1 = corners[3][0] + (corners[2][0] - corners[3][0]) * u;

    return x0 + (x1 - x0) * v;
  }

  /// 透视变换 Y 坐标映射
  double _perspectiveMapY(
    int x,
    int y,
    List<List<int>> corners,
    int width,
    int height,
  ) {
    final u = x / width;
    final v = y / height;

    final y0 = corners[0][1] + (corners[1][1] - corners[0][1]) * u;
    final y1 = corners[3][1] + (corners[2][1] - corners[3][1]) * u;

    return y0 + (y1 - y0) * v;
  }

  /// 双线性插值
  int _bilinearInterpolate(img.Image image, double x, double y) {
    final x0 = x.floor();
    final y0 = y.floor();
    final x1 = x0 + 1;
    final y1 = y0 + 1;

    final dx = x - x0;
    final dy = y - y0;

    final p00 = image.getPixel(x0, y0).r.toInt();
    final p10 = image.getPixel(x1, y0).r.toInt();
    final p01 = image.getPixel(x0, y1).r.toInt();
    final p11 = image.getPixel(x1, y1).r.toInt();

    final interpolated = p00 * (1 - dx) * (1 - dy) +
        p10 * dx * (1 - dy) +
        p01 * (1 - dx) * dy +
        p11 * dx * dy;

    return interpolated.toInt();
  }

  /// 检测图像的主方向角度
  double _detectMainAngle(img.Image edges) {
    // 简化版：统计边缘像素的方向
    var totalAngle = 0.0;
    var count = 0;

    for (var y = 1; y < edges.height - 1; y++) {
      for (var x = 1; x < edges.width - 1; x++) {
        if (edges.getPixel(x, y).r > 128) {
          // 计算梯度方向
          final gx = edges.getPixel(x + 1, y).r - edges.getPixel(x - 1, y).r;
          final gy = edges.getPixel(x, y + 1).r - edges.getPixel(x, y - 1).r;

          if (gx.abs() > 0 || gy.abs() > 0) {
            final angle = math.atan2(gy, gx) * 180 / math.pi;
            totalAngle += angle;
            count++;
          }
        }
      }
    }

    return count > 0 ? totalAngle / count : 0.0;
  }

  /// 计算图像的平均亮度
  double _calculateAverageBrightness(img.Image image) {
    var sum = 0.0;
    var count = 0;

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        sum += image.getPixel(x, y).r;
        count++;
      }
    }

    return count > 0 ? sum / count : 0.0;
  }

  /// 计算图像对比度
  double _calculateContrast(img.Image image) {
    double min = 255.0;
    double max = 0.0;

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final value = image.getPixel(x, y).r.toDouble();
        min = math.min<double>(min, value);
        max = math.max<double>(max, value);
      }
    }

    return max - min;
  }

  /// 估算噪声水平
  double _estimateNoise(img.Image image) {
    var sumDiff = 0.0;
    var count = 0;

    for (var y = 1; y < image.height - 1; y++) {
      for (var x = 1; x < image.width - 1; x++) {
        final center = image.getPixel(x, y).r;
        final neighbors = [
          image.getPixel(x - 1, y).r,
          image.getPixel(x + 1, y).r,
          image.getPixel(x, y - 1).r,
          image.getPixel(x, y + 1).r,
        ];

        final avg =
            neighbors.reduce((a, b) => a + b) / neighbors.length;
        sumDiff += (center - avg).abs();
        count++;
      }
    }

    return count > 0 ? sumDiff / count : 0.0;
  }
}
