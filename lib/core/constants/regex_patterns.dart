class RegexPatterns {
  RegexPatterns._();

  static final cardNumber = RegExp(r'\b\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{4}\b');

  // Handles MM/YY, MM-YY, and MMYY (year 20-39)
  static final expiry = RegExp(
    r'\b(0[1-9]|1[0-2])[\/\-]([0-9]{2})\b|\b(0[1-9]|1[0-2])(2[0-9]|3[0-9])(?!\d)\b',
  );

  static final cvv = RegExp(r'\b\d{3,4}\b');

  // Labeled account number patterns (checked first, higher confidence)
  static final labeledAccountNumber = RegExp(
    r'(?:A\/C(?:\s*NO\.?)?|ACCOUNT\s*NO\.?|ACC(?:\s*NO\.?)?)[:\s]+(\d{9,18})',
    caseSensitive: false,
  );

  static final accountNumber = RegExp(r'\b\d{9,18}\b');

  // IFSC must be matched against ORIGINAL (non-OCR-corrected) text
  static final ifscCode = RegExp(r'\b[A-Z]{4}0[A-Z0-9]{6}\b');

  static final micrCode = RegExp(r'\b\d{9}\b');
}