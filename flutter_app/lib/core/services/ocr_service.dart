import 'dart:io';
import 'dart:typed_data';
import 'package:tesseract_ocr/tesseract_ocr.dart';
import 'package:tesseract_ocr/ocr_engine_config.dart';
import 'package:image/image.dart' as img;

/// OCR 语言选项
enum OcrLanguage {
  chinese('chi_sim', '中文'),
  english('eng', 'English'),
  japanese('jpn', '日本語'),
  korean('kor', '한국어');

  final String code;
  final String displayName;
  const OcrLanguage(this.code, this.displayName);

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

/// OCR 服务 - 基于 Tesseract 开源引擎，支持多语言、预处理、缓存
class OcrService {
  final OcrLanguage _currentLanguage = OcrLanguage.chinese;

  /// 结果缓存: imagePath+language -> OcrResult
  final Map<String, OcrResult> _cache = {};
  static const int _maxCacheSize = 20;

  /// 当前语言
  OcrLanguage get currentLanguage => _currentLanguage;

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

      // Tesseract OCR 识别
      final config = OCRConfig(language: language.code);
      final text = await TesseractOcr.extractText(
        processedPath,
        config: config,
      );

      onProgress?.call('解析识别结果', 0.8);

      // 将纯文本解析为结构化数据
      final blocks = _textToBlocks(text);
      final paragraphs = _groupIntoParagraphs(blocks);

      // 清理预处理临时文件
      if (processedPath != imagePath) {
        try {
          await File(processedPath).delete();
        } catch (_) {}
      }

      stopwatch.stop();

      final result = OcrResult(
        fullText: text,
        blocks: blocks,
        paragraphs: paragraphs,
        averageConfidence: 0.8,
        detectedLanguages: {language.code: 1.0},
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

  /// 置信度过滤 - Tesseract 不提供逐字置信度，直接返回完整结果
  Future<OcrResult> recognizeTextFiltered(
    String imagePath, {
    OcrLanguage language = OcrLanguage.chinese,
    double confidenceThreshold = 0.7,
    OcrPreprocessMode preprocess = OcrPreprocessMode.auto,
  }) async {
    return recognizeText(
      imagePath,
      language: language,
      preprocess: preprocess,
    );
  }

  /// 表格识别 - 尝试检测并结构化表格数据
  Future<TableResult?> recognizeTable(
    String imagePath, {
    OcrLanguage language = OcrLanguage.chinese,
  }) async {
    final result = await recognizeText(imagePath, language: language);

    final tableBlocks = _detectTablePattern(result.blocks);
    if (tableBlocks == null) return null;

    return TableResult(
      rows: tableBlocks.rows,
      columns: tableBlocks.columns,
      cells: tableBlocks.cells,
      confidence: tableBlocks.confidence,
    );
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

  // ─── 文本结构化 ───

  /// 将 Tesseract 返回的纯文本解析为 OcrBlock 结构
  List<OcrBlock> _textToBlocks(String text) {
    if (text.trim().isEmpty) return [];

    final blocks = <OcrBlock>[];
    final lines = text.split('\n');
    var currentBlockLines = <String>[];

    for (final line in lines) {
      if (line.trim().isEmpty) {
        if (currentBlockLines.isNotEmpty) {
          blocks.add(_createBlock(currentBlockLines));
          currentBlockLines = [];
        }
      } else {
        currentBlockLines.add(line);
      }
    }
    if (currentBlockLines.isNotEmpty) {
      blocks.add(_createBlock(currentBlockLines));
    }

    return blocks;
  }

  OcrBlock _createBlock(List<String> lines) {
    final ocrLines = lines.map((lineText) {
      final words = lineText.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).map((word) {
        return OcrWord(text: word, confidence: 0.8);
      }).toList();

      return OcrLine(
        text: lineText,
        confidence: 0.8,
        words: words,
      );
    }).toList();

    return OcrBlock(
      text: lines.join('\n'),
      confidence: 0.8,
      lines: ocrLines,
      detectedLanguages: {},
    );
  }

  /// 检测表格模式
  _TablePattern? _detectTablePattern(List<OcrBlock> blocks) {
    if (blocks.length < 4) return null;

    // 按行数分组，检查是否有规则的列分隔（如 tab 或多空格）
    final rows = <List<String>>[];
    for (final block in blocks) {
      for (final line in block.lines) {
        // 尝试用 tab 或 2+ 空格分割
        final cells = line.text.split(RegExp(r'\t|  +')).where((s) => s.trim().isNotEmpty).toList();
        if (cells.length >= 2) {
          rows.add(cells);
        }
      }
    }

    if (rows.length < 2) return null;

    final columnCounts = rows.map((row) => row.length).toList();
    final avgColumns = columnCounts.reduce((a, b) => a + b) / columnCounts.length;

    // 列数一致性检查
    final consistent = columnCounts.where((c) => (c - avgColumns).abs() <= 1).length;
    if (consistent < rows.length * 0.6) return null;

    final maxColumns = columnCounts.reduce((a, b) => a > b ? a : b);
    final cells = <List<String?>>[];
    for (final row in rows) {
      final rowCells = <String?>[];
      for (int i = 0; i < maxColumns; i++) {
        rowCells.add(i < row.length ? row[i].trim() : null);
      }
      cells.add(rowCells);
    }

    return _TablePattern(
      rows: rows.length,
      columns: maxColumns,
      cells: cells,
      confidence: 0.7,
    );
  }

  List<OcrParagraph> _groupIntoParagraphs(List<OcrBlock> blocks) {
    if (blocks.isEmpty) return [];
    return blocks.map((block) {
      return OcrParagraph(
        text: block.text,
        blocks: [block],
        averageConfidence: block.confidence,
      );
    }).toList();
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
    _cache.clear();
  }
}

/// 表格识别结果
class TableResult {
  final int rows;
  final int columns;
  final List<List<String?>> cells;
  final double confidence;

  const TableResult({
    required this.rows,
    required this.columns,
    required this.cells,
    required this.confidence,
  });

  String? getCell(int row, int col) {
    if (row < 0 || row >= rows || col < 0 || col >= columns) {
      return null;
    }
    return cells[row][col];
  }

  List<String?> getRow(int rowIndex) {
    if (rowIndex < 0 || rowIndex >= rows) return [];
    return cells[rowIndex];
  }

  List<String?> getColumn(int colIndex) {
    if (colIndex < 0 || colIndex >= columns) return [];
    return cells.map((row) => row[colIndex]).toList();
  }

  String toCsv({String separator = ','}) {
    return cells
        .map((row) => row.map((cell) => cell ?? '').join(separator))
        .join('\n');
  }

  List<Map<String, String>> toJson() {
    if (rows < 2) return [];

    final headers = cells[0].map((h) => h ?? 'col_${cells[0].indexOf(h)}').toList();

    return cells.skip(1).map((row) {
      final map = <String, String>{};
      for (int i = 0; i < headers.length; i++) {
        map[headers[i]] = row[i] ?? '';
      }
      return map;
    }).toList();
  }
}

/// 表格模式（内部使用）
class _TablePattern {
  final int rows;
  final int columns;
  final List<List<String?>> cells;
  final double confidence;

  const _TablePattern({
    required this.rows,
    required this.columns,
    required this.cells,
    required this.confidence,
  });
}

/// OCR 异常
class OcrException implements Exception {
  final String message;
  const OcrException(this.message);
  @override
  String toString() => message;
}
