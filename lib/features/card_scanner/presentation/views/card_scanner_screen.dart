import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/camera_overlay.dart';
import '../../providers/card_providers.dart';
import '../viewmodels/card_scanner_viewmodel.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/services/camera_service.dart';

class CardScannerScreen extends ConsumerStatefulWidget {
  const CardScannerScreen({super.key});

  @override
  ConsumerState<CardScannerScreen> createState() => _CardScannerScreenState();
}

class _CardScannerScreenState extends ConsumerState<CardScannerScreen> {
  CameraController? _controller;
  bool _initializing = true;
  String? _initError;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndInit();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _requestPermissionAndInit() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _permissionDenied = true;
        _initializing = false;
      });
      return;
    }
    await _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await CameraService.getAvailableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _initError = 'No cameras found on this device';
          _initializing = false;
        });
        return;
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _controller = controller;
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = 'Camera init failed: $e';
        _initializing = false;
      });
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (ref.read(cardScannerViewModelProvider).status == ScanState.scanning) return;

    try {
      final file = await controller.takePicture();
      await ref.read(cardScannerViewModelProvider.notifier).scanImage(file.path);
    } catch (e) {
      // error handled by viewmodel state
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cardScannerViewModelProvider, (_, next) {
      if (next.status == ScanState.success && next.cardDetails != null) {
        final card = next.cardDetails!;
        final path = next.scannedImagePath;
        ref.read(cardScannerViewModelProvider.notifier).reset();
        context.push(AppRouter.cardResult, extra: (card, path));
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Card'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.camera_alt, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Camera permission is required to scan cards.',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: openAppSettings,
                child: const Text('Open Settings'),
              ),
            ],
          ),
        ),
      );
    }

    if (_initError != null) {
      return Center(
        child: Text(_initError!, style: const TextStyle(color: Colors.red, fontSize: 14)),
      );
    }

    final scanState = ref.watch(cardScannerViewModelProvider);
    final isScanning = scanState.status == ScanState.scanning;

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        const CameraOverlay(),
        if (isScanning)
          const ColoredBox(
            color: Color(0x80000000),
            child: Center(child: CircularProgressIndicator(color: Colors.white)),
          ),
        if (scanState.status == ScanState.error)
          Align(
            alignment: const Alignment(0, 0.75),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      scanState.errorMessage ?? 'Scan failed. Try again.',
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (!isScanning)
          Align(
            alignment: const Alignment(0, 0.92),
            child: GestureDetector(
              onTap: _capture,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: Colors.white54, width: 4),
                ),
                child: const Icon(Icons.camera_alt, color: Colors.black, size: 32),
              ),
            ),
          ),
      ],
    );
  }
}