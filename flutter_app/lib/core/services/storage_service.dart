import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  Future<Directory> get _appDir async {
    final dir = await getApplicationDocumentsDirectory();
    final appDir = Directory('${dir.path}/ScanPDF');
    if (!await appDir.exists()) {
      await appDir.create(recursive: true);
    }
    return appDir;
  }

  Future<Directory> get _documentsDir async {
    final appDir = await _appDir;
    final docsDir = Directory('${appDir.path}/Documents');
    if (!await docsDir.exists()) {
      await docsDir.create(recursive: true);
    }
    return docsDir;
  }

  Future<Directory> get _imagesDir async {
    final appDir = await _appDir;
    final imagesDir = Directory('${appDir.path}/Images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    return imagesDir;
  }

  Future<Directory> get _thumbnailsDir async {
    final appDir = await _appDir;
    final thumbsDir = Directory('${appDir.path}/Thumbnails');
    if (!await thumbsDir.exists()) {
      await thumbsDir.create(recursive: true);
    }
    return thumbsDir;
  }

  Future<String> saveImage(String imageId, List<int> imageData) async {
    final imagesDir = await _imagesDir;
    final filePath = '${imagesDir.path}/$imageId.jpg';
    final file = File(filePath);
    await file.writeAsBytes(imageData);
    return filePath;
  }

  Future<String> generateDocumentId() async {
    const uuid = Uuid();
    return 'doc_${uuid.v4()}';
  }

  Future<String> generateImageId() async {
    const uuid = Uuid();
    return 'img_${uuid.v4()}';
  }

  Future<String> getDocumentPath(String documentId) async {
    final docsDir = await _documentsDir;
    return '${docsDir.path}/$documentId.pdf';
  }

  Future<String> getThumbnailPath(String imageId) async {
    final thumbsDir = await _thumbnailsDir;
    return '${thumbsDir.path}/${imageId}_thumb.jpg';
  }

  Future<void> deleteFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<int> getStorageSize() async {
    final appDir = await _appDir;
    return await _getDirectorySize(appDir);
  }

  Future<int> _getDirectorySize(Directory dir) async {
    int totalSize = 0;
    final entities = dir.listSync(recursive: true, followLinks: false);
    for (final entity in entities) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }
    return totalSize;
  }

  Future<void> clearCache() async {
    final thumbsDir = await _thumbnailsDir;
    if (await thumbsDir.exists()) {
      await thumbsDir.delete(recursive: true);
      await thumbsDir.create(recursive: true);
    }
  }
}
