import '../../data/models/card_details.dart';
import '../../data/repositories/card_scanner_repository.dart';
import '../../../../core/errors/failures.dart';

class ScanCardUsecase {
  final CardScannerRepository _repository;

  const ScanCardUsecase(this._repository);

  Future<(CardDetails?, Failure?)> call(String imagePath) =>
      _repository.scanFromImage(imagePath);
}