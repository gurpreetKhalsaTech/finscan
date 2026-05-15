/// Central regex pattern registry for FinScan.
///
/// IMPORTANT — OCR correction rule:
///   • IFSC codes must be matched against ORIGINAL (non-corrected) text
///     because [StringUtils.fixOcrDigitAmbiguity] replaces O→0, which
///     would break patterns like SBIN, HDFC, etc.
library;

class RegexPatterns {
  RegexPatterns._();

  // ── Card ─────────────────────────────────────────────────────

  /// Standard 16-digit card (Visa, MC, RuPay) with optional separators.
  /// Also handles 15-digit Amex (4-6-5 grouping).
  static final cardNumber = RegExp(
    r'\b(\d{4}[\s\-]?\d{6}[\s\-]?\d{5}|\d{4}[\s\-]?\d{4}[\s\-]?\d{4}[\s\-]?\d{4})\b',
  );

  /// Expiry date — handles:
  ///   MM/YY  MM-YY  MM YY  MMYY  MM/YYYY  MM-YYYY
  ///   with optional labels: "VALID THRU", "EXP", "EXPIRES", etc.
  static final expiry = RegExp(
    r'(?:VALID\s*(?:THRU|THROUGH|TO)|EXPIRY|EXPIRES?|EXP)[\s\:\.]?'
    r'\s*(0[1-9]|1[0-2])[\/\-\s](20[2-3]\d|\d{2})'
    r'|\b(0[1-9]|1[0-2])[\/\-](20[2-3]\d|\d{2})\b'
    r'|\b(0[1-9]|1[0-2])(2[0-9]|3[0-9])(?!\d)\b',
    caseSensitive: false,
  );

  /// CVV — 3 or 4 digits standalone (used on back of card).
  static final cvv = RegExp(r'\b\d{3,4}\b');

  // ── Passbook — HIGH PRIORITY (labeled) ───────────────────────

  /// Labeled account number — highest confidence match.
  /// Handles: A/C NO, ACCOUNT NO, ACC NO, ACCOUNT NUMBER, A/C NUMBER, etc.
  static final labeledAccountNumber = RegExp(
    r'(?:A(?:\/C|CC(?:OUNT)?)(?:\s*(?:NO\.?|NUM(?:BER)?))?'
    r'|ACCOUNT\s*(?:NO\.?|NUM(?:BER)?)?)'
    r'[\s\.\:\-]+(\d[\d\s]{7,19}\d)',
    caseSensitive: false,
  );

  /// CIF (Customer Information File) number label.
  /// MUST be extracted and EXCLUDED from account number candidates.
  /// SBI CIF = 11 digits — identical length to SBI account number!
  static final cifLabel = RegExp(
    r'CIF(?:\s*(?:NO\.?|NUM(?:BER)?|ID))?[\s\.\:\-]+(\d{7,12})',
    caseSensitive: false,
  );

  /// MICR code label — 9 digits, must be excluded.
  static final micrLabel = RegExp(
    r'MICR(?:\s*CODE)?[\s\.\:\-]+(\d{9})',
    caseSensitive: false,
  );

  /// Branch code label — 4–6 digits, must be excluded.
  static final branchCodeLabel = RegExp(
    r'(?:BRANCH|BR\.?)(?:\s*CODE)?[\s\.\:\-]+(\d{4,6})',
    caseSensitive: false,
  );

  /// Phone / mobile number label — must be excluded.
  static final labeledPhoneNumber = RegExp(
    r'(?:PHONE|MOBILE|MOB\.?|PH\.?|TEL\.?|CONTACT)[\s\.\:\-]+([\d\s\-\+]{7,15})',
    caseSensitive: false,
  );

  /// PPO / Nomination Reg / Page No — short labeled numbers to exclude.
  static final otherLabeledNumbers = RegExp(
    r'(?:PPO\s*(?:NO\.?|NUMBER)?|NOM(?:INATION)?\s*REG\s*(?:NO\.?)?|PAGE\s*(?:NO\.?)?|PIN\s*CODE|PINCODE)'
    r'[\s\.\:\-]+(\d{4,12})',
    caseSensitive: false,
  );

  // ── Passbook — FALLBACK (unlabeled) ──────────────────────────

  /// Fallback: any standalone 9–18 digit number.
  /// Only used after all labeled exclusions have been collected.
  static final accountNumber = RegExp(r'\b\d{9,18}\b');

  // ── Common ───────────────────────────────────────────────────

  /// IFSC code — 4 uppercase letters + literal '0' + 6 alphanumeric.
  /// Match this against ORIGINAL text (before OCR digit correction).
  static final ifscCode = RegExp(r'\b[A-Z]{4}0[A-Z0-9]{6}\b');

  /// MICR code standalone — 9 digits.
  static final micrCode = RegExp(r'\b\d{9}\b');

  /// Labeled name — for passbook name extraction.
  /// Handles: NAME, A/C HOLDER, ACCOUNT HOLDER, CARD HOLDER.
  static final labeledName = RegExp(
    r'(?:NAME|A\/C\s*HOLDER(?:\s*NAME)?|ACCOUNT\s*HOLDER(?:\s*NAME)?|CARD\s*HOLDER(?:\s*NAME)?)'
    r'[\s\.\:\-]+([A-Z][A-Z\s\,\.]{2,60})',
    caseSensitive: false,
  );

  /// Customer service / toll-free phone numbers — exclude from all number matching.
  /// e.g. "1800 425 00 000" or "1860 267 7777" on card backs.
  static final tollFreeNumber = RegExp(
    r'\b(?:1800|1860|1900)\s*\d[\d\s]{6,12}\b',
  );
}