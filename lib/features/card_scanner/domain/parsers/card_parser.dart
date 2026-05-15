import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/regex_patterns.dart';
import '../../../../core/constants/validators.dart';
import '../../../../core/utils/string_utils.dart';
import '../../data/models/card_details.dart';

/// Parses raw OCR text from a card scan into structured [CardDetails].
///
/// Real-world cards handled (from actual scans):
///   • Indian Bank Platinum RuPay (dark background, blurry)
///   • IndusInd Debit Visa — front text "MY ACCOUNT MY NUMBER" noise
///   • IndusInd Legend Visa Signature — name only on front
///   • IndusInd back — has VALID FROM + VALID THRU both present
///
/// Key challenges solved:
///   1. Card back has TWO dates: "VALID FROM 03/22  VALID THRU 03/27"
///      → must pick VALID THRU, not VALID FROM
///   2. "MY ACCOUNT MY NUMBER" printed on IndusInd card face
///      → must be excluded from name extraction
///   3. OCR on dark cards misreads O→0, l→1 in card numbers
///      → fixOcrDigitAmbiguity applied before number matching
///   4. fixOcrNumericErrors must NOT run on full text (corrupts names/IFSC)
class CardParser {
  const CardParser._();

  /// Parses [rawText] (raw OCR output) into [CardDetails].
  ///
  /// Safe to call with messy, noisy, multi-line OCR text.
  static CardDetails parseCard(String rawText) {
    if (rawText.trim().isEmpty) {
      return const CardDetails();
    }

    // Step 1: Normalise whitespace and uppercase
    final normalised = StringUtils.normaliseSpaces(rawText.toUpperCase());

    // Step 2: Safe OCR digit fix (O→0, l→1 only) — safe on full text
    final ocrFixed = StringUtils.fixOcrDigitAmbiguity(normalised);

    // Step 3: Extract each field
    final cardNumber = _extractCardNumber(ocrFixed);
    final expiryDate = _extractExpiry(ocrFixed);
    final cardHolderName = _extractName(normalised); // Use pre-digit-fix for name

    // Step 4: Validate card number
    final isValid = cardNumber != null && Validators.isValidCardNumber(cardNumber);

    // Step 5: Mask for display
    final masked = cardNumber != null
        ? StringUtils.formatMaskedCard(cardNumber)
        : null;

    return CardDetails(
      cardNumber: cardNumber,
      maskedCardNumber: masked,
      expiryDate: expiryDate,
      cardHolderName: cardHolderName,
      isValid: isValid,
    );
  }

  // ── Private helpers ───────────────────────────────────────────

  /// Extracts card number from OCR-fixed text.
  ///
  /// Strategy:
  ///   1. Match all candidates with regex.
  ///   2. Clean each candidate (digits only).
  ///   3. Apply aggressive OCR fix (S→5, B→8 etc) on digit-only string.
  ///   4. Validate with Luhn — return first that passes.
  ///   5. If none pass Luhn, return longest valid-length candidate.
  static String? _extractCardNumber(String text) {
    final candidates = <String>[];

    for (final match in RegexPatterns.cardNumber.allMatches(text)) {
      final raw = match.group(0) ?? '';
      final digits = StringUtils.digitsOnly(raw);

      // Apply aggressive fix only on the digit-only candidate
      final fixed = StringUtils.fixOcrNumericErrors(digits);

      if (fixed.length >= AppConstants.minCardNumberLength &&
          fixed.length <= AppConstants.maxCardNumberLength) {
        candidates.add(fixed);
      }
    }

    if (candidates.isEmpty) return null;

    // Prefer Luhn-valid candidate
    for (final candidate in candidates) {
      if (Validators.isValidCardNumber(candidate)) return candidate;
    }

    // No Luhn-valid candidate — return longest (partial scan fallback)
    candidates.sort((a, b) => b.length.compareTo(a.length));
    return candidates.first;
  }

  /// Extracts expiry date from OCR-fixed text.
  ///
  /// Real-world problem: IndusInd card back has BOTH:
  ///   "VALID FROM 03/22  VALID THRU 03/27"
  ///
  /// Strategy:
  ///   1. Try to find "VALID THRU" specifically first.
  ///   2. Fall back to any expiry match if no labeled one found.
  ///   3. Normalise to MM/YY format.
  static String? _extractExpiry(String text) {
    // Priority: look for "VALID THRU" / "VALID THROUGH" / "EXPIRY" / "EXP" label
    final labeledPattern = RegExp(
      r'(?:VALID\s*(?:THRU|THROUGH|TO)|EXPIRY|EXPIRES?|EXP\.?|GOOD\s*THRU)'
      r'[\s\:\.]?\s*(0[1-9]|1[0-2])[\/\-\s](20[2-3]\d|\d{2})',
      caseSensitive: false,
    );

    final labeledMatch = labeledPattern.firstMatch(text);
    if (labeledMatch != null) {
      return _normaliseExpiry(
          labeledMatch.group(1)!, labeledMatch.group(2)!);
    }

    // Fallback: any MM/YY or MMYY pattern
    // Collect all matches and return the latest future date
    final allMatches = <String>[];
    for (final match in RegexPatterns.expiry.allMatches(text)) {
      final full = match.group(0) ?? '';
      final normalised = _parseExpiryFromRaw(full);
      if (normalised != null) allMatches.add(normalised);
    }

    if (allMatches.isEmpty) return null;

    // Return the latest expiry (furthest in future = VALID THRU, not FROM)
    allMatches.sort((a, b) => _expiryToInt(b).compareTo(_expiryToInt(a)));
    return allMatches.first;
  }

