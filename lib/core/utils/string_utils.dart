/// String utility functions for FinScan.
///
/// OCR correction strategy:
///   [fixOcrDigitAmbiguity]  → safe for full raw text (only O→0, l→1)
///   [fixOcrNumericErrors]   → ONLY use on strings already confirmed as numbers
///                             (corrupts names, IFSC codes if used on raw text)
class StringUtils {
  StringUtils._();

  // ── OCR Correction ────────────────────────────────────────────

  /// Safe OCR fix — only corrects characters that are NEVER valid
  /// in names or IFSC codes.
  ///
  /// Apply this to the full raw OCR text before regex matching.
  ///   O/o → 0  (capital O and lowercase o look like zero)
  ///   l   → 1  (lowercase L looks like one — safe because names are uppercase)
  ///
  /// DO NOT apply S→5, B→8, I→1, Z→2 here — those letters appear in:
  ///   • Names: SINGH, BURJ, SINGH, SOHAN
  ///   • IFSC:  SBIN0001234, HDFC0001234
  static String fixOcrDigitAmbiguity(String input) {
    return input
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('l', '1'); // lowercase L only — never in uppercase names
  }

  /// Aggressive OCR fix — use ONLY on a string already confirmed to be
  /// a card number or account number (digits only context).
  ///
  /// NEVER call this on full raw OCR text — it corrupts:
  ///   • Names: SOHAN SINGH → 50HAN 51NGH
  ///   • IFSC:  SBIN0005576 → 5B1N0005576 (breaks IFSC regex)
  static String fixOcrNumericErrors(String input) {
    return input
        .replaceAll('O', '0')
        .replaceAll('o', '0')
        .replaceAll('I', '1')
        .replaceAll('l', '1')
        .replaceAll('S', '5')
        .replaceAll('B', '8')
        .replaceAll('Z', '2');
  }

  // ── Digit Extraction ──────────────────────────────────────────

  /// Strips all non-digit characters from [input].
  static String digitsOnly(String input) =>
      input.replaceAll(RegExp(r'\D'), '');

  /// Returns true if [input] contains only digit characters.
  static bool isAllDigits(String input) =>
      input.isNotEmpty && RegExp(r'^\d+$').hasMatch(input);

  // ── Card Formatting ──────────────────────────────────────────

  /// Formats a digit string as groups of 4: "XXXX XXXX XXXX XXXX".
  /// Handles 15-digit Amex as "XXXX XXXXXX XXXXX".
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
      // Standard: groups of 4
      for (int i = 0; i < clean.length; i++) {
        if (i > 0 && i % 4 == 0) buffer.write(' ');
        buffer.write(clean[i]);
      }
    }

    return buffer.toString();
  }

  /// Masks all but the last 4 digits with '*'.
  /// e.g. "4147524980423995" → "************3995"
  static String maskCardNumber(String cardNumber) {
    final digits = digitsOnly(cardNumber);
    if (digits.length < 4) return '*' * digits.length;
    return '${'*' * (digits.length - 4)}${digits.substring(digits.length - 4)}';
  }

  /// Combines masking + grouping for display.
  /// e.g. "4147524980423995" → "**** **** **** 3995"
  static String formatMaskedCard(String cardNumber) {
    final digits = digitsOnly(cardNumber);
    if (digits.length < 4) return '*' * digits.length;
    final masked =
        '${'*' * (digits.length - 4)}${digits.substring(digits.length - 4)}';
    return formatCardNumber(masked);
  }

  // ── Passbook / Name Utilities ─────────────────────────────────

  /// Normalises whitespace: trims and collapses multiple spaces to one.
  static String normaliseSpaces(String input) =>
      input.trim().replaceAll(RegExp(r'\s{2,}'), ' ');

  /// Returns [input] with each word title-cased.
  /// e.g. "GURPREET SINGH" → "Gurpreet Singh"
  static String toTitleCase(String input) {
    return input.toLowerCase().replaceAllMapped(
      RegExp(r'\b\w'),
          (m) => m.group(0)!.toUpperCase(),
    );
  }

  /// Strips common trailing noise from an extracted name line.
  /// Removes things like "S/O", "D/O", "W/O", "H/O" relationship suffixes
  /// that sometimes bleed into the name field in passbooks.
  static String cleanNameTrailingNoise(String name) {
    return name
        .replaceAll(RegExp(r'\s*[,\-]\s*$'), '')
        .replaceAll(
        RegExp(r'\b(?:S\/O|D\/O|W\/O|H\/O|C\/O)\b.*$',
            caseSensitive: false),
        '')
        .trim();
  }

  /// Removes a candidate number string from [text] context
  /// by checking if it appears next to a label that suggests
  /// it is NOT an account number (CIF, MICR, Branch Code, etc.).
  static bool appearsAfterExcludedLabel(String number, String fullText) {
    // Build a pattern: any excluded label, then whitespace/colon, then the number
    final escaped = RegExp.escape(number);
    final pattern = RegExp(
      r'(?:CIF|MICR|BRANCH\s*CODE|BR\.?\s*CODE|PIN\s*CODE|PINCODE|'
      r'PHONE|MOBILE|MOB|TEL|PH|PPO|PAGE\s*NO)'
      r'[\s\.\:\-]*'
      r'[\d\s]*'
      '$escaped',
      caseSensitive: false,
    );
    return pattern.hasMatch(fullText);
  }
}