import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

/// OCR 语言选项
enum OcrLanguage {
  chinese('zh', '中文', TextRecognitionScript.chinese),
  english('en', 'English', TextRecognitionScript.latin),
  japanese('ja', '日本語', TextRecognitionScript.japanese),
  korean('ko', '한국어', TextRecognitionScript.korean);

  final String code;
  final String displayName;
  final TextRecognitionScript script;
  const OcrLanguage(this.code, this.displayName, this.script);

  static OcrLanguage fromCode(String code) {
    return OcrLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => OcrLanguage.chinese,
    );
  }
}

/// OCR 预处理选项
enum OcrPreprocessMode {
  none('原始'),
  auto('自动'),
  grayscale('灰度'),
  highContrast('高对比度'),
  binarize('二值化');

  final String label;
  const OcrPreprocessMode(this.label);
}

/// OCR 识别结果
class OcrResult {
  final String fullText;
  final List<OcrBlock> blocks;
  final List<OcrParagraph> paragraphs;
  final double averageConfidence;
  final Map<String, double> detectedLanguages;
  final Duration processingTime;
  final int totalCharacters;
  final int totalWords;
  final int totalLines;

  OcrResult({
    required this.fullText,
    required this.blocks,
    required this.paragraphs,
    required this.averageConfidence,
    required this.detectedLanguages,
    required this.processingTime,
  })  : totalCharacters = fullText.length,
        totalWords = fullText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
        totalLines = fullText.split('\n').where((l) => l.trim().isNotEmpty).length;

  bool get isEmpty => fullText.trim().isEmpty;
  bool get isNotEmpty => !isEmpty;
}

/// 文本块
class OcrBlock {
  final String text;
  final double confidence;
  final List<OcrLine> lines;
  final Map<String, double> detectedLanguages;
  final Rect? boundingBox;

  OcrBlock({
    required this.text,
    required this.confidence,
    required this.lines,
    required this.detectedLanguages,
    this.boundingBox,
  });
}

/// 文本行
class OcrLine {
  final String text;
  final double confidence;
  final List<OcrWord> words;
  final Rect? boundingBox;

  OcrLine({
    required this.text,
    required this.confidence,
    required this.words,
    this.boundingBox,
  });
}

/// 单词
class OcrWord {
  final String text;
  final double confidence;
  final Rect? boundingBox;

  OcrWord({
    required this.text,
    required this.confidence,
    this.boundingBox,
  });
}

/// 段落
class OcrParagraph {
  final String text;
  final List<OcrBlock> blocks;
  final double averageConfidence;

  OcrParagraph({
    required this.text,
    required this.blocks,
    required this.averageConfidence,
  });
}

