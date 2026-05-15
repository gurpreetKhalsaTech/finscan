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
  static CardDetails parseCard(String rawText) {
    if (rawText.trim().isEmpty) return const CardDetails();

    // Step 1: Safe OCR digit fix (O→0, l→1) BEFORE uppercase
    // This ensures lowercase 'l' from OCR is corrected to '1' before it becomes 'L'.
    final ocrFixed = StringUtils.fixOcrDigitAmbiguity(rawText);

    // Step 2: Normalise whitespace and uppercase
    final normalised = StringUtils.normaliseSpaces(ocrFixed.toUpperCase());

    // Step 3: Extract each field
    // Use normalised (all-caps, single-spaced) for extraction
    final cardNumber = _extractCardNumber(normalised);
    final expiryDate = _extractExpiry(normalised);
    final cardHolderName = _extractName(normalised);

    // Step 4: Validate card
    final isValid =
        cardNumber != null && Validators.isValidCardNumber(cardNumber);

    // Step 5: Mask for display
    final masked =
    cardNumber != null ? StringUtils.formatMaskedCard(cardNumber) : null;

    // Step 6: Detect network and bank
    final cardNetwork = _detectCardNetwork(cardNumber);
    final bankName = _detectBankName(normalised);

    return CardDetails(
      cardNumber: cardNumber,
      maskedCardNumber: masked,
      expiryDate: expiryDate,
      cardHolderName: cardHolderName,
      cardNetwork: cardNetwork,
      bankName: bankName,
      isValid: isValid,
    );
  }

  // ── Card Number ──────────────────────────────────────────────

  static String? _extractCardNumber(String text) {
    // ── Step 1: Build exclusion set (Phone/Toll-free numbers) ──
    final Set<String> excluded = {};
    for (final m in RegexPatterns.tollFreeNumber.allMatches(text)) {
      excluded.add(StringUtils.digitsOnly(m.group(0) ?? ''));
    }

    final candidates = <String>[];

    for (final match in RegexPatterns.cardNumber.allMatches(text)) {
      final raw = match.group(0) ?? '';
      final digits = StringUtils.digitsOnly(raw);

      if (excluded.contains(digits)) continue;

      if (digits.length >= AppConstants.minCardNumberLength &&
          digits.length <= AppConstants.maxCardNumberLength) {
        candidates.add(digits);
      }
    }

    if (candidates.isEmpty) return null;

    // Prefer Luhn-valid
    for (final candidate in candidates) {
      if (Validators.isValidCardNumber(candidate)) return candidate;
    }

    // No Luhn-valid — return longest (partial scan fallback)
    candidates.sort((a, b) => b.length.compareTo(a.length));
    return candidates.first;
  }

  // ── Expiry ───────────────────────────────────────────────────

  static String? _extractExpiry(String text) {
    // Priority: labeled VALID THRU / EXPIRY
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

    // Fallback: any MM/YY-style match; pick latest
    final allMatches = <String>[];
    for (final match in RegexPatterns.expiry.allMatches(text)) {
      final full = match.group(0) ?? '';
      final normalised = _parseExpiryFromRaw(full);
      if (normalised != null) allMatches.add(normalised);
    }

    if (allMatches.isEmpty) return null;

    allMatches.sort((a, b) => _expiryToInt(b).compareTo(_expiryToInt(a)));
    return allMatches.first;
  }

  static String _normaliseExpiry(String month, String year) {
    final mm = month.padLeft(2, '0');
    final yy = year.length == 4 ? year.substring(2) : year;
    return '$mm/$yy';
  }

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
      final digits = StringUtils.digitsOnly(cleaned);
      if (digits.length == 4) {
        return _normaliseExpiry(digits.substring(0, 2), digits.substring(2));
      }
    }
    return null;
  }

  static int _expiryToInt(String mmyy) {
    final parts = mmyy.split('/');
    if (parts.length != 2) return 0;
    final yy = int.tryParse(parts[1]) ?? 0;
    final mm = int.tryParse(parts[0]) ?? 0;
    return yy * 100 + mm;
  }

  // ── Name ─────────────────────────────────────────────────────

  static String? _extractName(String text) {
    // Try labeled match first
    final labeledMatch = RegexPatterns.labeledName.firstMatch(text);
    if (labeledMatch != null) {
      final name = StringUtils.cleanNameTrailingNoise(
          labeledMatch.group(1)?.trim() ?? '');
      if (_isPlausibleName(name)) return name;
    }

    // Line-based heuristic
    final lines = text.split(RegExp(r'[\n\r]+'));
    final nameCandidates = <String>[];

    for (final line in lines) {
      final trimmed = StringUtils.normaliseSpaces(line);
      if (_isPlausibleName(trimmed) && !_isNoiseLine(trimmed)) {
        nameCandidates.add(trimmed);
      }
    }

    if (nameCandidates.isEmpty) return null;

    nameCandidates.sort((a, b) => b.length.compareTo(a.length));
    return nameCandidates.first;
  }

  static bool _isPlausibleName(String line) {
    if (line.length < 2 || line.length > 40) return false;
    if (RegExp(r'\d').hasMatch(line)) return false;
    if (!RegExp(r'^[A-Z][A-Z\s\.\,]+$').hasMatch(line)) return false;

    final words = line.trim().split(RegExp(r'\s+'));
    if (words.length == 1 && words[0].length < 4) return false;

    return true;
  }

  static bool _isNoiseLine(String line) {
    final upper = line.toUpperCase().trim();
    for (final noise in AppConstants.cardNoisePhrases) {
      if (upper == noise || upper.contains(noise)) return true;
    }
    const bankKeywords = [
      'BANK', 'VISA', 'MASTERCARD', 'RUPAY', 'AMEX',
      'PLATINUM', 'GOLD', 'SIGNATURE', 'LEGEND', 'CLASSIC',
      'INFINITE', 'WORLD', 'TITANIUM',
    ];
    for (final kw in bankKeywords) {
      if (upper.contains(kw)) return true;
    }
    return false;
  }

  // ── Network & Bank ───────────────────────────────────────────

  /// Detects card network from IIN/BIN prefix.
  /// Reference: ISO/IEC 7812 + RuPay BIN ranges.
  static String? _detectCardNetwork(String? cardNumber) {
    if (cardNumber == null || cardNumber.isEmpty) return null;

    // Visa: starts with 4
    if (cardNumber.startsWith('4')) return 'Visa';

    // Mastercard: 51-55 or 2221-2720
    if (RegExp(r'^5[1-5]').hasMatch(cardNumber)) return 'Mastercard';
    if (RegExp(r'^(222[1-9]|22[3-9]\d|2[3-6]\d{2}|27[01]\d|2720)')
        .hasMatch(cardNumber)) {
      return 'Mastercard';
    }

    // Amex: 34 or 37
    if (cardNumber.startsWith('34') || cardNumber.startsWith('37')) {
      return 'Amex';
    }

    // RuPay: 60, 6521, 6522, 81, 82, 508
    if (RegExp(r'^(60|6521|6522|508|81|82)').hasMatch(cardNumber)) {
      return 'RuPay';
    }

    // Diners: 300-305, 36, 38
    if (RegExp(r'^(30[0-5]|36|38)').hasMatch(cardNumber)) return 'Diners';

    // Discover: 6011, 622126-622925, 644-649, 65
    if (RegExp(r'^(6011|65|64[4-9])').hasMatch(cardNumber)) return 'Discover';

    return null;
  }

  static String? _detectBankName(String text) {
    for (final bank in AppConstants.knownBanks) {
      if (text.contains(bank)) return bank;
    }
    return null;
  }
}