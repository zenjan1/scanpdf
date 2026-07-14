import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:scanpdf/core/theme/app_colors.dart';
import 'package:scanpdf/core/services/database_service.dart';
import 'package:scanpdf/core/services/pdf_service.dart';
import 'package:scanpdf/core/services/ocr_service.dart';
import 'package:scanpdf/core/services/service_locator.dart';
import 'package:scanpdf/features/document/domain/entities/document.dart';
import 'package:scanpdf/features/document/presentation/bloc/document_bloc.dart';

/// 文档预览/查看器页面
///
/// 支持 PDF 和图片查看，翻页，分享、打印、OCR 识别、删除。
/// 路由参数：document id
class DocumentViewerScreen extends StatefulWidget {
  final String documentId;

  const DocumentViewerScreen({
    super.key,
    required this.documentId,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  final DatabaseService _databaseService = sl<DatabaseService>();
  final PdfService _pdfService = sl<PdfService>();
  final OcrService _ocrService = sl<OcrService>();

  Document? _document;
  bool _isLoading = true;
  String? _errorMessage;

  // 当前页码（从 0 开始）
  int _currentPage = 0;
  int _totalPages = 1;

  // 文档类型
  _DocumentType _documentType = _DocumentType.pdf;

  // 图片列表（当文档为图片类型时）
  List<String> _imagePaths = [];

  // PDF 数据
  Uint8List? _pdfData;

  // PDF 页面图片缓存（rastered）
  final Map<int, Uint8List> _pdfPageImages = {};

  // OCR 相关
  bool _isOcrProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  @override
  void dispose() {
    _ocrService.close();
    super.dispose();
  }

  Future<void> _loadDocument() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final db = await _databaseService.database;
      final maps = await db.query(
        'documents',
        where: 'id = ?',
        whereArgs: [widget.documentId],
      );

      if (maps.isEmpty) {
        setState(() {
          _errorMessage = '文档不存在';
          _isLoading = false;
        });
        return;
      }

      final document = Document.fromMap(maps.first);
      final filePath = document.filePath;
      final file = File(filePath);

      if (!await file.exists()) {
        setState(() {
          _errorMessage = '文件不存在: $filePath';
          _isLoading = false;
        });
        return;
      }

      // 判断文档类型
      final ext = filePath.toLowerCase().split('.').last;
      if (ext == 'pdf') {
        _documentType = _DocumentType.pdf;
        _pdfData = await file.readAsBytes();
        _totalPages = document.pageCount;
        // 预光栅化第一页
        await _rasterizePdfPage(0);
      } else if (['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext)) {
        _documentType = _DocumentType.image;
        _imagePaths = [filePath];
        _totalPages = 1;
      } else {
        // 尝试作为 PDF 处理
        _documentType = _DocumentType.pdf;
        _pdfData = await file.readAsBytes();
        _totalPages = document.pageCount;
        await _rasterizePdfPage(0);
      }

      setState(() {
        _document = document;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载文档失败: $e';
        _isLoading = false;
      });
    }
  }

  /// 光栅化 PDF 指定页面为 PNG 图片
  Future<void> _rasterizePdfPage(int pageIndex) async {
    if (_pdfData == null) return;
    if (_pdfPageImages.containsKey(pageIndex)) return;

    try {
      final pages = await Printing.raster(
        _pdfData!,
        dpi: 200,
        pages: [pageIndex],
      ).toList();

      if (pages.isNotEmpty) {
        final pngData = await pages.first.toPng();
        _pdfPageImages[pageIndex] = pngData;
      }
    } catch (e) {
      debugPrint('Failed to rasterize PDF page $pageIndex: $e');
    }
  }

  void _goToPage(int page) {
    if (page < 0 || page >= _totalPages) return;
    setState(() {
      _currentPage = page;
    });
    // 预光栅化当前页和相邻页
    _rasterizePdfPage(page);
    if (page + 1 < _totalPages) _rasterizePdfPage(page + 1);
    if (page - 1 >= 0) _rasterizePdfPage(page - 1);
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() => _currentPage++);
    }
  }

  Future<void> _shareDocument() async {
    if (_document == null) return;

    try {
      final file = File(_document!.filePath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(_document!.filePath)],
          text: '分享文档: ${_document!.title}',
        );
      } else {
        _showSnackBar('文件不存在', isError: true);
      }
    } catch (e) {
      _showSnackBar('分享失败: $e', isError: true);
    }
  }

  Future<void> _printDocument() async {
    if (_document == null) return;

    try {
      if (_documentType == _DocumentType.pdf && _pdfData != null) {
        await _pdfService.printPdf(_pdfData!, _document!.title);
      } else if (_documentType == _DocumentType.image && _imagePaths.isNotEmpty) {
        // 将图片转为 PDF 后打印
        final pdfData = await _pdfService.createPdfFromImages(_imagePaths);
        await _pdfService.printPdf(pdfData, _document!.title);
      } else {
        _showSnackBar('无法打印：文件不可用', isError: true);
      }
    } catch (e) {
      _showSnackBar('打印失败: $e', isError: true);
    }
  }

  Future<void> _performOcr() async {
    if (_document == null) return;

    setState(() => _isOcrProcessing = true);

    try {
      String imagePath;

      if (_documentType == _DocumentType.image && _imagePaths.isNotEmpty) {
        imagePath = _imagePaths[_currentPage];
      } else if (_documentType == _DocumentType.pdf && _pdfData != null) {
        // 将当前 PDF 页面转为图片进行 OCR
        final tempDir = await getTemporaryDirectory();
        final pages = await Printing.raster(
          _pdfData!,
          dpi: 300,
          pages: [_currentPage],
        ).toList();

        if (pages.isEmpty) {
          _showSnackBar('无法提取页面进行 OCR', isError: true);
          setState(() => _isOcrProcessing = false);
          return;
        }

        final page = pages.first;
        final pngData = await page.toPng();
        final tempFile = File('${tempDir.path}/ocr_page_$_currentPage.png');
        await tempFile.writeAsBytes(pngData);
        imagePath = tempFile.path;
      } else {
        _showSnackBar('无法进行 OCR 识别', isError: true);
        setState(() => _isOcrProcessing = false);
        return;
      }

      // 导航到 OCR 页面
      if (mounted) {
        context.push('/ocr', extra: imagePath);
      }
    } catch (e) {
      _showSnackBar('OCR 识别失败: $e', isError: true);
    } finally {
      setState(() => _isOcrProcessing = false);
    }
  }

  void _showDeleteDialog() {
    if (_document == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除文档'),
        content: Text('确定要删除「${_document!.title}」吗？\n文档将移入回收站。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDocument();
            },
            child: const Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteDocument() async {
    if (_document == null) return;

    try {
      await _databaseService.deleteDocument(_document!.id);

      // 通知 Bloc 刷新列表
      if (mounted) {
        context.read<DocumentBloc>().add(const LoadDocumentsEvent());
        context.pop();
      }
    } catch (e) {
      _showSnackBar('删除失败: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _document?.title ?? '文档查看',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_document != null)
            IconButton(
              icon: Icon(
                _document!.isFavorite ? Icons.star : Icons.star_border,
                color: _document!.isFavorite ? Colors.amber : null,
              ),
              tooltip: _document!.isFavorite ? '取消收藏' : '收藏',
              onPressed: () {
                context.read<DocumentBloc>().add(
                      ToggleFavoriteEvent(
                        _document!.id,
                        !_document!.isFavorite,
                      ),
                    );
                // 刷新本地状态
                setState(() {
                  _document = _document!.copyWith(
                    isFavorite: !_document!.isFavorite,
                  );
                });
              },
            ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: _document != null ? _buildBottomToolbar() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDocument,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_documentType == _DocumentType.pdf) {
      return _buildPdfViewer();
    } else {
      return _buildImageViewer();
    }
  }

  Widget _buildPdfViewer() {
    if (_pdfData == null) {
      return const Center(child: Text('PDF 数据不可用'));
    }

    return Column(
      children: [
        // PDF 页面查看器（逐页）
        Expanded(
          child: PageView.builder(
            itemCount: _totalPages,
            controller: PageController(initialPage: _currentPage),
            onPageChanged: (page) {
              setState(() => _currentPage = page);
              _rasterizePdfPage(page);
              if (page + 1 < _totalPages) _rasterizePdfPage(page + 1);
            },
            itemBuilder: (context, index) {
              final imageData = _pdfPageImages[index];
              if (imageData != null) {
                return InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: Image.memory(
                      imageData,
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              }
              // 页面尚未光栅化，显示加载指示器
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在加载页面...'),
                  ],
                ),
              );
            },
          ),
        ),

        // 页面指示器和翻页控制
        if (_totalPages > 1) _buildPageNavigator(),
      ],
    );
  }

  Widget _buildImageViewer() {
    if (_imagePaths.isEmpty) {
      return const Center(child: Text('图片不可用'));
    }

    return Column(
      children: [
        // 图片查看器
        Expanded(
          child: PageView.builder(
            itemCount: _imagePaths.length,
            controller: PageController(initialPage: _currentPage),
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.file(
                    File(_imagePaths[index]),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image, size: 64, color: AppColors.error),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),

        // 页面指示器和翻页控制
        if (_totalPages > 1) _buildPageNavigator(),
      ],
    );
  }

  Widget _buildPageNavigator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 4,
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 上一页
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 0 ? _previousPage : null,
            tooltip: '上一页',
          ),

          // 页码显示 / 跳转
          GestureDetector(
            onTap: () => _showPageJumpDialog(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentPage + 1} / $_totalPages',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),

          // 下一页
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages - 1 ? _nextPage : null,
            tooltip: '下一页',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 分享
            _ToolbarItem(
              icon: Icons.share,
              label: '分享',
              onTap: _shareDocument,
            ),

            // 打印
            _ToolbarItem(
              icon: Icons.print,
              label: '打印',
              onTap: _printDocument,
            ),

            // OCR 识别
            _ToolbarItem(
              icon: Icons.text_snippet,
              label: 'OCR',
              onTap: _isOcrProcessing ? null : _performOcr,
              isLoading: _isOcrProcessing,
            ),

            // 删除
            _ToolbarItem(
              icon: Icons.delete_outline,
              label: '删除',
              onTap: _showDeleteDialog,
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }

  void _showPageJumpDialog() {
    final controller = TextEditingController(text: '${_currentPage + 1}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('跳转到页面'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('共 $_totalPages 页，请输入页码（1-$_totalPages）'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: '页码',
              ),
              onSubmitted: (value) {
                final page = int.tryParse(value);
                if (page != null && page >= 1 && page <= _totalPages) {
                  Navigator.pop(context);
                  _goToPage(page - 1);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              Navigator.pop(context);
              if (page != null && page >= 1 && page <= _totalPages) {
                _goToPage(page - 1);
              }
            },
            child: const Text('跳转'),
          ),
        ],
      ),
    );
  }
}

/// 文档类型
enum _DocumentType {
  pdf,
  image,
}

/// 底部工具栏项
class _ToolbarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final bool isLoading;

  const _ToolbarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? Theme.of(context).iconTheme.color ?? AppColors.textPrimaryLight;
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(
                icon,
                size: 24,
                color: isEnabled ? itemColor : itemColor.withOpacity(0.4),
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isEnabled ? itemColor : itemColor.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