/// 简化的矩形（不依赖 dart:ui）
class Rect {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const Rect({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get width => right - left;
  double get height => bottom - top;

  @override
  String toString() => 'Rect($left, $top, $right, $bottom)';
}

/// OCR 服务 - 支持多语言、预处理、缓存
class OcrService {
  TextRecognizer? _currentRecognizer;
  OcrLanguage _currentLanguage = OcrLanguage.chinese;

  /// 结果缓存: imagePath+language -> OcrResult
  final Map<String, OcrResult> _cache = {};
  static const int _maxCacheSize = 20;

  /// 当前语言
  OcrLanguage get currentLanguage => _currentLanguage;

  /// 获取指定语言的 TextRecognizer（复用已有实例）
  TextRecognizer _getRecognizer(OcrLanguage language) {
    if (_currentRecognizer != null && _currentLanguage == language) {
      return _currentRecognizer!;
    }
    _currentRecognizer?.close();
    _currentLanguage = language;
    _currentRecognizer = TextRecognizer(script: language.script);
    return _currentRecognizer!;
  }

  /// 提取纯文本
  Future<String> extractText(
    String imagePath, {
    OcrLanguage language = OcrLanguage.chinese,
  }) async {
    final result = await recognizeText(imagePath, language: language);
    return result.fullText;
  }

  /// 核心 OCR 识别方法 - 返回完整结果
  Future<OcrResult> recognizeText(
    String imagePath, {
    OcrLanguage language = OcrLanguage.chinese,
    OcrPreprocessMode preprocess = OcrPreprocessMode.auto,
    void Function(String status, double progress)? onProgress,
  }) async {
    final stopwatch = Stopwatch()..start();

    // 检查缓存
    final cacheKey = '$imagePath|${language.code}|${preprocess.name}';
    if (_cache.containsKey(cacheKey)) {
      onProgress?.call('使用缓存结果', 1.0);
      return _cache[cacheKey]!;
    }

    try {
      onProgress?.call('准备图片', 0.1);

      // 图片预处理
      String processedPath = imagePath;
      if (preprocess != OcrPreprocessMode.none) {
        onProgress?.call('图片预处理', 0.3);
        processedPath = await _preprocessImage(imagePath, preprocess);
      }

      onProgress?.call('正在识别文字', 0.5);

      // OCR 识别
      final recognizer = _getRecognizer(language);
      final inputImage = InputImage.fromFile(File(processedPath));
      final recognizedText = await recognizer.processImage(inputImage);

      onProgress?.call('解析识别结果', 0.8);

      // 解析结果为结构化数据
      final blocks = _parseBlocks(recognizedText.blocks);
      final paragraphs = _groupIntoParagraphs(blocks);
      final detectedLanguages = _collectLanguages(recognizedText.blocks);

      // 清理预处理临时文件
      if (processedPath != imagePath) {
        try {
          await File(processedPath).delete();
        } catch (_) {}
      }

      stopwatch.stop();

      final result = OcrResult(
        fullText: recognizedText.text,
        blocks: blocks,
        paragraphs: paragraphs,
        averageConfidence: _calculateConfidence(blocks),
        detectedLanguages: detectedLanguages,
        processingTime: stopwatch.elapsed,
      );

      // 存入缓存
      _addToCache(cacheKey, result);

      onProgress?.call('识别完成', 1.0);
      return result;
    } catch (e) {
      stopwatch.stop();
      throw OcrException('OCR 识别失败: $e');
    }
  }

  /// 批量 OCR - 多张图片
  Future<List<OcrResult>> recognizeMultiple(
    List<String> imagePaths, {
    OcrLanguage language = OcrLanguage.chinese,
    OcrPreprocessMode preprocess = OcrPreprocessMode.auto,
    void Function(int current, int total, String status)? onProgress,
  }) async {
    final results = <OcrResult>[];
    for (int i = 0; i < imagePaths.length; i++) {
      onProgress?.call(i + 1, imagePaths.length, '正在识别第 ${i + 1}/${imagePaths.length} 页');
      final result = await recognizeText(
        imagePaths[i],
        language: language,
        preprocess: preprocess,
      );
      results.add(result);
    }
    return results;
  }

  // ─── 图片预处理 ───

  Future<String> _preprocessImage(
    String imagePath,
    OcrPreprocessMode mode,
  ) async {
    final bytes = await File(imagePath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return imagePath;

    img.Image processed;

    switch (mode) {
      case OcrPreprocessMode.none:
        return imagePath;

      case OcrPreprocessMode.auto:
        // 自动预处理: 灰度 + 对比度增强 + 轻度降噪
        processed = img.grayscale(image);
        processed = img.adjustColor(processed, contrast: 1.4, brightness: 5);
        processed = img.gaussianBlur(processed, radius: 1);
        break;

      case OcrPreprocessMode.grayscale:
        processed = img.grayscale(image);
        break;

      case OcrPreprocessMode.highContrast:
        processed = img.grayscale(image);
        processed = img.adjustColor(processed, contrast: 1.8, brightness: 10);
        break;

      case OcrPreprocessMode.binarize:
        processed = img.grayscale(image);
        processed = img.adjustColor(processed, contrast: 2.0);
        // 简单二值化: 阈值 128
        final data = processed.getBytes();
        for (int i = 0; i < data.length; i += 4) {
          final val = data[i] > 128 ? 255 : 0;
          data[i] = val;
          data[i + 1] = val;
          data[i + 2] = val;
        }
        break;
    }

    final ext = imagePath.split('.').last;
    final processedPath =
        '${imagePath.substring(0, imagePath.length - ext.length - 1)}_ocr_prep.jpg';
    await File(processedPath).writeAsBytes(
      Uint8List.fromList(img.encodeJpg(processed, quality: 95)),
    );
    return processedPath;
  }

  // ─── 结果解析 ───

  List<OcrBlock> _parseBlocks(List<TextBlock> mlBlocks) {
    return mlBlocks.map((block) {
      final lines = block.lines.map((line) {
        final words = line.elements.map((element) {
          return OcrWord(
            text: element.text,
            confidence: element.confidence ?? 0.0,
            boundingBox: _convertRect(element.boundingBox),
          );
        }).toList();

        // 计算行的平均置信度
        final wordConfidences = words.map((w) => w.confidence).where((c) => c > 0);
        final lineConfidence = wordConfidences.isEmpty
            ? 0.0
            : wordConfidences.reduce((a, b) => a + b) / wordConfidences.length;

        return OcrLine(
          text: line.text,
          confidence: lineConfidence,
          words: words,
          boundingBox: _convertRect(line.boundingBox),
        );
      }).toList();

      // 计算 block 的平均置信度
      final lineConfidences = lines.map((l) => l.confidence).where((c) => c > 0);
      final blockConfidence = lineConfidences.isEmpty
          ? 0.0
          : lineConfidences.reduce((a, b) => a + b) / lineConfidences.length;

      return OcrBlock(
        text: block.text,
        confidence: blockConfidence,
        lines: lines,
        detectedLanguages: _extractBlockLanguages(block),
        boundingBox: _convertRect(block.boundingBox),
      );
    }).toList();
  }

  List<OcrParagraph> _groupIntoParagraphs(List<OcrBlock> blocks) {
    if (blocks.isEmpty) return [];

    final paragraphs = <OcrParagraph>[];
    var currentBlocks = <OcrBlock>[blocks[0]];

    for (int i = 1; i < blocks.length; i++) {
      final prevBox = blocks[i - 1].boundingBox;
      final currBox = blocks[i].boundingBox;

      // 如果两个 block 之间垂直间距较大，认为是新段落
      final gap = (currBox != null && prevBox != null)
          ? currBox.top - prevBox.bottom
          : 0.0;
      final lineHeight = prevBox?.height ?? 20.0;

      if (gap > lineHeight * 0.8) {
        paragraphs.add(_createParagraph(currentBlocks));
        currentBlocks = <OcrBlock>[blocks[i]];
      } else {
        currentBlocks.add(blocks[i]);
      }
    }

    if (currentBlocks.isNotEmpty) {
      paragraphs.add(_createParagraph(currentBlocks));
    }

    return paragraphs;
  }

  OcrParagraph _createParagraph(List<OcrBlock> blocks) {
    final text = blocks.map((b) => b.text).join('\n');
    final avgConf = blocks.isEmpty
        ? 0.0
        : blocks.map((b) => b.confidence).reduce((a, b) => a + b) /
            blocks.length;
    return OcrParagraph(text: text, blocks: blocks, averageConfidence: avgConf);
  }

  Map<String, double> _collectLanguages(List<TextBlock> mlBlocks) {
    final langCount = <String, int>{};
    for (final block in mlBlocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          // recognizedLanguages 是 List<String>
          for (final lang in element.recognizedLanguages) {
            final code = lang.isEmpty ? 'unknown' : lang;
            langCount[code] = (langCount[code] ?? 0) + 1;
          }
        }
      }
    }
    final total = langCount.values.fold(0, (a, b) => a + b);
    if (total == 0) return {};
    return langCount.map((k, v) => MapEntry(k, v / total));
  }

  Map<String, double> _extractBlockLanguages(TextBlock block) {
    final langs = <String, int>{};
    for (final line in block.lines) {
      for (final element in line.elements) {
        // recognizedLanguages 是 List<String>
        for (final lang in element.recognizedLanguages) {
          final code = lang.isEmpty ? 'unknown' : lang;
          langs[code] = (langs[code] ?? 0) + 1;
        }
      }
    }
    final total = langs.values.fold(0, (a, b) => a + b);
    if (total == 0) return {};
    return langs.map((k, v) => MapEntry(k, v / total));
  }

  double _calculateConfidence(List<OcrBlock> blocks) {
    if (blocks.isEmpty) return 0.0;
    final total = blocks.map((b) => b.confidence).reduce((a, b) => a + b);
    return total / blocks.length;
  }

  Rect? _convertRect(dynamic rawRect) {
    if (rawRect == null) return null;
    return Rect(
      left: rawRect.left.toDouble(),
      top: rawRect.top.toDouble(),
      right: rawRect.right.toDouble(),
      bottom: rawRect.bottom.toDouble(),
    );
  }

  // ─── 缓存管理 ───

  void _addToCache(String key, OcrResult result) {
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = result;
  }

  /// 清除缓存
  void clearCache() => _cache.clear();

  /// 关闭服务
  Future<void> close() async {
    await _currentRecognizer?.close();
    _currentRecognizer = null;
    _cache.clear();
  }
}

/// OCR 异常
class OcrException implements Exception {
  final String message;
  const OcrException(this.message);
  @override
  String toString() => message;
}
