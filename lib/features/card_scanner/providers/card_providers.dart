import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/usecases/scan_card_usecase.dart';
import '../presentation/viewmodels/card_scanner_viewmodel.dart';
import '../data/repositories/card_scanner_repository_impl.dart';
import '../../../shared/services/ocr_service.dart';
import '../../../shared/services/camera_service.dart';

final ocrServiceProvider = Provider<OcrService>((ref) {
  final service = OcrService();
  ref.onDispose(service.dispose);
  return service;
});

final cameraServiceProvider = Provider<CameraService>((ref) => CameraService());

final cardScannerRepositoryProvider = Provider<CardScannerRepositoryImpl>((ref) {
  return CardScannerRepositoryImpl(ref.read(ocrServiceProvider));
});

final scanCardUsecaseProvider = Provider<ScanCardUsecase>((ref) {
  return ScanCardUsecase(ref.read(cardScannerRepositoryProvider));
});

final cardScannerViewModelProvider =
    NotifierProvider<CardScannerViewModel, CardScannerState>(CardScannerViewModel.new);