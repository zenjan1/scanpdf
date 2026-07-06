import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'dart:io';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(
    script: TextRecognitionScript.chinese,
  );

  Future<String> extractText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }

  Future<List<OcrBlock>> extractTextWithBlocks(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.blocks.map((block) {
        return OcrBlock(
          text: block.text,
          confidence: block.recognizedLanguages.isNotEmpty ? 0.9 : 0.0,
          boundingBox: block.boundingBox,
        );
      }).toList();
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }

  Future<void> close() async {
    await _textRecognizer.close();
  }
}

class OcrBlock {
  final String text;
  final double confidence;
  final dynamic boundingBox;

  OcrBlock({
    required this.text,
    required this.confidence,
    this.boundingBox,
  });
}
