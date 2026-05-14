import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../card_scanner/presentation/widgets/camera_overlay.dart';
import '../../providers/passbook_providers.dart';
import '../viewmodels/passbook_viewmodel.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/services/camera_service.dart';

class PassbookScannerScreen extends ConsumerStatefulWidget {
  const PassbookScannerScreen({super.key});

  @override
  ConsumerState<PassbookScannerScreen> createState() => _PassbookScannerScreenState();
}

class _PassbookScannerScreenState extends ConsumerState<PassbookScannerScreen> {
  CameraController? _controller;
  bool _initializing = true;
  String? _initError;
  bool _permissionDenied = false;
  final _picker = ImagePicker();

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
    if (ref.read(passbookViewModelProvider).status == PassbookScanState.scanning) return;
    try {
      final file = await controller.takePicture();
      await ref.read(passbookViewModelProvider.notifier).scanImage(file.path);
    } catch (_) {}
  }

  Future<void> _pickFromGallery() async {
    if (ref.read(passbookViewModelProvider).status == PassbookScanState.scanning) return;
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
      if (file == null) return;
      await ref.read(passbookViewModelProvider.notifier).scanImage(file.path);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(passbookViewModelProvider, (_, next) {
      if (next.status == PassbookScanState.success && next.bankDetails != null) {
        final bank = next.bankDetails!;
        final path = next.scannedImagePath;
        ref.read(passbookViewModelProvider.notifier).reset();
        context.push(AppRouter.passbookResult, extra: (bank, path));
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Passbook'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_outlined),
            tooltip: 'Pick from gallery',
            onPressed: _pickFromGallery,
          ),
        ],
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
                'Camera permission is required to scan a passbook.',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'You can also pick an image from your gallery.',
                style: TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('Pick from Gallery'),
                onPressed: _pickFromGallery,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: openAppSettings,
                child: const Text('Open Settings', style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      );
    }

    if (_initError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_initError!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Pick from Gallery'),
              onPressed: _pickFromGallery,
            ),
          ],
        ),
      );
    }

    final scanState = ref.watch(passbookViewModelProvider);
    final isScanning = scanState.status == PassbookScanState.scanning;

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
        if (scanState.status == PassbookScanState.error)
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