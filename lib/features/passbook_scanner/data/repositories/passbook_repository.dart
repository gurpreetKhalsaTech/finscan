import '../models/bank_details.dart';
import '../../../../core/errors/failures.dart';

abstract class PassbookRepository {
  Future<(BankDetails?, Failure?)> scanFromImage(String imagePath);
}