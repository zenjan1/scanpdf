import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scanpdf/core/theme/app_colors.dart';
import 'package:scanpdf/core/services/ocr_service.dart';
import 'package:scanpdf/shared/widgets/app_button.dart';

/// OCR screen for extracting and editing text from scanned documents
class OcrScreen extends StatefulWidget {
  final String imagePath;

  const OcrScreen({super.key, required this.imagePath});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final OcrService _ocrService = OcrService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isProcessing = false;
  double _confidence = 0.0;
  String _selectedLanguage = 'zh';

  final List<_LanguageOption> _languages = [
    _LanguageOption('zh', '中文'),
    _LanguageOption('en', 'English'),
    _LanguageOption('ja', '日本語'),
    _LanguageOption('ko', '한국어'),
  ];

  @override
  void initState() {
    super.initState();
    _performOcr();
  }

  Future<void> _performOcr() async {
    setState(() {
      _isProcessing = true;
      _confidence = 0.0;
    });

    try {
      final blocks = await _ocrService.extractTextWithBlocks(widget.imagePath);

      final fullText = blocks.map((b) => b.text).join('\n\n');
      final avgConfidence = blocks.isEmpty
          ? 0.0
          : blocks.map((b) => b.confidence).reduce((a, b) => a + b) /
              blocks.length;

      setState(() {
        _textController.text = fullText;
        _confidence = avgConfidence;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OCR 识别失败: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _ocrService.close();
    super.dispose();
  }

  void _shareText(String text) async {
    try {
      // Save text to a temp file for sharing
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ocr_text_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(text);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: text,
        subject: 'OCR 识别结果',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  Future<void> _saveText(String text) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final saveDir = Directory('${dir.path}/ocr_texts');
      if (!await saveDir.exists()) {
        await saveDir.create(recursive: true);
      }
      final fileName = 'ocr_${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File('${saveDir.path}/$fileName');
      await file.writeAsString(text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已保存到: $fileName')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文字识别'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (value) {
              setState(() => _selectedLanguage = value);
              _performOcr();
            },
            itemBuilder: (context) => _languages
                .map((lang) => PopupMenuItem(
                      value: lang.code,
                      child: Row(
                        children: [
                          Radio<String>(
                            value: lang.code,
                            groupValue: _selectedLanguage,
                            onChanged: null,
                          ),
                          const SizedBox(width: 8),
                          Text(lang.name),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Image Preview
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Image.file(
              File(widget.imagePath),
              fit: BoxFit.contain,
            ),
          ),

          // Confidence Indicator
          if (_confidence > 0 && !_isProcessing)
            Container(
              padding: const EdgeInsets.all(12),
              color: AppColors.success.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '识别置信度: ${(_confidence * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          // Text Editor
          Expanded(
            child: _isProcessing
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          '正在识别文字...',
                          style: TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: '识别的文字将显示在这里...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
          ),

          // Action Buttons
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 8,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: AppButton(
                      text: '复制',
                      icon: Icons.copy,
                      isOutlined: true,
                      onPressed: _textController.text.isEmpty
                          ? null
                          : () {
                              Clipboard.setData(
                                ClipboardData(text: _textController.text),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('已复制到剪贴板')),
                              );
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: '分享',
                      icon: Icons.share,
                      isOutlined: true,
                      onPressed: _textController.text.isEmpty
                          ? null
                          : () => _shareText(_textController.text),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      text: '保存',
                      icon: Icons.save,
                      onPressed: _textController.text.isEmpty
                          ? null
                          : () => _saveText(_textController.text),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption {
  final String code;
  final String name;

  _LanguageOption(this.code, this.name);
}
