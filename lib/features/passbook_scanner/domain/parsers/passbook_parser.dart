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
///   PAN         : HINPS5614A
///
/// Key challenges solved:
///   1. CIF = 11 digits, Account No = 11 digits — MUST use label to distinguish.
///   2. MICR (9 digits) matches \b\d{9,18}\b fallback — must exclude by label.
///   3. Name field contains "SUBA SINGH, GURPREET SINGH" — take primary holder.
///   4. IFSC must be matched on ORIGINAL text (O not yet replaced with 0).
///   5. Toll-free numbers (1800/1860) must not be matched as account numbers.
///   6. Aadhaar (12 digits) and PAN must be excluded — they appear on passbooks.
///   7. Dates like "21/09/2023" contain digits that could match — pre-stripped.
///   8. HDFC uses "Customer ID" instead of "CIF" — both excluded.
class PassbookParser {
  const PassbookParser._();

  static BankDetails parsePassbook(String rawText) {
    if (rawText.trim().isEmpty) return const BankDetails();

    // Step 1: Normalise
    final normalised = StringUtils.normaliseSpaces(rawText.toUpperCase());

    // Step 2: IFSC must be matched on original text (before O→0)
    final ifscCode = _extractIfsc(normalised);

    // Step 3: Safe OCR digit fix for number extraction
    final ocrFixed = StringUtils.fixOcrDigitAmbiguity(normalised);

    // Step 4: Strip dates/times BEFORE number extraction
    final cleanedForNumbers = StringUtils.stripNoise(ocrFixed);

    // Step 5: Extract numbers with exclusion-based priority
    final accountNumber = _extractAccountNumber(cleanedForNumbers);
    final micrCode = _extractMicr(cleanedForNumbers);

    // Step 6: Name and metadata
    final accountHolderName = _extractName(normalised);
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

  // ── Account Number ───────────────────────────────────────────

  /// Extracts account number using a label-first, exclusion-based strategy.
  ///
  /// Challenge: passbooks have many numbers (CIF, MICR, branch code, phone,
  /// page number) that could be mistaken for account numbers. Strategy:
  ///   1. If labeled (A/C NO, ACCOUNT NO, etc.) → use that directly.
  ///   2. Build an exclusion set of known non-account numbers by their labels.
  ///   3. From remaining candidates, pick the longest valid-length number.
  static String? _extractAccountNumber(String text) {
    // ── Step 1: Labeled match (highest confidence) ──
    final labeledMatch = RegexPatterns.labeledAccountNumber.firstMatch(text);
    if (labeledMatch != null) {
      final raw = labeledMatch.group(1) ?? '';
      final digits = StringUtils.digitsOnly(raw);
      if (Validators.isValidAccountNumber(digits)) return digits;
    }

    // ── Step 2: Build exclusion set ──
    final Set<String> excluded = {};

    // CIF / Customer ID / UCIC (SBI CIF = 11 digits, same length as account no!)
    for (final m in RegexPatterns.cifLabel.allMatches(text)) {
      excluded.add(StringUtils.digitsOnly(m.group(1) ?? ''));
    }

    // MICR
    for (final m in RegexPatterns.micrLabel.allMatches(text)) {
      excluded.add(StringUtils.digitsOnly(m.group(1) ?? ''));
    }

    // Branch codes
    for (final m in RegexPatterns.branchCodeLabel.allMatches(text)) {
      excluded.add(StringUtils.digitsOnly(m.group(1) ?? ''));
    }

    // Phone numbers
    for (final m in RegexPatterns.labeledPhoneNumber.allMatches(text)) {
      excluded.add(StringUtils.digitsOnly(m.group(1) ?? ''));
    }

    // Toll-free numbers
    for (final m in RegexPatterns.tollFreeNumber.allMatches(text)) {
      excluded.add(StringUtils.digitsOnly(m.group(0) ?? ''));
    }

    // Other labeled numbers (PPO, PIN code, page no, cheque no, BSR, SWIFT)
    for (final m in RegexPatterns.otherLabeledNumbers.allMatches(text)) {
      excluded.add(StringUtils.digitsOnly(m.group(1) ?? ''));
    }

    // ── Step 3: Find unlabeled candidates ──
    final candidates = <String>[];

    for (final m in RegexPatterns.accountNumber.allMatches(text)) {
      final raw = m.group(0) ?? '';
      final digits = StringUtils.digitsOnly(raw);

      if (excluded.contains(digits)) continue;
      if (!Validators.isValidAccountNumber(digits)) continue;

      candidates.add(digits);
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) => b.length.compareTo(a.length));
    return candidates.first;
  }

  // ── IFSC ─────────────────────────────────────────────────────

  /// Extracts IFSC from original text (before O→0 replacement).
  static String? _extractIfsc(String text) {
    // Labeled match first
    final labeled = RegexPatterns.ifscLabel.firstMatch(text);
    if (labeled != null) return labeled.group(1)?.toUpperCase();

    // Bare pattern fallback
    final bare = RegexPatterns.ifscCode.firstMatch(text);
    return bare?.group(0)?.toUpperCase();
  }

  // ── MICR ─────────────────────────────────────────────────────

  /// Extracts MICR — labeled only to avoid false positives.
  static String? _extractMicr(String text) {
    final labeled = RegexPatterns.micrLabel.firstMatch(text);
    if (labeled != null) {
      final digits = StringUtils.digitsOnly(labeled.group(1) ?? '');
      if (Validators.isValidMicr(digits)) return digits;
    }
    // Don't fallback to standalone 9-digit — too prone to false positives
    return null;
  }

  // ── Name ─────────────────────────────────────────────────────

  static String? _extractName(String text) {
    // Try labeled match
    final labeled = RegexPatterns.labeledName.firstMatch(text);
    if (labeled != null) {
      final raw = labeled.group(1)?.trim() ?? '';
      return _cleanPassbookName(raw);
    }
    return null;
  }

  /// Cleans extracted name string.
  /// Handles "SUBA SINGH, GURPREET SINGH" → "SUBA SINGH"
  /// Handles "GURPREET SINGH S/O SOHAN" → "GURPREET SINGH"
  static String? _cleanPassbookName(String raw) {
    if (raw.isEmpty) return null;

    // Take first segment if comma-separated
    String name = raw.contains(',') ? raw.split(',').first.trim() : raw;

    // Remove relationship suffixes
    name = StringUtils.cleanNameTrailingNoise(name);

    // Remove trailing single letter
    name = name.replaceAll(RegExp(r'\s+[A-Z]$'), '').trim();

    if (name.length < 2) return null;
    return name;
  }

  // ── Bank, Branch, Account Type ───────────────────────────────

  static String? _extractBankName(String text) {
    for (final bank in AppConstants.knownBanks) {
      if (text.contains(bank)) return bank;
    }
    // Fallback regex
    final bankPattern = RegExp(r'([A-Z][A-Z\s]+BANK(?:\s+LIMITED|\s+LTD)?)\b');
    final match = bankPattern.firstMatch(text);
    return match?.group(1)?.trim();
  }

  static String? _extractBranchName(String text) {
    final branchPattern = RegExp(
      r'BRANCH(?:\s*NAME)?[\s\.\:\-]+([A-Z][A-Z\s\,\.]{2,50})',
      caseSensitive: false,
    );
    final match = branchPattern.firstMatch(text);
    return match?.group(1)?.trim();
  }

}