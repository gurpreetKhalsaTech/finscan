import '../models/card_details.dart';
import '../../../../core/errors/failures.dart';

abstract class CardScannerRepository {
  Future<(CardDetails?, Failure?)> scanFromImage(String imagePath);
}