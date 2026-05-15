import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/regex_patterns.dart';
import '../../../../core/constants/validators.dart';
import '../../../../core/utils/string_utils.dart';
import '../../data/models/bank_details.dart';

/// Parses raw OCR text from a passbook/bank document scan into [BankDetails].
///
/// Real-world SBI passbook layout handled (from actual scan):
///
///   Name        : SUBA SINGH, GURPREET SINGH
///   S/D/H/o     : SOHAN SINGH
///   CIF Number  : 81154707486   ← 11 digits (SAME length as account no!)
///   Account No. : 11412952622   ← 11 digits
///   MICR        : 152002131     ← 9 digits
///   Branch Code : 5576
///   IFSC        : SBIN0005576
///
/// Key challenges solved:
///   1. CIF = 11 digits, Account No = 11 digits — MUST use label to distinguish.
///   2. MICR (9 digits) matches \b\d{9,18}\b fallback — must exclude by label.
///   3. Name field contains BOTH holder + relation: "SUBA SINGH, GURPREET SINGH"
///      → take the part before the comma as the primary holder name.
///   4. IFSC must be matched on ORIGINAL text (O not yet replaced with 0)
///      because SBIN contains a real 'B', not a misread digit.
///   5. Toll-free numbers on card backs (1800 xxx xxxx) must not be matched.
class PassbookParser {
  const PassbookParser._();

  /// Parses [rawText] (raw OCR output) into [BankDetails].
  ///
  /// Safe to call with messy, multi-line, rotated passbook OCR text.
  static BankDetails parsePassbook(String rawText) {
    if (rawText.trim().isEmpty) return const BankDetails();

    // Step 1: Normalise
    final normalised = StringUtils.normaliseSpaces(rawText.toUpperCase());

    // Step 2: IFSC must be matched on original text BEFORE digit fixes
    final ifscCode = _extractIfsc(normalised);

    // Step 3: Safe OCR digit fix (O→0, l→1) for number extraction
    final ocrFixed = StringUtils.fixOcrDigitAmbiguity(normalised);

    // Step 4: Build exclusion set FIRST, then find account number
    final accountNumber = _extractAccountNumber(ocrFixed);

    // Step 5: MICR — match labeled or standalone 9-digit on digit-fixed text
    final micrCode = _extractMicr(ocrFixed);

    // Step 6: Name — use original normalised text (not digit-fixed)
    final accountHolderName = _extractName(normalised);

    // Step 7: Bank name and branch
    final bankName = _extractBankName(normalised);
    final branchName = _extractBranchName(normalised);

    return BankDetails(
      accountHolderName: accountHolderName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      micrCode: micrCode,
      bankName: bankName,
      branchName: branchName,
    );
  }

  // ── Account Number ────────────────────────────────────────────

  /// Extracts account number using a priority-based exclusion system.
  ///
  /// Priority order:
  ///   1. Labeled account number (A/C NO, ACCOUNT NO, etc.) → highest confidence
  ///   2. If labeled match found, validate length and return immediately.
  ///   3. If not found, build exclusion set from CIF/MICR/Branch/Phone labels.
  ///   4. Find all 9-18 digit numbers, skip those in exclusion set.
  ///   5. Apply length-based preference: Indian account numbers are 9–18 digits.
  static String? _extractAccountNumber(String text) {
    // ── Step 1: Labeled match (highest confidence) ──
    final labeledMatch = RegexPatterns.labeledAccountNumber.firstMatch(text);
    if (labeledMatch != null) {
      final raw = labeledMatch.group(1) ?? '';
      final digits = StringUtils.digitsOnly(raw);
      if (Validators.isValidAccountNumber(digits)) {
        return digits;
      }
    }

    // ── Step 2: Build exclusion set ──
    final Set<String> excluded = {};

    // Exclude CIF numbers (11 digits in SBI — same length as account no!)
    for (final m in RegexPatterns.cifLabel.allMatches(text)) {
      excluded.add(StringUtils.digitsOnly(m.group(1) ?? ''));
    }

    // Exclude MICR (9 digits)
    for (final m in RegexPatterns.micrLabel.allMatches(text)) {
      excluded.add(StringUtils.digitsOnly(m.group(1) ?? ''));
    }

    // Exclude branch codes (4-6 digits)
    for (final m in RegexPatterns.branchCodeLabel.allMatches(text)) {
      excluded.add(StringUtils.digitsOnly(m.group(1) ?? ''));
    }

    // Exclude labeled phone numbers
    for (final m in RegexPatterns.labeledPhoneNumber.allMatches(text)) {
      excluded.add(StringUtils.digitsOnly(m.group(1) ?? ''));
    }

    // Exclude toll-free numbers (1800/1860...)
    for (final m in RegexPatterns.tollFreeNumber.allMatches(text)) {
      excluded.add(StringUtils.digitsOnly(m.group(0) ?? ''));
    }

    // Exclude other labeled numbers (PPO, PIN code, Page No, etc.)
    for (final m in RegexPatterns.otherLabeledNumbers.allMatches(text)) {
      excluded.add(StringUtils.digitsOnly(m.group(1) ?? ''));
    }

    // ── Step 3: Fallback — find all unlabeled numbers ──
    final candidates = <String>[];
    for (final m in RegexPatterns.accountNumber.allMatches(text)) {
      final digits = StringUtils.digitsOnly(m.group(0) ?? '');

      // Skip if in exclusion set
      if (excluded.contains(digits)) continue;

      // Skip if also appears after an excluded label in context
      if (StringUtils.appearsAfterExcludedLabel(digits, text)) continue;

      if (Validators.isValidAccountNumber(digits)) {
        candidates.add(digits);
      }
    }

    if (candidates.isEmpty) return null;

    // Prefer longer candidates (more specific account numbers)
    candidates.sort((a, b) => b.length.compareTo(a.length));
    return candidates.first;
  }