  /// Normalises month + year strings to "MM/YY" format.
  static String _normaliseExpiry(String month, String year) {
    final mm = month.padLeft(2, '0');
    // Convert 4-digit year to 2-digit
    final yy = year.length == 4 ? year.substring(2) : year;
    return '$mm/$yy';
  }

  /// Parses a raw expiry match string into "MM/YY" format.
  static String? _parseExpiryFromRaw(String raw) {
    final cleaned = raw.trim();
    final sep = RegExp(r'[\/\-\s]');

    if (sep.hasMatch(cleaned)) {
      final parts = cleaned.split(sep);
      if (parts.length >= 2) {
        final m = parts[0].trim();
        final y = parts[1].trim();
        if (m.isNotEmpty && y.isNotEmpty) {
          return _normaliseExpiry(m, y);
        }
      }
    } else {
      // MMYY no separator
      final digits = StringUtils.digitsOnly(cleaned);
      if (digits.length == 4) {
        return _normaliseExpiry(digits.substring(0, 2), digits.substring(2));
      }
    }
    return null;
  }

  /// Converts "MM/YY" to an integer for comparison (YYMM order).
  static int _expiryToInt(String mmyy) {
    final parts = mmyy.split('/');
    if (parts.length != 2) return 0;
    final yy = int.tryParse(parts[1]) ?? 0;
    final mm = int.tryParse(parts[0]) ?? 0;
    return yy * 100 + mm;
  }

  /// Extracts cardholder name from original (non-digit-fixed) text.
  ///
  /// Strategy:
  ///   1. Try labeled name pattern first ("CARD HOLDER: ...")
  ///   2. Fall back to line-based heuristic — find uppercase name-like lines.
  ///   3. Skip all known noise phrases from [AppConstants.cardNoisePhrases].
  static String? _extractName(String text) {
    // Try labeled match first
    final labeledMatch = RegexPatterns.labeledName.firstMatch(text);
    if (labeledMatch != null) {
      final name = StringUtils.cleanNameTrailingNoise(
          labeledMatch.group(1)?.trim() ?? '');
      if (_isPlausibleName(name)) return name;
    }

    // Line-based heuristic: find lines that look like a person's name
    final lines = text.split(RegExp(r'[\n\r]+'));
    final nameCandidates = <String>[];

    for (final line in lines) {
      final trimmed = StringUtils.normaliseSpaces(line);
      if (_isPlausibleName(trimmed) && !_isNoiseLine(trimmed)) {
        nameCandidates.add(trimmed);
      }
    }

    if (nameCandidates.isEmpty) return null;

    // Return the best candidate — prefer longer names (first + last name)
    nameCandidates.sort((a, b) => b.length.compareTo(a.length));
    return nameCandidates.first;
  }

  /// Returns true if [line] looks like a person's name.
  ///
  /// Rules:
  ///   • 2–40 characters
  ///   • Contains only letters and spaces
  ///   • Has at least 2 words (first + last name) OR single word ≥4 chars
  ///   • Does NOT contain digits
  static bool _isPlausibleName(String line) {
    if (line.length < 2 || line.length > 40) return false;
    if (RegExp(r'\d').hasMatch(line)) return false; // No digits in names
    if (!RegExp(r'^[A-Z][A-Z\s\.\,]+$').hasMatch(line)) return false;

    final words = line.trim().split(RegExp(r'\s+'));
    if (words.length == 1 && words[0].length < 4) return false;

    return true;
  }

  /// Returns true if [line] is a known noise phrase (not a name).
  static bool _isNoiseLine(String line) {
    final upper = line.toUpperCase().trim();
    for (final noise in AppConstants.cardNoisePhrases) {
      if (upper == noise || upper.contains(noise)) return true;
    }
    // Also skip bank names and card type words
    const bankKeywords = [
      'BANK', 'VISA', 'MASTERCARD', 'RUPAY', 'AMEX',
      'PLATINUM', 'GOLD', 'SIGNATURE', 'LEGEND', 'CLASSIC',
    ];
    for (final kw in bankKeywords) {
      if (upper.contains(kw)) return true;
    }
    return false;
  }
}