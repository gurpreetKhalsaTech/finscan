class StringUtils {
  StringUtils._();

  /// Corrects common OCR misreads in numeric contexts (O→0, I→1, l→1, S→5).
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

  /// Strips all non-digit characters from a string.
  static String digitsOnly(String input) => input.replaceAll(RegExp(r'\D'), '');

  /// Formats a 16-digit card number as XXXX XXXX XXXX XXXX.
  static String formatCardNumber(String digits) {
    final clean = digitsOnly(digits);
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  /// Masks all but last 4 digits of a card number.
  static String maskCardNumber(String cardNumber) {
    final digits = digitsOnly(cardNumber);
    if (digits.length < 4) return '*' * digits.length;
    return '${'*' * (digits.length - 4)}${digits.substring(digits.length - 4)}';
  }

  static String formatMaskedCard(String cardNumber) {
    final masked = maskCardNumber(cardNumber);
    return formatCardNumber(masked);
  }
}