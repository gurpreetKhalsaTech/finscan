
import '../utils/string_utils.dart';
import '../../features/card_scanner/domain/parsers/luhn_validator.dart';
import 'app_constant.dart';

/// Input validation helpers.
///
/// These validate already-extracted values (post-parsing).
/// They are NOT parsers — do not pass raw OCR text here.
class Validators {
  Validators._();

  // ── Card ─────────────────────────────────────────────────────

  /// Returns true if [number] is a valid card number.
  ///
  /// Accepts 13–19 digit lengths to cover:
  ///   • Visa (13 or 16), Mastercard (16), RuPay (16), Amex (15),
  ///   • Discover (16), Diners (14), UnionPay (16–19).
  ///
  /// Validates using the Luhn algorithm.
  static bool isValidCardNumber(String number) {
    final digits = StringUtils.digitsOnly(number);
    if (digits.length < AppConstants.minCardNumberLength ||
        digits.length > AppConstants.maxCardNumberLength)     {
      return false;
    }
    return LuhnValidator.isValid(digits);
  }

  // ── Passbook ─────────────────────────────────────────────────

  /// Returns true if [account] has a plausible account number length (9–18 digits).
  static bool isValidAccountNumber(String account) {
    final digits = StringUtils.digitsOnly(account);
    return digits.length >= AppConstants.minAccountNumberLength &&
        digits.length <= AppConstants.maxAccountNumberLength;
  }

  /// Returns true if [number] is a 9-digit MICR code.
  static bool isValidMicr(String number) {
    final digits = StringUtils.digitsOnly(number);
    return digits.length == AppConstants.micrLength;
  }
}