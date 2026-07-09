import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scanpdf/core/theme/app_colors.dart';
import 'package:scanpdf/core/services/ocr_service.dart';
import 'package:scanpdf/shared/widgets/app_button.dart';

/// OCR 识别屏幕 - 支持多语言、预处理、实时进度
class OcrScreen extends StatefulWidget {
  final String imagePath;
  final OcrLanguage? initialLanguage;

  const OcrScreen({
    super.key,
    required this.imagePath,
    this.initialLanguage,
  });

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  final OcrService _ocrService = OcrService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isProcessing = false;
  double _progress = 0.0;
  String _progressStatus = '';
  OcrResult? _ocrResult;
  OcrLanguage _selectedLanguage = OcrLanguage.chinese;
  OcrPreprocessMode _preprocessMode = OcrPreprocessMode.auto;
  bool _showImagePreview = true;
  bool _showSearch = false;
  List<int> _searchMatches = [];
  int _currentMatchIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialLanguage != null) {
      _selectedLanguage = widget.initialLanguage!;
    }
    _performOcr();
  }

  Future<void> _performOcr() async {
    setState(() {
      _isProcessing = true;
      _progress = 0.0;
      _progressStatus = '准备中';
      _ocrResult = null;
      _searchMatches = [];
    });

    try {
      final result = await _ocrService.recognizeText(
        widget.imagePath,
        language: _selectedLanguage,
        preprocess: _preprocessMode,
        onProgress: (status, progress) {
          if (mounted) {
            setState(() {
              _progressStatus = status;
              _progress = progress;
            });
          }
        },
      );

      setState(() {
        _textController.text = result.fullText;
        _ocrResult = result;
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
    _searchController.dispose();
    _scrollController.dispose();
    _ocrService.close();
    super.dispose();
  }

  void _shareText(String text) async {
    try {
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

  void _searchText(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchMatches = [];
        _currentMatchIndex = 0;
      });
      return;
    }

    final text = _textController.text;
    final matches = <int>[];
    int startIndex = 0;

    while (true) {
      final index = text.indexOf(query, startIndex);
      if (index == -1) break;
      matches.add(index);
      startIndex = index + 1;
    }

    setState(() {
      _searchMatches = matches;
      _currentMatchIndex = matches.isEmpty ? 0 : 1;
    });
  }

  void _navigateSearch(bool forward) {
    if (_searchMatches.isEmpty) return;

    setState(() {
      if (forward) {
        _currentMatchIndex = (_currentMatchIndex + 1) % _searchMatches.length;
      } else {
        _currentMatchIndex = (_currentMatchIndex - 1 + _searchMatches.length) % _searchMatches.length;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('文字识别'),
        actions: [
          // 搜索按钮
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                  _searchMatches = [];
                }
              });
            },
          ),
          // 语言选择
          PopupMenuButton<OcrLanguage>(
            icon: const Icon(Icons.language),
            onSelected: (language) {
              setState(() => _selectedLanguage = language);
              _performOcr();
            },
            itemBuilder: (context) => OcrLanguage.values
                .map((lang) => PopupMenuItem(
                      value: lang,
                      child: Row(
                        children: [
                          Radio<OcrLanguage>(
                            value: lang,
                            groupValue: _selectedLanguage,
                            onChanged: null,
                          ),
                          const SizedBox(width: 8),
                          Text(lang.displayName),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
        bottom: _showSearch
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            hintText: '搜索文字...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            isDense: true,
                          ),
                          onChanged: _searchText,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (_searchMatches.isNotEmpty)
                        Text(
                          '$_currentMatchIndex/${_searchMatches.length}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      IconButton(
                        icon: const Icon(Icons.arrow_upward, size: 20),
                        onPressed: () => _navigateSearch(false),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward, size: 20),
                        onPressed: () => _navigateSearch(true),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: Column(
        children: [
          // 图片预览（可折叠）
          if (_showImagePreview)
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Stack(
                children: [
                  Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      color: Colors.black54,
                      onPressed: () {
                        setState(() => _showImagePreview = false);
                      },
                    ),
                  ),
                ],
              ),
            ),

          // 识别结果信息栏
          if (_ocrResult != null && !_isProcessing) _buildResultInfoBar(),

          // 主内容区域
          Expanded(
            child: _isProcessing
                ? _buildProgressView()
                : _buildTextEditor(),
          ),

          // 底部操作栏
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
                  // 重新识别按钮
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: _isProcessing ? null : _performOcr,
                    tooltip: '重新识别',
                  ),
                  const SizedBox(width: 8),
                  // 预处理模式选择
                  PopupMenuButton<OcrPreprocessMode>(
                    icon: const Icon(Icons.tune),
                    onSelected: (mode) {
                      setState(() => _preprocessMode = mode);
                      _performOcr();
                    },
                    itemBuilder: (context) => OcrPreprocessMode.values
                        .map((mode) => PopupMenuItem(
                              value: mode,
                              child: Text(mode.label),
                            ))
                        .toList(),
                    tooltip: '预处理模式',
                  ),
                  const SizedBox(width: 8),
                  // 图片预览切换
                  IconButton(
                    icon: Icon(_showImagePreview ? Icons.image : Icons.image_outlined),
                    onPressed: () {
                      setState(() => _showImagePreview = !_showImagePreview);
                    },
                    tooltip: _showImagePreview ? '隐藏图片' : '显示图片',
                  ),
                  const Spacer(),
                  // 操作按钮
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
                  const SizedBox(width: 8),
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
                  const SizedBox(width: 8),
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

  Widget _buildResultInfoBar() {
    final result = _ocrResult!;
    final confidenceColor = result.averageConfidence > 0.8
        ? AppColors.success
        : result.averageConfidence > 0.5
            ? Colors.orange
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: confidenceColor.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: confidenceColor.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: confidenceColor,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            '置信度: ${(result.averageConfidence * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              color: confidenceColor,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 16),
          Icon(Icons.text_fields, color: confidenceColor, size: 16),
          const SizedBox(width: 4),
          Text(
            '${result.totalCharacters}字',
            style: TextStyle(color: confidenceColor, fontSize: 12),
          ),
          const SizedBox(width: 12),
          Icon(Icons.article, color: confidenceColor, size: 16),
          const SizedBox(width: 4),
          Text(
            '${result.totalWords}词',
            style: TextStyle(color: confidenceColor, fontSize: 12),
          ),
          const SizedBox(width: 12),
          Icon(Icons.timer, color: confidenceColor, size: 16),
          const SizedBox(width: 4),
          Text(
            '${(result.processingTime.inMilliseconds / 1000).toStringAsFixed(1)}s',
            style: TextStyle(color: confidenceColor, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(
            _progressStatus,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(_progress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextEditor() {
    return Padding(
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
          contentPadding: const EdgeInsets.all(12),
        ),
        style: const TextStyle(fontSize: 16, height: 1.5),
        onChanged: (value) {
          if (_showSearch && _searchController.text.isNotEmpty) {
            _searchText(_searchController.text);
          }
        },
      ),
    );
  }
}
