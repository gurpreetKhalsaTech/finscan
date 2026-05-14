import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/bank_details.dart';
import '../../providers/passbook_providers.dart';

enum PassbookScanState { idle, scanning, success, error }

class PassbookState {
  final PassbookScanState status;
  final BankDetails? bankDetails;
  final String? errorMessage;
  final String? scannedImagePath;

  const PassbookState({
    this.status = PassbookScanState.idle,
    this.bankDetails,
    this.errorMessage,
    this.scannedImagePath,
  });

  PassbookState copyWith({
    PassbookScanState? status,
    BankDetails? bankDetails,
    String? errorMessage,
    String? scannedImagePath,
  }) {
    return PassbookState(
      status: status ?? this.status,
      bankDetails: bankDetails ?? this.bankDetails,
      errorMessage: errorMessage ?? this.errorMessage,
      scannedImagePath: scannedImagePath ?? this.scannedImagePath,
    );
  }
}

class PassbookViewModel extends Notifier<PassbookState> {
  @override
  PassbookState build() => const PassbookState();

  Future<void> scanImage(String imagePath) async {
    state = state.copyWith(status: PassbookScanState.scanning, scannedImagePath: imagePath);

    final repository = ref.read(passbookRepositoryProvider);
    final (details, failure) = await repository.scanFromImage(imagePath);

    if (failure != null) {
      state = state.copyWith(status: PassbookScanState.error, errorMessage: failure.message);
      return;
    }

    if (details == null) {
      state = state.copyWith(
        status: PassbookScanState.error,
        errorMessage: 'No bank details found in image',
      );
      return;
    }

    state = state.copyWith(status: PassbookScanState.success, bankDetails: details);
  }

  void reset() => state = const PassbookState();
}