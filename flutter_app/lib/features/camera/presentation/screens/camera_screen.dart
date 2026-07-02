import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scanpdf/core/theme/app_colors.dart';

/// Camera screen for capturing document photos
/// Features: auto-focus, flash control, batch capture mode
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
  List<String> _capturedImages = [];
  bool _isInitialized = false;
  late AnimationController _shutterAnimation;
  late Animation<double> _shutterScale;

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

      setState(() {
        _capturedImages.add(savedPath);
      });

      if (!_isBatchMode) {
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

          // Scan Guide Overlay
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
                          onTap: () {
                            // TODO: Open gallery picker
                          },
                        ),

                        // Shutter
                        GestureDetector(
                          onTap: _captureImage,
                          child: AnimatedBuilder(
                            animation: _shutterScale,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _shutterScale.value,
                                child: child,
                              );
                            },
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
