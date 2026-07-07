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
}
