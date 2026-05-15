import '../constants/regex_patterns.dart';
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

  /// Returns true if [expiry] represents a future date.
  ///
  /// Accepts formats: MM/YY, MM-YY, MM/YYYY, MM-YYYY
  /// Also tolerates "VALID THRU MM/YY" style labels.
  static bool isValidExpiry(String expiry) {
    if (expiry.isEmpty) return false;

    // Strip label noise
    final cleaned = expiry
        .replaceAll(
      RegExp(
        r'(?:VALID\s*(?:THRU|THROUGH|TO|FROM)|EXPIRY|EXPIRES?|EXP\.?)\s*',
        caseSensitive: false,
      ),
      '',
    )
        .trim();

    // Must contain a separator or be MMYY (4 digits)
    final hasSeparator = RegExp(r'[\/\-]').hasMatch(cleaned);

    int? month;
    int? year;

    if (hasSeparator) {
      final parts = cleaned.split(RegExp(r'[\/\-]'));
      if (parts.length < 2) return false;

      month = int.tryParse(parts[0].trim());
      final rawYear = parts[1].trim();

      // Handle YY (2-digit) and YYYY (4-digit)
      year = rawYear.length == 4
          ? int.tryParse(rawYear)
          : int.tryParse('20$rawYear');
    } else {
      // MMYY no separator
      final digits = StringUtils.digitsOnly(cleaned);
      if (digits.length != 4) return false;
      month = int.tryParse(digits.substring(0, 2));
      year = int.tryParse('20${digits.substring(2)}');
    }

    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;
    if (year < 2024 || year > 2040) return false;

    final now = DateTime.now();
    // Card is valid until end of the expiry month
    final expiryDate = DateTime(year, month + 1);
    return expiryDate.isAfter(now);
  }

  /// Returns true if [ifsc] matches the RBI IFSC format.
  /// Format: 4 uppercase letters + '0' + 6 alphanumeric characters.
  /// Must be validated against ORIGINAL text (not OCR-corrected).
  static bool isValidIfsc(String ifsc) =>
      RegexPatterns.ifscCode.hasMatch(ifsc.toUpperCase().trim());

  /// Returns true if [account] has a plausible account number length (9–18 digits).
  static bool isValidAccountNumber(String account) {
    final digits = StringUtils.digitsOnly(account);
    return digits.length >= 9 && digits.length <= 18;
  }

  /// Returns true if [number] passes a basic CIF check (7–12 digits).
  /// This is used to EXCLUDE CIF numbers from account number extraction.
  static bool looksLikeCif(String number) {
    final digits = StringUtils.digitsOnly(number);
    return digits.length >= 7 && digits.length <= 12;
  }
}