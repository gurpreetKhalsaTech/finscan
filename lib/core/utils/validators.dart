import '../constants/regex_patterns.dart';
import '../../features/card_scanner/domain/parsers/luhn_validator.dart';

class Validators {
  Validators._();

  static bool isValidCardNumber(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 16) return false;
    return LuhnValidator.isValid(digits);
  }

  static bool isValidExpiry(String expiry) {
    if (!RegexPatterns.expiry.hasMatch(expiry)) return false;
    final parts = expiry.split('/');
    final month = int.tryParse(parts[0]) ?? 0;
    final year = int.tryParse('20${parts[1]}') ?? 0;
    final now = DateTime.now();
    final expiryDate = DateTime(year, month + 1);
    return expiryDate.isAfter(now);
  }

  static bool isValidIfsc(String ifsc) => RegexPatterns.ifscCode.hasMatch(ifsc);

  static bool isValidAccountNumber(String account) =>
      RegexPatterns.accountNumber.hasMatch(account);
}