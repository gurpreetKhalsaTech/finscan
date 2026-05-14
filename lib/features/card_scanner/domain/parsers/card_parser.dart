import '../../data/models/card_details.dart';
import '../../../../core/constants/regex_patterns.dart';
import '../../../../core/utils/string_utils.dart';
import 'luhn_validator.dart';

class CardParser {
  CardParser._();

  static CardDetails? parseCard(String rawText) {
    final cleaned = StringUtils.fixOcrNumericErrors(rawText);

    final cardMatch = RegexPatterns.cardNumber.firstMatch(cleaned);
    if (cardMatch == null) return null;

    final rawNumber = StringUtils.digitsOnly(cardMatch.group(0)!);
    if (!LuhnValidator.isValid(rawNumber)) return null;

    final expiryMatch = RegexPatterns.expiry.firstMatch(cleaned);
    final expiry = expiryMatch != null ? _normalizeExpiry(expiryMatch.group(0)!) : '';

    final holderName = _extractHolderName(cleaned, cardMatch.start);

    return CardDetails(
      cardNumber: rawNumber,
      cardHolderName: holderName,
      expiryDate: expiry,
      cardNetwork: _detectNetwork(rawNumber),
    );
  }

  // Normalises MM-YY and MMYY into MM/YY
  static String _normalizeExpiry(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length == 4) return '${digits.substring(0, 2)}/${digits.substring(2)}';
    // Already MM/YY or MM-YY — keep separator as /
    return raw.replaceAll('-', '/');
  }

  static String _extractHolderName(String text, int cardMatchStart) {
    final above = text.substring(0, cardMatchStart).trim();
    final lines = above.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return '';
    final last = lines.last.trim();
    if (RegExp(r'^[A-Z ]{2,26}$').hasMatch(last)) return last;
    return '';
  }

  static String? _detectNetwork(String digits) {
    if (digits.startsWith('4')) return 'Visa';
    if (RegExp(r'^5[1-5]').hasMatch(digits)) return 'Mastercard';
    if (RegExp(r'^(508[5-9]|6069[89]|607|608|6521|6522)').hasMatch(digits)) return 'RuPay';
    if (RegExp(r'^3[47]').hasMatch(digits)) return 'Amex';
    return null;
  }
}