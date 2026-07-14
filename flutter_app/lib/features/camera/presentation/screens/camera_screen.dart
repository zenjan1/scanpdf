import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scanpdf/core/theme/app_colors.dart';
import 'package:scanpdf/core/services/image_processing_service.dart';

/// Camera screen for capturing document photos
/// Features: auto-focus, flash control, batch capture mode, real-time edge detection
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  bool _isFlashOn = false;
  bool _isBatchMode = false;
  final List<String> _capturedImages = [];
  bool _isInitialized = false;
  late AnimationController _shutterAnimation;
  late Animation<double> _shutterScale;

  // Real-time edge detection
  final ImageProcessingService _imageProcessingService = ImageProcessingService();
  List<List<int>> _detectedEdges = [];
  bool _isDetectingEdges = false;
  Timer? _edgeDetectionTimer;
  bool _showEdgeOverlay = true;

  // Gesture cropping (reserved for future use)
  // ignore: unused_field
  final List<Offset> _cropCorners = [];
  // ignore: unused_field
  final bool _isCropping = false;

  @override
  void initState() {
    super.initState();
    _shutterAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _shutterScale = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _shutterAnimation, curve: Curves.easeInOut),
    );
    _initializeCamera();
    _startEdgeDetection();
  }

  // 启动实时边缘检测
  void _startEdgeDetection() {
    _edgeDetectionTimer = Timer.periodic(
      const Duration(milliseconds: 500), // 每500ms检测一次
      (_) async {
        if (_controller == null || !_controller!.value.isInitialized) return;
        if (!_showEdgeOverlay) return;

        try {
          setState(() {
            _isDetectingEdges = true;
          });

          // 捕获当前帧
          final image = await _controller!.takePicture();
          final bytes = await image.readAsBytes();

          // 检测边缘
          final corners = await _imageProcessingService.detectDocumentEdges(bytes);

          if (mounted) {
            setState(() {
              _detectedEdges = corners;
              _isDetectingEdges = false;
            });
          }
        } catch (e) {
          debugPrint('Edge detection error: $e');
          if (mounted) {
            setState(() {
              _isDetectingEdges = false;
            });
          }
        }
      },
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final controller = CameraController(
        _cameras[_currentCameraIndex],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();
      await controller.setFocusMode(FocusMode.auto);

      if (mounted) {
        setState(() {
          _controller = controller;
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    await _controller?.dispose();
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras.length;
    await _initializeCamera();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    try {
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.off : FlashMode.torch,
      );
      setState(() => _isFlashOn = !_isFlashOn);
    } catch (e) {
      debugPrint('Flash toggle error: $e');
    }
  }

  Future<void> _captureImage() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    _shutterAnimation.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    _shutterAnimation.reverse();

    try {
      final xFile = await _controller!.takePicture();
      final dir = await getTemporaryDirectory();
      final fileName =
          'scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${dir.path}/$fileName';
      final savedFile = File(savedPath);
      await savedFile.writeAsBytes(await xFile.readAsBytes());

      if (!mounted) return;
      setState(() {
        _capturedImages.add(savedPath);
      });

      if (!_isBatchMode && mounted) {
        context.pushReplacement('/scan', extra: {'imagePath': savedPath});
      }
    } catch (e) {
      debugPrint('Capture error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _shutterAnimation.dispose();
    _edgeDetectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview
          if (_isInitialized && _controller != null)
            SizedBox.expand(
              child: CameraPreview(_controller!),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Scan Guide Overlay with Edge Detection
          if (_showEdgeOverlay && _detectedEdges.isNotEmpty)
            CustomPaint(
              painter: _EdgeDetectionPainter(
                corners: _detectedEdges,
                isDetecting: _isDetectingEdges,
              ),
              child: const SizedBox.expand(),
            )
          else if (_showEdgeOverlay)
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.width * 0.6,
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(
                  painter: _CornerPainter(),
                ),
              ),
            ),

          // Top Controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(
                    icon: Icons.close,
                    onTap: () => context.pop(),
                  ),
                  Row(
                    children: [
                      _buildCircleButton(
                        icon: _isFlashOn
                            ? Icons.flash_on
                            : Icons.flash_off,
                        onTap: _toggleFlash,
                      ),
                      const SizedBox(width: 12),
                      _buildCircleButton(
                        icon: Icons.cameraswitch,
                        onTap: _switchCamera,
                      ),
                      const SizedBox(width: 12),
                      _buildCircleButton(
                        icon: _showEdgeOverlay
                            ? Icons.crop_square
                            : Icons.crop_free,
                        onTap: () {
                          setState(() {
                            _showEdgeOverlay = !_showEdgeOverlay;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Batch counter
          if (_capturedImages.isNotEmpty)
            Positioned(
              top: 80,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_capturedImages.length} 张已拍摄',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mode Toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildModeChip('单页', !_isBatchMode),
                        const SizedBox(width: 12),
                        _buildModeChip('多页', _isBatchMode),
                        const SizedBox(width: 12),
                        _buildModeChip('ID卡', false),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Capture Button Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Gallery
                        _buildCircleButton(
                          icon: Icons.photo_library,
                          size: 44,
                          onTap: () async {
                            final picker = ImagePicker();
                            final images = await picker.pickMultiImage(
                              imageQuality: 90,
                            );
                            if (images.isEmpty || !mounted) return;
                            final paths = <String>[];
                            final tempCtx = context;
                            for (final img in images) {
                              final dir = await getTemporaryDirectory();
                              final fileName =
                                  'gallery_${DateTime.now().millisecondsSinceEpoch}_${img.name}';
                              final savedPath = '${dir.path}/$fileName';
                              await File(savedPath).writeAsBytes(await img.readAsBytes());
                              paths.add(savedPath);
                            }
                            if (!tempCtx.mounted) return;
                            tempCtx.pushReplacement('/scan', extra: {
                              'imagePaths': paths,
                            });
                          },
                        ),

                        // Shutter
                        GestureDetector(
                          onTap: _captureImage,
                          child: ScaleTransition(
                            scale: _shutterScale,
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Confirm / Continue
                        if (_isBatchMode && _capturedImages.isNotEmpty)
                          _buildCircleButton(
                            icon: Icons.check,
                            size: 44,
                            onTap: () {
                              context.pushReplacement('/scan', extra: {
                                'imagePaths': _capturedImages,
                              });
                            },
                          )
                        else
                          const SizedBox(width: 44),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onTap,
    double size = 40,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(0.4),
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }

  Widget _buildModeChip(String label, bool isSelected) {
    return GestureDetector(
      onTap: () {
        if (label == '多页') setState(() => _isBatchMode = true);
        if (label == '单页') setState(() => _isBatchMode = false);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const cornerLen = 30.0;

    // Top-left
    canvas.drawLine(
        const Offset(0, 0), const Offset(cornerLen, 0), paint);
    canvas.drawLine(
        const Offset(0, 0), const Offset(0, cornerLen), paint);

    // Top-right
    canvas.drawLine(Offset(size.width, 0),
        Offset(size.width - cornerLen, 0), paint);
    canvas.drawLine(Offset(size.width, 0),
        Offset(size.width, cornerLen), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height),
        Offset(cornerLen, size.height), paint);
    canvas.drawLine(Offset(0, size.height),
        Offset(0, size.height - cornerLen), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width - cornerLen, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLen), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EdgeDetectionPainter extends CustomPainter {
  final List<List<int>> corners;
  final bool isDetecting;

  _EdgeDetectionPainter({
    required this.corners,
    required this.isDetecting,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (corners.isEmpty) return;

    final paint = Paint()
      ..color = isDetecting ? Colors.orange : AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();

    // 将角点转换为屏幕坐标
    for (int i = 0; i < corners.length; i++) {
      final corner = corners[i];
      final x = corner[0].toDouble();
      final y = corner[1].toDouble();

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    canvas.drawPath(path, paint);

    // 绘制角点圆圈
    final circlePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    for (final corner in corners) {
      canvas.drawCircle(
        Offset(corner[0].toDouble(), corner[1].toDouble()),
        8,
        circlePaint,
      );
    }

    // 如果正在检测，显示加载指示器
    if (isDetecting) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '检测中...',
          style: TextStyle(
            color: Colors.orange,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width / 2 - textPainter.width / 2, 20),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EdgeDetectionPainter oldDelegate) {
    return oldDelegate.corners != corners ||
        oldDelegate.isDetecting != isDetecting;
  }
}
