import '../constants/regex_patterns.dart';

/// String utility functions for FinScan.
///
/// OCR correction strategy:
///   [fixOcrDigitAmbiguity]  → safe for full raw text (only O→0, l→1)
///   [fixOcrNumericErrors]   → ONLY use on strings already confirmed as numbers
class StringUtils {
  StringUtils._();

  // ── OCR Correction ────────────────────────────────────────────

  /// Safe OCR fix — only corrects characters that are NEVER valid
  /// in names or IFSC codes.
  ///
  ///   O/o → 0  (visually identical to zero)
  ///   l   → 1  (lowercase L — safe because names are uppercase)
  ///
  /// DO NOT apply S→5, B→8, I→1, Z→2 here — those letters appear in:
  ///   • Names: SINGH, BURJ, SOHAN
  ///   • IFSC:  SBIN0001234, HDFC0001234
  static String fixOcrDigitAmbiguity(String input) {
    return input
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('l', '1');
  }

  /// Aggressive OCR fix — use ONLY on a string that has letters AND
  /// should be all digits (rare; only when raw OCR returned letters
  /// inside a number context).
  static String fixOcrNumericErrors(String input) {
    return input
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('I', '1')
        .replaceAll('l', '1')
        .replaceAll('S', '5')
        .replaceAll('B', '8')
        .replaceAll('Z', '2')
        .replaceAll('G', '6')
        .replaceAll('q', '9');
  }

  // ── Digit Extraction ──────────────────────────────────────────

  static String digitsOnly(String input) =>
      input.replaceAll(RegExp(r'\D'), '');

  static bool isAllDigits(String input) =>
      input.isNotEmpty && RegExp(r'^\d+$').hasMatch(input);

  // ── Card Formatting ──────────────────────────────────────────

  static String formatCardNumber(String digits) {
    final clean = digitsOnly(digits);
    if (clean.isEmpty) return '';

    final buffer = StringBuffer();

    if (clean.length == 15) {
      // Amex: 4-6-5
      buffer.write(clean.substring(0, 4));
      buffer.write(' ');
      buffer.write(clean.substring(4, 10));
      buffer.write(' ');
      buffer.write(clean.substring(10));
    } else {
      for (int i = 0; i < clean.length; i++) {
        if (i > 0 && i % 4 == 0) buffer.write(' ');
        buffer.write(clean[i]);
      }
    }
    return buffer.toString();
  }

  static String maskCardNumber(String cardNumber) {
    final digits = digitsOnly(cardNumber);
    if (digits.length < 4) return '*' * digits.length;
    return '${'*' * (digits.length - 4)}${digits.substring(digits.length - 4)}';
  }

  static String formatMaskedCard(String cardNumber) {
    final digits = digitsOnly(cardNumber);
    if (digits.length < 4) return '*' * digits.length;
    final masked =
        '${'*' * (digits.length - 4)}${digits.substring(digits.length - 4)}';
    return formatCardNumber(masked);
  }

  // ── Text Cleaning ─────────────────────────────────────────────

  static String normaliseSpaces(String input) =>
      input.trim().replaceAll(RegExp(r'\s{2,}'), ' ');

  /// Strips relationship suffixes (S/O, D/O, W/O, H/O, C/O) and trailing punctuation.
  static String cleanNameTrailingNoise(String name) {
    return name
        .replaceAll(RegExp(r'\s*[,\-]\s*$'), '')
        .replaceAll(
        RegExp(r'\b(?:S\/O|D\/O|W\/O|H\/O|C\/O|S\/D\/H\/O)\b.*$',
            caseSensitive: false),
        '')
        .trim();
  }

  /// Pre-clean text by removing dates and times before number extraction.
  /// Returns a copy with those segments replaced by spaces.
  static String stripNoise(String text) {
    String result = text;
    result = result.replaceAll(RegexPatterns.datePattern, ' ');
    result = result.replaceAll(RegexPatterns.timePattern, ' ');
    return result;
  }
}