  // ── IFSC ──────────────────────────────────────────────────────

  /// Extracts IFSC code from text.
  ///
  /// IMPORTANT: Match against original text (before O→0 replacement).
  /// SBIN, HDFC, ICIC contain real uppercase letters — not OCR errors.
  static String? _extractIfsc(String text) {
    // Try labeled match first
    final labeledIfsc = RegExp(
      r'IFSC(?:\s*(?:CODE|NO\.?|NUMBER))?[\s\.\:\-]+([A-Z]{4}0[A-Z0-9]{6})',
      caseSensitive: false,
    );
    final labeled = labeledIfsc.firstMatch(text);
    if (labeled != null) return labeled.group(1)?.toUpperCase();

    // Fallback: bare IFSC pattern in text
    final bare = RegexPatterns.ifscCode.firstMatch(text);
    return bare?.group(0)?.toUpperCase();
  }

  // ── MICR ──────────────────────────────────────────────────────

  /// Extracts MICR code (9 digits).
  static String? _extractMicr(String text) {
    // Try labeled match first
    final labeled = RegexPatterns.micrLabel.firstMatch(text);
    if (labeled != null) {
      final digits = StringUtils.digitsOnly(labeled.group(1) ?? '');
      if (digits.length == AppConstants.micrLength) return digits;
    }

    // Fallback: standalone 9-digit number (only if no label context needed)
    final bare = RegexPatterns.micrCode.firstMatch(text);
    if (bare != null) {
      final digits = StringUtils.digitsOnly(bare.group(0) ?? '');
      if (digits.length == AppConstants.micrLength) return digits;
    }

    return null;
  }

  // ── Name ──────────────────────────────────────────────────────

  /// Extracts account holder name from passbook text.
  ///
  /// Real SBI challenge: "NAME : SUBA SINGH, GURPREET SINGH"
  ///   → The part before the comma is the primary account holder.
  ///   → The part after may be a joint holder or nominee.
  ///
  /// Strategy:
  ///   1. Try labeled name pattern.
  ///   2. If comma-separated, take the first name segment.
  ///   3. Clean trailing noise (S/O, D/O, W/O suffixes).
  static String? _extractName(String text) {
    // Try labeled match
    final labeled = RegexPatterns.labeledName.firstMatch(text);
    if (labeled != null) {
      final raw = labeled.group(1)?.trim() ?? '';
      return _cleanPassbookName(raw);
    }

    // Try "NAME :" pattern specifically (common in SBI)
    final sbiNamePattern = RegExp(
      r'NAME[\s]*:[\s]*([A-Z][A-Z\s\,\.]{2,60})',
      caseSensitive: false,
    );
    final sbiMatch = sbiNamePattern.firstMatch(text);
    if (sbiMatch != null) {
      final raw = sbiMatch.group(1)?.trim() ?? '';
      return _cleanPassbookName(raw);
    }

    return null;
  }

  /// Cleans a raw name string extracted from a passbook.
  ///
  /// Handles:
  ///   • "SUBA SINGH, GURPREET SINGH" → "SUBA SINGH" (take primary holder)
  ///   • "GURPREET SINGH S/O SOHAN SINGH" → "GURPREET SINGH"
  static String? _cleanPassbookName(String raw) {
    if (raw.isEmpty) return null;

    // If comma-separated, take the first segment (primary holder)
    String name = raw.contains(',') ? raw.split(',').first.trim() : raw;

    // Remove relationship suffixes
    name = StringUtils.cleanNameTrailingNoise(name);

    // Remove trailing single characters or punctuation
    name = name.replaceAll(RegExp(r'\s+[A-Z]$'), '').trim();

    if (name.length < 2) return null;
    return name;
  }

  // ── Bank & Branch ─────────────────────────────────────────────

  /// Extracts bank name from passbook text.
  static String? _extractBankName(String text) {
    const knownBanks = [
      'STATE BANK OF INDIA',
      'PUNJAB NATIONAL BANK',
      'BANK OF BARODA',
      'CANARA BANK',
      'UNION BANK OF INDIA',
      'BANK OF INDIA',
      'INDIAN BANK',
      'CENTRAL BANK OF INDIA',
      'UCO BANK',
      'BANK OF MAHARASHTRA',
      'HDFC BANK',
      'ICICI BANK',
      'AXIS BANK',
      'KOTAK MAHINDRA BANK',
      'INDUSIND BANK',
      'YES BANK',
      'IDFC FIRST BANK',
    ];

    for (final bank in knownBanks) {
      if (text.contains(bank)) return bank;
    }

    // Fallback: find "X BANK" pattern
    final bankPattern = RegExp(r'([A-Z][A-Z\s]+BANK(?:\s+LIMITED|\s+LTD)?)\b');
    final match = bankPattern.firstMatch(text);
    return match?.group(1)?.trim();
  }

  /// Extracts branch name from passbook text.
  static String? _extractBranchName(String text) {
    final branchPattern = RegExp(
      r'BRANCH(?:\s*NAME)?[\s\.\:\-]+([A-Z][A-Z\s\,\.]{2,50})',
      caseSensitive: false,
    );
    final match = branchPattern.firstMatch(text);
    return match?.group(1)?.trim();
  }
}