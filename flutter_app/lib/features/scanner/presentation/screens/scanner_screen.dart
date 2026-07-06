import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scanpdf/core/theme/app_colors.dart';
import 'package:scanpdf/core/services/image_processing_service.dart';
import 'package:scanpdf/core/services/pdf_service.dart';
import 'package:scanpdf/core/services/ocr_service.dart';
import 'package:scanpdf/core/services/storage_service.dart';
import 'package:scanpdf/shared/widgets/app_button.dart';

/// Scanner screen for edge detection, cropping, and image enhancement
/// Inspired by CamScanner's scan flow: capture → edge detect → crop → enhance → export
class ScannerScreen extends StatefulWidget {
  final Map<String, dynamic>? params;

  const ScannerScreen({super.key, this.params});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with SingleTickerProviderStateMixin {
  final ImageProcessingService _imageProcessor = ImageProcessingService();
  final PdfService _pdfService = PdfService();
  final OcrService _ocrService = OcrService();
  final StorageService _storageService = StorageService();

  late TabController _tabController;
  List<String> _imagePaths = [];
  int _currentImageIndex = 0;
  bool _isProcessing = false;
  String _currentFilter = 'original';
  bool _ocrEnabled = false;

  final List<_FilterOption> _filters = [
    _FilterOption('original', '原图', Icons.image),
    _FilterOption('grayscale', '灰度', Icons.exposure),
    _FilterOption('enhance', '增强', Icons.auto_fix_high),
    _FilterOption('bw', '黑白', Icons.contrast),
    _FilterOption('magic', '魔法', Icons.auto_awesome),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Parse incoming image paths
    if (widget.params != null) {
      if (widget.params!.containsKey('imagePaths')) {
        _imagePaths = List<String>.from(widget.params!['imagePaths']);
      } else if (widget.params!.containsKey('imagePath')) {
        _imagePaths = [widget.params!['imagePath'] as String];
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _applyFilter(String filterName, String imagePath) async {
    setState(() {
      _isProcessing = true;
      _currentFilter = filterName;
    });

    try {
      final file = File(imagePath);
      final imageData = await file.readAsBytes();
      Uint8List result;

      switch (filterName) {
        case 'grayscale':
          result = await _imageProcessor.convertToGrayscale(imageData);
          break;
        case 'enhance':
          result = await _imageProcessor.enhanceImage(imageData);
          break;
        case 'bw':
          result = await _imageProcessor.convertToGrayscale(imageData);
          result = await _imageProcessor.enhanceImage(result);
          break;
        case 'magic':
          result = await _imageProcessor.autoCropDocument(imageData);
          result = await _imageProcessor.enhanceImage(result);
          break;
        default:
          result = imageData;
      }

      final processedPath = '${file.path}_processed_$filterName.jpg';
      await File(processedPath).writeAsBytes(result);

      setState(() {
        _imagePaths[_currentImageIndex] = processedPath;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('处理失败: $e')),
        );
      }
    }
  }

  Future<void> _shareDocument() async {
    if (_imagePaths.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有可分享的文档')),
      );
      return;
    }

    try {
      // Share images directly or create PDF first
      if (_imagePaths.length == 1) {
        await Share.shareXFiles(
          [XFile(_imagePaths[0])],
          text: '分享的扫描文档',
        );
      } else {
        // For multiple images, share as PDF
        final docId = await _storageService.generateDocumentId();
        final pdfPath = await _storageService.getDocumentPath(docId);
        List<String> ocrTexts = [];

        if (_ocrEnabled) {
          for (final path in _imagePaths) {
            final text = await _ocrService.extractText(path);
            ocrTexts.add(text);
          }
        }

        final pdfBytes = _ocrEnabled
            ? await _pdfService.createSearchablePdf(_imagePaths, ocrTexts)
            : await _pdfService.createPdfFromImages(_imagePaths);

        await File(pdfPath).writeAsBytes(pdfBytes);
        await Share.shareXFiles(
          [XFile(pdfPath)],
          text: '分享的扫描文档',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败: $e')),
        );
      }
    }
  }

  Future<void> _saveAsPdf() async {
    setState(() => _isProcessing = true);

    try {
      final docId = await _storageService.generateDocumentId();
      final pdfPath = await _storageService.getDocumentPath(docId);
      List<String> ocrTexts = [];

      // Perform OCR if enabled
      if (_ocrEnabled) {
        for (final path in _imagePaths) {
          final text = await _ocrService.extractText(path);
          ocrTexts.add(text);
        }
      }

      // Generate PDF
      final pdfBytes = _ocrEnabled
          ? await _pdfService.createSearchablePdf(_imagePaths, ocrTexts)
          : await _pdfService.createPdfFromImages(_imagePaths);

      await File(pdfPath).writeAsBytes(pdfBytes);

      // Save thumbnail for first page
      if (_imagePaths.isNotEmpty) {
        final thumbData = await _imageProcessor.createThumbnail(
          await File(_imagePaths[0]).readAsBytes(),
        );
        final thumbId = await _storageService.generateImageId();
        await _storageService.saveImage(thumbId, thumbData);
      }

      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF 保存成功！')),
        );
        context.pop();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
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
        title: const Text('编辑扫描'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareDocument,
          ),
        ],
      ),
      body: Column(
        children: [
          // Image Preview
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                // Main Image
                if (_imagePaths.isNotEmpty)
                  GestureDetector(
                    onDoubleTap: () => _applyFilter('magic', _imagePaths[_currentImageIndex]),
                    child: Image.file(
                      File(_imagePaths[_currentImageIndex]),
                      fit: BoxFit.contain,
                      width: double.infinity,
                    ),
                  ),

                // Processing Overlay
                if (_isProcessing)
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            '处理中...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Page Indicator
                if (_imagePaths.length > 1)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentImageIndex + 1}/${_imagePaths.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Controls
          Container(
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
              child: Column(
                children: [
                  // Tab Bar
                  TabBar(
                    controller: _tabController,
                    tabs: const [
                      Tab(text: '裁剪', icon: Icon(Icons.crop)),
                      Tab(text: '滤镜', icon: Icon(Icons.filter)),
                      Tab(text: '更多', icon: Icon(Icons.more_horiz)),
                    ],
                    labelColor: AppColors.primary,
                  ),

                  // Tab Content
                  SizedBox(
                    height: 160,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Crop Tab
                        _buildCropTab(),
                        // Filter Tab
                        _buildFilterTab(),
                        // More Tab
                        _buildMoreTab(),
                      ],
                    ),
                  ),

                  // Action Buttons
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            text: '添加页面',
                            icon: Icons.add_photo_alternate,
                            isOutlined: true,
                            onPressed: () => context.push('/camera'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: AppButton(
                            text: _ocrEnabled ? '保存可搜索PDF' : '保存PDF',
                            icon: Icons.save,
                            isLoading: _isProcessing,
                            onPressed: _saveAsPdf,
                          ),
                        ),
                      ],
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

  Widget _buildCropTab() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '拖动边角进行裁剪',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCropButton('自动检测', Icons.auto_fix_high, () {
              _applyFilter('magic', _imagePaths[_currentImageIndex]);
            }),
            const SizedBox(width: 16),
            _buildCropButton('1:1', Icons.square, () {}),
            const SizedBox(width: 16),
            _buildCropButton('A4', Icons.aspect_ratio, () {}),
            const SizedBox(width: 16),
            _buildCropButton('自由', Icons.crop_free, () {}),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterTab() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _currentFilter == filter.name;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _applyFilter(
                filter.name,
                _imagePaths[_currentImageIndex],
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: Icon(
                      filter.icon,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    filter.label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade600,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMoreTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMoreButton(Icons.rotate_left, '左旋转', () {}),
          _buildMoreButton(Icons.rotate_right, '右旋转', () {}),
          _buildMoreButton(
            Icons.text_fields,
            _ocrEnabled ? 'OCR已开' : 'OCR识别',
            () {
              setState(() => _ocrEnabled = !_ocrEnabled);
            },
          ),
          _buildMoreButton(Icons.delete_sweep, '删除本页', () {
            if (_imagePaths.length > 1) {
              setState(() {
                _imagePaths.removeAt(_currentImageIndex);
                if (_currentImageIndex >= _imagePaths.length) {
                  _currentImageIndex = _imagePaths.length - 1;
                }
              });
            }
          }),
        ],
      ),
    );
  }

  Widget _buildCropButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMoreButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

class _FilterOption {
  final String name;
  final String label;
  final IconData icon;

  _FilterOption(this.name, this.label, this.icon);
}
