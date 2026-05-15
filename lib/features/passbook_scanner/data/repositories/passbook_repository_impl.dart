import '../models/bank_details.dart';
import 'passbook_repository.dart';
import '../../../../core/errors/failures.dart';
import '../../../../shared/services/ocr_service.dart';
import '../../domain/parsers/passbook_parser.dart';

class PassbookRepositoryImpl implements PassbookRepository {
  final OcrService _ocrService;

  const PassbookRepositoryImpl(this._ocrService);

  @override
  Future<(BankDetails?, Failure?)> scanFromImage(String imagePath) async {
    try {
      final text = await _ocrService.extractText(imagePath);
      final details = PassbookParser.parsePassbook(text);
      if (!details.hasAnyData) {
        return (null, const ParseFailure('No bank details found in image'));
      }
      return (details, null);
    } catch (e) {
      return (null, OcrFailure(e.toString()));
    }
  }
}