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
  /// We use [ \-] instead of \s to prevent matching across newlines.
  static final cardNumber = RegExp(
    r'\b(\d{4}[ \-]?\d{6}[ \-]?\d{5}|\d{4}[ \-]?\d{4}[ \-]?\d{4}[ \-]?\d{4})\b',
  );

  /// Expiry date — handles:
  ///   MM/YY  MM-YY  MM YY  MMYY  MM/YYYY  MM-YYYY
  static final expiry = RegExp(
    r'(?:VALID\s*(?:THRU|THROUGH|TO)|EXPIRY|EXPIRES?|EXP)[\s\:\.]?'
    r'\s*(0[1-9]|1[0-2])[\/\-\s](20[2-3]\d|\d{2})'
    r'|\b(0[1-9]|1[0-2])[\/\-](20[2-3]\d|\d{2})\b'
    r'|\b(0[1-9]|1[0-2])(2[0-9]|3[0-9])(?!\d)\b',
    caseSensitive: false,
  );

  // ── Passbook — HIGH PRIORITY (labeled) ───────────────────────

  /// Labeled account number — handles spaced groups like "1141 2952 622".
  /// Supports: A/C NO, ACCOUNT NO, ACC NO, ACCOUNT NUMBER, SB A/C NO, CA A/C NO, etc.
  static final labeledAccountNumber = RegExp(
    r'(?:(?:SB|CA|OD|CC)\s+)?'
    r'(?:A(?:\/C|CC(?:OUNT)?|CCT)|ACCOUNT)'
    r'(?:\s*(?:NO\.?|NUM(?:BER)?))?'
    r'[\s\.\:\-]+(\d[\d \-]{7,22}\d)',
    caseSensitive: false,
  );

  /// CIF / Customer ID / UCIC — bank-specific names for the same thing.
  /// SBI: CIF (11 digits), HDFC: Customer ID (8 digits), Union: UCIC.
  static final cifLabel = RegExp(
    r'(?:CIF|CUSTOMER\s*ID|CUST\s*ID|CUSTOMER\s*NO\.?|CUSTOMER\s*NUMBER|UCIC)'
    r'(?:\s*(?:NO\.?|NUM(?:BER)?|ID))?'
    r'[\s\.\:\-]+(\d{7,12})',
    caseSensitive: false,
  );

  /// MICR code label — 9 digits, must be excluded.
  static final micrLabel = RegExp(
    r'MICR(?:\s*(?:CODE|NO\.?))?[\s\.\:\-]+(\d{9})',
    caseSensitive: false,
  );

  /// Branch code label — 4–6 digits, must be excluded.
  static final branchCodeLabel = RegExp(
    r'(?:BRANCH|BR\.?)(?:\s*CODE)?[\s\.\:\-]+(\d{4,6})',
    caseSensitive: false,
  );

  /// Phone / mobile number label — must be excluded.
  static final labeledPhoneNumber = RegExp(
    r'(?:PHONE|MOBILE|MOB\.?|PH\.?|TEL\.?|TELEPHONE|CONTACT)(?:\s*NO\.?)?'
    r'[\s\.\:\-]+([\d \-\+]{7,15})',
    caseSensitive: false,
  );

  /// PPO / Nomination / Page / PIN code — short labeled numbers to exclude.
  static final otherLabeledNumbers = RegExp(
    r'(?:PPO\s*(?:NO\.?|NUMBER)?'
    r'|NOM(?:INATION)?\s*REG\s*(?:NO\.?)?'
    r'|PAGE\s*(?:NO\.?)?'
    r'|PIN\s*CODE'
    r'|PINCODE'
    r'|PIN\s*(?:NO\.?)?'
    r'|CHEQUE\s*(?:NO\.?|NUMBER)?'
    r'|CHQ\s*(?:NO\.?|NUMBER)?'
    r'|BSR\s*CODE'
    r'|SWIFT(?:\s*CODE)?)'
    r'[\s\.\:\-]+(\d{4,12})',
    caseSensitive: false,
  );

  // ── Passbook — FALLBACK (unlabeled) ──────────────────────────

  /// Fallback: any standalone 9–18 digit number.
  /// Also matches spaced groups: "1141 2952 622" → cleaned to "11412952622".
  static final accountNumber = RegExp(
    r'\b\d[\d \-]{8,22}\d\b',
  );

  // ── Common ───────────────────────────────────────────────────

  /// IFSC code — 4 uppercase letters + literal '0' + 6 alphanumeric.
  /// Match this against ORIGINAL text (before OCR digit correction).
  static final ifscCode = RegExp(r'\b[A-Z]{4}0[A-Z0-9]{6}\b');

  /// IFSC with label — higher confidence match.
  static final ifscLabel = RegExp(
    r'IFSC(?:\s*(?:CODE|NO\.?|NUMBER))?[\s\.\:\-]+([A-Z]{4}0[A-Z0-9]{6})',
    caseSensitive: false,
  );

  /// MICR code standalone — 9 digits.
  static final micrCode = RegExp(r'\b\d{9}\b');

  /// Labeled name — handles both UPPERCASE and Title Case names.
  /// HDFC/ICICI passbooks often print names in title case.
  /// We exclude newlines from the name match to prevent over-capturing.
  static final labeledName = RegExp(
    r'(?:NAME|A\/C\s*HOLDER(?:\s*NAME)?'
    r'|ACCOUNT\s*HOLDER(?:\s*NAME)?'
    r'|CARD\s*HOLDER(?:\s*NAME)?'
    r'|HOLDER\s*NAME)'
    r'[\s\.\:\-]+([A-Za-z][A-Za-z \t\,\.]{2,60})',
    caseSensitive: false,
  );

  /// Customer service / toll-free phone numbers — exclude from all number matching.
  /// e.g. "1800 425 00 000" or "1860 267 7777" on card backs.
  static final tollFreeNumber = RegExp(
    r'\b(?:1800|1860|1900|0124|022|011|080|044|033)[\s\-]*\d[\d \-]{6,15}\b',
  );

  /// Date patterns — exclude from number matching.
  /// DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD
  static final datePattern = RegExp(
    r'\b\d{2}[\/\-]\d{2}[\/\-]\d{4}\b|\b\d{4}[\/\-]\d{2}[\/\-]\d{2}\b',
  );

  /// Time pattern HH:MM:SS or HH:MM — exclude.
  static final timePattern = RegExp(r'\b\d{1,2}:\d{2}(?::\d{2})?\b');

}