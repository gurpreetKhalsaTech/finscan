import '../models/card_details.dart';
import 'card_scanner_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/services/ocr_service.dart';
import '../../domain/parsers/card_parser.dart';

class CardScannerRepositoryImpl implements CardScannerRepository {
  final OcrService _ocrService;

  const CardScannerRepositoryImpl(this._ocrService);

  @override
  Future<(CardDetails?, Failure?)> scanFromImage(String imagePath) async {
    try {
      final text = await _ocrService.extractText(imagePath);
      final card = CardParser.parseCard(text);
      if (!card.hasAnyData) {
        return (null, const ParseFailure('No valid card found in image'));
      }
      return (card, null);
    } on OcrFailure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, OcrFailure(e.toString()));
    }
  }
}