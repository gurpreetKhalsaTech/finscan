import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/card_details.dart';
import '../../../card_scanner/providers/card_providers.dart';

enum ScanState { idle, scanning, success, error }

class CardScannerState {
  final ScanState status;
  final CardDetails? cardDetails;
  final String? errorMessage;
  final String? scannedImagePath;

  const CardScannerState({
    this.status = ScanState.idle,
    this.cardDetails,
    this.errorMessage,
    this.scannedImagePath,
  });

  CardScannerState copyWith({
    ScanState? status,
    CardDetails? cardDetails,
    String? errorMessage,
    String? scannedImagePath,
  }) {
    return CardScannerState(
      status: status ?? this.status,
      cardDetails: cardDetails ?? this.cardDetails,
      errorMessage: errorMessage ?? this.errorMessage,
      scannedImagePath: scannedImagePath ?? this.scannedImagePath,
    );
  }
}

class CardScannerViewModel extends Notifier<CardScannerState> {
  @override
  CardScannerState build() => const CardScannerState();

  Future<void> scanImage(String imagePath) async {
    state = state.copyWith(status: ScanState.scanning, scannedImagePath: imagePath);

    final usecase = ref.read(scanCardUsecaseProvider);
    final (card, failure) = await usecase(imagePath);

    if (failure != null) {
      state = state.copyWith(status: ScanState.error, errorMessage: failure.message);
      return;
    }

    if (card == null) {
      state = state.copyWith(status: ScanState.error, errorMessage: 'No card found in image');
      return;
    }

    state = state.copyWith(status: ScanState.success, cardDetails: card);
  }

  void reset() => state = const CardScannerState();
}