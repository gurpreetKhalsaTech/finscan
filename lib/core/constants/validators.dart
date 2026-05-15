import '../utils/string_utils.dart';
import '../../features/card_scanner/domain/parsers/luhn_validator.dart';

/// Input validation helpers.
///
/// These validate already-extracted values (post-parsing).
/// They are NOT parsers — do not pass raw OCR text here.
class Validators {
  Validators._();

  // ── Card ─────────────────────────────────────────────────────

  /// Returns true if [number] (digits only) is a valid card number.
  ///
  /// Accepts 13–19 digit lengths to cover:
  ///   • Visa (13 or 16), Mastercard (16), RuPay (16), Amex (15),
  ///     Discover (16), Diners (14), UnionPay (16–19).
  ///
  /// Validates using the Luhn algorithm.
  static bool isValidCardNumber(String number) {
    final digits = StringUtils.digitsOnly(number);
    if (digits.length < 13 || digits.length > 19) return false;
    return LuhnValidator.isValid(digits);
  }

  // ── Passbook ─────────────────────────────────────────────────

  /// Returns true if [account] has a plausible account number length (9–18 digits).
  static bool isValidAccountNumber(String account) {
    final digits = StringUtils.digitsOnly(account);
    return digits.length >= 9 && digits.length <= 18;
  }
}